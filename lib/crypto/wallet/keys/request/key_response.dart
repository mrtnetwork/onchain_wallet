part of 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

final class CryptoPrivateKeysResponse with AppSerialization {
  final List<CryptoPrivateKeyDataWithInfo> keys;
  CryptoPrivateKeysResponse.__(List<CryptoPrivateKeyDataWithInfo> keys)
      : keys = List<CryptoPrivateKeyDataWithInfo>.unmodifiable(keys);
  factory CryptoPrivateKeysResponse._(List<CryptoPrivateKeyDataWithInfo> keys) {
    return CryptoPrivateKeysResponse.__(keys);
  }
  factory CryptoPrivateKeysResponse.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.accessPrivateKeysRequest);
    final List<CryptoPrivateKeyDataWithInfo> indexes = cbor.value
        .map((e) => CryptoPrivateKeyDataWithInfo.deserialize(object: e))
        .toList();
    return CryptoPrivateKeysResponse._(indexes);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.accessPrivateKeysRequest;

  @override
  List<CborObject?> get serializationItems => keys.map((e) => e.toCbor()).toList();
  CryptoPrivateKeyData get(DerivableIndex index) {
    return keys
        .firstWhere((e) => e.index == index,
            orElse: () => throw AppCryptoExceptionConst.invalidDerivationKey)
        .key;
  }
}

final class CryptoPublicKeysResponse with AppSerialization {
  final List<CryptoPublicKeyDataWithInfo> keys;
  CryptoPublicKeysResponse.__(List<CryptoPublicKeyDataWithInfo> keys)
      : keys = List<CryptoPublicKeyDataWithInfo>.unmodifiable(keys);
  factory CryptoPublicKeysResponse._(List<CryptoPublicKeyDataWithInfo> keys) {
    return CryptoPublicKeysResponse.__(keys);
  }
  factory CryptoPublicKeysResponse.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.accessPublicKeysRequest);
    final List<CryptoPublicKeyDataWithInfo> indexes = cbor.value
        .map((e) => CryptoPublicKeyDataWithInfo.deserialize(object: e))
        .toList();
    return CryptoPublicKeysResponse.__(indexes);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.accessPublicKeysRequest;

  @override
  List<CborObject?> get serializationItems => keys.map((e) => e.toCbor()).toList();
}
