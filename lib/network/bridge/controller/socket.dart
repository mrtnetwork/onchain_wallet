import 'dart:async';

import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/bridge/exception/exception.dart';
import 'package:on_chain_wallet/network/bridge/types/server/types.dart';
import 'package:on_chain_wallet/network/bridge/core/core.dart';
import 'package:on_chain_wallet/network/bridge/socket/service.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/socket.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/types.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/topic_message.dart';

mixin IBridgeSocketController on IBridgeCore {
  void onPublishMessageStatusChanged(IBridgeRequest message);

  Future<IResult<BridgeServerUrl>> generateUrl(BridgeProtocol protocol);
  late final BridgeSocketService _walletConnecet = BridgeSocketService(
      onGenerateUrl: generateUrl,
      protocol: BridgeProtocol.walletConnect,
      context: context);
  late final BridgeSocketService _local = BridgeSocketService(
      onGenerateUrl: generateUrl, protocol: BridgeProtocol.onChain, context: context);
  final _lock = SafeAtomicLock();
  final Map<BigInt, IBridgeRequest> _publishedMessage = {};
  final Map<int, BridgeRequestMessage> _pendingResults = {};
  final List<IBridgeSession> _activeTopics = [];
  StreamSubscription<RelayClientResponse>? _walletConnecetSub;
  StreamSubscription<RelayClientResponse>? _localSub;
  final Set<int> _proccessedMessage = {};

  @override
  StreamValue<SocketConnectionStatus> connectionStatus(BridgeProtocol protocol) =>
      _walletConnecet.statusStream;

  @override
  void onPairingPingMessage(TopicMessagePairing message) {
    super.onPairingPingMessage(message);
    publish(BridgeRequestMessage.response(
        response: TopicResponseSuccess(true),
        session: message.session,
        correlationId: message.message.id));
    Logging.info(
        fn: () => AppLogData(
            runtime: runtimeType,
            function: "onPairingPingMessage",
            msg: "New pairing message. topic: ${message.session.topic}"));
  }

  @override
  void onSessionPingMessage(TopicMessageRequest message) {
    super.onSessionPingMessage(message);
    publish(BridgeRequestMessage.response(
        response: TopicResponseSuccess(true),
        session: message.session,
        correlationId: message.message.id));
    Logging.info(
        fn: () => AppLogData(
            runtime: runtimeType,
            function: "onSessionPingMessage",
            msg: "Session ping. topic: ${message.session.topic}"));
  }

  @override
  void onConnect(BridgeProtocol protocol) {
    super.onConnect(protocol);
    final messages = [
      ..._publishedMessage.values.where((e) => e.protocol == protocol),
      ..._pendingResults.values.where((e) => e.protocol == protocol),
    ];
    for (final i in messages) {
      _publish(i);
    }
    Logging.info(
        fn: () => AppLogData(
            runtime: runtimeType,
            function: "onConnect",
            msg: "Protocol connected: $protocol pending messages ${messages.length}"));
  }

  @override
  void onDisconnect(BridgeProtocol protocol) {
    super.onDisconnect(protocol);
    final exitMessages = _publishedMessage.values.toList();
    for (final i in exitMessages) {
      if (i case BridgeRequestTopic()) {
        _publishedMessage.remove(i.id);
      }
    }
    _activeTopics.clear();
    Logging.info(
        fn: () => AppLogData(
            runtime: runtimeType,
            function: "onDisconnect",
            msg: "Protocol disconnected: $protocol"));
  }

  @override
  void onRelayMessage(RelayClientResponse message) {
    Logging.info(
        fn: () => AppLogData(
            runtime: runtimeType, function: "onRelayMessage", msg: "message:$message"));
    switch (message) {
      case RelayClientRequestResponse(:final id, :final result):
        final msg = _publishedMessage.remove(id);
        switch (msg) {
          case BridgeRequestSubscribe():
            msg.response(result);
            _activeTopics.add(msg.session);

            break;
          case BridgeRequestMessage():
            msg.response(result);
            if (msg.mode.requiredResult) {
              _pendingResults[msg.correlationId] = msg;
            }
            break;
          case BridgeRequestUnsubscribe(:final session):
            _activeTopics.removeWhere((e) => e.topic == session.topic);
            break;
          case null:
            break;
        }
        return;
      case RelayClientErrorResponse(:final id, :final code, :final message):
        final msg = _publishedMessage.remove(id);
        if (msg case BridgeRequestSubscribe(:final session)) {
          _activeTopics.removeWhere((e) => e.topic == session.topic);
        }
        msg?.error(BridgeException(message, code: code));
        return;
      case RelayClientConnectResponse():
        onConnect(message.protocol);
        break;
      case RelayClientDisconnectResponse():
        onDisconnect(message.protocol);
        break;
      case RelayClientSubscribeResponse():
        _onSubscribeMessage(message);
        break;
    }
  }

  Future<IResult<void>> _publish(IBridgeRequest message) async {
    switch (message) {
      case BridgeRequestSubscribe():
        if (_activeTopics.contains(message.session)) {
          message.response(null);
          _publishedMessage.remove(message.id);
          return ResultOk.okVoid;
        }
        break;
      case BridgeRequestMessage(:final status):
        if (!status.isPending) return ResultOk.okVoid;
        break;
      case BridgeRequestUnsubscribe():
        if (!_activeTopics.contains(message.session)) {
          message.response(null);
          _publishedMessage.remove(message.id);
          return ResultOk.okVoid;
        }
    }
    final msg = await toPublishMessage(message);
    final result = switch (message.protocol) {
      BridgeProtocol.walletConnect => await _walletConnecet.sendMessage(msg),
      BridgeProtocol.onChain => await _local.sendMessage(msg),
    };
    Logging.info(
        fn: () => AppLogData(
            runtime: runtimeType,
            function: "_publish",
            msg: "Message published: ${message.id}",
            err: result.err()?.exception));
    return result;
  }

  @override
  Future<IResult<T?>> publish<T>(IBridgeRequest message) async {
    Logging.info(
        fn: () => AppLogData(
            runtime: runtimeType,
            function: "publish",
            msg: "Publis new message:$message"));
    final id = message.id;
    if (!_publishedMessage.containsKey(id)) {
      final _ = await message.toPublishMessage(_serializeMessage);
      _publishedMessage[id] = message;
      onPublishMessageStatusChanged(message);
    }
    await _publish(message);
    try {
      return await message.waitOnResult<T>();
    } finally {
      _publishedMessage.remove(id);
      onPublishMessageStatusChanged(message);
    }
  }

  @override
  Future<IResult<void>> subscribe<T>(IBridgeSession session) async {
    final result = await publish(BridgeRequestSubscribe(session: session));
    return result.map<void>((_) {});
  }

  @override
  Future<IResult<void>> unSubscribe<T>(IBridgeSession session) async {
    _activeTopics.remove(session);
    final result = await publish(BridgeRequestUnsubscribe(session: session));
    return result.map<void>((_) {});
  }

  Future<void> _onSubscribeMessage(RelayClientSubscribeResponse message) async {
    final identifier = message.message.identifier;
    if (_proccessedMessage.contains(identifier)) return;
    _proccessedMessage.add(identifier);
    final session = await getSession(message.topic);
    if (session == null) {
      Logging.info(
        fn: () => AppLogData(
            runtime: runtimeType,
            function: "onSubscribeMessage",
            msg: "Session not found ${message.topic}"),
      );
      return;
    }
    final dcryptedMessage =
        await _decryptMessage(session: session, message: message.message);

    if (dcryptedMessage == null) return;
    final messageInfo = ITopicMessage.fromMessage(
        message: IJsonRpcMessage.fromJson(dcryptedMessage),
        protocol: message.protocol,
        session: session,
        publishedAt: message.publishedAt);
    switch (messageInfo) {
      case TopicMessagePairing():
        onPairingMessage(messageInfo);
        break;
      case TopicMessageRequest():
        onSessionMessage(messageInfo);
        break;
      case TopicMessageResponse(:final message):
        final pendingMessage = _pendingResults.remove(message.id);
        switch (message) {
          case JsonRpcMessageResponseSucceess(:final result):
            await pendingMessage?.response(result);
            break;
          case JsonRpcMessageResponseError(:final error):
            final err = error.toException();

            await pendingMessage?.error(err);
            Logging.error(
              fn: () => AppLogData(
                runtime: runtimeType,
                function: "onSubscribeMesssage",
                msg: dcryptedMessage.toString(),
              ),
            );
            break;
        }
        onReponseMessage(messageInfo);
        break;
      case TopicMessageUnknown(:final message)
          when message.messageType == JsonRpcMessageType.unknwon:
        publish(BridgeRequestMessage.response(
            response: TopicResponseError.unknownMethod(),
            session: messageInfo.session,
            storage: PublishMessageStorageType.none,
            correlationId: messageInfo.message.id));
        break;
      case TopicMessageUnknown(:final message)
          when message.messageType == JsonRpcMessageType.unsuported:
        publish(BridgeRequestMessage.response(
            response: TopicResponseError.unsupportedWcMethod(),
            session: messageInfo.session,
            storage: PublishMessageStorageType.none,
            correlationId: messageInfo.message.id));
        break;
      case TopicMessageInvalidSession():
        publish(BridgeRequestMessage.response(
            response: TopicResponseError.noMatchingKey(),
            session: messageInfo.session,
            storage: PublishMessageStorageType.none,
            correlationId: messageInfo.message.id));
        break;
      default:
        Logging.info(
          fn: () => AppLogData(
              runtime: runtimeType,
              function: "onSubscribeMessage",
              msg: "Unknown message. ${message.topic}",
              data: message.toJson()),
        );
        break;
    }
  }

  Future<String> _serializeMessage(
      IBridgeSession session, Map<String, dynamic> payload) async {
    final List<int> message = StringUtils.encodeJson(payload);
    final msg = RelayClientEncryptedMessage(
        type: BrdigeMessageTypes.wcType0,
        sealed: message,
        nonce: QuickCrypto.generateRandom(12));
    final encrypt =
        await encryptMessage(message: msg.sealed, key: session.symKey, nonce: msg.nonce);

    final encryptedMessage =
        RelayClientEncryptedMessage(type: msg.type, sealed: encrypt, nonce: msg.nonce);
    return encryptedMessage.serialize();
  }

  Future<Map<String, dynamic>?> _decryptMessage({
    required IBridgeSession session,
    required RelayClientEncryptedMessage message,
  }) async {
    final msg = message.type.supported
        ? await decryptMessage(
            message: message.sealed, key: session.symKey, nonce: message.nonce)
        : null;
    String? strMessage;
    if (msg != null) {
      strMessage = StringUtils.tryDecode(msg);
      if (strMessage != null) {
        final json = StringUtils.tryToJson<Map<String, dynamic>>(strMessage);
        if (json != null) return json;
      }
    }

    Logging.error(
      fn: () => AppLogData(
          runtime: runtimeType,
          function: "decryptMessage",
          msg: msg == null
              ? "Message decryption failed. topic: ${session.topic}, message type: ${message.type.name}"
              : "Message parsing failed. topic: ${session.topic} message: $strMessage"),
    );
    return null;
  }

  @override
  Future<REQUEST> toPublishMessage<REQUEST extends RelayClientRequest>(
      IBridgeRequest<REQUEST> message) async {
    final msg = await message.toPublishMessage(_serializeMessage);
    if (message case BridgeRequestMessage()) {
      final r = BridgeRequestMessage.fromPublishMessage(
          message: RelayClientPublish.deserialize(
              bytes: (msg as RelayClientPublish).toCbor().encode()),
          session: message.session);
      final s = await r.toPublishMessage(_serializeMessage);
      return s as REQUEST;
    }
    return msg;
  }

  Future<void> init({
    List<BridgeProtocol> protocols = const [BridgeProtocol.walletConnect],
  }) async {
    await _lock.run(() async {
      if (protocols.contains(BridgeProtocol.walletConnect) &&
          _walletConnecetSub == null) {
        await _walletConnecet.init();
        _walletConnecetSub = _walletConnecet.stream.listen(onRelayMessage);
      }

      if (protocols.contains(BridgeProtocol.onChain) && _localSub == null) {
        await _local.init();
        _localSub = _local.stream.listen(onRelayMessage);
      }
    });
  }

  @override
  Future<void> close({List<BridgeProtocol> protocols = BridgeProtocol.values}) async {
    await _lock.run(() async {
      if (protocols.contains(BridgeProtocol.walletConnect) &&
          _walletConnecetSub != null) {
        await _walletConnecet.close();
        _walletConnecetSub?.cancel();
        _walletConnecetSub = null;
      }
      if (protocols.contains(BridgeProtocol.onChain) && _localSub != null) {
        await _local.close();
        _localSub?.cancel();
        _localSub = null;
      }
    });
  }

  @override
  Future<void> dispose({List<BridgeProtocol> protocols = BridgeProtocol.values}) async {
    await _lock.run(() async {
      if (protocols.contains(BridgeProtocol.walletConnect) &&
          _walletConnecetSub != null) {
        await _walletConnecet.dispose();
        _walletConnecetSub?.cancel();
        _walletConnecetSub = null;
      }
      if (protocols.contains(BridgeProtocol.onChain) && _localSub != null) {
        await _local.dispose();
        _localSub?.cancel();
        _localSub = null;
      }
    });
    return super.dispose(protocols: protocols);
  }
}
