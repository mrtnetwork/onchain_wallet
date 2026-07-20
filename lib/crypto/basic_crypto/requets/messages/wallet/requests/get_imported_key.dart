import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/wallet/keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';

final class WalletRequestReadImportedKey
    extends WalletRequest<CryptoPrivateKeyDataWithInfo> {
  final int keyId;
  const WalletRequestReadImportedKey(this.keyId);

  factory WalletRequestReadImportedKey.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletRequestMethod.readImportKey.tag);
    return WalletRequestReadImportedKey(values.rawValueAt(0));
  }

  @override
  WalletRequestMethod get method => WalletRequestMethod.readImportKey;

  @override
  Future<CryptoPrivateKeyDataWithInfo> parsResult(MessageArgsComplete result) async {
    return CryptoPrivateKeyDataWithInfo.deserialize(object: result.result);
  }

  @override
  Future<CryptoPrivateKeyDataWithInfo> result(
      MemoryWalletContext wallet, AppContext context) async {
    final key = wallet.getImportedKey(keyId);
    return CryptoPrivateKeyDataWithInfo(key: key, index: null);
  }

  @override
  List<CborObject?> get serializationItems => [keyId.toCbor()];
}
