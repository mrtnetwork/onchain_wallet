import 'dart:async';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/types.dart';
import 'package:on_chain_wallet/crypto/wallet/keys.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/monero/monero.dart';
import 'package:on_chain_wallet/wallet/models/networks/monero/syncing/tracker.dart';
import 'package:on_chain_wallet/wallet/chain/chain/chain.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/block/models/offset.dart';
import 'package:on_chain_wallet/wallet/models/block/models/status.dart';

import 'request.dart';
import 'sync_account.dart';

typedef CbCreateStreamCryptoController = Future<
        IResult<
            StreamCryptoRequestController<MoneroSyncOffsetResponse,
                MoneroBlockTrackingRequestOffset>>>
    Function(SyncWorkerMode? mode, CancelableListener? cancelable, Duration syncingInverval);
typedef CbGetMoneroSecretKey = Future<IResult<LongTimeMemorySecretKey>> Function();
typedef CbMoneroSyncTrackerUpdated = Future<IResult<void>> Function(
    MoneroSyncingEvent event);
typedef CbMoneroClient = Future<IResult<MoneroNetworkClient>> Function();

abstract class MoneroSyncing {
  Future<IResult<void>> dispose();
  Future<IResult<void>> syncRemoved(int requestId);
  Future<IResult<void>> newRequestImported();
  Future<IResult<void>> newAccountImported();
  Future<IResult<void>> retryErrors();
  List<MoneroTrackingOffsetWithStatus> getTrackerOffsets(MoneroSyncTracker tracker);
  BlockSyncStatus get status;
  StreamValue<MoneroChainNotify> get latestEvent;
  int? get latestHeight;
  int get latestSyncedHeight;
  Duration get maxSyncingInterval;
}

class MoneroSyncingDefault implements MoneroSyncing {
  final SafeAtomicLock sync = SafeAtomicLock();
  final MoneroSyncTrackerController tracker;
  final CbCreateStreamCryptoController createSyncRequest;
  final CbMoneroSyncTrackerUpdated onTrackerUpdated;
  final CbGetMoneroSecretKey _secretKeyRequestCallback;
  final Duration blockInterval;
  @override
  final StreamValue<MoneroChainNotify> latestEvent = StreamValue<MoneroChainNotify>(
      MoneroChainNotify.syncingStatusChanged,
      name: "MoneroSyncingDefault");
  @override
  BlockSyncStatus status = BlockSyncStatusPending();
  final cancelable = CancelableListener();
  final int maxRequestThread;
  // int get maxThread => tracker.maxThread;
  final CbMoneroClient clientCallBack;
  StreamSubscription<dynamic>? _periodicTimer;
  bool _disposed = false;
  bool _isOnline = true;
  int? _latestHeight;
  LongTimeMemorySecretKey? _secretKey;

  @override
  int? get latestHeight => _latestHeight;
  final Map<String, MoneroTrackingOffsetWithStatus> _offsets = {};
  MoneroSyncingDefault({
    required this.tracker,
    required this.createSyncRequest,
    required this.onTrackerUpdated,
    required this.clientCallBack,
    required this.maxRequestThread,
    required CbGetMoneroSecretKey secretKeyRequestCallback,
    required WalletMoneroNetwork network,
    required Stream<bool>? connectivity,
  })  : blockInterval = Duration(seconds: network.coinParam.averageBlockTime),
        _secretKeyRequestCallback = secretKeyRequestCallback {
    _init();
    connectivity?.listen(_onConnectivityChange);
  }

  void _init() {
    if (!_disposed) {
      if (tracker.initialized && _periodicTimer == null) {
        _periodicTimer?.cancel();
        _periodicTimer = Stream.periodic(
          blockInterval,
          (computationCount) => computationCount,
        ).listen(_onBlockInternal);
        _onBlockInternal(0);
        _startSyncOffsets();
      } else {
        _checkStatus();
      }
    }
  }

  void emitTrackerOffset(MoneroChainNotify event) {
    if (_disposed) return;
    latestEvent.updateValue = event;
    switch (event) {
      case MoneroChainNotify.syncingStatusChanged:
        onTrackerUpdated(MoneroSyncingEvent.event(event));
        break;
      default:
        break;
    }
  }

  @override
  List<MoneroTrackingOffsetWithStatus> getTrackerOffsets(MoneroSyncTracker tracker) {
    return _offsets.values.where((e) => e.tracker == tracker).toList();
  }

  void _checkStatus() {
    if (_disposed) return;
    BlockSyncStatus status;
    if (_offsets.isEmpty) {
      status = BlockSyncStatusSynced();
    } else {
      status = _offsets.values.firstWhereOrNull((e) => e.status.isErr)?.offsetStatus ??
          BlockSyncStatusPending();
    }
    if (status != this.status) {
      this.status = status;
      emitTrackerOffset(MoneroChainNotify.syncingStatusChanged);
    }
  }

  Future<IResult<T>> callSync<T>(FutureOr<IResult<T>> Function() fn) async {
    return sync.run(() async {
      if (_disposed || _periodicTimer == null || !_isOnline) {
        return ResultErr.fromException(AppInternalError.internalError("moneroSyncing",
            reason: _disposed
                ? "syncing already disposed."
                : _isOnline
                    ? "syncing not initialized."
                    : "no internet connection"));
      }
      final result = await fn();
      _checkStatus();
      return result;
    });
  }

  Future<IResult<void>> _syncUpdated(
      MoneroTrackingOffsetWithStatus request, MoneroSyncOffsetResponse response) async {
    return callSync<void>(() async {
      assert(request.isPending, "Bad request status");
      Future<IResult<MoneroMergeResult>> sync() async {
        if (response.status.synced && response.requestId != null) {
          final utxoKeyImages = response.getUtxoKeyImages();
          final client = await clientCallBack();
          final result = await client.mapCatchAsync((client) async {
            final spendeKeyImages = await client.getSpendedKeyImages(utxoKeyImages);
            response =
                response.copyWith(keyImages: {...response.keyImages, ...spendeKeyImages});
          });
          if (result.isErr) return result.cast();
        }
        IResult<MoneroMergeResult> result =
            await tracker.updateTrackerOffset(response).andThenAsync((offset) async {
          final event = MoneroSyncingEvent.offsetUpdated(offset.account);
          final update = await onTrackerUpdated(event);
          return update.map((e) => offset);
        });
        return await result.mapErrAsync((e) async {
          final update = await onTrackerUpdated(MoneroSyncingEvent.prediocSave());
          if (update.isErr) return update.unwrapErr().exception;
          return e.exception;
        });
      }

      if (!request.isPending) return ResultOk.okVoid;
      final result = await sync();
      bool accountUpdated = false;
      result.watch(
        onOk: (e) {
          final status = e.status.offset.status;
          accountUpdated = e.account.updated;
          switch (status) {
            case BlockSyncStatusSynced():
              request.asComplete();
              _offsets.remove(request.identifier());
              break;
            case BlockSyncStatusError(:final error):
              request.asError(error);
              break;
            case BlockSyncStatusPending():
              break;
          }
          Logging.error(
              when: () => status.isErr,
              fn: () => AppLogData(
                  prefix: "monero_syncing_main",
                  runtime: runtimeType,
                  function: "syncUpdated",
                  msg:
                      "syncUpdated: ${status.cast<BlockSyncStatusError>().error.toDebugMessage()} ${response.toString()}"));
        },
        onErr: (error) {
          request.asError(error.exception);
          Logging.error(
              fn: () => AppLogData(
                  runtime: runtimeType,
                  function: "syncUpdated",
                  prefix: "monero_syncing_main",
                  err: error.exception,
                  trace: error.trace,
                  msg:
                      "syncError: ${response.toString()} error: ${error.exception} status: ${request.offset.status} "));
        },
      );
      emitTrackerOffset(MoneroChainNotify.trackerOffsetUpdated);
      if (accountUpdated) {
        emitTrackerOffset(MoneroChainNotify.accountUtxosChanged);
      }
      _startSyncOffsets();
      return ResultOk.okVoid;
    });
  }

  Future<IResult<void>> _syncClosed(MoneroTrackingOffsetWithStatus request) async {
    return callSync(() {
      request.asIdle();
      Logging.info(
        fn: () => AppLogData(
          runtime: runtimeType,
          function: "syncClosed",
          msg: "sync closed. status:  ${request.status}/${request.offset.status}",
          prefix: "monero_syncing_main",
        ),
      );
      return ResultOk.okVoid;
    });
  }

  Future<IResult<void>> _syncError(
      {required MoneroTrackingOffsetWithStatus request,
      required IException error}) async {
    return callSync(() {
      request.asError(error);
      Logging.error(
        fn: () => AppLogData(
          runtime: runtimeType,
          function: "syncError: ${request.requestId ?? 'default'}, ${request.offset}",
          err: error,
          prefix: "monero_syncing_main",
        ),
      );
      return ResultOk.okVoid;
    });
  }

  Future<IResult<void>> _startSyncOffset(MoneroTrackingOffsetWithStatus offset) async {
    final request = offset.toRequest();
    final secrentKey = await _getScecretKey();
    final controller = await secrentKey.andThenAsync((secrentKey) async {
      final result = switch (request) {
        MoneroBlockTrackingRequestOffset() => await createSyncRequest(
            offset.requestId == null ? SyncWorkerMode.monero : null,
            cancelable,
            maxSyncingInterval)
      };
      return result.map((e) {
        final account = MoneroSyncRequestAccount(
            accounts: offset.accounts, network: tracker.network, secretKeys: secrentKey);
        return (connector: e, account: account);
      });
    });
    final result = await controller.andThenAsync((data) async {
      return callSync(() async {
        final connector = data.connector;
        final subscribtion = connector.stream.listen((event) {
          _syncUpdated(offset, event);
        }, onDone: () {
          _syncClosed(offset);
        });
        offset.addConnector(connector: connector, subscribtion: subscribtion);
        switch (request) {
          case MoneroBlockTrackingRequestOffset():
            return await connector.add(request, data.account.toCbor().encode());
        }
      });
    });
    result.watch(onErr: (e) {
      _syncError(request: offset, error: e.exception);
    });
    return ResultOk.okVoid;
  }

  Future<void> _onBlockInternal(int _) async {
    final client = switch (_isOnline) {
      true => await clientCallBack(),
      false =>
        ResultErr<MoneroNetworkClient>.fromException(APIErrorConst.noNetworkConnection)
    };
    final blockHeight = await client.mapCatchAsync((client) async {
      return await client.getHeight();
    });
    final IResult<int?> update = await blockHeight.andThenAsync((height) async {
      if (height == _latestHeight) {
        return ResultOk<int?>(null);
      }
      final result = await tracker.updateDefaultTrackerHeight(height);
      return result.map((e) => height);
    });
    update.map((height) {
      if (height == null) return;
      _latestHeight = height;
      _startSyncOffsets();
      emitTrackerOffset(MoneroChainNotify.blockHeightUpdated);
    }).mapErr((e) {
      status = BlockSyncStatusError(e.exception);
      emitTrackerOffset(MoneroChainNotify.syncingStatusChanged);
      return e.exception;
    });
  }

  Future<IResult<LongTimeMemorySecretKey>> _getScecretKey() {
    return callSync(() async {
      final secretKey = _secretKey;
      if (secretKey != null) return ResultOk(secretKey);
      final result = await _secretKeyRequestCallback();
      return result.map((secretKey) {
        _secretKey = secretKey;
        return secretKey;
      });
    });
  }

  String _getOffsetIdentifier(BlockTrackingOffset offset, int? requestId) {
    return "${offset.startHeight}_${offset.endHeight}_${requestId ?? -1}";
  }

  Future<IResult<void>> _startSyncOffsets() async {
    return callSync(() async {
      final totalPending = _offsets.values.where((e) => e.status.isPending).length;
      final int totalThread = (maxRequestThread + 1) - totalPending;
      if (totalThread <= 0) return ResultOk.okVoid;
      final trackers = tracker.pendingTrackers();
      for (final tracker in trackers) {
        for (final i in tracker.offsets.offsets) {
          if (i.status.synced) continue;
          final id = _getOffsetIdentifier(i, tracker.requestId);
          if (_offsets.containsKey(id)) continue;
          final account = this.tracker.getSyncRequestAccount(tracker.requestId);
          assert(account != null, "account not found,");
          if (account == null) continue;
          _offsets[id] = MoneroTrackingOffsetWithStatus(
              controller: this.tracker, tracker: tracker, offset: i, accounts: account);
        }
      }

      final pendingOffsets =
          _offsets.values.where((e) => e.status.isIdle).take(totalThread).toList();
      for (final i in pendingOffsets) {
        i.asPending();
        _startSyncOffset(i);
      }
      emitTrackerOffset(MoneroChainNotify.trackerOffsetChanged);
      return ResultOk.okVoid;
    });
  }

  @override
  Future<IResult<void>> dispose() async {
    return callSync(() async {
      _periodicTimer?.cancel();
      _periodicTimer = null;
      _disposed = true;
      latestEvent.dispose();
      for (final i in _offsets.values) {
        i.asIdle();
      }
      return ResultOk.okVoid;
    });
  }

  @override
  Future<IResult<void>> retryErrors() async {
    return callSync(() async {
      for (final i in _offsets.values) {
        i.tryAsIdle();
      }
      _startSyncOffsets();

      return ResultOk.okVoid;
    });
  }

  @override
  Future<IResult<void>> syncRemoved(int requestId) async {
    return callSync(() async {
      final requestOffsets =
          _offsets.values.where((e) => e.requestId == requestId).toList();
      for (final i in requestOffsets) {
        final offset = _offsets.remove(i.identifier());
        offset?.asIdle();
      }
      if (requestOffsets.isNotEmpty) {
        emitTrackerOffset(MoneroChainNotify.trackerOffsetChanged);
        _startSyncOffsets();
      }
      return ResultOk.okVoid;
    });
  }

  @override
  Future<IResult<void>> newRequestImported() async {
    return callSync(() async {
      _startSyncOffsets();
      return ResultOk.okVoid;
    });
  }

  void _onConnectivityChange(bool isOnline) {
    if (_disposed) return;
    sync.run(() {
      _isOnline = isOnline;
      if (!isOnline) {
        for (final i in _offsets.values) {
          i.tryAsIdle();
        }
      } else {
        _startSyncOffsets();
      }
    });
  }

  @override
  Future<IResult<void>> newAccountImported() {
    return sync.run(() async {
      if (_disposed || !tracker.initialized) {
        return ResultErr.fromException(AppInternalError.internalError("moneroSyncing",
            reason:
                _disposed ? "syncing already disposed." : "tracker not initialized."));
      }
      _init();
      final defaultTrackers = _offsets.values
          .where((e) => e.requestId == null)
          .where((e) => e.isPending)
          .toList();
      for (final i in defaultTrackers) {
        i.asIdle();
      }
      _startSyncOffsets();
      return ResultOk.okVoid;
    });
  }

  @override
  int get latestSyncedHeight => tracker.defaultTracker.currentHeight;

  @override
  Duration get maxSyncingInterval => Duration(minutes: 2);
}

enum MoneroPendingTrackerStatus {
  idle,
  pending,
  complete,
  error;

  bool get isPending => this == pending;
  bool get isIdle => this == idle;
  bool get isErr => this == error;
}

class MoneroTrackingOffsetWithStatus with Equality {
  final MoneroSyncTracker tracker;
  final BlockTrackingOffset offset;
  final List<MoneroSyncAccount> accounts;
  final MoneroSyncTrackerController controller;
  int? get requestId => tracker.requestId;
  BlockSyncStatus offsetStatus;
  MoneroPendingTrackerStatus status = MoneroPendingTrackerStatus.idle;
  bool get isPending => status.isPending;
  String identifier() => "${offset.startHeight}_${offset.endHeight}_${requestId ?? -1}";

  MoneroBlockTrackingRequest toRequest() {
    return MoneroBlockTrackingRequestOffset(
        offset: offset,
        requestId: requestId,
        network: controller.network,
        keyImages: controller.keyImages());
  }

  // bool closed = false;
  MoneroTrackingOffsetWithStatus({
    required this.tracker,
    required this.offset,
    required List<MoneroSyncAccount> accounts,
    required this.controller,
  })  : offsetStatus = offset.status,
        accounts = accounts.immutable;
  StreamCryptoRequestController? connector;
  StreamSubscription? subscribtion;

  void closeConnection() {
    connector = null;
    subscribtion?.cancel();
    subscribtion = null;
  }

  void addConnector({
    required StreamCryptoRequestController connector,
    required StreamSubscription subscribtion,
  }) {
    assert(status.isPending);
    assert(this.connector == null);
    assert(this.subscribtion == null);
    this.connector = connector;
    this.subscribtion = subscribtion;
    if (!status.isPending) {
      closeConnection();
    }
  }

  void asPending() {
    assert(status == MoneroPendingTrackerStatus.idle, "Invalid status.");
    if (!status.isIdle) return;
    assert(!offset.status.synced);
    offsetStatus = BlockSyncStatusPending();
    status = MoneroPendingTrackerStatus.pending;
    offset.setAsPending();
  }

  void asError(IException error) {
    if (!status.isPending) return;
    assert(!offset.status.synced, "Invalid offset status");
    offsetStatus = BlockSyncStatusError(error);
    status = MoneroPendingTrackerStatus.error;
    closeConnection();
  }

  void asComplete() {
    assert(offset.status.synced, "Invalid offset status");
    if (!status.isPending) return;
    offsetStatus = BlockSyncStatusSynced();
    status = MoneroPendingTrackerStatus.complete;
    closeConnection();
  }

  void asIdle() {
    if (!status.isPending) return;
    assert(!offset.status.synced, "Invalid offset status");
    offsetStatus = BlockSyncStatusPending();
    status = MoneroPendingTrackerStatus.idle;
    closeConnection();
  }

  void tryAsIdle() {
    if (status != MoneroPendingTrackerStatus.error || offset.status.synced) return;
    status = MoneroPendingTrackerStatus.idle;
  }

  @override
  List<dynamic> get variables => [offset, requestId];

  @override
  String toString() {
    return "offset $offset $status";
  }
}

class MoneroSyncingEvent {
  final MoneroMergeAccountResult? details;
  final bool saveTracker;
  final MoneroChainNotify? event;
  const MoneroSyncingEvent({this.details, this.saveTracker = true, this.event});
  factory MoneroSyncingEvent.offsetUpdated(MoneroMergeAccountResult details) {
    return MoneroSyncingEvent(details: details, saveTracker: true);
  }
  factory MoneroSyncingEvent.prediocSave() => MoneroSyncingEvent(saveTracker: true);
  factory MoneroSyncingEvent.event(MoneroChainNotify event) =>
      MoneroSyncingEvent(event: event);
}
