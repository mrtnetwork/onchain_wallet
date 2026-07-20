import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

final class CryptoPersonalSignResponse with AppSerialization {
  late final String signatureHex = BytesUtils.toHexString(signature, prefix: "0x");
  final List<int> signature;
  CryptoPersonalSignResponse({
    required List<int> signature,
  }) : signature = signature.asImmutableBytes;

  factory CryptoPersonalSignResponse.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag,
        cborBytes: bytes,
        cborObject: object);
    return CryptoPersonalSignResponse(signature: values.rawValueAt(0));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [signature.toCborBytes()];
}

final class CryptoBitcoinPersonalSignResponse with AppSerialization {
  final List<int> signature;
  final List<int> digest;
  CryptoBitcoinPersonalSignResponse({
    required List<int> signature,
    required List<int> digest,
  })  : digest = digest.asImmutableBytes,
        signature = signature.asImmutableBytes;
  factory CryptoBitcoinPersonalSignResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag,
        cborBytes: bytes,
        cborObject: object);
    return CryptoBitcoinPersonalSignResponse(
        signature: values.rawValueAt(0), digest: values.rawValueAt(1));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems =>
      [signature.toCborBytes(), digest.toCborBytes()];
}
