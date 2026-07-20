part of 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

final class MoneroPublicKeyData extends CryptoPublicKeyData {
  final MoneroPublicKey spendPublicKey;
  final MoneroPublicKey viewPublicKey;
  final MoneroPrivateKey viewPrivateKey;
  // @override
  // final String keyName;

  @override
  PublicKeysView get toViewKey => MoneroPublicKeysView._(
      extendKey: extendedKey,
      comprossed: comprossed,
      uncomprossed: uncomprossed,
      chainCode: chainCode,
      spendPublicKey: spendPublicKey.toHex(),
      viewPublicKey: viewPublicKey.toHex(),
      // keyName: keyName,
      keyType: type);

  MoneroPublicKeyData.__(
      {required super.extendedKey,
      // required this.keyName,
      required this.spendPublicKey,
      required this.viewPublicKey,
      required this.viewPrivateKey,
      required super.chainCode,
      required super.comprossed,
      required super.coin})
      : super._(
            type: CryptoPublicKeyDataType.monero,
            uncomprossed: null,
            curve: EllipticCurveTypes.ed25519Monero);
  factory MoneroPublicKeyData._fromBip32({
    required Bip32Base<dynamic> account,
    // required String keyName,
    required CryptoCoins coin,
  }) {
    if (!coin.proposal.isBip) {
      throw AppCryptoExceptionConst.invalidCoin;
    }
    final moneroAccount = MoneroAccount.fromBip44PrivateKey(account.privateKey.raw);
    return MoneroPublicKeyData.__(
        extendedKey: account.publicKey.toExtended,
        // keyName: keyName,
        chainCode: account.chainCode.toHex(),
        spendPublicKey: moneroAccount.publicSpendKey,
        viewPrivateKey: moneroAccount.privateViewKey,
        viewPublicKey: moneroAccount.publicViewKey,
        coin: coin,
        comprossed: account.publicKey.toHex());
  }
  factory MoneroPublicKeyData._({
    required MoneroPrivateKey privateKey,
    // required String keyName,
    required CryptoCoins coin,
  }) {
    if (!coin.proposal.isBip) {
      throw AppCryptoExceptionConst.invalidCoin;
    }
    final moneroAccount = MoneroAccount.fromPrivateSpendKey(privateKey.key);
    return MoneroPublicKeyData.__(
        extendedKey: null,
        // keyName: keyName,
        chainCode: null,
        spendPublicKey: moneroAccount.publicSpendKey,
        viewPrivateKey: moneroAccount.privateViewKey,
        viewPublicKey: moneroAccount.publicViewKey,
        comprossed: moneroAccount.publicSpendKey.toHex(),
        coin: coin);
  }
  factory MoneroPublicKeyData.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.accessMoneroPublicKeyResponse);
    return MoneroPublicKeyData.__(
        extendedKey: values.rawValueAt(0),
        // keyName: values.rawValueAt(1),
        chainCode: values.rawValueAt(1),
        spendPublicKey: MoneroPublicKey.fromBytes(values.rawValueAt(2)),
        viewPrivateKey: MoneroPrivateKey.fromBytes(values.rawValueAt(3)),
        viewPublicKey: MoneroPublicKey.fromBytes(values.rawValueAt(4)),
        comprossed: values.rawValueAt(5),
        coin: CoinsUtils.getSerializationCoin(values.rawValueAt<int>(6)));
  }

  @override
  CryptoPublicKeyDataType get type => CryptoPublicKeyDataType.monero;

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;

  @override
  List<CborObject?> get serializationItems => [
        extendedKey?.toCbor(),
        chainCode?.toCbor(),
        CborBytesValue(spendPublicKey.key),
        CborBytesValue(viewPrivateKey.key),
        CborBytesValue(viewPublicKey.key),
        comprossed.toCbor(),
        coin.identifier.toCbor()
      ];

  @override
  Bip32Base? toHdKey() {
    final extendedKey = this.extendedKey;
    if (extendedKey == null) return null;
    return CryptoKeyUtils.extendedKeyToBip32Key(extendedKey: extendedKey, coin: coin);
  }
}
