import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';

final class WalletRequestReadPublicKeys extends WalletRequest<CryptoPublicKeysResponse> {
  final AccessCryptoKeysRequest request;
  const WalletRequestReadPublicKeys._(this.request);

  factory WalletRequestReadPublicKeys(AccessCryptoKeysRequest request) {
    return WalletRequestReadPublicKeys._(request);
  }
  factory WalletRequestReadPublicKeys.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletRequestMethod.readPublicKeys.tag);
    return WalletRequestReadPublicKeys(
        AccessCryptoKeysRequest.deserialize(object: values.objectAt<CborTagValue>(0)));
  }

  @override
  WalletRequestMethod get method => WalletRequestMethod.readPublicKeys;

  @override
  Future<CryptoPublicKeysResponse> parsResult(MessageArgsComplete result) async {
    return CryptoPublicKeysResponse.deserialize(object: result.result);
  }

  @override
  Future<CryptoPublicKeysResponse> result(
      MemoryWalletContext wallet, AppContext context) async {
    final keys = wallet.readPublicKeys(request.indexes);
    return keys;
  }

  @override
  List<CborObject?> get serializationItems => [request.toCbor()];
}
