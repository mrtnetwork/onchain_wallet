part of 'core/wallet.dart';

@JS("PINGREFRENCE_")
external set _pingRefrence(JSFunction? f);
@JS("PINGREFRENCE_")
external JSFunction get pringRefrence;

@JS("OnBackgroundListener_")
external set _onBackgroundListener(JSFunction? f);
@JS("OnBackgroundListener_")
external JSFunction get _onBackgroundListener;

class JSExtentionWallet extends Web3JSWalletHandler {
  final _portLock = SafeAtomicLock();
  @override
  final String clientId;
  final String tabId;
  RuntimePort? _port;
  Web3APPData? _initializeAuthenticated;

  bool onMessage(JSWalletEvent message, MessageSender sender, JSFunction sendResponse) {
    final event = message.toEvent();
    if (event == null) return false;
    switch (event.type) {
      case WalletEventTypes.tabId:
        final response = JSWalletEventDart(
                target: WalletEventTarget.external,
                type: WalletEventTypes.tabId,
                clientId: clientId)
            .toJsEvent();
        sendResponse.callAsFunction(sendResponse, response);
        return true;
      default:
        final update = _onWalletResponse(message.toEvent());
        final response = JSWalletEventDart(
            target: WalletEventTarget.external,
            type: WalletEventTypes.message,
            clientId: clientId,
            data: [update ? 1 : 0]).toJsEvent();
        sendResponse.callAsFunction(sendResponse, response);
        return true;
    }
  }

  JSExtentionWallet._(
      {required ChaCha20Poly1305 crypto,
      required this.clientId,
      required this.tabId,
      required Web3APPData authenticated,
      required AppContext context})
      : _initializeAuthenticated = authenticated,
        super._(crypto, context);

  static JSExtentionWallet initialize(
      {required JSWalletEventDart activationEvent,
      required X25519Keypair keypair,
      required AppContext context}) {
    final additional = activationEvent.additional!.split(":");
    final peerKey = BytesUtils.fromHexString(additional[1]);
    final sharedKey =
        JsCryptoUtils.generateShareKey(privateKey: keypair.privateKey, peerKey: peerKey);
    final chacha = ChaCha20Poly1305(sharedKey);
    final data = List<int>.from(activationEvent.data);
    final encryptedMessage = Web3EncryptedMessage.deserialize(bytes: data);
    final decode = chacha.decrypt(encryptedMessage.nonce, encryptedMessage.message);
    final message = Web3ChainMessage.deserialize(bytes: decode);

    final handler = JSExtentionWallet._(
        crypto: chacha,
        clientId: activationEvent.clientId,
        authenticated: message.authenticated,
        context: context,
        tabId: additional[0]);
    handler._listenOnClients();
    extension.runtime.onMessage.addListener(handler.onMessage.toJS);
    return handler;
  }

  void initClients() {
    final auth = _initializeAuthenticated;
    if (auth == null) return;
    _initializeAuthenticated = null;
    _updateAuthenticated(auth);
  }

  void _onExtentionPortDiscounect(RuntimePort port) {
    _portLock.run(() {
      _port = null;
    });
  }

  void _onExtentionPortMessage(JSWalletEvent event, RuntimePort port) {}
  static Future<RuntimePort?> _pingPort(RuntimePort? newPort) async {
    if (newPort == null) return null;
    final completer = Completer<RuntimePort>();

    try {
      void onEmitMessage(JSWalletEvent? message, RuntimePort port) {
        final event = message?.toEvent();
        if (event?.type != WalletEventTypes.ping) return;
        completer.complete(port);
      }

      _pingRefrence = onEmitMessage.toJS;
      newPort.postMessage(JSWalletEventDart(
              target: WalletEventTarget.external,
              type: WalletEventTypes.ping,
              requestId: 'extension newPort')
          .toJsEvent());
      newPort.onMessage.addListener(pringRefrence);
      final result = await completer.future;
      return result;
    } finally {
      newPort.onMessage.removeListener(pringRefrence);
      _pingRefrence = null;
    }
  }

  Future<RuntimePort?> _getPort() async {
    return _portLock.run(() async {
      final RuntimePort? port = await _pingPort(_port);
      if (port != null) return port;
      return null;
    });
  }

  Future<RuntimePort> _openPort() async {
    return _portLock.run(() async {
      final RuntimePort? port = await _pingPort(_port);
      if (port != null) return port;
      _port?.disconnect();
      _port = null;
      final newPort = await _pingPort(extension.runtime
          .connect(extension.runtime.id, ConnectConnectionInf(name: clientId)));
      if (newPort == null) {
        throw UnimplementedError('port not found');
      }
      _port = newPort;
      _port!.onDisconnect.addListener(_onExtentionPortDiscounect.toJS);
      _port!.onMessage.addListener(_onExtentionPortMessage.toJS);
      return _port!;
    });
  }

  static Future<JSWalletEventDart> sendBackgroudMessage(JSWalletEventDart msg,
      {List<WalletEventTarget> allowTargets = const [
        WalletEventTarget.background
      ]}) async {
    bool hasListener = false;
    try {
      final Completer<JSWalletEventDart> completer = Completer<JSWalletEventDart>();
      bool onMessage(
          JSWalletEvent? message, MessageSender? sender, JSFunction? sendResponse) {
        final event = message?.toEvent();
        if (event == null) return false;
        if (event.type != WalletEventTypes.ping) return false;
        if (!allowTargets.contains(event.target)) {
          return false;
        }
        final result = extension.runtime.sendMessage_(message: msg);

        result.then((e) {
          completer.complete(e);
        });
        result.catchError((e) {
          completer.completeError(e);
          return null;
        });
        return true;
      }

      try {
        final r = await extension.runtime.sendMessage_(message: msg);
        return r!;
      } catch (e) {
        _onBackgroundListener = onMessage.toJS;
        extension.runtime.onMessage.addListener(_onBackgroundListener);
        hasListener = true;
        return await completer.future;
      }
    } finally {
      if (hasListener) {
        extension.runtime.onMessage.removeListener(_onBackgroundListener);
      }
    }
  }

  Future<void> _sendMessageToExtention(
      {required JSWalletEventDart message, required String requestId}) async {
    RuntimePort? port = await _getPort();
    if (port == null) {
      final openWallet = await sendBackgroudMessage(JSWalletConstant.openExtension,
              allowTargets: [WalletEventTarget.wallet, WalletEventTarget.background])
          .timeout(const Duration(seconds: 10))
          .catchError((e) {
        return throw Web3RequestExceptionConst.internalErr("_sendMessageToExtention",
            reason: "Failed to start background service. ${e.toString()}");
      });
      if (openWallet.target != WalletEventTarget.wallet &&
          openWallet.type != WalletEventTypes.ping) {
        throw Exception("Open popup failed");
      }
    }
    port ??= await _openPort();
    void onDisconnect(RuntimePort port) {
      completer.complete(
          response: Web3RequestExceptionConst.rejectedByUser
              .toResponseMessage(requestId: requestId),
          requestId: requestId);
    }

    void onMessage(JSWalletEvent event, RuntimePort port) {
      if (event.clientId != clientId || event.requestId != requestId) return;
      _onWalletResponse(event.toEvent());
    }

    port.onDisconnect.addListener(onDisconnect.toJS);
    port.onMessage.addListener(onMessage.toJS);
    port.postMessage(message.toJsEvent());
  }

  @override
  Future<void> _sendMessageToWallet(
      {required Web3WalletRequestParams message, required String requestId}) async {
    final encryptedMessage = _encryptMessage(message).toCbor().encode();
    switch (message.method) {
      case Web3GlobalRequestMethods.disconnect:
      case Web3GlobalRequestMethods.connectSilent:
        final event = JSWalletEventDart(
            clientId: clientId,
            data: encryptedMessage,
            requestId: requestId,
            type: WalletEventTypes.background,
            target: WalletEventTarget.external);
        final r = await sendBackgroudMessage(event);
        _onWalletResponse(r);
        break;
      default:
        final event = JSWalletEventDart(
            clientId: clientId,
            data: encryptedMessage,
            requestId: requestId,
            type: WalletEventTypes.message,
            target: WalletEventTarget.external,
            additional: tabId);
        await _sendMessageToExtention(message: event, requestId: requestId);
        break;
    }
  }

  @override
  JSWalletMode get mode => JSWalletMode.extension;
}
