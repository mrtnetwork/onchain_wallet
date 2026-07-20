import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';

import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';

final class WalletRequestRemoveKey extends WalletRequest<ViewMasterKey> {
  final int keyId;
  const WalletRequestRemoveKey(this.keyId);

  factory WalletRequestRemoveKey.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletRequestMethod.removeWalletKeys.tag);
    return WalletRequestRemoveKey(values.rawValueAt(0));
  }

  @override
  WalletRequestMethod get method => WalletRequestMethod.removeWalletKeys;

  @override
  Future<ViewMasterKey> parsResult(MessageArgsComplete result) async {
    return ViewMasterKey.deserialize(object: result.result);
  }

  @override
  Future<ViewMasterKey> result(MemoryWalletContext wallet, AppContext context) async {
    return wallet.removeSecretKey(keyId);
  }

  @override
  List<CborObject?> get serializationItems => [keyId.toCbor()];
}
