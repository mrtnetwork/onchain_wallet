part of 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

final class AdaLegacyPublicKeyData extends CryptoPublicKeyData {
  final String hdPathKey;
  @override
  String get chainCode => super.chainCode!;
  AdaLegacyPublicKeyData._(
      {required super.extendedKey,
      required super.comprossed,
      required super.uncomprossed,
      // required this.keyName,
      required this.hdPathKey,
      required String super.chainCode,
      required super.coin,
      required super.curve})
      : super._(type: CryptoPublicKeyDataType.ada);
  factory AdaLegacyPublicKeyData._fromBip32(
      {required Bip32Base<dynamic> account,
      required List<int> hdPathKey,
      required CryptoCoins coin}) {
    final comperesed = BytesUtils.toHexString(account.publicKey.compressed);
    final uncompresed = BytesUtils.toHexString(account.publicKey.uncompressed);
    if (!coin.proposal.isBip) {
      throw AppCryptoExceptionConst.invalidCoin;
    }
    return AdaLegacyPublicKeyData._(
        extendedKey: account.publicKey.toExtended,
        comprossed: comperesed,
        uncomprossed: uncompresed == comperesed ? null : uncompresed,
        // keyName: keyName,
        chainCode: account.chainCode.toHex(),
        hdPathKey: BytesUtils.toHexString(hdPathKey),
        curve: account.curveType,
        coin: coin);
  }
  factory AdaLegacyPublicKeyData.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.accessAdaPubliKeyResponse);
    return AdaLegacyPublicKeyData._(
        extendedKey: values.rawValueAt(0),
        comprossed: values.rawValueAt(1),
        uncomprossed: values.rawValueAt(2),
        // keyName: values.rawValueAt(3),
        hdPathKey: values.rawValueAt(3),
        chainCode: values.rawValueAt(4),
        curve: EllipticCurveTypes.fromName(values.rawValueAt(5)),
        coin: CoinsUtils.getSerializationCoin(values.rawValueAt<int>(6)));
  }

  List<int> hdPathKeyBytes() {
    return BytesUtils.fromHexString(hdPathKey);
  }

  @override
  List<int> chainCodeBytes() {
    return BytesUtils.fromHexString(chainCode);
  }

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;

  @override
  List<CborObject?> get serializationItems => [
        extendedKey?.toCbor(),
        comprossed.toCbor(),
        uncomprossed?.toCbor(),
        hdPathKey.toCbor(),
        chainCode.toCbor(),
        curve.name.toCbor(),
        coin.identifier.toCbor(),
      ];

  @override
  Bip32Base? toHdKey() {
    final extendedKey = this.extendedKey;
    if (extendedKey == null) return null;
    return CryptoKeyUtils.extendedKeyToBip32Key(extendedKey: extendedKey, coin: coin);
  }
}
