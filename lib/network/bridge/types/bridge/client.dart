import 'package:on_chain_wallet/app/stream/live.dart';
import 'package:on_chain_wallet/app/utils/method/result.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/socket.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/types.dart';
import 'package:on_chain_wallet/network/bridge/types/server/types.dart';
import 'package:on_chain_wallet/network/bridge/types/wallet_connect/types.dart';

abstract class IBridgeClient {
  Stream<BridgeEventWeb3> get onWeb3Event;
  StreamValue<SocketConnectionStatus> connectionStatus(BridgeProtocol protocol);
  Future<IResult<bool?>> sendWeb3Request(
      {required WCAction action,
      String? topic,
      IBridgeSession? session,
      PublishMessageMode mode = PublishMessageMode.publish,
      PublishMessageStorageType? storage});
  Future<IResult<T?>> publish<T>(IBridgeRequest message);
  Future<IResult<void>> subscribe<T>(IBridgeSession session);
  Future<IResult<void>> unSubscribe<T>(IBridgeSession session);
  Future<IResult<void>> addAndSubscribeSession(IBridgeSession session);
  Future<IResult<void>> removeAndUnSubscribeSession(IBridgeSession session);

  Future<void> dispose({List<BridgeProtocol> protocols = BridgeProtocol.values});
  Future<void> close({List<BridgeProtocol> protocols = BridgeProtocol.values});

  Future<REQUEST> toPublishMessage<REQUEST extends RelayClientRequest>(
      IBridgeRequest<REQUEST> message);
  Future<void> disconnectPairing(BridgeSession session);
  Future<void> init({
    List<BridgeProtocol> protocols = const [BridgeProtocol.walletConnect],
  });
}
