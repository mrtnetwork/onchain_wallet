part of '../scripts.dart';

class AptosPageController extends WalletStandardPageController {
  final Map<JSEventType, List<JSFunction>> _aptosLiteners = {
    JSEventType.accountsChanged: [],
    JSEventType.chainChanged: [],
  };
  AptosPageController(super.postMessage);

  JSPromise<JSAptosWalletStandardUserResponse> _changeNetwork(
      JSAptosNetworkInfo message) {
    return waitForSuccessResponsePromise<JSAptosWalletStandardUserResponse>(
        method: AptosJSConstant.changeNetworkRequestName, params: [message].toJS);
  }

  JSPromise<JSAptosWalletStandardUserResponse> _signMessage(
      JSAptosSignMessageParams message) {
    return waitForSuccessResponse<JSAptosWalletStandardUserResponse>(
            method: AptosJSConstant.signMessageRequestName, params: [message].toJS)
        .then((e) {
      if (e.type.isRejected) return e;
      final signingResponse = e.args as JSAptosSignMessageResponse;
      signingResponse.buildSerializable();
      return JSAptosWalletStandardUserResponse.approved(signingResponse);
    }).toPromise;
  }

  JSPromise<JSAptosWalletStandardUserResponse> _signTransaction(
      JSAptosSignTransactionParams transaction) {
    return waitForSuccessResponse<JSAptosWalletStandardUserResponse>(
            method: AptosJSConstant.signTransaction,
            params: [transaction.toRequest()].toJS)
        .then((e) {
      if (e.type.isRejected) return e;
      final signingResponse = e.args as JSAptosSignTransactionResponse;
      signingResponse.buildSerializable();
      return JSAptosWalletStandardUserResponse.approved(signingResponse);
    }).toPromise;
  }

  JSPromise<JSAptosWalletStandardUserResponse> _requestAccount([JSString? chainId]) {
    final network = chainId.isDefinedAndNotNull ? JsUtils.asJSString(chainId) : null;
    return waitForSuccessResponse<JSAptosWalletStandardUserResponse>(
      method: AptosJSConstant.requestAccountRequestName,
      params: [if (network != null) network].toJS,
    ).then((e) {
      if (e.type.isRejected) return e;
      final response = e.args as JSAptosWalletAccount;
      response.publicKey.buildSerializable();
      response.publicKey = response.publicKey.toProxy();
      return JSAptosWalletStandardUserResponse.approved(response);
    }).toPromise;
  }

  JSPromise<JSAptosNetworkInfo> _network() {
    return waitForSuccessResponsePromise<JSAptosNetworkInfo>(
        method: AptosJSConstant.getNetworkRequestName);
  }

  void _onAccountChange(JSFunction callBack) {
    _aptosLiteners[JSEventType.accountsChanged]!.add(callBack);
    _emitEvent(PageMessageEvent.build(event: JSEventType.accountsChanged));
  }

  void _onNetworkChange(JSFunction callBack) {
    _aptosLiteners[JSEventType.chainChanged]!.add(callBack);
    _emitEvent(PageMessageEvent.build(event: JSEventType.chainChanged));
  }

  @override
  void _emit(List<JSFunction> listeners, JSAny? message) {
    final clone = [...listeners];
    for (final i in clone) {
      i.callAsFunction(null, message);
    }
  }

  @override
  void onWalletEvent(WalletMessageEvent message) {
    super.onWalletEvent(message);
    final data = message.data as JSWalletNetworkEvent;
    final events = data.eventTypes;
    for (final event in events) {
      switch (event) {
        case JSNetworkEventType.defaultAccountChanged:
          _emit(_aptosLiteners[JSEventType.accountsChanged]!, data.account);
          break;
        case JSNetworkEventType.defaultChainChanged:
          final chainChanged = data.chainChanged as JSAptosNetworkInfo?;
          if (chainChanged != null) {
            _emit(_aptosLiteners[JSEventType.chainChanged]!, chainChanged);
          }
          break;
        default:
      }
    }
  }

  @override
  JSClientType get _client => JSClientType.aptos;

  @override
  void _initNetworkFeatures(JSWalletStandardFeature feature) {
    feature.aptosConnect =
        AptosWalletAdapterStandardConnectFeature.setup(connect: _requestAccount.toJS);
    feature.aptosSignTransaction = AptosWalletAdapterStandardSignTransactionFeature.setup(
        signTransaction: _signTransaction.toJS);
    feature.aptosSignMessage = AptosWalletAdapterStandardSignMessageFeature.setup(
        signMessage: _signMessage.toJS);
    feature.aptosAccount =
        AptosWalletAdapterStandardAccountFeature.setup(account: _requestAccount.toJS);
    feature.aptosOnNetworkChange = AptosWalletAdapterStandardOnNetworkChangeFeature.setup(
        onNetworkChange: _onNetworkChange.toJS);
    feature.aptosNetwork =
        AptosWalletAdapterStandardGetNetworkFeature.setup(network: _network.toJS);
    feature.aptosOnAccountChange = AptosWalletAdapterStandardOnAccountChangeFeature.setup(
        onAccountChange: _onAccountChange.toJS);
    feature.aptosDisconnect = AptosWalletAdapterStandardDisconnectFeature.setup(
        disconnect: _disconnectChain.toJS);
    feature.aptosChangeNetwork = AptosWalletAdapterStandardChangeNetworkFeature.setup(
        changeNetwork: _changeNetwork.toJS);
    feature.aptosEvents = JSWalletStandardEventsFeature.setup(on: _onEvents.toJS);
  }
}
