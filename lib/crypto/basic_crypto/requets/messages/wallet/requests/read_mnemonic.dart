import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';

final class WalletRequestReadMnemonic extends WalletRequest<AccessMnemonicResponse> {
  WalletRequestReadMnemonic._();

  factory WalletRequestReadMnemonic() {
    return WalletRequestReadMnemonic._();
  }

  factory WalletRequestReadMnemonic.deserialize({List<int>? bytes, CborObject? object}) {
    AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletRequestMethod.readMnemonic.tag);
    return WalletRequestReadMnemonic();
  }

  @override
  WalletRequestMethod get method => WalletRequestMethod.readMnemonic;

  @override
  Future<AccessMnemonicResponse> parsResult(MessageArgsComplete result) async {
    final response = AccessMnemonicResponse.deserialize(object: result.result);
    return response;
  }

  @override
  Future<AccessMnemonicResponse> result(
      MemoryWalletContext wallet, AppContext context) async {
    return wallet.mnemonic();
  }

  @override
  List<CborObject?> get serializationItems => [];
}
