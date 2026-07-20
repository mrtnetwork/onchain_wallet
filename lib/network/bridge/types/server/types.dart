import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/bridge/exception/exception.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/types.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/topic_message.dart';
import 'package:on_chain_wallet/network/bridge/utils/id_generator.dart';

enum PublishMessageStorageType {
  memory(0),
  database(1),
  none(2),
  unknown(-1);

  final int value;
  const PublishMessageStorageType(this.value);
  static PublishMessageStorageType fromValue(int? id) {
    return values.firstWhere((e) => e.value == id, orElse: () => unknown);
  }
}

enum PublishMessageMode {
  publish(0),
  publishAndResult(1),
  unknown(-1);

  final int value;
  const PublishMessageMode(this.value);
  bool get requiredResult => this == publishAndResult;
  static PublishMessageMode fromValue(int? id) {
    return values.firstWhere((e) => e.value == id, orElse: () => unknown);
  }
}

enum RelayClientResponseType {
  error,
  request,
  subscribe,
  connect,
  disconnect;
}

enum BridgeProtocol {
  walletConnect(0),
  onChain(1);

  final int value;
  const BridgeProtocol(this.value);

  static BridgeProtocol fromValue(int? id) {
    return values.firstWhere((e) => e.value == id,
        orElse: () => throw BridgeExceptionConst.internalError);
  }
}

sealed class RelayClientResponse {
  final RelayClientResponseType type;
  final BridgeProtocol protocol = BridgeProtocol.walletConnect;
  const RelayClientResponse({required this.type});
  factory RelayClientResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey("error")) {
      return RelayClientErrorResponse.fromJson(json);
    } else if (json.containsKey("params")) {
      return RelayClientSubscribeResponse.fromJson(json);
    }
    return RelayClientRequestResponse.fromJson(json);
  }
  Map<String, dynamic> toJson();
}

class RelayClientConnectResponse extends RelayClientResponse {
  const RelayClientConnectResponse() : super(type: RelayClientResponseType.connect);

  @override
  Map<String, dynamic> toJson() {
    return {};
  }

  @override
  String toString() {
    return "RelayClientConnectResponse()";
  }
}

class RelayClientDisconnectResponse extends RelayClientResponse {
  const RelayClientDisconnectResponse() : super(type: RelayClientResponseType.disconnect);
  @override
  Map<String, dynamic> toJson() {
    return {};
  }

  @override
  String toString() {
    return "RelayClientDisconnectResponse()";
  }
}

class RelayClientSubscribeResponse extends RelayClientResponse with Equality {
  final String topic;
  final RelayClientEncryptedMessage message;
  final int id;
  final DateTime? publishedAt;
  const RelayClientSubscribeResponse(
      {required this.topic,
      required this.message,
      required this.id,
      required this.publishedAt})
      : super(type: RelayClientResponseType.subscribe);
  factory RelayClientSubscribeResponse.fromJson(Map<String, dynamic> json) {
    return RelayClientSubscribeResponse(
        topic: json["params"]["data"]["topic"],
        message:
            RelayClientEncryptedMessage.deserialize(json["params"]["data"]["message"]),
        id: json["id"],
        publishedAt: json["publishedAt"] == null
            ? null
            : DateTimeUtils.fromSecondsSinceEpoch(IntUtils.parse(json["publishedAt"])));
  }
  @override
  String toString() {
    return "RelayClientSubscribeResponse {topic: $topic}";
  }

  @override
  List get variables => [topic, message];

  @override
  Map<String, dynamic> toJson() {
    return {
      "params": {
        "data": {"topic": topic, "message": message},
      },
      "id": id,
      "publishedAt": switch (publishedAt) {
        DateTime publishedAt => DateTimeUtils.secondsSinceEpoch(publishedAt),
        _ => null
      }
    }.notNullValue;
  }
}

class RelayClientRequestResponse extends RelayClientResponse {
  final dynamic result;
  final BigInt id;
  final String? method;
  const RelayClientRequestResponse(
      {required this.result, required this.id, required this.method})
      : super(type: RelayClientResponseType.request);
  factory RelayClientRequestResponse.fromJson(Map<String, dynamic> json) {
    return RelayClientRequestResponse(
        result: json["result"],
        id: json.valueAsBigInt("id"),
        method: json.valueAs("method"));
  }

  @override
  String toString() {
    return "RelayClientRequestResponse {method: $method, result: $result}";
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "id": id.toString(),
      "method": method,
      "result": result,
      "jsonrpc": "2.0",
    }.notNullValue;
  }
}

class RelayClientErrorResponse extends RelayClientResponse {
  final int code;
  final String message;
  final BigInt id;
  final String? method;
  const RelayClientErrorResponse(
      {required this.code, required this.message, required this.id, required this.method})
      : super(type: RelayClientResponseType.error);
  factory RelayClientErrorResponse.fromJson(Map<String, dynamic> json) {
    return RelayClientErrorResponse(
        code: json["error"]["code"],
        id: json.valueAsBigInt("id"),
        message: json["error"]["message"],
        method: json["method"]);
  }
  @override
  Map<String, dynamic> toJson() {
    return {
      "error": {
        "code": code,
        "message": message,
      },
      "id": id.toString(),
      "method": method,
      "jsonrpc": "2.0",
    }.notNullValue;
  }

  @override
  String toString() {
    return "RelayClientErrorResponse {method: $method, message: $message}";
  }
}

enum WalletConnectRelayClientMethods {
  publish('publish'),
  subscription('subscription'),
  subscribe('subscribe'),
  unsubscribe('unsubscribe'),
  unknown(""),
  ;

  final String method;
  const WalletConnectRelayClientMethods(this.method);

  String get withProtocol => "irn_$method";
  static WalletConnectRelayClientMethods fromName(String? name) {
    return values.firstWhere(
      (e) => e.name == name || e.withProtocol == name,
      orElse: () => WalletConnectRelayClientMethods.unknown,
    );
  }
}

enum PublishMessageStatus {
  pending(0),
  published(1),
  error(2),
  complete(3);

  bool get isPublished => this == published || this == complete;
  bool get isError => this == error;
  bool get isComplete => this == complete;
  final int value;
  const PublishMessageStatus(this.value);
  bool get isPending => this == pending;
  bool get allowUpdateStatus => this == pending || this == published;
}

class RelayClientPublish extends RelayClientRequest
    with AppSerialization, PartialEquality {
  final String topic;
  final String message;
  final int ttl;
  final int tag;
  final int correlationId;
  final DateTime expired;
  final PublishMessageStorageType storageType;
  final PublishMessageMode mode;
  final BridgeProtocol protocol;
  final BridgeKnownMethods? bridgeMethod;
  final BridgeSession? session;

  bool isExpired() {
    return expired.isBefore(DateTime.now());
  }

  @override
  List<dynamic> get parts => [topic, message, correlationId];

  RelayClientPublish._({
    required this.tag,
    required this.topic,
    required this.correlationId,
    required this.message,
    required this.ttl,
    required this.storageType,
    required this.mode,
    required this.expired,
    required this.protocol,
    this.bridgeMethod,
    this.session,
    super.id,
  }) : super(method: WalletConnectRelayClientMethods.publish);

  RelayClientPublish copyWith(
      {int? tag,
      String? topic,
      int? correlationId,
      String? message,
      int? ttl,
      PublishMessageStorageType? storageType,
      PublishMessageMode? mode,
      DateTime? expired,
      BigInt? id,
      BridgeProtocol? protocol,
      BridgeKnownMethods? bridgeMethod,
      BridgeSession? session}) {
    return RelayClientPublish._(
      tag: tag ?? this.tag,
      topic: topic ?? this.topic,
      correlationId: correlationId ?? this.correlationId,
      message: message ?? this.message,
      ttl: ttl ?? this.ttl,
      storageType: storageType ?? this.storageType,
      mode: mode ?? this.mode,
      expired: expired ?? this.expired,
      id: id ?? this.id,
      protocol: protocol ?? this.protocol,
      bridgeMethod: bridgeMethod ?? this.bridgeMethod,
      session: session ?? this.session,
    );
  }

  RelayClientPublish({
    required this.tag,
    required this.topic,
    required this.correlationId,
    required this.message,
    required this.ttl,
    required this.storageType,
    required this.mode,
    // required this.type,
    required this.protocol,
    this.bridgeMethod,
    this.session,
    super.id,
  })  : expired = DateTime.now().add(Duration(seconds: ttl)),
        super(method: WalletConnectRelayClientMethods.publish);

  factory RelayClientPublish.deserialize({List<int>? bytes, CborTagValue? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.wcPendigMessage);
    return RelayClientPublish(
        message: values.rawValueAt(0),
        ttl: values.rawValueAt(1),
        topic: values.rawValueAt(2),
        tag: values.rawValueAt(3),
        correlationId: values.rawValueAt(4),
        storageType: PublishMessageStorageType.fromValue(values.rawValueAt(5)),
        mode: PublishMessageMode.fromValue(values.rawValueAt(6)),
        protocol: BridgeProtocol.fromValue(values.rawValueAt(7)),
        id: values.rawValueAt(8),
        bridgeMethod: values.maybeRawValueAt<BridgeKnownMethods, int>(
            9, (v) => BridgeKnownMethods.fromValue(v)),
        session: values.maybeObjectAt<BridgeSession, CborTagValue>(
            10, (v) => BridgeSession.deserialize(object: v)));
  }
  factory RelayClientPublish.fromJson(Map<String, dynamic> json) {
    return RelayClientPublish(
        tag: json.valueAs("tag"),
        topic: json.valueAs("topic"),
        correlationId: json.valueAs("correlationId"),
        message: json.valueAs("message"),
        ttl: json.valueAs("ttl"),
        storageType: PublishMessageStorageType.unknown,
        mode: PublishMessageMode.unknown,
        protocol: BridgeProtocol.walletConnect,
        id: json.valueAsBigInt("id"));
  }

  @override
  Map<String, dynamic> toParams() {
    return {
      'message': message,
      'ttl': ttl,
      'topic': topic,
      'tag': tag,
      'correlationId': correlationId,
      'id': id.toString()
    };
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.wcPendigMessage;

  @override
  List<CborObject?> get serializationItems => [
        message.toCbor(),
        ttl.toCbor(),
        topic.toCbor(),
        tag.toCbor(),
        correlationId.toCbor(),
        storageType.value.toCbor(),
        mode.value.toCbor(),
        protocol.value.toCbor(),
        id.toCbor(),
        bridgeMethod?.value.toCbor(),
        session?.toCbor()
      ];

  @override
  RelayClientResponse toResponse() {
    if (isExpired()) {
      return RelayClientErrorResponse(
          id: id,
          method: method.name,
          code: BridgeErrors.expired.code,
          message: BridgeErrors.expired.message);
    }
    return RelayClientRequestResponse(id: id, method: method.name, result: {});
  }

  Map<String, dynamic> toSubscribeJson({DateTime? publishedAt}) {
    publishedAt ??= DateTime.now();
    return {
      "params": {
        "data": {"topic": topic, "message": message},
      },
      "id": correlationId,
      "publishedAt": DateTimeUtils.secondsSinceEpoch(publishedAt)
    }.notNullValue;
  }
}

sealed class RelayClientRequest {
  final BigInt id;
  final WalletConnectRelayClientMethods method;
  RelayClientRequest({required this.method, BigInt? id})
      : id = id ?? WCNextIdGenerator.nextRandomRpcId();

  factory RelayClientRequest.fromJson(Map<String, dynamic> json) {
    final method = WalletConnectRelayClientMethods.fromName(json.valueAs("method"));
    final id = json.valueAs<BigInt?>("id");
    return switch (method) {
      WalletConnectRelayClientMethods.publish =>
        RelayClientPublish.fromJson(json.valueEnsureAsMap<String, dynamic>("params")),
      WalletConnectRelayClientMethods.subscribe => RelayClientSubscribe.fromJson(
          json.valueEnsureAsMap<String, dynamic>("params"),
          id: id),
      WalletConnectRelayClientMethods.subscription =>
        RelayClientSubscribtion(params: json.valueAs("params"), id: id),
      WalletConnectRelayClientMethods.unsubscribe =>
        RelayClientSubscribe.fromJson(json.valueEnsureAsMap<String, dynamic>("params")),
      WalletConnectRelayClientMethods.unknown =>
        RelayClientUnknown(params: json.valueAs("params"), id: id),
    };
  }

  Object? toParams();
  Map<String, dynamic> toRelayMessage() {
    final params = toParams();
    return {
      "jsonrpc": "2.0",
      "method": method.withProtocol,
      if (params != null) "params": params,
      "id": id.toString()
    };
  }

  RelayClientResponse toResponse();
}

class RelayClientSubscribe extends RelayClientRequest {
  final String topic;
  RelayClientSubscribe({required this.topic, super.id})
      : super(method: WalletConnectRelayClientMethods.subscribe);
  factory RelayClientSubscribe.fromJson(Map<String, dynamic> json, {BigInt? id}) {
    return RelayClientSubscribe(topic: json.valueAs("topic"), id: id);
  }

  @override
  Map<String, dynamic> toParams() {
    return {"topic": topic};
  }

  @override
  RelayClientResponse toResponse() {
    return RelayClientRequestResponse(id: id, method: method.name, result: {});
  }
}

class RelayClientUnsubscribe extends RelayClientRequest {
  final String topic;
  RelayClientUnsubscribe({required this.topic, super.id})
      : super(method: WalletConnectRelayClientMethods.unsubscribe);
  factory RelayClientUnsubscribe.fromJson(Map<String, dynamic> json) {
    return RelayClientUnsubscribe(topic: json.valueAs("topic"));
  }
  @override
  Map<String, dynamic> toParams() {
    return {"topic": topic};
  }

  @override
  RelayClientResponse toResponse() {
    return RelayClientRequestResponse(id: id, method: method.name, result: {});
  }

  @override
  String toString() {
    return "RelayClientUnsubscribe{topic:$topic}";
  }
}

class RelayClientUnknown extends RelayClientRequest {
  final Object? params;
  RelayClientUnknown({required this.params, super.id})
      : super(method: WalletConnectRelayClientMethods.unknown);

  @override
  Object? toParams() {
    return params;
  }

  @override
  RelayClientResponse toResponse() {
    return RelayClientErrorResponse(
        id: id,
        method: method.name,
        code: BridgeErrors.invalidMethod.code,
        message: BridgeErrors.invalidMethod.message);
  }

  @override
  String toString() {
    return "RelayClientUnknown{params:$params}";
  }
}

class RelayClientSubscribtion extends RelayClientRequest {
  final Object? params;
  RelayClientSubscribtion({required this.params, super.id})
      : super(method: WalletConnectRelayClientMethods.subscription);

  @override
  Object? toParams() {
    return params;
  }

  @override
  RelayClientResponse toResponse() {
    return RelayClientErrorResponse(
        id: id,
        method: method.name,
        code: BridgeErrors.invalidMethod.code,
        message: BridgeErrors.invalidMethod.message);
  }

  @override
  String toString() {
    return "RelayClientSubscribtion{params:$params}";
  }
}

enum BridgeErrors {
  invalidMethod("Invalid method.", 1001),
  expired("Expired. ", 6);

  final String message;
  final int code;
  const BridgeErrors(this.message, this.code);

  Map<String, dynamic> toJson() {
    return {"message": message, "code": code};
  }
}

class ClientPublishMessage with AppSerialization, Equality {
  final RelayClientPublish message;
  final String clientId;
  final DateTime publishedAt;
  String get messageId => "${clientId}_${message.correlationId}";
  ClientPublishMessage(
      {required this.message, required this.clientId, DateTime? publishedAt})
      : publishedAt = publishedAt ?? DateTime.now();
  factory ClientPublishMessage.deserialize({CborObject? object, List<int>? bytes}) {
    final values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: AppSerializationIdentifier.bridgeMessage,
    );
    return ClientPublishMessage(
        message: RelayClientPublish.deserialize(object: values.objectAt(0)),
        clientId: values.rawValueAt(1),
        publishedAt: values.rawValueAt(2));
  }

  String toSubscribtionResponse() {
    return StringUtils.fromJson(message.toSubscribeJson(publishedAt: publishedAt));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.bridgeMessage;

  @override
  List<CborObject?> get serializationItems =>
      [message.toCbor(), clientId.toCbor(), publishedAt.toCbor()];

  @override
  List<dynamic> get variables => [message, clientId, publishedAt];
}
