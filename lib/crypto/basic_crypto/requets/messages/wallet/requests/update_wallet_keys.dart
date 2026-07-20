import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';

final class WalletRequestImportNewKey extends WalletRequest<ViewMasterKey> {
  final ImportedKeyStorage newKey;
  const WalletRequestImportNewKey._(this.newKey);

  factory WalletRequestImportNewKey(ImportedKeyStorage newKey) {
    return WalletRequestImportNewKey._(newKey);
  }
  factory WalletRequestImportNewKey.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletRequestMethod.updateWalletKeys.tag);
    return WalletRequestImportNewKey(
        ImportedKeyStorage.deserialize(object: values.objectAt<CborTagValue>(0)));
  }

  @override
  WalletRequestMethod get method => WalletRequestMethod.updateWalletKeys;

  @override
  Future<ViewMasterKey> parsResult(MessageArgsComplete result) async {
    return ViewMasterKey.deserialize(object: result.result);
  }

  @override
  Future<ViewMasterKey> result(MemoryWalletContext wallet, AppContext context) async {
    return wallet.importSecretKey(newKey);
  }

  @override
  List<CborObject?> get serializationItems => [newKey.toCbor()];
}
