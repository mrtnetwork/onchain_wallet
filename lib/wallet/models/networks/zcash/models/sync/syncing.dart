import 'dart:async';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/types.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/zcash/clients/client.dart';
import 'package:on_chain_wallet/wallet/chain/chain/chain.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/block/models/offset.dart';
import 'package:on_chain_wallet/wallet/models/block/models/status.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/sync/sync_account.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/sync/tracker.dart';
import 'request.dart';

typedef CbCreateStreamCryptoController = Future<
        IResult<
            StreamCryptoRequestController<ZcashSyncOffsetResponse,
                ZcashBlockTrackingRequestOffset>>>
    Function(SyncWorkerMode? mode, CancelableListener? cancelable, Duration syncingInverval, ZcashSyncTracker tracker);

typedef CbCreateNullifierRequest = Future<
        IResult<
            StreamCryptoRequestController<ZcashSyncNullifierResponse,
                ZcashBlockTrackingRequestNullifier>>>
    Function(CancelableListener? cancelable);
typedef CbMoneroSyncTrackerUpdated = Future<IResult<void>> Function(
    ZcashSyncingEvent event);
typedef CbZcashClient = Future<IResult<ZcashNetworkClient>> Function();

abstract class ZcashSyncing {
  Future<IResult<void>> dispose();
  Future<IResult<void>> syncRemoved(int requestId);
  Future<IResult<void>> newRequestImported();
  Future<IResult<void>> newAccountImported();
  Future<IResult<void>> retryErrors();
  List<ZcashTrackingOffsetWithStatus> getTrackerOffsets(ZcashSyncTracker tracker);
  BlockSyncStatus get status;
  StreamValue<ZcashChainNotify> get latestEvent;
  int? get latestHeight;
  int get latestSyncedHeight;
  Duration get maxSyncingInterval;
}

class ZcashSyncingDefault implements ZcashSyncing {
  final SafeAtomicLock sync = SafeAtomicLock();
  final ZcashSyncTrackerController tracker;
  final CbCreateStreamCryptoController createSyncRequest;
  final CbCreateNullifierRequest createNullifierRequest;
  final CbMoneroSyncTrackerUpdated onTrackerUpdated;
  final Duration blockInterval;
  final int maxRequestThread;
  @override
  final StreamValue<ZcashChainNotify> latestEvent = StreamValue<ZcashChainNotify>(
      ZcashChainNotify.syncingStatusChanged,
      name: "ZcashSyncingDefault");
  @override
  BlockSyncStatus status = BlockSyncStatusPending();
  final cancelable = CancelableListener();
  // int get maxThread => tracker.maxThread;
  final CbZcashClient clientCallBack;
  StreamSubscription<dynamic>? _periodicTimer;
  bool _disposed = false;
  bool _isOnline = true;
  int? _latestHeight;

  @override
  int? get latestHeight => _latestHeight;
  final Map<String, ZcashTrackingOffsetWithStatus> _offsets = {};
  ZcashSyncingDefault({
    required this.tracker,
    required this.createSyncRequest,
    required this.createNullifierRequest,
    required this.onTrackerUpdated,
    required this.clientCallBack,
    required WalletZcashNetwork network,
    required Stream<bool>? connectivity,
    required this.maxRequestThread,
  }) : blockInterval = Duration(seconds: network.coinParam.syncingBlockInterval) {
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

  void emitTrackerOffset(ZcashChainNotify event) {
    latestEvent.value = event;
    switch (event) {
      case ZcashChainNotify.syncingStatusChanged:
        onTrackerUpdated(ZcashSyncingEvent.event(event));
        break;
      default:
        break;
    }
  }

  @override
  List<ZcashTrackingOffsetWithStatus> getTrackerOffsets(ZcashSyncTracker tracker) {
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
      emitTrackerOffset(ZcashChainNotify.syncingStatusChanged);
    }
  }

  Future<IResult<T>> callSync<T>(FutureOr<IResult<T>> Function() fn) async {
    return sync.run(() async {
      if (_disposed || _periodicTimer == null || !_isOnline) {
        return ResultErr.fromException(AppInternalError.internalError("zcashSyncing",
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
      ZcashTrackingOffsetWithStatus request, ZcashBlockSyncedOffset response) async {
    return callSync<void>(() async {
      assert(request.isPending, "Bad request status");
      if (!request.isPending) return ResultOk.okVoid;
      final update = tracker.updateTrackerOffset(response);
      IResult<ZcashMergeResult> result = await update.andThenAsync((offset) async {
        final event = ZcashSyncingEvent.offsetUpdated(offset.account);
        final update = await onTrackerUpdated(event);
        return update.map((e) => offset);
      });
      result = await result.mapErrAsync((e) async {
        final update = await onTrackerUpdated(ZcashSyncingEvent.prediocSave());
        if (update.isErr) return update.unwrapErr().exception;
        return e.exception;
      });
      bool accountUpdated = false;
      result.watch(
        onOk: (e) {
          final status = e.status.offset.status;
          accountUpdated = e.account.updated;
          switch (status) {
            case BlockSyncStatusSynced():
              request.asComplete();
              _offsets.remove(request.identifier());
              if (e.phase != request.phase) {
                for (final i in _offsets.values) {
                  if (i.requestId == null && i.isPending) {
                    i.asIdle();
                  }
                }
              }
              break;
            case BlockSyncStatusError(:final error):
              request.asError(error);
              Logging.error(
                  when: () => status.isErr,
                  fn: () => AppLogData(
                      prefix: "zcash_syncing_main",
                      runtime: runtimeType,
                      function: "syncUpdated",
                      err: error,
                      msg:
                          "syncUpdated: {id:${request.requestId ?? "default"}, status: $status, response:${response.toString()} data:$update}"));
              break;
            case BlockSyncStatusPending():
              break;
          }
        },
        onErr: (error) {
          request.asError(error.exception);
          Logging.error(
              fn: () => AppLogData(
                  runtime: runtimeType,
                  function: "syncUpdated",
                  prefix: "zcash_syncing_main",
                  err: error.exception,
                  trace: error.trace,
                  msg:
                      "syncError:{id:${request.requestId ?? "default"}, response: ${response.toString()}, error:${error.exception}, status:${request.offset.status} }"));
        },
      );
      emitTrackerOffset(ZcashChainNotify.trackerOffsetUpdated);
      if (accountUpdated) {
        emitTrackerOffset(ZcashChainNotify.accountUtxosChanged);
      }
      _startSyncOffsets();
      return ResultOk.okVoid;
    });
  }

  Future<IResult<void>> _syncClosed(ZcashTrackingOffsetWithStatus request) async {
    return callSync(() {
      request.asIdle();
      return ResultOk.okVoid;
    });
  }

  Future<IResult<void>> _syncError(
      {required ZcashTrackingOffsetWithStatus request, required IException error}) async {
    return callSync(() {
      request.asError(error);
      Logging.error(
        fn: () => AppLogData(
          runtime: runtimeType,
          function: "syncError: ${request.requestId ?? 'default'}, ${request.offset}",
          err: error,
          prefix: "zcash_syncing_main",
        ),
      );
      return ResultOk.okVoid;
    });
  }

  Future<IResult<void>> _startSyncOffset(ZcashTrackingOffsetWithStatus offset) async {
    final r = offset.toRequest();

    final request = switch (r) {
      ZcashBlockTrackingRequestOffset() => await createSyncRequest(
          offset.requestId == null ? SyncWorkerMode.zcash : null,
          cancelable,
          maxSyncingInterval,
          offset.tracker),
      ZcashBlockTrackingRequestNullifier() => await createNullifierRequest(cancelable),
    };
    final result = await request.andThenAsync((connector) async {
      return callSync(() async {
        final subscribtion = connector.stream.listen((event) {
          _syncUpdated(offset, event);
        }, onDone: () {
          _syncClosed(offset);
        });
        offset.addConnector(connector: connector, subscribtion: subscribtion);
        return await connector.add(r, offset.account.toCbor().encode());
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
        ResultErr<ZcashNetworkClient>.fromException(APIErrorConst.noNetworkConnection)
    };
    final blockHeight = await client.mapCatchAsync((client) async {
      return await client.getLatestBlockHeight();
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
      emitTrackerOffset(ZcashChainNotify.blockHeightUpdated);
    }).mapErr((e) {
      status = BlockSyncStatusError(e.exception);
      emitTrackerOffset(ZcashChainNotify.syncingStatusChanged);
      return e.exception;
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
          _offsets[id] = ZcashTrackingOffsetWithStatus(
              controller: this.tracker,
              tracker: tracker,
              offset: i,
              account: account,
              phase: tracker.phase);
        }
      }

      final pendingOffsets =
          _offsets.values.where((e) => e.status.isIdle).take(totalThread).toList();
      for (final i in pendingOffsets) {
        i.asPending();
        _startSyncOffset(i);
      }
      emitTrackerOffset(ZcashChainNotify.trackerOffsetChanged);
      return ResultOk.okVoid;
    });
  }

  // Future<IResult<void>> _init(WalletZcashNetwork network) async {
  //   return callSync(() async {

  //     return ResultOk.okVoid;
  //   });
  // }

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
        emitTrackerOffset(ZcashChainNotify.trackerOffsetChanged);
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
        return ResultErr.fromException(AppInternalError.internalError("zcashSyncing",
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

enum ZcashPendingTrackerStatus {
  idle,
  pending,
  complete,
  error;

  bool get isPending => this == pending;
  bool get isIdle => this == idle;
  bool get isErr => this == error;
}

class ZcashTrackingOffsetWithStatus with Equality {
  // final ZcashBlockTrackingRequest request;
  final ZcashSyncTracker tracker;
  final BlockTrackingOffset offset;
  final ZcashSyncRequestAccount account;
  final ZcashSyncTrackerController controller;
  final ZcashSyncRequestPhase phase;
  int? get requestId => tracker.requestId;
  BlockSyncStatus offsetStatus;
  ZcashPendingTrackerStatus status = ZcashPendingTrackerStatus.idle;
  bool get isPending => status.isPending;
  String identifier() => "${offset.startHeight}_${offset.endHeight}_${requestId ?? -1}";

  ZcashBlockTrackingRequest toRequest() {
    final nullifiers = controller.utxosNullifiers(requestId);
    return switch (phase) {
      ZcashSyncRequestPhase.utxos => ZcashBlockTrackingRequestOffset(
          offset: offset, requestId: requestId, utxoNullifiers: nullifiers),
      ZcashSyncRequestPhase.nullifiers => ZcashBlockTrackingRequestNullifier(
          offset: offset,
          requestId: requestId ?? -1,
          utxoNullifiers: nullifiers,
          network: controller.network),
    };
  }

  // bool closed = false;
  ZcashTrackingOffsetWithStatus({
    required this.phase,
    required this.tracker,
    required this.offset,
    required this.account,
    required this.controller,
  }) : offsetStatus = offset.status;
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
    assert(status == ZcashPendingTrackerStatus.idle, "Invalid status.");
    if (!status.isIdle) return;
    assert(!offset.status.synced);
    offsetStatus = BlockSyncStatusPending();
    status = ZcashPendingTrackerStatus.pending;
    offset.setAsPending();
  }

  void asError(IException error) {
    if (!status.isPending) return;
    assert(!offset.status.synced, "Invalid offset status");
    offsetStatus = BlockSyncStatusError(error);
    status = ZcashPendingTrackerStatus.error;
    closeConnection();
  }

  void asComplete() {
    assert(offset.status.synced, "Invalid offset status");
    if (!status.isPending) return;
    offsetStatus = BlockSyncStatusSynced();
    status = ZcashPendingTrackerStatus.complete;
    closeConnection();
  }

  void asIdle() {
    if (!status.isPending) return;
    assert(!offset.status.synced, "Invalid offset status");
    offsetStatus = BlockSyncStatusPending();
    status = ZcashPendingTrackerStatus.idle;
    closeConnection();
  }

  void tryAsIdle() {
    if (status != ZcashPendingTrackerStatus.error || offset.status.synced) return;
    status = ZcashPendingTrackerStatus.idle;
  }

  @override
  List<dynamic> get variables => [offset, requestId];

  @override
  String toString() {
    return "offset $offset $status";
  }
}

class ZcashSyncingEvent {
  final ZcashMergeAccountResult? details;
  final bool saveTracker;
  final ZcashChainNotify? event;
  const ZcashSyncingEvent({this.details, this.saveTracker = true, this.event});
  factory ZcashSyncingEvent.offsetUpdated(ZcashMergeAccountResult details) {
    return ZcashSyncingEvent(details: details, saveTracker: true);
  }
  factory ZcashSyncingEvent.prediocSave() => ZcashSyncingEvent(saveTracker: true);
  factory ZcashSyncingEvent.event(ZcashChainNotify event) =>
      ZcashSyncingEvent(event: event);
}
