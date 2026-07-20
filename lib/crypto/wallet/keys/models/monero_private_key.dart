part of 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

final class MoneroPrivateKeyData extends CryptoPrivateKeyData {
  @override
  final CryptoCoins coin;
  @override
  final String privateKey;
  final MoneroPrivateKey viewPrivateKey;
  final MoneroPrivateKey spendPrivateKey;
  @override
  final String? extendedKey;
  @override
  final String? wif;
  // @override
  // final String keyName;

  @override
  MoneroPrivateKeysView get toViewKey => MoneroPrivateKeysView._(
      extendKey: extendedKey,
      privateKey: privateKey,
      wif: wif,
      // keyName: keyName,
      keyType: type,
      spendPrivateKey: spendPrivateKey.toHex(),
      viewPrivateKey: viewPrivateKey.toHex(),
      curve: coin.conf.type);

  MoneroAccount toMoneroAccount() {
    return MoneroAccount.fromPrivateSpendKey(spendPrivateKey.key);
  }

  @override
  final MoneroPublicKeyData publicKey;
  factory MoneroPrivateKeyData.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.accessMoneroPrivateKeyResponse);
    final CryptoCoins coin = CoinsUtils.getSerializationCoin(values.rawValueAt(0));
    return MoneroPrivateKeyData.__(
      privateKey: values.rawValueAt(1),
      extendedKey: values.rawValueAt(2),
      coin: coin,
      wif: values.rawValueAt(3),
      // keyName: values.rawValueAt(4),
      publicKey:
          MoneroPublicKeyData.deserialize(object: values.objectAt<CborTagValue>(4)),
      spendPrivateKey: MoneroPrivateKey.fromBytes(values.rawValueAt(5)),
      viewPrivateKey: MoneroPrivateKey.fromBytes(values.rawValueAt(6)),
    );
  }

  const MoneroPrivateKeyData.__(
      {required this.privateKey,
      required this.extendedKey,
      required this.coin,
      required this.wif,
      // required this.keyName,
      required this.publicKey,
      required this.viewPrivateKey,
      required this.spendPrivateKey})
      : super._();
  factory MoneroPrivateKeyData._fromBip32({
    required Bip32Base<dynamic> account,
    required CryptoCoins coin,
    // required String keyName,
  }) {
    final moneroAccount = MoneroAccount.fromBip44PrivateKey(account.privateKey.raw);
    final wifKey = CryptoKeyUtils.toWif(privateKey: account.privateKey.raw, coin: coin);
    return MoneroPrivateKeyData.__(
      privateKey: account.privateKey.toHex(),
      extendedKey: account.privateKey.toExtended,
      coin: coin,
      wif: wifKey,
      // keyName: keyName,
      viewPrivateKey: moneroAccount.privVkey,
      spendPrivateKey: moneroAccount.privateSpendKey,
      publicKey: MoneroPublicKeyData._fromBip32(account: account, coin: coin),
    );
  }

  factory MoneroPrivateKeyData._({
    required String spendKey,
    required CryptoCoins coin,
  }) {
    final mSpendKey = MoneroPrivateKey.fromHex(spendKey);
    final moneroAccount = MoneroAccount.fromPrivateSpendKey(mSpendKey.key);
    final wifKey = CryptoKeyUtils.toWif(privateKey: mSpendKey.key, coin: coin);
    return MoneroPrivateKeyData.__(
      privateKey: mSpendKey.toHex(),
      extendedKey: null,
      coin: coin,
      wif: wifKey,
      viewPrivateKey: moneroAccount.privVkey,
      spendPrivateKey: moneroAccount.privateSpendKey,
      publicKey: MoneroPublicKeyData._(privateKey: mSpendKey, coin: coin),
    );
  }

  factory MoneroPrivateKeyData._fromExtendedKey({
    required String extendedKey,
    required CryptoCoins coin,
    // required String keyName,
  }) {
    final account =
        CryptoKeyUtils.extendedKeyToBip32Key(extendedKey: extendedKey, coin: coin);
    return MoneroPrivateKeyData._fromBip32(account: account, coin: coin);
  }

  factory MoneroPrivateKeyData._fromSeed({
    required List<int> seedBytes,
    required CryptoCoins coin,
    // required String keyName,
  }) {
    final moneroAccount = MoneroAccount.fromSeed(seedBytes);
    return MoneroPrivateKeyData.__(
      privateKey: moneroAccount.privateSpendKey.toHex(),
      extendedKey: null,
      coin: coin,
      wif: null,
      // keyName: keyName,
      viewPrivateKey: moneroAccount.privVkey,
      spendPrivateKey: moneroAccount.privateSpendKey,
      publicKey: MoneroPublicKeyData._(
          privateKey: moneroAccount.privateSpendKey,
          // keyName: keyName,
          coin: coin),
    );
  }

  @override
  Bip32Base toHdKey() {
    if (extendedKey == null) {
      return CryptoKeyUtils.privteKeyToBip32(privateKey: privateKey, coin: coin);
    }
    return CryptoKeyUtils.extendedKeyToBip32Key(extendedKey: extendedKey!, coin: coin);
  }

  @override
  List<int> privateKeyBytes() {
    return BytesUtils.fromHexString(privateKey);
  }

  @override
  CryptoPrivateKeyDataType get type => CryptoPrivateKeyDataType.monero;

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;

  @override
  List<CborObject?> get serializationItems => [
        coin.identifier.toCbor(),
        privateKey.toCbor(),
        extendedKey?.toCbor(),
        wif?.toCbor(),
        publicKey.toCbor(),
        CborBytesValue(spendPrivateKey.key),
        CborBytesValue(viewPrivateKey.key),
      ];
}
