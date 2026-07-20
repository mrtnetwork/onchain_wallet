import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/login.dart';
import 'package:on_chain_wallet/future/wallet/setting/color_selector.dart';
import 'package:on_chain_wallet/future/wallet/start/pages/platform_widgets/widgets.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/wallet/models/access/wallet_access.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/hd_wallet.dart';

class WalletLoginPageView extends StatelessWidget {
  const WalletLoginPageView({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = context.wallet;
    return WalletLoginView<WalletCredentialResponseLogin, WalletCredentialLogin>(
      key: ValueKey(true),
      appBar: AppBar(
        centerTitle: false,
        title: Text(wallet.wallet.wallet.name),
        actions: [
          WidgetConstant.width8,
          BrightnessToggleIcon(
              onToggleBrightness: () => wallet.toggleBrightness(),
              brightness: ThemeController.appTheme.brightness),
          ColorSelectorIconView(
            (p0) {
              if (p0 == null) return;
              return wallet.changeColor(p0);
            },
          ),
          appbarWidgets(false),
        ],
        leading: IconButton(
            onPressed: () {
              context.openDialogPage<MainWallet>("switch_wallets".tr,
                  child: (c) => SwitchWalletsView());
            },
            icon: const Icon(Icons.account_balance_wallet_rounded)),
      ),
      request: WalletCredentialLogin.instance,
      onWalletAccess: (credential) {},
      subtitle: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [CircleAssetsImageView(APPConst.logo), WidgetConstant.height20],
            ),
          ),
        ],
      ),
    );
  }
}
