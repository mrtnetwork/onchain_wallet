import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

class ExternalWalletBackupResponse with AppSerialization {
  final String backup;
  final ViewExternalWalletConnectionInfo session;
  const ExternalWalletBackupResponse({required this.backup, required this.session});
  factory ExternalWalletBackupResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag,
        cborBytes: bytes,
        cborObject: object);
    return ExternalWalletBackupResponse(
        backup: values.rawValueAt(0),
        session:
            ViewExternalWalletConnectionInfo.deserialize(object: values.objectAt(1)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [backup.toCbor(), session.toCbor()];
}

class DecryptExternalWalletBackupResponse with AppSerialization {
  final List<int> encodedWallet;
  final ViewExternalWalletConnectionInfo session;
  const DecryptExternalWalletBackupResponse(
      {required this.encodedWallet, required this.session});
  factory DecryptExternalWalletBackupResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag,
        cborBytes: bytes,
        cborObject: object);
    return DecryptExternalWalletBackupResponse(
        encodedWallet: values.rawValueAt(0),
        session:
            ViewExternalWalletConnectionInfo.deserialize(object: values.objectAt(1)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(encodedWallet), session.toCbor()];
}
