part of 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

final class PrivateKeyData extends CryptoPrivateKeyData {
  @override
  final CryptoCoins coin;
  @override
  final String privateKey;
  @override
  final String? extendedKey;
  @override
  final String? wif;
  // @override
  // final String keyName;
  @override
  final CryptoPublicKeyData publicKey;
  const PrivateKeyData.__(
      {required this.privateKey,
      required this.extendedKey,
      required this.coin,
      required this.wif,
      // required this.keyName,
      required this.publicKey})
      : super._();
  factory PrivateKeyData._fromBip32({
    required Bip32Base<dynamic> account,
    required CryptoCoins coin,
  }) {
    final wifKey = CryptoKeyUtils.toWif(privateKey: account.privateKey.raw, coin: coin);

    return PrivateKeyData.__(
        privateKey: account.privateKey.toHex(),
        extendedKey: account.privateKey.toExtended,
        coin: coin,
        wif: wifKey,
        // keyName: keyName,
        publicKey: PublicKeyData._fromBip32(account: account, coin: coin));
  }
  factory PrivateKeyData._fromExtendedKey({
    required String extendedKey,
    required CryptoCoins coin,
    // required String keyName,
  }) {
    final bipKey =
        CryptoKeyUtils.extendedKeyToBip32Key(extendedKey: extendedKey, coin: coin);
    final wifKey = CryptoKeyUtils.toWif(privateKey: bipKey.privateKey.raw, coin: coin);
    return PrivateKeyData.__(
        privateKey: bipKey.privateKey.toHex(),
        extendedKey: bipKey.privateKey.toExtended,
        coin: coin,
        wif: wifKey,
        publicKey: PublicKeyData._fromBip32(account: bipKey, coin: coin));
  }
  factory PrivateKeyData.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.accessPrivateKeyResponse);
    final CryptoCoins coin = CoinsUtils.getSerializationCoin(cbor.rawValueAt(0));
    return PrivateKeyData.__(
        coin: coin,
        privateKey: cbor.rawValueAt(1),
        extendedKey: cbor.rawValueAt(2),
        wif: cbor.rawValueAt(3),
        // keyName: cbor.rawValueAt(4),
        publicKey: PublicKeyData.deserialize(object: cbor.objectAt<CborTagValue>(4)));
  }

  factory PrivateKeyData._(
      {required CryptoCoins coin,
      // required String keyName,
      required IPrivateKey key}) {
    return PrivateKeyData.__(
        privateKey: key.toHex(),
        extendedKey: null,
        coin: coin,
        wif: CryptoKeyUtils.toWif(privateKey: key.raw, coin: coin),
        publicKey: PublicKeyData._(key: key.publicKey, coin: coin));
  }

  @override
  Bip32Base toHdKey() {
    final extendedKey = this.extendedKey;
    if (!coin.proposal.isBip || extendedKey == null) {
      throw AppCryptoExceptionConst.invalidCoin;
    }
    // if (extendedKey == null) {
    //   return CryptoKeyUtils.privteKeyToBip32(
    //       privateKey: privateKey, coin: coin);
    // }
    return CryptoKeyUtils.extendedKeyToBip32Key(extendedKey: extendedKey, coin: coin);
  }

  @override
  List<int> privateKeyBytes() {
    return BytesUtils.fromHexString(privateKey);
  }

  @override
  CryptoPrivateKeyDataType get type => CryptoPrivateKeyDataType.public;

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;

  @override
  List<CborObject?> get serializationItems => [
        coin.identifier.toCbor(),
        privateKey.toCbor(),
        extendedKey?.toCbor(),
        wif?.toCbor(),
        publicKey.toCbor()
      ];
}
