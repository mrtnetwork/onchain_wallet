import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/bridge/exception/exception.dart';
import 'package:on_chain_wallet/network/bridge/types/server/types.dart';
import 'package:on_chain_wallet/network/bridge/constants/constants.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/topic_message.dart';
import 'package:on_chain_wallet/network/bridge/utils/id_generator.dart';
import 'package:on_chain_wallet/network/bridge/types/wallet_connect/types.dart';
import 'package:on_chain_wallet/network/bridge/utils/utils.dart';
import 'package:on_chain_wallet/context/core/context.dart';

typedef TypeCbSerializeBridgeMessage = Future<String> Function(
    IBridgeSession session, Map<String, dynamic> payload);

enum BridgeEventTarget {
  web3,
  onchain,
}

abstract class IBridgeEvent {
  final BridgeEventTarget target;
  const IBridgeEvent(this.target);
}

abstract class IBrdigeAction<RESPONSE extends Object?> extends IBridgeMessage<RESPONSE> {
  @override
  final BridgeKnownMethods method;
  const IBrdigeAction({required this.method, required super.messageType});
}

abstract class IBridgeMessage<RESPONSE extends Object?> {
  final BridgeMessageType messageType;
  BridgeKnownMethods? get method;
  const IBridgeMessage({required this.messageType});
  Object serialize();
  RESPONSE onResponse(Object? result);
  T cast<T extends IBridgeMessage>() {
    if (this is! T) {
      throw BridgeExceptionConst.internalError;
    }
    return this as T;
  }
}

sealed class IBridgeRequest<REQUEST extends RelayClientRequest> {
  final BigInt id;
  final IBridgeSession session;
  const IBridgeRequest({required this.id, required this.session});
  BridgeProtocol get protocol => session.protocol;
  FutureOr<REQUEST> toPublishMessage(TypeCbSerializeBridgeMessage onSerializeMessage);
  Future<IResult<T?>> waitOnResult<T>();
  Future<void> response(dynamic result);

  Future<void> error(IException err);
}

sealed class BridgeRequestTopic<REQUEST extends RelayClientRequest>
    extends IBridgeRequest<REQUEST> with Equality {
  BridgeRequestTopic({required super.session})
      : super(id: session.idGenerator.nextRpcId());

  @override
  FutureOr<REQUEST> toPublishMessage(TypeCbSerializeBridgeMessage onSerializeMessage);

  Completer<IResult>? _completer;

  @override
  Future<IResult<T?>> waitOnResult<T>(
      {Duration timeout = BridgeConstants.relayMessageResponseTimeout}) async {
    assert(_completer == null);
    final completer = _completer ??= Completer<IResult>();
    final result = await completer.future.timeout(
      timeout,
      onTimeout: () {
        return ResultErr.fromException(BridgeExceptionConst.topicSubscribtionTimeout);
      },
    );
    return result.map<T>(JsonParser.valueAs);
  }

  @override
  Future<void> error(IException err) async {
    final completer = _completer;
    _completer = null;
    completer?.complete(ResultErr.fromException(err));
  }

  @override
  Future<void> response(result) async {
    final completer = _completer;
    _completer = null;
    completer?.complete(ResultOk(result));
  }

  @override
  List<dynamic> get variables => [session];
}

class BridgeRequestSubscribe extends BridgeRequestTopic<RelayClientSubscribe>
    with Equality {
  BridgeRequestSubscribe({required super.session}) : super();

  @override
  FutureOr<RelayClientSubscribe> toPublishMessage(
      TypeCbSerializeBridgeMessage onSerializeMessage) {
    return RelayClientSubscribe(topic: session.topic, id: id);
  }

  @override
  String toString() {
    return "BridgeRequestSubscribe({topic:${session.topic}, id:$id, type:${session.type}})";
  }
}

class BridgeRequestUnsubscribe extends BridgeRequestTopic<RelayClientUnsubscribe>
    with Equality {
  BridgeRequestUnsubscribe({required super.session}) : super();

  @override
  FutureOr<RelayClientUnsubscribe> toPublishMessage(
      TypeCbSerializeBridgeMessage onSerializeMessage) {
    return RelayClientUnsubscribe(topic: session.topic, id: id);
  }

  @override
  String toString() {
    return "BridgeRequestUnsubscribe({topic:${session.topic}, id:$id, type:${session.type}})";
  }
}

class BridgeRequestMessage extends IBridgeRequest<RelayClientPublish> {
  final IBridgeMessage? message;
  final int correlationId;
  final PublishMessageStorageType storageType;
  final PublishMessageMode mode;
  PublishMessageStatus _status = PublishMessageStatus.pending;
  PublishMessageStatus get status => _status;
  RelayClientPublish? _clientMessage;
  final _lock = SafeAtomicLock();
  BridgeRequestMessage._(
      {required this.message,
      required this.correlationId,
      required super.session,
      required super.id,
      RelayClientPublish? clientMessage,
      PublishMessageStatus? status,
      this.storageType = PublishMessageStorageType.memory,
      this.mode = PublishMessageMode.publish})
      : _status = status ?? PublishMessageStatus.pending,
        _clientMessage = clientMessage;
  factory BridgeRequestMessage.fromPublishMessage({
    required RelayClientPublish message,
    required IBridgeSession session,
  }) {
    assert(message.topic == session.topic,
        "Invalid topic or clientId. message: ${message.topic}. session: ${session.topic}/${session.clientId}");
    return BridgeRequestMessage._(
        message: null,
        correlationId: message.correlationId,
        session: session,
        id: message.id,
        mode: message.mode,
        storageType: message.storageType,
        clientMessage: message);
  }
  factory BridgeRequestMessage.action({
    required IBrdigeAction action,
    int? fixedId,
    required IBridgeSession session,
    PublishMessageMode mode = PublishMessageMode.publishAndResult,
    PublishMessageStorageType? storage,
  }) {
    storage ??= switch (action.method.isPairing || action.method.isPing) {
      true => PublishMessageStorageType.memory,
      false => PublishMessageStorageType.database
    };
    return BridgeRequestMessage._(
        message: action,
        correlationId: session.idGenerator.nextPayloadId(action.messageType),
        // correlationId: switch (fixedId) {
        //   int id => session.idGenerator.fixedId(action.messageType, id),
        //   _ => session.idGenerator.nextId(action.messageType),
        // },
        session: session,
        mode: mode,
        storageType: storage,
        id: session.idGenerator.nextRpcId());
  }
  factory BridgeRequestMessage.response({
    required ITopicResponse response,
    required IBridgeSession session,
    required int correlationId,
    PublishMessageMode mode = PublishMessageMode.publish,
    PublishMessageStorageType? storage,
  }) {
    storage ??= switch (response.method) {
      null => PublishMessageStorageType.database,
      BridgeKnownMethods method => switch (method.isPairing ||
            method.isPing ||
            method.isUnregistred ||
            !method.allowReceive) {
          true => PublishMessageStorageType.memory,
          false => PublishMessageStorageType.database
        },
    };
    return BridgeRequestMessage._(
      message: response.cast(),
      correlationId: correlationId,
      session: session,
      mode: mode,
      storageType: storage,
      // id: DateTime.now().subtract(Duration(days: 250)).millisecondsSinceEpoch
      id: session.idGenerator.nextRpcId(),
    );
  }

  Map<String, dynamic>? _toPublishMessageJson() {
    final bridgeMessage = message;
    if (bridgeMessage == null) return null;
    return switch (bridgeMessage.messageType) {
      PublishBridgeMessageType.response =>
        bridgeMessage.cast<ITopicResponse>().serialize(id: correlationId),
      _ => {
          "method": bridgeMessage.method?.method,
          "id": correlationId,
          "params": bridgeMessage.serialize(),
          "jsonrpc": "2.0",
        },
    };
  }

  @override
  Future<RelayClientPublish> toPublishMessage(
      TypeCbSerializeBridgeMessage onSerializeMessage) async {
    final message = _clientMessage;
    if (message != null) return message;
    final bridgeMessage = this.message;
    final toJson = _toPublishMessageJson();
    if (toJson == null || bridgeMessage == null) {
      throw BridgeExceptionConst.internalError;
    }
    final serializeMessage = await onSerializeMessage(session, toJson);
    WalletConnectMethodParams? opts = switch (bridgeMessage.messageType) {
      PublishBridgeMessageType.response =>
        bridgeMessage.method?.reject ?? bridgeMessage.method?.responseParam,
      _ => bridgeMessage.method?.requestParam,
    };
    final ttl = opts?.ttl ?? WalletConnectMethodParams.defaultTll;
    final tag = opts?.tag ?? WalletConnectMethodParams.runtimeTag;
    return _clientMessage = RelayClientPublish(
        topic: session.topic,
        message: serializeMessage,
        storageType: storageType,
        protocol: protocol,
        mode: mode,
        ttl: ttl,
        tag: tag,
        correlationId: correlationId,
        id: id,
        bridgeMethod: bridgeMessage.method,
        session: switch (bridgeMessage.messageType) {
          Web3BridgeMessageType.delete => BridgeSession.from(session),
          _ => null
        });
  }

  IResult<RelayClientPublish> get clientMessage {
    final message = _clientMessage;
    if (message == null) {
      return ResultErr.fromException(BridgeExceptionConst.internalError)
        ..logError(
            runtime: runtimeType,
            function: "clientMessage",
            msg: "Encrypted message missing.");
    }
    return ResultOk(message);
  }

  Completer<IResult>? _completer;
  Future<void> _setError() async {
    await _lock.run(() {
      if (status.allowUpdateStatus) {
        _status = PublishMessageStatus.error;
      }
    });
  }

  Future<Completer<IResult>?> _getCompleter() async {
    return _lock.run(() {
      switch (status) {
        case PublishMessageStatus.pending:
        case PublishMessageStatus.published:
          final completer = _completer = Completer<IResult>();
          return completer;
        default:
          return null;
      }
    });
  }

  @override
  Future<IResult<T?>> waitOnResult<T>() async {
    final clientMessage = this.clientMessage;
    return clientMessage.andThenAsync((clientMessage) async {
      Duration? timeout() {
        final n = clientMessage.expired.millisecondsSinceEpoch -
            DateTime.now().millisecondsSinceEpoch;
        if (n <= 0) {
          return null;
        }
        return Duration(milliseconds: n);
      }

      switch (status) {
        case PublishMessageStatus.pending:
        case PublishMessageStatus.published:
          final completer = await _getCompleter();
          if (completer == null) {
            return ResultErr<T>.fromException(
                BridgeExceptionConst.badPublishMessageStatus);
          }
          final result = await completer.future.timeout(
            timeout() ?? Duration.zero,
            onTimeout: () {
              _completer = null;
              return ResultErr<T>.fromException(
                  BridgeExceptionConst.publishMessageExpired);
            },
          );
          if (result.isErr) {
            await _setError();
            return result.cast<T>();
          }
          if (!mode.requiredResult) {
            return ResultOk<T?>(null);
          }
          if (status.isComplete) {
            return result.map<T>(
              (e) => JsonParser.valueAs<T>(e),
            );
          }
          return waitOnResult<T>();
        case PublishMessageStatus.error:
          return ResultErr<T>.fromException(BridgeExceptionConst.publishMessageError);
        case PublishMessageStatus.complete:
          if (mode.requiredResult) {
            return ResultErr<T>.fromException(
                BridgeExceptionConst.badPublishMessageStatus);
          }
          return ResultOk<T?>(null);
      }
    });
  }

  @override
  Future<void> response(dynamic result) async {
    await _lock.run(() async {
      if (status.allowUpdateStatus) {
        if (status.isPublished || (status.isPending && !mode.requiredResult)) {
          _status = PublishMessageStatus.complete;
        } else {
          _status = PublishMessageStatus.published;
        }
      }
      final completer = _completer;
      _completer = null;
      completer?.complete(ResultOk(result));
    });
  }

  @override
  Future<void> error(IException err) async {
    await _lock.run(() async {
      if (status.allowUpdateStatus) {
        _status = PublishMessageStatus.error;
      }
      final completer = _completer;
      _completer = null;
      completer?.complete(ResultErr.fromException(err));
    });
  }

  @override
  String toString() {
    return "BridgeRequestMessage {topic:${session.topic}, correlationId:$correlationId,"
        " method:${message?.method?.name ?? _clientMessage?.bridgeMethod?.name}, message:${_toPublishMessageJson()}}"
        " storageType: $storageType, status: ${status.name}";
  }
}

enum BridgeSessionType {
  pairingWb3(0),
  pairingOnChain(1),
  web3(2),
  onChain(3);

  bool get isPairing => this == pairingWb3 || this == pairingOnChain;
  final int value;
  const BridgeSessionType(this.value);
  static BridgeSessionType fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw AppInternalError.internalError("BridgeSessionType"),
    );
  }
}

abstract class IBridgeSession with Equality {
  final List<int> symKey;
  final String topic;
  final BridgeSessionType type;
  final BridgeProtocol protocol;
  WCNextIdGenerator get idGenerator;
  IBridgeSession({
    required List<int> symKey,
    required String topic,
    required this.type,
    required this.protocol,
  })  : symKey = symKey.exc(
            length: 32,
            operation: "IBridgeSession",
            onErr: () => throw BridgeExceptionConst.internalError),
        topic = StringUtils.normalizeHex(topic);
  int get clientId => idGenerator.clientId;

  T cast<T extends IBridgeSession>() {
    if (this is! T) {
      throw BridgeExceptionConst.internalError;
    }
    return this as T;
  }

  @override
  List<dynamic> get variables => [topic];
}

class BridgeSession extends IBridgeSession with AppSerialization {
  @override
  final WCNextIdGenerator idGenerator;
  BridgeSession({
    required super.symKey,
    required super.topic,
    required super.type,
    required super.protocol,
    WCNextIdGenerator? idGenerator,
  })  : idGenerator = idGenerator ?? WCNextIdGenerator(0),
        super();
  factory BridgeSession.from(IBridgeSession session) {
    return BridgeSession(
        symKey: session.symKey,
        topic: session.topic,
        type: session.type,
        protocol: session.protocol);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;
  factory BridgeSession.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag,
        cborBytes: bytes,
        cborObject: object);
    return BridgeSession(
        symKey: values.rawValueAt(0),
        topic: values.rawValueAt(1),
        type: BridgeSessionType.fromValue(values.rawValueAt(2)),
        protocol: BridgeProtocol.fromValue(values.rawValueAt(3)));
  }

  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(symKey),
        topic.toCbor(),
        type.value.toCbor(),
        protocol.value.toCbor()
      ];
}

class BridgeClientConfig {
  final String wcBridgeUrl;
  final String wcProjectId;
  final String onChainBridgeUrl;
  final String onChainProjectId;
  final AppContext context;
  const BridgeClientConfig(
      {this.wcBridgeUrl = BridgeConstants.wcRelayUrl,
      this.wcProjectId = BridgeConstants.wcProjectId,
      this.onChainBridgeUrl = "",
      this.onChainProjectId = "",
      required this.context});
}

class BridgeUri {
  final String protocol;
  final String topic;
  final List<String> methods;
  final List<int> symkey;
  final DateTime expire;
  final WCProtocolOptions relay;
  final int version;

  Duration? timeout() {
    final n = expire.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch;
    if (n <= 0) return null;
    return Duration(milliseconds: n);
  }

  BridgeUri({
    required this.topic,
    this.protocol = BridgeConstants.wcProtocol,
    this.methods = const [],
    required this.symkey,
    DateTime? expire,
    WCProtocolOptions? relay,
    this.version = BridgeConstants.wcDefaultVersion,
  })  : expire = expire ?? BridgeUtils.wcDefaultPairExpireTime(),
        relay = WCProtocolOptions();
}

enum BrdigeMessageTypes {
  wcType0(0),
  wcType1(1),
  wcType2(2);

  final int tag;
  bool get supported => this == wcType0;
  const BrdigeMessageTypes(this.tag);
  static BrdigeMessageTypes fromTag(int? tag) {
    return values.firstWhere((e) => e.tag == tag,
        orElse: () => throw BridgeExceptionConst.internalError);
  }
}

class RelayClientEncryptedMessage {
  final List<int> sealed;
  final List<int> nonce;
  final List<int>? senderPublicKey;
  final int identifier;
  final BrdigeMessageTypes type;

  String serialize() {
    List<int> serializeBytes;
    switch (type) {
      case BrdigeMessageTypes.wcType0:
        serializeBytes = [type.tag, ...nonce, ...sealed];
        break;
      case BrdigeMessageTypes.wcType1:
        final senderPublicKey = this.senderPublicKey;
        if (senderPublicKey == null) {
          throw BridgeException('Missing sender public key for type 1 envlope.');
        }
        serializeBytes = [type.tag, ...senderPublicKey, ...nonce, ...sealed];
        break;
      case BrdigeMessageTypes.wcType2:
        serializeBytes = [type.tag, ...sealed];
        break;
    }
    return StringUtils.decode(serializeBytes, encoding: StringEncoding.base64);
  }

  RelayClientEncryptedMessage(
      {required this.type,
      required List<int> sealed,
      required List<int> nonce,
      List<int>? publickKey})
      : sealed = sealed.asImmutableBytes,
        nonce = nonce.asImmutableBytes,
        senderPublicKey = publickKey?.asImmutableBytes,
        identifier = Crc32().quickIntDigest(sealed);
  factory RelayClientEncryptedMessage.deserialize(String b64) {
    final decode = StringUtils.encode(b64,
        validateB64Padding: false, encoding: StringEncoding.base64);
    final type = BrdigeMessageTypes.fromTag(decode.elementAtOrNull(0));
    switch (type) {
      case BrdigeMessageTypes.wcType0:
        return RelayClientEncryptedMessage(
            sealed: decode
                .sublist(BridgeConstants.messageTypeLength + BridgeConstants.nonceLength),
            nonce: decode.sublist(BridgeConstants.messageTypeLength,
                BridgeConstants.messageTypeLength + BridgeConstants.nonceLength),
            type: type);
      case BrdigeMessageTypes.wcType2:
        return RelayClientEncryptedMessage(
            publickKey: null,
            nonce: QuickCrypto.generateRandom(BridgeConstants.nonceLength),
            sealed: decode.sublist(BridgeConstants.messageTypeLength),
            type: type);
      case BrdigeMessageTypes.wcType1:
        final publickKey = decode.sublist(BridgeConstants.messageTypeLength,
            Ed25519KeysConst.pubKeyByteLen + BridgeConstants.messageTypeLength);
        return RelayClientEncryptedMessage(
            publickKey: publickKey,
            nonce: decode.sublist(
                Ed25519KeysConst.pubKeyByteLen + BridgeConstants.messageTypeLength,
                Ed25519KeysConst.pubKeyByteLen +
                    BridgeConstants.messageTypeLength +
                    BridgeConstants.nonceLength),
            sealed: decode.sublist(
              Ed25519KeysConst.pubKeyByteLen +
                  BridgeConstants.messageTypeLength +
                  BridgeConstants.nonceLength,
            ),
            type: type);
    }
  }
}
