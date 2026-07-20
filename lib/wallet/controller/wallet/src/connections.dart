part of 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';

// TODO
// incomplete
mixin ExternalWalletConnectionsController {
  String get id;
  MainWallet get wallet;
  // Map<String, WCMSession> _sessions = {};
  WalletStorageManager get storage;
  WalletConnectionStorageManager get connectionsStoage;
  // StreamSubscription<BridgeEventOnChain>? _clientSubscribtion;
  IBridgeClient get bridgeController;

  // void _sendEvent(WCMActionEvent event) {
  //   for (final i in _sessions.values) {
  //     // controller.sendEvent(event, i);
  //   }
  // }

  void onUnlock() {
    // _sendEvent(WCMEventWalletUnlocked(WCMEventWalletUpdated(
    //     importedKeys: wallet.importedKeys, subWallets: wallet.subWallets)));
  }

  StreamSubscription<IStorageEvent>? _databaseSubscribtion;

  // void _onStorageEvent(IStorageEvent event) {
  //   _sendEvent(WCMEventStorage(event: event));
  // }

  // Future<void> _onClientEvent(BridgeEventOnChain event) async {
  //   // Logging.debug(
  //   //     runtime: runtimeType,
  //   //     functionName: "_onClientEvent",
  //   //     msg: "new client event ${event.runtimeType}");
  //   // switch (event) {
  //   //   case WcInternalPublishMessageEvent event:
  //   //     Logging.debug(
  //   //         runtime: runtimeType,
  //   //         functionName: "_onClientEvent",
  //   //         msg: "new event messagee ${event.message} ${event.message.correlationId}");
  //   //     connectionsStoage.handlePublishMessageStorage(event.message);
  //   //     break;
  //   //   case WcInternalSessionRequestResponse response:
  //   //     final message = await connectionsStoage.getPendingMessage(response.response.id);
  //   //     if (message != null) {
  //   //       await connectionsStoage.removePendingMessage(message);
  //   //     }

  //   //     break;
  //   // }
  // }

  // Future<IResult<void>> init() async {
  //   if (wallet.externalConnections.isNotEmpty) {
  //     final messages = await connectionsStoage.getPendingMessages();
  //     return messages.andThenAsync((messages) async {
  //       final sessions = wallet.externalConnections.map((e) {
  //         final sessionMessages = messages
  //             .where((m) => e.topic == m.topic)
  //             .map((e) => e.correlationId)
  //             .toList();
  //         return WCMSession(e)..idGenerator.updateState(sessionMessages);
  //       }).toList();
  //       _sessions = Map<String, WCMSession>.fromEntries(
  //           sessions.map((e) => MapEntry<String, WCMSession>(e.topic, e)));
  //       // controller.init(sessions: _sessions.values.toList(), messages: messages);
  //       // _clientSubscribtion = bridgeController.onChainEvent.listen(_onClientEvent);
  //       // _databaseSubscribtion = storage.database.database.listenOnTable(id, actions: [
  //       //   OnChainBrdigeSerializationIdentifier.storageActionWrite
  //       // ]).where((e) {
  //       //   final id = StorageActionId.fromId(e.action.actionId);
  //       //   return switch (id) {
  //       //     StorageActionId.web3 ||
  //       //     StorageActionId.network ||
  //       //     StorageActionId.chain ||
  //       //     StorageActionId.wallet ||
  //       //     StorageActionId.walletRuntime =>
  //       //       true,
  //       //     _ => false
  //       //   };
  //       // }).listen(_onStorageEvent);
  //       return ResultOk.okVoid;
  //     });
  //   }
  //   return ResultOk.okVoid;
  // }

  Future<IResult<void>> dispose() async {
    // _sessions.clear();
    // _databaseSubscribtion?.cancel();
    // _databaseSubscribtion = null;
    // _clientSubscribtion?.cancel();
    // _clientSubscribtion = null;

    // await bridgeController.dispose();
    return ResultOk(null);
  }
}
