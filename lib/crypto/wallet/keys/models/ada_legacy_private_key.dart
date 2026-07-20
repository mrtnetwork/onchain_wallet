part of 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

final class ADALegacyPrivateKeyData extends CryptoPrivateKeyData {
  @override
  final CryptoCoins coin;
  @override
  final String privateKey;
  @override
  final String extendedKey;
  @override
  final String? wif;
  // @override
  // final String keyName;

  @override
  final CryptoPublicKeyData publicKey;
  factory ADALegacyPrivateKeyData.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.accessAdaLegacyPrivateKeyResponse);
    final CryptoCoins coin = CoinsUtils.getSerializationCoin(cbor.rawValueAt(0));
    return ADALegacyPrivateKeyData._(
        coin: coin,
        privateKey: cbor.rawValueAt(1),
        extendedKey: cbor.rawValueAt(2),
        wif: cbor.rawValueAt(3),
        // keyName: cbor.rawValueAt(4),
        publicKey:
            AdaLegacyPublicKeyData.deserialize(object: cbor.objectAt<CborTagValue>(4)));
  }

  const ADALegacyPrivateKeyData._(
      {required this.privateKey,
      required this.extendedKey,
      required this.coin,
      required this.wif,
      // required this.keyName,
      required this.publicKey})
      : super._();

  @override
  Bip32Base toHdKey() {
    return CryptoKeyUtils.extendedKeyToBip32Key(extendedKey: extendedKey, coin: coin);
  }

  @override
  List<int> privateKeyBytes() {
    return BytesUtils.fromHexString(privateKey);
  }

  @override
  CryptoPrivateKeyDataType get type => CryptoPrivateKeyDataType.ada;

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;

  @override
  List<CborObject?> get serializationItems => [
        coin.identifier.toCbor(),
        privateKey.toCbor(),
        extendedKey.toCbor(),
        wif?.toCbor(),
        publicKey.toCbor()
      ];
}
