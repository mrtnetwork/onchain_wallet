import 'dart:async';
import 'package:flutter/material.dart';
import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/future/state_managment/core/observer.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/tools/frame_tracker/desktop_frame_tracker.dart';
import 'package:on_chain_wallet/future/wallet/controller/impls/action_controller.dart';
import 'package:on_chain_wallet/future/wallet/controller/impls/tabs.dart';
import 'package:on_chain_wallet/future/wallet/controller/impls/theme.dart';
import 'package:on_chain_wallet/marketcap/prices/live_currency.dart';
import 'package:on_chain_wallet/wallet/models/others/models/wallet.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/ui_actions.dart';
import 'wallet/ui_wallet.dart';
export 'types/types.dart';
import 'wallet/cross/cross.dart'
    if (dart.library.js_interop) 'wallet/cross/web.dart'
    if (dart.library.io) 'wallet/cross/native.dart';

enum APPStatusType {
  init,
  ready,
  failed;

  bool get isInit => this == init;
  bool get isError => this == failed;
}

class APPStatus {
  final APPStatusType status;
  final String? error;
  const APPStatus._({required this.status, this.error});
  factory APPStatus.error(String error) {
    return APPStatus._(status: APPStatusType.failed, error: error);
  }
  static const APPStatus init = APPStatus._(status: APPStatusType.init);
  static const APPStatus ready = APPStatus._(status: APPStatusType.ready);
}

abstract class BaseWalletProvider extends StateController with DesktopFrameTracker {
  WalletRouteObserver get observer;
  UIWallet get wallet;
  @override
  MainAppContext get context;
  @override
  GlobalKey<NavigatorState> get navigatorKey;
  GlobalKey<ScaffoldMessengerState> get messengerKey;
  Future<void> onWalletEvent(WalletEvent event);
  Future<IResult<T>> onWalletUiAction<T extends Object?>(WalletUiAction<T> request);
  LiveCurrencies get currency;
  @override
  APPStatus get appStatus;
  void updateAppSettings(APPSetting setting);
  APPSetting get appSetting;
  bool get supportTorConnection;
  bool get supportBarcodeScanner;
  bool get isExtension;
}

class WalletProvider extends BaseWalletProvider
    with
        WalletProviderUiActionController,
        WalletProviderTabController,
        WalletProviderThemeController {
  @override
  final GlobalKey<ScaffoldMessengerState> messengerKey;
  @override
  final MainAppContext context;
  APPStatus _status = APPStatus.init;
  @override
  APPStatus get appStatus => _status;
  StreamSubscription<WalletEvent>? _onWalletStatus;
  @override
  APPSetting get appSetting => context.setting.setting;

  @override
  GlobalKey<NavigatorState> get navigatorKey => wallet.navigatorKey;
  @override
  final WalletRouteObserver observer;
  @override
  final UIWallet wallet;

  @override
  bool get supportWebView => context.setting.supportWebView;

  @override
  bool get supportTorConnection => context.netApi.supportTorConnection;
  @override
  bool get supportBarcodeScanner => context.setting.supportBarcodeScanner;
  @override
  bool get isExtension => context.setting.isExtension;
  WalletProvider(
      {required IResult<MainAppContext> contextResult,
      required this.observer,
      required GlobalKey<NavigatorState> navigatorKey,
      required this.messengerKey})
      : context =
            contextResult.unwrapOr((err) => DisabledMainAppContext(AppPlatform.android)),
        wallet = uiWallet(
            navigatorKey,
            contextResult
                .unwrapOr((err) => DisabledMainAppContext(AppPlatform.android))) {
    contextResult.mapErr((e) {
      _status = APPStatus.error(e.localizationError);
      return e.exception;
    });
  }

  @override
  void updateAppSettings(APPSetting setting) {
    context.setting.updateAppSettingSync(setting);
  }

  void changeCurrency(Currency? currency) {
    if (currency == null || appSetting.currency == currency) return;
    this.currency.changeCurrency(currency);
    updateAppSettings(appSetting.copyWith(currency: currency));
  }

  void onAppHover() {
    wallet.onWalletIntraction();
  }

  Future<void> _initWallet() async {
    if (_status.status.isInit) {
      final init = await wallet.init();
      init.fold(
        onErr: (error) {
          _status = APPStatus.error(error.localizationError);
        },
        onOk: (value) {
          _status = APPStatus.ready;
        },
      );
    }
    notify();
  }

  @override
  Future<void> onWalletEvent(WalletEvent event) async {
    if (!event.status.isSuccess) return;
    switch (event.walletStatus) {
      case WStatus.init:
      case WStatus.setup:
      case WStatus.lock:
        navigatorKey.currentContext?.popToHome();
        break;
      case WStatus.readOnly || WStatus.unlock
          when (!currency.inited ||
              event.action == WalletActionEventType.updateAccount ||
              event.action == WalletActionEventType.importNetwork ||
              event.action == WalletActionEventType.switchWallet):
        final coinIds =
            wallet.getChains().map((e) => e.network.token.market?.apiId).toList();
        final tokens = await wallet.currentChain.tokens();
        tokens.map((tokens) {
          coinIds.addAll(tokens.map((e) => e.token.market?.apiId));
          currency.streamPrices(coinIds.whereType<String>().toList());
        });
        break;
      case WStatus.readOnly:
      case WStatus.unlock:
        break;
    }
    switch (event.action) {
      case WalletActionEventType.switchNetwork:
        final tokens = await wallet.currentChain.tokens();
        tokens.map((tokens) {
          currency.streamPrices(
              tokens.map((e) => e.token.market?.apiId).whereType<String>().toList());
        });
        break;
      case WalletActionEventType.setup:
      case WalletActionEventType.removeWallet:
        navigatorKey.currentContext?.popToHome();
        break;
      default:
    }
    await super.onWalletEvent(event);
  }

  @override
  void close() {
    super.close();
    _onWalletStatus?.cancel();
    _onWalletStatus = null;
  }

  @override
  void ready() {
    super.ready();
    FocusManager.instance.addListener(onAppHover);
    currency.changeCurrency(appSetting.currency);
    _onWalletStatus = wallet.status.stream.listen(onWalletEvent);
    _initWallet();
  }
}
