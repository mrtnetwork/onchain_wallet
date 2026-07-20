import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

class GeneratedSharedKey with AppSerialization {
  final List<int> topic;
  final List<int> publicKey;
  final List<int> symkey;
  GeneratedSharedKey(
      {required List<int> topic, required List<int> publicKey, required List<int> symkey})
      : topic = topic.asImmutableBytes,
        publicKey = publicKey.asImmutableBytes,
        symkey = symkey.asImmutableBytes;
  late final String topicAsHex = BytesUtils.toHexString(topic);
  late final String publicKeyAsHex = BytesUtils.toHexString(publicKey);
  late final String symkeyAsHex = BytesUtils.toHexString(symkey);

  factory GeneratedSharedKey.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag,
        cborBytes: bytes,
        cborObject: object);
    return GeneratedSharedKey(
        topic: values.rawValueAt(0),
        publicKey: values.rawValueAt(1),
        symkey: values.rawValueAt(2));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(topic), CborBytesValue(publicKey), CborBytesValue(symkey)];
}

class GeneratedX25519Key with AppSerialization {
  final List<int> publicKey;
  final List<int> privateKey;
  GeneratedX25519Key({required List<int> privateKey, required List<int> publicKey})
      : publicKey = publicKey.asImmutableBytes,
        privateKey = privateKey.asImmutableBytes;
  late final String publicKeyAsHex = BytesUtils.toHexString(publicKey);

  factory GeneratedX25519Key.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag,
        cborBytes: bytes,
        cborObject: object);
    return GeneratedX25519Key(
        privateKey: values.rawValueAt(0), publicKey: values.rawValueAt(1));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(privateKey), CborBytesValue(publicKey)];
}
