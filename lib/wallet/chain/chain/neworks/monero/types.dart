part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

enum MoneroChainNotify implements ChainNotify {
  trackerOffsetUpdated(0),
  trackerOffsetChanged(1),
  trackerAccountChanged(2),
  syncingStatusChanged(3),
  blockHeightUpdated(4),
  accountUtxosChanged(5);

  @override
  final int value;
  const MoneroChainNotify(this.value);
}

class MoneroSyncChain with AppSerialization, Equality {
  final int value;
  final MoneroNetwork? network;
  const MoneroSyncChain._(this.value, this.network);
  static const MoneroSyncChain none = MoneroSyncChain._(0, null);
  static const MoneroSyncChain mainnet = MoneroSyncChain._(1, MoneroNetwork.mainnet);
  static const MoneroSyncChain testnet = MoneroSyncChain._(2, MoneroNetwork.testnet);
  static const MoneroSyncChain stagenet = MoneroSyncChain._(3, MoneroNetwork.stagenet);
  factory MoneroSyncChain.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.moneroSyncChain);
    final int value = values.rawValueAt(0);
    return switch (value) {
      0 => MoneroSyncChain.none,
      1 => MoneroSyncChain.mainnet,
      2 => MoneroSyncChain.testnet,
      3 => MoneroSyncChain.stagenet,
      _ => throw AppInternalError.internalError("MoneroSyncChain")
    };
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.moneroSyncChain;
  @override
  List<CborObject?> get serializationItems => [value.toCbor()];
  @override
  List get variables => [value];
}

class MoneroNetworkStorageId extends DefaultNetworkStorageId {
  static const MoneroNetworkStorageId defaultTracker = MoneroNetworkStorageId(51);
  static const MoneroNetworkStorageId walletRPC = MoneroNetworkStorageId(52);
  static const MoneroNetworkStorageId addressUtxos = MoneroNetworkStorageId(53);
  const MoneroNetworkStorageId(super.storageId);
  static const List<DefaultNetworkStorageId> values = [
    ...DefaultNetworkStorageId.values,
    defaultTracker,
    walletRPC,
    addressUtxos,
  ];
}

class MoneroChainStorageId extends DefaultChainStorageId {
  static const MoneroChainStorageId syncChain = MoneroChainStorageId(101);
  const MoneroChainStorageId(super.storageId);
  static const List<DefaultChainStorageId> values = [
    ...DefaultChainStorageId.values,
    syncChain
  ];
}
