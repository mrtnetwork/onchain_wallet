part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class ITonAddress extends ChainAccount<TonAddress, TonJettonToken, NFTCore,
    TonWalletTransaction, WalletTonNetwork> {
  ITonAddress._({
    required super.derivationIndex,
    required super.database,
    required super.coin,
    required List<int> publicKey,
    required super.address,
    required super.network,
    required super.networkAddress,
    required this.context,
    required super.identifier,
    required super.id,
  }) : publicKey = publicKey.asImmutableBytes;

  factory ITonAddress._newAccount({
    required List<int> publicKey,
    required WalletTonNetwork network,
    required CryptoCoins coin,
    required TonAddress address,
    required String identifier,
    required DerivableIndex derivationIndex,
    required TonAccountContext addressContext,
    required IAppDatabaseApi? database,
    required String? id,
  }) {
    return ITonAddress._(
        coin: coin,
        publicKey: publicKey,
        address: address.toFriendly(bounceable: addressContext.bouncable).address,
        derivationIndex: derivationIndex,
        database: database,
        networkAddress: address,
        network: network,
        context: addressContext,
        identifier: identifier,
        id: id);
  }

  factory ITonAddress.deserialize(
      {required WalletTonNetwork network,
      required String? id,
      required IAppDatabaseApi? database,
      List<int>? bytes,
      CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.tonAccount);
    final CryptoCoins coin = CoinsUtils.getSerializationCoin(cbor.rawValueAt(0));
    final derivationIndex =
        DerivationIndex.deserialize(object: cbor.objectAt<CborTagValue>(1));
    final List<int> publicKey = cbor.rawValueAt(2);

    final TonAddress tonAddress =
        TonAddress.deserializeIAddress(bytes: cbor.rawValueAt(3));

    final int networkId = cbor.rawValueAt(4);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final context = TonAccountContext.deserialize(object: cbor.objectAt<CborTagValue>(5));
    final String identifier = cbor.rawValueAt(6);
    return ITonAddress._(
        coin: coin,
        publicKey: publicKey,
        address: tonAddress.address,
        derivationIndex: derivationIndex,
        database: database,
        networkAddress: tonAddress,
        network: network,
        context: context,
        identifier: identifier,
        id: id);
  }

  final TonAccountContext context;
  final List<int> publicKey;

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.tonAccount;
  @override
  List<CborObject?> get serializationItems => [
        coin.identifier.toCbor(),
        derivationIndex.toCbor(),
        publicKey.toCborBytes(),
        CborBytesValue(networkAddress.encodeAsIAddress()),
        network.value.toCbor(),
        context.toCbor(),
        identifier.toCbor(),
      ];
  @override
  List get variables {
    return [derivationIndex, network.value, networkAddress, context];
  }

  @override
  late final String? type = switch (networkAddress.config.workchain) {
    TonWorkChain.basechain => "BaseChain(${context.version.name})",
    _ => "MasterChain(${context.version.name})"
  };

  VersionedWalletContract toWalletContract() {
    return context.toWalletContract(publicKey);
  }

  @override
  TonNewAddressParams toAccountParams() {
    return TonNewAddressParams(
        deriveIndex: derivationIndex.cast<DerivableIndex>(),
        coin: coin,
        context: context);
  }

  @override
  String get baseAddress => networkAddress.toRawAddress();
}
