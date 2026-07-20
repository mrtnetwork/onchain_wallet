import 'dart:async';
import 'dart:js_interop';
import 'package:on_chain_bridge/models/events/models/wallet_event.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/models/models/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/models/authenticated.dart';
import 'js_wallet/js_wallet.dart';
import 'package:on_chain_bridge/web/web.dart';

@JS("workerListener_")
external set workerListener(JSFunction? f);
@JS("workerListener_")
external JSFunction get workerListener;

@JS("errorListener_")
external set onWorkerErrorListener(JSFunction? f);
@JS("errorListener_")
external JSFunction get onWorkerErrorListener;
@JS("encodeURIComponent")
external String encodeURIComponent(String uriComponent);

void postToWallet({required JSWorkerWalletData data, required JSWebviewTraget target}) {
  if (target.isMacos) {
    jsWindow.webkit.messageHandlers.onChain.postMessage(data.toJson().jsify());
    return;
  }
  onChain.onChainInternalJsRequest(data.clientId, data.data, data.requestId, data.type);
}

void main(List<String> args) async {
  final pageController = JSWithWorkerPageController.setup();
  if (onChainNullable == null) {
    onChain = OnChainWallet(JSObject());
  }

  final applicationId =
      Web3ApplicationAuthentication.toApplicationId(jsWindow.location.origin);
  if (applicationId == null) {
    throw Web3RequestExceptionConst.invalidHost;
  }

  final workerCompleter = Completer<(Worker, JSWebviewTraget)>();
  bool onActivation(JSWalletEvent data) {
    final walletEvent = data.toEvent();
    if (walletEvent == null || walletEvent.clientId != onChain.clientId) {
      return false;
    }
    if (walletEvent.type == WalletEventTypes.exception) {
      final error = Web3ExceptionMessage.deserialize(bytes: walletEvent.data);
      workerCompleter.completeError(error.toWalletError());
      return false;
    }
    final target = JSWebviewTraget.fromName(walletEvent.platform);
    if (target == null) return false;

    final workerModule = data.additional!;
    final blob =
        Blob([workerModule.toJS].toJS, BlobOptions(type: 'application/javascript'));
    final obj = URL.createObjectURL(blob);
    final worker = Worker(obj, WorkerOptions(name: 'js'));
    onWorkerErrorListener = (MessageEvent event) {}.toJS;
    void onEvent(MessageEvent event) {
      final workerEvent = event.data as JSWorkerEvent;
      switch (workerEvent.eventType) {
        case JSWorkerType.ready:
          if (workerEvent.clientId == null) {
            throw JSError(message: "Invalid request. missing client ID");
          }
          postToWallet(
              data: JSWorkerWalletData(
                  clientId: workerEvent.clientId!,
                  requestId: "",
                  data: workerEvent.clientId!,
                  type: WalletEventTypes.tabId.name),
              target: onChain.onChainInternalJsRequest_ == null
                  ? JSWebviewTraget.macos
                  : JSWebviewTraget.android);
          onChain.onWebViewMessage = (JSWalletEvent event) {
            if (walletEvent.type == WalletEventTypes.exception) {
              final error = Web3ExceptionMessage.deserialize(bytes: walletEvent.data)
                  .toWalletError();
              workerCompleter.completeError(error);
              worker.terminate();
              pageController.disable(error);
              return false.toJS;
            }
            if (walletEvent.type != WalletEventTypes.activation) {
              return false.toJS;
            }
            data.additional = null;
            worker.postMessage(event);
            onChain.onWebViewMessage = null;
            return true.toJS;
          }.toJS;

          break;
        case JSWorkerType.active:
          workerCompleter.complete((worker, target));
          worker.removeEventListener("error", onWorkerErrorListener);
          worker.removeEventListener("message", workerListener);
          onWorkerErrorListener = null;
          workerListener = null;
          postToWallet(
              data: JSWorkerWalletData(
                  clientId: onChain.clientId,
                  requestId: '',
                  data: '',
                  type: WalletEventTypes.activation.name),
              target: target);
          break;
        case JSWorkerType.error:
          final error = (workerEvent.data as JSString).toDart;
          final message = Web3ExceptionMessage.deserialize(hex: error);
          worker.terminate();
          pageController.disable(message.toWalletError());
          workerCompleter.completeError(error);
          postToWallet(
              data: JSWorkerWalletData(
                  clientId: onChain.clientId,
                  requestId: data.requestId!,
                  data: error,
                  type: WalletEventTypes.exception.name),
              target: target);
          break;
        case JSWorkerType.client:
          break;
        default:
          throw UnimplementedError();
      }
    }

    workerListener = onEvent.toJS;
    worker.addEventListener("error", onWorkerErrorListener);
    worker.addEventListener("message", workerListener);
    return true;
  }

  onChain.onWebViewMessage = onActivation.toJS;
  final activation = await workerCompleter.future;
  final worker = activation.$1;
  final target = activation.$2;

  onChain.onWebViewMessage = null;

  bool onWalletEvent(JSWalletEvent jsRequest) {
    worker.postMessage(JSWorkerEvent(type: JSWorkerType.wallet, data: jsRequest));
    return true;
  }

  void onWorkerWalletEvent(MessageEvent event) {
    final workerEvent = event.data as JSWorkerEvent;
    switch (workerEvent.eventType) {
      case JSWorkerType.wallet:
        final data = workerEvent.data as JSWorkerWalletData;
        postToWallet(data: data, target: target);
        break;
      case JSWorkerType.client:
        final data = workerEvent.data as WalletMessage;
        pageController.onWalletEvent(data);
        break;
      default:
    }
  }

  onWorkerErrorListener = (MessageEvent event) {}.toJS;
  workerListener = onWorkerWalletEvent.toJS;
  worker.addEventListener("error", onWorkerErrorListener);
  worker.addEventListener("message", workerListener);
  onChain.onWebViewMessage = onWalletEvent.toJS;
  pageController.initClients('', worker: activation.$1);
}
