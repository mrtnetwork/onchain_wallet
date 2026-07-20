part of 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

class CryptoKeyUtils {
  static int defaultChaChaNonceLength = 12;
  static List<int> privateKeyToBytes(
      {required String privateKey, required CryptoCoins coin}) {
    return IPrivateKey.fromBytes(BytesUtils.fromHexString(privateKey), coin.conf.type)
        .raw;
  }

  static List<int> _toSecretKeyBytes(
      {required List<int> keypair, required EllipticCurveTypes type}) {
    const int ed25519KeyPairLength =
        Ed25519KeysConst.privKeyByteLen + Ed25519KeysConst.pubKeyByteLen;
    if (keypair.length != ed25519KeyPairLength) return keypair;
    switch (type) {
      case EllipticCurveTypes.ed25519:
      case EllipticCurveTypes.ed25519Blake2b:
        return keypair.sublist(0, Ed25519KeysConst.privKeyByteLen);
      default:
        return keypair;
    }
  }

  static ImportedKeyStorage extendeKeyToStorage(
      {required String extendedKey, required CryptoCoins coin, required String keyName}) {
    if (!coin.proposal.isBip || coin.conf is! BipCoinConfig) {
      throw AppCryptoExceptionConst.invalidCoin;
    }
    final key = extendedKeyToBip32Key(extendedKey: extendedKey, coin: coin);
    return ImportedKeyStorage.generate(
        checksum: _createCustomKeyChecksum(
            pubkeyBytes: key.publicKey.compressed,
            chainCode: key.chainCode.toBytes(),
            coin: coin),
        keyStr: key.privateKey.toExtended,
        coin: coin,
        name: keyName,
        keyType: CustomKeyType.extendedKey);
  }

  static ImportedKeyStorage privateKeyToStorage(
      {required String privateKey, required CryptoCoins coin, required String keyName}) {
    return _privateKeyToStorage(
        keyBytes: BytesUtils.fromHexString(privateKey), coin: coin, keyName: keyName);
  }

  static List<int> privateKeyToKeypairBytes(
      {required List<int> privateKey, required CryptoCoins coin}) {
    try {
      final ripplePrivateKey = XRPPrivateKey.fromBytes(privateKey,
          algorithm: coin.conf.type == EllipticCurveTypes.ed25519
              ? XRPKeyAlgorithm.ed25519
              : XRPKeyAlgorithm.secp256k1);

      return ripplePrivateKey.toBytes();
    } catch (e) {
      throw AppCryptoExceptionConst.invalidEncodedKeyData;
    }
  }

  static IPrivateKey _validatePrivateKey(
      {required List<int> keyBytes, required CryptoCoins coin}) {
    switch (coin) {
      case SubstrateCoins substrate:
        final substratee = Substrate.fromPrivateKey(keyBytes, substrate);
        return substratee.priveKey.privKey;
      case Bip44Coins.ripple:
      case Bip44Coins.rippleEd25519:
      case Bip44Coins.rippleTestnet:
      case Bip44Coins.rippleTestnetED25519:
        keyBytes = privateKeyToKeypairBytes(coin: coin, privateKey: keyBytes);
        break;
      case Bip44Coins.moneroEd25519Slip:
        return MoneroPrivateKey.fromBytes(keyBytes);
      default:
        break;
    }
    return IPrivateKey.fromBytes(keyBytes, coin.conf.type);
  }

  static ImportedKeyStorage _privateKeyToStorage(
      {required List<int> keyBytes, required CryptoCoins coin, required String keyName}) {
    switch (coin) {
      case BipCoins():
      case SubstrateCoins():
        break;
      default:
        throw AppCryptoExceptionConst.invalidCoin;
    }
    final secretKeyBytes = _toSecretKeyBytes(keypair: keyBytes, type: coin.conf.type);
    final key = _validatePrivateKey(keyBytes: secretKeyBytes, coin: coin);
    return ImportedKeyStorage.generate(
        checksum:
            _createCustomKeyChecksum(pubkeyBytes: key.publicKey.compressed, coin: coin),
        keyStr: key.toHex(),
        coin: coin,
        name: keyName,
        keyType: CustomKeyType.privateKey);
  }

  static ImportedKeyStorage wifToStorage(
      {required String wifKey, required CryptoCoins coin, required String keyName}) {
    if (!coin.conf.hasWif) {
      throw AppCryptoExceptionConst.invalidCoin;
    }
    try {
      final keyBytes = WifDecoder.decode(wifKey, netVer: coin.conf.wifNetVer!).$1;
      return _privateKeyToStorage(keyBytes: keyBytes, coin: coin, keyName: keyName);
    } catch (e) {
      throw AppCryptoExceptionConst.invalidEncodedKeyData;
    }
  }

  static ImportedKeyStorage orchardSpendKeyToStorage(
      {required String keyData,
      required CryptoCoins coin,
      required String keyName,
      required OnChainCryptoContext context}) {
    final config = coin.conf;
    if (!coin.proposal.isZip || config.type != EllipticCurveTypes.redPallas) {
      throw AppCryptoExceptionConst.invalidCoin;
    }
    try {
      final toBytes = BytesUtils.fromHexString(keyData);
      final spedKey = OrchardSpendingKey.fromBytes(bytes: toBytes, context: context);

      return ImportedKeyStorage.generate(
          checksum: _createCustomKeyChecksum(
              pubkeyBytes: OrchardFullViewingKey.fromSpendKey(spedKey).toBytes(),
              coin: coin),
          keyStr: keyData,
          coin: coin,
          name: keyName,
          keyType: CustomKeyType.orchardSpendKey);
    } catch (e) {
      throw AppCryptoExceptionConst.invalidEncodedKeyData;
    }
  }

  static ImportedKeyStorage saplingSpendingKeyToStorage(
      {required String keyData, required CryptoCoins coin, required String keyName}) {
    final config = coin.conf;
    if (!coin.proposal.isZip || config.type != EllipticCurveTypes.redJubJub) {
      throw AppCryptoExceptionConst.invalidCoin;
    }
    try {
      final toBytes = BytesUtils.fromHexString(keyData);
      final spedKey = Zip32Sapling.fromSpendKey(toBytes);
      return ImportedKeyStorage.generate(
          checksum: _createCustomKeyChecksum(
              pubkeyBytes: spedKey.publicKey.toDiversifiableFullViewingKey().toBytes(),
              coin: coin),
          keyStr: keyData,
          coin: coin,
          name: keyName,
          keyType: CustomKeyType.saplingSpendKey);
    } catch (e) {
      throw AppCryptoExceptionConst.invalidEncodedKeyData;
    }
  }

  static ImportedKeyStorage saplingExtendedSpandingKeyToStorage(
      {required String keyData, required CryptoCoins coin, required String keyName}) {
    final config = coin.conf;
    if (!coin.proposal.isZip || config.type != EllipticCurveTypes.redJubJub) {
      throw AppCryptoExceptionConst.invalidCoin;
    }
    try {
      final spedKey =
          Zip32Sapling.fromExtendedSpendingKey(keyData, config as ZIP32CoinConfig);
      return ImportedKeyStorage.generate(
          checksum: _createCustomKeyChecksum(
              pubkeyBytes: spedKey.publicKey.toDiversifiableFullViewingKey().toBytes(),
              coin: coin),
          keyStr: keyData,
          coin: coin,
          name: keyName,
          keyType: CustomKeyType.saplingExtendedSpandingKey);
    } catch (e) {
      throw AppCryptoExceptionConst.invalidEncodedKeyData;
    }
  }

  static Bip32Base privteKeyToBip32(
      {required String privateKey, required CryptoCoins coin}) {
    try {
      if (coin is! BipCoins) {
        throw AppCryptoExceptionConst.invalidCoin;
      }
      final privateKeyBytes = BytesUtils.fromHexString(privateKey);
      if (coin.proposal == CoinProposal.cip0019) {
        return CardanoByronLegacyBip32.fromPrivateKey(privateKeyBytes);
      }
      switch (coin.conf.type) {
        case EllipticCurveTypes.secp256k1:
          return Bip32Slip10Secp256k1.fromPrivateKey(privateKeyBytes);
        case EllipticCurveTypes.ed25519:
          return Bip32Slip10Ed25519.fromPrivateKey(privateKeyBytes);
        case EllipticCurveTypes.ed25519Kholaw:
          final bool icarus =
              coin.conf.defaultHdKeyDerivator == DefaultHdKeyDerivator.icarus;
          if (icarus) {
            return CardanoIcarusBip32.fromPrivateKey(privateKeyBytes);
          }
          return Bip32KholawEd25519.fromPrivateKey(privateKeyBytes);
        case EllipticCurveTypes.ed25519Blake2b:
          return Bip32Slip10Ed25519Blake2b.fromPrivateKey(privateKeyBytes);
        case EllipticCurveTypes.nist256p1:
          return Bip32Slip10Nist256p1.fromPrivateKey(privateKeyBytes);
        case EllipticCurveTypes.nist256p1Hybrid:
          return Bip32Slip10Nist256p1Hybrid.fromPrivateKey(privateKeyBytes);
        default:
          throw AppCryptoExceptionConst.invalidEncodedKeyData;
      }
    } catch (e) {
      throw AppCryptoExceptionConst.invalidEncodedKeyData;
    }
  }

  static Bip32Base extendedKeyToBip32Key(
      {required String extendedKey, required CryptoCoins coin}) {
    try {
      if (!coin.proposal.isBip) {
        throw AppCryptoExceptionConst.invalidCoin;
      }
      final conf = coin.conf;
      if (!coin.conf.hasExtendedKeys) {
        throw AppCryptoExceptionConst.invalidEncodedKeyData;
      }
      final keyNetVar = conf.keyNetVer;
      if (coin.proposal == CoinProposal.cip0019) {
        return CardanoByronLegacyBip32.fromExtendedKey(extendedKey, keyNetVar);
      }

      switch (conf.type) {
        case EllipticCurveTypes.secp256k1:
          return Bip32Slip10Secp256k1.fromExtendedKey(extendedKey, keyNetVar);
        case EllipticCurveTypes.ed25519:
          return Bip32Slip10Ed25519.fromExtendedKey(extendedKey, keyNetVar);
        case EllipticCurveTypes.ed25519Kholaw:
          if (conf.defaultHdKeyDerivator == DefaultHdKeyDerivator.icarus) {
            return CardanoIcarusBip32.fromExtendedKey(extendedKey, keyNetVar);
          }
          return Bip32KholawEd25519.fromExtendedKey(extendedKey, keyNetVar);
        case EllipticCurveTypes.ed25519Blake2b:
          return Bip32Slip10Ed25519Blake2b.fromExtendedKey(extendedKey, keyNetVar);
        case EllipticCurveTypes.nist256p1:
          return Bip32Slip10Nist256p1.fromExtendedKey(extendedKey, keyNetVar);
        case EllipticCurveTypes.nist256p1Hybrid:
          return Bip32Slip10Nist256p1Hybrid.fromExtendedKey(extendedKey, keyNetVar);
        default:
          throw AppCryptoExceptionConst.invalidEncodedKeyData;
      }
    } on AppCryptoException {
      rethrow;
    } catch (e) {
      throw AppCryptoExceptionConst.invalidEncodedKeyData;
    }
  }

  static void validateMnemonic(String mnemonic) {
    if (!isValidMenemonic(mnemonic)) {
      throw AppCryptoExceptionConst.invalidMnemonic;
    }
  }

  static bool isValidMenemonic(String mnemonic) {
    final validator = Bip39MnemonicValidator();
    return validator.isValid(mnemonic);
  }

  static void validateMnemonicWords(List<String> mnemonic) {
    try {
      final isValid = Bip39MnemonicValidator();
      if (!isValid.validateWords(mnemonic.join(" "))) {
        throw AppCryptoExceptionConst.invalidBip39MnemonicWords;
      }
    } catch (e) {
      throw AppCryptoExceptionConst.invalidBip39MnemonicWords;
    }
  }

  static List<String> normalizeMnemonic(String mnemonic) {
    return Mnemonic.fromString(mnemonic).toList();
  }

  static Bip32Base seedToBipKey({required List<int> seedBytes, required BipCoins coin}) {
    Bip32Base validate(Bip32Base bip32Obj) {
      final depth = bip32Obj.depth.depth;
      if (bip32Obj.isPublicOnly) {
        if (depth < Bip44Levels.account.value || depth > Bip44Levels.addressIndex.value) {
          throw AppCryptoExceptionConst.invalidKeyDerivationPath;
        }
      } else {
        if (depth < 0 || depth > Bip44Levels.addressIndex.value) {
          throw AppCryptoExceptionConst.invalidKeyDerivationPath;
        }
      }

      return bip32Obj;
    }

    Bip32Base bip;
    final conf = coin.conf;
    Bip32KeyNetVersions? keyNetVar;
    bool isIcarus = false;
    keyNetVar = coin.conf.keyNetVer;
    isIcarus = coin.conf.defaultHdKeyDerivator == DefaultHdKeyDerivator.icarus;
    switch (conf.type) {
      case EllipticCurveTypes.secp256k1:
        bip = Bip32Slip10Secp256k1.fromSeed(seedBytes, keyNetVar);
        break;
      case EllipticCurveTypes.ed25519:
        bip = Bip32Slip10Ed25519.fromSeed(seedBytes, keyNetVar);
        break;
      case EllipticCurveTypes.ed25519Kholaw:
        if (coin.proposal == CoinProposal.cip0019) {
          bip = CardanoByronLegacyBip32.fromSeed(seedBytes, keyNetVar);
          break;
        }
        if (isIcarus) {
          bip = CardanoIcarusBip32.fromSeed(seedBytes, keyNetVar);
          break;
        }
        bip = Bip32KholawEd25519.fromSeed(seedBytes, keyNetVar);
        break;
      case EllipticCurveTypes.ed25519Blake2b:
        bip = Bip32Slip10Ed25519Blake2b.fromSeed(seedBytes, keyNetVar);
        break;
      case EllipticCurveTypes.nist256p1:
        bip = Bip32Slip10Nist256p1.fromSeed(seedBytes, keyNetVar);
        break;
      case EllipticCurveTypes.nist256p1Hybrid:
        bip = Bip32Slip10Nist256p1Hybrid.fromSeed(seedBytes, keyNetVar);
        break;
      default:
        throw AppCryptoExceptionConst.invalidCoin;
    }

    return validate(bip);
  }

  static IPrivateKey seedToSubstratePrivateKey(
      {required List<int> seedBytes, required CryptoCoins coin}) {
    if (coin.proposal != CoinProposal.substrate) {
      throw AppCryptoExceptionConst.invalidCoin;
    }
    final substrate = Substrate.fromSeed(seedBytes, coin as SubstrateCoins);
    return substrate.priveKey.privKey;
  }

  static List<int> _createCustomKeyChecksum(
      {required List<int> pubkeyBytes, List<int>? chainCode, required CryptoCoins coin}) {
    chainCode ??= List<int>.filled(Bip32ChainCode.fixedLength(), 0);
    return QuickCrypto.sha3256Hash(<int>[
      ...pubkeyBytes,
      ...chainCode,
      ...coin.proposal.name.codeUnits,
      ...coin.coinName.codeUnits
    ]);
  }

  static String? validateHdPathKey(String path, {int? maxIndex}) {
    try {
      final parser = Bip32PathParser.parse(path);
      if (maxIndex != null && parser.length() != maxIndex) {
        return null;
      }
      return path;
    } catch (e) {
      return null;
    }
  }

  static String? toWif({required List<int> privateKey, required CryptoCoins coin}) {
    if (coin is BipCoins) {
      final wif = coin.conf.wifNetVer;
      if (wif != null) {
        return WifEncoder.encode(privateKey, netVer: wif);
      }
    }
    return null;
  }

  static String generateRandomString(int length) {
    const String chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(length, (index) => chars[QuickCrypto.prng.nextInt(chars.length)])
        .join('');
  }

  static String generateStringIndentifier(String str) {
    return BytesUtils.toHexString(MD4.hash(StringUtils.encode(str)));
  }

  static String generateCrc32Identifier(String str, int prefix) {
    final id = Crc32().quickIntDigest(StringUtils.encode(str));
    return "$id$prefix";
  }

  static String toPublicKeyHex(List<int> keyBytes, EllipticCurveTypes type) {
    List<int> bytes = toPublicBytes(keyBytes, type);
    return BytesUtils.toHexString(bytes, prefix: "0x");
  }

  static String normalizePublicKeyHex(String keyBytes, EllipticCurveTypes type) {
    final key = BytesUtils.fromHexString(keyBytes);
    return BytesUtils.toHexString(normalizePublicKeyBytes(key, type));
  }

  static List<int> normalizePublicKeyBytes(List<int> keyBytes, EllipticCurveTypes type) {
    // final key = StringUtils.normalizeHex(keyBytes);
    switch (type) {
      case EllipticCurveTypes.ed25519:
      case EllipticCurveTypes.ed25519Kholaw:
        if (keyBytes.length == Ed25519KeysConst.pubKeyByteLen) {
          return keyBytes;
        }
        if (keyBytes.length !=
            Ed25519KeysConst.pubKeyByteLen + Ed25519KeysConst.pubKeyPrefix.length) {
          throw AppCryptoExceptionConst.invalidEncodedKeyData;
        }
        return keyBytes.sublist(Ed25519KeysConst.pubKeyPrefix.length);
      default:
        return keyBytes;
    }
  }

  static List<int> toPublicBytes(List<int> publicKey, EllipticCurveTypes type) {
    final key = IPublicKey.fromBytes(publicKey, type);
    List<int> bytes = key.compressed;
    switch (key.curve) {
      case EllipticCurveTypes.ed25519:
      case EllipticCurveTypes.ed25519Kholaw:
        if (bytes.length ==
            Ed25519KeysConst.pubKeyByteLen + Ed25519KeysConst.pubKeyPrefix.length) {
          bytes = bytes.sublist(1);
        }
        break;
      default:
    }
    return bytes;
  }

  static ImportCustomKeys tonMoneroPrivateSpendKey({
    required String mnemonic,
    required CryptoCoins coin,
  }) {
    final validate = MoneroMnemonicValidator().isValid(mnemonic);
    if (!validate) {
      throw AppCryptoExceptionConst.invalidMnemonic;
    }
    final seed = MoneroSeedGenerator(Mnemonic.fromString(mnemonic)).generate();
    final account = MoneroAccount.fromSeed(seed);
    return ImportCustomKeys._(
        privateKey: account.privateSpendKey.toHex(),
        publicKey: account.privateSpendKey.publicKey.toHex(),
        coin: coin);
  }

  static List<int> bip39MnemonicToBinary(Mnemonic mnemonic) {
    final decoder = Bip39MnemonicDecoder();
    final language = decoder.findLanguage(mnemonic);
    final decode = Bip39MnemonicDecoder().mnemonicToBinaryStr(mnemonic, language.$1);
    return BytesUtils.fromBinary(decode);
  }

  static ImportCustomKeys tonMnemonicToPrivateKey(
      {required CryptoCoins coin,
      required String mnemonic,
      required String? password,
      required bool validateTonMnemonic}) {
    final mn = Mnemonic.fromString(mnemonic);
    final seed = TonSeedGenerator(mn)
        .generate(password: password ?? "", validateTonMnemonic: validateTonMnemonic);
    final key = TonPrivateKey.fromBytes(seed);
    return ImportCustomKeys._(
        privateKey: key.toHex(), publicKey: key.toPublicKey().toHex(), coin: coin);
  }

  static List<int> bip39MnemonicToBytesNew(Mnemonic mnemonic) {
    List<int> mnemonicBytes = StringUtils.encode(mnemonic.toStr());
    if (mnemonicBytes.length < F4Jumble.minValidLength) {
      final n = List<int>.filled(F4Jumble.minValidLength, 0);
      n.setAll(0, mnemonicBytes);
      mnemonicBytes = n;
    }
    return F4Jumble.apply(mnemonicBytes);
  }

  static Mnemonic bytesToBip39MnemonicNew(List<int> bytes) {
    final inv = F4Jumble.applyInv(bytes);
    final zero = inv.indexOf(0);
    if (zero.isNegative) {
      return Mnemonic.fromString(StringUtils.decode(inv));
    }
    return Mnemonic.fromString(StringUtils.decode(inv.sublist(0, zero)));
  }

// Bytes → Mnemonic
  static Mnemonic bytesToBip39Mnemonic(
      {required List<int> bytes, required MnemonicLanguages language}) {
    if (bytes.isEmpty || bytes[0] > 127) {
      throw AppCryptoExceptionConst.invalidMnemonic;
    }
    int length = bytes[0];
    bytes = bytes.sublist(1);
    final toBinary =
        BytesUtils.toBinary(bytes, zeroPadBitLen: length * Bip39MnemonicConst.wordBitLen);
    bytes = bytes.sublist(1);
    final words = <String>[];
    for (var i = 0;
        i + Bip39MnemonicConst.wordBitLen <= toBinary.length;
        i += Bip39MnemonicConst.wordBitLen) {
      final wordBinStr = toBinary.substring(i, i + Bip39MnemonicConst.wordBitLen);
      final wordIdx = int.parse(wordBinStr, radix: 2);
      words.add(language.wordList[wordIdx]);
    }
    return Mnemonic.fromList(words);
  }

  static List<int>? tryDecodeWebAuthPublicKeyCredential(String publicKey) {
    final pubKeyBytes = BytesUtils.tryFromHexString(publicKey);
    if (pubKeyBytes == null ||
        pubKeyBytes.length < EcdsaKeysConst.pubKeyUncompressedByteLen) {
      return null;
    }
    final rawKey = pubKeyBytes
        .sublist(pubKeyBytes.length - EcdsaKeysConst.pubKeyUncompressedByteLen);
    if (IPublicKey.isValidBytes(rawKey, EllipticCurveTypes.nist256p1)) {
      return rawKey;
    }
    return null;
  }

  static bool validateWebAuthSecp256p1DerSignature(
      {required List<int> authenticatorData,
      required List<int> clientDataJSON,
      required List<int> signature,
      required List<int> pubKeyBytes}) {
    final digest = QuickCrypto.sha256Hash(
        [...authenticatorData, ...QuickCrypto.sha256Hash(clientDataJSON)]);
    final derSignature = Secp256k1EcdsaSignature.fromDer(signature);
    final pk = Nist256p1PublicKey.fromBytes(pubKeyBytes);
    return pk.publicKey
        .verifies(BigintUtils.fromBytes(digest), derSignature.toEcdsaSignature());
  }

  static List<int> encryptKeyNames(String name, List<int> keyChechsum) {
    final toBytes = StringUtils.encode(name);
    final desc = List<int>.filled(toBytes.length, 0);
    final nonce = List<int>.filled(8, 12);
    return ChaCha20.streamXOR(keyChechsum, nonce, toBytes, desc);
  }

  static String decryptKeyNames(List<int> name, List<int> keyChechsum) {
    final des = List<int>.filled(name.length, 0);
    final nonce = List<int>.filled(8, 12);
    return StringUtils.decode(ChaCha20.streamXOR(keyChechsum, nonce, name, des));
  }

  static const int keyItration = 25000;
  static List<int> generateNonce(List<int> seed) {
    final hasher = SHAKE128();
    final digest = List<int>.unmodifiable(hasher.update(seed).digest(12));
    hasher.clean();
    return digest;
  }

  static List<int> hashKeyNew({required List<int> key, required List<int> checksum}) {
    final hash = QuickCrypto.sha256Hash(key);
    return PBKDF2.deriveKey(
        mac: () => HMAC(() => SHA512(), hash),
        salt: checksum,
        iterations: keyItration,
        length: QuickCrypto.sha256DigestSize);
  }

  static List<int> encryptChacha(
      {required List<int> key, required List<int> nonce, required List<int> data}) {
    final chacha = ChaCha20Poly1305(key);
    try {
      return chacha.encrypt(nonce, data);
    } finally {
      chacha.clean();
    }
  }

  static List<int>? decryptChacha({
    required List<int> key,
    required List<int> nonce,
    required List<int> data,
  }) {
    final chacha = ChaCha20Poly1305(key);
    try {
      final decrypt = chacha.decrypt(nonce, data);
      if (decrypt != null) {
        return List<int>.unmodifiable(decrypt);
      }
      return decrypt;
    } finally {
      chacha.clean();
    }
  }
}
