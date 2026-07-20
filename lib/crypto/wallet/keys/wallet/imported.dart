part of 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

final class ImportedKeyStorage with AppSerialization, Equality {
  final List<int> checksum;
  final int id;
  final String keyStr;
  final List<int> name;
  final DateTime created;
  final CryptoCoins coin;
  final CustomKeyType keyType;
  ImportedKeyStorage._(
      {required List<int> checksum,
      required this.id,
      required this.keyStr,
      required this.coin,
      required this.name,
      DateTime? created,
      required this.keyType})
      : created = created ?? DateTime.now(),
        checksum = checksum.asImmutableBytes;

  factory ImportedKeyStorage.generate({
    required String keyStr,
    required String name,
    DateTime? created,
    required CryptoCoins coin,
    required CustomKeyType keyType,
    required List<int> checksum,
  }) {
    final int id = Crc32().quickIntDigest(checksum);
    return ImportedKeyStorage._(
        checksum: checksum,
        id: id,
        keyStr: keyStr,
        coin: coin,
        name: CryptoKeyUtils.encryptKeyNames(name, checksum),
        keyType: keyType,
        created: created);
  }

  factory ImportedKeyStorage.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.walletCustomKey);
    return ImportedKeyStorage._(
        checksum: values.rawValueAt(0),
        keyStr: values.rawValueAt(1),
        created: values.rawValueAt(2),
        name: values.rawValueAt(3),
        keyType: CustomKeyType.fromValue(values.rawValueAt(4)),
        coin: CoinsUtils.getSerializationCoin(values.rawValueAt(5)),
        id: values.rawValueAt(6));
  }

  @override
  List get variables => [checksum, keyStr, coin.coinName];

  CryptoPrivateKeyData getKey() {
    bool isMonero = coin == Bip44Coins.moneroEd25519Slip;
    switch (keyType) {
      case CustomKeyType.wif:
      case CustomKeyType.privateKey:
        if (isMonero) {
          return MoneroPrivateKeyData._(spendKey: keyStr, coin: coin);
        }

        return PrivateKeyData._(
            coin: coin, key: IPrivateKey.fromHex(keyStr, coin.conf.type));
      case CustomKeyType.extendedKey:
        if (isMonero) {
          return MoneroPrivateKeyData._fromExtendedKey(extendedKey: keyStr, coin: coin);
        }
        return PrivateKeyData._fromExtendedKey(extendedKey: keyStr, coin: coin);
      case CustomKeyType.orchardSpendKey when coin is ZIP32Coins:
        return Zip32PrivateKeyData._fromOrchardSpendKey(
            spendKey: keyStr, coin: coin.cast());
      case CustomKeyType.saplingExtendedSpandingKey when coin is ZIP32Coins:
        return Zip32PrivateKeyData._fromSaplingExtendedSpendKey(
            extendedSpendKey: keyStr, coin: coin.cast());
      case CustomKeyType.saplingSpendKey when coin is ZIP32Coins:
        return Zip32PrivateKeyData._fromSaplingSpendKey(
            spendKey: keyStr, coin: coin.cast());
      default:
        throw AppCryptoExceptionConst.invalidCoin;
    }
  }

  bool canUseFor(CryptoCoins coin) {
    if (this.coin == coin) return true;
    if (coin == Bip44Coins.moneroEd25519Slip) {
      return false;
    }
    if (!keyType.isPrivateKey) return false;
    return this.coin.conf.type == coin.conf.type;
  }

  CryptoPrivateKeyData _toBip32Key(DerivableIndex key) {
    final currentCoin = key.currencyCoin;
    bool isMonero = currentCoin == Bip44Coins.moneroEd25519Slip;
    switch (keyType) {
      case CustomKeyType.wif:
      case CustomKeyType.privateKey:
        if (isMonero) {
          return MoneroPrivateKeyData._(spendKey: keyStr, coin: currentCoin);
        }
        return PrivateKeyData._(
            coin: currentCoin, key: IPrivateKey.fromHex(keyStr, currentCoin.conf.type));
      case CustomKeyType.extendedKey:
        if (isMonero) {
          return MoneroPrivateKeyData._fromExtendedKey(
              extendedKey: keyStr, coin: currentCoin);
        }
        return PrivateKeyData._fromExtendedKey(extendedKey: keyStr, coin: currentCoin);
      case CustomKeyType.orchardSpendKey when coin is ZIP32Coins:
        return Zip32PrivateKeyData._fromOrchardSpendKey(
            spendKey: keyStr, coin: coin.cast());
      case CustomKeyType.saplingExtendedSpandingKey when coin is ZIP32Coins:
        return Zip32PrivateKeyData._fromSaplingExtendedSpendKey(
            extendedSpendKey: keyStr, coin: coin.cast());

      case CustomKeyType.saplingSpendKey when coin is ZIP32Coins:
        return Zip32PrivateKeyData._fromSaplingSpendKey(
            spendKey: keyStr, coin: coin.cast());
      default:
        throw AppCryptoExceptionConst.invalidCoin;
    }
  }

  CryptoPrivateKeyData toKey(DerivableIndex key) {
    if (!canUseFor(coin)) {
      throw AppCryptoExceptionConst.invalidCoin;
    }
    if (!key.isMaster) {
      if (keyType.isPrivateKey && !key.currencyCoin.proposal.isSubstrate) {
        throw AppCryptoExceptionConst.importedKeyDerivationNotAllowed;
      }
    }
    final bipKey = _toBip32Key(key);
    return key._derive(bipKey);
  }

  ViewImportedSecretKey toVieweKey() {
    return ViewImportedSecretKey.__(
        coin: coin,
        id: id,
        created: created,
        name: CryptoKeyUtils.decryptKeyNames(name, checksum),
        keyType: keyType);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.walletCustomKey;

  @override
  List<CborObject?> get serializationItems => [
        checksum.toCborBytes(),
        keyStr.toCbor(),
        CborEpochIntValue(created),
        name.toCborBytes(),
        keyType.value.toCbor(),
        coin.identifier.toCbor(),
        id.toCbor()
      ];
}
