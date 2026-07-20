import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

enum ArgsResponseType {
  streamId(AppSerializationIdentifier.streamId),
  streamArgs(AppSerializationIdentifier.streamArgs),
  result(AppSerializationIdentifier.oneBytes),
  exception(AppSerializationIdentifier.exception);

  final AppSerializationIdentifier tag;
  const ArgsResponseType(this.tag);
  static ArgsResponseType fromTag(AppSerializationIdentifier identifer) {
    return values.firstWhere((e) => e.tag == identifer,
        orElse: () => throw AppInternalError.internalError("ArgsResponseType"));
  }
}

class MessageArgsComplete extends CborMessageResponseArgs {
  final CborTagValue result;
  MessageArgsComplete(this.result);
  factory MessageArgsComplete.deserialize({List<int>? bytes, CborTagValue? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: ArgsResponseType.result.tag);
    return MessageArgsComplete(values.objectAt(0));
  }
  factory MessageArgsComplete.empty() {
    return MessageArgsComplete(
        CborTagValue(CborNullValue(), [AppSerializationIdentifier.runtimeTag.id]));
  }

  @override
  ArgsResponseType get type => ArgsResponseType.result;

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;

  @override
  List<CborObject?> get serializationItems => [result];
}

class MessageArgsStreamId extends CborMessageResponseArgs {
  final String streamId;
  MessageArgsStreamId(this.streamId);
  factory MessageArgsStreamId.deserialize({List<int>? bytes, CborTagValue? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: ArgsResponseType.streamId.tag);
    return MessageArgsStreamId(values.rawValueAt(0));
  }

  @override
  ArgsResponseType get type => ArgsResponseType.streamId;

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;

  @override
  List<CborObject?> get serializationItems => [streamId.toCbor()];
}

enum MessageArgsStreamMethod {
  message(0),
  close(1);

  final int value;
  const MessageArgsStreamMethod(this.value);
  static MessageArgsStreamMethod fromValue(int? value) {
    return values.firstWhere((e) => e.value == value,
        orElse: () => throw AppInternalError.internalError("MessageArgsStreamMethod"));
  }
}

class MessageArgsStreamResponse extends CborMessageResponseArgs {
  final List<int>? data;
  final String streamId;
  final MessageArgsStreamMethod method;
  MessageArgsStreamResponse._(
      {List<int>? data, required this.streamId, required this.method})
      : data = data?.asImmutableBytes;
  factory MessageArgsStreamResponse.deserialize(
      {List<int>? bytes, CborTagValue? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: ArgsResponseType.streamArgs.tag);
    return MessageArgsStreamResponse._(
        data: values.rawValueAt(0),
        streamId: values.rawValueAt(1),
        method: MessageArgsStreamMethod.fromValue(values.rawValueAt(2)));
  }
  factory MessageArgsStreamResponse({required List<int> data, required String streamId}) {
    return MessageArgsStreamResponse._(
        data: data, method: MessageArgsStreamMethod.message, streamId: streamId);
  }
  factory MessageArgsStreamResponse.close(String streamId) {
    return MessageArgsStreamResponse._(
        method: MessageArgsStreamMethod.close, streamId: streamId);
  }

  @override
  ArgsResponseType get type => ArgsResponseType.streamArgs;

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;

  @override
  List<CborObject?> get serializationItems =>
      [data?.toCborBytes(), streamId.toCbor(), method.value.toCbor()];
}

class MessageArgsException extends CborMessageResponseArgs {
  final IException message;
  const MessageArgsException(this.message);
  factory MessageArgsException.deserialize({List<int>? bytes, CborTagValue? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: ArgsResponseType.exception.tag);
    return MessageArgsException(IExceptionUtils.deserialize(object: values.objectAt(0)));
  }

  @override
  ArgsResponseType get type => ArgsResponseType.exception;

  @override
  String toString() {
    return "MessageArgsException:$message";
  }

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;

  @override
  List<CborObject?> get serializationItems => [message.toCbor()];
}

sealed class CborMessageResponseArgs with AppSerialization {
  const CborMessageResponseArgs();
  abstract final ArgsResponseType type;
  static T deserialize<T extends CborMessageResponseArgs>(List<int> bytes) {
    final decode = AppSerialization.decodeTaggedValueWithInfo<AppSerializationIdentifier>(
        cborBytes: bytes,
        expectedTags: [
          ArgsResponseType.result.tag,
          ArgsResponseType.streamId.tag,
          ArgsResponseType.exception.tag,
          ArgsResponseType.streamArgs.tag
        ]);
    final type = ArgsResponseType.fromTag(decode.identifier);
    CborMessageResponseArgs args;
    switch (type) {
      case ArgsResponseType.result:
        args = MessageArgsComplete.deserialize(object: decode.tag);
        break;
      case ArgsResponseType.streamId:
        args = MessageArgsStreamId.deserialize(object: decode.tag);
        break;
      case ArgsResponseType.exception:
        args = MessageArgsException.deserialize(object: decode.tag);
        break;
      case ArgsResponseType.streamArgs:
        args = MessageArgsStreamResponse.deserialize(object: decode.tag);
        break;
    }
    if (args is! T) {
      throw AppInternalError.internalError("CborMessageResponseArgs");
    }
    return args;
  }
}
