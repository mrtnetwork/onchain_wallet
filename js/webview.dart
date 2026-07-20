import 'dart:async';
import 'dart:js_interop';
import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/models/models/exception.dart';
import 'js_crypto_utils.dart';
import 'js_wallet/js_wallet.dart';
import 'package:on_chain_bridge/web/web.dart';

@JS("postMessage")
external void postMessage(JSWorkerEvent data);
@JS("onmessage")
external set onMessage(JSFunction _);

void main(List<String> args) async {
  final walletCompleter = Completer<(JSWorkerEvent, JSWebviewWallet?)>();
  final key = JsCryptoUtils.generateKey();
  void onData(MessageEvent event) {
    try {
      final data = event.data as JSWalletEvent;
      final walletEvent = data.toEvent();
      switch (walletEvent!.type) {
        case WalletEventTypes.exception:
          final message = Web3ExceptionMessage.deserialize(bytes: walletEvent.data);
          final error =
              JSWorkerEvent(data: message.toWalletError(), type: JSWorkerType.error);
          walletCompleter.complete((error, null));
          break;
        case WalletEventTypes.activation:
          final activeEvent = JSWorkerEvent(type: JSWorkerType.active);
          final wallet = JSWebviewWallet.initialize(
              request: walletEvent,
              clientId: walletEvent.clientId,
              keyPair: key,
              target: JSWebviewTraget.fromName(walletEvent.platform)!);
          walletCompleter.complete((activeEvent, wallet));
          break;
        default:
          break;
      }
    } catch (e, trace) {
      final error = JSWorkerEvent(
          data: Web3RequestExceptionConst.internalErr("webview.main",
                  reason: e.toString(), trace: trace.toString())
              .toResponseMessage()
              .toCbor()
              .toCborHex()
              .toJS,
          type: JSWorkerType.error);
      walletCompleter.complete((error, null));
    }
  }

  onMessage = onData.toJS;
  postMessage(JSWorkerEvent(type: JSWorkerType.ready, clientId: key.publicKeyHex()));
  final event = await walletCompleter.future;
  postMessage(event.$1);
  final wallet = event.$2;
  if (wallet != null) {
    wallet.initClients();
  }
}
