import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/json/extension/json.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/bridge/exception/exception.dart';
import 'package:on_chain_wallet/network/bridge/types/server/types.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/types.dart';
import 'package:on_chain_wallet/network/bridge/utils/id_generator.dart';

sealed class ITopicMessage {
  final IBridgeSession session;
  final DateTime? publishedAt;
  final DateTime expire;
  final BridgeProtocol protocol;
  abstract final IJsonRpcMessage message;
  bool get isEpire => expire.isBefore(DateTime.now());
  Duration? timeout() {
    final now = DateTime.now();
    final n = expire.millisecondsSinceEpoch - now.millisecondsSinceEpoch;
    if (n <= 0) {
      return null;
    }
    return Duration(milliseconds: n);
  }

  BridgeKnownMethods? get method => message.method;
  const ITopicMessage(
      {required this.session,
      required this.publishedAt,
      required this.expire,
      required this.protocol});
  factory ITopicMessage.fromMessage({
    required IJsonRpcMessage message,
    required BridgeProtocol protocol,
    TransportType trasportType = TransportType.relay,
    required IBridgeSession session,
    DateTime? publishedAt,
  }) {
    return switch (message) {
      JsonRpcMessageRequest message => switch (message.method) {
          BridgeKnownMethods.pairingPing ||
          BridgeKnownMethods.pairingDelete ||
          BridgeKnownMethods.sessionPropose when session.type.isPairing =>
            TopicMessagePairing(
                request: message,
                trasportType: trasportType,
                publishedAt: publishedAt,
                protocol: protocol,
                session: session),
          _ when !session.type.isPairing => TopicMessageRequest(
              message: message,
              session: session,
              publishedAt: publishedAt,
              protocol: protocol),
          _ => TopicMessageInvalidSession(
              message: message,
              publishedAt: publishedAt,
              session: session,
              protocol: protocol)
        },
      IJsonRpcMessageResponse message => TopicMessageResponse(
          session: session,
          message: message,
          publishedAt: publishedAt,
          protocol: protocol),
      _ => TopicMessageUnknown(
          request: message,
          session: session,
          publishedAt: publishedAt,
          protocol: protocol)
    };
  }
}

class TopicMessagePairing extends ITopicMessage {
  @override
  final JsonRpcMessageRequest message;

  const TopicMessagePairing._({
    required super.session,
    required this.message,
    required super.publishedAt,
    required super.expire,
    required super.protocol,
  });
  factory TopicMessagePairing({
    required JsonRpcMessageRequest request,
    required TransportType trasportType,
    required IBridgeSession session,
    required BridgeProtocol protocol,
    DateTime? publishedAt,
  }) {
    publishedAt ??= DateTime.now();
    final expire = publishedAt.add(Duration(seconds: request.method.requestParam.ttl));
    return TopicMessagePairing._(
        message: request,
        session: session,
        protocol: protocol,
        publishedAt: publishedAt,
        expire: expire);
  }

  @override
  BridgeKnownMethods get method => message.method;
}

class TopicMessageRequest extends ITopicMessage {
  @override
  final JsonRpcMessageRequest message;
  TopicMessageRequest({
    required super.session,
    required this.message,
    required DateTime? publishedAt,
    required super.protocol,
  }) : super(
            publishedAt: publishedAt ??= DateTime.now(),
            expire: publishedAt.add(Duration(seconds: message.method.requestParam.ttl)));
  @override
  BridgeKnownMethods get method => message.method;
}

class TopicMessageResponse extends ITopicMessage {
  @override
  final IJsonRpcMessageResponse message;
  TopicMessageResponse({
    required super.session,
    required this.message,
    required DateTime? publishedAt,
    required super.protocol,
  }) : super(publishedAt: publishedAt ??= DateTime.now(), expire: DateTime.now());
  @override
  BridgeKnownMethods? get method => null;
}

class TopicMessageUnknown extends ITopicMessage {
  @override
  final IJsonRpcMessage message;

  const TopicMessageUnknown._({
    required super.session,
    required this.message,
    required super.publishedAt,
    required super.expire,
    required super.protocol,
  });
  factory TopicMessageUnknown({
    required IJsonRpcMessage request,
    required IBridgeSession session,
    required BridgeProtocol protocol,
    DateTime? publishedAt,
  }) {
    return TopicMessageUnknown._(
        session: session,
        message: request,
        publishedAt: publishedAt ?? DateTime.now(),
        expire: DateTime.now(),
        protocol: protocol);
  }
}

class TopicMessageInvalidSession extends ITopicMessage {
  @override
  final JsonRpcMessageRequest message;
  TopicMessageInvalidSession({
    required super.session,
    required this.message,
    required super.publishedAt,
    required super.protocol,
  }) : super(expire: DateTime.now());
  @override
  BridgeKnownMethods get method => message.method;
}

enum JsonRpcMessageResponseType { error, result }

enum JsonRpcMessageType { request, response, unsuported, unknwon }

sealed class IJsonRpcMessage {
  final int id;
  BridgeKnownMethods? get method;
  final JsonRpcMessageType messageType;
  const IJsonRpcMessage({required this.messageType, required this.id});
  T cast<T extends IJsonRpcMessage>() {
    if (this is! T) throw BridgeExceptionConst.internalError;
    return this as T;
  }

  factory IJsonRpcMessage.fromJson(Map<String, dynamic> json) {
    final int? id = IntUtils.tryParse(json["id"]);
    final bool hasMethod = json["method"] != null;
    final bool hasParams = json["params"] != null;
    final bool hasError = json["error"] != null;
    final bool hasResult = json["result"] != null;
    if (id == null) {
      return JsonRpcMessageUnknown(id: DateTime.now().millisecondsSinceEpoch);
    }
    if (hasMethod && hasParams) {
      final request = JsonRpcMessageRequest.fromJson(json);
      if (request.method == BridgeKnownMethods.unregisteredMethod ||
          !request.method.allowReceive) {
        return JsonRpcMessageUnsupportedMethod(id: id, method: request.method);
      }
      return request;
    }
    if (hasError || hasResult) {
      return IJsonRpcMessageResponse.fromJson(json);
    }
    return JsonRpcMessageUnknown(id: id);
  }
}

class JsonRpcMessageUnknown extends IJsonRpcMessage {
  const JsonRpcMessageUnknown({required super.id})
      : super(messageType: JsonRpcMessageType.unknwon);

  @override
  BridgeKnownMethods? get method => null;
}

class JsonRpcMessageUnsupportedMethod extends IJsonRpcMessage {
  @override
  final BridgeKnownMethods method;
  const JsonRpcMessageUnsupportedMethod({required super.id, required this.method})
      : super(messageType: JsonRpcMessageType.unsuported);
}

class JsonRpcMessageRequest extends IJsonRpcMessage {
  final dynamic params;
  @override
  final BridgeKnownMethods method;
  final String jsonrpc;
  const JsonRpcMessageRequest(
      {required super.id,
      required this.params,
      required this.method,
      required this.jsonrpc})
      : super(messageType: JsonRpcMessageType.request);
  factory JsonRpcMessageRequest.fromJson(Map<String, dynamic> json) {
    return JsonRpcMessageRequest(
        id: json["id"],
        params: json["params"],
        method: BridgeKnownMethods.fromName(json['method']),
        jsonrpc: json["jsonrpc"] ?? "2.0");
  }

  T paramsAs<T>() => JsonParser.valueAs<T>(params);

  Map<String, dynamic> toJson() {
    return {"id": id, "params": params, "method": method.method, "jsonrpc": jsonrpc};
  }
}

sealed class IJsonRpcMessageResponse extends IJsonRpcMessage {
  final String jsonrpc;
  final JsonRpcMessageResponseType type;
  const IJsonRpcMessageResponse(
      {required super.id, required this.jsonrpc, required this.type})
      : super(messageType: JsonRpcMessageType.response);
  factory IJsonRpcMessageResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey("error")) {
      return JsonRpcMessageResponseError.fromJson(json);
    }
    return JsonRpcMessageResponseSucceess.fromJson(json);
  }

  @override
  BridgeKnownMethods? get method => null;
}

class JsonRpcMessageResponseSucceess extends IJsonRpcMessageResponse {
  final dynamic result;
  const JsonRpcMessageResponseSucceess({
    required super.id,
    super.jsonrpc = "2.0",
    required this.result,
  }) : super(type: JsonRpcMessageResponseType.result);

  factory JsonRpcMessageResponseSucceess.fromJson(Map<String, dynamic> json) {
    return JsonRpcMessageResponseSucceess(
      id: json['id'],
      jsonrpc: json['jsonrpc'],
      result: json['result'],
    );
  }
}

class JsonRpcMessageResponseError extends IJsonRpcMessageResponse {
  final IRpcError error;
  const JsonRpcMessageResponseError({
    required super.id,
    super.jsonrpc = "2.0",
    required this.error,
  }) : super(type: JsonRpcMessageResponseType.error);

  factory JsonRpcMessageResponseError.fromJson(Map<String, dynamic> json) {
    return JsonRpcMessageResponseError(
      id: json['id'],
      jsonrpc: json['jsonrpc'],
      error: IRpcError.deserialize(json["error"]),
    );
  }
}

class WalletConnectMethodParams {
  final int ttl;
  final int tag;
  final bool prompt;
  static const int defaultTll = 24 * 60 * 60 * 6;
  static const int runtimeTag = 24 * 60 * 60 * 6;
  const WalletConnectMethodParams(
      {required this.ttl, required this.tag, required this.prompt});
}

enum BridgeKnownMethods {
  pairingPing(
      value: 0,
      method: 'wc_pairingPing',
      requestParam: WalletConnectMethodParams(ttl: 30, tag: 1002, prompt: false),
      responseParam: WalletConnectMethodParams(ttl: 30, tag: 1003, prompt: false)),
  pairingDelete(
      value: 1,
      method: 'wc_pairingDelete',
      requestParam:
          WalletConnectMethodParams(ttl: 24 * 60 * 60, tag: 1000, prompt: false),
      responseParam:
          WalletConnectMethodParams(ttl: 24 * 60 * 60, tag: 1001, prompt: false)),
  unregisteredMethod(
      value: 2,
      method: 'unregistered_method',
      requestParam: WalletConnectMethodParams(ttl: 24 * 60 * 60, tag: 0, prompt: false),
      responseParam: WalletConnectMethodParams(ttl: 24 * 60 * 60, tag: 0, prompt: false)),

  sessionPropose(
      value: 3,
      method: 'wc_sessionPropose',
      requestParam: WalletConnectMethodParams(ttl: 5 * 60, tag: 1100, prompt: true),
      responseParam: WalletConnectMethodParams(ttl: 5 * 60, tag: 1101, prompt: false),
      reject: WalletConnectMethodParams(ttl: 5 * 60, tag: 1120, prompt: false),
      autoReject: WalletConnectMethodParams(ttl: 5 * 60, tag: 1121, prompt: false)),
  sessionUpdate(
      value: 4,
      method: 'wc_sessionUpdate',
      requestParam:
          WalletConnectMethodParams(ttl: 24 * 60 * 60, tag: 1104, prompt: false),
      responseParam:
          WalletConnectMethodParams(ttl: 24 * 60 * 60, tag: 1105, prompt: false),
      allowReceive: false),
  sessionExtend(
      value: 5,
      method: 'wc_sessionExtend',
      requestParam:
          WalletConnectMethodParams(ttl: 24 * 60 * 60, tag: 1106, prompt: false),
      responseParam:
          WalletConnectMethodParams(ttl: 24 * 60 * 60, tag: 1107, prompt: false),
      allowReceive: false),
  sessionRequest(
      value: 6,
      method: 'wc_sessionRequest',
      requestParam: WalletConnectMethodParams(ttl: 5 * 60, tag: 1108, prompt: true),
      responseParam: WalletConnectMethodParams(ttl: 5 * 60, tag: 1109, prompt: false)),
  sessionEvent(
      value: 7,
      method: 'wc_sessionEvent',
      requestParam: WalletConnectMethodParams(ttl: 5 * 60, tag: 1110, prompt: true),
      responseParam: WalletConnectMethodParams(ttl: 5 * 60, tag: 1111, prompt: false)),
  sessionDelete(
      value: 8,
      method: 'wc_sessionDelete',
      requestParam:
          WalletConnectMethodParams(ttl: 24 * 60 * 60, tag: 1112, prompt: false),
      responseParam:
          WalletConnectMethodParams(ttl: 24 * 60 * 60, tag: 1113, prompt: false)),
  sessionPing(
      value: 9,
      method: 'wc_sessionPing',
      requestParam:
          WalletConnectMethodParams(ttl: 24 * 60 * 60, tag: 1114, prompt: false),
      responseParam:
          WalletConnectMethodParams(ttl: 24 * 60 * 60, tag: 1115, prompt: false)),
  sessionSettle(
      value: 10,
      method: 'wc_sessionSettle',
      requestParam: WalletConnectMethodParams(ttl: 5 * 60, tag: 1102, prompt: false),
      responseParam: WalletConnectMethodParams(ttl: 5 * 60, tag: 1103, prompt: false),
      allowReceive: false),
  sessionAuthenticate(
      value: 11,
      method: 'wc_sessionAuthenticate',
      requestParam: WalletConnectMethodParams(ttl: 60 * 60, tag: 1116, prompt: true),
      responseParam: WalletConnectMethodParams(ttl: 60 * 60, tag: 1117, prompt: false),
      reject: WalletConnectMethodParams(ttl: 5 * 60, tag: 1118, prompt: false),
      autoReject: WalletConnectMethodParams(ttl: 5 * 60, tag: 1119, prompt: false),
      allowReceive: false),

  onChainMessageComplete(
      value: 12,
      method: 'onchain_messageComplete',
      requestParam:
          WalletConnectMethodParams(ttl: 24 * 60 * 60, tag: 1106, prompt: false),
      responseParam:
          WalletConnectMethodParams(ttl: 24 * 60 * 60, tag: 1107, prompt: false),
      allowReceive: false);

  static BridgeKnownMethods fromName(String name) {
    return values.firstWhere(
      (e) => e.method == name,
      orElse: () => BridgeKnownMethods.unregisteredMethod,
    );
  }

  static BridgeKnownMethods fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw AppInternalError.internalError("BridgeKnownMethods"),
    );
  }

  final String method;
  final WalletConnectMethodParams requestParam;
  final WalletConnectMethodParams responseParam;
  final WalletConnectMethodParams? reject;
  final WalletConnectMethodParams? autoReject;
  final bool allowReceive;
  final int value;
  const BridgeKnownMethods(
      {required this.method,
      required this.requestParam,
      required this.responseParam,
      required this.value,
      this.allowReceive = true,
      this.reject,
      this.autoReject});
  bool get isPairing {
    return switch (this) {
      BridgeKnownMethods.pairingPing ||
      BridgeKnownMethods.pairingDelete ||
      BridgeKnownMethods.sessionPropose =>
        true,
      _ => false,
    };
  }

  bool get isPing {
    return switch (this) {
      BridgeKnownMethods.pairingPing || BridgeKnownMethods.sessionPing => true,
      _ => false,
    };
  }

  bool get isUnregistred => this == unregisteredMethod;
}

sealed class IRpcError {
  const IRpcError();
  Object serialize();
  IException toException();
  factory IRpcError.deserialize(Object object) {
    if (object is Map) {
      return JsonRpcError.fromJson_(JsonParser.valueEnsureAsMap<String, dynamic>(object));
    }
    return WalletRpcError.deserialize(JsonParser.valueAsBytes(object));
  }
}

class JsonRpcError extends IRpcError {
  final int? code;
  final String? message;
  final dynamic data;

  const JsonRpcError({
    required this.code,
    required this.message,
    this.data,
  });
  factory JsonRpcError.invalidRequest(String message) {
    return JsonRpcError(code: -32600, message: message);
  }
  factory JsonRpcError.methodNotFound(String message) {
    return JsonRpcError(code: -32601, message: message);
  }

  factory JsonRpcError.walletError(String message) {
    return JsonRpcError(code: -32601, message: message);
  }

  factory JsonRpcError.fromJson_(Map<String, dynamic> json) {
    return JsonRpcError(
      code: json['code'],
      message: json['message'],
      data: json['data'],
    );
  }

  @override
  Map<String, dynamic> serialize() => {
        'code': code,
        'message': message,
        'data': data,
      }.withoutNullValue;

  @override
  IException toException() {
    final message = this.message;
    if (message == null) {
      return BridgeExceptionConst.requestError;
    }
    return BridgeException(message, code: code);
  }
}

class WalletRpcError extends IRpcError {
  final IException error;
  const WalletRpcError(this.error);
  factory WalletRpcError.deserialize(List<int> bytes) {
    return WalletRpcError(IExceptionUtils.deserialize(bytes: bytes));
  }

  @override
  Object serialize() {
    return error.toCbor().encode();
  }

  @override
  IException toException() {
    return error;
  }
}

enum TransportType {
  relay(0),
  linkMode(1);

  final int value;
  const TransportType(this.value);

  bool get isLinkMode => this == linkMode;
  bool get isRelay => this == relay;
  static TransportType fromTag(int? tag) {
    return values.firstWhere(
      (e) => e.value == tag,
      orElse: () => throw BridgeExceptionConst.internalError,
    );
  }
}

abstract class ITopicResponse extends IBridgeMessage<bool> {
  @override
  final BridgeKnownMethods? method;
  const ITopicResponse({this.method})
      : super(messageType: PublishBridgeMessageType.response);
  // factory ITopicResponse.from(IResult result) {
  //   if (result.isErr) {
  //     return TopicResponseError(error: JsonRpcError.walletError(result.error));
  //   }
  //   return TopicResponseSuccess(result.unwrap());
  // }

  @override
  bool onResponse(Object? _) {
    return false;
  }

  @override
  Map<String, dynamic> serialize({int? id});
}

class TopicResponseSuccess extends ITopicResponse {
  final dynamic result;
  const TopicResponseSuccess(this.result);
  factory TopicResponseSuccess.wallet(AppSerialization response) {
    return TopicResponseSuccess(response.toCbor().encode());
  }
  @override
  Map<String, dynamic> serialize({int? id}) {
    assert(id != null, "missing response id");
    return {"result": result, "id": id, "jsonrpc": "2.0"};
  }
}

class TopicResponseError extends ITopicResponse {
  final IRpcError error;
  const TopicResponseError.web3(JsonRpcError this.error);
  TopicResponseError.wallet(IException error) : error = WalletRpcError(error);
  factory TopicResponseError.unknownMethod() {
    return TopicResponseError.web3(BridgeGenericError.invalidMethod.toRpcError());
  }
  factory TopicResponseError.unsupportedWcMethod() {
    return TopicResponseError.web3(BridgeGenericError.unsuportedWcMethod.toRpcError());
  }
  factory TopicResponseError.noMatchingKey() {
    return TopicResponseError.web3(BridgeGenericError.noMatchingKey.toRpcError());
  }
  // factory TopicResponseError.fromGenericError(BridgeGenericError err) {
  //   return TopicResponseError(error: err.toRpcError());
  // }

  @override
  Map<String, dynamic> serialize({int? id}) {
    assert(id != null, "missing response id");
    return {'id': id, 'jsonrpc': '2.0', 'error': error.serialize()};
  }
}

enum BridgeGenericError {
  invalidMethod("Invalid method.", 1001),
  userDisconnected("User disconnected.", 6000),
  unsuportedWcMethod("Unsuported wc method.", 10001),
  userRejected("User rejected.", 5000),
  unauthorizedMethod("Unauthorized method. ", 3001),
  userRejectedMethods("User rejected methods. ", 5002),
  userRejectedChains("User rejected chains. ", 5001),
  unsuportedMethod("Unsuported method. ", 5101),
  unsuportedChains("Unsuported chains. ", 5100),
  noMatchingKey("No matching key. ", 2),
  expired("Expired. ", 6);

  final String message;
  final int code;
  const BridgeGenericError(this.message, this.code);

  Map<String, dynamic> toJson() {
    return {"message": message, "code": code};
  }

  JsonRpcError toRpcError() {
    return JsonRpcError(code: code, message: message);
  }
}
