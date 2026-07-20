import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/wallet/models/block/models/utils.dart';
import 'package:on_chain_wallet/wallet/models/networks/monero/account/account.dart';
import 'package:on_chain_wallet/wallet/models/networks/monero/account/utxo.dart';
import 'package:on_chain_wallet/wallet/models/networks/monero/syncing/sync_account.dart';
import 'package:on_chain_wallet/wallet/models/block/models/offset.dart';

import 'request.dart';

sealed class MoneroSyncTracker with AppSerialization {
  final BlockSyncingOffsets offsets;
  final DateTime created;
  List<MoneroSyncAccountIndex> get accountIndexes;
  int get startHeight => offsets.startHeight;
  int get endHeight => offsets.endHeight;
  int get currentHeight => offsets.currentHeight;
  int? get requestId;
  MoneroSyncTracker({required this.offsets, required this.created});

  BlockTrackingOffset? findOffset(BlockTrackingOffset offset) {
    return offsets.offsets.firstWhereOrNull((e) => e == offset);
  }
}

class MoneroSyncRequestTracker extends MoneroSyncTracker {
  @override
  final int requestId;
  @override
  final int startHeight;
  @override
  final int endHeight;
  Set<MoneroAccountIndex> _accounts;
  Set<MoneroAccountIndex> get accounts => _accounts;

  MoneroSyncRequestTracker.__(
      {required super.offsets,
      required super.created,
      required this.startHeight,
      required this.endHeight,
      required Iterable<MoneroAccountIndex> accounts,
      required this.requestId})
      : _accounts = accounts.toImutableSet;
  factory MoneroSyncRequestTracker._({
    required BlockSyncingOffsets offsets,
    required DateTime created,
    required Iterable<MoneroAccountIndex> accounts,
    required int startHeight,
    required int endHeight,
  }) {
    final id = offsets.requestId;
    if (id == null) {
      throw AppInternalError.internalError("MoneroSyncRequestTracker",
          reason: "missing request id.");
    }
    return MoneroSyncRequestTracker.__(
        offsets: offsets,
        created: created,
        accounts: accounts,
        requestId: id,
        startHeight: startHeight,
        endHeight: endHeight);
  }

  factory MoneroSyncRequestTracker.start({
    required int startHeight,
    required int endHeight,
    required int requestId,
    required Iterable<MoneroAccountIndex> accounts,
  }) {
    return MoneroSyncRequestTracker._(
        offsets: BlockSyncingOffsets.buildRequest(
            startHeight: startHeight,
            endHeight: endHeight,
            requestId: requestId,
            totalBlockPerOffset: BlockTrackerUtils.moneroBlockPerOffset,
            totalOffsets: BlockTrackerUtils.moneroTotalOffset),
        created: DateTime.now(),
        accounts: accounts,
        startHeight: startHeight,
        endHeight: endHeight);
  }

  factory MoneroSyncRequestTracker.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.moneroSyncRequestTracker);
    final offset = BlockSyncingOffsets.deserialize(object: values.objectAt(0));
    return MoneroSyncRequestTracker._(
        offsets: offset,
        created: values.rawValueAt<DateTime>(1),
        accounts: values
            .listAt<CborTagValue>(2)
            .map((e) => MoneroAccountIndex.deserialize(object: e))
            .toList(),
        startHeight: values.rawValueAt<int>(3),
        endHeight: values.rawValueAt<int>(4));
  }

  /// remove account from request and return false if request accounts is empty.
  bool removeAccount(MoneroAccountIndex account) {
    if (!_accounts.contains(account)) return _accounts.isNotEmpty;
    final accounts = _accounts.clone();
    accounts.remove(account);
    _accounts = accounts.toImutableSet;
    return _accounts.isNotEmpty;
  }

  IResult<MoneroMergeResult> updateOffset(
      {required MoneroBlockSyncedOffset offset,
      required MoneroSyncTrackerController controller}) {
    if (offset.requestId != requestId) {
      return ResultErr.fromException(AppInternalError.internalError(
          "MoneroSyncRequestTracker.updateOffset",
          reason: "Invalid offset request id."));
    }
    switch (offset) {
      case MoneroSyncOffsetResponse():
        final result = offsets.updateOffset(offset,
            totalBlockPerOffset: BlockTrackerUtils.moneroBlockPerOffset,
            totalOffsets: BlockTrackerUtils.moneroTotalOffset);
        return result.andThen((status) {
          MoneroMergeAccountResult merge = MoneroMergeAccountResult();
          for (final i in offset.accounts) {
            final account = controller.getAccountFromFullViewingKey(i.derivationKey);
            if (account == null) continue;
            merge += account.mergeWithSyncingUtxosReponse(indexes: i.indexes);
          }
          if (offset.keyImages.isNotEmpty) {
            final syncAccounts = controller.defaultTracker.syncAccounts;
            bool updated = false;
            for (final i in syncAccounts) {
              updated |= i.mergeKeyImageReponse(offset.keyImages);
            }
            merge = MoneroMergeAccountResult(
                utxos: merge.utxos, updated: updated | merge.updated);
          }
          return ResultOk(MoneroMergeResult(account: merge, status: status));
        });
    }
  }

  List<BlockTrackingOffset> pendingOffsets() {
    return offsets.offsets.where((e) => !e.status.synced).toList();
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.moneroSyncRequestTracker;

  @override
  List<CborObject?> get serializationItems => [
        offsets.toCbor(),
        created.toCbor(),
        AppSerialization.listFromObjects(_accounts.map((e) => e.toCbor()).toList()),
        startHeight.toCbor(),
        endHeight.toCbor()
      ];

  @override
  List<MoneroSyncAccountIndex> get accountIndexes => accounts
      .map((e) => MoneroSyncAccountIndex(index: e, startHeight: startHeight))
      .toList();
}

class MoneroSyncDefaultTracker extends MoneroSyncTracker {
  final bool initialized;
  Set<MoneroSyncAccount> _syncAccount;
  Set<MoneroSyncAccount> get syncAccounts => _syncAccount;

  @override
  int? get requestId => null;
  List<MoneroAccountIndex> get accounts =>
      _syncAccount.expand((e) => e.accounts).toList();

  MoneroSyncDefaultTracker.__({
    required super.offsets,
    required super.created,
    required this.initialized,
    required Iterable<MoneroSyncAccount> accounts,
  }) : _syncAccount = accounts.toImutableSet;

  factory MoneroSyncDefaultTracker.start() {
    return MoneroSyncDefaultTracker.__(
        offsets: BlockSyncingOffsets.buildDefault(startHeight: 0, endHeight: 0),
        created: DateTime.now(),
        accounts: [],
        initialized: false);
  }

  factory MoneroSyncDefaultTracker._(
      {required BlockSyncingOffsets offsets,
      required DateTime created,
      required List<MoneroSyncAccount> accounts,
      required bool initialized}) {
    final id = offsets.requestId;
    if (id != null) {
      throw AppInternalError.internalError("MoneroSyncDefaultTracker");
    }
    return MoneroSyncDefaultTracker.__(
        offsets: offsets, created: created, accounts: accounts, initialized: initialized);
  }

  factory MoneroSyncDefaultTracker.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.moneroSyncDefaultTracker);
    return MoneroSyncDefaultTracker._(
        offsets: BlockSyncingOffsets.deserialize(object: values.objectAt(0)),
        created: values.rawValueAt<DateTime>(1),
        accounts: values
            .listAt<CborTagValue>(2)
            .map((e) => MoneroSyncAccount.deserialize(object: e))
            .toList(),
        initialized: values.rawValueAt(3));
  }

  void addAccount(
      MoneroViewPrimaryAccountDetails derivationKey, MoneroAccountIndex info) {
    MoneroSyncAccount? syncAccount =
        syncAccounts.firstWhereNullable((e) => e.derivationKey == derivationKey);
    if (syncAccount == null) {
      syncAccount = MoneroSyncAccount(derivationKey: derivationKey);
      _syncAccount = {..._syncAccount, syncAccount}.toImutableSet;
    }
    syncAccount.addIndex(
        MoneroSyncAccountIndex(index: info, startHeight: offsets.currentHeight));
  }

  bool removeAccount(MoneroAccountIndex account) {
    final MoneroSyncAccount? syncAccount =
        syncAccounts.firstWhereNullable((e) => e.indexes.any((e) => e.index == account));
    if (syncAccount != null) {
      final hasAccount = syncAccount.removeIndex(account);
      if (!hasAccount) {
        _syncAccount = _syncAccount.where((e) => e != syncAccount).toImutableSet;
      }
    }
    return _syncAccount.isNotEmpty;
  }

  bool resetAccountIndex(MoneroAccountIndex account, int index) {
    final MoneroSyncAccount? syncAccount =
        syncAccounts.firstWhereNullable((e) => e.indexes.any((e) => e.index == account));
    if (syncAccount != null) {
      syncAccount.resetAccountIndex(account, index);
      return true;
    }
    return false;
  }

  MoneroSyncAccountIndex? findSyncAccountIndex(MoneroAccountIndex index) {
    for (final a in _syncAccount) {
      for (final i in a.indexes) {
        if (i.index == index) return i;
      }
    }
    assert(false, "index does not exist.");
    return null;
  }

  MoneroSyncAccount? findPrimaryAccount(DerivableIndex index) {
    final account = _syncAccount.firstWhereOrNull((e) => e.derivationKey.index == index);
    assert(account != null, "account not found.");
    return account;
  }

  List<MoneroUtxo> getAccountUtxos(MoneroAccountIndex index) {
    final account = findSyncAccountIndex(index);
    return account?.utxos.toList() ?? [];
  }

  List<MoneroUtxo> getAccountPendingUtxos(MoneroAccountIndex index) {
    final account = findSyncAccountIndex(index);
    return account?.utxos.toList() ?? [];
  }

  List<MoneroUtxo> getPrimaryAccountUtxos(DerivableIndex index) {
    return findPrimaryAccount(index)?.getUtxos() ?? [];
  }

  List<MoneroUtxosWithAccountInfo> getPrimaryAccountUtxosWithInfo(DerivableIndex index) {
    return findPrimaryAccount(index)?.getUtxosWithAccountInfo() ?? [];
  }

  MoneroViewPrimaryAccountDetails? getPrimaryAccount(DerivableIndex index) {
    return findPrimaryAccount(index)?.derivationKey;
  }

  MoneroSyncAccount? getAccountFromFullViewingKey(
      MoneroViewPrimaryAccountDetails derivationKey) {
    final account =
        _syncAccount.firstWhereOrNull((e) => e.derivationKey == derivationKey);
    Logging.error(
        when: () => account == null,
        fn: () => AppLogData(
            runtime: runtimeType,
            function: "getAccountFromFullViewingKey",
            msg: "account not found ."));
    return account;
  }

  IResult<void> updateHeight(int height) {
    if (!initialized || height < endHeight) {
      return ResultErr.fromException(WalletExceptionConst.badAccountSyncingConfiguration);
    }
    return offsets.updateHeight(height).map<void>((status) {
      Logging.debug(
          fn: () => AppLogData(
              runtime: runtimeType,
              function: "updateHeight",
              msg:
                  "Monero sync updated. start: $startHeight current: $currentHeight end: $endHeight"));
    });
  }

  IResult<MoneroMergeAccountResult> importUtxos(List<MoneroSyncAccountIndex> utxos) {
    MoneroMergeAccountResult merge = MoneroMergeAccountResult();
    for (final i in utxos) {
      final account = findPrimaryAccount(i.index.masterIndex);
      assert(account != null, "utxo account not found.");
      if (account == null) continue;
      merge += account.mergeWithSyncingUtxosReponse(indexes: {i});
    }
    return ResultOk(merge);
  }

  MoneroSyncDefaultTracker resetState({required int height, bool initialized = true}) {
    final offset =
        BlockSyncingOffsets.buildDefault(startHeight: height, endHeight: height);
    return MoneroSyncDefaultTracker.__(
        offsets: offset,
        created: DateTime.now(),
        accounts: syncAccounts.map((e) => e.resetState(height)),
        initialized: initialized);
  }

  IResult<MoneroMergeResult> updateOffset(MoneroBlockSyncedOffset offset) {
    if (offset.requestId != null) {
      return ResultErr.fromException(AppInternalError.internalError(
          "MoneroSyncDefaultTracker.updateOffset",
          reason: "Invalid offset. request id must be null"));
    }
    switch (offset) {
      case MoneroSyncOffsetResponse():
        final result = offsets.updateOffset(offset);
        return result.map((status) {
          MoneroMergeAccountResult merge = MoneroMergeAccountResult();
          for (final i in offset.accounts) {
            final account = getAccountFromFullViewingKey(i.derivationKey);
            if (account == null) continue;
            merge += account.mergeWithSyncingUtxosReponse(indexes: i.indexes);
          }
          if (offset.keyImages.isNotEmpty) {
            final syncAccounts = this.syncAccounts;
            bool updated = false;
            for (final i in syncAccounts) {
              updated |= i.mergeKeyImageReponse(offset.keyImages);
            }
            merge = MoneroMergeAccountResult(
                utxos: merge.utxos, updated: updated | merge.updated);
          }

          return MoneroMergeResult(account: merge, status: status);
        });
    }
  }

  IResult<void> trancateCurrentHeight(int height) {
    return offsets.trancateCurrentHeight(height);
  }

  List<BlockTrackingOffset> pendingOffsets() {
    return offsets.offsets.where((e) => !e.status.synced).toList();
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.moneroSyncDefaultTracker;

  @override
  List<CborObject?> get serializationItems => [
        offsets.toCbor(),
        created.toCbor(),
        AppSerialization.listFromObjects(_syncAccount.map((e) => e.toCbor()).toList()),
        initialized.toCbor()
      ];

  @override
  List<MoneroSyncAccountIndex> get accountIndexes =>
      _syncAccount.expand((e) => e.indexes).toList();
}

class MoneroSyncTrackerController with AppSerialization {
  final MoneroNetwork network;
  List<MoneroSyncRequestTracker> _requestsTrackers;
  MoneroSyncDefaultTracker _defaultTracker;
  final _lock = SafeAtomicLock();
  final Map<int?, List<MoneroSyncAccount>> _cachedRequestAccounts = {};
  bool get initialized => _defaultTracker.initialized;
  int _latestTrackerId;
  MoneroSyncDefaultTracker get defaultTracker => _defaultTracker;
  List<MoneroSyncRequestTracker> get requestTrackers => _requestsTrackers;

  MoneroSyncTrackerController(
      {required this.network,
      required MoneroSyncDefaultTracker defaultTracker,
      required List<MoneroSyncRequestTracker> requestTrackers,
      required int latestTrackerId})
      : _defaultTracker = defaultTracker,
        _requestsTrackers = requestTrackers.immutable,
        _latestTrackerId = latestTrackerId;
  factory MoneroSyncTrackerController.start(MoneroNetwork network) {
    return MoneroSyncTrackerController(
        network: network,
        defaultTracker: MoneroSyncDefaultTracker.start(),
        requestTrackers: [],
        latestTrackerId: 1);
  }
  factory MoneroSyncTrackerController.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.moneroSyncController);
    return MoneroSyncTrackerController(
        network: MoneroNetwork.fromValue(values.rawValueAt(0)),
        defaultTracker: MoneroSyncDefaultTracker.deserialize(object: values.objectAt(1)),
        requestTrackers: values
            .listAt<CborTagValue>(2)
            .map((e) => MoneroSyncRequestTracker.deserialize(object: e))
            .toList(),
        latestTrackerId: values.rawValueAt<int>(3));
  }
  bool accountExists(MoneroAccountIndex shield) {
    return _defaultTracker.syncAccounts.any((e) => e.accounts.contains(shield));
  }

  MoneroSyncAccount? getAccountFromFullViewingKey(
      MoneroViewPrimaryAccountDetails derivationKey) {
    return _defaultTracker.getAccountFromFullViewingKey(derivationKey);
  }

  MoneroViewPrimaryAccountDetails? getPrimaryAccount(MoneroAccountIndex index) {
    return _defaultTracker.getPrimaryAccount(index.masterIndex);
  }

  List<MoneroUtxo> getAccountUtxos(MoneroAccountIndex index) {
    return _defaultTracker.getAccountUtxos(index);
  }

  List<MoneroUtxo> getAccountPendingUtxos(MoneroAccountIndex index) {
    return _defaultTracker.getAccountPendingUtxos(index);
  }

  List<MoneroUtxo> getPrimaryAccountUtxos(DerivableIndex index) {
    return _defaultTracker.getPrimaryAccountUtxos(index);
  }

  List<MoneroUtxosWithAccountInfo> getPrimaryAccountUtxosWithInfo(DerivableIndex index) {
    return _defaultTracker.getPrimaryAccountUtxosWithInfo(index);
  }

  Future<IResult<void>> addAccount(
      MoneroViewPrimaryAccountDetails derivationKey, MoneroAccountIndex info) {
    return _lock.run(() async {
      _defaultTracker.addAccount(derivationKey, info);
      _cachedRequestAccounts.remove(null);
      return ResultOk.okVoid;
    });
  }

  Future<IResult<void>> removeAccount(MoneroAccountIndex account) async {
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
    required Set<MoneroAccountIndex> accounts,
  }) {
    final existAccounts = _defaultTracker.accounts;
    for (final i in accounts) {
      if (!existAccounts.contains(i)) {
        return ResultErr.fromException(WalletExceptionConst.accountDoesNotFound);
      }
    }
    if (startHeight > endHeight) {
      return ResultErr.fromException(
          AppInternalError.internalError("MoneroRequestBlockTrackingInfo"));
    }
    final ids = _requestsTrackers.map((e) => e.requestId).toList()..sort();
    int requestId = _latestTrackerId;
    while (ids.contains(requestId)) {
      requestId++;
    }
    final request = MoneroSyncRequestTracker.start(
        startHeight: startHeight,
        endHeight: endHeight,
        requestId: requestId,
        accounts: accounts);
    _requestsTrackers = [..._requestsTrackers, request].toImutableList;
    return ResultOk(requestId);
  }

  Future<IResult<int>> addSyncRequest({
    required int startHeight,
    required int endHeight,
    required Set<MoneroAccountIndex> accounts,
  }) async {
    return await _lock.run(() async {
      return addSyncRequestInternal(
          startHeight: startHeight, endHeight: endHeight, accounts: accounts);
    });
  }

  Future<IResult<MoneroSyncRequestTracker?>> removeRequest(int requestId) {
    return _lock.run(() async {
      final request = _requestsTrackers.firstWhereOrNull((e) => e.requestId == requestId);
      assert(request != null, "unknow request id. request does not exists.");
      if (request == null) return ResultOk(null);
      _requestsTrackers = _requestsTrackers.where((e) => e != request).toImutableList;
      _cachedRequestAccounts.remove(requestId);
      return ResultOk(request);
    });
  }

  /// Remove everything, must be called afrer all wallet account removed.
  Future<IResult<void>> toDefaultState() {
    return _lock.run(() async {
      _defaultTracker = MoneroSyncDefaultTracker.start();
      _requestsTrackers = [];
      _cachedRequestAccounts.clear();
      return ResultOk.okVoid;
    });
  }

  Future<IResult<bool>> resetDefaultTrackerState(
      {required int height,
      required int currentHeight,
      Set<MoneroAccountIndex>? accounts}) async {
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
        List<MoneroSyncRequestTracker> trackers = [];
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

  IResult<void> trancateCurrentHeight(int height) {
    return defaultTracker.trancateCurrentHeight(height);
  }

  IResult<MoneroMergeAccountResult> importUtxos(List<MoneroSyncAccountIndex> utxos) {
    return _defaultTracker.importUtxos(utxos);
  }

  IResult<MoneroMergeResult> updateTrackerOffset(MoneroBlockSyncedOffset offset) {
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

  List<MoneroSyncAccount>? getSyncRequestAccount(int? requestId) {
    final id = requestId;
    final cached = _cachedRequestAccounts[id];
    if (cached != null) return cached;
    if (id == null) {
      return _cachedRequestAccounts[id] =
          _defaultTracker.syncAccounts.map((e) => e.toRequest()).toList();
    }
    final request = _requestsTrackers.firstWhereOrNull((e) => e.requestId == id);
    if (request == null) return null;
    final Map<MoneroViewPrimaryAccountDetails, MoneroSyncAccount> acc = {};
    for (final i in request.accounts) {
      final account = _defaultTracker.syncAccounts
          .firstWhereNullable((e) => e.indexes.any((e) => e.index == i));
      assert(account != null, "account not found.");
      if (account == null) continue;
      final syncAccount = acc[account.derivationKey] ??=
          MoneroSyncAccount(derivationKey: account.derivationKey);
      syncAccount.addIndex(MoneroSyncAccountIndex(index: i, startHeight: 0));
    }
    return _cachedRequestAccounts[id] = acc.values.toList();
  }

  MoneroSyncTracker? trackerByRequestId(int? requestId) {
    if (requestId == null) {
      return _defaultTracker;
    }
    return _requestsTrackers.firstWhereOrNull((e) => e.requestId == requestId);
  }

  List<MoneroSyncTracker> pendingTrackers() {
    return [_defaultTracker, ..._requestsTrackers.where((e) => !e.offsets.status.synced)];
  }

  List<MoneroSyncTracker> trackers() {
    return [_defaultTracker, ..._requestsTrackers];
  }

  BlockTrackingOffset? findRequestOffset(MoneroBlockTrackingRequestOffset request) {
    return trackerByRequestId(request.requestId)?.findOffset(request.offset);
  }

  List<TxKeyImage> keyImages() {
    return _defaultTracker.syncAccounts.expand((e) => e.keyImages()).toList();
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.moneroSyncController;

  @override
  List<CborObject?> get serializationItems => [
        network.value.toCbor(),
        _defaultTracker.toCbor(),
        AppSerialization.listFromObjects(
            _requestsTrackers.map((e) => e.toCbor()).toList()),
        _latestTrackerId.toCbor()
      ];
}
