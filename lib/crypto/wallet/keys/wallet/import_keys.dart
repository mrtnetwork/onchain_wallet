part of 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

final class ImportCustomKeys with AppSerialization {
  final String privateKey;
  final String publicKey;
  final CryptoCoins coin;
  const ImportCustomKeys._(
      {required this.privateKey, required this.publicKey, required this.coin});

  factory ImportCustomKeys.fromPrivateKey(
      {required List<int> privateKey, required CryptoCoins coin}) {
    final key = IPrivateKey.fromBytes(privateKey, coin.conf.type);
    return ImportCustomKeys._fromBytes(
        privateKey: key.raw,
        publicKey: CryptoKeyUtils.toPublicBytes(key.publicKey.compressed, coin.conf.type),
        coin: coin);
  }
  factory ImportCustomKeys._fromBytes(
      {required List<int> privateKey,
      required List<int> publicKey,
      required CryptoCoins coin}) {
    return ImportCustomKeys._(
        privateKey: BytesUtils.toHexString(privateKey),
        publicKey: BytesUtils.toHexString(publicKey),
        coin: coin);
  }
  factory ImportCustomKeys.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.importCustomKeys);
    return ImportCustomKeys._(
        privateKey: values.rawValueAt(0),
        publicKey: values.rawValueAt(1),
        coin: CoinsUtils.getSerializationCoin(values.rawValueAt(2)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.importCustomKeys;

  @override
  List<CborObject?> get serializationItems => [
        privateKey.toCbor(),
        publicKey.toCbor(),
        coin.identifier.toCbor(),
      ];
}
