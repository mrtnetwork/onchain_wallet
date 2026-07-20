import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/hd_wallet.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/models/authenticated.dart';
import 'package:on_chain_wallet/app/core.dart';

enum WalletBackupTypes {
  walletV3(AppSerializationIdentifier.walletBackupWalletV3),
  externalWallet(AppSerializationIdentifier.externalWalletBackup),
  mnemonic(AppSerializationIdentifier.walletBackupMnemonic),
  privatekey(AppSerializationIdentifier.walletBackupPrivateKey),
  ufsk(AppSerializationIdentifier.walletBackupUfsk),
  orchardSpendKey(AppSerializationIdentifier.walletBackupOrchardSpendKey),
  saplingExtendedSpandingKey(
      AppSerializationIdentifier.walletBackupSaplingExtendedSpendKey),
  saplingSpendKey(AppSerializationIdentifier.walletBackupSaplingSpendKey),
  wif(AppSerializationIdentifier.walletBackupWif),
  keystore(AppSerializationIdentifier.runtimeTag),
  extendedKey(AppSerializationIdentifier.walletBackupExtendedKey);

  bool get isWalletBackup => this == walletV3;
  final AppSerializationIdentifier tag;
  const WalletBackupTypes(this.tag);

  static WalletBackupTypes fromValue(List<int> tags) {
    return values.firstWhere((e) => e.tag.isValidTags(tags));
  }

  SecretWalletEncoding get encoding {
    switch (this) {
      case WalletBackupTypes.keystore:
        return SecretWalletEncoding.json;
      default:
        return SecretWalletEncoding.cbor;
    }
  }

  bool get isPrivateKey =>
      this == WalletBackupTypes.privatekey || this == WalletBackupTypes.keystore;

  List<int> toEncryptionBytes(String data) {
    switch (this) {
      case WalletBackupTypes.saplingExtendedSpandingKey:
      case WalletBackupTypes.mnemonic:
        return StringUtils.encode(data);
      case WalletBackupTypes.keystore:
      case WalletBackupTypes.privatekey:
      case WalletBackupTypes.walletV3:
      case WalletBackupTypes.externalWallet:
      case WalletBackupTypes.ufsk:
      case WalletBackupTypes.orchardSpendKey:
      case WalletBackupTypes.saplingSpendKey:
        return BytesUtils.fromHexString(data);
      default:
        return Base58Decoder.checkDecode(data);
    }
  }

  String fromDecyrptBytes(List<int> decryptedKeyBytes) {
    switch (this) {
      case WalletBackupTypes.saplingExtendedSpandingKey:
      case WalletBackupTypes.mnemonic:
        return StringUtils.decode(decryptedKeyBytes);
      case WalletBackupTypes.privatekey:
      case WalletBackupTypes.walletV3:
      case WalletBackupTypes.externalWallet:
      case WalletBackupTypes.keystore:
      case WalletBackupTypes.ufsk:
      case WalletBackupTypes.orchardSpendKey:
      case WalletBackupTypes.saplingSpendKey:
        return BytesUtils.toHexString(decryptedKeyBytes);

      default:
        return Base58Encoder.checkEncode(decryptedKeyBytes);
    }
  }
}

abstract final class WalletBackupCore {
  abstract final WalletBackupTypes type;
  abstract final DateTime created;
  abstract final String key;
  abstract final bool isEncrypted;
  factory WalletBackupCore.deserialize({List<int>? bytes, CborObject? object}) {
    final CborTagValue tag = AppSerialization.decode(
      cborBytes: bytes,
      cborObject: object,
    );

    final type = WalletBackupTypes.fromValue(tag.tags);
    switch (type) {
      case WalletBackupTypes.walletV3:
        return WalletBackup.deserialize(object: tag);
      case WalletBackupTypes.externalWallet:
        return ExternalWalletBackup.deserialize(object: tag);
      default:
        return WalletKeyBackup.deserialize(object: tag);
    }
  }
  WalletBackupCore decrypt(List<int> decryptedKey);
}

final class WalletBackupNetworkRepository with AppSerialization {
  final List<int> value;
  final int storageID;
  final int networkID;
  final int? createdAt;
  final String? identifier;
  final String? identifier2;

  const WalletBackupNetworkRepository._(
      {required this.storageID,
      required this.identifier,
      required this.value,
      required this.networkID,
      required this.identifier2,
      required this.createdAt});
  factory WalletBackupNetworkRepository(
      {required int storageID,
      required String? identifier,
      required String? identifier2,
      required List<int> value,
      required int networkID,
      required int? createdAt}) {
    return WalletBackupNetworkRepository._(
        storageID: storageID,
        identifier: identifier,
        value: value,
        networkID: networkID,
        identifier2: identifier2,
        createdAt: createdAt);
  }
  factory WalletBackupNetworkRepository.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.walletBackupNetworkStorageIds);

    return WalletBackupNetworkRepository(
        value: values.rawValueAt(0),
        storageID: values.rawValueAt(1),
        identifier: values.rawValueAt(2),
        identifier2: values.rawValueAt(3),
        networkID: values.rawValueAt(4),
        createdAt: values.rawValueAt(5));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.walletBackupNetworkStorageIds;

  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(value),
        storageID.toCbor(),
        identifier?.toCbor(),
        identifier2?.toCbor(),
        networkID.toCbor(),
        createdAt?.toCbor(),
      ];
}

final class WalletNetworkBackup with AppSerialization {
  final WalletNetwork network;
  final List<ChainAccount> addresses;
  final List<WalletBackupNetworkRepository> repositories;
  WalletNetworkBackup._(
      {required this.network,
      required List<ChainAccount> addresses,
      List<WalletBackupNetworkRepository> repositories = const []})
      : repositories = repositories.immutable,
        addresses = addresses.immutable;
  factory WalletNetworkBackup(
      {required WalletNetwork network,
      required List<ChainAccount> addresses,
      required List<WalletBackupNetworkRepository> repositories}) {
    return WalletNetworkBackup._(
        network: network, addresses: addresses, repositories: repositories);
  }
  factory WalletNetworkBackup.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.walletBackupChains);
    final network = WalletNetwork.deserialize(object: values.objectAt(0));
    return WalletNetworkBackup(
        network: network,
        addresses: values
            .listAt<CborTagValue>(1)
            .map((e) => ChainAccount.deserialize(
                network: network, id: null, obj: e, database: null))
            .toList(),
        repositories: values
            .listAt<CborTagValue>(2)
            .map((e) => WalletBackupNetworkRepository.deserialize(object: e))
            .toList());
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.walletBackupChains;

  @override
  List<CborObject?> get serializationItems => [
        network.toCbor(),
        AppSerialization.listFromObjects(addresses.map((e) => e.toCbor()).toList()),
        AppSerialization.listFromObjects(repositories.map((e) => e.toCbor()).toList())
      ];
}

final class WalletBackupChainRepository with AppSerialization {
  final List<int> value;
  final int storageID;
  final int chainID;
  final int? createdAt;
  final String? identifier;
  final String? identifier2;

  const WalletBackupChainRepository._(
      {required this.storageID,
      required this.identifier,
      required this.value,
      required this.chainID,
      required this.identifier2,
      required this.createdAt});
  factory WalletBackupChainRepository(
      {required int storageID,
      required String? identifier,
      required String? identifier2,
      required List<int> value,
      required int chainID,
      required int? createdAt}) {
    return WalletBackupChainRepository._(
        storageID: storageID,
        identifier: identifier,
        value: value,
        chainID: chainID,
        identifier2: identifier2,
        createdAt: createdAt);
  }
  factory WalletBackupChainRepository.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.walletBackupChainStorageIds);

    return WalletBackupChainRepository(
        value: values.rawValueAt(0),
        storageID: values.rawValueAt(1),
        identifier: values.rawValueAt(2),
        identifier2: values.rawValueAt(3),
        chainID: values.rawValueAt(4),
        createdAt: values.rawValueAt(5));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.walletBackupChainStorageIds;

  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(value),
        storageID.toCbor(),
        identifier?.toCbor(),
        identifier2?.toCbor(),
        chainID.toCbor(),
        createdAt?.toCbor(),
      ];
}

final class WalletBackup implements WalletBackupCore {
  final MainWallet wallet;
  final List<WalletNetworkBackup> networks;
  final List<Web3ApplicationAuthentication> dapps;
  final List<WalletBackupChainRepository> chains;
  final List<int>? checksum;
  WalletBackup._({
    required this.key,
    required List<WalletNetworkBackup> networks,
    required List<WalletBackupChainRepository> chains,
    required this.wallet,
    List<Web3ApplicationAuthentication> dapps = const [],
    DateTime? created,
    this.isEncrypted = true,
    List<int>? checksum,
  })  : networks = networks.immutable,
        created = created ?? DateTime.now(),
        dapps = dapps.immutable,
        chains = chains.immutable,
        checksum = checksum?.asImmutableBytes;
  factory WalletBackup(
      {required String key,
      required MainWallet wallet,
      required List<WalletNetworkBackup> networks,
      required List<WalletBackupChainRepository> chains,
      List<Web3ApplicationAuthentication> dapps = const [],
      DateTime? created}) {
    return WalletBackup._(
        key: key,
        networks: networks,
        created: created,
        dapps: dapps,
        chains: chains,
        wallet: wallet);
  }
  factory WalletBackup.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: WalletBackupTypes.walletV3.tag);
    return WalletBackup._(
        key: values.rawValueAt(0),
        networks: values
            .listAt<CborTagValue>(1)
            .map((e) => WalletNetworkBackup.deserialize(object: e))
            .toList(),
        created: values.rawValueAt(2),
        dapps: values
            .listAt<CborTagValue>(3, emptyOnNull: true)
            .map((e) => Web3ApplicationAuthentication.deserialize(object: e))
            .toList(),
        chains: values
            .listAt<CborTagValue>(4, emptyOnNull: true)
            .map((e) => WalletBackupChainRepository.deserialize(object: e))
            .toList(),
        checksum: values.rawValueAt(5),
        wallet: MainWallet.fromBackup(object: values.objectAt<CborTagValue>(6)));
  }

  @override
  final String key;

  @override
  final DateTime created;

  CborTagValue toCbor(List<int> checksum) {
    return CborTagValue(
        CborListValue<CborObject>.definite([
          CborStringValue(key),
          CborListValue.definite(networks.map((e) => e.toCbor()).toList()),
          CborEpochIntValue(created),
          CborListValue.definite(dapps.map((e) => e.toCbor()).toList()),
          CborListValue.definite(chains.map((e) => e.toCbor()).toList()),
          CborBytesValue(checksum),
          wallet.toBackup()
        ]),
        type.tag.tags());
  }

  @override
  WalletBackupTypes get type => WalletBackupTypes.walletV3;

  @override
  final bool isEncrypted;

  @override
  WalletBackup decrypt(List<int> decryptedKeyBytes) {
    return WalletBackup._(
        key: type.fromDecyrptBytes(decryptedKeyBytes),
        created: created,
        isEncrypted: false,
        networks: networks,
        dapps: dapps,
        chains: chains,
        checksum: checksum,
        wallet: wallet);
  }
}

final class SubWalletBackupData with AppSerialization {
  final String name;
  final int id;
  const SubWalletBackupData({required this.name, required this.id});
  factory SubWalletBackupData.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.walletBackupSubWalletInfos);
    return SubWalletBackupData(name: values.rawValueAt(0), id: values.rawValueAt(1));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.walletBackupSubWalletInfos;

  @override
  List<CborObject?> get serializationItems => [CborStringValue(name), CborIntValue(id)];
}

final class WalletKeyBackup with AppSerialization implements WalletBackupCore {
  WalletKeyBackup._(
      {required this.key,
      required this.type,
      required this.created,
      this.isEncrypted = true});
  factory WalletKeyBackup(
      {required String key, required WalletBackupTypes type, DateTime? created}) {
    switch (type) {
      case WalletBackupTypes.keystore:
      case WalletBackupTypes.walletV3:
        throw WalletExceptionConst.invalidBackupOptions;
      default:
        break;
    }
    return WalletKeyBackup._(key: key, type: type, created: created ?? DateTime.now());
  }
  factory WalletKeyBackup.deserialize({List<int>? bytes, CborObject? object}) {
    final CborTagValue tag = AppSerialization.decode(
      cborBytes: bytes,
      cborObject: object,
    );
    final CborListValue values =
        AppSerialization.decodeTaggedValue(cborObject: tag, identifier: null);
    return WalletKeyBackup(
        key: values.rawValueAt(0),
        created: values.rawValueAt(1),
        type: WalletBackupTypes.fromValue(tag.tags));
  }

  @override
  final String key;
  @override
  final DateTime created;

  @override
  final WalletBackupTypes type;

  @override
  final bool isEncrypted;

  @override
  WalletBackupCore decrypt(List<int> decryptedKeyBytes) {
    return WalletKeyBackup._(
      key: type.fromDecyrptBytes(decryptedKeyBytes),
      type: type,
      created: created,
      isEncrypted: false,
    );
  }

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;

  @override
  List<CborObject?> get serializationItems =>
      [CborStringValue(key), CborEpochIntValue(created)];
}

final class GenerateWalletBackupOptions {
  final List<Chain> chains;
  final bool backupDapps;
  final String? passphrase;
  final String? newPassword;
  GenerateWalletBackupOptions(
      {required List<Chain> chains,
      required this.backupDapps,
      required this.passphrase,
      required this.newPassword})
      : chains = chains.immutable;
}

final class ExternalWalletBackup implements WalletBackupCore {
  final MainWallet wallet;
  final List<WalletNetworkBackup> networks;
  final List<Web3ApplicationAuthentication> dapps;
  final List<WalletBackupChainRepository> chains;
  final List<int>? checksum;
  @override
  final String key;
  @override
  final DateTime created;
  @override
  final bool isEncrypted;
  ExternalWalletBackup._({
    required this.key,
    required List<WalletNetworkBackup> networks,
    required List<WalletBackupChainRepository> chains,
    required this.wallet,
    List<Web3ApplicationAuthentication> dapps = const [],
    DateTime? created,
    this.isEncrypted = true,
    List<int>? checksum,
  })  : networks = networks.immutable,
        created = created ?? DateTime.now(),
        dapps = dapps.immutable,
        chains = chains.immutable,
        checksum = checksum?.asImmutableBytes;
  factory ExternalWalletBackup(
      {required String key,
      required MainWallet wallet,
      required List<WalletNetworkBackup> networks,
      required List<WalletBackupChainRepository> chains,
      List<Web3ApplicationAuthentication> dapps = const [],
      DateTime? created}) {
    return ExternalWalletBackup._(
        key: key,
        networks: networks,
        created: created,
        dapps: dapps,
        chains: chains,
        wallet: wallet);
  }
  factory ExternalWalletBackup.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletBackupTypes.externalWallet.tag);
    return ExternalWalletBackup._(
        key: values.rawValueAt(0),
        networks: values
            .listAt<CborTagValue>(1)
            .map((e) => WalletNetworkBackup.deserialize(object: e))
            .toList(),
        created: values.rawValueAt(2),
        dapps: values
            .listAt<CborTagValue>(3)
            .map((e) => Web3ApplicationAuthentication.deserialize(object: e))
            .toList(),
        chains: values
            .listAt<CborTagValue>(4)
            .map((e) => WalletBackupChainRepository.deserialize(object: e))
            .toList(),
        checksum: values.rawValueAt(5),
        wallet: MainWallet.fromBackup(object: values.objectAt<CborTagValue>(6)));
  }

  CborTagValue toCbor({List<int>? checksum}) {
    return CborTagValue(
        CborListValue<CborObject>.definite([
          CborStringValue(key),
          CborListValue.definite(networks.map((e) => e.toCbor()).toList()),
          CborEpochIntValue(created),
          CborListValue.definite(dapps.map((e) => e.toCbor()).toList()),
          CborListValue.definite(chains.map((e) => e.toCbor()).toList()),
          AppSerialization.bytesToCbor(checksum),
          wallet.toBackup()
        ]),
        type.tag.tags());
  }

  @override
  WalletBackupTypes get type => WalletBackupTypes.externalWallet;

  @override
  ExternalWalletBackup decrypt(List<int> decryptedKeyBytes) {
    return ExternalWalletBackup._(
        key: type.fromDecyrptBytes(decryptedKeyBytes),
        created: created,
        isEncrypted: false,
        networks: networks,
        dapps: dapps,
        chains: chains,
        checksum: checksum,
        wallet: wallet);
  }
}

final class BackupChain {
  final WalletNetwork network;
  final List<ChainAccount> addresses;
  final List<WalletBackupNetworkRepository> repositories;
  BackupChain({
    required this.network,
    required List<ChainAccount> addresses,
    required List<WalletBackupNetworkRepository> repositories,
  })  : addresses = addresses.immutable,
        repositories = repositories.immutable;

  CborTagValue toChainCbor(String id) {
    return CborTagValue(
        AppSerialization.listFromObjects(
            [network.value.toCbor(), network.toCbor(), id.toCbor()]),
        AppSerializationIdentifier.iAccount.tags());
  }
}

sealed class VerifiedWalletBackup<ENC extends IViewMasterKey,
    MK extends IWalletMasterKeys<ENC>, W extends IMainWallet<ENC>> {
  final MK masterKeys;
  final List<BackupChain> networks;
  final List<Web3ApplicationAuthentication> dapps;
  final List<WalletBackupChainRepository> chains;
  final W wallet;
  VerifiedWalletBackup({
    required this.masterKeys,
    required this.wallet,
    required List<BackupChain> networks,
    required List<Web3ApplicationAuthentication> dapps,
    required List<WalletBackupChainRepository> chains,
  })  : networks = networks.immutable,
        dapps = dapps.immutable,
        chains = chains.immutable;
}

final class VerifiedExternalWalletBackup extends VerifiedWalletBackup<
    ViewExternalMasterKey, WalletMasterKeysExternal, ExternalWallet> {
  final List<int> checksum;
  VerifiedExternalWalletBackup({
    required super.masterKeys,
    required super.wallet,
    required super.networks,
    required super.dapps,
    required super.chains,
    required List<int> checksum,
  }) : checksum = checksum.asImmutableBytes;
}

final class VerifiedMainWalletBackup
    extends VerifiedWalletBackup<ViewMasterKey, WalletMasterKeys, MainWallet> {
  final List<ChainAccount> invalidAddresses;
  final bool verifiedChecksum;
  final int totalAccounts;
  bool get hasFailedAccount => invalidAddresses.isNotEmpty;
  VerifiedMainWalletBackup({
    required super.masterKeys,
    required super.networks,
    required List<ChainAccount> invalidAddresses,
    required super.dapps,
    required super.chains,
    required super.wallet,
    required this.verifiedChecksum,
  })  : invalidAddresses = invalidAddresses.immutable,
        totalAccounts =
            networks.fold(0, (p, c) => p + c.addresses.length) + invalidAddresses.length;
}
