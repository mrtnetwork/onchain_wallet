import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/generate_master_key.dart';
import 'package:on_chain_wallet/crypto/types/sym_key.dart';

class CryptoRequestRestoreBackupMasterKey
    extends CryptoRequest<CryptoRestoreBackupMasterKeyResponse> {
  final String? passphrase;
  final List<int> backup;
  final List<int> rawKey;
  final List<int> memoryKey;
  final List<int> checksum;
  CryptoRequestRestoreBackupMasterKey(
      {required this.passphrase,
      required List<int> backup,
      required List<int> rawKey,
      required List<int> memoryKey,
      required List<int> checksum})
      : backup = backup.asImmutableBytes,
        rawKey = rawKey.asImmutableBytes,
        memoryKey = memoryKey.asImmutableBytes,
        checksum = checksum.asImmutableBytes;

  factory CryptoRequestRestoreBackupMasterKey.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: CryptoRequestMethod.createMasterKey.tag);
    return CryptoRequestRestoreBackupMasterKey(
        passphrase: values.rawValueAt(0),
        backup: values.rawValueAt(1),
        rawKey: values.rawValueAt(2),
        memoryKey: values.rawValueAt(3),
        checksum: values.rawValueAt(4));
  }

  @override
  CryptoRestoreBackupMasterKeyResponse parsResult(MessageArgsComplete result) {
    return CryptoRestoreBackupMasterKeyResponse.deserialize(object: result.result);
  }

  @override
  CryptoRequestMethod get method => CryptoRequestMethod.createMasterKey;

  @override
  Future<CryptoRestoreBackupMasterKeyResponse> result(AppContext context,
      {List<int>? encryptedPart}) async {
    final masterKey =
        WalletMasterKeys.generateFromBackup(passphrase: passphrase, bytes: backup);
    final encrypt = masterKey.$1.toEncryptedMaterKey(
        key: MemoryWalletKey.fromRawKey(rawKey: rawKey, checksum: checksum),
        memoryKey: memoryKey);
    return CryptoRestoreBackupMasterKeyResponse(
        encryptedKey: encrypt,
        masterKey: masterKey.$1,
        isValid: masterKey.$2,
        checksum: masterKey.$3);
  }

  @override
  SerializationIdentifier get serializationIdentifier => method.tag;

  @override
  List<CborObject?> get serializationItems => [
        passphrase?.toCbor(),
        CborBytesValue(backup),
        CborBytesValue(rawKey),
        CborBytesValue(memoryKey),
        CborBytesValue(checksum)
      ];
}

class CryptoRequestRestoreExternalBackupMasterKey
    extends CryptoRequest<CryptoRestoreExternalBackupMasterKeyResponse> {
  final List<int> backup;
  final List<int> rawKey;
  final List<int> memoryKey;
  final List<int> checksum;
  final SymKey key;
  CryptoRequestRestoreExternalBackupMasterKey(
      {required List<int> backup,
      required List<int> rawKey,
      required List<int> memoryKey,
      required List<int> checksum,
      required this.key})
      : backup = backup.asImmutableBytes,
        rawKey = rawKey.asImmutableBytes,
        memoryKey = memoryKey.asImmutableBytes,
        checksum = checksum.asImmutableBytes;

  factory CryptoRequestRestoreExternalBackupMasterKey.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: CryptoRequestMethod.restoreExternalMasterKey.tag);
    return CryptoRequestRestoreExternalBackupMasterKey(
        backup: values.rawValueAt(0),
        rawKey: values.rawValueAt(1),
        memoryKey: values.rawValueAt(2),
        checksum: values.rawValueAt(3),
        key: SymKey.deserialize(object: values.objectAt(4)));
  }

  @override
  CryptoRestoreExternalBackupMasterKeyResponse parsResult(MessageArgsComplete result) {
    return CryptoRestoreExternalBackupMasterKeyResponse.deserialize(
        object: result.result);
  }

  @override
  CryptoRequestMethod get method => CryptoRequestMethod.restoreExternalMasterKey;

  @override
  Future<CryptoRestoreExternalBackupMasterKeyResponse> result(AppContext context,
      {List<int>? encryptedPart}) async {
    final deserialize = WalletMasterKeysExternal.generateFromBackup(bytes: backup);
    final connectionInfo = ExternalWalletConnectionInfo.generate(
        key, deserialize.masterKey.connectionId.clientId);
    WalletMasterKeysExternal masterKey = deserialize.masterKey;
    masterKey = masterKey.copyWith(connectionId: connectionInfo);
    final encrypt = masterKey.toEncryptedMaterKey(
        key: MemoryWalletKey.fromRawKey(rawKey: rawKey, checksum: checksum),
        memoryKey: memoryKey);
    return CryptoRestoreExternalBackupMasterKeyResponse(
        encryptedKey: encrypt, masterKey: masterKey, checksum: deserialize.connectorId);
  }

  @override
  SerializationIdentifier get serializationIdentifier => method.tag;

  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(backup),
        CborBytesValue(rawKey),
        CborBytesValue(memoryKey),
        CborBytesValue(checksum),
        key.toCbor()
      ];
}
