import 'dart:async';
import 'dart:js_interop';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_bridge/platform_interface.dart';
import 'package:on_chain_bridge/web/web.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/web/context/extension_background.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/src/background.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/storage/app_wallet_storage.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';
import '../js_crypto_utils.dart';
import '../js_wallet/constant/constant.dart';
part 'web3.dart';

typedef ONDBOPENED<T> = Future<T> Function(IDatabseInterfaceJS db);

class _JSBackgroundHandler with JSExtensionBackgroudHandler {
  @override
  final DefaultAppContextExtensionBackgroundScript context;
  final lock = SafeAtomicLock();
  static Future<IResult<_JSBackgroundHandler>> initContext() async {
    final context = await DefaultAppContextExtensionBackgroundScript.init_();
    return context.map((e) => _JSBackgroundHandler._(e));
  }

  _JSBackgroundHandler._(this.context);

  Future<void> send(JSWalletEventDart? event, int? tabId) async {
    if (event == null || tabId == null) return;
    await extension.tabs
        .sendMessage_(tabId: tabId, message: event.toJsEvent())
        .catchError((e) {
      return null;
    });
  }

  Future<void> sendAlive() async {
    final tabs = await extension.tabs.query_();
    for (final i in tabs) {
      send(
          JSWalletEventDart(
              target: WalletEventTarget.background,
              type: WalletEventTypes.ping,
              requestId: 'sendAlive'),
          i.id);
    }
  }

  static Future<JSWalletEventDart> sendWalletMessage(JSWalletEventDart msg,
      {List<WalletEventTarget> allowTargets = const [WalletEventTarget.wallet]}) async {
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
        _onContentListener = onMessage.toJS;
        extension.runtime.onMessage.addListener(_onContentListener);
        hasListener = true;
        return await completer.future;
      }
    } finally {
      if (hasListener) {
        extension.runtime.onMessage.removeListener(_onContentListener);
        _onContentListener = null;
      }
    }
  }

  Future<JSWalletEventDart> openPopup(JSWalletEventDart event) async {
    return lock.run(() async {
      final JSWalletEventDart? windowIdResponse = await extension.runtime
          .sendMessage_(message: event.copyWith(target: WalletEventTarget.background))
          .then((e) => e)
          .catchError((e) => null);
      if (windowIdResponse != null) {
        return windowIdResponse;
      }
      final newWidth = 500;
      final newHeight = 700;
      await extension.windows.create_(
        url: "${extension.runtime.getURL("index.html")}?context=popup",
        type: JSWalletConstant.extentionType,
        width: newWidth,
        height: newHeight,
        focused: true,
      );
      final result = await sendWalletMessage(
          JSWalletConstant.openExtension.copyWith(target: WalletEventTarget.background));

      return result;
    });
  }
}

@JS("OnBackgroundListener_")
external set _onContentListener(JSFunction? f);

@JS("OnBackgroundListener_")
external JSFunction get _onContentListener;

@JS("initDart")
external set initDart(JSFunction? object);
void main() {
  const mode = LoggerMode.debug;
  Logging.init(
      LoggingConfig(
          mode: mode,
          netsdk: LoggerMode.danger,
          libs: LoggerMode.danger,
          printDebug: true,
          environment: "Background Service"),
      writer: LogWriterDefault(mode));

  Future<IResult<_JSBackgroundHandler>> handler = _JSBackgroundHandler.initContext();
  extension.runtime.onInstalled.addListener((OnInstalledDetails details) {}.toJS);
  JSWalletEvent createErrorEvent(JSWalletEventDart event, IException error) {
    return JSWalletEventDart(
            clientId: event.clientId,
            data: Web3RequestExceptionConst.fromException(error)
                .toResponseMessage()
                .toCbor()
                .encode(),
            requestId: event.requestId,
            type: WalletEventTypes.exception,
            target: WalletEventTarget.background)
        .toJsEvent();
  }

  extension.runtime.onMessage.addListener(
      (JSWalletEvent? message, MessageSender sender, JSFunction sendResponse) {
    final event = message?.toEvent();

    final tab = sender.tab;
    if (event == null ||
        event.target != WalletEventTarget.external ||
        tab == null ||
        tab.id == null) {
      return false;
    }
    switch (event.type) {
      case WalletEventTypes.tabId:
      case WalletEventTypes.background:
      case WalletEventTypes.openExtension:
        handler.then((handler) {
          handler.fold(
            onErr: (error) {
              sendResponse.callAsFunction(
                  sendResponse, createErrorEvent(event, error.exception));
            },
            onOk: (handler) {
              switch (event.type) {
                case WalletEventTypes.tabId:
                case WalletEventTypes.background:
                  handler.onContentScriptMessage(sender.tab!, event).then((e) {
                    return sendResponse.callAsFunction(sendResponse, e.toJsEvent());
                  });
                  break;
                case WalletEventTypes.openExtension:
                  handler.openPopup(event).then((e) {
                    sendResponse.callAsFunction(sendResponse, e.toJsEvent());
                  });
                  break;
                default:
                  break;
              }
            },
          );
        });
        return true;
      default:
        return false;
    }
  }.toJS);
}

class BackgroundHdWallet {
  final HdWalletKey wallet;
  final WalletBackgroundController controller;
  final String id;
  const BackgroundHdWallet(
      {required this.wallet, required this.id, required this.controller});

  Future<IResult<Web3APPData>> createWeb3Auth(Web3ApplicationAuthentication app,
      {List<NetworkType>? networks}) async {
    return await controller.createWeb3Auth(app, networks: networks);
  }

  Future<IResult<void>> disconnectWeb3Chain(Web3ApplicationAuthentication app,
      {List<NetworkType>? networks}) async {
    return controller.disconnectWeb3Chain(app, networks: networks);
  }
}
