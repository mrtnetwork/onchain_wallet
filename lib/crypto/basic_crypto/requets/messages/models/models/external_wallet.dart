import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys.dart';

final class ExternalWalletBackupReponse with AppSerialization {
  final List<int> encryptedWallet;
  final String connectionId;
  final List<int> sharedKey;

  ExternalWalletBackupReponse(
      {required List<int> encryptedWallet,
      required List<int> sharedKey,
      required this.connectionId})
      : encryptedWallet = encryptedWallet.asImmutableBytes,
        sharedKey = sharedKey.asImmutableBytes;
  factory ExternalWalletBackupReponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag,
        cborBytes: bytes,
        cborObject: object);
    return ExternalWalletBackupReponse(
        encryptedWallet: values.rawValueAt(0),
        sharedKey: values.rawValueAt(1),
        connectionId: values.rawValueAt(2));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(encryptedWallet), CborBytesValue(sharedKey), connectionId.toCbor()];
}

final class ImportExternalWalletResponse with AppSerialization {
  final ViewMasterKey encryptedKey;
  final ViewExternalWalletConnectionInfo connection;
  ImportExternalWalletResponse({
    required this.encryptedKey,
    required this.connection,
  });
  factory ImportExternalWalletResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag,
        cborBytes: bytes,
        cborObject: object);
    return ImportExternalWalletResponse(
        encryptedKey: ViewMasterKey.deserialize(object: values.objectAt(0)),
        connection:
            ViewExternalWalletConnectionInfo.deserialize(object: values.objectAt(1)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems =>
      [encryptedKey.toCbor(), connection.toCbor()];
}
