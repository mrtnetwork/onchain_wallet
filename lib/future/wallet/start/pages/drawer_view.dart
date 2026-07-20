import 'dart:async';

import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/theme/theme.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';

import 'package:on_chain_wallet/future/wallet/setting/color_selector.dart';
import 'package:on_chain_wallet/future/wallet/swap/pages/pages/swap.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/wallet/models/access/wallet_access.dart';
import 'package:on_chain_wallet/wallet/models/others/models/wallet.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/hd_wallet.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';

class DrawerView extends StatefulWidget {
  const DrawerView({super.key});

  @override
  State<DrawerView> createState() => _DrawerViewState();
}

class _DrawerViewState extends State<DrawerView> with SafeState<DrawerView> {
  void toggleBrightness() {
    wallet.toggleBrightness();
    updateState(() {});
  }

  void changeColor(Color? color) {
    if (color == null) return;
    wallet.changeColor(color);
    updateState(() {});
    context.showAlert("color_changed".tr);
  }

  void toggleWebView() {
    wallet.toggleWebView();
    updateState(() {});
  }

  void toggleSwap() {
    wallet.toggleSwap();
    updateState(() {});
  }

  Future<void> swapSetting() async {
    wallet.swap?.updateSettings((controller) {
      return context.openSliverDialog(
          widget: (context) => SelectSwapProvidersView(controller),
          label: 'swap_settings'.tr);
    }).then((e) => e.watch(
          onErr: (error) => context.showAlert(error.localizationError),
        ));
  }

  void toggleWalletLock() {
    if (wallet.wallet.isReadOnly) {
      context.openDialogPage(
        "",
        child: (context) {
          return AccessWalletView<WalletCredentialResponseLogin, WalletCredentialLogin>(
            request: WalletCredentialLogin.instance,
            onWalletAccess: (password) async {},
          );
        },
      );
    } else {
      wallet.wallet.lock();
    }
  }

  Future<void> switchOrCreateWallet() async {
    context.openDialogPage<MainWallet>("switch_wallets".tr,
        child: (c) => SwitchWalletsView());
  }

  late WalletProvider wallet;
  String? setting;

  void closeDrawer() {
    final key = Scaffold.maybeOf(context);
    key?.closeDrawer();
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    wallet = context.wallet;
    setting = PageRouter.networkSettings(wallet.wallet.network);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          automaticallyImplyLeading: false,
          pinned: true,
          title: Row(
            children: [
              BrightnessToggleIcon(
                  onToggleBrightness: () => wallet.toggleBrightness(),
                  brightness: ThemeController.appTheme.brightness),
              ColorSelectorIconView(
                (p0) {
                  if (p0 == null) return;
                  return wallet.changeColor(p0);
                },
              ),
              IconButton(
                  onPressed: toggleWalletLock,
                  icon: ConditionalWidget(
                    enable: wallet.wallet.isReadOnly,
                    onActive: (context) => Icon(Icons.lock),
                    onDeactive: (context) => Icon(Icons.lock_open),
                  )),
            ],
          ),
          actions: [
            IconButton(onPressed: closeDrawer, icon: Icon(Icons.close)),
          ],
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              AppListTile(
                leading: const Icon(Icons.change_circle),
                title: Text("wallet_management".tr),
                subtitle: Text("wallet_management_desc".tr),
                onTap: switchOrCreateWallet,
              ),
              AppListTile(
                onTap: () {
                  context.to(PageRouter.walletConnect);
                },
                leading: Icon(CustomIcons.wc),
                title: Text("wallet_connect_management".tr),
                subtitle: Text("manage_and_pair".tr),
              ),
              AppListTile(
                onTap: () {
                  context.to(PageRouter.manageDaps);
                },
                leading: Icon(CustomIcons.web3),
                title: Text("dapps_management".tr),
                subtitle: Text("dapps_management_desc".tr),
              ),
              if (setting != null)
                AppListTile(
                  leading: const Icon(Icons.settings),
                  title: Text("network_settings".tr),
                  subtitle: Text(wallet.wallet.network.coinParam.token.name),
                  onTap: () {
                    context.to(setting);
                  },
                ),
              AppListTile(
                leading: const Icon(Icons.delete),
                title: Text("erase_wallet".tr),
                subtitle: Text("clear_wallet_data".tr),
                onTap: () {
                  context.to(PageRouter.eraswWallet);
                },
              ),
              AppListTile(
                leading: const Icon(Icons.password),
                title: Text("wallet_password".tr),
                subtitle: Text("change_password".tr),
                onTap: () {
                  context.to(PageRouter.changePassword);
                },
              ),
              AppListTile(
                leading: const Icon(Icons.security),
                title: Text("seed_phrase".tr),
                subtitle: Text("export_security_phrase".tr),
                onTap: () {
                  context.to(PageRouter.exportSeed);
                },
              ),
              AppListTile(
                leading: const Icon(Icons.key),
                title: Text("external_keys".tr),
                subtitle: Text("import_private_key".tr),
                onTap: () {
                  context.to(PageRouter.importAccount);
                },
              ),
              AppListTile(
                leading: const Icon(Icons.remove_red_eye),
                title: Text("external_keys".tr),
                subtitle: Text("manage_imported_key".tr),
                onTap: () {
                  context.to(PageRouter.manageImportedKey,
                      argruments: wallet.wallet.network);
                },
              ),
              AppListTile(
                leading: const Icon(Icons.backup),
                title: Text("backup".tr),
                subtitle: Text("backup_wallet".tr),
                onTap: () {
                  context.to(PageRouter.backupWallet, argruments: wallet.wallet.network);
                },
              ),
              AppListTile(
                leading: const Icon(Icons.settings),
                title: Text("wallet_settings".tr),
                subtitle: Text("wallet_settings_desc".tr),
                onTap: () {
                  context.to(PageRouter.updateSetting).then((value) {
                    setState(() {});
                  });
                },
              ),
              AppListTile(
                leading: const Icon(Icons.contacts),
                title: Text("contacts".tr),
                subtitle: Text("manage_your_account_contacts".tr),
                onTap: () {
                  context.to(PageRouter.contacts);
                },
              ),
              ConditionalWidget(
                  enable: wallet.supportWebView,
                  onActive: (context) => AppListTile(
                        onTap: toggleWebView,
                        leading: const Icon(Icons.web),
                        trailing: Switch(
                          value: wallet.enableWebView,
                          onChanged: (value) => toggleWebView(),
                        ),
                        title: Text("webview".tr),
                        subtitle: Text("enable_webview_application".tr),
                      )),
              AppListTile(
                onTap: toggleSwap,
                leading: const Icon(Icons.swap_horiz),
                trailing: Switch(
                  value: wallet.enableSwap,
                  onChanged: (value) => toggleSwap(),
                ),
                title: Text("swap".tr),
                subtitle: Text("enable_swap_application".tr),
              ),
              ConditionalWidget(
                enable: wallet.enableSwap,
                onActive: (context) => AppListTile(
                    onTap: swapSetting,
                    leading: const Icon(Icons.swap_horiz),
                    title: Text("swap_settings".tr),
                    subtitle: Text("swap_setting_desc".tr)),
              ),
              const Divider(),
              AppListTile(
                leading: const Icon(Icons.currency_bitcoin),
                title: AppDropDownBottom(
                  items: {
                    for (final i in Currency.values)
                      i: RichText(
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                            style: context.textTheme.labelLarge,
                            text: i.name.toUpperCase(),
                            children: [
                              TextSpan(
                                  text: " (${i.currencyName})",
                                  style: context.textTheme.bodyMedium)
                            ]),
                      )
                  },
                  hint: "toggle_currency".tr,
                  value: wallet.appSetting.currency,
                  onChanged: wallet.changeCurrency,
                  isExpanded: true,
                ),
              ),
              if (wallet.supportBarcodeScanner)
                AppListTile(
                  onTap: () {
                    context.to(PageRouter.barcodeScanner);
                  },
                  leading: const Icon(Icons.qr_code),
                  title: Text("qr_code_scanner".tr),
                  subtitle: Text("retrive_barcode_data".tr),
                ),
              const Divider(),
              AppListTile(
                title: Text("about_onchain_wallet".tr),
                leading: const Icon(Icons.home),
                onTap: () {
                  context.appContext.platformUtls.lunchUri(LinkConst.appGithub);
                },
              ),
              WidgetConstant.height20,
            ],
          ),
        )
      ],
    );
  }
}

class SwitchWalletsView extends StatefulWidget {
  const SwitchWalletsView({super.key});

  @override
  State<SwitchWalletsView> createState() => _SwitchWalletsViewState();
}

class _SwitchWalletsViewState extends State<SwitchWalletsView>
    with SafeState<SwitchWalletsView> {
  late final WalletProvider wallet;
  List<HdWalletKey> wallets = [];
  List<ViewSubWalletKey> subWallets = [];
  HdWalletKey? currentWallet;
  StreamSubscription<WalletEvent>? subscription;

  void init() {
    wallets = wallet.wallet.wallets.clone()
      ..sort((a, b) => b.created.compareTo(a.created));
    currentWallet = wallet.wallet.wallet.tokey();
    subWallets = wallet.wallet.wallet.subWallets;
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    wallet = context.wallet;
    init();
    subscription = wallet.wallet.status.stream.listen((event) {
      if (event.inProgress) return;
      switch (event.action) {
        case WalletActionEventType.importSubWallet:
        case WalletActionEventType.switchWallet:
        case WalletActionEventType.switchNetwork:
        case WalletActionEventType.removeWallet:
        case WalletActionEventType.removeSubWallet:
        case WalletActionEventType.updateWallet:
        case WalletActionEventType.createWallet:
          init();
          updateState();
          break;
        default:
          break;
      }
    });
  }

  @override
  void safeDispose() {
    super.safeDispose();
    subscription?.cancel();
    subscription = null;
  }

  @override
  Widget build(BuildContext context) {
    return APPStreamWidget(
        stream: wallet.wallet.status,
        allowNotify: (value) => !value.action.isLockingTimeout,
        builder: (context, s) {
          return CustomScrollView(
            shrinkWrap: true,
            slivers: [
              SliverAppBar(
                title: Text("switch_wallets".tr),
                leading: WidgetConstant.sizedBox,
                leadingWidth: 0,
                pinned: true,
                actions: [
                  IconButton(
                      onPressed: () {
                        context.to(PageRouter.createWallet);
                      },
                      icon: Icon(Icons.add_box, color: context.onPrimaryContainer)),
                  const CloseButton()
                ],
              ),
              SliverConstraintsBoxView(
                padding: WidgetConstant.padding20,
                sliver: SliverList.builder(
                    itemBuilder: (context, index) {
                      final wallet = wallets[index];
                      final bool selected = wallet == currentWallet;
                      return CustomizedContainer(
                        onStackIcon: selected ? Icons.check_circle : Icons.circle,
                        onTapStackIcon: () {
                          this
                              .wallet
                              .wallet
                              .doAction(WalletActionSwitchAppWallet(wallet: wallet))
                              .then((e) {
                            if (e.isErr) {
                              context.showAlert(e.unwrapErr().localizationError);
                            }
                          });
                        },
                        child: APPExpansionListTile(
                          title: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.account_balance_wallet),
                                  WidgetConstant.width8,
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(wallet.name,
                                            style: context.textTheme.labelLarge),
                                        Text(wallet.created.toString(),
                                            style: context.textTheme.bodySmall),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          children: [
                            ConditionalWidget(
                                enable: selected,
                                onActive: (context) => Column(children: [
                                      ...subWallets.map((e) => ContainerWithBorder(
                                            backgroundColor: context.onPrimaryContainer,
                                            child: Row(
                                              children: [
                                                Icon(
                                                    Icons.account_balance_wallet_outlined,
                                                    color: context.primaryContainer),
                                                WidgetConstant.width8,
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(e.name,
                                                          style: context.primaryTextTheme
                                                              .bodyMedium),
                                                      Text(e.created.toDateAndTime(),
                                                          style: context.primaryTextTheme
                                                              .bodySmall),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ))
                                    ])),
                            ConditionalWidget(
                                enable: selected,
                                onActive: (context) => ContainerWithBorder(
                                      onRemove: () {
                                        context.to(PageRouter.createSubWallet);
                                      },
                                      backgroundColor: context.onPrimaryContainer,
                                      onRemoveIcon: Icon(Icons.add_box,
                                          color: context.primaryContainer),
                                      child: Text("tap_to_add_a_subwallet".tr,
                                          style: context.primaryTextTheme.bodyMedium),
                                    ))
                          ],
                        ),
                      );
                    },
                    itemCount: wallets.length),
              ),
            ],
          );
        });
  }
}
