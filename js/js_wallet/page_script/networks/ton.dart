part of '../scripts.dart';

class TonPageController extends WalletStandardPageController {
  TonPageController(super.postMessage);

  @override
  void _initNetworkFeatures(JSWalletStandardFeature feature) {
    feature.tonSignAndSendTransaction =
        TonWalletAdapterTonSignAndSendTransactionFeature.setup(
            signAndSendTransaction: _sendTransaction.toJS);
    feature.tonSignTransaction = TonWalletAdapterTonSignTransactionFeature.setup(
        signTransaction: _signTransaction.toJS);
    feature.tonSignMessage =
        TonWalletAdapterTonSignMessageFeature.setup(signMessage: _signMessage.toJS);
    feature.tonConnect = JSTonWalletStandardConnectFeature.setup(connect: _connect.toJS);
    feature.tonDisconnect =
        JSWalletStandardDisconnectFeature.setup(disconnect: _disconnectChain.toJS);
    feature.tonEvents = JSWalletStandardEventsFeature.setup(on: _onEvents.toJS);
  }

  JSPromise<JSTonWalletStandardConnect> _connect([JSString? chainId]) {
    final network = JsUtils.asJSString(chainId);
    final params = network == null ? null : [network].toJS;
    return waitForSuccessResponsePromise<JSTonWalletStandardConnect>(
        method: TonJSConst.requestAccounts, params: params);
  }

  JSPromise<JSTonSignTransactionResponse> _signTransaction(
      JSTonSendOrSignTransactionParams params) {
    return waitForSuccessResponsePromise<JSTonSignTransactionResponse>(
        method: TonJSConst.signTransaction, params: [params].toJS);
  }

  JSPromise<JSTonSendTransactionResponse> _sendTransaction(
      JSTonSendOrSignTransactionParams params) {
    return waitForSuccessResponsePromise<JSTonSendTransactionResponse>(
        method: TonJSConst.sendTransaction, params: [params].toJS);
  }

  JSPromise<JSTonSignMessageResponse> _signMessage(JSTonSignMessageParams params) {
    return waitForSuccessResponsePromise<JSTonSignMessageResponse>(
        method: TonJSConst.signMessage, params: [params].toJS);
  }

  @override
  JSClientType get _client => JSClientType.ton;
}
