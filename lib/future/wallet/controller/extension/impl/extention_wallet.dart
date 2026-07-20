import 'dart:async';
import 'dart:js_interop';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_bridge/web/web.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:on_chain_wallet/future/wallet/controller/extension/models/models.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/web3/controller/web3_request_controller.dart';
import 'package:on_chain_wallet/future/wallet/web3/types/types.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';

mixin ExtentionWalletHandler on Web3RequestControllerImpl {
  ExtensionWalletContext _context = ExtensionWalletContext.init;
  final Cancelable _cancelable = Cancelable();
  ExtensionWalletContext get context => _context;
  GlobalKey<NavigatorState> get navigatorKey;
  List<ExtensionWalletContextType> _supportedActions = [];
  List<ExtensionWalletContextType> get supportedActions => _supportedActions;
  final _lock = SafeAtomicLock();
  final Map<String, String> _clientsIds = {};

  @override
  Future<void> sendMessageToClient(
      {required Web3ActiveClient client, required Web3EncryptedMessage message}) async {
    final event = toResponseEvent(
        id: client.clientId,
        type: WalletEventTypes.message,
        data: message.toCbor().encode());
    _sendToClient(event, client);
  }

  Future<IResult<void>> initContext() async {
    final parse = Uri.tryParse(jsWindow.location.search ?? '');
    final context = ExtensionWalletContextType.fromName(
        parse?.queryParameters[ExtentionSessionStorageConst.contextQueryParameters]);
    final window = (await _getWindow());
    final windowId = window.id;
    if (windowId == null || context == null) {
      return ResultErr.fromException(AppException('initialize_app_failed'));
    }
    int? tabId;
    if (context.isTab) {
      final tab = window.tabs?.toDart
          .firstWhereNullable((e) => e.url?.contains(jsWindow.location.href) ?? false);
      tabId = tab?.id;
      if (tabId == null) {
        return ResultErr.fromException(AppException('initialize_app_failed'));
      }
    }
    final isIframe =
        parse?.queryParameters[ExtentionSessionStorageConst.viewQueryParameters] ==
            ExtentionSessionStorageConst.iframeName;
    _context = ExtensionWalletContext(
        context: context,
        windowId: windowId,
        instanceId: UUID.generateUUIDv4(),
        tabId: tabId,
        iframe: isIframe);
    _supportedActions = [
      ExtensionWalletContextType.popup,
      ExtensionWalletContextType.tab,
      if (extension.sidePanelNullable?.openFunc != null)
        ExtensionWalletContextType.sidePanel,
      if (extension.sidebarActionNullable?.openFunc != null ||
          oprNullable?.sidebarActionNullable?.openFunc != null)
        ExtensionWalletContextType.sidebarAction,
    ].immutable;

    final exists = await _getAllActiveIntance();
    if (exists.isEmpty) return ResultOk(null);
    await navigatorKey.currentContext?.openSliverDialog<bool>(
        widget: (context) => DuplicateExtensionInstanceAlert(),
        label: 'duplicate_wallet_instance'.tr,
        dismissible: false);
    _closeSelf();
    return ResultErr.fromException(AppException('initialize_app_failed'));
  }

  Future<void> initExtension() async {
    extension.runtime.onMessage.addListener(_onRuntimeMessage.toJS);
    extension.runtime.onConnect.addListener(_onConnet.toJS);
    extension.runtime.sendMessage_(
        message: JSWalletEventDart(
            target: WalletEventTarget.wallet,
            type: WalletEventTypes.ping,
            requestId: 'initExtension'));
    await _getInitializeTab().then((e) => _updateLatestClient(e));
    extension.tabs.onActivated.addListener(_onTabActive.toJS);
    extension.tabs.onUpdated.addListener(_onTabUpdate.toJS);
    extension.windows.onFocusChanged.addListener(_onWindowFocusChanged.toJS);
    extension.tabs.onRemoved.addListener(_onTabRemoved.toJS);
  }

  Future<void> openPopup(ExtensionWalletContextType context) async {
    if (context == ExtensionWalletContextType.action) return;
    await _lock.run(() async {
      switch (context) {
        case ExtensionWalletContextType.sidePanel:
          await extension.sidePanel.open_(windowId: this.context.windowId);
          break;
        case ExtensionWalletContextType.sidebarAction:
          if (extension.sidebarActionNullable?.openFunc != null) {
            await extension.sidebarAction.open_();
          } else {
            await oprNullable?.sidebarAction.open_();
          }
          break;
        case ExtensionWalletContextType.tab:
          await extension.tabs
              .create_(url: "${extension.runtime.getURL("side_panel.html")}?context=tab");
          break;
        default:
          final info = await extension.windows.getCurrent_(populate: true);
          final newLeft = IntUtils.max(0, info.left! + 100);
          final newTop = IntUtils.max(0, info.top! + 100);
          final newWidth = 400;
          final newHeight = 600;
          await extension.windows.create_(
              url: "${extension.runtime.getURL("index.html")}?context=popup",
              type: ExtentionSessionStorageConst.extentionType,
              width: newWidth,
              height: newHeight,
              top: newTop,
              focused: true,
              left: newLeft);
          break;
      }
      _closeSelf();
    });
  }

  Future<ChromeTab?> _getInitializeTab() async {
    if (!context.context.isPopup) {
      ChromeWindow windows = await extension.windows.get_(
        context.windowId,
        populate: true,
        windowTypes: [ExtentionSessionStorageConst.normalTabType],
      );
      return (windows.tabs?.toDart ?? <ChromeTab>[]).firstWhereOrNull((e) => e.active);
    }
    List<ChromeWindow> windows = await extension.windows.getAll_(populate: true);

    final validWindowses = windows.where((e) => e.id != context.windowId);
    final focusedWindows = validWindowses.firstWhereOrNull((e) => e.focused == true);
    final tabs = validWindowses.expand((e) => e.tabs?.toDart ?? <ChromeTab>[]);
    if (focusedWindows != null) {
      return tabs.firstWhereOrNull((e) => e.active && e.id == focusedWindows.id);
    }
    return tabs.firstWhereOrNull((e) => e.active);
  }

  void _closeSelf() {
    if (context.context == ExtensionWalletContextType.sidebarAction) {
      extension.sidebarAction.close_();
    } else if (context.iframe) {
      jsWindow.parent?.postMessage(ExtentionSessionStorageConst.closeEvent.jsify());
    } else {
      jsWindow.close();
    }
  }

  bool _onRuntimeMessage(
      JSWalletEvent? message, MessageSender sender, JSFunction sendResponse) {
    final event = message?.toEvent();
    Logging.debug(
        fn: () => AppLogData(
              runtime: runtimeType,
              function: "_onRuntimeMessage",
              msg: "New web3 message: ${event?.type}",
            ));
    if (event == null) return false;
    switch (event.type) {
      case WalletEventTypes.openExtension:
        sendResponse.callAsFunction(
            null,
            JSWalletEventDart(
                    target: WalletEventTarget.wallet,
                    type: WalletEventTypes.ping,
                    requestId: 'wallet _onRuntimeMessage')
                .toJsEvent());
        _focusCurrent();
        return true;
      case WalletEventTypes.close:
        if (event.clientId == context.instanceId) return false;
        final instance = StringUtils.tryDecode(event.data);
        if (instance == context.instanceId) {
          _closeSelf();
        }
        break;
      case WalletEventTypes.windowId:
        if (event.clientId == context.instanceId) return false;
        if (event.platform == null) return false;
        final contextType = ExtensionWalletContextType.fromName(event.platform);
        if (context.context != contextType) return false;
        sendResponse.callAsFunction(
            null,
            JSWalletEventDart(
                    type: WalletEventTypes.windowId,
                    target: WalletEventTarget.wallet,
                    clientId: context.instanceId)
                .toJsEvent());
        return true;
      case WalletEventTypes.tabId:
        final tab = sender.tab;
        if (tab == null) return false;
        _onAuthTabMessage(tab: tab, event: event)
            .then((e) => sendResponse.callAsFunction(null, e.toJsEvent()));
        return true;
      default:
        break;
    }
    return false;
  }

  Future<JSWalletEventDart> _onAuthTabMessage(
      {required ChromeTab tab, required JSWalletEventDart event}) async {
    _onTabRemoved(tab.id);

    final client = await _getTabInfo(tab, clientId: event.clientId);
    final auth = await createPageAuthenticated(
        peerKey: event.clientId,
        identifier: tab.id.toString(),
        info: client.client?.client);
    _lock.run(() {
      if (client.identifier == latestClient.value.identifier) {
        _updateLatestClient(tab);
      }
    });
    return auth.event.copyWith(additional: "${tab.id}:${auth.event.additional}");
  }

  void _onMessage(JSWalletEvent message, RuntimePort port) async {
    final event = message.toEvent();
    Logging.debug(
        fn: () => AppLogData(
              runtime: runtimeType,
              function: "_onMessage",
              msg: "New web3 message: ${event?.type}",
            ));
    if (event == null || event.target != WalletEventTarget.external) return;
    if (event.type == WalletEventTypes.ping) {
      port.postMessage(message);
      return;
    }
    final tabId = int.tryParse(event.additional ?? '');
    final tab = await _getTab(id: tabId);
    final client = await _getTabInfo(tab);
    _focusCurrent();
    final Completer<JSWalletEventDart?> completer = Completer();
    onRequest(
        request: event,
        identifier: event.additional!,
        url: tab?.url,
        title: tab?.title,
        image: tab?.favIconUrl,
        completer: completer);

    void onDisconnect(RuntimePort port) {
      onWeb3ClinetDisconnected(client.client);
    }

    port.onDisconnect.addListener(onDisconnect.toJS);
    final responseEvent = await completer.future;
    Logging.debug(
        fn: () => AppLogData(
              runtime: runtimeType,
              function: "_onMessage",
              msg: "Web respone: $responseEvent",
            ));
    bool result = responseEvent != null;
    if (responseEvent != null) {
      port.postMessage(responseEvent.toJsEvent());
    }
    completeRequest(requestId: event.requestId, clientId: event.clientId, result: result);
    if (tabId != null) await extension.tabs.update_(tabId, active: true);
  }

  void _onConnet(RuntimePort port) {
    port.onMessage.addListener(_onMessage.toJS);
  }

  Web3ClientInfo? _createClientInfosFromTab(ChromeTab? tab) {
    if (tab == null) return null;
    final id = tab.id;
    if (id == null || id.isNegative || id == context.tabId) return null;
    return createClientInfos(
        clientId: "$id", url: tab.url, title: tab.title, faviIcon: tab.favIconUrl);
  }

  String _createClientIdentifier(Web3ClientInfo client, int? tabId) {
    assert(tabId != null, "invalid tabId");
    return "$tabId:${client.identifier}";
  }

  Future<LastWeb3ActiveClient> _getTabInfo(ChromeTab? tab, {String? clientId}) async {
    if (tab == null || tab.id == null) {
      return LastWeb3ActiveClient(web3Status: WalletJSScriptStatus.unknownHost);
    }
    final client = _createClientInfosFromTab(tab);
    if (client == null) {
      return LastWeb3ActiveClient(
          web3Status: WalletJSScriptStatus.unknownHost,
          identifier: tab.id.toString(),
          url: tab.url);
    }
    final identifier = _createClientIdentifier(client, tab.id);
    if (clientId != null && !_clientsIds.containsKey(identifier)) {
      _clientsIds[identifier] = clientId;
    }
    clientId ??= _clientsIds[identifier];
    if (clientId == null) {
      final r = await extension.tabs
          .sendMessage_(
              tabId: tab.id!,
              message: JSWalletEventDart(
                target: WalletEventTarget.external,
                type: WalletEventTypes.tabId,
              ).toJsEvent())
          .timeout(const Duration(seconds: 5))
          .catchError((_) {
        return null;
      });
      clientId = r?.clientId;
      if (clientId != null) {
        _clientsIds[identifier] = clientId;
      }
    }
    if (clientId == null) {
      return LastWeb3ActiveClient(
          web3Status: WalletJSScriptStatus.failed,
          identifier: tab.id.toString(),
          url: tab.url);
    }
    final key = await getEncryptionKey(
        clientId: clientId, identifier: tab.id.toString(), client: client);
    return LastWeb3ActiveClient(
        web3Status: WalletJSScriptStatus.active,
        client: key,
        identifier: tab.id.toString(),
        url: tab.url);
  }

  Future<void> _updateLatestClient(ChromeTab? tab) async {
    _cancelable.cancel();
    await _lock.run(() async {
      latestClient.value = LastWeb3ActiveClient();
      final result = await IResult.call(() => _getTabInfo(tab), cancelable: _cancelable);
      if (result.isErr) return;
      latestClient.value = result.unwrap();
    });
  }

  void _onTabActive(ActiveInfo info) async {
    if (context.context == ExtensionWalletContextType.popup &&
        info.windowId == context.windowId) {
      return;
    }
    if (context.context == ExtensionWalletContextType.tab &&
        info.tabId == context.tabId) {
      return;
    }

    final tab = await _getTab(id: info.tabId);
    _updateLatestClient(tab);
  }

  void _onTabUpdate(int id, ChangeInfo info, ChromeTab tab) async {
    if (info.status != ExtentionSessionStorageConst.updateTabCompleteStatus) {
      return;
    }
    if (context.context == ExtensionWalletContextType.popup &&
        tab.windowId == context.windowId) {
      return;
    }
    if (context.context == ExtensionWalletContextType.tab && id == context.tabId) {
      return;
    }
    _onTabRemoved(tab.id);
    _updateLatestClient(tab);
  }

  void _onTabRemoved(int? tabId) async {
    if (tabId == null) return;
    _clientsIds.removeWhere((k, v) => k.startsWith("$tabId:"));
    onWeb3ClientRemoved(tabId.toString());
  }

  void _onWindowFocusChanged(int windowId) async {
    if (context.context == ExtensionWalletContextType.popup &&
        windowId == context.windowId) {
      return;
    }
    final tab = await _getLatestWindowTab(windowId);
    if (context.context == ExtensionWalletContextType.tab && tab?.id == context.tabId) {
      return;
    }
    _updateLatestClient(tab);
  }

  Future<ChromeWindow> _getWindow() async {
    return await extension.windows.getCurrent_(populate: true);
  }

  Future<ChromeTab?> _getTab({String? idStr, int? id}) async {
    if (idStr == null && id == null) return null;
    id ??= IntUtils.tryParse(idStr);
    if (id == null) return null;
    try {
      return await extension.tabs.get_(id);
    } catch (_) {
      return null;
    }
  }

  Future<ChromeTab?> _getLatestWindowTab(int windowId) async {
    try {
      final tab = await extension.tabs.query_(active: true, windowId: windowId);
      return tab.firstOrNull;
    } catch (_) {
      return null;
    }
  }

  Future<void> _focusCurrent() async {
    switch (context.context) {
      case ExtensionWalletContextType.sidePanel:
      case ExtensionWalletContextType.popup:
        await extension.windows.update_(context.windowId, focused: true);
        break;
      case ExtensionWalletContextType.tab:
        await extension.windows.update_(context.windowId, focused: true);
        await extension.tabs.update_(context.tabId, active: true);
        break;
      default:
    }
  }

  Future<List<String>> _getAllActiveIntance() async {
    final List<String> existsContext = [];
    for (final i in ExtensionWalletContextType.values) {
      final r = await IResult.call(() async {
        return await extension.runtime.sendMessage_(
            message: JSWalletEventDart(
                target: WalletEventTarget.wallet,
                type: WalletEventTypes.windowId,
                clientId: context.instanceId,
                platform: i.name));
      });
      final event = r.ok();
      if (event == null) continue;
      existsContext.add(event.clientId);
    }
    return existsContext;
  }

  Future<void> _sendToClient(JSWalletEventDart event, Web3ActiveClient client) async {
    await extension.tabs
        .sendMessage_(tabId: int.parse(client.identifier), message: event.toJsEvent())
        .timeout(APPConst.tenSecoundDuration)
        .catchError((e) {
      return null;
    });
  }
}
