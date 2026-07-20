import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys.dart';

final class CryptoGenerateMasterKeyResponse {
  final ViewMasterKey masterKey;
  CryptoGenerateMasterKeyResponse({
    required this.masterKey,
  });
}

final class CryptoRestoreBackupMasterKeyResponse with AppSerialization {
  final ViewMasterKey encryptedKey;
  final WalletMasterKeys masterKey;
  final List<int>? checksum;
  final bool isValid;
  CryptoRestoreBackupMasterKeyResponse({
    required this.encryptedKey,
    required this.masterKey,
    required this.isValid,
    required List<int>? checksum,
  }) : checksum = checksum?.asImmutableBytes;
  factory CryptoRestoreBackupMasterKeyResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag,
        cborBytes: bytes,
        cborObject: object);
    return CryptoRestoreBackupMasterKeyResponse(
        encryptedKey: ViewMasterKey.deserialize(object: values.objectAt(0)),
        masterKey: WalletMasterKeys.deserialize(object: values.objectAt(1)),
        checksum: values.rawValueAt(2),
        isValid: values.rawValueAt(3));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [
        encryptedKey.toCbor(),
        masterKey.toCbor(),
        AppSerialization.bytesToCbor(checksum),
        isValid.toCbor()
      ];
}

final class CryptoRestoreExternalBackupMasterKeyResponse with AppSerialization {
  final ViewExternalMasterKey encryptedKey;
  final WalletMasterKeysExternal masterKey;
  final List<int> checksum;
  CryptoRestoreExternalBackupMasterKeyResponse({
    required this.encryptedKey,
    required this.masterKey,
    required List<int> checksum,
  }) : checksum = checksum.asImmutableBytes;
  factory CryptoRestoreExternalBackupMasterKeyResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag,
        cborBytes: bytes,
        cborObject: object);
    return CryptoRestoreExternalBackupMasterKeyResponse(
        encryptedKey: ViewExternalMasterKey.deserialize(object: values.objectAt(0)),
        masterKey: WalletMasterKeysExternal.deserialize(object: values.objectAt(1)),
        checksum: values.rawValueAt(2));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [
        encryptedKey.toCbor(),
        masterKey.toCbor(),
        CborBytesValue(checksum),
      ];
}

final class CryptoImportSubWalletResponse with AppSerialization {
  final ViewMasterKey masterKey;

  final int subWalletId;
  CryptoImportSubWalletResponse({
    required this.masterKey,
    required this.subWalletId,
  });

  factory CryptoImportSubWalletResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag,
        cborBytes: bytes,
        cborObject: object);
    return CryptoImportSubWalletResponse(
        masterKey: ViewMasterKey.deserialize(object: values.objectAt(0)),
        subWalletId: values.rawValueAt(1));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [masterKey.toCbor(), subWalletId.toCbor()];
}
