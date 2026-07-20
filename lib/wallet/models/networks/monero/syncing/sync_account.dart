import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys.dart';
import 'package:on_chain_wallet/wallet/models/networks/monero/account/account.dart';
import 'package:on_chain_wallet/wallet/models/networks/monero/account/utxo.dart';
import 'package:on_chain_wallet/wallet/models/block/models/offset.dart';
import 'package:on_chain_wallet/wallet/models/block/models/status.dart';

import 'request.dart';

class MoneroSyncAccountIndex with AppSerialization, Equality {
  final MoneroAccountIndex index;
  final int startHeight;
  Set<MoneroUtxo> _utxos;

  Set<MoneroUtxo> get utxos => _utxos;

  bool get hasTx => _utxos.isNotEmpty;
  bool get isEmpty => _utxos.isEmpty;
  MoneroSyncAccountIndex toRequest() {
    return MoneroSyncAccountIndex(index: index, startHeight: startHeight);
  }

  List<TxKeyImage> keyImages() => utxos.map((e) => e.output.keyImage).toList();

  /// only account without nullifiers or utxos
  MoneroSyncAccountIndex onlyAccount() {
    return MoneroSyncAccountIndex(index: index, startHeight: startHeight);
  }

  bool addUtxo(MoneroUtxo utxo) {
    assert(utxo.output.accountIndex == index.index, "Invalid utxo index.");
    if (_utxos.contains(utxo) || utxo.output.accountIndex != index.index) return false;
    _utxos = [..._utxos, utxo].toImutableSet;
    return true;
  }

  static ({
    Iterable<TxKeyImage> unknownKeyImages,
    Iterable<MoneroUtxo> spendableUtxos,
    Iterable<MoneroUtxo> spendedUtxos
  }) _findNullifiersAndUtxos(
      {required Iterable<TxKeyImage> keyImages, required Iterable<MoneroUtxo> utxos}) {
    List<MoneroUtxo> spendedUtxos =
        utxos.where((e) => keyImages.contains(e.output.keyImage)).toList();
    final spendedKeyImages = spendedUtxos.map((e) => e.output.keyImage).toList();
    final spendableUtxos = utxos.where((e) => !spendedUtxos.contains(e)).toList();
    final unknownKeyImages =
        keyImages.where((e) => !spendedKeyImages.contains(e)).toSet();
    return (
      unknownKeyImages: unknownKeyImages,
      spendableUtxos: spendableUtxos,
      spendedUtxos: spendedUtxos
    );
  }

  /// merge index with syncing object
  bool mergeKeyImages(Iterable<TxKeyImage> keyImages) {
    if (keyImages.isEmpty) return false;
    List<MoneroUtxo> spendedUtxos = [];
    var spendInfo = _findNullifiersAndUtxos(keyImages: keyImages, utxos: _utxos);
    _utxos = spendInfo.spendableUtxos.toImutableSet;
    spendedUtxos.addAll(spendInfo.spendedUtxos);
    return spendedUtxos.isNotEmpty;
  }

  MoneroMergeAccountResult addSyncUtxos(Iterable<MoneroUtxo> utxos) {
    if (utxos.isEmpty) return MoneroMergeAccountResult();
    bool updated = false;
    for (final i in utxos) {
      updated |= addUtxo(i);
    }
    Logging.debug(
        fn: () => AppLogData(
              function: 'addUtxo',
              runtime: runtimeType,
              msg: "update account utxos. ${utxos.length} utxos. index: $index}",
            ));
    return MoneroMergeAccountResult(updated: updated, utxos: [
      if (utxos.isNotEmpty)
        MoneroUtxosWithAccountInfo(
            account: index,
            utxos: utxos.map((e) => MoneroUtxoWithSpendingInfo.unconfirmed(e)).toList())
    ]);
  }

  MoneroSyncAccountIndex(
      {required this.index,
      required this.startHeight,
      Iterable<MoneroUtxo> utxos = const []})
      : _utxos = utxos.toImutableSet;
  factory MoneroSyncAccountIndex.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.moneroSyncAccountIndex);
    return MoneroSyncAccountIndex(
        index: MoneroAccountIndex.deserialize(object: values.objectAt(0)),
        startHeight: values.rawValueAt(1),
        utxos: values
            .listAt<CborTagValue>(2)
            .map((e) => MoneroUtxo.deserialize(object: e))
            .toList());
  }

  MoneroSyncAccountIndex resetState(int height) {
    return MoneroSyncAccountIndex(index: index, startHeight: height, utxos: []);
  }

  @override
  List get variables => [index];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.moneroSyncAccountIndex;

  @override
  List<CborObject?> get serializationItems => [
        index.toCbor(),
        startHeight.toCbor(),
        AppSerialization.listFromObjects(_utxos.map((e) => e.toCbor()).toList()),
      ];
}

class MoneroSyncAccount with AppSerialization, Equality {
  final MoneroViewPrimaryAccountDetails derivationKey;

  Set<MoneroSyncAccountIndex> _indexes;
  Set<MoneroSyncAccountIndex> get indexes => _indexes;
  List<MoneroAccountIndex> get accounts => _indexes.map((e) => e.index).toList();
  bool get hasUtxo => _indexes.any((e) => e._utxos.isNotEmpty);
  bool get isEmpty => _indexes.every((e) => e.isEmpty);

  MoneroAccountKeys getAccountKeys() {
    return MoneroAccountKeys(
        account: derivationKey.account,
        network: derivationKey.network,
        indexes: _indexes.map((e) => e.index.index).toList());
  }

  MoneroAccountIndex? getUtxoAccount(MoneroUtxo utxo) {
    return _indexes
        .firstWhereNullable((e) => e.index.index == utxo.output.accountIndex)
        ?.index;
  }

  MoneroSyncAccountIndex? _getIndex(MoneroAccountIndex index) {
    final account = _indexes.firstWhereNullable((e) => e.index == index);

    return account;
  }

  MoneroSyncAccountIndex? _fromSubIndex(MoneroSubIndex index) {
    final account = _indexes.firstWhereNullable((e) => e.index.index == index);
    return account;
  }

  /// add utxo from block sync module
  void addUtxo(MoneroUtxo utxo) {
    final index = _fromSubIndex(utxo.output.accountIndex);
    assert(index != null, "Monero account not found. $index");
    index?.addUtxo(utxo);
  }

  bool mergeKeyImageReponse(Set<TxKeyImage> nullifiers) {
    bool update = false;
    for (final i in _indexes) {
      update |= i.mergeKeyImages(nullifiers);
    }
    return update;
  }

  /// merge index with syncing object
  MoneroMergeAccountResult mergeWithSyncingUtxosReponse(
      {required Set<MoneroSyncAccountIndex> indexes, int? requestId}) {
    MoneroMergeAccountResult merge = MoneroMergeAccountResult();
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
      merge += index.addSyncUtxos(i._utxos);
    }
    return MoneroMergeAccountResult(utxos: merge.utxos, updated: merge.updated | update);
  }

  /// create object for syncing
  MoneroSyncAccount toRequest() {
    return MoneroSyncAccount(
        derivationKey: derivationKey,
        indexes: _indexes.map((e) => e.toRequest()).toList());
  }

  /// only account without nullifiers or utxos
  MoneroSyncAccount onlyAccount() {
    return MoneroSyncAccount(
        derivationKey: derivationKey,
        indexes: _indexes.map((e) => e.onlyAccount()).toList());
  }

  MoneroSyncAccount(
      {List<MoneroSyncAccountIndex> indexes = const [], required this.derivationKey})
      : _indexes = indexes.toImutableSet;
  factory MoneroSyncAccount.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.moneroSyncAccount);
    return MoneroSyncAccount(
        derivationKey:
            MoneroViewPrimaryAccountDetails.deserialize(object: values.objectAt(0)),
        indexes: values
            .listAt<CborTagValue>(1)
            .map((e) => MoneroSyncAccountIndex.deserialize(object: e))
            .toList());
  }

  bool removeIndex(MoneroAccountIndex index) {
    final indexes = this.indexes.clone();
    indexes.removeWhere((e) => e.index == index);
    _indexes = indexes.toImutableSet;
    return _indexes.isNotEmpty;
  }

  void resetAccountIndex(MoneroAccountIndex index, int height) {
    final indexes = this.indexes.clone();
    _indexes = indexes.map((e) {
      if (e.index == index) return e.resetState(height);
      return e;
    }).toImutableSet;
  }

  MoneroSyncAccount resetState(int height, {List<MoneroSyncAccountIndex>? accounts}) {
    return MoneroSyncAccount(
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

  void addIndex(MoneroSyncAccountIndex index) {
    if (_indexes.contains(index)) return;
    _indexes = {..._indexes, index}.toImutableSet;
  }

  List<MoneroUtxo> getUtxos() => _indexes.expand((e) => e.utxos).toList();
  List<MoneroUtxosWithAccountInfo> getUtxosWithAccountInfo() {
    return _indexes
        .map((e) => MoneroUtxosWithAccountInfo(
            account: e.index,
            utxos:
                e.utxos.map((e) => MoneroUtxoWithSpendingInfo.unconfirmed(e)).toList()))
        .toList();
  }

  List<TxKeyImage> keyImages() => _indexes.expand((e) => e.keyImages()).toList();

  @override
  List get variables => [derivationKey];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.moneroSyncAccount;

  @override
  List<CborObject?> get serializationItems => [
        derivationKey.toCbor(),
        AppSerialization.listFromObjects(_indexes.map((e) => e.toCbor()).toList()),
      ];
}

class MoneroSyncRequestAccount with AppSerialization {
  final MoneroNetwork network;
  final List<MoneroSyncAccount> accounts;
  final LongTimeMemorySecretKey secretKeys;
  MoneroSyncRequestAccount(
      {required List<MoneroSyncAccount> accounts,
      required this.network,
      required this.secretKeys})
      : accounts = accounts.immutable;

  factory MoneroSyncRequestAccount.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    return MoneroSyncRequestAccount(
        accounts: values
            .listAt<CborTagValue>(0)
            .map((e) => MoneroSyncAccount.deserialize(object: e))
            .toList(),
        network: MoneroNetwork.fromValue(values.rawValueAt(1)),
        secretKeys: LongTimeMemorySecretKey.deserialize(object: values.objectAt(2)));
  }

  MoneroSyncAccount onlyAccount(MoneroViewPrimaryAccountDetails derivationKey) {
    return accounts.firstWhere((e) => e.derivationKey == derivationKey).onlyAccount();
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(accounts.map((e) => e.toCbor()).toList()),
        network.value.toCbor(),
        secretKeys.toCbor()
      ];
}

sealed class MoneroBlockSyncedOffset extends BlockSyncedOffset {
  MoneroBlockSyncedOffset(
      {required super.currentHeight, required super.total, required super.status});
  List<TxKeyImage> getUtxoKeyImages();
}

final class MoneroSyncOffsetResponse extends MoneroBlockSyncedOffset {
  final MoneroBlockTrackingRequestOffset request;
  final Set<MoneroSyncAccount> accounts;
  final Set<TxKeyImage> keyImages;
  @override
  BlockTrackingOffset get offset => request.offset;
  @override
  int? get requestId => request.requestId;
  bool get hasTx => accounts.any((e) => e.hasUtxo);

  @override
  List<TxKeyImage> getUtxoKeyImages() {
    return accounts.expand((e) => e.keyImages()).toList();
  }

  MoneroSyncOffsetResponse copyWith(
      {MoneroBlockTrackingRequestOffset? request,
      Set<MoneroSyncAccount>? accounts,
      Set<TxKeyImage>? keyImages,
      BlockSyncStatus? status,
      int? total,
      int? currentHeight}) {
    return MoneroSyncOffsetResponse(
        accounts: accounts ?? this.accounts,
        currentHeight: currentHeight ?? this.currentHeight,
        total: total ?? this.total,
        request: request ?? this.request,
        status: status ?? this.status,
        keyImages: keyImages ?? this.keyImages);
  }

  MoneroSyncOffsetResponse({
    required Iterable<MoneroSyncAccount> accounts,
    required super.currentHeight,
    required super.total,
    required this.request,
    required super.status,
    required Iterable<TxKeyImage> keyImages,
  })  : accounts = accounts.toImutableSet,
        keyImages = keyImages.toImutableSet;

  factory MoneroSyncOffsetResponse.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    return MoneroSyncOffsetResponse(
        accounts: values
            .listAt<CborTagValue>(0)
            .map((e) => MoneroSyncAccount.deserialize(object: e))
            .toList(),
        currentHeight: values.rawValueAt(1),
        total: values.rawValueAt(2),
        request: MoneroBlockTrackingRequestOffset.deserialize(
            object: values.objectAt<CborTagValue>(3)),
        status: BlockSyncStatus.deserialize(object: values.objectAt(4)),
        keyImages: values
            .listAt<CborTagValue>(5)
            .map((e) => TxKeyImage.deserialize(obj: e))
            .toList());
  }

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(accounts.map((e) => e.toCbor()).toList()),
        currentHeight.toCbor(),
        total.toCbor(),
        request.toCbor(),
        status.toCbor(),
        AppSerialization.listFromObjects(keyImages.map((e) => e.toCbor()).toList()),
      ];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  String toString() {
    return "height: ${currentHeight + total}, $request $status";
  }
}

class MoneroMergeAccountResult {
  final List<MoneroUtxosWithAccountInfo> utxos;
  final bool updated;
  const MoneroMergeAccountResult({this.utxos = const [], this.updated = false});

  MoneroMergeAccountResult operator +(MoneroMergeAccountResult other) {
    return MoneroMergeAccountResult(
        utxos: [...utxos, ...other.utxos], updated: updated | other.updated);
  }

  @override
  String toString() {
    return "MoneroMergeAccountResult {utxos: ${utxos.length}, updated: $updated}";
  }
}

class MoneroMergeResult {
  final MoneroMergeAccountResult account;
  final UpdateOffsetResult status;
  const MoneroMergeResult({required this.account, required this.status});

  @override
  String toString() {
    return "MoneroMergeResult {account: $account, status: $status}";
  }
}

class MoneroSyncAccountRequest {
  final List<MoneroAccountIndex> indexes;
  final int startHeight;
  final int endHeight;
  final String heightsStr;
  MoneroSyncAccountRequest(
      {required this.indexes, required this.startHeight, required this.endHeight})
      : heightsStr = "$startHeight/$endHeight";
}
