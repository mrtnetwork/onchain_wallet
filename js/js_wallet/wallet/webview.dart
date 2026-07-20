part of 'core/wallet.dart';

enum JSWebviewTraget {
  android,
  macos;

  bool get isMacos => this == macos;
  static JSWebviewTraget? fromName(String? name) {
    return values.firstWhereOrNull((e) => e.name == name);
  }
}

class JSWebviewWallet extends Web3JSWalletHandler {
  @override
  final String clientId;

  final JSWebviewTraget target;
  final bool isWorker;

  Web3APPData? _initializeAuthenticated;

  void initClients() {
    final auth = _initializeAuthenticated;
    if (auth == null) return;
    _initializeAuthenticated = null;
    _updateAuthenticated(auth);
  }

  void _inWorkerResponse(MessageEvent jsRequest) {
    final event = jsRequest.data as JSWorkerEvent;
    switch (event.eventType) {
      case JSWorkerType.wallet:
        _onWalletResponse((event.data as JSWalletEvent).toEvent());
        break;
      case JSWorkerType.client:
        handleClientMessage(event.data as PageMessage);
        break;
      default:
        break;
    }
  }

  bool _onMainResponse(JSWalletEvent jsEvnt) {
    final event = jsEvnt.toEvent();
    return _onWalletResponse(event);
  }

  @override
  void _listenOnClients({bool isWorker = false}) {
    if (!isWorker) {
      return super._listenOnClients();
    }
  }

  JSWebviewWallet._({
    required ChaCha20Poly1305 crypto,
    required this.clientId,
    required this.target,
    required this.isWorker,
    required AppContext context,
    Web3APPData? initializeAuthenticated,
  })  : _initializeAuthenticated = initializeAuthenticated,
        super._(crypto, context);
  factory JSWebviewWallet.initialize(
      {required JSWalletEventDart request,
      required String clientId,
      required X25519Keypair keyPair,
      required JSWebviewTraget target,
      bool isWorker = true}) {
    final peerKey = BytesUtils.fromHexString(request.additional!);
    final sharedKey = X25519.scalarMult(keyPair.privateKey, peerKey);
    final chacha = ChaCha20Poly1305(sharedKey);
    final data = List<int>.from(request.data);
    final encryptedMessage = Web3EncryptedMessage.deserialize(bytes: data);
    final decode = chacha.decrypt(encryptedMessage.nonce, encryptedMessage.message);
    final message = Web3ChainMessage.deserialize(bytes: decode);
    final context = DefaultAppContextExtensionContentScript.init().unwrap();
    final handler = JSWebviewWallet._(
        crypto: chacha,
        clientId: clientId,
        target: target,
        isWorker: isWorker,
        context: context,
        initializeAuthenticated: message.authenticated);
    if (isWorker) {
      onMessage = handler._inWorkerResponse.toJS;
    } else {
      onChain.onWebViewMessage = handler._onMainResponse.toJS;
    }

    handler._listenOnClients(isWorker: isWorker);
    return handler;
  }

  @override
  void _sendMessageToClient(WalletMessage response) {
    if (!isWorker) return super._sendMessageToClient(response);
    final event = JSWorkerEvent(type: JSWorkerType.client, data: response);
    postMessage(event);
  }

  @override
  Future<void> _sendMessageToWallet(
      {required Web3MessageCore message, required String requestId}) async {
    final encryptedMessage = _encryptMessage(message).toCbor().toCborHex();
    if (isWorker) {
      final event = JSWorkerWalletData(
          clientId: clientId,
          requestId: requestId,
          data: encryptedMessage,
          type: WalletEventTypes.message.name);
      postMessage(JSWorkerEvent(data: event, type: JSWorkerType.wallet));
      return;
    }
    if (target == JSWebviewTraget.macos) {
      jsWindow.webkit.messageHandlers.onChain.postMessage({
        "id": clientId,
        "requestId": requestId,
        "data": encryptedMessage,
        "type": WalletEventTypes.message.name
      }.jsify());
      return;
    }
    onChain.onChainInternalJsRequest(
        clientId, encryptedMessage, requestId, WalletEventTypes.message.name);
  }

  @override
  JSWalletMode get mode => JSWalletMode.webview;
}
