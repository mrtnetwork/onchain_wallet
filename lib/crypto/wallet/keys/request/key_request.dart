part of 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

final class AccessCryptoKeysRequest with AppSerialization {
  final List<DerivableIndex> indexes;
  AccessCryptoKeysRequest._(List<DerivableIndex> indexes)
      : indexes = List<DerivableIndex>.unmodifiable(indexes);
  factory AccessCryptoKeysRequest(List<DerivableIndex> indexes) {
    return AccessCryptoKeysRequest._(indexes);
  }
  factory AccessCryptoKeysRequest.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.accessPrivateKeysRequest);
    final List<DerivableIndex> indexes =
        cbor.value.map((e) => DerivableIndex.deserialize(object: e)).toList();
    return AccessCryptoKeysRequest(indexes);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.accessPrivateKeysRequest;

  @override
  List<CborObject?> get serializationItems => indexes.map((e) => e.toCbor()).toList();
}

// final class AccessCryptoPrivateKeyRequest with AppSerialization {
//   final DerivableIndex index;

//   const AccessCryptoPrivateKeyRequest._({required this.index});
//   factory AccessCryptoPrivateKeyRequest({required DerivableIndex index}) {
//     return AccessCryptoPrivateKeyRequest._(index: index);
//   }

//   factory AccessCryptoPrivateKeyRequest.deserialize(
//       {List<int>? bytes, CborObject? object}) {
//     final CborListValue cbor = AppSerialization.decodeTaggedValue(
//         cborBytes: bytes,
//         cborObject: object,
//         identifier: AppSerializationIdentifier.accessPrivateKeyRequest);

//     return AccessCryptoPrivateKeyRequest._(
//         index: DerivableIndex.deserialize(object: cbor.objectAt<CborTagValue>(0)));
//   }

//   @override
//   SerializationIdentifier get serializationIdentifier =>
//       AppSerializationIdentifier.accessPrivateKeyRequest;

//   @override
//   List<CborObject?> get serializationItems => [index.toCbor()];
// }
