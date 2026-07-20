import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

class SymKey with AppSerialization {
  final List<int> privateKey;
  final List<int> targetPublicKey;
  SymKey({required List<int> privateKey, required List<int> targetPublicKey})
      : privateKey = privateKey
            .exc(length: Ed25519KeysConst.privKeyByteLen, operation: "SymKey")
            .asImmutableBytes,
        targetPublicKey = targetPublicKey
            .exc(length: Ed25519KeysConst.pubKeyByteLen, operation: "SymKey")
            .asImmutableBytes;
  factory SymKey.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: AppSerializationIdentifier.runtimeTag,
    );
    return SymKey(
        privateKey: values.rawValueAt(0), targetPublicKey: values.rawValueAt(1));
  }

  List<int> sharedKey() => X25519.scalarMult(privateKey, targetPublicKey);

  List<int> publicKey() => X25519.scalarMultBase(privateKey).publicKey;

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(privateKey), CborBytesValue(targetPublicKey)];
}
