import 'package:flutter/material.dart';
import 'package:on_chain_bridge/web/api/chrome/api/core.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/extension/models/models.dart';
import 'package:on_chain_wallet/future/wallet/controller/wallet/cross/web.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';

import 'package:on_chain_wallet/future/wallet/swap/pages/pages/swap.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/client_info.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/permission_view.dart';
import 'package:on_chain_wallet/future/widgets/widgets/list_tile.dart';
import 'package:on_chain_wallet/future/widgets/widgets/widget_constant.dart';
import 'package:on_chain_wallet/wallet/models/access/wallet_access.dart';

Widget appbarWidgets(bool walletIsUnlock) {
  if (isExtension) return _AppbarExtentionWidget(walletIsUnlock);
  return _AppbarWebWidget(walletIsUnlock);
}

class _AppbarExtentionWidget extends StatelessWidget {
  final bool walletIsUnlock;
  const _AppbarExtentionWidget(this.walletIsUnlock);

  @override
  Widget build(BuildContext context) {
    final wallet = context.wallet;
    final extension = wallet.wallet as ExtentionWallet;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (walletIsUnlock)
          APPStreamBuilder(
              value: extension.latestClient,
              builder: (context, client) => Web3ClientInfoIconView(
                  client: client,
                  onTap: (s) {
                    extension.updateApplicationAuthenticated(
                      (authenticated, onPermissionUpdate) async {
                        if (authenticated == null) return;
                        context.openDialogPage(
                          "update_permission".tr,
                          fullWidget: (context) => Web3PermissionUpdateView(
                              authenticated: authenticated,
                              onPermissionUpdate: onPermissionUpdate),
                        );
                      },
                    );
                  })),
        PopupMenuButton<ExtensionWalletContextType?>(
            iconColor: context.colors.onSurface,
            icon: Icon(Icons.more_vert),
            routeSettings: RouteSettings(name: PageRouter.settingMenu),
            constraints: WidgetConstant.constraintsMinWidth200,
            onSelected: (v) {
              if (v == null) return;
              extension.openPopup(v);
            },
            itemBuilder: (c) {
              return [
                if (wallet.wallet.isReadOnly)
                  PopupMenuItem<ExtensionWalletContextType>(
                    child: AppListTile(
                      onTap: () {
                        context.openDialogPage(
                          "",
                          child: (context) {
                            return AccessWalletView<WalletCredentialResponseLogin,
                                WalletCredentialLogin>(
                              request: WalletCredentialLogin.instance,
                              onWalletAccess: (_) {},
                            );
                          },
                        );
                      },
                      trailing: const Icon(Icons.lock_open),
                      title:
                          Text("unlock_wallet".tr, style: context.textTheme.labelMedium),
                    ),
                  ),
                if (wallet.wallet.isUnlock)
                  PopupMenuItem<ExtensionWalletContextType>(
                    child: AppListTile(
                      onTap: () {
                        wallet.wallet.lock();
                      },
                      trailing: const Icon(Icons.lock),
                      title: Text("lock_wallet".tr, style: context.textTheme.labelMedium),
                    ),
                  ),
                if (wallet.wallet.isOpen)
                  PopupMenuItem<ExtensionWalletContextType>(
                    child: AppListTile(
                      onTap: () {
                        context.to(PageRouter.setting);
                      },
                      trailing: const Icon(Icons.settings),
                      title: Text("settings".tr, style: context.textTheme.labelMedium),
                    ),
                  ),
                if (wallet.walletPage.inSwap)
                  PopupMenuItem<ExtensionWalletContextType>(
                    child: AppListTile(
                      onTap: () {
                        wallet.swap?.updateSettings((controller) {
                          return context.openSliverDialog(
                              widget: (context) => SelectSwapProvidersView(controller),
                              label: 'swap_settings'.tr);
                        }).then((e) => e.watch(
                              onErr: (error) =>
                                  context.showAlert(error.localizationError),
                            ));
                      },
                      trailing: const Icon(Icons.swap_horiz_outlined),
                      title:
                          Text("swap_settings".tr, style: context.textTheme.labelMedium),
                    ),
                  ),
                if (extension.context.context.isAction) ...[
                  PopupMenuItem<ExtensionWalletContextType>(
                    value: ExtensionWalletContextType.popup,
                    child: AppListTile(
                      trailing: const Icon(Icons.open_in_new),
                      title:
                          Text("open_as_popup".tr, style: context.textTheme.labelMedium),
                    ),
                  ),
                  PopupMenuItem<ExtensionWalletContextType>(
                    value: ExtensionWalletContextType.tab,
                    child: AppListTile(
                      trailing: const Icon(Icons.open_in_browser),
                      title: Text("open_in_new_tab".tr,
                          style: context.textTheme.labelMedium),
                    ),
                  ),
                  if (extension.supportedActions
                      .contains(ExtensionWalletContextType.sidePanel))
                    PopupMenuItem<ExtensionWalletContextType>(
                      value: ExtensionWalletContextType.sidePanel,
                      child: AppListTile(
                        trailing: const Icon(Icons.view_sidebar),
                        title: Text("opn_in_side_panel".tr,
                            style: context.textTheme.labelMedium),
                      ),
                    )
                  else if (extension.supportedActions
                      .contains(ExtensionWalletContextType.sidebarAction))
                    PopupMenuItem<ExtensionWalletContextType>(
                      value: ExtensionWalletContextType.sidebarAction,
                      child: AppListTile(
                        trailing: const Icon(Icons.view_sidebar),
                        title: Text("opn_in_side_panel".tr,
                            style: context.textTheme.labelMedium),
                      ),
                    ),
                ],
              ];
            })
      ],
    );
  }
}

class _AppbarWebWidget extends StatelessWidget {
  final bool walletIsUnlock;
  const _AppbarWebWidget(this.walletIsUnlock);

  @override
  Widget build(BuildContext context) {
    final wallet = context.wallet;
    if (!wallet.wallet.isOpen) return WidgetConstant.sizedBox;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PopupMenuButton(
            iconColor: context.colors.onSurface,
            icon: Icon(Icons.more_vert),
            constraints: WidgetConstant.constraintsMinWidth200,
            routeSettings: RouteSettings(name: PageRouter.settingMenu),
            onSelected: (v) {},
            itemBuilder: (c) {
              return [
                if (wallet.wallet.isReadOnly)
                  PopupMenuItem<ExtensionWalletContextType>(
                    child: AppListTile(
                      onTap: () {
                        context.openDialogPage(
                          "",
                          child: (context) {
                            return AccessWalletView<WalletCredentialResponseLogin,
                                WalletCredentialLogin>(
                              request: WalletCredentialLogin.instance,
                              onWalletAccess: (_) {},
                            );
                          },
                        );
                      },
                      trailing: const Icon(Icons.lock_open),
                      title:
                          Text("unlock_wallet".tr, style: context.textTheme.labelMedium),
                    ),
                  ),
                if (wallet.wallet.isUnlock)
                  PopupMenuItem<ExtensionWalletContextType>(
                    child: AppListTile(
                      onTap: () {
                        wallet.wallet.lock();
                      },
                      trailing: const Icon(Icons.lock),
                      title: Text("lock_wallet".tr, style: context.textTheme.labelMedium),
                    ),
                  ),
                if (wallet.wallet.isOpen)
                  PopupMenuItem<ExtensionWalletContextType>(
                    child: AppListTile(
                      onTap: () {
                        context.to(PageRouter.setting);
                      },
                      trailing: const Icon(Icons.settings),
                      title: Text("settings".tr, style: context.textTheme.labelMedium),
                    ),
                  ),
                if (wallet.walletPage.inSwap)
                  PopupMenuItem<ExtensionWalletContextType>(
                    child: AppListTile(
                      onTap: () {
                        wallet.swap?.updateSettings((controller) {
                          return context.openSliverDialog(
                              widget: (context) => SelectSwapProvidersView(controller),
                              label: 'swap_settings'.tr);
                        }).then((e) => e.watch(
                              onErr: (error) =>
                                  context.showAlert(error.localizationError),
                            ));
                      },
                      trailing: const Icon(Icons.swap_horiz_outlined),
                      title:
                          Text("swap_settings".tr, style: context.textTheme.labelMedium),
                    ),
                  ),
              ];
            })
      ],
    );
  }
}
