part of 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

final class PublicKeyData extends CryptoPublicKeyData {
  // @override
  // final String keyName;

  PublicKeyData.__(
      {required super.extendedKey,
      required super.comprossed,
      required super.uncomprossed,
      // required this.keyName,
      required super.chainCode,
      required super.curve,
      required super.coin})
      : super._(type: CryptoPublicKeyDataType.public);
  factory PublicKeyData._fromBip32({
    required Bip32Base<dynamic> account,
    required CryptoCoins coin,
  }) {
    final comperesed = BytesUtils.toHexString(account.publicKey.compressed);
    final uncompresed = BytesUtils.toHexString(account.publicKey.uncompressed);
    if (!coin.proposal.isBip) {
      throw AppCryptoExceptionConst.invalidCoin;
    }
    return PublicKeyData.__(
        extendedKey: account.publicKey.toExtended,
        comprossed: comperesed,
        uncomprossed: uncompresed == comperesed ? null : uncompresed,
        // keyName: keyName,
        chainCode: account.publicKey.chainCode.toHex(),
        curve: account.curveType,
        coin: coin);
  }

  factory PublicKeyData._({
    required IPublicKey key,
    required CryptoCoins coin,
    // required String keyName,
  }) {
    final comperesed = BytesUtils.toHexString(key.compressed);
    final uncompresed = BytesUtils.toHexString(key.uncompressed);
    if (!coin.proposal.isBip && !coin.proposal.isSubstrate) {
      throw AppCryptoExceptionConst.invalidCoin;
    }
    return PublicKeyData.__(
        extendedKey: null,
        comprossed: key.toHex(),
        uncomprossed: uncompresed == comperesed ? null : uncompresed,
        // keyName: keyName,
        chainCode: null,
        curve: key.curve,
        coin: coin);
  }

  factory PublicKeyData.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.accessPubliKeyResponse);
    return PublicKeyData.__(
        extendedKey: values.rawValueAt(0),
        comprossed: values.rawValueAt(1),
        uncomprossed: values.rawValueAt(2),
        // keyName: values.rawValueAt(3),
        chainCode: values.rawValueAt(3),
        curve: EllipticCurveTypes.fromName(values.rawValueAt(4)),
        coin: CoinsUtils.getSerializationCoin(values.rawValueAt<int>(5)));
  }

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;

  @override
  List<CborObject?> get serializationItems => [
        extendedKey?.toCbor(),
        comprossed.toCbor(),
        uncomprossed?.toCbor(),
        chainCode?.toCbor(),
        curve.name.toCbor(),
        coin.identifier.toCbor()
      ];

  @override
  Bip32Base? toHdKey() {
    final extendedKey = this.extendedKey;
    if (extendedKey == null || !coin.proposal.isBip) return null;
    return CryptoKeyUtils.extendedKeyToBip32Key(extendedKey: extendedKey, coin: coin);
  }
}
