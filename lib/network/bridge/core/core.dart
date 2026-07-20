import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/bridge/types/server/types.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/socket.dart';
import 'package:on_chain_wallet/network/bridge/onchain/types/types.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/topic_message.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/types.dart';
import 'package:on_chain_wallet/network/bridge/types/wallet_connect/types.dart';
import 'package:on_chain_wallet/context/core/context.dart';

abstract class IBridgeCore {
  AppContext get context;
  Future<IBridgeSession?> getSession(String topic);
  Stream<BridgeEventWeb3> get onWeb3Event;
  Stream<BridgeEventOnChain> get onChainEvent;
  Future<List<int>> encryptMessage(
      {required List<int> message, required List<int> key, required List<int> nonce});
  Future<List<int>?> decryptMessage(
      {required List<int> message, required List<int> key, required List<int> nonce});

  Future<IResult<T?>> publish<T>(IBridgeRequest message);
  Future<IResult<void>> subscribe<T>(IBridgeSession session);
  Future<IResult<void>> unSubscribe<T>(IBridgeSession session);
  StreamValue<SocketConnectionStatus> connectionStatus(BridgeProtocol protocol);

  Future<IResult<RESPONSE>> sendRequestAndGetResponse<RESPONSE extends Object?>(
      {required IBrdigeAction<RESPONSE> action,
      PublishMessageStorageType? storage,
      String? topic,
      IBridgeSession? session,
      int? fixedId});

  Future<IResult<RESPONSE?>> sendOnChainRequest<RESPONSE extends Object?>({
    required WCMAction<RESPONSE> action,
    String? topic,
    IBridgeSession? session,
  });
  Future<IResult<bool?>> sendWeb3Request(
      {required WCAction action,
      String? topic,
      IBridgeSession? session,
      PublishMessageMode mode = PublishMessageMode.publish,
      PublishMessageStorageType? storage});

  Future<REQUEST> toPublishMessage<REQUEST extends RelayClientRequest>(
      IBridgeRequest<REQUEST> message);

  Future<IResult<RESPONSE>> sendOnChainRequestAndGetResult<RESPONSE extends Object?>({
    required WCMAction<RESPONSE> action,
    String? topic,
    IBridgeSession? session,
  });

  Future<void> disconnectPairing(BridgeSession session);

  Future<IResult<void>> addAndSubscribeSession(IBridgeSession session);
  Future<IResult<void>> removeAndUnSubscribeSession(IBridgeSession session);

  bool removeSession(IBridgeSession session);

  void onRelayMessage(RelayClientResponse message);
  void onPairingMessage(TopicMessagePairing message);
  void onSessionMessage(TopicMessageRequest message);
  void onReponseMessage(TopicMessageResponse message);
  void onPairingPingMessage(TopicMessagePairing message);
  void onPairingDelete(TopicMessagePairing message);
  void onSessionPingMessage(TopicMessageRequest message);
  void onConnect(BridgeProtocol protocol);
  void onDisconnect(BridgeProtocol protocol);
  void addSession(IBridgeSession session);

  Future<void> dispose({List<BridgeProtocol> protocols = BridgeProtocol.values});
  Future<void> close({List<BridgeProtocol> protocols = BridgeProtocol.values});
}
