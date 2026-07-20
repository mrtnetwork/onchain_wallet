import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';

final class WalletRequestRemoveSubWallet extends WalletRequest<ViewMasterKey> {
  final int id;
  const WalletRequestRemoveSubWallet({required this.id});

  factory WalletRequestRemoveSubWallet.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletRequestMethod.removeSubWallet.tag);
    return WalletRequestRemoveSubWallet(id: values.rawValueAt(0));
  }

  @override
  WalletRequestMethod get method => WalletRequestMethod.removeSubWallet;

  @override
  Future<ViewMasterKey> parsResult(MessageArgsComplete result) async {
    return ViewMasterKey.deserialize(object: result.result);
  }

  @override
  Future<ViewMasterKey> result(MemoryWalletContext wallet, AppContext context) async {
    final newWallet = wallet.removeSubWallet(id);
    return newWallet;
  }

  @override
  List<CborObject?> get serializationItems => [CborIntValue(id)];
}
