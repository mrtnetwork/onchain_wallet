import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/types/credential.dart';
import 'package:on_chain_wallet/app/core.dart';

final class HDWalletsConst {
  static const String initializeName = "Wallet";
  static const String initializeSubWalletName = "Sub Wallet";
  static const String firstWalletName = "$initializeName (1)";
  static const int checksumLength = 16;
  static const int defaultKeyIteration = 10;
}

final class HdWalletKey with AppSerialization, Equality {
  final int id;
  final String key;
  final String name;
  final DateTime created;
  const HdWalletKey(
      {required this.id, required this.key, required this.name, required this.created});
  factory HdWalletKey.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.hdWalletKey,
        cborBytes: bytes,
        cborObject: object);
    return HdWalletKey(
        id: values.rawValueAt(0),
        key: values.rawValueAt(1),
        name: values.rawValueAt(2),
        created: values.rawValueAt(3));
  }
  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.hdWalletKey;

  @override
  List<CborObject?> get serializationItems =>
      [id.toCbor(), key.toCbor(), name.toCbor(), created.toCbor()];

  @override
  List<dynamic> get variables => [id, key];
}

final class HDWalletsKeys with AppSerialization {
  Map<String, HdWalletKey> _wallets;
  List<HdWalletKey> get wallets => _wallets.values.toList();
  String? _currentWallet;
  bool get hasWallet => _wallets.isNotEmpty;
  bool get needSetup => _wallets.isEmpty;
  String? get currentWallet => _currentWallet;

  List<String> get walletNames => _wallets.values.map((e) => e.name).toList();
  HDWalletsKeys._({Map<String, HdWalletKey> wallets = const {}, String? currentWallet})
      : _wallets = wallets.clone(),
        _currentWallet = wallets.containsKey(currentWallet)
            ? currentWallet
            : wallets.isEmpty
                ? null
                : wallets.keys.first;
  factory HDWalletsKeys({List<HdWalletKey> wallets = const [], String? currentWallet}) {
    return HDWalletsKeys._(
        currentWallet: currentWallet,
        wallets:
            Map<String, HdWalletKey>.fromEntries(wallets.map((e) => MapEntry(e.key, e))));
  }
  factory HDWalletsKeys.deserialize({List<int>? bytes, CborObject? object}) {
    final decode = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.hdWalletKeys,
        cborBytes: bytes,
        cborObject: object);
    final keys = decode
        .listAt<CborTagValue>(0)
        .map((e) => HdWalletKey.deserialize(object: e))
        .toList();
    return HDWalletsKeys(wallets: keys, currentWallet: decode.rawValueAt(1));
  }
  HdWalletKey? _getInitializeWallet({String? key}) {
    if (_wallets.isEmpty) {
      return null;
    }
    if (_wallets.containsKey(key)) {
      return _wallets[key]!;
    }
    if (_wallets.containsKey(_currentWallet)) {
      return _wallets[_currentWallet]!;
    }
    final wallet = _wallets.values.first;
    return wallet;
  }

  HdWalletKey? getInitializeWallet({String? key}) {
    final wallet = _getInitializeWallet(key: key);
    _currentWallet = wallet?.key;
    return wallet;
  }

  IResult<void> removeWallet(IMainWallet wallet) {
    if (_wallets.containsKey(wallet.key)) {
      _wallets.remove(wallet.key);
      return ResultOk(null);
    }
    return ResultErr.fromException(WalletExceptionConst.walletDoesNotExists);
  }

  IResult<void> setupNewWallet(IMainWallet newWallet) {
    if (newWallet.data.isSetup ||
        newWallet.key.trim().isEmpty ||
        newWallet.id.isNegative ||
        _wallets.containsKey(newWallet.key) ||
        _wallets.values.any((element) => element.id == newWallet.id)) {
      return ResultErr.fromException(WalletExceptionConst.verificationWalletDataFailed);
    }

    _wallets[newWallet.key] = newWallet.tokey();
    return ResultOk(null);
  }

  String generateNewWalletChecksum() {
    String rand =
        BytesUtils.toHexString(QuickCrypto.generateRandom(HDWalletsConst.checksumLength));
    while (_wallets.containsKey("w_$rand")) {
      rand = BytesUtils.toHexString(
          QuickCrypto.generateRandom(HDWalletsConst.checksumLength));
    }
    return "w_$rand";
  }

  int generateNewWalletId() {
    int id = 0;
    final ids = _wallets.values.map((e) => e.id);
    while (ids.contains(id)) {
      id++;
    }
    return id;
  }

  MainWallet createNewMainWallet({
    required String name,
    String? connectorId,
    bool protectWallet = true,
  }) {
    final key = generateNewWalletChecksum();
    final id = generateNewWalletId();
    return MainWallet._(
        key: key,
        name: name,
        data: StorageEncryptedWallet.setup(),
        requiredPassword: false,
        locktime: WalletLockTime.fiveMinute,
        network: 0,
        created: DateTime.now(),
        protectWallet: protectWallet,
        subWallets: const [],
        id: id,
        platformCredential: null,
        importedKeys: const [],
        externalConnections: const []);
  }

  bool updateWallet(HdWalletKey key) {
    final wallet = _wallets[key.key];
    assert(wallet == key, "Invalid wallet id.");
    if (wallet == null || wallet != key) {
      return false;
    }
    if (key.name == wallet.name) {
      return false;
    }
    _wallets[key.key] = key;
    return true;
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.hdWalletKeys;

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(_wallets.values.map((e) => e.toCbor()).toList()),
        currentWallet?.toCbor()
      ];
}

enum IWalletType {
  main,
  external;

  bool get isExternal => this == external;
}

sealed class IMainWallet<KEY extends IViewMasterKey> with AppSerialization, Equality {
  final int id;
  final String key;
  final String name;
  final StorageEncryptedWallet data;
  final bool requiredPassword;
  final bool protectWallet;
  final WalletLockTime locktime;
  final int network;
  final DateTime created;
  final List<ViewSubWalletKey> subWallets;
  final List<ViewImportedSecretKey> importedKeys;
  final WalletPlatformCredential? platformCredential;
  final List<int> checkSumBytes;
  IWalletType get type;
  IMainWallet({
    required this.id,
    required this.key,
    required this.name,
    required this.data,
    required this.requiredPassword,
    required this.protectWallet,
    required this.locktime,
    required this.network,
    required this.created,
    required List<ViewSubWalletKey> subWallets,
    required List<ViewImportedSecretKey> importedKeys,
    this.platformCredential,
  })  : subWallets = subWallets.immutable,
        importedKeys = importedKeys.immutable,
        checkSumBytes = StringUtils.encode(key);
  bool hasSubwallet(int id) {
    return subWallets.any((e) => e.id == id);
  }

  HdWalletKey tokey() => HdWalletKey(id: id, key: key, name: name, created: created);
  ViewSubWalletKey? getSubWallet(int subId) {
    return subWallets.firstWhereOrNull((e) => e.id == subId);
  }

  ViewImportedSecretKey? getImportedKey(int id) {
    return importedKeys.firstWhereOrNull((e) => e.id == id);
  }

  IMainWallet<KEY> fromViewKey(KEY masterKey);
  IMainWallet<KEY> updateKey(String key);
  IMainWallet<KEY> updateId(int id);
  IMainWallet<KEY> updateNetwork(int updateNetworkId);
  IMainWallet<KEY> updateSettings({required WalletUpdateInfosData update, int? network});

  factory IMainWallet.deserialize({List<int>? bytes, CborObject? object}) {
    final decode = AppSerialization.decodeTaggedValueWithInfo(
        cborBytes: bytes,
        cborObject: object,
        expectedTags: [
          AppSerializationIdentifier.wallet,
          AppSerializationIdentifier.externalWallet
        ]);
    final IMainWallet w = switch (decode.identifier) {
      AppSerializationIdentifier.wallet => MainWallet.deserialize(object: decode.tag),
      AppSerializationIdentifier.externalWallet =>
        ExternalWallet.deserialize(object: decode.tag),
      _ => throw AppInternalError.internalError("IMainWallet")
    };
    return w.cast();
  }

  T cast<T>() {
    if (this is! T) {
      throw AppInternalError.internalError("IMainWallet");
    }
    return this as T;
  }
}

final class MainWallet extends IMainWallet<ViewMasterKey> {
  final List<ViewExternalWalletConnectionInfo> externalConnections;
  MainWallet.__(
      {required super.id,
      required super.key,
      required super.name,
      required super.data,
      required super.requiredPassword,
      required super.locktime,
      required super.network,
      required super.created,
      required super.protectWallet,
      required super.subWallets,
      required super.importedKeys,
      required super.platformCredential,
      required List<ViewExternalWalletConnectionInfo> externalConnections})
      : externalConnections = externalConnections.immutable;

  factory MainWallet._({
    required String key,
    required String name,
    required StorageEncryptedWallet data,
    required bool requiredPassword,
    required WalletLockTime locktime,
    required int network,
    required int id,
    required WalletPlatformCredential? platformCredential,
    required List<ViewImportedSecretKey> importedKeys,
    required List<ViewSubWalletKey> subWallets,
    bool protectWallet = true,
    DateTime? created,
    required List<ViewExternalWalletConnectionInfo> externalConnections,
  }) {
    return MainWallet.__(
        key: key,
        name: name,
        data: data,
        requiredPassword: requiredPassword,
        locktime: locktime,
        network: network,
        created: created ?? DateTime.now(),
        protectWallet: protectWallet,
        subWallets: subWallets,
        id: id,
        platformCredential: platformCredential,
        importedKeys: importedKeys,
        externalConnections: externalConnections);
  }

  factory MainWallet.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.wallet);
    final int setting = values.rawValueAt(5);
    final int network = values.rawValueAt(4);
    WalletLockTime lockTime = WalletLockTime.fromValue(setting);
    return MainWallet._(
        key: values.rawValueAt(0),
        name: values.rawValueAt(1),
        data: StorageEncryptedWallet.deserialize(object: values.objectAt(2)),
        requiredPassword: values.rawValueAt(3),
        network: network,
        locktime: lockTime,
        created: values.rawValueAt<DateTime>(6),
        protectWallet: values.rawValueAt<bool?>(7) ?? true,
        subWallets: [],
        id: values.rawValueAt(9),
        platformCredential: values.maybeObjectAt<WalletPlatformCredential, CborTagValue>(
            10, (e) => WalletPlatformCredential.deserialize(object: e)),
        importedKeys: [],
        externalConnections: values
            .listAt<CborObject>(11, emptyOnNull: true)
            .map((e) => ViewExternalWalletConnectionInfo.deserialize(object: e))
            .toList());
  }

  factory MainWallet.fromBackup({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.wallet);
    return MainWallet.__(
        id: -1,
        key: '',
        name: values.rawValueAt(0),
        data: StorageEncryptedWallet.setup(),
        requiredPassword: values.rawValueAt(1),
        locktime: WalletLockTime.fromValue(values.rawValueAt(3)),
        network: values.rawValueAt(2),
        created: values.rawValueAt(4),
        protectWallet: values.rawValueAt(5),
        subWallets: [],
        platformCredential: null,
        importedKeys: [],
        externalConnections: []);
  }

  @override
  MainWallet fromViewKey(ViewMasterKey updateData) {
    return MainWallet._(
        key: key,
        name: name,
        data: updateData.storageData,
        requiredPassword: requiredPassword,
        network: network,
        locktime: locktime,
        created: created,
        protectWallet: protectWallet,
        subWallets: updateData.subWallets.clone()
          ..sort((a, b) => b.created.compareTo(a.created)),
        id: id,
        platformCredential: platformCredential,
        importedKeys: updateData.customKeys.clone()
          ..sort((a, b) => b.created.compareTo(a.created)),
        externalConnections: updateData.externalConnectors);
  }

  @override
  MainWallet updateKey(String key) {
    assert(this.key.isEmpty, "wallet key already updated.");
    return MainWallet._(
        key: key,
        name: name,
        data: data,
        requiredPassword: requiredPassword,
        network: network,
        locktime: locktime,
        created: created,
        protectWallet: protectWallet,
        subWallets: subWallets,
        id: id,
        platformCredential: platformCredential,
        importedKeys: importedKeys,
        externalConnections: externalConnections);
  }

  @override
  MainWallet updateId(int id) {
    assert(this.id.isNegative, "wallet id already updated.");
    return MainWallet._(
        key: key,
        name: name,
        data: data,
        requiredPassword: requiredPassword,
        network: network,
        locktime: locktime,
        created: created,
        protectWallet: protectWallet,
        subWallets: subWallets,
        id: id,
        platformCredential: platformCredential,
        importedKeys: importedKeys,
        externalConnections: externalConnections);
  }

  @override
  MainWallet updateNetwork(int updateNetworkId) {
    return MainWallet._(
        key: key,
        name: name,
        data: data,
        requiredPassword: requiredPassword,
        network: updateNetworkId,
        locktime: locktime,
        created: created,
        protectWallet: protectWallet,
        subWallets: subWallets,
        id: id,
        platformCredential: platformCredential,
        importedKeys: importedKeys,
        externalConnections: externalConnections);
  }

  @override
  MainWallet updateSettings({required WalletUpdateInfosData update, int? network}) {
    return MainWallet._(
        key: key,
        name: update.name,
        data: data,
        requiredPassword: update.requirmentPassword,
        network: network ?? this.network,
        locktime: update.lockTime,
        created: created,
        protectWallet: update.protectWallet,
        subWallets: subWallets,
        id: id,
        platformCredential: update.platformCredential,
        importedKeys: importedKeys,
        externalConnections: externalConnections);
  }

  CborTagValue toBackup() {
    return CborTagValue(
        AppSerialization.listFromObjects([
          name.toCbor(),
          CborBoleanValue(requiredPassword),
          network.toCbor(),
          locktime.value.toCbor(),
          CborEpochIntValue(created),
          protectWallet.toCbor(),
          CborNullValue(),
        ]),
        AppSerializationIdentifier.wallet.tags());
  }

  ExternalWallet toExternalWallet(ViewExternalWalletConnectionInfo connection) {
    return ExternalWallet._(
        key: key,
        name: name,
        data: data,
        requiredPassword: requiredPassword,
        locktime: locktime,
        network: network,
        id: id,
        platformCredential: platformCredential,
        importedKeys: importedKeys,
        subWallets: subWallets,
        connection: connection,
        created: created,
        protectWallet: protectWallet);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.wallet;

  @override
  List<CborObject?> get serializationItems => [
        key.toCbor(),
        name.toCbor(),
        data.toCbor(),
        CborBoleanValue(requiredPassword),
        network.toCbor(),
        locktime.value.toCbor(),
        CborEpochIntValue(created),
        protectWallet.toCbor(),
        CborNullValue(),
        id.toCbor(),
        platformCredential?.toCbor(),
        AppSerialization.listFromObjects(
            externalConnections.map((e) => e.toCbor()).toList())
      ];

  @override
  List<dynamic> get variables => [
        id,
        key,
        name,
        data,
        requiredPassword,
        network,
        locktime,
        created,
        protectWallet,
        id,
        platformCredential,
        importedKeys,
        subWallets,
        externalConnections
      ];

  @override
  IWalletType get type => IWalletType.main;
}

final class ExternalWallet extends IMainWallet<ViewExternalMasterKey> {
  final ViewExternalWalletConnectionInfo connection;
  ExternalWallet.__(
      {required super.id,
      required super.key,
      required super.name,
      required super.data,
      required super.requiredPassword,
      required super.locktime,
      required super.network,
      required super.created,
      required super.protectWallet,
      required super.subWallets,
      required super.importedKeys,
      required super.platformCredential,
      required this.connection});

  factory ExternalWallet._({
    required String key,
    required String name,
    required StorageEncryptedWallet data,
    required bool requiredPassword,
    required WalletLockTime locktime,
    required int network,
    required int id,
    required WalletPlatformCredential? platformCredential,
    required List<ViewImportedSecretKey> importedKeys,
    required List<ViewSubWalletKey> subWallets,
    required ViewExternalWalletConnectionInfo connection,
    bool protectWallet = true,
    DateTime? created,
  }) {
    return ExternalWallet.__(
        key: key,
        name: name,
        data: data,
        requiredPassword: requiredPassword,
        locktime: locktime,
        network: network,
        created: created ?? DateTime.now(),
        protectWallet: protectWallet,
        subWallets: subWallets,
        id: id,
        platformCredential: platformCredential,
        importedKeys: importedKeys,
        connection: connection);
  }

  factory ExternalWallet.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.externalWallet);
    final int setting = values.rawValueAt(5);
    final int network = values.rawValueAt(4);
    WalletLockTime lockTime = WalletLockTime.fromValue(setting);
    return ExternalWallet._(
        key: values.rawValueAt(0),
        name: values.rawValueAt(1),
        data: StorageEncryptedWallet.deserialize(object: values.objectAt(2)),
        requiredPassword: values.rawValueAt(3),
        network: network,
        locktime: lockTime,
        created: values.rawValueAt<DateTime>(6),
        protectWallet: values.rawValueAt<bool?>(7) ?? true,
        subWallets: [],
        id: values.rawValueAt(9),
        platformCredential: values.maybeObjectAt<WalletPlatformCredential, CborTagValue>(
            10, (e) => WalletPlatformCredential.deserialize(object: e)),
        importedKeys: [],
        connection:
            ViewExternalWalletConnectionInfo.deserialize(object: values.objectAt(11)));
  }

  // factory ExternalWallet.fromBackup({List<int>? bytes, CborObject? object}) {
  //   final CborListValue values = AppSerialization.decodeTaggedValue(
  //       cborBytes: bytes,
  //       cborObject: object,
  //       identifier: AppSerializationIdentifier.externalWallet);
  //   return ExternalWallet.__(
  //       id: -1,
  //       key: '',
  //       name: values.rawValueAt(0),
  //       data: '',
  //       requiredPassword: values.rawValueAt(1),
  //       locktime: WalletLockTime.fromValue(values.rawValueAt(3)),
  //       network: values.rawValueAt(2),
  //       created: values.rawValueAt(4),
  //       protectWallet: values.rawValueAt(5),
  //       subWallets: [],
  //       platformCredential: null,
  //       importedKeys: [],
  //       connection:
  //           ViewExternalWalletConnectionInfo.deserialize(object: values.objectAt(6)));
  // }

  @override
  ExternalWallet fromViewKey(ViewExternalMasterKey updateData) {
    return ExternalWallet._(
        key: key,
        name: name,
        data: updateData.storageData,
        requiredPassword: requiredPassword,
        network: network,
        locktime: locktime,
        created: created,
        protectWallet: protectWallet,
        subWallets: updateData.subWallets,
        id: id,
        platformCredential: platformCredential,
        importedKeys: updateData.customKeys,
        connection: updateData.connectionInfo);
  }

  @override
  ExternalWallet updateKey(String key) {
    assert(this.key.isEmpty, "wallet key already updated.");
    return ExternalWallet._(
        key: key,
        name: name,
        data: data,
        requiredPassword: requiredPassword,
        network: network,
        locktime: locktime,
        created: created,
        protectWallet: protectWallet,
        subWallets: subWallets,
        id: id,
        platformCredential: platformCredential,
        importedKeys: importedKeys,
        connection: connection);
  }

  @override
  ExternalWallet updateId(int id) {
    assert(this.id.isNegative, "wallet id already updated.");
    return ExternalWallet._(
        key: key,
        name: name,
        data: data,
        requiredPassword: requiredPassword,
        network: network,
        locktime: locktime,
        created: created,
        protectWallet: protectWallet,
        subWallets: subWallets,
        id: id,
        platformCredential: platformCredential,
        importedKeys: importedKeys,
        connection: connection);
  }

  @override
  ExternalWallet updateNetwork(int updateNetworkId) {
    return ExternalWallet._(
        key: key,
        name: name,
        data: data,
        requiredPassword: requiredPassword,
        network: updateNetworkId,
        locktime: locktime,
        created: created,
        protectWallet: protectWallet,
        subWallets: subWallets,
        id: id,
        platformCredential: platformCredential,
        importedKeys: importedKeys,
        connection: connection);
  }

  @override
  ExternalWallet updateSettings({required WalletUpdateInfosData update, int? network}) {
    return ExternalWallet._(
        key: key,
        name: update.name,
        data: data,
        requiredPassword: update.requirmentPassword,
        network: network ?? this.network,
        locktime: update.lockTime,
        created: created,
        protectWallet: update.protectWallet,
        subWallets: subWallets,
        id: id,
        platformCredential: update.platformCredential,
        importedKeys: importedKeys,
        connection: connection);
  }

  CborTagValue toBackup() {
    return CborTagValue(
        AppSerialization.listFromObjects([
          name.toCbor(),
          CborBoleanValue(requiredPassword),
          network.toCbor(),
          locktime.value.toCbor(),
          CborEpochIntValue(created),
          protectWallet.toCbor(),
          connection.toCbor(),
        ]),
        AppSerializationIdentifier.externalWallet.tags());
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.externalWallet;

  @override
  List<CborObject?> get serializationItems => [
        key.toCbor(),
        name.toCbor(),
        data.toCbor(),
        CborBoleanValue(requiredPassword),
        network.toCbor(),
        locktime.value.toCbor(),
        CborEpochIntValue(created),
        protectWallet.toCbor(),
        CborNullValue(),
        id.toCbor(),
        platformCredential?.toCbor(),
        connection.toCbor()
      ];

  @override
  List<dynamic> get variables => [
        id,
        key,
        name,
        data,
        requiredPassword,
        network,
        locktime,
        created,
        protectWallet,
        id,
        platformCredential,
        importedKeys,
        subWallets,
        connection
      ];

  @override
  IWalletType get type => IWalletType.external;
}

enum WalletLockTime {
  twoMinute(120, "two_minute"),
  fiveMinute(300, "five_minute"),
  tenMinute(600, "ten_minute"),
  thirtyMinute(1800, "thirty_minute");

  final int value;
  final String viewName;
  const WalletLockTime(this.value, this.viewName);
  static WalletLockTime fromValue(int value) {
    if (value == 0) {
      return WalletLockTime.fiveMinute;
    }
    return values.firstWhere((element) => element.value == value,
        orElse: () => WalletLockTime.fiveMinute);
  }
}

final class WalletUpdateInfosData {
  final String name;
  final WalletLockTime lockTime;
  final bool requirmentPassword;
  final bool protectWallet;
  final WalletPlatformCredential? platformCredential;
  const WalletUpdateInfosData(
      {required this.name,
      required this.lockTime,
      required this.requirmentPassword,
      required this.protectWallet,
      required this.platformCredential});
}
