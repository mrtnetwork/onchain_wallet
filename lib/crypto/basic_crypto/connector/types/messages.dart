import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

enum BasicCryptoMessageType {
  encrypted(AppSerializationIdentifier.encryptedMessage),
  nonEncrypted(AppSerializationIdentifier.noneEncryptedMessage);

  final AppSerializationIdentifier tag;
  const BasicCryptoMessageType(this.tag);
  static BasicCryptoMessageType fromTag(List<int>? tags) {
    return values.firstWhere((e) => e.tag.isValidTags(tags),
        orElse: () => throw AppInternalError.internalError("BasicCryptoMessageType"));
  }

  bool get isEncrypted => this == encrypted;
}

abstract class IIsolateCryptoMessage {
  final BasicCryptoMessageType type;
  final int id;
  IIsolateCryptoMessage({required this.type, required this.id});

  T cast<T extends IIsolateCryptoMessage>() {
    if (this is! T) {
      throw AppInternalError.internalError("IIsolateCryptoMessage");
    }
    return this as T;
  }

  List<int> messageBytes();

  IIsolateCryptoEncryptedMessage? encryptPart();
}

abstract class IIsolateCryptoEncryptedMessage extends IIsolateCryptoMessage {
  IIsolateCryptoEncryptedMessage({required super.id})
      : super(type: BasicCryptoMessageType.encrypted);

  List<int> nonceBytes();
  @override
  IIsolateCryptoEncryptedMessage? encryptPart() {
    return null;
  }
}

abstract class IIsolateCryptoSerializableMessage extends IIsolateCryptoMessage
    with AppSerialization {
  IIsolateCryptoSerializableMessage({required super.type, required super.id});

  factory IIsolateCryptoSerializableMessage.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborTagValue decode = AppSerialization.decode(
      cborBytes: bytes,
      cborObject: object,
    );
    final type = BasicCryptoMessageType.fromTag(decode.tags);
    return switch (type) {
      BasicCryptoMessageType.encrypted =>
        IsolateCryptoSerializableEncryptedMessage.deserialize(object: decode),
      BasicCryptoMessageType.nonEncrypted =>
        IsolateCryptoSerializableMessage.deserialize(object: decode),
    };
  }
}

final class IsolateCryptoSerializableMessage extends IIsolateCryptoSerializableMessage {
  final List<int> message;
  final IsolateCryptoSerializableEncryptedMessage? encryptedPart;

  IsolateCryptoSerializableMessage({
    required this.message,
    required super.id,
    this.encryptedPart,
  }) : super(type: BasicCryptoMessageType.nonEncrypted);
  factory IsolateCryptoSerializableMessage.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: BasicCryptoMessageType.nonEncrypted.tag);
    return IsolateCryptoSerializableMessage(
        message: cbor.rawValueAt(0),
        id: cbor.rawValueAt(1),
        encryptedPart:
            cbor.maybeObjectAt<IsolateCryptoSerializableEncryptedMessage, CborObject>(
          2,
          (p0) => IsolateCryptoSerializableEncryptedMessage.deserialize(object: p0),
        ));
  }

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;

  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(message), CborIntValue(id), encryptedPart?.toCbor()];

  @override
  List<int> messageBytes() {
    return message;
  }

  @override
  IIsolateCryptoEncryptedMessage? encryptPart() {
    return encryptedPart;
  }
}

final class IsolateCryptoSerializableEncryptedMessage
    extends IIsolateCryptoSerializableMessage implements IIsolateCryptoEncryptedMessage {
  final List<int> nonce;
  final List<int> message;

  IsolateCryptoSerializableEncryptedMessage({
    required List<int> message,
    required List<int> nonce,
    required super.id,
  })  : nonce = nonce.asImmutableBytes,
        message = message.asImmutableBytes,
        super(type: BasicCryptoMessageType.encrypted);
  factory IsolateCryptoSerializableEncryptedMessage.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: BasicCryptoMessageType.encrypted.tag);
    return IsolateCryptoSerializableEncryptedMessage(
        nonce: cbor.rawValueAt(0), message: cbor.rawValueAt(1), id: cbor.rawValueAt(2));
  }

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;

  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(nonce), CborBytesValue(message), CborIntValue(id)];

  @override
  List<int> messageBytes() {
    return message;
  }

  @override
  List<int> nonceBytes() {
    return nonce;
  }

  @override
  IIsolateCryptoEncryptedMessage? encryptPart() {
    return null;
  }
}
