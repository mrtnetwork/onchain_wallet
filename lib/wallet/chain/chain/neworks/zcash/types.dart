part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

class ZcashNetworkStorageId extends DefaultNetworkStorageId {
  static const ZcashNetworkStorageId transparentUtxos = ZcashNetworkStorageId(51);
  static const ZcashNetworkStorageId saplingUtxos = ZcashNetworkStorageId(52);
  static const ZcashNetworkStorageId orchardUtxos = ZcashNetworkStorageId(53);
  static const ZcashNetworkStorageId defaultTracker = ZcashNetworkStorageId(54);
  static const ZcashNetworkStorageId chainTreeState = ZcashNetworkStorageId(55);
  const ZcashNetworkStorageId(super.storageId);
  static const List<DefaultNetworkStorageId> values = [
    ...DefaultNetworkStorageId.values,
    transparentUtxos,
    saplingUtxos,
    orchardUtxos,
    defaultTracker,
    chainTreeState
  ];
}

enum ZcashChainNotify implements ChainNotify {
  trackerOffsetUpdated(0),
  trackerOffsetChanged(1),
  trackerAccountChanged(2),
  syncingStatusChanged(3),
  blockHeightUpdated(4),
  accountUtxosChanged(5);

  @override
  final int value;
  const ZcashChainNotify(this.value);
}

class ZcashSyncChain with AppSerialization, Equality {
  final int value;
  final ZcashNetwork? network;
  const ZcashSyncChain._(this.value, this.network);
  static const ZcashSyncChain none = ZcashSyncChain._(0, null);
  static const ZcashSyncChain mainnet = ZcashSyncChain._(1, ZcashNetwork.mainnet);
  static const ZcashSyncChain testnet = ZcashSyncChain._(2, ZcashNetwork.testnet);
  static const ZcashSyncChain regtest = ZcashSyncChain._(3, ZcashNetwork.regtest);
  factory ZcashSyncChain.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.zcashSyncChain);
    final int value = values.rawValueAt(0);
    return switch (value) {
      0 => ZcashSyncChain.none,
      1 => ZcashSyncChain.mainnet,
      2 => ZcashSyncChain.testnet,
      3 => ZcashSyncChain.regtest,
      _ => throw AppInternalError.internalError("ZcashSyncChain")
    };
  }
  static const List<ZcashSyncChain> values = [none, mainnet, testnet, regtest];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.zcashSyncChain;
  @override
  List<CborObject?> get serializationItems => [value.toCbor()];
  @override
  List get variables => [value];
}

class ZcashChainStorageId extends DefaultChainStorageId {
  static const ZcashChainStorageId syncChain = ZcashChainStorageId(102);

  const ZcashChainStorageId(super.storageId);
  static const List<DefaultChainStorageId> values = [
    ...DefaultChainStorageId.values,
    syncChain
  ];
}
