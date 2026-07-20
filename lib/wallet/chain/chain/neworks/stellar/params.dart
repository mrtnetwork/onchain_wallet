part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class StellarNewAddressParams extends NewDerivableAccountParams<IStellarAddress> {
  EllipticCurveTypes get curve => coin.conf.type;

  @override
  final DerivableIndex deriveIndex;

  final BigInt? id;
  @override
  final CryptoCoins coin;
  const StellarNewAddressParams._(
      {required this.deriveIndex, required this.coin, this.id});
  factory StellarNewAddressParams(
      {required DerivableIndex deriveIndex, required CryptoCoins coin, BigInt? id}) {
    return StellarNewAddressParams._(deriveIndex: deriveIndex, coin: coin, id: id);
  }

  factory StellarNewAddressParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NewAccountParamsType.stellarNewAddressParams.tag);
    return StellarNewAddressParams(
      deriveIndex: DerivableIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
      id: values.rawValueAt(1),
      coin: CoinsUtils.getSerializationCoin(values.rawValueAt(2)),
    );
  }
  @override
  IStellarAddress toAccount(WalletNetwork network, CryptoPublicKeyData? publicKey,
      String? id, IAppDatabaseApi? database) {
    if (publicKey == null) {
      throw WalletExceptionConst.pubkeyRequired;
    }
    if (network is! WalletStellarNetwork) {
      throw WalletExceptionConst.invalidAccountData("StellarNewAddressParams.toAccount");
    }
    final keyBytes = publicKey.keyBytes(immutable: true);
    final BigInt? muxId = this.id;
    StellarAddress address;
    if (muxId != null) {
      address = StellarMuxedAddress.fromPublicKey(publicKey: keyBytes, accountId: muxId);
    } else {
      address = StellarAccountAddress.fromPublicKey(keyBytes);
    }
    return IStellarAddress._newAccount(
        publicKey: keyBytes,
        network: network,
        address: address,
        database: database,
        coin: coin,
        muxId: muxId,
        derivationIndex: deriveIndex,
        identifier: NewAccountParams.toIdentifier(address.address),
        id: id);
  }

  @override
  List<CborObject?> get serializationItems =>
      [deriveIndex.toCbor(), id?.toCbor(), coin.identifier.toCbor()];
  @override
  NewAccountParamsType get type => NewAccountParamsType.stellarNewAddressParams;
}
