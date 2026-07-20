part of '../scripts.dart';

class ZcashPageController extends WalletStandardPageController {
  ZcashPageController(super.postMessage);
  @override
  void _initNetworkFeatures(JSWalletStandardFeature feature) {
    feature.payment = ZcashWalletAdapterZcashPaymentFeature.setup(payment: _payment.toJS);
    feature.zcashSignMessage =
        ZcashWalletAdapterZcashSignMessageFeature.setup(signMessage: _signMessage.toJS);
    feature.zcashConnect =
        JSZcashWalletStandardConnectFeature.setup(connect: _connect.toJS);
    feature.zcashEvents = JSWalletStandardEventsFeature.setup(on: _onEvents.toJS);

    feature.zcashDisconnect =
        JSWalletStandardDisconnectFeature.setup(disconnect: _disconnectChain.toJS);
  }

  JSPromise<JSZcashWalletStandardConnect> _connect([JSString? chainId]) {
    final network = JsUtils.asJSString(chainId);
    final params = network == null ? null : [network].toJS;
    return waitForSuccessResponsePromise<JSZcashWalletStandardConnect>(
        method: ZcashJSConst.requestAccounts, params: params);
  }

  JSPromise<JSZcashSendTransactionResponse> _payment(
      JSZcashSendOrSignTransactionParams params) {
    return waitForSuccessResponsePromise<JSZcashSendTransactionResponse>(
        method: ZcashJSConst.sendTransaction, params: [params].toJS);
  }

  JSPromise<JSZcashSignMessageResponse> _signMessage(JSZcashSignMessageParams params) {
    return waitForSuccessResponsePromise<JSZcashSignMessageResponse>(
        method: ZcashJSConst.signMessage, params: [params].toJS);
  }

  @override
  JSClientType get _client => JSClientType.zcash;
}
