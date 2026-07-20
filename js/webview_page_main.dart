import 'dart:async';
import 'dart:js_interop';
import 'package:on_chain_bridge/models/events/models/wallet_event.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/models/authenticated.dart';
import 'js_crypto_utils.dart';
import 'js_wallet/js_wallet.dart';
import 'package:on_chain_bridge/web/web.dart';

void postToWallet({required JSWorkerWalletData data, required JSWebviewTraget target}) {
  if (target.isMacos) {
    jsWindow.webkit.messageHandlers.onChain.postMessage(data.toJson().jsify());
    return;
  }
  onChain.onChainInternalJsRequest(data.clientId, data.data, data.requestId, data.type);
}

void main(List<String> args) async {
  final pageController = JSPageController.setup();
  if (onChainNullable == null) {
    onChain = OnChainWallet(JSObject());
  }

  final applicationId =
      Web3ApplicationAuthentication.toApplicationId(jsWindow.location.origin);
  if (applicationId == null) {
    throw Web3RequestExceptionConst.invalidHost;
  }
  final key = JsCryptoUtils.generateKey();
  final pubKey = key.publicKeyHex();
  postToWallet(
      data: JSWorkerWalletData(
          clientId: pubKey,
          requestId: "0",
          data: pubKey,
          type: WalletEventTypes.tabId.name),
      target: onChain.onChainInternalJsRequest_ == null
          ? JSWebviewTraget.macos
          : JSWebviewTraget.android);
  final workerCompleter = Completer<(JSWebviewWallet, JSWebviewTraget)>();
  bool onActivation(JSWalletEvent data) {
    try {
      final walletEvent = data.toEvent();
      if (walletEvent == null || walletEvent.clientId != pubKey) {
        return false;
      }
      if (walletEvent.type == WalletEventTypes.exception) {
        workerCompleter
            .completeError(JSError(message: String.fromCharCodes(walletEvent.data)));
        return false;
      }
      final target = JSWebviewTraget.fromName(walletEvent.platform);
      if (target == null) return false;
      final wallet = JSWebviewWallet.initialize(
          request: walletEvent,
          clientId: walletEvent.clientId,
          isWorker: false,
          keyPair: key,
          target: JSWebviewTraget.fromName(walletEvent.platform)!);
      workerCompleter.complete((wallet, target));
      return true;
    } catch (e) {
      return false;
    }
  }

  onChain.onWebViewMessage = onActivation.toJS;
  try {
    final activation = await workerCompleter.future;
    pageController.initClients(pubKey);
    activation.$1.initClients();
  } catch (e) {
    jsConsole.error("wallet initialize failed. ${e.toString()}");
  }
}
