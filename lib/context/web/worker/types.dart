import 'dart:js_interop';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:on_chain_bridge/web/api/types/types.dart';
import 'package:on_chain_bridge/web/utils/utils.dart';
import 'package:on_chain_bridge/web/web.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/types/worker.dart';

@JS()
extension type JSIsolateEncodedMessage._(JSObject _) implements JSObject {
  external factory JSIsolateEncodedMessage(
      {JSArray<JSAny> transfableParams, required JSWorkerMessage message});
  external JSArray<JSAny>? get transfableParams;
  external JSWorkerMessage get message;
  factory JSIsolateEncodedMessage.fromBuffer(
      {required List<int> bytes, required IsolateMessageTypes type, required int id}) {
    final toBytes = JsUtils.toAppJsUint8Array(bytes);
    return JSIsolateEncodedMessage(
        message: JSWorkerMessage.messageInternal(
            id: id.toJS, buffer: toBytes.buffer, type: type.value.toJS),
        transfableParams: [toBytes.buffer].toJS);
  }
}
// @JS()
// extension type JSWorkerMessagePort._(JSObject _) implements JSObject {
//   external factory JSWorkerMessagePort({JSNumber id, JSMessagePort port});
//   external JSNumber get id;
//   external JSMessagePort get port;
// }
@JS()
extension type JSWorkerMessage._(JSObject _) implements JSObject {
  external factory JSWorkerMessage.close({@JS("worker_message_closed") JSBoolean? close});
  external factory JSWorkerMessage.messageInternal({
    @JS("worker_message_message") JSAny? message,
    @JS("worker_message_buffer") APPJSArrayBuffer? buffer,
    @JS("worker_message_port") JSMessagePort? port,
    @JS("worker_config") APPJSArrayBuffer? config,
    @JS("worker_message_type") required JSNumber type,
    @JS("worker_message_id") required JSNumber id,
  });
  @JS("worker_message_type")
  external JSNumber? get type;
  @JS("worker_message_id")
  external JSNumber? get id;
  @JS("worker_message_closed")
  external JSBoolean? get closed;
  @JS("worker_message_message")
  external JSAny? get message;
  @JS("worker_message_buffer")
  external APPJSArrayBuffer? get buffer;
  @JS("worker_message_port")
  external JSMessagePort? get port;
  @JS("worker_config")
  external APPJSArrayBuffer? get config;

  IResult<T> fold<T extends Object?>({
    required IResult<T>? Function(JSDartWorkerMessage message) fn,
    IResult<T> Function(IException? error)? onMissing,
  }) {
    return toDart().andThen((e) => IResult.callSync(() => fn(e))).and((result, error) {
      if (error != null || result == null) {
        if (onMissing != null) {
          return onMissing(error);
        }
        return ResultErr.fromException(error ??
            AppInternalError.internalError("JSWorkerMessage.fold",
                reason: "Unexpected JSWorkerMessage."));
      }
      return result;
    });
  }

  JSAny? getMessage() {
    if (message.isDefinedAndNotNull) return message;
    return null;
  }

  JSMessagePort? getMessagePort() {
    if (port.isDefinedAndNotNull) return port;
    return null;
  }

  APPJSArrayBuffer? getBuffer() {
    if (buffer.isDefinedAndNotNull) return buffer;
    return null;
  }

  APPJSArrayBuffer? getConfig() {
    if (config.isDefinedAndNotNull) return config;
    return null;
  }

  bool isClosed() {
    return closed.isDefinedAndNotNull;
  }

  int? getId() {
    if (id.isDefinedAndNotNull) return id?.toDartInt;
    return null;
  }

  int? getType() {
    if (type.isDefinedAndNotNull) return type?.toDartInt;
    return null;
  }

  IResult<JSDartWorkerMessage> toDart() {
    final message = getMessage();
    final buffer = getBuffer();
    final port = getMessagePort();
    final config = getConfig();
    final id = getId();
    final type = IsolateMessageTypes.tryFromValue(getType());
    if (type == null || id == null) {
      return ResultErr.fromException(AppInternalError.internalError("JSWorkerMessage",
          reason: "Invalid message. missing type"));
    }
    return IResult.callSync<JSDartWorkerMessage>(() => JSDartWorkerMessage(
        type: type,
        buffer: buffer?.toUint8Array().toBytes(),
        config: config?.toUint8Array().toBytes(),
        port: port,
        message: message,
        id: id));
  }
}

class JSDartWorkerMessage {
  final IsolateMessageTypes type;
  final int id;
  final List<int>? buffer;
  final List<int>? config;
  final JSMessagePort? port;
  final JSAny? message;
  const JSDartWorkerMessage(
      {required this.type,
      required this.buffer,
      required this.config,
      required this.port,
      required this.message,
      required this.id});
  @override
  String toString() {
    return "JSDartWorkerMessage(${type.name})";
  }
}

class WebIsolateEncodedMessage {
  final List<int>? bytes;
  final List<int>? config;
  final JSMessagePort? port;
  final IsolateMessageTypes type;
  final JSAny? message;
  final bool transfableMessage;
  final int id;

  WebIsolateEncodedMessage._(
      {this.bytes,
      this.port,
      this.config,
      required this.type,
      this.message,
      this.transfableMessage = false,
      required this.id});
  factory WebIsolateEncodedMessage.bytes(
      {required int id, required List<int> bytes, required IsolateMessageTypes type}) {
    return WebIsolateEncodedMessage._(bytes: bytes, type: type, id: id);
  }
  factory WebIsolateEncodedMessage.message(
      {required IsolateMessageTypes type,
      required JSAny? message,
      required int id,
      List<int>? buffer,
      bool transfableMessage = false}) {
    return WebIsolateEncodedMessage._(
        message: message,
        transfableMessage: transfableMessage,
        type: type,
        bytes: buffer,
        id: id);
  }
  factory WebIsolateEncodedMessage.port(
      {required JSMessagePort port, required IsolateMessageTypes type, required int id}) {
    return WebIsolateEncodedMessage._(port: port, type: type, id: id);
  }
  factory WebIsolateEncodedMessage.empty(IsolateMessageTypes type, int id) {
    return WebIsolateEncodedMessage._(type: type, id: id);
  }
  WebIsolateEncodedMessage withConfig(List<int> config) {
    return WebIsolateEncodedMessage._(
        bytes: bytes, port: port, config: config, type: type, id: id);
  }

  WebIsolateEncodedMessage withPort(JSMessagePort port) {
    return WebIsolateEncodedMessage._(
        bytes: bytes, port: port, config: config, type: type, id: id);
  }

  ({JSWorkerMessage message, JSArray<JSAny> transfableParams}) encode() {
    final bytes = switch (this.bytes) {
      List<int> bytes => JsUtils.toAppJsUint8Array(bytes),
      null => null
    };
    final config = switch (this.config) {
      List<int> bytes => JsUtils.toAppJsUint8Array(bytes),
      null => null
    };
    final port = this.port;
    final message = this.message;
    return (
      message: JSWorkerMessage.messageInternal(
          buffer: bytes?.buffer,
          config: config?.buffer,
          port: port,
          type: type.value.toJS,
          id: id.toJS,
          message: message),
      transfableParams: [
        if (bytes != null) bytes.buffer,
        if (config != null) config.buffer,
        if (port != null) port,
        if (message != null && transfableMessage) message,
      ].toJS,
    );
  }
}
