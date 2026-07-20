import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/account/account.dart';
import 'package:on_chain_wallet/wallet/models/block/models/offset.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/sync/sync_account.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/account/utxos.dart';
import 'package:zcash_dart/zcash.dart';

import 'request.dart';

sealed class ZcashSyncTracker with AppSerialization {
  BlockSyncingOffsets _offsets;
  BlockSyncingOffsets get offsets => _offsets;
  final DateTime created;
  List<ZcashSyncAccountIndex> get accountIndexes;
  int get startHeight => offsets.startHeight;
  int get endHeight => offsets.endHeight;
  int get currentHeight => offsets.currentHeight;
  int? get requestId;
  ZcashSyncRequestPhase get phase;
  ZcashSyncTracker({required BlockSyncingOffsets offsets, required this.created})
      : _offsets = offsets;

  BlockTrackingOffset? findOffset(BlockTrackingOffset offset) {
    return offsets.offsets.firstWhereOrNull((e) => e == offset);
  }
}

enum ZcashSyncRequestPhase {
  utxos(0),
  nullifiers(1);

  final int value;
  const ZcashSyncRequestPhase(this.value);
  bool get inNullifier => this == nullifiers;
  static ZcashSyncRequestPhase fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw AppInternalError.internalError("ZcashSyncRequestPhase",
          reason: "Unknown ZcashSyncRequestPhase value."),
    );
  }
}

class ZcashSyncRequestTracker extends ZcashSyncTracker {
  @override
  final int requestId;
  @override
  final int startHeight;
  @override
  final int endHeight;
  ZcashSyncRequestPhase _phase;
  @override
  ZcashSyncRequestPhase get phase => _phase;
  Set<ZcashAccountInfoShield> _accounts;
  Set<ZcashAccountInfoShield> get accounts => _accounts;
  // BlockSyncingOffsets? get nullifierOffset => _nullifierOffset;

  ZcashSyncRequestTracker.__(
      {required super.offsets,
      required super.created,
      required this.startHeight,
      required this.endHeight,
      required Iterable<ZcashAccountInfoShield> accounts,
      required this.requestId,
      required ZcashSyncRequestPhase phase})
      : _accounts = accounts.toImutableSet,
        _phase = phase;
  factory ZcashSyncRequestTracker._({
    required BlockSyncingOffsets offsets,
    required DateTime created,
    required Iterable<ZcashAccountInfoShield> accounts,
    required ZcashSyncRequestPhase phase,
    required int startHeight,
    required int endHeight,
  }) {
    final id = offsets.requestId;
    if (id == null) {
      throw AppInternalError.internalError("ZcashSyncRequestTracker",
          reason: "missing request id.");
    }
    return ZcashSyncRequestTracker.__(
        offsets: offsets,
        created: created,
        accounts: accounts,
        requestId: id,
        phase: phase,
        startHeight: startHeight,
        endHeight: endHeight);
  }
  factory ZcashSyncRequestTracker.start({
    required int startHeight,
    required int endHeight,
    required int requestId,
    required Set<ZcashAccountInfoShield> accounts,
  }) {
    return ZcashSyncRequestTracker._(
        offsets: BlockSyncingOffsets.buildRequest(
            startHeight: startHeight, endHeight: endHeight, requestId: requestId),
        created: DateTime.now(),
        accounts: accounts,
        phase: ZcashSyncRequestPhase.utxos,
        startHeight: startHeight,
        endHeight: endHeight);
  }

  factory ZcashSyncRequestTracker.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.zcashSyncRequestTracker);
    final offset = BlockSyncingOffsets.deserialize(object: values.objectAt(0));
    return ZcashSyncRequestTracker._(
        offsets: offset,
        created: values.rawValueAt<DateTime>(1),
        accounts: values
            .listAt<CborTagValue>(2)
            .map((e) => ZcashAccountInfoShield.deserialize(object: e))
            .toList(),
        phase: ZcashSyncRequestPhase.fromValue(values.rawValueAt(3)),
        startHeight: values.rawValueAt<int>(4),
        endHeight: values.rawValueAt<int>(5));
  }

  /// remove account from request and return false if request accounts is empty.
  bool removeAccount(ZcashAccountInfoShield account) {
    if (!_accounts.contains(account)) return _accounts.isNotEmpty;
    final accounts = _accounts.clone();
    accounts.remove(account);
    _accounts = accounts.toImutableSet;
    return _accounts.isNotEmpty;
  }

  IResult<ZcashMergeResult> updateOffset(
      {required ZcashBlockSyncedOffset offset,
      required ZcashSyncTrackerController controller}) {
    if (offset.requestId != requestId) {
      return ResultErr.fromException(AppInternalError.internalError(
          "ZcashSyncRequestTracker.updateOffset",
          reason: "Invalid offset request id."));
    }
    switch (offset) {
      case ZcashSyncOffsetResponse():
        if (phase.inNullifier) {
          return ResultErr.fromException(AppInternalError.internalError(
              "ZcashSyncRequestTracker.updateOffset",
              reason: "offset already synced"));
        }
        final clone = offsets.clone();
        final result = offsets.updateOffset(offset);

        return result.andThen((status) {
          ZcashMergeAccountResult merge = ZcashMergeAccountResult();
          for (final i in offset.accounts) {
            final account = controller.getAccountFromFullViewingKey(i.derivationKey);
            if (account == null) continue;
            merge += account.mergeWithSyncingUtxosReponse(indexes: i.indexes);
          }
          if (offset.nullifiers.isNotEmpty) {
            final syncAccounts = controller.defaultTracker.syncAccounts;
            bool updated = false;
            for (final i in syncAccounts) {
              updated |= i.mergeNullifierReponse(offset.nullifiers);
            }
            merge = ZcashMergeAccountResult(
                utxos: merge.utxos, updated: updated | merge.updated);
          }
          if (!status.offsetsStatus.synced) {
            return ResultOk(
                ZcashMergeResult(account: merge, status: status, phase: phase));
          }
          final nullifierOffset = controller.buildNullifierOffset(requestId);

          return nullifierOffset.mapErr((e) {
            _offsets = clone;
            return e.exception;
          }).map((e) {
            _offsets = e;
            _phase = ZcashSyncRequestPhase.nullifiers;
            if (_offsets.status.synced) {
              bool updated = false;
              for (final i in controller.defaultTracker._syncAccount) {
                updated |= i.mergeRequestUtxos(requestId);
              }
              merge = ZcashMergeAccountResult(
                  updated: merge.updated | updated, utxos: merge.utxos);
            }
            return ZcashMergeResult(
                account: merge,
                phase: phase,
                status: UpdateOffsetResult(
                    offset: status.offset, offsetsStatus: _offsets.status));
          });
        });
      case ZcashSyncNullifierResponse(:final nullifiers):
        // final nullifierOffset = _nullifierOffset;
        if (!phase.inNullifier) {
          return ResultErr.fromException(AppInternalError.internalError(
              "ZcashSyncRequestTracker.updateOffset",
              reason: "nullifierOffset not available."));
        }
        final update = offsets.updateOffset(offset);
        return update.map((status) {
          bool updated = false;
          final indexes = accountIndexes;
          final syncAccounts = controller.defaultTracker.syncAccounts;
          for (final i in syncAccounts) {
            for (final index in indexes) {
              if (i.indexes.contains(index)) {
                updated |= i.mergeNullifierReponse(nullifiers);
                if (status.offsetsStatus.synced) {
                  updated |= i.mergeRequestUtxos(requestId);
                }
                break;
              }
            }
          }
          return ZcashMergeResult(
              account: ZcashMergeAccountResult(utxos: [], updated: updated),
              status: status,
              phase: phase);
        });
    }
  }

  List<BlockTrackingOffset> pendingOffsets() {
    return offsets.offsets.where((e) => !e.status.synced).toList();
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.zcashSyncRequestTracker;

  @override
  List<CborObject?> get serializationItems => [
        offsets.toCbor(),
        created.toCbor(),
        AppSerialization.listFromObjects(_accounts.map((e) => e.toCbor()).toList()),
        phase.value.toCbor(),
        startHeight.toCbor(),
        endHeight.toCbor()
      ];

  @override
  List<ZcashSyncAccountIndex> get accountIndexes => accounts
      .map((e) => ZcashSyncAccountIndex(index: e, startHeight: startHeight))
      .toList();
}

class ZcashSyncDefaultTracker extends ZcashSyncTracker {
  final bool initialized;
  Set<ZcashSyncAccount> _syncAccount;
  Set<ZcashSyncAccount> get syncAccounts => _syncAccount;

  @override
  ZcashSyncRequestPhase get phase => ZcashSyncRequestPhase.utxos;
  @override
  int? get requestId => null;
  List<ZcashAccountInfoShield> get accounts =>
      _syncAccount.expand((e) => e.accounts).toList();

  ZcashSyncDefaultTracker.__({
    required super.offsets,
    required super.created,
    required this.initialized,
    required Iterable<ZcashSyncAccount> accounts,
  }) : _syncAccount = accounts.toImutableSet;

  factory ZcashSyncDefaultTracker.start() {
    return ZcashSyncDefaultTracker.__(
        offsets: BlockSyncingOffsets.buildDefault(startHeight: 0, endHeight: 0),
        created: DateTime.now(),
        accounts: [],
        initialized: false);
  }

  factory ZcashSyncDefaultTracker._(
      {required BlockSyncingOffsets offsets,
      required DateTime created,
      required List<ZcashSyncAccount> accounts,
      required bool initialized}) {
    final id = offsets.requestId;
    if (id != null) {
      throw AppInternalError.internalError("ZcashSyncDefaultTracker");
    }
    return ZcashSyncDefaultTracker.__(
        offsets: offsets, created: created, accounts: accounts, initialized: initialized);
  }

  factory ZcashSyncDefaultTracker.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.zcashSyncDefaultTracker);
    return ZcashSyncDefaultTracker._(
        offsets: BlockSyncingOffsets.deserialize(object: values.objectAt(0)),
        created: values.rawValueAt<DateTime>(1),
        accounts: values
            .listAt<CborTagValue>(2)
            .map((e) => ZcashSyncAccount.deserialize(object: e))
            .toList(),
        initialized: values.rawValueAt(3));
  }

  void addAccount(
      DiversifiableFullViewingKey derivationKey, ZcashAccountInfoShield info) {
    if (info.protocol != derivationKey.protocol) {
      throw WalletExceptionConst.invalidAccountData("Missmatch address protocol.");
    }
    ZcashSyncAccount? syncAccount =
        syncAccounts.firstWhereNullable((e) => e.derivationKey == derivationKey);
    if (syncAccount == null) {
      syncAccount = ZcashSyncAccount(derivationKey: derivationKey);
      _syncAccount = {..._syncAccount, syncAccount}.toImutableSet;
    }
    syncAccount
        .addIndex(ZcashSyncAccountIndex(index: info, startHeight: offsets.currentHeight));
  }

  bool removeAccount(ZcashAccountInfoShield account) {
    final ZcashSyncAccount? syncAccount =
        syncAccounts.firstWhereNullable((e) => e.indexes.any((e) => e.index == account));
    if (syncAccount != null) {
      final hasAccount = syncAccount.removeIndex(account);
      if (!hasAccount) {
        _syncAccount = _syncAccount.where((e) => e != syncAccount).toImutableSet;
      }
    }
    return _syncAccount.isNotEmpty;
  }

  bool resetAccountIndex(ZcashAccountInfoShield account, int index) {
    final ZcashSyncAccount? syncAccount =
        syncAccounts.firstWhereNullable((e) => e.indexes.any((e) => e.index == account));
    if (syncAccount != null) {
      syncAccount.resetAccountIndex(account, index);
      return true;
    }
    return false;
  }

  ZcashSyncAccountIndex? findSyncAccountIndex(ZcashAccountInfoShield index) {
    for (final a in _syncAccount) {
      if (a.derivationKey.protocol != index.protocol) continue;
      for (final i in a.indexes) {
        if (i.index == index) return i;
      }
    }
    assert(false, "index does not exist.");
    return null;
  }

  List<ZcashUtxoShield> getAccountUtxos(ZcashAccountInfoShield index) {
    final account = findSyncAccountIndex(index);
    return account?.utxos.toList() ?? [];
  }

  List<ZcashUtxoShield> getAccountPendingUtxos(ZcashAccountInfoShield index) {
    final account = findSyncAccountIndex(index);
    return account?.utxos.toList() ?? [];
  }

  List<ZcashUtxoShield> pendingUtxos(ZcashAccountInfoShield index) {
    final account = findSyncAccountIndex(index);
    return account?.pendingUtxos() ?? [];
  }

  List<ZcashUtxoShield> getAccountInfoUtxos(ZcashDerivedAccountInfo account) {
    final shielded = account.shieldAccounts();
    return shielded.expand((e) => getAccountUtxos(e)).toList();
  }

  ZcashSyncAccount? getAccountFromFullViewingKey(
      DiversifiableFullViewingKey derivationKey) {
    final account =
        _syncAccount.firstWhereOrNull((e) => e.derivationKey == derivationKey);
    Logging.error(
        when: () => account == null,
        fn: () => AppLogData(
            runtime: runtimeType,
            function: "getAccountFromFullViewingKey",
            msg: "account not found ${derivationKey.protocol}"));
    return account;
  }

  IResult<void> updateHeight(int height) {
    if (!initialized || height < endHeight) {
      return ResultErr.fromException(WalletExceptionConst.badAccountSyncingConfiguration);
    }
    return offsets.updateHeight(height);
  }

  ZcashSyncDefaultTracker resetState({required int height, bool initialized = true}) {
    final offset =
        BlockSyncingOffsets.buildDefault(startHeight: height, endHeight: height);
    return ZcashSyncDefaultTracker.__(
        offsets: offset,
        created: DateTime.now(),
        accounts: syncAccounts.map((e) => e.resetState(height)),
        initialized: initialized);
  }

  IResult<ZcashMergeResult> updateOffset(ZcashBlockSyncedOffset offset) {
    if (offset.requestId != null) {
      return ResultErr.fromException(AppInternalError.internalError(
          "ZcashSyncDefaultTracker.updateOffset",
          reason: "Invalid offset. request id must be null"));
    }
    switch (offset) {
      case ZcashSyncOffsetResponse():
        final result = offsets.updateOffset(offset);
        return result.map((status) {
          ZcashMergeAccountResult merge = ZcashMergeAccountResult();
          for (final i in offset.accounts) {
            final account = getAccountFromFullViewingKey(i.derivationKey);
            if (account == null) continue;
            merge += account.mergeWithSyncingUtxosReponse(indexes: i.indexes);
          }
          if (offset.nullifiers.isNotEmpty) {
            final syncAccounts = this.syncAccounts;
            bool updated = false;
            for (final i in syncAccounts) {
              updated |= i.mergeNullifierReponse(offset.nullifiers);
            }
            merge = ZcashMergeAccountResult(
                utxos: merge.utxos, updated: updated | merge.updated);
          }

          return ZcashMergeResult(account: merge, status: status, phase: phase);
        });
      case ZcashSyncNullifierResponse():
        return ResultErr.fromException(AppInternalError.internalError(
            "ZcashSyncDefaultTracker.updateOffset",
            reason: "Invalid offset."));
    }
  }

  List<BlockTrackingOffset> pendingOffsets() {
    return offsets.offsets.where((e) => !e.status.synced).toList();
  }

  void removeRequestUtxos(int requestId) {
    for (final i in syncAccounts) {
      i.removeRequestUtxos(requestId);
    }
  }

  List<Nullifier> utxosNullifiers(int? id) {
    return syncAccounts.expand((e) => e.utxosNullifiers(id)).toList();
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.zcashSyncDefaultTracker;

  @override
  List<CborObject?> get serializationItems => [
        offsets.toCbor(),
        created.toCbor(),
        AppSerialization.listFromObjects(_syncAccount.map((e) => e.toCbor()).toList()),
        initialized.toCbor()
      ];

  @override
  List<ZcashSyncAccountIndex> get accountIndexes =>
      _syncAccount.expand((e) => e.indexes).toList();
}

class ZcashSyncTrackerController with AppSerialization {
  final ZcashNetwork network;
  int _latestTrackerId;
  List<ZcashSyncRequestTracker> _requestsTrackers;
  ZcashSyncDefaultTracker _defaultTracker;
  final _lock = SafeAtomicLock();
  final Map<int?, ZcashSyncRequestAccount> _cachedRequestAccounts = {};
  bool get initialized => _defaultTracker.initialized;
  ZcashSyncDefaultTracker get defaultTracker => _defaultTracker;
  List<ZcashSyncRequestTracker> get requestTrackers => _requestsTrackers;

  ZcashSyncTrackerController(
      {required this.network,
      required ZcashSyncDefaultTracker defaultTracker,
      required List<ZcashSyncRequestTracker> requestTrackers,
      required int latestTrackerId})
      : _defaultTracker = defaultTracker,
        _requestsTrackers = requestTrackers.immutable,
        _latestTrackerId = latestTrackerId;
  factory ZcashSyncTrackerController.start(ZcashNetwork network) {
    return ZcashSyncTrackerController(
        network: network,
        defaultTracker: ZcashSyncDefaultTracker.start(),
        requestTrackers: [],
        latestTrackerId: 1);
  }
  factory ZcashSyncTrackerController.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.zcashSyncController);
    return ZcashSyncTrackerController(
        network: ZcashNetwork.fromValue(values.rawValueAt(0)),
        defaultTracker: ZcashSyncDefaultTracker.deserialize(object: values.objectAt(1)),
        requestTrackers: values
            .listAt<CborTagValue>(2)
            .map((e) => ZcashSyncRequestTracker.deserialize(object: e))
            .toList(),
        latestTrackerId: values.rawValueAt(3));
  }
  bool accountExists(ZcashAccountInfoShield shield) {
    return _defaultTracker.syncAccounts.any((e) => e.accounts.contains(shield));
  }

  ZcashSyncAccount? getAccountFromFullViewingKey(
      DiversifiableFullViewingKey derivationKey) {
    return _defaultTracker.getAccountFromFullViewingKey(derivationKey);
  }

  List<ZcashUtxoShield> getAccountUtxos(ZcashAccountInfoShield index) {
    return _defaultTracker.getAccountUtxos(index);
  }

  List<ZcashUtxoShield> getAccountPendingUtxos(ZcashAccountInfoShield index) {
    return _defaultTracker.getAccountPendingUtxos(index);
  }

  List<ZcashUtxoShield> getAccountInfoUtxos(ZcashDerivedAccountInfo account) {
    return _defaultTracker.getAccountInfoUtxos(account);
  }

  Future<IResult<void>> addAccount(
      DiversifiableFullViewingKey derivationKey, ZcashAccountInfoShield info) {
    return _lock.run(() async {
      _defaultTracker.addAccount(derivationKey, info);
      _cachedRequestAccounts.remove(null);
      return ResultOk.okVoid;
    });
  }

  Future<IResult<void>> removeAccount(ZcashAccountInfoShield account) async {
    return _lock.run(() async {
      _defaultTracker.removeAccount(account);
      final requests = _requestsTrackers.clone();
      for (final i in requests) {
        if (!i.removeAccount(account)) {
          _requestsTrackers = requests.where((e) => e != i).toImutableList;
          _cachedRequestAccounts.remove(i.requestId);
        }
      }
      _cachedRequestAccounts.remove(null);
      return ResultOk.okVoid;
    });
  }

  IResult<int> addSyncRequestInternal({
    required int startHeight,
    required int endHeight,
    required Set<ZcashAccountInfoShield> accounts,
  }) {
    final existAccounts = _defaultTracker.accounts;
    for (final i in accounts) {
      if (!existAccounts.contains(i)) {
        return ResultErr.fromException(WalletExceptionConst.accountDoesNotFound);
      }
    }
    if (startHeight > endHeight) {
      return ResultErr.fromException(
          AppInternalError.internalError("ZcashRequestBlockTrackingInfo"));
    }
    final ids = _requestsTrackers.map((e) => e.requestId).toList()..sort();
    int requestId = _latestTrackerId;
    while (ids.contains(requestId)) {
      requestId++;
    }
    final request = ZcashSyncRequestTracker.start(
        startHeight: startHeight,
        endHeight: endHeight,
        requestId: requestId,
        accounts: accounts);
    _requestsTrackers = [..._requestsTrackers, request].toImutableList;
    _latestTrackerId = requestId;
    return ResultOk(requestId);
  }

  Future<IResult<int>> addSyncRequest({
    required int startHeight,
    required int endHeight,
    required Set<ZcashAccountInfoShield> accounts,
  }) async {
    return await _lock.run(() async {
      return addSyncRequestInternal(
          startHeight: startHeight, endHeight: endHeight, accounts: accounts);
    });
  }

  Future<IResult<ZcashSyncRequestTracker?>> removeRequest(int requestId) {
    return _lock.run(() async {
      final request = _requestsTrackers.firstWhereOrNull((e) => e.requestId == requestId);
      assert(request != null, "unknow request id. request does not exists.");
      if (request == null) return ResultOk(null);
      _defaultTracker.removeRequestUtxos(requestId);
      _requestsTrackers = _requestsTrackers.where((e) => e != request).toImutableList;
      _cachedRequestAccounts.remove(requestId);
      return ResultOk(request);
    });
  }

  /// Remove everything, must be called afrer all wallet account removed.
  Future<IResult<void>> toDefaultState() {
    return _lock.run(() async {
      _defaultTracker = ZcashSyncDefaultTracker.start();
      _requestsTrackers = [];
      _cachedRequestAccounts.clear();
      return ResultOk.okVoid;
    });
  }

  /// reset default tracker to current height
  /// all utxos and nullifiers will be removed.
  Future<IResult<bool>> resetDefaultTrackerState(
      {required int height,
      required int currentHeight,
      Set<ZcashAccountInfoShield>? accounts}) async {
    // accounts = accounts?.toSet().toList();
    return await _lock.run(() async {
      if (height.isNegative || currentHeight < height) {
        return ResultErr.fromException(AppInternalError.internalError("initializeTracker",
            details: {"height": "$height"}));
      }
      if (currentHeight >= defaultTracker.endHeight && accounts != null) {
        if (height > _defaultTracker.endHeight) {
          return ResultErr.fromException(AppInternalError.internalError(
              "initializeTracker",
              details: {"height": "$height"}));
        }
        int? id;
        if (height < _defaultTracker.currentHeight) {
          final result = addSyncRequestInternal(
              startHeight: height,
              endHeight: _defaultTracker.currentHeight,
              accounts: accounts);
          if (result.isErr) return result.cast();
          id = result.unwrap();
        }
        int totalAccount = 0;
        for (final i in accounts) {
          bool reset = _defaultTracker.resetAccountIndex(i, height);
          if (reset) totalAccount++;
        }
        List<ZcashSyncRequestTracker> trackers = [];
        for (final i in _requestsTrackers) {
          if (id != null && i.requestId == id) {
            trackers.add(i);
            continue;
          }
          if (i._accounts.any((e) => accounts.contains(e))) continue;
          trackers.add(i);
        }

        _requestsTrackers = trackers.toImutableList;
        _cachedRequestAccounts.clear();

        return ResultOk(_defaultTracker.accountIndexes.length == totalAccount);
      }
      _defaultTracker = _defaultTracker.resetState(height: height);
      _requestsTrackers = [];
      _cachedRequestAccounts.clear();
      return ResultOk(true);
    });
  }

  Future<IResult<void>> updateDefaultTrackerHeight(int height) async {
    return await _lock.run(() async {
      return _defaultTracker.updateHeight(height);
    });
  }

  IResult<BlockSyncingOffsets> buildNullifierOffset(int requestId) {
    final request = _requestsTrackers.firstWhereNullable((e) => e.requestId == requestId);
    if (request == null) {
      return ResultErr.fromException(AppInternalError.internalError(
          "buildNullifierOffset",
          reason: "request not found"));
    }
    if (!request.offsets.status.synced || request.phase.inNullifier) {
      return ResultErr.fromException(AppInternalError.internalError(
          "buildNullifierOffset",
          reason: "Bad tracker state"));
    }
    final cDefaultOffset = _defaultTracker.offsets.currentHeight;
    if (cDefaultOffset < request.offsets.endHeight) {
      return ResultErr.fromException(AppInternalError.internalError(
          "buildNullifierOffset",
          reason: "Bad tracker offset"));
    }
    final haveUtxos =
        _defaultTracker.syncAccounts.any((e) => e.requstHaveUtxos(requestId));
    if (haveUtxos) {
      return ResultOk(BlockSyncingOffsets.buildRequest(
          startHeight: request.offsets.endHeight,
          endHeight: cDefaultOffset,
          requestId: requestId,
          currentHeight: request.offsets.endHeight));
    }
    return ResultOk(BlockSyncingOffsets.buildRequest(
        startHeight: request.offsets.endHeight,
        endHeight: cDefaultOffset,
        requestId: requestId,
        currentHeight: cDefaultOffset));
  }

  IResult<ZcashMergeResult> updateTrackerOffset(ZcashBlockSyncedOffset offset) {
    final id = offset.requestId;
    if (id != null) {
      final request = _requestsTrackers.firstWhereNullable((e) => e.requestId == id);
      if (request == null) {
        return ResultErr.fromException(AppInternalError.internalError(
            "_updateTrackerOffset",
            reason: "request not found"));
      }

      return request.updateOffset(offset: offset, controller: this);
    }
    return _defaultTracker.updateOffset(offset);
  }

  ZcashSyncRequestAccount? getSyncRequestAccount(int? requestId) {
    final id = requestId;
    final cached = _cachedRequestAccounts[id];
    if (cached != null) return cached;
    if (id == null) {
      return _cachedRequestAccounts[id] = ZcashSyncRequestAccount(
          accounts: _defaultTracker.syncAccounts.map((e) => e.toRequest()).toList(),
          network: network);
    }
    final request = _requestsTrackers.firstWhereOrNull((e) => e.requestId == id);
    if (request == null) return null;
    final Map<DiversifiableFullViewingKey, ZcashSyncAccount> acc = {};
    for (final i in request.accounts) {
      final account = _defaultTracker.syncAccounts
          .firstWhereNullable((e) => e.indexes.any((e) => e.index == i));
      assert(account != null, "account not found.");
      if (account == null) continue;
      final syncAccount = acc[account.derivationKey] ??=
          ZcashSyncAccount(derivationKey: account.derivationKey);
      syncAccount.addIndex(ZcashSyncAccountIndex(index: i, startHeight: 0));
    }
    return _cachedRequestAccounts[id] =
        ZcashSyncRequestAccount(accounts: acc.values.toList(), network: network);
  }

  ZcashSyncTracker? trackerByRequestId(int? requestId) {
    if (requestId == null) {
      return _defaultTracker;
    }
    return _requestsTrackers.firstWhereOrNull((e) => e.requestId == requestId);
  }

  List<ZcashSyncTracker> pendingTrackers() {
    return [_defaultTracker, ..._requestsTrackers.where((e) => !e.offsets.status.synced)];
  }

  List<ZcashSyncTracker> trackers() {
    return [_defaultTracker, ..._requestsTrackers];
  }

  BlockTrackingOffset? findRequestOffset(ZcashBlockTrackingRequestOffset request) {
    return trackerByRequestId(request.requestId)?.findOffset(request.offset);
  }

  List<Nullifier> utxosNullifiers(int? id) {
    return defaultTracker.syncAccounts.expand((e) => e.utxosNullifiers(id)).toList();
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.zcashSyncController;

  @override
  List<CborObject?> get serializationItems => [
        network.value.toCbor(),
        _defaultTracker.toCbor(),
        AppSerialization.listFromObjects(
            _requestsTrackers.map((e) => e.toCbor()).toList()),
        _latestTrackerId.toCbor()
      ];
}
