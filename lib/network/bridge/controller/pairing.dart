import 'package:on_chain_wallet/network/bridge/core/core.dart';
import 'package:on_chain_wallet/network/bridge/types/server/types.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/types.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/topic_message.dart';
import 'package:on_chain_wallet/network/bridge/types/wallet_connect/types.dart';

mixin IBridgePairingController on IBridgeCore {
  @override
  void onPairingDelete(TopicMessagePairing message) {
    removeAndUnSubscribeSession(message.session);
  }

  @override
  Future<void> disconnectPairing(BridgeSession session) async {
    if (session.type == BridgeSessionType.pairingWb3) {
      final error = BridgeGenericError.userDisconnected;
      await sendWeb3Request(
          action: WCActionPairingDelete(code: error.code, message: error.message),
          storage: PublishMessageStorageType.memory,
          session: session);
    }
    removeAndUnSubscribeSession(session);
  }
}
