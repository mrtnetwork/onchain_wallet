import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/theme/theme.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';

mixin WalletProviderThemeController on BaseWalletProvider {
  ThemeData get theme => ThemeController.appTheme;
  void toggleBrightness() {
    ThemeController.toggleBrightness();
    notify();
    final setting = appSetting.copyWith(
        appBrightness: ThemeController.appBrightness,
        appColor: ThemeController.appColorHex);
    updateAppSettings(setting);
  }

  void changeColor(Color color) {
    ThemeController.changeColor(color);
    notify();
    final setting = appSetting.copyWith(
        appBrightness: ThemeController.appBrightness,
        appColor: ThemeController.appColorHex);
    updateAppSettings(setting);
  }
}
