part of 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

final class MemoryWalletEncryptedData with AppSerialization {
  final int version;
  final List<int> _nonce;

  /// encrypted master key bytes.
  final List<int> _data;

  /// encrypted memory wallet key bytes
  final List<int> _key;

  factory MemoryWalletEncryptedData.generate(
      {required MemoryWalletKey key,

      /// encoded master key
      required List<int> walletData,

      /// memory key
      required List<int> memoryKey,
      int version = WalletMasterKeysConst.keyVersion}) {
    // final password = MemoryWalletKey(key: key, rawKey: rawKey);
    final List<int> nonce = QuickCrypto.generateRandom(12);
    final List<int> encrypt =
        CryptoKeyUtils.encryptChacha(key: key.key, nonce: nonce, data: walletData);
    return MemoryWalletEncryptedData(
        version: version, nonce: nonce, data: encrypt, key: key._encrypt(memoryKey));
  }
  MemoryWalletEncryptedData(
      {required this.version,
      required List<int> nonce,
      required List<int> data,
      required List<int> key})
      : _nonce = nonce.asImmutableBytes,
        _data = data.asImmutableBytes,
        _key = key.asImmutableBytes;
  factory MemoryWalletEncryptedData.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.inMemoryKey);
    return MemoryWalletEncryptedData(
        version: values.rawValueAt(0),
        nonce: values.rawValueAt(1),
        data: values.rawValueAt(2),
        key: values.rawValueAt(3));
  }

  MemoryWalletKey _getWalletKey(List<int> memoryKey) {
    final CborListValue values = AppSerialization.decode(cborBytes: _key);
    final List<int> nonce = values.rawValueAt(0);
    final List<int> encryptData = values.rawValueAt(1);
    final decrypt =
        CryptoKeyUtils.decryptChacha(key: memoryKey, nonce: nonce, data: encryptData);
    if (decrypt == null) {
      throw WalletExceptionConst.authFailed;
    }
    return MemoryWalletKey.deserialize(bytes: decrypt);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.inMemoryKey;

  @override
  List<CborObject?> get serializationItems => [
        CborIntValue(version),
        CborBytesValue(_nonce),
        CborBytesValue(_data),
        CborBytesValue(_key)
      ];
}

final class MemoryWalletKey with AppSerialization {
  /// hashed key of raw key
  final List<int> key;

  /// raw string key encoded as utf8
  final List<int> rawKey;
  MemoryWalletKey._({required List<int> key, required List<int> rawKey})
      : key = key.asImmutableBytes,
        rawKey = rawKey.asImmutableBytes;
  factory MemoryWalletKey.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.inMemoryPassword);
    return MemoryWalletKey._(key: values.rawValueAt(0), rawKey: values.rawValueAt(1));
  }

  factory MemoryWalletKey.fromRawKey(
      {required List<int> rawKey, required List<int> checksum}) {
    final key = CryptoKeyUtils.hashKeyNew(key: rawKey, checksum: checksum);
    return MemoryWalletKey._(key: key, rawKey: rawKey);
  }

  List<int> _encrypt(List<int> key) {
    final nonce = QuickCrypto.generateRandom(12);
    final encrypt =
        CryptoKeyUtils.encryptChacha(key: key, nonce: nonce, data: toCbor().encode());
    return CborListValue.definite([
      CborBytesValue(nonce),
      CborBytesValue(encrypt),
    ]).encode();
  }

  StorageEncryptedWallet encryptWalletStorage(List<int> data) {
    final List<int> nonce = CryptoKeyUtils.generateNonce(key);
    final encrypt = CryptoKeyUtils.encryptChacha(key: key, nonce: nonce, data: data);
    return StorageEncryptedWallet._(encrypted: encrypt);
  }

  List<int> decryptWalletStorage(StorageEncryptedWallet data) {
    final nonce = CryptoKeyUtils.generateNonce(key);
    final decrypt =
        CryptoKeyUtils.decryptChacha(key: key, nonce: nonce, data: data.encrypted);
    if (decrypt == null) {
      throw WalletExceptionConst.authFailed;
    }
    return decrypt;
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.inMemoryPassword;

  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(key),
        CborBytesValue(rawKey),
      ];
}

abstract class MemoryWalletContext {
  const MemoryWalletContext();
  factory MemoryWalletContext.fromTransfableMemeoryWallet(TransfableMemoryWallet data) {
    return data._toMemoryWallet();
  }
  T _getMasterKey<T extends IWalletMasterKeys>();
  List<int> _getMemoryKey();
  MemoryWalletKey _getWalletKey();

  CryptoPublicKeysResponse readPublicKeys(List<DerivableIndex> requestKeys) {
    return _getMasterKey().readPublicKeys(requestKeys);
  }

  CryptoPrivateKeysResponse readSecretKeys(List<DerivableIndex> requestKeys) {
    return _getMasterKey().readKeys(requestKeys);
  }

  IViewMasterKey changePassword(List<int> newPassword, List<int> checksum) {
    return _getMasterKey().toEncryptedMaterKey(
        key: MemoryWalletKey.fromRawKey(rawKey: newPassword, checksum: checksum),
        memoryKey: _getMemoryKey());
  }

  CryptoPrivateKeyData getImportedKey(int keyId) {
    return _getMasterKey().getImportedKey(keyId);
  }

  AccessMnemonicResponse mnemonic() {
    return _getMasterKey().mnemonic();
  }

  ViewMasterKey removeSubWallet(int id) {
    final wallet = _getMasterKey().removeSubWallet(id);
    return wallet.encrypt(_getWalletKey(), _getMemoryKey());
  }

  ({ViewMasterKey viewKey, int subwalletId}) importNewSubWallet({
    required String mnemonic,
    required SubWalletType type,
    required String name,
    required DateTime? created,
    String? passphrase,
  }) {
    final newWallet = _getMasterKey().importNewSubWallet(
        mnemonic: mnemonic,
        type: type,
        passphrase: passphrase,
        name: name,
        created: null);
    final encrypt = newWallet.$1.encrypt(_getWalletKey(), _getMemoryKey());
    return (viewKey: encrypt, subwalletId: newWallet.$2);
  }

  ViewMasterKey importSecretKey(ImportedKeyStorage secretKey) {
    final newWallet = _getMasterKey().importCustomKey(secretKey);
    return newWallet.encrypt(_getWalletKey(), _getMemoryKey());
  }

  ViewMasterKey removeSecretKey(int keyId) {
    final newWallet = _getMasterKey().removeKey(keyId);
    return newWallet.encrypt(_getWalletKey(), _getMemoryKey());
  }

  List<int> _encodeBackupMasterKey(List<int> checksum) {
    final masterKey = _getMasterKey<WalletMasterKeys>();
    return masterKey.toCbor(backupChecksum: checksum).encode();
  }

  List<int> getMasterKeyChecksum() => _getMasterKey().checksum;

  List<int> getMemoryKeyChecksum() => _getMemoryKey().sublist(0, 8);

  WalletMasterKeysExternal toExternalWallet(ExternalWalletConnectionInfo connection) {
    final masterKey = _getMasterKey<WalletMasterKeys>();
    return masterKey.toExternalWallet(connection);
  }

  int getNewExternalConnectionClientId() {
    final masterKey = _getMasterKey<WalletMasterKeys>();
    return masterKey.getNewExternalConnectionClientId();
  }

  ViewMasterKey importNewExternalConnection(ExternalWalletConnectionInfo connection) {
    final masterKey = _getMasterKey<WalletMasterKeys>();
    final newKey = masterKey.importNewExternalConnection(connection);
    return newKey.encrypt(_getWalletKey(), _getMemoryKey());
  }

  String backupWallet(List<int> checksum, {String? password}) {
    final encrypt = Web3SecretStorageDefinationV3.encode(_encodeBackupMasterKey(checksum),
        password ?? StringUtils.decode(_getWalletKey().rawKey));
    return encrypt.encrypt(encoding: SecretWalletEncoding.cbor);
  }

  Web3SecretStorageDefinationV3 encryptByWalletKey(List<int> data, {String? password}) {
    return Web3SecretStorageDefinationV3.encode(
        data, password ?? StringUtils.decode(_getWalletKey().rawKey));
  }

  void close();
}

final class MemoryWalletSync extends MemoryWalletContext {
  IWalletMasterKeys? _masterKey;
  MemoryWalletKey? _key;
  List<int>? _memoryKey;
  MemoryWalletSync._(
      {required WalletMasterKeys masterKey,
      // required MemoryWalletEncryptedData data,
      required MemoryWalletKey key,
      required List<int> memoryKey})
      : _memoryKey = memoryKey.asImmutableBytes,
        _masterKey = masterKey,
        // _data = data,
        _key = key;
  // factory MemoryWalletSync.fromMemory(TransfableMemoryWallet data) {
  //   final k = data._getWalletKey();
  //   final decrypt =
  //       WorkerCryptoUtils.decryptChacha(key: k.key, nonce: key._nonce, data: key._data);
  //   if (decrypt == null) {
  //     throw WalletExceptionConst.authFailed;
  //   }
  //   return MemoryWalletSync._(
  //       masterKey: WalletMasterKeys.deserialize(bytes: decrypt),
  //       key: k,
  //       memoryKey: memoryKey);
  // }

  @override
  T _getMasterKey<T extends IWalletMasterKeys<IViewMasterKey>>() {
    final masterKey = _masterKey?.cast<T>();
    if (masterKey == null) throw WalletExceptionConst.authFailed;
    return masterKey;
  }

  @override
  List<int> _getMemoryKey() {
    final memoryKey = _memoryKey;
    if (memoryKey == null) throw WalletExceptionConst.authFailed;
    return memoryKey;
  }

  @override
  MemoryWalletKey _getWalletKey() {
    final walletKey = _key;
    if (walletKey == null) throw WalletExceptionConst.authFailed;
    return walletKey;
  }

  @override
  void close() {
    _masterKey = null;
    _memoryKey = null;
    _key = null;
  }
}

final class StorageEncryptedWallet with AppSerialization, Equality {
  final List<int> encrypted;
  final int version;

  bool get isSetup => version.isNegative;
  factory StorageEncryptedWallet.setup() {
    return StorageEncryptedWallet._(encrypted: [], version: -1);
  }

  StorageEncryptedWallet._(
      {required List<int> encrypted, this.version = WalletMasterKeysConst.keyVersion})
      : encrypted = encrypted.asImmutableBytes;
  factory StorageEncryptedWallet.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.walletStorageData,
        cborBytes: bytes,
        cborObject: object);
    return StorageEncryptedWallet._(
        encrypted: values.rawValueAt(0), version: values.rawValueAt(1));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.walletStorageData;

  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(encrypted), version.toCbor()];

  @override
  List<dynamic> get variables => [encrypted, version];
}

final class TransfableMemoryWallet with AppSerialization {
  final MemoryWalletEncryptedData encryptedData;
  final List<int> memoryKey;
  TransfableMemoryWallet({required this.encryptedData, required List<int> memoryKey})
      : memoryKey = memoryKey.asImmutableBytes;
  factory TransfableMemoryWallet.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    return TransfableMemoryWallet(
        encryptedData: MemoryWalletEncryptedData.deserialize(object: values.objectAt(0)),
        memoryKey: values.rawValueAt(1));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [
        encryptedData.toCbor(),
        CborBytesValue(memoryKey),
      ];

  MemoryWalletContext _toMemoryWallet() {
    final walletKey = encryptedData._getWalletKey(memoryKey);
    final decrypt = CryptoKeyUtils.decryptChacha(
        key: walletKey.key, nonce: encryptedData._nonce, data: encryptedData._data);
    if (decrypt == null) {
      throw WalletExceptionConst.authFailed;
    }
    return MemoryWalletSync._(
        masterKey: WalletMasterKeys.deserialize(bytes: decrypt),
        key: walletKey,
        memoryKey: memoryKey);
  }
}
