import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

final class CryptoEncryptChachaResponse with AppSerialization {
  final List<int> encrypted;
  final List<int> nonce;
  CryptoEncryptChachaResponse({required List<int> encrypted, required List<int> nonce})
      : encrypted = encrypted.asImmutableBytes,
        nonce = nonce.asImmutableBytes;

  factory CryptoEncryptChachaResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag,
        cborBytes: bytes,
        cborObject: object);
    return CryptoEncryptChachaResponse(
        encrypted: values.rawValueAt(0), nonce: values.rawValueAt(1));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(encrypted), CborBytesValue(nonce)];
  String get encryptedHex => BytesUtils.toHexString(encrypted);
  String get nonceHex => BytesUtils.toHexString(nonce);
}

class CryptoDecryptChachaResponse with AppSerialization {
  final List<int> decrypted;
  CryptoDecryptChachaResponse(List<int> decrypted)
      : decrypted = decrypted.asImmutableBytes;
  factory CryptoDecryptChachaResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag,
        cborBytes: bytes,
        cborObject: object);
    return CryptoDecryptChachaResponse(values.rawValueAt(0));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [CborBytesValue(decrypted)];
}
