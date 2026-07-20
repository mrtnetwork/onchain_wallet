part of 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

class WalletMasterKeysConst {
  static const int keyVersion = 2;
  static const int connectorIdLength = 16;
}

enum WalletMasterKeyVersion {
  v0(0),
  v1(1);

  static WalletMasterKeyVersion fromValue(int? tag,
      {WalletMasterKeyVersion? defaultVersion}) {
    return values.firstWhere((e) => e.value == tag, orElse: () {
      if (tag != null || defaultVersion == null) {
        throw AppInternalError.internalError("WalletMasterKeyVersion");
      }
      return defaultVersion;
    });
  }

  final int value;
  const WalletMasterKeyVersion(this.value);
}

sealed class IWalletMasterKeys<ENC extends IViewMasterKey> with AppSerialization {
  const IWalletMasterKeys();
  factory IWalletMasterKeys.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValueWithInfo(expectedTags: [
      AppSerializationIdentifier.masterKeyExternal,
      AppSerializationIdentifier.masterKey
    ], cborBytes: bytes, cborObject: object);
    final IWalletMasterKeys masterKey = switch (values.identifier) {
      AppSerializationIdentifier.masterKeyExternal =>
        WalletMasterKeysExternal.deserialize(object: values.tag),
      AppSerializationIdentifier.masterKey =>
        WalletMasterKeys.deserialize(object: values.tag),
      _ => throw AppInternalError.internalError("IWalletMasterKeys")
    };
    return masterKey.cast();
  }
  List<int> get checksum;
  AccessMnemonicResponse mnemonic();
  ImportedKeyStorage? getKeyById(int keyId);
  CryptoPrivateKeysResponse readKeys(List<DerivableIndex> requestKeys);
  CryptoPublicKeysResponse readPublicKeys(List<DerivableIndex> requestKeys);
  CryptoPrivateKeyData getImportedKey(int keyId);
  WalletMasterKeys importCustomKey(ImportedKeyStorage newKey,
      {bool validateChecksum = true});
  WalletMasterKeys removeKey(int keyId);
  WalletMasterKeys removeSubWallet(int id);
  (WalletMasterKeys, int) importNewSubWallet(
      {required String mnemonic,
      required SubWalletType type,
      required String name,
      required DateTime? created,
      String? passphrase});
  CryptoPrivateKeyData toKey(DerivableIndex key);
  ENC toEncryptedMaterKey({required MemoryWalletKey key, required List<int> memoryKey});
  ENC encrypt(MemoryWalletKey walletKey, List<int> memoryKey);
  T cast<T extends IWalletMasterKeys>() {
    if (this is! T) {
      throw AppInternalError.internalError("IWalletMasterKeys");
    }
    return this as T;
  }
}

final class WalletMasterKeysExternal extends IWalletMasterKeys<ViewExternalMasterKey> {
  @override
  final List<int> checksum;
  final ExternalWalletConnectionInfo connectionId;
  final List<ViewImportedSecretKey> customKeys;
  final List<ViewSubWalletKey> subWallets;
  WalletMasterKeysExternal({
    required List<int> checksum,
    required this.connectionId,
    List<ViewImportedSecretKey> customKeys = const [],
    List<ViewSubWalletKey> subWallets = const [],
  })  : checksum = checksum.asImmutableBytes,
        customKeys = customKeys.immutable,
        subWallets = subWallets.immutable;
  factory WalletMasterKeysExternal.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.masterKeyExternal,
        cborBytes: bytes,
        cborObject: object);
    final List<ViewImportedSecretKey> customKeys = values
        .listAt<CborTagValue>(2)
        .map((e) => ViewImportedSecretKey.deserialize(object: e))
        .toList();
    final List<ViewSubWalletKey> subWallets = values
        .listAt<CborTagValue>(3)
        .map((e) => ViewSubWalletKey.deserialize(object: e))
        .toList();
    return WalletMasterKeysExternal(
        checksum: values.rawValueAt(0),
        connectionId:
            ExternalWalletConnectionInfo.deserialize(object: values.objectAt(1)),
        customKeys: customKeys,
        subWallets: subWallets);
  }

  static ({WalletMasterKeysExternal masterKey, List<int> connectorId}) generateFromBackup(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.masterKeyExternal,
        cborBytes: bytes,
        cborObject: object);
    final List<ViewImportedSecretKey> customKeys = values
        .listAt<CborTagValue>(2)
        .map((e) => ViewImportedSecretKey.deserialize(object: e))
        .toList();
    final List<ViewSubWalletKey> subWallets = values
        .listAt<CborTagValue>(3)
        .map((e) => ViewSubWalletKey.deserialize(object: e))
        .toList();
    final masterKey = WalletMasterKeysExternal(
        checksum: values.rawValueAt(0),
        connectionId:
            ExternalWalletConnectionInfo.deserialize(object: values.objectAt(1)),
        customKeys: customKeys,
        subWallets: subWallets);
    return (masterKey: masterKey, connectorId: values.rawValueAt(4));
  }

  @override
  ViewExternalMasterKey encrypt(MemoryWalletKey walletKey, List<int> memoryKey) {
    final data = toCbor().encode().asImmutableBytesConst;
    final storageBytes = walletKey.encryptWalletStorage(data);
    return ViewExternalMasterKey._(
        connectionInfo: connectionId.toViewKey(),
        masterKey: MemoryWalletEncryptedData.generate(
            key: walletKey, walletData: data, memoryKey: memoryKey),
        storageData: storageBytes,
        customKeys: customKeys,
        subWallets: subWallets);
  }

  @override
  ViewExternalMasterKey toEncryptedMaterKey(
      {required MemoryWalletKey key, required List<int> memoryKey}) {
    final data = toCbor().encode().asImmutableBytesConst;
    final storageBytes = key.encryptWalletStorage(data);
    return ViewExternalMasterKey._(
        connectionInfo: connectionId.toViewKey(),
        masterKey: MemoryWalletEncryptedData.generate(
            key: key, walletData: data, memoryKey: memoryKey),
        storageData: storageBytes,
        customKeys: customKeys,
        subWallets: subWallets);
  }

  @override
  CryptoPrivateKeyData toKey(DerivableIndex key) {
    throw UnimplementedError();
  }

  @override
  CryptoPrivateKeyData getImportedKey(int keyId) {
    throw UnimplementedError();
  }

  @override
  ImportedKeyStorage? getKeyById(int keyId) {
    throw UnimplementedError();
  }

  @override
  WalletMasterKeys importCustomKey(ImportedKeyStorage newKey,
      {bool validateChecksum = true}) {
    throw UnimplementedError();
  }

  @override
  (WalletMasterKeys, int) importNewSubWallet(
      {required String mnemonic,
      required SubWalletType type,
      required String name,
      required DateTime? created,
      String? passphrase}) {
    throw UnimplementedError();
  }

  @override
  AccessMnemonicResponse mnemonic() {
    throw UnimplementedError();
  }

  @override
  CryptoPrivateKeysResponse readKeys(List<DerivableIndex> requestKeys) {
    throw UnimplementedError();
  }

  @override
  CryptoPublicKeysResponse readPublicKeys(List<DerivableIndex> requestKeys) {
    throw UnimplementedError();
  }

  @override
  WalletMasterKeys removeKey(int keyId) {
    throw UnimplementedError();
  }

  @override
  WalletMasterKeys removeSubWallet(int id) {
    throw UnimplementedError();
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.masterKeyExternal;

  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(checksum),
        connectionId.toCbor(),
        AppSerialization.listFromObjects(customKeys.map((e) => e.toCbor()).toList()),
        AppSerialization.listFromObjects(subWallets.map((e) => e.toCbor()).toList()),
      ];
  @override
  CborTagValue<CborObject<Object?>> toCbor({List<int>? connectionId}) {
    if (connectionId != null) {
      return CborTagValue(
          AppSerialization.listFromObjects([
            CborBytesValue(checksum),
            this.connectionId.toCbor(),
            AppSerialization.listFromObjects(customKeys.map((e) => e.toCbor()).toList()),
            AppSerialization.listFromObjects(subWallets.map((e) => e.toCbor()).toList()),
            CborBytesValue(connectionId)
          ]),
          AppSerializationIdentifier.masterKeyExternal.tags());
    }
    return super.toCbor();
  }

  WalletMasterKeysExternal copyWith({
    List<int>? checksum,
    ExternalWalletConnectionInfo? connectionId,
    List<ViewImportedSecretKey>? customKeys,
    List<ViewSubWalletKey>? subWallets,
  }) {
    return WalletMasterKeysExternal(
        checksum: checksum ?? this.checksum,
        connectionId: connectionId ?? this.connectionId,
        customKeys: customKeys ?? this.customKeys,
        subWallets: subWallets ?? this.subWallets);
  }
}

final class WalletMasterKeys extends IWalletMasterKeys<ViewMasterKey> {
  final List<int> _mnemonic;
  final List<int> _seed;
  final List<int> _entropySeed;
  final List<int> _cardanoLegacyByronSeed;
  final List<int> _cardanoIcarusSeed;
  final List<int> _checksum;
  final APPBip39Languages _language;
  final List<ImportedKeyStorage> _customKeys;
  final List<SubWalletMasterKeys> _subWallets;
  final List<ExternalWalletConnectionInfo> externalConnections;
  final WalletMasterKeyVersion version = WalletMasterKeyVersion.v1;
  @override
  List<int> get checksum => _checksum;

  WalletMasterKeys._({
    required List<int> mnemonic,
    required List<int> seedBytes,
    required List<ImportedKeyStorage> customKeys,
    required List<SubWalletMasterKeys> subWallets,
    required List<int> entropySeedBytes,
    required List<int> cardanoLegacyByronSeed,
    required List<int> cardanoIcarusSeed,
    required List<int> checksum,
    required APPBip39Languages language,
    required List<ExternalWalletConnectionInfo> externalConnections,
    // required this.version,
  })  : _seed = seedBytes.asImmutableBytesConst,
        _cardanoLegacyByronSeed = cardanoLegacyByronSeed.asImmutableBytesConst,
        _cardanoIcarusSeed = cardanoIcarusSeed.asImmutableBytesConst,
        _checksum = checksum.asImmutableBytesConst,
        _entropySeed = entropySeedBytes.asImmutableBytesConst,
        _mnemonic = mnemonic.asImmutableBytesConst,
        _customKeys = customKeys.immutable,
        _language = language,
        _subWallets = subWallets.immutable,
        externalConnections = externalConnections.immutable;

  factory WalletMasterKeys.generate({
    String? passphrase,
    required String mnemonic,
    List<SubWalletMasterKeys> subWallets = const [],
    List<ImportedKeyStorage> importedKeys = const [],
  }) {
    final mn = Mnemonic.fromString(mnemonic);
    final language = APPBip39Languages.findLanguage(mn);

    final isValid = Bip39MnemonicValidator(language.language);
    if (!isValid.isValid(mnemonic)) {
      throw AppCryptoExceptionConst.invalidMnemonic;
    }
    final decode = Bip39MnemonicDecoder(language.language).decode(mn.toStr());
    final String passPhrase = passphrase ?? '';
    final seed = Bip39SeedGenerator(mn);
    final List<int> seedBytes = seed.generate(passPhrase);
    final List<int> entropySeedBytes = seed.generateFromEntropy(passPhrase);
    final icarus = CardanoIcarusSeedGenerator(mnemonic).generate();
    final cardanoLegacy = CardanoByronLegacySeedGenerator(mnemonic).generate();
    final List<int> checksum = QuickCrypto.sha3256Hash(
        [...seedBytes, ...icarus, ...cardanoLegacy, ...passPhrase.codeUnits]);

    return WalletMasterKeys._(
        mnemonic: decode,
        seedBytes: seedBytes,
        customKeys: importedKeys,
        cardanoLegacyByronSeed: cardanoLegacy,
        cardanoIcarusSeed: icarus,
        checksum: checksum,
        entropySeedBytes: entropySeedBytes,
        language: language,
        subWallets: subWallets,
        externalConnections: []);
  }

  factory WalletMasterKeys.deserialize({List<int>? bytes, CborObject? object}) {
    try {
      final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.masterKey,
      );

      final List<int> mnemonic = values.rawValueAt(0);
      final List<int> seed = values.rawValueAt(1);
      final importedKeys = values
          .listAt<CborTagValue>(2)
          .map((e) => ImportedKeyStorage.deserialize(object: e))
          .toList();
      final List<int> cardanoLegacy = values.rawValueAt(4);
      final List<int> icarus = values.rawValueAt(5);
      final List<int> checksum = values.rawValueAt(6);
      final List<int> entropySeed = values.rawValueAt(7);
      final APPBip39Languages language =
          APPBip39Languages.fromValue(values.rawValueAt(8));
      final version = WalletMasterKeyVersion.fromValue(values.rawValueAt(11),
          defaultVersion: WalletMasterKeyVersion.v0);
      final subWallets = values
          .listAt<CborTagValue>(9, emptyOnNull: true)
          .map((e) => SubWalletMasterKeys.deserialize(version, object: e))
          .toList();
      final externalWallets = values
          .listAt<CborTagValue>(10, emptyOnNull: true)
          .map((e) => ExternalWalletConnectionInfo.deserialize(object: e))
          .toList();

      return WalletMasterKeys._(
          mnemonic: mnemonic,
          seedBytes: seed,
          customKeys: importedKeys,
          cardanoLegacyByronSeed: cardanoLegacy,
          cardanoIcarusSeed: icarus,
          checksum: checksum,
          entropySeedBytes: entropySeed,
          language: language,
          subWallets: subWallets,
          externalConnections: externalWallets);
    } catch (e) {
      throw AppCryptoExceptionConst.invalidMnemonic;
    }
  }

  static (WalletMasterKeys, bool, List<int>?) generateFromBackup(
      {String? passphrase, List<int>? bytes, CborObject? object}) {
    try {
      final CborListValue values = AppSerialization.decodeTaggedValue(
          cborBytes: bytes,
          cborObject: object,
          identifier: AppSerializationIdentifier.backupMasterKey);
      final version = WalletMasterKeyVersion.fromValue(values.rawValueAt(6),
          defaultVersion: WalletMasterKeyVersion.v0);

      final List<int> mnemonicBytes = values.rawValueAt(0);
      final importedKeys = switch (version) {
        WalletMasterKeyVersion.v0 => <ImportedKeyStorage>[],
        WalletMasterKeyVersion.v1 => values
            .listAt<CborTagValue>(1)
            .map((e) => ImportedKeyStorage.deserialize(object: e))
            .toList(),
      };
      final List<int> checksum = values.rawValueAt(2);
      final APPBip39Languages language =
          APPBip39Languages.fromValue(values.rawValueAt(3));
      final mnemonic = Bip39MnemonicEncoder(language.language).encode(mnemonicBytes);
      final subWallets = values
          .listAt<CborTagValue>(4, emptyOnNull: true)
          .map((e) => SubWalletMasterKeys.deserialize(version, object: e))
          .toList();
      final List<int>? backupChecksum = values.rawValueAt(5);
      WalletMasterKeys wallet = WalletMasterKeys.generate(
          mnemonic: mnemonic.toStr(),
          passphrase: passphrase,
          subWallets: subWallets,
          importedKeys: importedKeys);
      return (wallet, BytesUtils.bytesEqual(checksum, wallet.checksum), backupChecksum);
    } catch (_) {
      throw WalletExceptionConst.invalidBackupData;
    }
  }

  @override
  AccessMnemonicResponse mnemonic() {
    final encode = Bip39MnemonicEncoder(_language.language).encode(_mnemonic);
    return AccessMnemonicResponse._(
        mnemonic: encode,
        subWallets: _subWallets
            .map((e) =>
                SubWalletMnemonicResponse._(subWalletId: e.id, mnemonic: e.mnemonic()))
            .toList());
  }

  @override
  ImportedKeyStorage? getKeyById(int keyId) {
    return _customKeys.firstWhereOrNull((element) => element.id == keyId);
  }

  @override
  CryptoPrivateKeyData toKey(DerivableIndex key) {
    if (key.isImportedKey) {
      final customKey = getKeyById(key.importedKeyId!);
      if (customKey == null) {
        throw AppCryptoExceptionConst.privateKeyIsNotAvailable;
      }
      return customKey.toKey(key);
    }

    if (key.subId != null) {
      final subKey = _subWallets.firstWhere((e) => e.id == key.subId,
          orElse: () => throw WalletExceptionConst.walletDoesNotExists);
      return subKey.toKey(key);
    }
    final seedBytes = _getSeed(key.seedGeneration);
    final bip32Key =
        CryptoPrivateKeyData._fromSeed(seedBytes: seedBytes, coin: key.currencyCoin);
    return key._derive(bip32Key);
  }

  @override
  CryptoPrivateKeysResponse readKeys(List<DerivableIndex> requestKeys) {
    final List<CryptoPrivateKeyDataWithInfo> keys = [];
    for (final i in requestKeys) {
      final key = toKey(i);
      keys.add(CryptoPrivateKeyDataWithInfo(key: key, index: i));
    }
    return CryptoPrivateKeysResponse._(keys);
  }

  @override
  CryptoPublicKeysResponse readPublicKeys(List<DerivableIndex> requestKeys) {
    final List<CryptoPublicKeyDataWithInfo> pubKeys = [];
    for (final i in requestKeys) {
      final bool byronLegacy = i.currencyCoin.proposal == CoinProposal.cip0019;

      final CryptoPrivateKeyData privateKey = toKey(i);
      if (!byronLegacy) {
        pubKeys.add(CryptoPublicKeyDataWithInfo(key: privateKey.publicKey, index: i));
        continue;
      }
      final bipKey = privateKey.toHdKey() as Bip32Base<dynamic>;
      final hdPathKey = CardanoByronLegacy.fromBip32(
              toKey(i.cast<Bip32DerivationIndex>().take(Bip44Levels.master)).toHdKey()
                  as Bip32Base<dynamic>)
          .hdPathKey;
      pubKeys.add(CryptoPublicKeyDataWithInfo(
          key: AdaLegacyPublicKeyData._fromBip32(
              account: bipKey, hdPathKey: hdPathKey, coin: i.currencyCoin),
          index: i));
    }
    return CryptoPublicKeysResponse._(pubKeys);
  }

  @override
  CryptoPrivateKeyData getImportedKey(int keyId) {
    final importedKey = getKeyById(keyId);
    if (importedKey == null) {
      throw AppCryptoExceptionConst.privateKeyIsNotAvailable;
    }
    final keyInfo = importedKey.getKey();
    return keyInfo;
  }

  @override
  WalletMasterKeys importCustomKey(ImportedKeyStorage newKey,
      {bool validateChecksum = true}) {
    if (_customKeys.contains(newKey) ||
        _customKeys.any((e) => e.checksum == newKey.checksum)) {
      throw WalletExceptionConst.keyAlreadyExist;
    }
    return WalletMasterKeys._(
      mnemonic: _mnemonic,
      seedBytes: _seed,
      customKeys: [newKey, ..._customKeys],
      cardanoLegacyByronSeed: _cardanoLegacyByronSeed,
      cardanoIcarusSeed: _cardanoIcarusSeed,
      checksum: _checksum,
      entropySeedBytes: _entropySeed,
      language: _language,
      subWallets: _subWallets,
      externalConnections: externalConnections,
    );
  }

  @override
  ViewMasterKey encrypt(MemoryWalletKey walletKey, List<int> memoryKey) {
    return toEncryptedMaterKey(key: walletKey, memoryKey: memoryKey);
  }

  @override
  ViewMasterKey toEncryptedMaterKey(
      {required MemoryWalletKey key, required List<int> memoryKey}) {
    final msgBytes = toCbor().encode().asImmutableBytes;
    final storageBytes = key.encryptWalletStorage(msgBytes);
    return ViewMasterKey._(
        externalConnectors: externalConnections.map((e) => e.toViewKey()).toList(),
        masterKey: MemoryWalletEncryptedData.generate(
            key: key, walletData: msgBytes, memoryKey: memoryKey),
        storageData: storageBytes,
        customKeys: _customKeys.map((e) => e.toVieweKey()).toList(),
        subWallets: _subWallets.map((e) => e.toViewKey()).toList());
  }

  @override
  (WalletMasterKeys, int) importNewSubWallet(
      {required String mnemonic,
      required SubWalletType type,
      required String name,
      required DateTime? created,
      String? passphrase}) {
    final SubWalletMasterKeys subWallet = switch (type) {
      SubWalletType.bip39 => Bip39WalletMasterKeys.generate(
          mnemonic: mnemonic, passphrase: passphrase, name: name, created: created),
      SubWalletType.monero =>
        MoneroWalletMasterKeys.generate(mnemonic: mnemonic, created: created, name: name),
      SubWalletType.ton => TonWalletMasterKeys.generate(
          mnemonic: mnemonic, passphrase: passphrase, name: name, created: created),
    };
    if (_subWallets.any((e) => e.id == subWallet.id)) {
      throw WalletExceptionConst.walletAlreadyExists;
    }
    final masterKey = WalletMasterKeys._(
      mnemonic: _mnemonic,
      seedBytes: _seed,
      customKeys: _customKeys,
      cardanoLegacyByronSeed: _cardanoLegacyByronSeed,
      cardanoIcarusSeed: _cardanoIcarusSeed,
      checksum: _checksum,
      entropySeedBytes: _entropySeed,
      language: _language,
      externalConnections: externalConnections,
      subWallets: [..._subWallets, subWallet],
    );
    return (masterKey, subWallet.id);
  }

  @override
  WalletMasterKeys removeSubWallet(int id) {
    return WalletMasterKeys._(
      mnemonic: _mnemonic,
      seedBytes: _seed,
      customKeys: _customKeys,
      cardanoLegacyByronSeed: _cardanoLegacyByronSeed,
      cardanoIcarusSeed: _cardanoIcarusSeed,
      checksum: _checksum,
      entropySeedBytes: _entropySeed,
      language: _language,
      externalConnections: externalConnections,
      subWallets: _subWallets.where((e) => e.id != id).toList(),
    );
  }

  @override
  WalletMasterKeys removeKey(int keyId) {
    final accounts = _customKeys.where((element) => element.id != keyId).toList();
    return WalletMasterKeys._(
      mnemonic: _mnemonic,
      seedBytes: _seed,
      customKeys: accounts,
      cardanoLegacyByronSeed: _cardanoLegacyByronSeed,
      cardanoIcarusSeed: _cardanoIcarusSeed,
      checksum: _checksum,
      entropySeedBytes: _entropySeed,
      externalConnections: externalConnections,
      language: _language,
      subWallets: _subWallets,
    );
  }

  List<int> _getSeed(SeedTypes type) {
    switch (type) {
      case SeedTypes.bip39:
        return _seed;
      case SeedTypes.bip39Entropy:
        return _entropySeed;
      case SeedTypes.icarus:
        return _cardanoIcarusSeed;
      default:
        return _cardanoLegacyByronSeed;
    }
  }

  int getNewExternalConnectionClientId() {
    final ids = externalConnections.map((e) => e.clientId).toList();
    int clientId = 0;
    while (clientId < BinaryOps.mask8) {
      if (!ids.contains(clientId)) return clientId;
      clientId++;
    }
    throw WalletExceptionConst.toManyWalletConnections;
  }

  WalletMasterKeys importNewExternalConnection(
      ExternalWalletConnectionInfo newConnection) {
    if (externalConnections.any((e) =>
        BytesUtils.bytesEqual(e.publicKey, newConnection.publicKey) ||
        e.clientId == newConnection.clientId)) {
      throw WalletExceptionConst.externalWalletConnectionAlreadyExists;
    }
    return WalletMasterKeys._(
      mnemonic: _mnemonic,
      seedBytes: _seed,
      customKeys: _customKeys,
      cardanoLegacyByronSeed: _cardanoLegacyByronSeed,
      cardanoIcarusSeed: _cardanoIcarusSeed,
      checksum: _checksum,
      entropySeedBytes: _entropySeed,
      language: _language,
      subWallets: _subWallets,
      externalConnections: [...externalConnections, newConnection],
    );
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.masterKey;

  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(_mnemonic),
        CborBytesValue(_seed),
        AppSerialization.listFromObjects(_customKeys.map((e) => e.toCbor()).toList()),
        const CborNullValue(),
        CborBytesValue(_cardanoLegacyByronSeed),
        CborBytesValue(_cardanoIcarusSeed),
        CborBytesValue(_checksum),
        CborBytesValue(_entropySeed),
        _language.value.toCbor(),
        AppSerialization.listFromObjects(_subWallets.map((e) => e.toCbor()).toList()),
        AppSerialization.listFromObjects(
            externalConnections.map((e) => e.toCbor()).toList()),
        version.value.toCbor(),
      ];

  @override
  CborTagValue toCbor({List<int>? backupChecksum}) {
    if (backupChecksum != null) {
      return CborTagValue(
          AppSerialization.listFromObjects([
            CborBytesValue(_mnemonic),
            AppSerialization.listFromObjects(_customKeys.map((e) => e.toCbor()).toList()),
            CborBytesValue(_checksum),
            _language.value.toCbor(),
            AppSerialization.listFromObjects(_subWallets.map((e) => e.toCbor()).toList()),
            CborBytesValue(backupChecksum),
            version.value.toCbor()
          ]),
          AppSerializationIdentifier.backupMasterKey.tags());
    }
    return super.toCbor();
  }

  WalletMasterKeysExternal toExternalWallet(ExternalWalletConnectionInfo connectorId) {
    return WalletMasterKeysExternal(
        checksum: checksum,
        connectionId: connectorId,
        customKeys: _customKeys.map((e) => e.toVieweKey()).toList(),
        subWallets: _subWallets.map((e) => e.toViewKey()).toList());
  }
}

enum SubWalletType {
  bip39(AppSerializationIdentifier.bip39),
  monero(AppSerializationIdentifier.moneroSubWallet),
  ton(AppSerializationIdentifier.ton);

  final AppSerializationIdentifier tags;
  const SubWalletType(this.tags);
  static SubWalletType fromValue(List<int>? tags) {
    return values.firstWhere((e) => e.tags.isValidTags(tags),
        orElse: () => throw AppInternalError.internalError("SubWalletType"));
  }

  static SubWalletType fromIdentifier(int? identifier) {
    return values.firstWhere((e) => e.tags.id == identifier,
        orElse: () => throw AppInternalError.internalError("SubWalletType"));
  }

  bool get allowDerivation => this == SubWalletType.bip39;

  bool allowUsFor(EllipticCurveTypes type) {
    switch (this) {
      case SubWalletType.bip39:
        return true;
      case SubWalletType.monero:
        return type == EllipticCurveTypes.ed25519Monero;
      case SubWalletType.ton:
        return type == EllipticCurveTypes.ed25519;
    }
  }
}

abstract class SubWalletMasterKeys with AppSerialization {
  static String get defaultName => "SW";
  final List<int> checksum;
  final int id;
  final SubWalletType type;
  final List<int> name;
  final DateTime created;
  SubWalletMasterKeys._(
      {required this.id,
      required this.type,
      required List<int> name,
      required this.created,
      required List<int> checksum})
      : name = name.asImmutableBytes,
        checksum = checksum.asImmutableBytes;
  Mnemonic mnemonic();
  CryptoPrivateKeyData toKey(DerivableIndex key);
  factory SubWalletMasterKeys.deserialize(WalletMasterKeyVersion version,
      {List<int>? bytes, CborObject? object}) {
    final CborTagValue decode =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);
    final type = SubWalletType.fromValue(decode.tags);
    return switch (type) {
      SubWalletType.bip39 => Bip39WalletMasterKeys.deserialize(object: decode),
      SubWalletType.monero => MoneroWalletMasterKeys.deserialize(object: decode),
      SubWalletType.ton => TonWalletMasterKeys.deserialize(version, object: decode)
    };
  }

  ViewSubWalletKey toViewKey() => ViewSubWalletKey._(
      id: id,
      type: type,
      created: created,
      name: CryptoKeyUtils.decryptKeyNames(name, checksum));
}

final class Bip39WalletMasterKeys extends SubWalletMasterKeys {
  final List<int> _mnemonic;
  final List<int> _seed;
  final List<int> _entropySeed;
  final List<int> _cardanoLegacyByronSeed;
  final List<int> _cardanoIcarusSeed;

  final APPBip39Languages _language;

  @override
  Bip39Mnemonic mnemonic() {
    return Bip39MnemonicEncoder(_language.language).encode(_mnemonic);
  }

  factory Bip39WalletMasterKeys.generate({
    required String mnemonic,
    required String name,
    required DateTime? created,
    String? passphrase,
  }) {
    final mn = Mnemonic.fromString(mnemonic);
    final language = APPBip39Languages.findLanguage(mn);

    final isValid = Bip39MnemonicValidator(language.language);
    if (!isValid.isValid(mnemonic)) {
      throw AppCryptoExceptionConst.invalidMnemonic;
    }
    final decode = Bip39MnemonicDecoder(language.language).decode(mn.toStr());
    final String passPhrase = passphrase ?? '';
    final seed = Bip39SeedGenerator(mn);
    final List<int> seedBytes = seed.generate(passPhrase);
    final List<int> entropySeedBytes = seed.generateFromEntropy(passPhrase);
    final icarus = CardanoIcarusSeedGenerator(mnemonic).generate();
    final cardanoLegacy = CardanoByronLegacySeedGenerator(mnemonic).generate();
    final List<int> checksum =
        QuickCrypto.sha3256Hash([...seedBytes, ...icarus, ...cardanoLegacy]);
    final int id = Crc32().quickIntDigest(checksum);

    return Bip39WalletMasterKeys.__(
        mnemonic: decode,
        seedBytes: seedBytes,
        cardanoLegacyByronSeed: cardanoLegacy,
        cardanoIcarusSeed: icarus,
        checksum: checksum,
        entropySeedBytes: entropySeedBytes,
        language: language,
        name: CryptoKeyUtils.encryptKeyNames(name, checksum),
        created: created,
        id: id);
  }
  factory Bip39WalletMasterKeys.__({
    required List<int> mnemonic,
    required List<int> seedBytes,
    required List<int> entropySeedBytes,
    required List<int> cardanoLegacyByronSeed,
    required List<int> cardanoIcarusSeed,
    required List<int> checksum,
    required int id,
    required APPBip39Languages language,
    required List<int>? name,
    required DateTime? created,
  }) {
    name ??= CryptoKeyUtils.encryptKeyNames(
        "${SubWalletMasterKeys.defaultName} $id", checksum);
    return Bip39WalletMasterKeys._(
        mnemonic: mnemonic,
        seedBytes: seedBytes,
        entropySeedBytes: entropySeedBytes,
        cardanoLegacyByronSeed: cardanoLegacyByronSeed,
        cardanoIcarusSeed: cardanoIcarusSeed,
        checksum: checksum,
        id: id,
        language: language,
        created: created ?? DateTime.now(),
        name: name);
  }

  Bip39WalletMasterKeys._({
    required List<int> mnemonic,
    required List<int> seedBytes,
    required List<int> entropySeedBytes,
    required List<int> cardanoLegacyByronSeed,
    required List<int> cardanoIcarusSeed,
    required super.checksum,
    required super.name,
    required super.created,
    required super.id,
    required APPBip39Languages language,
  })  : _seed = seedBytes.asImmutableBytesConst,
        _cardanoLegacyByronSeed = cardanoLegacyByronSeed.asImmutableBytesConst,
        _cardanoIcarusSeed = cardanoIcarusSeed.asImmutableBytesConst,
        _entropySeed = entropySeedBytes.asImmutableBytesConst,
        _mnemonic = mnemonic.asImmutableBytesConst,
        _language = language,
        super._(type: SubWalletType.bip39);

  factory Bip39WalletMasterKeys.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: SubWalletType.bip39.tags);
    return Bip39WalletMasterKeys.__(
      mnemonic: values.rawValueAt(0),
      seedBytes: values.rawValueAt(1),
      entropySeedBytes: values.rawValueAt(2),
      cardanoLegacyByronSeed: values.rawValueAt(3),
      cardanoIcarusSeed: values.rawValueAt(4),
      checksum: values.rawValueAt(5),
      language: APPBip39Languages.fromValue(values.rawValueAt(6)),
      id: values.rawValueAt(7),
      name: values.rawValueAt(8),
      created: values.rawValueAt(9),
    );
  }

  List<int> _getSeed(SeedTypes type) {
    switch (type) {
      case SeedTypes.bip39:
        return _seed;
      case SeedTypes.bip39Entropy:
        return _entropySeed;
      case SeedTypes.icarus:
        return _cardanoIcarusSeed;
      default:
        return _cardanoLegacyByronSeed;
    }
  }

  @override
  CryptoPrivateKeyData toKey(DerivableIndex key) {
    if (key.isImportedKey) {
      throw AppCryptoExceptionConst.privateKeyIsNotAvailable;
    }
    final seedBytes = _getSeed(key.seedGeneration);
    final bip32Key =
        CryptoPrivateKeyData._fromSeed(seedBytes: seedBytes, coin: key.currencyCoin);
    return key._derive(bip32Key);
  }

  @override
  SerializationIdentifier get serializationIdentifier => type.tags;

  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(_mnemonic),
        CborBytesValue(_seed),
        CborBytesValue(_entropySeed),
        CborBytesValue(_cardanoLegacyByronSeed),
        CborBytesValue(_cardanoIcarusSeed),
        CborBytesValue(checksum),
        _language.value.toCbor(),
        id.toCbor(),
        CborBytesValue(name),
        created.toCbor()
      ];
}

enum MoneroMnemonicType {
  checksum(0),
  nChecksum(1);

  const MoneroMnemonicType(this.value);

  final int value;
  static MoneroMnemonicType fromMnemonicLength(int length) {
    if (length == MoneroWordsNum.wordsNum13.value ||
        length == MoneroWordsNum.wordsNum25.value) {
      return MoneroMnemonicType.checksum;
    } else if (length == MoneroWordsNum.wordsNum12.value ||
        length == MoneroWordsNum.wordsNum24.value) {
      return MoneroMnemonicType.nChecksum;
    }
    throw AppCryptoExceptionConst.invalidMnemonic;
  }

  static MoneroMnemonicType fromValue(int? tag) {
    return values.firstWhere((e) => e.value == tag,
        orElse: () => throw AppInternalError.internalError("MoneroMnemonicType"));
  }
}

final class MoneroWalletMasterKeys extends SubWalletMasterKeys {
  final List<int> _mnemonic;
  final List<int> _seed;
  final AppMoneroMnemonicLanguages _language;
  final MoneroMnemonicType _type;

  @override
  Mnemonic mnemonic() {
    switch (_type) {
      case MoneroMnemonicType.checksum:
        return MoneroMnemonicEncoder(_language.language).encodeWithChecksum(_mnemonic);
      case MoneroMnemonicType.nChecksum:
        return MoneroMnemonicEncoder(_language.language).encodeNoChecksum(_mnemonic);
    }
  }

  factory MoneroWalletMasterKeys.generate(
      {required String mnemonic, required String name, required DateTime? created}) {
    final mn = Mnemonic.fromString(mnemonic);
    final language = AppMoneroMnemonicLanguages.findLanguage(mn);

    final isValid = MoneroMnemonicValidator(language.language);
    if (!isValid.isValid(mnemonic)) {
      throw AppCryptoExceptionConst.invalidMnemonic;
    }
    final decode = MoneroMnemonicDecoder(language.language).decode(mn.toStr());
    final seed = MoneroSeedGenerator(mn);
    final List<int> seedBytes = seed.generate();
    final List<int> checksum = QuickCrypto.sha3256Hash([...seedBytes]);
    final id = Crc32().quickIntDigest(checksum);
    return MoneroWalletMasterKeys.__(
        mnemonic: decode,
        seedBytes: seedBytes,
        checksum: checksum,
        language: language,
        type: MoneroMnemonicType.fromMnemonicLength(mn.wordsCount()),
        id: id,
        created: created,
        name: CryptoKeyUtils.encryptKeyNames(name, checksum));
  }
  factory MoneroWalletMasterKeys.__(
      {required List<int> mnemonic,
      required List<int> seedBytes,
      required List<int> checksum,
      required AppMoneroMnemonicLanguages language,
      required MoneroMnemonicType type,
      required int id,
      required DateTime? created,
      required List<int>? name}) {
    return MoneroWalletMasterKeys._(
        mnemonic: mnemonic,
        seedBytes: seedBytes,
        checksum: checksum,
        language: language,
        type: type,
        id: id,
        created: created ?? DateTime.now(),
        name: name ??
            CryptoKeyUtils.encryptKeyNames(
                "${SubWalletMasterKeys.defaultName} $id", checksum));
  }
  MoneroWalletMasterKeys._({
    required List<int> mnemonic,
    required List<int> seedBytes,
    required super.checksum,
    required AppMoneroMnemonicLanguages language,
    required MoneroMnemonicType type,
    required super.id,
    required super.created,
    required super.name,
  })  : _seed = seedBytes.asImmutableBytes,
        _mnemonic = mnemonic.asImmutableBytes,
        _language = language,
        _type = type,
        super._(type: SubWalletType.monero);

  factory MoneroWalletMasterKeys.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: SubWalletType.monero.tags);
    return MoneroWalletMasterKeys.__(
        mnemonic: values.rawValueAt(0),
        seedBytes: values.rawValueAt(1),
        checksum: values.rawValueAt(2),
        language: AppMoneroMnemonicLanguages.fromValue(values.rawValueAt(3)),
        type: MoneroMnemonicType.fromValue(values.rawValueAt(4)),
        id: values.rawValueAt(5),
        name: values.rawValueAt(6),
        created: values.rawValueAt(7));
  }

  @override
  SubWalletType get type => SubWalletType.monero;

  @override
  CryptoPrivateKeyData toKey(DerivationIndex key,
      {Bip44Levels maxLevel = Bip44Levels.addressIndex}) {
    if (key is! Bip32DerivationIndex) {
      throw AppCryptoExceptionConst.invalidDerivationKey;
    }
    if (key.indexes.isNotEmpty) {
      throw AppCryptoExceptionConst.invalidDerivationKey;
    }
    return MoneroPrivateKeyData._fromSeed(seedBytes: _seed, coin: key.currencyCoin);
  }

  @override
  SerializationIdentifier get serializationIdentifier => type.tags;

  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(_mnemonic),
        CborBytesValue(_seed),
        CborBytesValue(checksum),
        _language.value.toCbor(),
        _type.value.toCbor(),
        id.toCbor(),
        CborBytesValue(name),
        created.toCbor()
      ];
}

final class TonWalletMasterKeys extends SubWalletMasterKeys {
  final List<int> _mnemonic;
  final List<int> _seed;

  @override
  Mnemonic mnemonic() {
    return CryptoKeyUtils.bytesToBip39MnemonicNew(_mnemonic);
  }

  factory TonWalletMasterKeys.generate(
      {required String mnemonic,
      required String name,
      required DateTime? created,
      required String? passphrase}) {
    final mn = Mnemonic.fromString(mnemonic);
    final seed = TonSeedGenerator(mn);
    final List<int> seedBytes =
        seed.generate(password: passphrase ?? '', validateTonMnemonic: true);
    final List<int> checksum = QuickCrypto.sha3256Hash([...seedBytes]);
    final int id = Crc32().quickIntDigest(checksum);
    return TonWalletMasterKeys._(
        mnemonic: CryptoKeyUtils.bip39MnemonicToBytesNew(mn),
        seedBytes: seedBytes,
        checksum: checksum,
        id: id,
        version: WalletMasterKeyVersion.v1,
        name: CryptoKeyUtils.encryptKeyNames(name, checksum),
        created: created);
  }

  TonWalletMasterKeys.__(
      {required List<int> mnemonic,
      required List<int> seedBytes,
      required super.id,
      required super.checksum,
      required super.created,
      required super.name})
      : _seed = seedBytes.asImmutableBytes,
        _mnemonic = mnemonic.asImmutableBytes,
        super._(type: SubWalletType.ton);
  factory TonWalletMasterKeys._({
    required List<int> mnemonic,
    required List<int> seedBytes,
    required List<int> checksum,
    required int id,
    required WalletMasterKeyVersion version,
    required DateTime? created,
    required List<int>? name,
  }) {
    if (version == WalletMasterKeyVersion.v0) {
      final mn = CryptoKeyUtils.bytesToBip39Mnemonic(
          bytes: mnemonic, language: TonMnemonicLanguages.english);
      mnemonic = CryptoKeyUtils.bip39MnemonicToBytesNew(mn);
    }
    return TonWalletMasterKeys.__(
        mnemonic: mnemonic,
        seedBytes: seedBytes,
        checksum: checksum,
        id: id,
        // version: WalletMasterKeyVersion.v1,
        created: created ?? DateTime.now(),
        name: name ??
            CryptoKeyUtils.encryptKeyNames(
                "${SubWalletMasterKeys.defaultName} $id", checksum));
  }
  factory TonWalletMasterKeys.deserialize(WalletMasterKeyVersion version,
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: SubWalletType.ton.tags);
    return TonWalletMasterKeys._(
        mnemonic: values.rawValueAt(0),
        seedBytes: values.rawValueAt(1),
        checksum: values.rawValueAt(2),
        id: values.rawValueAt(3),
        version: version,
        name: values.rawValueAt(4),
        created: values.rawValueAt(5));
  }

  @override
  SubWalletType get type => SubWalletType.ton;

  @override
  CryptoPrivateKeyData toKey(DerivationIndex key) {
    if (key is! Bip32DerivationIndex) {
      throw AppCryptoExceptionConst.invalidDerivationKey;
    }
    if (key.indexes.isNotEmpty) {
      throw AppCryptoExceptionConst.invalidDerivationKey;
    }
    return PrivateKeyData._(
      key: Ed25519PrivateKey.fromBytes(_seed.sublist(0, Ed25519KeysConst.privKeyByteLen)),
      coin: key.currencyCoin,
    );
  }

  @override
  SerializationIdentifier get serializationIdentifier => type.tags;

  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(_mnemonic),
        CborBytesValue(_seed),
        CborBytesValue(checksum),
        CborIntValue(id),
        CborBytesValue(name),
        created.toCbor()
      ];
}

final class ExternalWalletConnectionInfo with AppSerialization {
  final List<int> privateKey;
  final List<int> publicKey;
  final List<int> targetPublicKey;
  final List<int> sharedKey;
  final List<int> topic;
  final int clientId;
  ExternalWalletConnectionInfo({
    required List<int> privateKey,
    required List<int> publicKey,
    required List<int> sharedKey,
    required List<int> targetPublicKey,
    required List<int> topic,
    required this.clientId,
  })  : privateKey = privateKey.asImmutableBytesConst,
        publicKey = publicKey.asImmutableBytes,
        sharedKey = sharedKey.asImmutableBytes,
        targetPublicKey = targetPublicKey.asImmutableBytes,
        topic = topic.asImmutableBytes;
  factory ExternalWalletConnectionInfo.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.externalWalletConnectorId);
    return ExternalWalletConnectionInfo(
        privateKey: values.rawValueAt(0),
        publicKey: values.rawValueAt(1),
        sharedKey: values.rawValueAt(2),
        targetPublicKey: values.rawValueAt(3),
        topic: values.rawValueAt(4),
        clientId: values.rawValueAt(5));
  }
  factory ExternalWalletConnectionInfo.generate(SymKey key, int clientId) {
    final hdkf = HKDF(
        ikm: key.sharedKey(),
        hash: () => SHA256(),
        length: Ed25519KeysConst.privKeyByteLen);
    final symKey = hdkf.derive().asImmutableBytes;
    return ExternalWalletConnectionInfo(
        privateKey: key.privateKey,
        publicKey: key.publicKey(),
        sharedKey: symKey,
        targetPublicKey: key.targetPublicKey,
        topic: QuickCrypto.sha256Hash(symKey),
        clientId: clientId);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.externalWalletConnectorId;

  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(privateKey),
        CborBytesValue(publicKey),
        CborBytesValue(sharedKey),
        CborBytesValue(targetPublicKey),
        CborBytesValue(topic),
        clientId.toCbor()
      ];

  ViewExternalWalletConnectionInfo toViewKey() {
    return ViewExternalWalletConnectionInfo(
        topic: BytesUtils.toHexString(topic), sharedKey: sharedKey, clientId: clientId);
  }
}
