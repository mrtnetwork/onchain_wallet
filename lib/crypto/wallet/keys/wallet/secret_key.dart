part of 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

final class LongTimeMemorySecretKey with AppSerialization {
  final List<int> secretKeyBytes;
  final List<int> key;
  final List<int> nonce;
  LongTimeMemorySecretKey(
      {required List<int> secretKeyBytes,
      required List<int> key,
      required List<int> nonce})
      : secretKeyBytes = secretKeyBytes.asImmutableBytes,
        key = key.asImmutableBytes,
        nonce = nonce.asImmutableBytes;
  factory LongTimeMemorySecretKey.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag,
        cborBytes: bytes,
        cborObject: object);
    return LongTimeMemorySecretKey(
        secretKeyBytes: values.rawValueAt(0),
        key: values.rawValueAt(1),
        nonce: values.rawValueAt(2));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(secretKeyBytes), CborBytesValue(key), CborBytesValue(nonce)];

  CryptoPrivateKeyData getSecretKey(DerivableIndex index) {
    final decode =
        CryptoKeyUtils.decryptChacha(key: key, nonce: nonce, data: secretKeyBytes);
    if (decode == null) {
      throw WalletExceptionConst.authFailed;
    }
    final keys = CryptoPrivateKeysResponse.deserialize(bytes: decode);
    return keys.get(index);
  }
}
