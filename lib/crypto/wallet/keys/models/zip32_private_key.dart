part of 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

final class Zip32PrivateKeyData extends BaseZip32PrivateKeyData {
  @override
  final CryptoCoins coin;
  @override
  final String privateKey;

  @override
  final String? extendedKey;
  @override
  final String? wif = null;
  @override
  final Zip32Porotcol protocol;

  @override
  PrivateKeysView get toViewKey => PrivateKeysView._(
      extendKey: extendedKey,
      privateKey: privateKey,
      wif: wif,
      // keyName: keyName,
      keyType: CryptoPrivateKeyDataType.zip32,
      curve: coin.conf.type,
      inNetworkStyle: null);

  @override
  final Zip32PublicKeyData publicKey;
  factory Zip32PrivateKeyData.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.accessZip32PrivateKeyResponse);
    final CryptoCoins coin = CoinsUtils.getSerializationCoin(values.rawValueAt(0));
    return Zip32PrivateKeyData.__(
        privateKey: values.rawValueAt(1),
        extendedKey: values.rawValueAt(2),
        coin: coin,
        // keyName: values.rawValueAt(3),
        publicKey:
            Zip32PublicKeyData.deserialize(object: values.objectAt<CborTagValue>(3)),
        protocol: Zip32Porotcol.fromValue(values.rawValueAt(4)));
  }

  const Zip32PrivateKeyData.__({
    required this.privateKey,
    required this.extendedKey,
    required this.coin,
    // required this.keyName,
    required this.publicKey,
    required this.protocol,
  });
  factory Zip32PrivateKeyData._fromSaplingExtendedSpendKey({
    required String extendedSpendKey,
    required ZIP32Coins coin,
  }) {
    final config = coin.conf;
    if (config.type != EllipticCurveTypes.redJubJub) {
      throw AppCryptoExceptionConst.invalidCoin;
    }
    final account = Zip32Sapling.fromExtendedSpendingKey(extendedSpendKey, config);
    return Zip32PrivateKeyData._fromZip32(account: account, coin: coin);
  }

  factory Zip32PrivateKeyData._fromSaplingSpendKey({
    required String spendKey,
    required ZIP32Coins coin,
  }) {
    final config = coin.conf;
    if (config.type != EllipticCurveTypes.redJubJub) {
      throw AppCryptoExceptionConst.invalidCoin;
    }
    final account = Zip32Sapling.fromSpendKey(BytesUtils.fromHexString(spendKey));
    return Zip32PrivateKeyData._fromZip32(account: account, coin: coin);
  }

  factory Zip32PrivateKeyData._fromOrchardSpendKey({
    required String spendKey,
    required ZIP32Coins coin,
  }) {
    final config = coin.conf;
    if (config.type != EllipticCurveTypes.redPallas) {
      throw AppCryptoExceptionConst.invalidCoin;
    }
    final account =
        Zip32Orchard.fromSpendKey(sk: BytesUtils.fromHexString(spendKey), check: false);
    return Zip32PrivateKeyData._fromZip32(account: account, coin: coin);
  }

  factory Zip32PrivateKeyData._fromZip32({
    required Zip32Base account,
    required ZIP32Coins coin,
  }) {
    final config = coin.conf;
    String? extendedKey;
    List<int> sk;
    Zip32Porotcol protocol;
    switch (account) {
      case Zip32Sapling sapling when config.type == EllipticCurveTypes.redJubJub:
        sk = sapling.privateKey.toBytes();
        extendedKey = sapling.encodeExtendedSpendKey(config);
        protocol = Zip32Porotcol.zcashSapling;
        break;
      case Zip32Orchard orchard when config.type == EllipticCurveTypes.redPallas:
        sk = orchard.privateKey.sk.toBytes();
        protocol = Zip32Porotcol.zcashOrchard;
        break;
      default:
        throw AppCryptoExceptionConst.invalidCoin;
    }
    final publicKey = Zip32PublicKeyData._fromZip32(account: account, coin: coin);
    return Zip32PrivateKeyData.__(
      privateKey: BytesUtils.toHexString(sk),
      protocol: protocol,
      extendedKey: extendedKey,
      coin: coin,
      publicKey: publicKey,
    );
  }

  factory Zip32PrivateKeyData._fromSeed({
    required List<int> seedBytes,
    required ZIP32Coins coin,
  }) {
    final conf = coin.conf;
    switch (conf.type) {
      case EllipticCurveTypes.redJubJub:
        final account = Zip32Sapling.fromSeed(seedBytes);
        return Zip32PrivateKeyData._fromZip32(account: account, coin: coin);
      case EllipticCurveTypes.redPallas:
        final account = Zip32Orchard.fromSeed(seedBytes);
        return Zip32PrivateKeyData._fromZip32(account: account, coin: coin);
      default:
        throw AppInternalError.internalError("Unknown zip32 derivation");
    }
  }

  @override
  Zip32Base toHdKey() {
    final conf = coin.conf;
    switch (conf.type) {
      case EllipticCurveTypes.redJubJub:
        return Zip32Sapling.fromExtendedSpendingKeyBytes(privateKeyBytes());
      case EllipticCurveTypes.redPallas:
        return Zip32Orchard.fromSpendKey(sk: privateKeyBytes(), check: false);
      default:
        throw AppInternalError.internalError("Unknown zip32 derivation");
    }
  }

  @override
  List<int> privateKeyBytes() {
    return BytesUtils.fromHexString(privateKey);
  }

  @override
  CryptoPrivateKeyDataType get type => CryptoPrivateKeyDataType.zip32;

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;

  @override
  List<CborObject?> get serializationItems => [
        coin.identifier.toCbor(),
        privateKey.toCbor(),
        extendedKey?.toCbor(),
        publicKey.toCbor(),
        protocol.value.toCbor(),
      ];
}
