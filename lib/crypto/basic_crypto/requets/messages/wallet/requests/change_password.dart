import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';

import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';

final class WalletRequestChangePassword extends WalletRequest<ViewMasterKey> {
  final List<int> newPassword;
  final List<int> checksum;
  WalletRequestChangePassword._(
      {required List<int> newPassword, required List<int> checksum})
      : newPassword = newPassword.asImmutableBytes,
        checksum = checksum.asImmutableBytes;

  factory WalletRequestChangePassword(
      {required String newPassword, required List<int> checksum}) {
    return WalletRequestChangePassword._(
        newPassword: StringUtils.encode(newPassword), checksum: checksum);
  }
  factory WalletRequestChangePassword.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletRequestMethod.changeWalletPassword.tag);
    return WalletRequestChangePassword._(
        newPassword: values.rawValueAt(0), checksum: values.rawValueAt(1));
  }

  @override
  WalletRequestMethod get method => WalletRequestMethod.changeWalletPassword;

  @override
  Future<ViewMasterKey> parsResult(MessageArgsComplete result) async {
    return ViewMasterKey.deserialize(object: result.result);
  }

  @override
  Future<ViewMasterKey> result(MemoryWalletContext wallet, AppContext context) async {
    return wallet.changePassword(newPassword, checksum).cast<ViewMasterKey>();
  }

  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(newPassword), CborBytesValue(checksum)];
}
