import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/external_wallet.dart';
import 'package:on_chain_wallet/crypto/types/sym_key.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';

final class WalletRequestImportExternalWallet
    extends WalletRequest<ImportExternalWalletResponse> {
  final SymKey key;
  final int clientId;
  final List<int> checksum;

  WalletRequestImportExternalWallet({
    required this.key,
    required this.clientId,
    required List<int> checksum,
  }) : checksum = checksum.asImmutableBytes;

  factory WalletRequestImportExternalWallet.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletRequestMethod.importExternalWallet.tag);
    return WalletRequestImportExternalWallet(
        key: SymKey.deserialize(object: values.objectAt(0)),
        checksum: values.rawValueAt(1),
        clientId: values.rawValueAt(2));
  }

  @override
  WalletRequestMethod get method => WalletRequestMethod.importExternalWallet;

  @override
  Future<ImportExternalWalletResponse> parsResult(MessageArgsComplete result) async {
    return ImportExternalWalletResponse.deserialize(object: result.result);
  }

  @override
  Future<ImportExternalWalletResponse> result(
      MemoryWalletContext wallet, AppContext context) async {
    final sharedKey = key.sharedKey();
    final List<int> checksum = QuickCrypto.keccack256Hash([
      ...sharedKey,
      ...wallet.getMasterKeyChecksum(),
      ...wallet.getMemoryKeyChecksum(),
      ...clientId.toU32LeBytes()
    ]);
    if (!BytesUtils.bytesEqual(checksum, this.checksum)) {
      throw WalletExceptionConst.externalWalletConnectionAuthenticatedFailed;
    }
    final newConnection = ExternalWalletConnectionInfo.generate(key, clientId);
    final newWallet = wallet.importNewExternalConnection(newConnection);
    return ImportExternalWalletResponse(
        encryptedKey: newWallet, connection: newConnection.toViewKey());
  }

  @override
  List<CborObject?> get serializationItems =>
      [key.toCbor(), CborBytesValue(checksum), clientId.toCbor()];
}
