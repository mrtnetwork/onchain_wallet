part of 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

sealed class IViewMasterKey with AppSerialization, Equality {
  final MemoryWalletEncryptedData masterKey;
  final List<ViewImportedSecretKey> customKeys;
  final List<ViewSubWalletKey> subWallets;
  final StorageEncryptedWallet storageData;
  // String? _storageDataStr;
  // String storageDataB64() {
  //   return _storageDataStr ??=
  //       StringUtils.decode(storageData, type: StringEncoding.base64);
  // }

  factory IViewMasterKey.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValueWithInfo(
        cborBytes: bytes,
        cborObject: object,
        expectedTags: [
          AppSerializationIdentifier.encryptedMasterKey,
          AppSerializationIdentifier.encryptedMasterKeyExternal
        ]);
    return switch (values.identifier) {
      AppSerializationIdentifier.encryptedMasterKey =>
        ViewMasterKey.deserialize(object: values.tag),
      AppSerializationIdentifier.encryptedMasterKeyExternal =>
        ViewExternalMasterKey.deserialize(object: values.tag),
      _ => throw AppInternalError.internalError("IViewMasterKey")
    };
  }
  IViewMasterKey({
    required this.masterKey,
    required List<ViewImportedSecretKey> customKeys,
    required this.storageData,
    List<ViewSubWalletKey> subWallets = const [],
  })  : customKeys = customKeys.immutable,
        subWallets = subWallets.toImutableList;

  bool hasSubwallet(int id) {
    return subWallets.any((e) => e.id == id);
  }

  bool hasImportedKey(int id) {
    return customKeys.any((e) => e.id == id);
  }

  String? getKeyNameOrId(int id) {
    final key = customKeys.firstWhereOrNull((e) => e.id == id);
    return key?.name;
  }

  T cast<T extends IViewMasterKey>() {
    if (this is! T) {
      throw AppInternalError.internalError("IViewMasterKey");
    }
    return this as T;
  }
}

final class ViewMasterKey extends IViewMasterKey {
  final List<ViewExternalWalletConnectionInfo> externalConnectors;

  ViewMasterKey.__({
    required super.masterKey,
    required super.customKeys,
    required super.storageData,
    List<ViewExternalWalletConnectionInfo> externalConnectors = const [],
    super.subWallets = const [],
  }) : externalConnectors = externalConnectors.immutable;
  factory ViewMasterKey._(
      {required MemoryWalletEncryptedData masterKey,
      required StorageEncryptedWallet storageData,
      required List<ViewImportedSecretKey> customKeys,
      required List<ViewSubWalletKey> subWallets,
      required List<ViewExternalWalletConnectionInfo> externalConnectors}) {
    return ViewMasterKey.__(
        masterKey: masterKey,
        customKeys: customKeys,
        subWallets: subWallets,
        storageData: storageData,
        externalConnectors: externalConnectors);
  }
  factory ViewMasterKey.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.encryptedMasterKey);
    final List<ViewImportedSecretKey> customKeys = values
        .listAt<CborTagValue>(1)
        .map((e) => ViewImportedSecretKey.deserialize(object: e))
        .toList();
    final List<ViewSubWalletKey> subWallets = values
        .listAt<CborTagValue>(2, emptyOnNull: true)
        .map((e) => ViewSubWalletKey.deserialize(object: e))
        .toList();
    return ViewMasterKey._(
        masterKey: MemoryWalletEncryptedData.deserialize(
            object: values.objectAt<CborTagValue>(0)),
        customKeys: customKeys,
        subWallets: subWallets,
        storageData: StorageEncryptedWallet.deserialize(object: values.objectAt(3)),
        externalConnectors: values
            .listAt<CborTagValue>(4)
            .map((e) => ViewExternalWalletConnectionInfo.deserialize(object: e))
            .toList());
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.encryptedMasterKey;

  @override
  List<CborObject?> get serializationItems => [
        masterKey.toCbor(),
        CborListValue.definite(customKeys.map((e) => e.toCbor()).toList()),
        CborListValue.definite(subWallets.map((e) => e.toCbor()).toList()),
        storageData.toCbor(),
        AppSerialization.listFromObjects(
            externalConnectors.map((e) => e.toCbor()).toList())
      ];

  @override
  List<dynamic> get variables => [storageData];
}

final class ViewExternalMasterKey extends IViewMasterKey {
  final ViewExternalWalletConnectionInfo connectionInfo;
  ViewExternalMasterKey.__({
    required super.masterKey,
    required super.customKeys,
    required super.storageData,
    required this.connectionInfo,
    super.subWallets = const [],
  });
  factory ViewExternalMasterKey._(
      {required MemoryWalletEncryptedData masterKey,
      required StorageEncryptedWallet storageData,
      required List<ViewImportedSecretKey> customKeys,
      required List<ViewSubWalletKey> subWallets,
      required ViewExternalWalletConnectionInfo connectionInfo}) {
    return ViewExternalMasterKey.__(
        masterKey: masterKey,
        customKeys: customKeys,
        subWallets: subWallets,
        storageData: storageData,
        connectionInfo: connectionInfo);
  }
  factory ViewExternalMasterKey.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.encryptedMasterKeyExternal);
    final List<ViewImportedSecretKey> customKeys = values
        .listAt<CborTagValue>(1)
        .map((e) => ViewImportedSecretKey.deserialize(object: e))
        .toList();
    final List<ViewSubWalletKey> subWallets = values
        .listAt<CborTagValue>(2, emptyOnNull: true)
        .map((e) => ViewSubWalletKey.deserialize(object: e))
        .toList();
    return ViewExternalMasterKey._(
        masterKey: MemoryWalletEncryptedData.deserialize(
            object: values.objectAt<CborTagValue>(0)),
        customKeys: customKeys,
        subWallets: subWallets,
        storageData: StorageEncryptedWallet.deserialize(object: values.rawValueAt(3)),
        connectionInfo:
            ViewExternalWalletConnectionInfo.deserialize(object: values.objectAt(4)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.encryptedMasterKeyExternal;

  @override
  List<CborObject?> get serializationItems => [
        masterKey.toCbor(),
        CborListValue.definite(customKeys.map((e) => e.toCbor()).toList()),
        CborListValue.definite(subWallets.map((e) => e.toCbor()).toList()),
        storageData.toCbor(),
        connectionInfo.toCbor()
      ];

  @override
  List<dynamic> get variables => [storageData];
}

final class ViewSubWalletKey with AppSerialization, Equality {
  final int id;
  final SubWalletType type;
  final String name;
  final DateTime created;
  const ViewSubWalletKey._(
      {required this.id, required this.type, required this.name, required this.created});
  factory ViewSubWalletKey.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.encryptedSubWallet);
    return ViewSubWalletKey._(
        id: values.rawValueAt(0),
        type: SubWalletType.fromIdentifier(values.rawValueAt<int>(1)),
        name: values.rawValueAt(2),
        created: values.rawValueAt(3));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.encryptedSubWallet;

  @override
  List<CborObject?> get serializationItems =>
      [CborIntValue(id), CborIntValue(type.tags.id), name.toCbor(), created.toCbor()];

  @override
  List<dynamic> get variables => [id, type, name, created];
}

final class ViewImportedSecretKey with Equality, AppSerialization {
  final int id;
  final CryptoCoins coin;
  final DateTime created;
  final String name;
  final CustomKeyType keyType;
  const ViewImportedSecretKey.__(
      {required this.coin,
      required this.id,
      required this.created,
      required this.name,
      required this.keyType});
  factory ViewImportedSecretKey.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.encryptedCustomKey);
    return ViewImportedSecretKey.__(
        id: values.rawValueAt(0),
        coin: CoinsUtils.getSerializationCoin(values.rawValueAt(1)),
        created: values.rawValueAt(2),
        name: values.rawValueAt(3),
        keyType: CustomKeyType.fromValue(values.rawValueAt(4)));
  }

  bool allowDerivation(CryptoCoins coin) {
    assert(canUseFor(coin), "unsupported coin. should not be happend");
    return !keyType.isPrivateKey || coin.proposal.isSubstrate;
  }

  @override
  List get variables => [id, coin, keyType.name];

  bool canUseFor(CryptoCoins coin) {
    if (this.coin == coin) return true;
    if (coin == Bip44Coins.moneroEd25519Slip) {
      return false;
    }
    if (!keyType.isPrivateKey) return false;
    return this.coin.conf.type == coin.conf.type;
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.encryptedCustomKey;

  @override
  List<CborObject?> get serializationItems => [
        id.toCbor(),
        coin.identifier.toCbor(),
        CborEpochIntValue(created),
        name.toCbor(),
        keyType.value.toCbor(),
      ];
}
