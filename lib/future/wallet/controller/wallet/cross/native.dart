import 'package:flutter/material.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/future/wallet/controller/wallet/ui_wallet.dart';

UIWallet uiWallet(GlobalKey<NavigatorState> navigatorKey, MainAppContext context) =>
    Wallet(navigatorKey: navigatorKey, context: context);

class Wallet extends UIWallet {
  Wallet({required super.navigatorKey, required super.context});
}
