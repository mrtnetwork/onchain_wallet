import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/app_backup_response.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/external_backup.dart';
import 'package:on_chain_wallet/crypto/types/sym_key.dart';

final class WalletRequestBackupWallet extends WalletRequest<AppBackupResponse> {
  final String? passhrase;
  final String? newPassword;
  final List<int> checksum;

  WalletRequestBackupWallet(
      {required this.passhrase, required this.newPassword, required List<int> checksum})
      : checksum = checksum.asImmutableBytes;

  factory WalletRequestBackupWallet.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletRequestMethod.walletBackup.tag);
    return WalletRequestBackupWallet(
        newPassword: values.rawValueAt(0),
        passhrase: values.rawValueAt(1),
        checksum: values.rawValueAt(2));
  }

  @override
  WalletRequestMethod get method => WalletRequestMethod.walletBackup;

  @override
  Future<AppBackupResponse> parsResult(MessageArgsComplete result) async {
    return AppBackupResponse.deserialize(object: result.result);
  }

  @override
  Future<AppBackupResponse> result(MemoryWalletContext wallet, AppContext context) async {
    final masterKey = WalletMasterKeys.generate(
        mnemonic: wallet.mnemonic().mnemonic.toStr(), passphrase: passhrase);
    if (!BytesUtils.bytesEqual(masterKey.checksum, wallet.getMasterKeyChecksum())) {
      throw WalletExceptionConst.invalidBackupChecksum;
    }
    return AppBackupResponse(wallet.backupWallet(checksum, password: newPassword));
  }

  @override
  List<CborObject?> get serializationItems =>
      [newPassword?.toCbor(), passhrase?.toCbor(), CborBytesValue(checksum)];
}

final class WalletRequestBackupKey extends WalletRequest<AppBackupResponse> {
  final List<int> backup;
  final SecretWalletEncoding encoding;

  WalletRequestBackupKey({required this.encoding, required List<int> backup})
      : backup = backup.asImmutableBytes;

  factory WalletRequestBackupKey.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletRequestMethod.encodeBackup.tag);
    final encoding = SecretWalletEncoding.values.firstWhere(
        (element) => element.name == values.rawValueAt<String>(1),
        orElse: () =>
            throw AppInternalError.internalError("WalletRequestBackupKey.deserialize"));
    return WalletRequestBackupKey(backup: values.rawValueAt(0), encoding: encoding);
  }

  @override
  WalletRequestMethod get method => WalletRequestMethod.encodeBackup;

  @override
  Future<AppBackupResponse> parsResult(MessageArgsComplete result) async {
    return AppBackupResponse.deserialize(object: result.result);
  }

  @override
  Future<AppBackupResponse> result(MemoryWalletContext wallet, AppContext context) async {
    final web3SD = wallet.encryptByWalletKey(backup);
    return AppBackupResponse(web3SD.encrypt(encoding: encoding));
  }

  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(backup), encoding.name.toCbor()];
}

final class WalletRequestBackupExternalWallet
    extends WalletRequest<ExternalWalletBackupResponse> {
  final SymKey key;

  WalletRequestBackupExternalWallet(this.key);

  factory WalletRequestBackupExternalWallet.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletRequestMethod.walletExternalBackup.tag);
    return WalletRequestBackupExternalWallet(
      SymKey.deserialize(object: values.objectAt(0)),
    );
  }

  @override
  WalletRequestMethod get method => WalletRequestMethod.walletExternalBackup;

  @override
  Future<ExternalWalletBackupResponse> parsResult(MessageArgsComplete result) async {
    return ExternalWalletBackupResponse.deserialize(object: result.result);
  }

  @override
  Future<ExternalWalletBackupResponse> result(
      MemoryWalletContext wallet, AppContext context) async {
    final clientId = wallet.getNewExternalConnectionClientId();
    final connection = ExternalWalletConnectionInfo(
        privateKey: QuickCrypto.generateRandom(),
        publicKey: QuickCrypto.generateRandom(),
        targetPublicKey: QuickCrypto.generateRandom(),
        sharedKey: QuickCrypto.generateRandom(),
        topic: QuickCrypto.generateRandom(),
        clientId: clientId);
    final masterKey = wallet.toExternalWallet(connection);
    final sharedKey = key.sharedKey();
    final List<int> connectorIdBytes = QuickCrypto.keccack256Hash([
      ...sharedKey,
      ...masterKey.checksum,
      ...wallet.getMemoryKeyChecksum(),
      ...connection.clientId.toU32LeBytes(),
    ]);
    final nonce = QuickCrypto.generateRandom(8);
    final data = masterKey.toCbor(connectionId: connectorIdBytes).encode();
    final encrypt = QuickCrypto.chaCha20Poly1305Encrypt(
        key: sharedKey, nonce: nonce, plainText: data);
    return ExternalWalletBackupResponse(
        backup: BytesUtils.toHexString([...nonce, ...encrypt]),
        session: ExternalWalletConnectionInfo.generate(key, clientId).toViewKey());
  }

  @override
  List<CborObject?> get serializationItems => [key.toCbor()];
}
