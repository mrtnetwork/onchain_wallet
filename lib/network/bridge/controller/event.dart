import 'dart:async';

import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/bridge/types/server/types.dart';
import 'package:on_chain_wallet/network/bridge/core/core.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/types.dart';
import 'package:on_chain_wallet/network/bridge/onchain/types/types.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/topic_message.dart';
import 'package:on_chain_wallet/network/bridge/types/wallet_connect/types.dart';

mixin IBridgeEventController on IBridgeCore {
  final SafeStreamController<IBridgeEvent> _controller =
      SafeStreamController(name: "IBridgeEventController");

  @override
  Stream<BridgeEventWeb3> get onWeb3Event => _controller
      .stream()
      .where((e) => e.target == BridgeEventTarget.web3)
      .cast<BridgeEventWeb3>();
  @override
  Stream<BridgeEventOnChain> get onChainEvent => _controller
      .stream()
      .where((e) => e.target == BridgeEventTarget.onchain)
      .cast<BridgeEventOnChain>();

  @override
  void onPairingPingMessage(TopicMessagePairing message) {}

  @override
  void onSessionPingMessage(TopicMessageRequest message) {}

  void onPublishMessageStatusChanged(IBridgeRequest message) {
    switch (message) {
      case BridgeRequestUnsubscribe():
        break;
      case BridgeRequestSubscribe():
        break;
      case BridgeRequestMessage():
        switch (message.session.type) {
          case BridgeSessionType.pairingWb3:
          case BridgeSessionType.web3:
            _controller.add(BridgeEventWeb3MessageStatus(message: message));
            break;
          case BridgeSessionType.onChain:
          case BridgeSessionType.pairingOnChain:
            _controller.add(BridgeEventOnChainMessageStatus(message: message));
            break;
        }
        break;
    }
  }

  @override
  void onPairingMessage(TopicMessagePairing message) {
    final method = message.method;
    final params = message.message.params;
    switch (message.session.type) {
      case BridgeSessionType.pairingWb3:
        switch (method) {
          case BridgeKnownMethods.pairingPing:
            onPairingPingMessage(message);
            break;
          case BridgeKnownMethods.pairingDelete:
            onPairingDelete(message);
            break;
          default:
            break;
        }
        final event = BridgeEventWeb3.fromPairingMessage(message);
        if (event != null) _controller.add(event);

        break;
      case BridgeSessionType.pairingOnChain:
        switch (method) {
          case BridgeKnownMethods.pairingPing:
            onPairingPingMessage(message);
            break;
          case BridgeKnownMethods.pairingDelete:
            onPairingDelete(message);
            break;
          default:
            break;
        }
        final msg = WCMActionPairing.deserialize(bytes: JsonParser.valueAsBytes(params));
        _controller.add(BridgeEventOnChainPairingAction(message: message, request: msg));
        break;
      default:
        break;
    }
  }

  @override
  void onSessionMessage(TopicMessageRequest message) {
    final method = message.method;
    final params = message.message.params;
    Logging.info(
        fn: () => AppLogData(
            runtime: runtimeType,
            function: "onSessionMessage",
            msg: "New session request: method:$message, params: $params"));
    if (method == BridgeKnownMethods.sessionPing) {
      onSessionPingMessage(message);
    }
    switch (message.session.type) {
      case BridgeSessionType.web3:
        final event = BridgeEventWeb3.fromSessionMessage(message);
        if (event != null) _controller.add(event);
        break;
      case BridgeSessionType.onChain:
        final event = BridgeEventOnChainSession.fromSessionMessage(
            message: message, bytes: JsonParser.valueAsBytes(params));
        _controller.add(event);
        break;
      default:
        break;
    }
  }

  @override
  void onConnect(BridgeProtocol protocol) {
    _controller.add(BridgeEventWeb3Connected(protocol));
    _controller.add(BridgeEventOnChainConnected(protocol));
  }

  @override
  void onDisconnect(BridgeProtocol protocol) {
    _controller.add(BridgeEventWeb3Disconnected(protocol));
    _controller.add(BridgeEventOnChainDisconnected(protocol));
  }

  @override
  Future<void> dispose({List<BridgeProtocol> protocols = BridgeProtocol.values}) async {
    _controller.close();
  }
}
