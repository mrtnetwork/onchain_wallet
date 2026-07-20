part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class IEthereumAddress extends ChainAccount<ETHAddress, ETHERC20Token, NFTCore,
    EthWalletTransaction, WalletEthereumNetwork> {
  IEthereumAddress._(
      {required super.derivationIndex,
      required super.database,
      required super.coin,
      required super.address,
      required super.network,
      required super.networkAddress,
      required super.identifier,
      required List<int> publicKey,
      required super.id})
      : publicKey = publicKey.asImmutableBytes;

  factory IEthereumAddress._newAccount({
    required List<int> publicKey,
    required WalletEthereumNetwork network,
    required CryptoCoins coin,
    required ETHAddress address,
    required String identifier,
    required DerivationIndex derivationIndex,
    required IAppDatabaseApi? database,
    required String? id,
  }) {
    return IEthereumAddress._(
        coin: coin,
        address: address.address,
        derivationIndex: derivationIndex,
        database: database,
        networkAddress: address,
        network: network,
        publicKey: publicKey,
        identifier: identifier,
        id: id);
  }

  factory IEthereumAddress.deserialize(
      {required WalletEthereumNetwork network,
      required String? id,
      required IAppDatabaseApi? database,
      List<int>? bytes,
      CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.ethAccount);
    final CryptoCoins coin = CoinsUtils.getSerializationCoin(values.rawValueAt(0));
    final derivationIndex =
        DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(1));
    final ETHAddress ethAddress =
        ETHAddress.deserializeIAddress(bytes: values.rawValueAt(2));
    final int networkId = values.rawValueAt(3);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final List<int> publicKey = values.rawValueAt(4);
    final String identifier = values.rawValueAt(5);
    return IEthereumAddress._(
        coin: coin,
        address: ethAddress.address,
        derivationIndex: derivationIndex,
        database: database,
        networkAddress: ethAddress,
        network: network,
        publicKey: publicKey,
        identifier: identifier,
        id: id);
  }

  final List<int> publicKey;

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.ethAccount;
  @override
  List<CborObject?> get serializationItems => [
        coin.identifier.toCbor(),
        derivationIndex.toCbor(),
        CborBytesValue(networkAddress.encodeAsIAddress()),
        network.value.toCbor(),
        CborBytesValue(publicKey),
        identifier.toCbor()
      ];
  @override
  List get variables {
    return [derivationIndex, network.value];
  }

  @override
  String? get type => null;

  @override
  EthereumNewAddressParams toAccountParams() {
    return switch (derivationIndex) {
      DerivableIndex index => EthereumNewAddressParams(deriveIndex: index, coin: coin),
      _ => throw AppCryptoExceptionConst.invalidDerivationKey
    };
  }
}
