import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';

final class WalletRequestReadPrivateKeys
    extends WalletRequest<CryptoPrivateKeysResponse> {
  final AccessCryptoKeysRequest request;
  const WalletRequestReadPrivateKeys(this.request);

  factory WalletRequestReadPrivateKeys.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletRequestMethod.readPrivateKeys.tag);
    return WalletRequestReadPrivateKeys(
        AccessCryptoKeysRequest.deserialize(object: values.objectAt<CborTagValue>(0)));
  }

  @override
  WalletRequestMethod get method => WalletRequestMethod.readPrivateKeys;

  @override
  Future<CryptoPrivateKeysResponse> parsResult(MessageArgsComplete result) async {
    return CryptoPrivateKeysResponse.deserialize(object: result.result);
  }

  @override
  Future<CryptoPrivateKeysResponse> result(
      MemoryWalletContext wallet, AppContext context) async {
    final keys = wallet.readSecretKeys(request.indexes);
    return keys;
  }

  @override
  List<CborObject?> get serializationItems => [request.toCbor()];
}

final class WalletRequestLognTimeSecretKeys
    extends WalletRequest<LongTimeMemorySecretKey> {
  final AccessCryptoKeysRequest request;
  const WalletRequestLognTimeSecretKeys(this.request);

  factory WalletRequestLognTimeSecretKeys.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletRequestMethod.longTimeSecretKet.tag);
    return WalletRequestLognTimeSecretKeys(
        AccessCryptoKeysRequest.deserialize(object: values.objectAt<CborTagValue>(0)));
  }

  @override
  WalletRequestMethod get method => WalletRequestMethod.longTimeSecretKet;

  @override
  Future<LongTimeMemorySecretKey> parsResult(MessageArgsComplete result) async {
    return LongTimeMemorySecretKey.deserialize(object: result.result);
  }

  @override
  Future<LongTimeMemorySecretKey> result(
      MemoryWalletContext wallet, AppContext context) async {
    final keys = wallet.readSecretKeys(request.indexes);
    final key = QuickCrypto.generateRandom().asImmutableBytes;
    final nonce = QuickCrypto.generateRandom(12).asImmutableBytes;
    final encrypt = CryptoKeyUtils.encryptChacha(
        key: key, nonce: nonce, data: keys.toCbor().encode());
    return LongTimeMemorySecretKey(secretKeyBytes: encrypt, key: key, nonce: nonce);
  }

  @override
  List<CborObject?> get serializationItems => [request.toCbor()];
}
