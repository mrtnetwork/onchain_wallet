import 'dart:async';
import 'package:flutter/material.dart';
import 'package:on_chain_bridge/web/api/chrome/api/core.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/future/wallet/controller/extension/impl/extension_wallet_login.dart';
import 'package:on_chain_wallet/future/wallet/controller/extension/impl/extention_wallet.dart';
import 'package:on_chain_wallet/future/wallet/controller/wallet/ui_wallet.dart';
import 'package:on_chain_wallet/future/wallet/web3/controller/web3_request_controller.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'native.dart';

UIWallet uiWallet(GlobalKey<NavigatorState> navigatorKey, MainAppContext context) {
  if (context.platform.isWeb && isExtension) {
    return ExtentionWallet(navigatorKey: navigatorKey, context: context);
  }
  return Wallet(navigatorKey: navigatorKey, context: context);
}

class ExtentionWallet extends UIWallet
    with Web3RequestControllerImpl, ExtentionWalletHandler {
  ExtentionWallet({required super.navigatorKey, required super.context});

  final ExtensionWalletLoginController _loginController =
      ExtensionWalletLoginController();

  @override
  void onWalletIntraction() {
    super.onWalletIntraction();
    _loginController.onWalletIntraction();
  }

  @override
  Future<IResult<void>> init() async {
    final context = await initContext();
    return context.andThenAsync((_) async {
      final wallet = await super.init();
      return wallet.andThenAsync((_) async {
        await initExtension();
        return ResultOk.okVoid;
      });
    });
  }

  @override
  Future<IResult<T>> doAction<T>(WalletAction<T> action,
      {Duration? delay = APPConst.animationDuraion}) async {
    switch (action) {
      case WalletActionLock _:
        await _loginController.clearLoginHistory();
        break;
      case WalletActionInit request:
        if (isUnlock || request.initialPassword != null) break;
        final loginHistory = await _loginController.getLoginHistory();

        if (loginHistory != null) {
          action = WalletActionInit(initialPassword: loginHistory) as WalletAction<T>;
        }
        final result = await super.doAction(action, delay: delay);
        if (!isUnlock) _loginController.clearLoginHistory();
        return result;
      case WalletActionAccess request:
        final password = request.request.password;
        final bool isReadOnly = this.isReadOnly || isLock;
        final result = await super.doAction(action, delay: delay);
        if (isReadOnly && isUnlock && password != null) {
          await _loginController.saveLoginHistory(password);
        }
        return result;
      default:
        break;
    }
    return super.doAction(action, delay: delay);
  }

  @override
  AppWalletController get walletCore => this;
}
