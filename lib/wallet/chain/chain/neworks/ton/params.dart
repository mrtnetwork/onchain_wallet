part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class TonNewAddressParams extends NewDerivableAccountParams<ITonAddress> {
  @override
  final CryptoCoins coin;
  final TonAccountContext context;
  @override
  final DerivableIndex deriveIndex;

  const TonNewAddressParams._(
      {required this.deriveIndex, required this.coin, required this.context});
  factory TonNewAddressParams(
      {required DerivableIndex deriveIndex,
      required CryptoCoins coin,
      required TonAccountContext context}) {
    return TonNewAddressParams._(deriveIndex: deriveIndex, coin: coin, context: context);
  }

  factory TonNewAddressParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NewAccountParamsType.tonNewAddressParams.tag);
    return TonNewAddressParams(
      deriveIndex: DerivableIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
      context: TonAccountContext.deserialize(object: values.objectAt<CborTagValue>(1)),
      coin: CoinsUtils.getSerializationCoin(values.rawValueAt(2)),
    );
  }

  @override
  ITonAddress toAccount(WalletNetwork network, CryptoPublicKeyData? publicKey, String? id,
      IAppDatabaseApi? database) {
    if (publicKey == null) {
      throw WalletExceptionConst.pubkeyRequired;
    }
    if (network is! WalletTonNetwork) {
      throw WalletExceptionConst.invalidAccountData("TonNewAddressParams.toAccount");
    }
    final keyBytes = publicKey.normalizedComprossedBytes.asImmutableBytes;
    final address = context.toWalletContract(keyBytes).address;
    return ITonAddress._newAccount(
        publicKey: keyBytes,
        network: network,
        address: address,
        database: database,
        coin: coin,
        addressContext: context,
        identifier: NewAccountParams.toIdentifier(address.toRawAddress()),
        derivationIndex: deriveIndex,
        id: id);
  }

  @override
  List<CborObject?> get serializationItems =>
      [deriveIndex.toCbor(), context.toCbor(), coin.identifier.toCbor()];
  @override
  NewAccountParamsType get type => NewAccountParamsType.tonNewAddressParams;
}
