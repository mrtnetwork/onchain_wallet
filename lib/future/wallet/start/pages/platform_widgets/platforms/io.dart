import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';

import 'package:on_chain_wallet/future/wallet/swap/pages/pages/swap.dart';
import 'package:on_chain_wallet/future/widgets/widgets/list_tile.dart';
import 'package:on_chain_wallet/future/widgets/widgets/widget_constant.dart';
import 'package:on_chain_wallet/wallet/models/access/wallet_access.dart';

Widget appbarWidgets(bool walletIsUnlock) => _AppbarExtentionWidget(walletIsUnlock);

class _AppbarExtentionWidget extends StatelessWidget {
  final bool walletIsUnlock;
  const _AppbarExtentionWidget(this.walletIsUnlock);

  @override
  Widget build(BuildContext context) {
    final wallet = context.wallet;
    if (!wallet.wallet.isOpen) return WidgetConstant.sizedBox;
    return PopupMenuButton(
        iconColor: context.colors.onSurface,
        icon: Icon(Icons.more_vert),
        routeSettings: RouteSettings(name: PageRouter.settingMenu),
        constraints: WidgetConstant.constraintsMinWidth200,
        itemBuilder: (c) {
          return [
            if (wallet.wallet.isReadOnly)
              PopupMenuItem(
                onTap: () {
                  context.openDialogPage(
                    "",
                    child: (context) {
                      return AccessWalletView<WalletCredentialResponseLogin,
                          WalletCredentialLogin>(
                        request: WalletCredentialLogin.instance,
                        onWalletAccess: (_) async {},
                      );
                    },
                  );
                },
                child: AppListTile(
                  trailing: const Icon(Icons.lock_open),
                  title: Text("unlock_wallet".tr, style: context.textTheme.labelMedium),
                ),
              ),
            if (wallet.wallet.isUnlock)
              PopupMenuItem(
                onTap: () {
                  wallet.wallet.lock();
                },
                child: AppListTile(
                  trailing: const Icon(Icons.lock),
                  title: Text("lock_wallet".tr, style: context.textTheme.labelMedium),
                ),
              ),
            if (wallet.wallet.isOpen)
              PopupMenuItem(
                onTap: () {
                  context.to(PageRouter.setting);
                },
                child: AppListTile(
                  trailing: const Icon(Icons.settings),
                  title: Text("settings".tr, style: context.textTheme.labelMedium),
                ),
              ),
            if (wallet.walletPage.inSwap)
              PopupMenuItem(
                onTap: () {
                  wallet.swap?.updateSettings((controller) {
                    return context.openSliverDialog(
                        widget: (context) => SelectSwapProvidersView(controller),
                        label: 'swap_settings'.tr);
                  }).then((e) => e.watch(
                        onErr: (error) => context.showAlert(error.localizationError),
                      ));
                },
                child: AppListTile(
                  trailing: const Icon(Icons.swap_horiz_outlined),
                  title: Text("swap_settings".tr, style: context.textTheme.labelMedium),
                ),
              ),
          ];
        });
  }
}
