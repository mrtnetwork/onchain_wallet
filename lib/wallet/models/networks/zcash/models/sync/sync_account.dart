import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/account/account.dart';
import 'package:on_chain_wallet/wallet/models/block/models/offset.dart';
import 'package:on_chain_wallet/wallet/models/block/models/status.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/account/utxos.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/sync/tracker.dart';
import 'package:zcash_dart/zcash.dart';

import 'request.dart';

class ZcashSyncAccountIndex with AppSerialization, Equality {
  final ZcashAccountInfoShield index;
  final int startHeight;
  Set<ZcashUtxoShield> _utxos;
  Map<int, Set<ZcashUtxoShield>> _requestUtxos;

  Set<ZcashUtxoShield> get utxos => _utxos;

  bool get hasTx => _utxos.isNotEmpty;
  bool get isEmpty => _utxos.isEmpty;
  ZcashSyncAccountIndex toRequest() {
    return ZcashSyncAccountIndex(index: index, startHeight: startHeight);
  }

  @override
  String toString() {
    return "ZcashSyncAccountIndex {index: $index, utxos: ${_utxos.map((e) => BytesUtils.toHexString(e.nullifier.toBytes())).toList()}}";
  }

  List<ZcashUtxoShield> pendingUtxos() => _requestUtxos.values.expand((e) => e).toList();

  List<Nullifier> utxosNullifiers(int? id) {
    if (id != null) {
      final request = _requestUtxos[id] ?? {};
      return request.map((e) => e.nullifier).toList();
    }
    return [..._utxos, ..._requestUtxos.values.expand((e) => e)]
        .map((e) => e.nullifier)
        .toList();
  }

  /// only account without nullifiers or utxos
  ZcashSyncAccountIndex onlyAccount() {
    return ZcashSyncAccountIndex(index: index, startHeight: startHeight);
  }

  bool addUtxo(ZcashUtxoShield utxo, int? requestId) {
    assert(utxo.protocol == index.type.protocol);
    if (utxo.protocol != index.type.protocol) {
      return false;
    }

    if (requestId != null) {
      final rUtxos = _requestUtxos.clone();
      rUtxos[requestId] = {...?_requestUtxos[requestId], utxo}.toImutableSet;
      _requestUtxos = rUtxos.immutable;
      return false;
    } else {
      _utxos = {..._utxos, utxo}.toImutableSet;
    }

    return true;
  }

  bool mergeRequestUtxos(int requestId) {
    final utxos = _requestUtxos[requestId] ?? {};
    if (utxos.isEmpty) return false;
    final allUtxos = {
      ..._utxos,
      ...utxos.map((e) => e.updateStatus(ZcashUtxoSpendableStatus.ready))
    };
    _utxos = allUtxos.toImutableSet;
    removeRequestUtxos(requestId);
    return true;
  }

  bool requestHaveUtxos(int requestId) {
    return _requestUtxos.isNotEmpty;
  }

  void removeRequestUtxos(int requestId) {
    final requestUtxos = _requestUtxos.clone();
    requestUtxos.remove(requestId);
    _requestUtxos = requestUtxos.immutable;
  }

  ZcashMergeAccountResult addSyncUtxos(Iterable<ZcashUtxoShield> utxos, int? requestId) {
    if (utxos.isEmpty) return ZcashMergeAccountResult();
    bool updated = false;
    for (final i in utxos) {
      updated |= addUtxo(
          i.withoutMemo(
              status: switch (requestId) {
            int _ => ZcashUtxoSpendableStatus.notReady,
            null => ZcashUtxoSpendableStatus.ready
          }),
          requestId);
    }
    return ZcashMergeAccountResult(updated: updated, utxos: [
      if (utxos.isNotEmpty)
        ZcashUtxosWithAccountInfo(
            account: index,
            utxos: utxos.map((e) => ZcashUtxoWithSpendingInfo.unconfirmed(e)).toList())
    ]);
  }

  /// find spended nullifiers and spendable utxos
  static ({
    Iterable<Nullifier> unknownNullifiers,
    Iterable<ZcashUtxoShield> spendableUtxos,
    Iterable<ZcashUtxoShield> spendedUtxos
  }) _findNullifiersAndUtxos(
      {required Iterable<Nullifier> nullifiers,
      required Iterable<ZcashUtxoShield> utxos}) {
    List<ZcashUtxoShield> spendedUtxos =
        utxos.where((e) => nullifiers.contains(e.nullifier)).toList();
    final spendedNullifiers = spendedUtxos.map((e) => e.nullifier).toList();
    final spendableUtxos = utxos.where((e) => !spendedUtxos.contains(e)).toList();
    final unknownNullifiers =
        nullifiers.where((e) => !spendedNullifiers.contains(e)).toSet();
    return (
      unknownNullifiers: unknownNullifiers,
      spendableUtxos: spendableUtxos,
      spendedUtxos: spendedUtxos
    );
  }

  /// merge index with syncing object
  bool mergeNullifiers(Iterable<Nullifier> nullifiers) {
    if (nullifiers.isEmpty) return false;
    List<ZcashUtxoShield> spendedUtxos = [];
    var spendInfo = _findNullifiersAndUtxos(nullifiers: nullifiers, utxos: _utxos);
    _utxos = spendInfo.spendableUtxos.toImutableSet;
    spendedUtxos.addAll(spendInfo.spendedUtxos);
    _requestUtxos = _requestUtxos.map((k, v) {
      spendInfo =
          _findNullifiersAndUtxos(nullifiers: spendInfo.unknownNullifiers, utxos: v);
      spendedUtxos.addAll(spendInfo.spendedUtxos);
      return MapEntry(k, spendInfo.spendableUtxos.toImutableSet);
    }).immutable;

    return spendedUtxos.isNotEmpty;
  }

  ZcashSyncAccountIndex(
      {required this.index,
      required this.startHeight,
      Iterable<ZcashUtxoShield> utxos = const [],
      Map<int, Set<ZcashUtxoShield>> requestUtxos = const {}})
      : _utxos = utxos.toImutableSet,
        _requestUtxos = requestUtxos.immutable;
  factory ZcashSyncAccountIndex.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.zcashSyncAccountInfo);
    return ZcashSyncAccountIndex(
        index:
            ZcashAccountInfoShield.deserialize(object: values.objectAt<CborTagValue>(0)),
        startHeight: values.rawValueAt(1),
        utxos: values
            .listAt<CborTagValue>(2)
            .map((e) => ZcashUtxoShield.deserialize(object: e))
            .toList(),
        requestUtxos: values.mapAt<CborIntValue, CborListValue>(3).map((k, v) => MapEntry(
            k.value,
            v.value.map((e) => ZcashUtxoShield.deserialize(object: e)).toImutableSet)));
  }

  ZcashSyncAccountIndex resetState(int height) {
    return ZcashSyncAccountIndex(index: index, startHeight: height, utxos: []);
  }

  @override
  List get variables => [index];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.zcashSyncAccountInfo;

  @override
  List<CborObject?> get serializationItems => [
        index.toCbor(),
        startHeight.toCbor(),
        AppSerialization.listFromObjects(_utxos.map((e) => e.toCbor()).toList()),
        CborMapValue.definite(_requestUtxos.map((k, v) => MapEntry(CborIntValue(k),
            AppSerialization.listFromObjects(v.map((e) => e.toCbor()).toList()))))
      ];
}

class ZcashSyncAccount with AppSerialization, Equality {
  final DiversifiableFullViewingKey derivationKey;

  Set<ZcashSyncAccountIndex> _indexes;
  Set<ZcashSyncAccountIndex> get indexes => _indexes;
  List<ZcashAccountInfoShield> get accounts => _indexes.map((e) => e.index).toList();
  bool get hasUtxo => _indexes.any((e) => e._utxos.isNotEmpty);
  bool get isEmpty => _indexes.every((e) => e.isEmpty);

  ZcashSyncAccountIndex? _getIndex(ZcashAccountInfoShield index) {
    final account = _indexes.firstWhereNullable((e) => e.index == index);

    return account;
  }

  List<Nullifier> utxosNullifiers(int? id) {
    return _indexes.expand((e) => e.utxosNullifiers(id)).toList();
  }

  /// add utxo from block sync module
  void addUtxo(ZcashAccountInfoShield index, ZcashUtxoShield utxo) {
    final acc = _getIndex(index);
    assert(acc != null, "Zcash account index not found.");
    acc?.addUtxo(utxo, null);
  }

  /// merge index with syncing object
  ZcashMergeAccountResult mergeWithSyncingUtxosReponse(
      {required Set<ZcashSyncAccountIndex> indexes, int? requestId}) {
    ZcashMergeAccountResult merge = ZcashMergeAccountResult();
    bool update = false;
    for (final i in indexes) {
      final index = _getIndex(i.index);
      Logging.error(
          when: () => index == null,
          fn: () => AppLogData(
              runtime: runtimeType,
              function: "_getIndex",
              msg: "Index not found: ${index.toString()}.\n"
                  "inxeses: ${_indexes.map((e) => e.index.toString()).toList()}"));
      if (index == null) continue;
      merge += index.addSyncUtxos(i._utxos, requestId);
    }
    return ZcashMergeAccountResult(utxos: merge.utxos, updated: merge.updated | update);
  }

  bool mergeNullifierReponse(Set<Nullifier> nullifiers) {
    bool update = false;
    for (final i in _indexes) {
      update |= i.mergeNullifiers(nullifiers);
    }
    return update;
  }

  bool mergeRequestUtxos(int requestId) {
    bool updated = false;
    for (final i in indexes) {
      updated |= i.mergeRequestUtxos(requestId);
    }
    return updated;
  }

  bool requstHaveUtxos(int requestId) {
    for (final i in indexes) {
      if (i.requestHaveUtxos(requestId)) {
        return true;
      }
    }
    return false;
  }

  void removeRequestUtxos(int requestId) {
    for (final i in indexes) {
      i.removeRequestUtxos(requestId);
    }
  }

  /// create object for syncing
  ZcashSyncAccount toRequest() {
    return ZcashSyncAccount(
        derivationKey: derivationKey,
        indexes: _indexes.map((e) => e.toRequest()).toList());
  }

  /// only account without nullifiers or utxos
  ZcashSyncAccount onlyAccount() {
    return ZcashSyncAccount(
        derivationKey: derivationKey,
        indexes: _indexes.map((e) => e.onlyAccount()).toList());
  }

  ZcashSyncAccount(
      {List<ZcashSyncAccountIndex> indexes = const [], required this.derivationKey})
      : _indexes = indexes.toImutableSet;
  factory ZcashSyncAccount.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.zcashSyncAccount);
    return ZcashSyncAccount(
        derivationKey: DiversifiableFullViewingKey.fromBytes(values.rawValueAt(0)),
        indexes: values
            .listAt<CborTagValue>(1)
            .map((e) => ZcashSyncAccountIndex.deserialize(object: e))
            .toList());
  }

  bool removeIndex(ZcashAccountInfoShield index) {
    final indexes = this.indexes.clone();
    indexes.removeWhere((e) => e.index == index);
    _indexes = indexes.toImutableSet;
    return _indexes.isNotEmpty;
  }

  void resetAccountIndex(ZcashAccountInfoShield index, int height) {
    final indexes = this.indexes.clone();
    _indexes = indexes.map((e) {
      if (e.index == index) return e.resetState(height);
      return e;
    }).toImutableSet;
  }

  ZcashSyncAccount resetState(int height, {List<ZcashSyncAccountIndex>? accounts}) {
    return ZcashSyncAccount(
        derivationKey: derivationKey,
        indexes: _indexes.map((e) {
          if (accounts != null) {
            if (accounts.contains(e)) {
              return e.resetState(height);
            }
            return e;
          }

          return e.resetState(height);
        }).toList());
  }

  void addIndex(ZcashSyncAccountIndex index) {
    if (_indexes.contains(index)) return;
    assert(index.index.protocol == derivationKey.protocol);
    if (index.index.protocol != derivationKey.protocol) return;
    _indexes = {..._indexes, index}.toImutableSet;
  }

  @override
  List get variables => [derivationKey];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.zcashSyncAccount;

  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(derivationKey.toBytes()),
        AppSerialization.listFromObjects(_indexes.map((e) => e.toCbor()).toList()),
      ];
}

class ZcashSyncRequestAccount with AppSerialization {
  final ZcashNetwork network;
  final List<ZcashSyncAccount> accounts;
  ZcashSyncRequestAccount(
      {required List<ZcashSyncAccount> accounts, required this.network})
      : accounts = accounts.immutable;

  factory ZcashSyncRequestAccount.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    return ZcashSyncRequestAccount(
        accounts: values
            .listAt<CborTagValue>(0)
            .map((e) => ZcashSyncAccount.deserialize(object: e))
            .toList(),
        network: ZcashNetwork.fromValue(values.rawValueAt(1)));
  }

  List<AccountWithIvkAndNullifiers> accountWithIvkAndNullifiers(ZCryptoContext context) {
    final List<AccountWithIvkAndNullifiers> ivks = [];
    for (final i in accounts) {
      for (final index in i.indexes) {
        ivks.add(AccountWithIvkAndNullifiers(
          ivk: i.derivationKey.toIvk(index.index.scope, context: context),
          account: index.index,
          derivationKey: i.derivationKey,
        ));
      }
    }
    return ivks;
  }

  ZcashSyncAccount onlyAccount(DiversifiableFullViewingKey derivationKey) {
    return accounts.firstWhere((e) => e.derivationKey == derivationKey).onlyAccount();
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(accounts.map((e) => e.toCbor()).toList()),
        network.value.toCbor()
      ];
}

sealed class ZcashBlockSyncedOffset extends BlockSyncedOffset {
  final Set<Nullifier> nullifiers;
  ZcashBlockSyncedOffset(
      {required super.currentHeight,
      required super.total,
      required super.status,
      required Iterable<Nullifier> nullifiers})
      : nullifiers = nullifiers.toImutableSet;
}

final class ZcashSyncOffsetResponse extends ZcashBlockSyncedOffset {
  final ZcashBlockTrackingRequestOffset request;
  final Set<ZcashSyncAccount> accounts;
  @override
  BlockTrackingOffset get offset => request.offset;
  @override
  int? get requestId => request.requestId;
  bool get hasTx => accounts.any((e) => e.hasUtxo);

  ZcashSyncOffsetResponse({
    required Iterable<ZcashSyncAccount> accounts,
    required super.currentHeight,
    required super.total,
    required this.request,
    required super.status,
    required super.nullifiers,
  }) : accounts = accounts.toImutableSet;

  factory ZcashSyncOffsetResponse.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    return ZcashSyncOffsetResponse(
      accounts: values
          .listAt<CborTagValue>(0)
          .map((e) => ZcashSyncAccount.deserialize(object: e))
          .toList(),
      currentHeight: values.rawValueAt(1),
      total: values.rawValueAt(2),
      request: ZcashBlockTrackingRequestOffset.deserialize(
          object: values.objectAt<CborTagValue>(3)),
      status: BlockSyncStatus.deserialize(object: values.objectAt(4)),
      nullifiers: values
          .listAt<CborTagValue>(5)
          .map((e) => Nullifier.deserialize(obj: e))
          .toList(),
    );
  }

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(accounts.map((e) => e.toCbor()).toList()),
        currentHeight.toCbor(),
        total.toCbor(),
        request.toCbor(),
        status.toCbor(),
        AppSerialization.listFromObjects(nullifiers.map((e) => e.toCbor()).toList()),
      ];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  String toString() {
    return "height: ${currentHeight + total}, $request $status";
  }
}

class ZcashMergeAccountResult {
  final List<ZcashUtxosWithAccountInfo> utxos;
  final bool updated;
  const ZcashMergeAccountResult({this.utxos = const [], this.updated = false});

  ZcashMergeAccountResult operator +(ZcashMergeAccountResult other) {
    return ZcashMergeAccountResult(
        utxos: [...utxos, ...other.utxos], updated: updated | other.updated);
  }

  @override
  String toString() {
    return "ZcashMergeAccountResult {utxos: ${utxos.length}, updated: $updated}";
  }
}

class ZcashMergeResult {
  final ZcashMergeAccountResult account;
  final UpdateOffsetResult status;
  final ZcashSyncRequestPhase phase;
  const ZcashMergeResult(
      {required this.account, required this.status, required this.phase});

  @override
  String toString() {
    return "ZcashMergeResult {account: $account, status: $status, phase: $phase}";
  }
}

class ZcashSyncAccountRequest {
  final List<ZcashAccountInfoShield> accounts;
  final int startHeight;
  final int endHeight;
  final String heightsStr;
  ZcashSyncAccountRequest(
      {required this.accounts, required this.startHeight, required this.endHeight})
      : heightsStr = "$startHeight/$endHeight";
}

final class ZcashSyncNullifierResponse extends ZcashBlockSyncedOffset {
  final ZcashBlockTrackingRequestNullifier request;
  @override
  BlockTrackingOffset get offset => request.offset;
  @override
  int get requestId => request.requestId;

  ZcashSyncNullifierResponse({
    required super.nullifiers,
    required super.currentHeight,
    required super.total,
    required this.request,
    required super.status,
  });

  factory ZcashSyncNullifierResponse.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    return ZcashSyncNullifierResponse(
      nullifiers: values
          .listAt<CborTagValue>(0)
          .map((e) => Nullifier.deserialize(obj: e))
          .toList(),
      currentHeight: values.rawValueAt(1),
      total: values.rawValueAt(2),
      request: ZcashBlockTrackingRequestNullifier.deserialize(
          object: values.objectAt<CborTagValue>(3)),
      status: BlockSyncStatus.deserialize(object: values.objectAt(4)),
    );
  }

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(nullifiers.map((e) => e.toCbor()).toList()),
        currentHeight.toCbor(),
        total.toCbor(),
        request.toCbor(),
        status.toCbor(),
      ];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  String toString() {
    return "height: ${currentHeight + total}, $request $status";
  }
}
