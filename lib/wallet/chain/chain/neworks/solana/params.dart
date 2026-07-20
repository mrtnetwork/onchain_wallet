part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class SolanaNewAddressParams extends NewDerivableAccountParams<ISolanaAddress> {
  @override
  final DerivableIndex deriveIndex;
  @override
  final CryptoCoins coin;
  SolanaNewAddressParams._({required this.deriveIndex, required this.coin});
  factory SolanaNewAddressParams(
      {required DerivableIndex deriveIndex, required CryptoCoins coin}) {
    return SolanaNewAddressParams._(deriveIndex: deriveIndex, coin: coin);
  }

  factory SolanaNewAddressParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NewAccountParamsType.solanaNewAddressParams.tag);
    return SolanaNewAddressParams(
      deriveIndex: DerivableIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
      coin: CoinsUtils.getSerializationCoin(values.rawValueAt(1)),
    );
  }

  @override
  ISolanaAddress toAccount(WalletNetwork network, CryptoPublicKeyData? publicKey,
      String? id, IAppDatabaseApi? database) {
    if (publicKey == null) {
      throw WalletExceptionConst.pubkeyRequired;
    }
    if (network is! WalletSolanaNetwork) {
      throw WalletExceptionConst.invalidAccountData("SolanaNewAddressParams.toAccount");
    }
    final keyBytes = publicKey.normalizedComprossedBytes.asImmutableBytes;
    final address = SolAddress.fromPublicKey(keyBytes);

    return ISolanaAddress._newAccount(
        publicKey: keyBytes,
        network: network,
        address: address,
        database: database,
        coin: coin,
        derivationIndex: deriveIndex,
        identifier: NewAccountParams.toIdentifier(address.address),
        id: id);
  }

  @override
  List<CborObject?> get serializationItems =>
      [deriveIndex.toCbor(), coin.identifier.toCbor()];
  @override
  NewAccountParamsType get type => NewAccountParamsType.solanaNewAddressParams;
}
