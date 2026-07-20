import 'package:on_chain_wallet/app/stream/live.dart';
import 'package:on_chain_wallet/app/utils/method/result.dart';
import 'package:on_chain_wallet/app/utils/method/utiils.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/socket.dart';
import 'package:on_chain_wallet/network/bridge/types/wallet_connect/types.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/models/authenticated.dart';

abstract class IWeb3WalletConnectController {
  StreamValue<SocketConnectionStatus> get connectionStatus;
  StreamValue<void> get onSessionUpdated;
  WCSession? getSession({String? topic, String? peerKey});
  Future<List<Web3ClientInfo>> getActiveSessions();
  Future<IResult<void>> pair(Uri uri,
      {OnceCancelableTemplate<BridgeEventWeb3PairingPropose>? cancelable});
  Future<IResult<void>> disconnectSession(Web3ClientInfo client);
  Future<void> updateAuthenticated(Web3DappInfo app);
  Future<IResult<List<int>>> getSessionRequiredChainIds(
      {required WCSession session, Web3APPData? auth});
  Future<void> connect();
  Future<void> dispose();
  Future<void> close();
}
