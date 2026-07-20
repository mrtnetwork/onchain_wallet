import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/models/others/models/wallet.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/ui_actions.dart';
import 'package:on_chain_wallet/web3/web3/core/request/web_request.dart';
import 'package:on_chain_wallet/web3/web3/networks/global/params/core/core.dart';

typedef CbOnScaffoldFeatureController = void Function(SnackbarController controller);

mixin WalletProviderUiActionController on BaseWalletProvider {
  final _lock = SafeAtomicLock();
  final _bannerLock = SafeAtomicLock();
  ScaffoldMessengerState? _getMessengerState() {
    final state = messengerKey.currentState;
    assert(state != null);
    return state;
  }

  bool _toPage(String? page, {Object? argruments}) {
    assert(page != null, "request page missing");
    if (page == null) return false;
    final state = navigatorKey.currentContext;
    assert(state != null, "Navigator state missing.");
    if (state == null) return false;
    final push = state.toSync(page, argruments: argruments);
    assert(push, "Unmounted context.");
    return push;
  }

  @override
  Future<IResult<T>> onWalletUiAction<T extends Object?>(
      WalletUiAction<T> request) async {
    Logging.debug(
      fn: () => AppLogData(
          runtime: runtimeType,
          function: "onWalletUiAction",
          msg: "New ui request ${request.runtimeType}"),
    );
    switch (request) {
      case Web3NetworkRequest request:
        final push =
            _toPage(PageRouter.web3Page(request.chain.network), argruments: request);
        if (!push) {
          return ResultErr.fromException(AppExceptionConst.walletContextNotAvailable);
        }
        final result = await request.getResponse();
        return result.map((e) => e as T);
      case Web3GlobalRequest request:
        final push = _toPage(PageRouter.web3Global, argruments: request);
        if (!push) {
          return ResultErr.fromException(AppExceptionConst.walletContextNotAvailable);
        }
        final result = await request.getResponse();
        return result.map((e) => e as T);
      case WalletUiActionChainRequest<T> request:
        return bannerActions(request);
      default:
        return ResultErr.fromException(AppExceptionConst.walletContextNotAvailable);
    }
  }

  @override
  Future<void> onWalletEvent(WalletEvent event) async {
    switch (event) {
      case WalletTimeoutEvent event:
        switch (wallet.isUnlock) {
          case false:
            _lock.run(() async {
              _closeTimersnackbar();
            });
            break;
          case true:
            switch (event.timeout) {
              case int? timeout when timeout == null || timeout > 110:
                _lock.run(() async {
                  _closeTimersnackbar();
                });
                break;
              case int _:
                if (_timerSnackbar != null || _warningMessage != null) return;
                _lock.run(() async {
                  if (_timerSnackbar != null || _warningMessage != null) return;
                  _timerSnackbar = _showTimerSnackbar();
                });
            }

            break;
        }
      case WalletActionEvent():
        switch (event.action) {
          case WalletActionEventType.lock:
            _lock.run(() async {
              _closeTimersnackbar();
            });
            break;
          default:
            break;
        }
    }
  }

  void showAlert(String message) {
    SnackbarController? controller;
    return showSnackbar(
      _createAlertSnackbar(message, () {
        controller?.close();
      }),
      (cs) {
        controller = cs;
      },
    );
  }

  void showSnackbar(SnackBar snackbar, CbOnScaffoldFeatureController onShow) {
    _lock.run(() async {
      _closeTimersnackbar();
      _closeSnackbar();
      final controller = _warningMessage = _showSnackbar(snackbar);
      if (controller == null) return;
      onShow(controller);
      await controller.closed;
      _warningMessage = null;
    });
  }

  void closeSnackBar(ScaffoldFeatureController controller) {
    _lock.run(() async {
      final c = _warningMessage;
      if (identical(c, controller)) {
        _warningMessage?.close();
      }
    });
  }

  SnackbarController? _showSnackbar(SnackBar snackbar) {
    return SnackbarController.from(_getMessengerState()?.showSnackBar(snackbar));
  }

  SnackBar _createAlertSnackbar(String message, DynamicVoid onTap) {
    return SnackBar(
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.fixed,
        actionOverflowThreshold: 0,
        elevation: 0,
        content: SnackbarAlert(message: message, onTap: onTap));
  }

  SnackbarController? _showTimerSnackbar() {
    return SnackbarController.from(_getMessengerState()?.showSnackBar(SnackBar(
      content: APPStreamWidget(
        stream: wallet.status,
        allowNotify: (value) => value.action.isLockingTimeout,
        builder: (context, _) {
          return Text("wallet_lock_timer_desc".tr.replaceOne(wallet.tick.toString()));
        },
      ),
      dismissDirection: DismissDirection.none,
      action: SnackBarAction(label: "keep_unlock".tr, onPressed: () {}),
    )));
  }

  SnackbarController? _timerSnackbar;
  SnackbarController? _warningMessage;
  void _closeTimersnackbar() {
    _timerSnackbar?.close();
    _timerSnackbar = null;
  }

  void _closeSnackbar() {
    _warningMessage?.close();
    _warningMessage = null;
  }

  SnackbarController? _banner;
  void _closeBanner() {
    _banner?.close();
    _banner = null;
  }

  Future<IResult<T>> bannerActions<T extends Object?>(
      WalletUiActionChainRequest<T> action) async {
    SnackbarController? controller;
    switch (action) {
      case WalletUiActionChainRequestLogin action:
        if (wallet.isUnlock) {
          action.complete(true);
          break;
        }
        _closeBanner();
        _bannerLock.run(() async {
          controller = _banner = SnackbarController.from(
              _getMessengerState()?.showMaterialBanner(MaterialBanner(
                  content: BannerChainInfoWidget(
                      chain: action.chain,
                      subtitle: "chain_loging_request_desc".tr,
                      onLogin: () {
                        action.complete(true);
                        controller?.close();
                      }),
                  actions: [
                CloseButton(
                  onPressed: () {
                    action.complete(false);
                    controller?.close();
                  },
                )
              ])));
          if (controller == null) {
            action.error(AppExceptionConst.walletContextNotAvailable);
            return null;
          }
          Future<dynamic> close() async {
            final result = await controller?.closed;
            if (identical(_banner, controller)) _banner = null;
            action.error(AppExceptionConst.loginRequestRejected);
            return result;
          }

          await close();
        });
    }
    final result = await action.getResponse();
    return result.mapErr((e) {
      if (e.exception == AppExceptionConst.loginTimeout) {
        controller?.close();
      }
      return e.exception;
    });
  }

  void showBanner(Widget content, CbOnScaffoldFeatureController onShow) {
    _closeBanner();
    _bannerLock.run(() async {
      SnackbarController? controller;
      controller = _banner =
          SnackbarController.from(_getMessengerState()?.showMaterialBanner(MaterialBanner(
              // minActionBarHeight: 120,
              content: content,
              actions: [
            CloseButton(
              onPressed: () {
                controller?.close();
              },
            )
          ])));
      if (controller == null) return;
      onShow(controller);
      await controller.closed;
      _banner = null;
    });
  }
}
