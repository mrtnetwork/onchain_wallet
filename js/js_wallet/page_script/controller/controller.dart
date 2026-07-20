part of '../scripts.dart';

typedef POSTPAGEMESSAGE = void Function(PageMessage message);

abstract class JSBasePageController {
  late final PageRequestController requestController = PageRequestController(postMessage);
  late final _walletStandardController =
      JSPageWalletStandardController(requestController);

  SafeAtomicLock? _lock = SafeAtomicLock();
  Completer<void>? _wait = Completer();
  String? _walletId;
  void postMessage(PageMessage message);
  void initClients(String clientId);

  Future<void> _waitForActivation() async {
    return await _lock?.run(() async {
      try {
        return await _wait?.future;
      } finally {
        _wait = null;
        _lock = null;
      }
    });
  }

  late final Map<JSClientType, WalletStandardPageController> _networks = {
    JSClientType.ethereum: EthereumPageController(requestController),
    JSClientType.tron: TronPageController(requestController),
    JSClientType.solana: SolanaPageController(requestController),
    JSClientType.ton: TonPageController(requestController),
    JSClientType.stellar: StellarPageController(requestController),
    JSClientType.substrate: SubstratePageController(requestController),
    JSClientType.aptos: AptosPageController(requestController),
    JSClientType.sui: SuiPageController(requestController),
    JSClientType.cosmos: CosmosPageController(requestController),
    JSClientType.bitcoin: BitcoinPageController(requestController),
    JSClientType.xrpl: RipplePageController(requestController),
    JSClientType.monero: MoneroPageController(requestController),
    JSClientType.cardano: ADAPageController(requestController),
    JSClientType.bitcoinCash: BitcoinCashPageController(requestController),
    JSClientType.zcash: ZcashPageController(requestController)
  };

  void _initControllers() {
    try {
      for (final i in _networks.entries) {
        try {
          final page = i.value;
          page._initNetworkFeatures(_walletStandardController._feature);
        } catch (e, s) {
          jsConsole.error("Initializing wallet failed: ${i.key.networkName} $e $s");
        }
      }
      _walletStandardController._initController();
    } catch (e, s) {
      jsConsole.error("Initializing wallet failed: $e $s");
    }
  }

  void disable(JSWalletError err) {
    if (err.message != null) {
      jsConsole.error(err.message);
    }
    _wait?.complete();
  }

  void handleWalletMessage(WalletMessage walletResponse) {
    if (walletResponse.data.messageType == JSWalletMessageType.response) {
      requestController._completeRequest(walletResponse);
      return;
    }
    final event = walletResponse.data as WalletMessageEvent;
    if (walletResponse.clientType == null) {
      _walletStandardController._onGlobalEventEvent(event);
      return;
    }
    _networks[walletResponse.clientType]?.onWalletEvent(event);
  }
}

class JSPageController extends JSBasePageController {
  JSPageController._();
  @override
  void postMessage(PageMessage message) async {
    await _waitForActivation();
    final event = CustomEvent.create(type: _walletId, detail: message);
    jsWindow.dispatchEvent(event);
  }

  factory JSPageController.setup() {
    final client = JSPageController._();
    client._initControllers();
    return client;
  }

  void _onWalletEvent(CustomEvent response) {
    final WalletMessage walletResponse = response.detail as WalletMessage;
    handleWalletMessage(walletResponse);
  }

  @override
  void initClients(String clientId) {
    if (_walletId != null) return;
    _walletId = JsUtils.toWalletId(clientId);
    jsWindow.addEventListener(JsUtils.toEthereumClientId(clientId), _onWalletEvent.toJS);
    _wait?.complete();
  }
}

class JSWithWorkerPageController extends JSBasePageController {
  Worker? _worker;
  JSWithWorkerPageController._();
  @override
  void postMessage(PageMessage message) async {
    await _waitForActivation();
    _worker?.postMessage(JSWorkerEvent(data: message, type: JSWorkerType.client));
  }

  factory JSWithWorkerPageController.setup() {
    final client = JSWithWorkerPageController._();
    client._initControllers();
    return client;
  }

  @override
  void initClients(String clientId, {Worker? worker}) {
    if (_worker != null) return;
    _worker = worker;
    _wait?.complete();
  }

  void onWalletEvent(WalletMessage response) {
    handleWalletMessage(response);
  }
}
