part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class CosmosNewAddressParams extends NewDerivableAccountParams<ICosmosAddress> {
  @override
  final CryptoCoins coin;

  @override
  final DerivableIndex deriveIndex;

  final CosmosKeysAlgs algorithm;

  const CosmosNewAddressParams._(
      {required this.deriveIndex, required this.coin, required this.algorithm});
  factory CosmosNewAddressParams(
      {required DerivableIndex deriveIndex,
      required CryptoCoins coin,
      required CosmosKeysAlgs algorithm}) {
    return CosmosNewAddressParams._(
        deriveIndex: deriveIndex, coin: coin, algorithm: algorithm);
  }
  factory CosmosNewAddressParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NewAccountParamsType.cosmosNewAddressParams.tag);
    return CosmosNewAddressParams(
        deriveIndex: DerivableIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        coin: CoinsUtils.getSerializationCoin(values.rawValueAt(1)),
        algorithm: CosmosKeysAlgs.fromValue(values.rawValueAt(2)));
  }

  CosmosPublicKey toPublicKey(List<int> publicKey) {
    return CosmosPublicKey.fromBytes(keyBytes: publicKey, algorithm: algorithm);
  }

  @override
  ICosmosAddress toAccount(WalletNetwork network, CryptoPublicKeyData? publicKey,
      String? id, IAppDatabaseApi? database) {
    if (publicKey == null) {
      throw WalletExceptionConst.pubkeyRequired;
    }
    if (network is! WalletCosmosNetwork) {
      throw WalletExceptionConst.invalidAccountData("CosmosNewAddressParams.toAccount");
    }
    final publickKeyBytes = publicKey.normalizedComprossedBytes.asImmutableBytes;
    final pubKey = toPublicKey(publickKeyBytes);
    final address = pubKey.toAddress(hrp: network.coinParam.hrp);
    ETHAddress? ethAddress;
    if (algorithm.isEthereum) {
      if (pubKey case CosmosETHSecp256K1PublicKey()) {
        ethAddress = ETHAddress(pubKey.toEthAddress());
      } else {
        throw AppInternalError.internalError("CosmosNewAddressParams.toAccount",
            reason: "Invalud cosmos publicKey");
      }
    }
    return ICosmosAddress._newAccount(
        publicKey: publickKeyBytes,
        network: network,
        address: address,
        database: database,
        derivationIndex: deriveIndex,
        algorithm: algorithm,
        coin: coin,
        ethAddress: ethAddress,
        identifier: NewAccountParams.toIdentifier(address.address),
        id: id);
  }

  @override
  List<CborObject?> get serializationItems =>
      [deriveIndex.toCbor(), coin.identifier.toCbor(), algorithm.value.toCbor()];
  @override
  NewAccountParamsType get type => NewAccountParamsType.cosmosNewAddressParams;
}
