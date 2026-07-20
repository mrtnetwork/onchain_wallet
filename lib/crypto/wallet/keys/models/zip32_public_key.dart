part of 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

final class Zip32PublicKeyData extends BaseZip32PublicKeyData {
  // @override
  // final String keyName;

  @override
  PublicKeysView get toViewKey => PublicKeysView._(
      extendKey: extendedKey,
      comprossed: comprossed,
      uncomprossed: uncomprossed,
      chainCode: chainCode,
      // keyName: keyName,
      keyType: CryptoPublicKeyDataType.zip32);

  Zip32PublicKeyData.__(
      {required super.extendedKey,
      // required this.keyName,
      required super.chainCode,
      required super.comprossed,
      required super.protocol,
      required super.coin})
      : super(
            type: CryptoPublicKeyDataType.zip32,
            uncomprossed: null,
            curve: switch (protocol) {
              Zip32Porotcol.zcashOrchard => EllipticCurveTypes.redPallas,
              Zip32Porotcol.zcashSapling => EllipticCurveTypes.redJubJub,
            });
  factory Zip32PublicKeyData._fromZip32({
    required Zip32Base account,
    // required String keyName,
    required ZIP32Coins coin,
  }) {
    final config = coin.conf;
    Zip32Porotcol protocol;
    List<int> fvk;
    String? extendedKey;
    switch (account) {
      case Zip32Sapling sapling when config.type == EllipticCurveTypes.redJubJub:
        fvk = sapling.publicKey.toDiversifiableFullViewingKey().toBytes();
        protocol = Zip32Porotcol.zcashSapling;
        extendedKey = sapling.publicKey.encodeExtendedFullViewKey(coin.conf);
        break;
      case Zip32Orchard orchard when config.type == EllipticCurveTypes.redPallas:
        fvk = orchard.publicKey.fvk.toBytes();
        protocol = Zip32Porotcol.zcashOrchard;
        break;
      default:
        throw AppInternalError.internalError("Invalid zip32 coin config.");
    }
    return Zip32PublicKeyData.__(
        extendedKey: extendedKey,
        // keyName: keyName,
        chainCode: account.chainCode.toHex(),
        protocol: protocol,
        comprossed: BytesUtils.toHexString(fvk),
        coin: coin);
  }
  factory Zip32PublicKeyData.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.accessZip32PublicKeyResponse);
    return Zip32PublicKeyData.__(
        extendedKey: values.rawValueAt(0),
        // keyName: values.rawValueAt(1),
        chainCode: values.rawValueAt(1),
        protocol: Zip32Porotcol.fromValue(values.rawValueAt(2)),
        comprossed: values.rawValueAt(3),
        coin: CoinsUtils.getSerializationCoin(values.rawValueAt<int>(4)));
  }

  @override
  CryptoPublicKeyDataType get type => CryptoPublicKeyDataType.zip32;

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;

  @override
  List<CborObject?> get serializationItems => [
        extendedKey?.toCbor(),
        // keyName,
        chainCode?.toCbor(),
        protocol.value.toCbor(),
        comprossed.toCbor(),
        coin.identifier.toCbor()
      ];

  @override
  Zip32Base? toHdKey() {
    final conf = coin.conf;
    switch (conf.type) {
      case EllipticCurveTypes.redJubJub:
        final extendedKey = this.extendedKey;
        if (extendedKey == null) return null;
        return Zip32Sapling.fromExtendedFullViewKey(extendedKey);
      case EllipticCurveTypes.redPallas:
        return Zip32Orchard.fromFullViewKeyUnchecked(fvk: keyBytes());
      default:
        throw AppInternalError.internalError("Unknown zip32 derivation");
    }
  }

  DiversifiableFullViewingKey toFvk() {
    final conf = coin.conf;
    switch (conf.type) {
      case EllipticCurveTypes.redJubJub:
        return SaplingDiversifiableFullViewingKey.fromBytes(keyBytes());
      case EllipticCurveTypes.redPallas:
        return OrchardFullViewingKey.fromBytesUnchecked(keyBytes());
      default:
        throw AppInternalError.internalError("Unknown zip32 derivation");
    }
  }
}
