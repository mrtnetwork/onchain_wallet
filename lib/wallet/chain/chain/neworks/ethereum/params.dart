part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class EthereumNewAddressParams extends NewDerivableAccountParams<IEthereumAddress> {
  @override
  final DerivableIndex deriveIndex;
  @override
  final CryptoCoins coin;
  const EthereumNewAddressParams._({required this.deriveIndex, required this.coin});
  factory EthereumNewAddressParams(
      {required DerivableIndex deriveIndex, required CryptoCoins coin}) {
    return EthereumNewAddressParams._(deriveIndex: deriveIndex, coin: coin);
  }
  factory EthereumNewAddressParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NewAccountParamsType.ethereumNewAddressParamss.tag);
    return EthereumNewAddressParams(
      deriveIndex: DerivableIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
      coin: CoinsUtils.getSerializationCoin(values.rawValueAt(1)),
    );
  }

  @override
  IEthereumAddress toAccount(WalletNetwork network, CryptoPublicKeyData? publicKey,
      String? id, IAppDatabaseApi? database) {
    if (publicKey == null) {
      throw WalletExceptionConst.pubkeyRequired;
    }
    if (network is! WalletEthereumNetwork) {
      throw WalletExceptionConst.invalidAccountData("EthereumNewAddressParams.toAccount");
    }
    final keyBytes = publicKey.keyBytes(immutable: true);
    final address = ETHAddress.fromPublicKey(keyBytes);
    return IEthereumAddress._newAccount(
        address: address,
        coin: coin,
        database: database,
        identifier: NewAccountParams.toIdentifier(address.address),
        derivationIndex: deriveIndex,
        publicKey: keyBytes,
        network: network,
        id: id);
  }

  @override
  List<CborObject?> get serializationItems =>
      [deriveIndex.toCbor(), coin.identifier.toCbor()];
  @override
  NewAccountParamsType get type => NewAccountParamsType.ethereumNewAddressParamss;
}
