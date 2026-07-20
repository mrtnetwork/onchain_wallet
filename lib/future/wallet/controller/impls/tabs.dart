import 'dart:async';
import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/controller/wallet/ui_wallet.dart';
import 'package:on_chain_wallet/future/wallet/swap/controller/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/webview/controller/controller/controller.dart';
import 'package:on_chain_wallet/marketcap/prices/live_currency.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/others/models/wallet.dart';

enum WalletPage {
  wallet,
  swap,
  webview;

  bool get inWallet => this == wallet;
  bool get inSwap => this == swap;
  bool get inWebview => this == webview;
  static WalletPage findCurrentPage({required int index, required bool hasSwap}) {
    if (index == 0) return WalletPage.wallet;
    if (index == 2) return WalletPage.webview;
    if (hasSwap) return WalletPage.swap;
    return WalletPage.webview;
  }
}

mixin WalletProviderTabController on BaseWalletProvider {
  final _lock = SafeAtomicLock();
  @override
  late final LiveCurrencies currency = LiveCurrencies(wallet.config.netApi);
  WebViewController? _webviewController;
  SwapStateController? _swap;
  bool get supportWebView;
  @override
  UIWallet get wallet;
  bool _enableSwap = false;
  bool get enableSwap => _enableSwap;
  bool _enableWebview = false;
  bool get enableWebView => _enableWebview;
  bool _multipleTab = false;
  bool get multipleTab => _multipleTab;
  WebViewController? get webviewContoller => _webviewController;
  SwapStateController? get swap => _swap;

  WalletPage _walletPage = WalletPage.wallet;
  WalletPage get walletPage => _walletPage;
  int _homepageIndex = 0;
  int get homepageIndex => _homepageIndex;

  bool _canPop = false;

  bool get canPop => _canPop;
  Timer? _popTimer;
  bool _isReady = false;

  final Cancelable _cancelable = Cancelable();

  bool get allowRefresh =>
      (walletPage.inWallet && wallet.isOpen) ||
      (walletPage.inWebview && (webviewContoller?.page.inBrowser ?? false));

  void onAppBackButton(bool canPop, Object? n) {
    if (canPop) return;
    if (_walletPage.inWebview) {
      final webview = _webviewController;
      if (webview == null || webview.onBackButton()) {
        onChangeIndex(0);
      }
    } else if (!_walletPage.inWallet) {
      onChangeIndex(0);
    } else {
      _canPop = true;
      wallet.navigatorKey.currentContext?.showAlert("press_back_button_twice".tr);
      _resetPopTimer();
      notify();
    }
  }

  void toggleWebView() {
    _enableWebview = !_enableWebview;
    updateAppSettings(appSetting.copyWith(
        walletSetting: appSetting.walletSetting.copyWith(enableWebView: _enableWebview)));
    _lock.run(() async {
      if (!_enableWebview) {
        await _webviewController?.dispose();
        _webviewController = null;
      } else {
        await _initWebView();
      }
      _multipleTab = _enableSwap || _enableWebview;
      onChangeIndex(0);
      notify();
    });
  }

  void toggleSwap() {
    _enableSwap = !_enableSwap;
    updateAppSettings(appSetting.copyWith(
        walletSetting: appSetting.walletSetting.copyWith(enableSwap: _enableSwap)));
    _lock.run(() async {
      if (!_enableSwap) {
        _swap?.dispose();
        _swap = null;
      } else {
        await _initSwap();
      }
      _multipleTab = _enableSwap || _enableWebview;
      onChangeIndex(0);
      notify();
    });
  }

  void onChangeIndex(int index) {
    if (index == homepageIndex) return;
    _canPop = false;
    _homepageIndex = index;
    _walletPage = WalletPage.findCurrentPage(index: index, hasSwap: _enableSwap);
    _swap?.onWalletPageChanged(_walletPage);
    _cancelable.cancel();
    notify();
  }

  @override
  Future<void> onWalletEvent(WalletEvent event) async {
    super.onWalletEvent(event);
    switch (event.walletStatus) {
      case WStatus.lock:
        await _dispose();
        onChangeIndex(0);
        break;
      case WStatus.unlock || WStatus.readOnly when !_isReady:
        _initTabs();
        break;
      default:
    }
    await _webviewController?.onWalletEvent(event);
  }

  Future<void> onRefresh() async {
    _cancelable.dispose();
    await IResult.call(() async {
      switch (walletPage) {
        case WalletPage.wallet:
          if (!wallet.isOpen) return;
          final result = await wallet.currentChain.updateCurrentAddressBalance();
          result.watch(
              onErr: (error) =>
                  wallet.navigatorKey.currentContext?.showAlert(error.localizationError));
        case WalletPage.webview:
          return await webviewContoller?.reload();
        default:
      }
    }, cancelable: _cancelable);
  }

  Future<IResult<void>> setAccountProvider(
      {required NetworkClientConfig provider, required Chain account}) async {
    _cancelable.cancel();
    return await account.setServiceProvider(provider);
  }

  Future<bool> _initWebView() async {
    if (_webviewController == null &&
        supportWebView &&
        appSetting.walletSetting.enableWebView) {
      final controller =
          context.platformInterface().andThen((e) => e.webView.toResult()).ok();
      if (controller == null) return false;
      _webviewController = WebViewController(
          walletCore: wallet, observer: observer, webViewController: controller);
      await _webviewController?.init();
      _enableWebview = true;
      return true;
    }
    return false;
  }

  Future<bool> _initSwap() async {
    if (_swap == null && appSetting.walletSetting.enableSwap) {
      _swap = SwapStateController(
          chains: wallet.getChains(),
          liveCurrencies: currency,
          database: wallet.config.database,
          netApi: wallet.config.netApi);
      _swap?.initSwap();
      _enableSwap = true;
      return true;
    }
    return false;
  }

  Future<void> _initTabs() async {
    _lock.run(() async {
      final webView = await _initWebView();
      final swap = await _initSwap();
      final multipleTab = _enableSwap || _enableWebview;
      if (webView || swap || multipleTab != this.multipleTab) {
        _multipleTab = multipleTab;
        notify();
      }
      _isReady = true;
    });
  }

  Future<void> _dispose() async {
    _lock.run(() async {
      if (!_isReady) return;
      _isReady = false;
      _swap?.dispose();
      _swap = null;
      _enableSwap = false;
      await _webviewController?.dispose();
      _webviewController = null;
      _enableWebview = false;
      _multipleTab = _enableSwap || _enableWebview;
      notify();
    });
  }

  void _resetPopTimer() {
    _popTimer?.cancel();
    _popTimer = null;
    _popTimer = Timer(APPConst.twoSecoundDuration, () {
      if (!_canPop) return;
      _canPop = false;
      notify();
    });
  }
}
