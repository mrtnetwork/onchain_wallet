import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/external_backup.dart';
import 'package:on_chain_wallet/crypto/types/sym_key.dart';
import 'package:on_chain_wallet/app/core.dart';

class CryptoRequestDecodeBackup extends CryptoRequest<AppSerializationBinary> {
  final String password;
  final String backup;
  final SecretWalletEncoding encoding;
  CryptoRequestDecodeBackup(
      {required this.password, required this.backup, required this.encoding});
  factory CryptoRequestDecodeBackup.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: CryptoRequestMethod.decodeBackup.tag);
    final encoding = SecretWalletEncoding.values.firstWhere(
        (element) => element.name == values.rawValueAt<String>(2),
        orElse: () => throw AppInternalError.internalError(
            "CryptoRequestDecodeBackup.deserialize"));
    return CryptoRequestDecodeBackup(
        password: values.rawValueAt(0), backup: values.rawValueAt(1), encoding: encoding);
  }

  @override
  CryptoRequestMethod get method => CryptoRequestMethod.decodeBackup;

  @override
  Future<AppSerializationBinary> result(AppContext context,
      {List<int>? encryptedPart}) async {
    try {
      final decode =
          Web3SecretStorageDefinationV3.decode(backup, password, encoding: encoding);
      return AppSerializationBinary(decode.data);
    } on ArgumentException {
      throw WalletExceptionConst.invalidBackupEncoding;
    } on Web3SecretStorageDefinationV3Exception catch (e) {
      if (e == Web3SecretStorageDefinationV3Exception.unsuportedBackupContent) {
        throw WalletExceptionConst.unsupportedBackupContent;
      }
      throw WalletExceptionConst.wrongBackupPassword;
    }
  }

  @override
  SerializationIdentifier get serializationIdentifier => method.tag;

  @override
  List<CborObject?> get serializationItems =>
      [password.toCbor(), backup.toCbor(), encoding.name.toCbor()];

  @override
  AppSerializationBinary parsResult(MessageArgsComplete result) {
    return AppSerializationBinary.deserialize(obj: result.result);
  }
}

class CryptoRequestDecryptExternalWalletBackup
    extends CryptoRequest<DecryptExternalWalletBackupResponse> {
  final SymKey key;
  final String backup;
  CryptoRequestDecryptExternalWalletBackup({required this.key, required this.backup});
  factory CryptoRequestDecryptExternalWalletBackup.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: CryptoRequestMethod.decryptExternalWalletBackup.tag);
    return CryptoRequestDecryptExternalWalletBackup(
        backup: values.rawValueAt(0),
        key: SymKey.deserialize(object: values.objectAt(1)));
  }

  @override
  CryptoRequestMethod get method => CryptoRequestMethod.decryptExternalWalletBackup;

  @override
  DecryptExternalWalletBackupResponse parsResult(MessageArgsComplete result) {
    return DecryptExternalWalletBackupResponse.deserialize(object: result.result);
  }

  @override
  Future<DecryptExternalWalletBackupResponse> result(AppContext context,
      {List<int>? encryptedPart}) async {
    try {
      final toBytes = BytesUtils.fromHexString(backup);
      final nonce = toBytes.sublist(0, 8);
      final sharedKey = key.sharedKey();
      final decode = ChaCha20Poly1305(sharedKey).decrypt(nonce, toBytes.sublist(8));
      if (decode != null) {
        final session = ExternalWalletConnectionInfo.generate(key, 0).toViewKey();
        return DecryptExternalWalletBackupResponse(
            encodedWallet: decode, session: session);
      }
      throw WalletExceptionConst.wrongBackupPassword;
    } on ArgumentException {
      throw WalletExceptionConst.invalidBackupEncoding;
    } on Web3SecretStorageDefinationV3Exception catch (e) {
      if (e == Web3SecretStorageDefinationV3Exception.unsuportedBackupContent) {
        throw WalletExceptionConst.unsupportedBackupContent;
      }
      throw WalletExceptionConst.wrongBackupPassword;
    } on WalletException {
      rethrow;
    } catch (_) {}
    throw WalletExceptionConst.invalidBackupEncoding;
  }

  @override
  SerializationIdentifier get serializationIdentifier => method.tag;

  @override
  List<CborObject?> get serializationItems => [backup.toCbor(), key.toCbor()];
}
