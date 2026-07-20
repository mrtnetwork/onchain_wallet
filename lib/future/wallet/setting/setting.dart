import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/theme/theme.dart';
import 'package:on_chain_wallet/future/wallet/account/controller/account_controller.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'color_selector.dart';

class AppSettingView extends StatelessWidget {
  const AppSettingView({super.key});

  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<NetworkClient?, ChainAccount?, Chain>(
        childBulder: (wallet, account, client, address) {
          return _AppSettingView(wallet);
        },
        addressRequired: false,
        clientRequired: false);
  }
}

class _AppSettingView extends StatefulWidget {
  final WalletProvider wallet;
  const _AppSettingView(this.wallet);

  @override
  State<_AppSettingView> createState() => _AppSettingViewState();
}

class _AppSettingViewState extends State<_AppSettingView>
    with SafeState<_AppSettingView> {
  WalletProvider get wallet => widget.wallet;
  bool supportTorConnection = false;
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

  @override
  Widget build(BuildContext context) {
    // final wallet = context.wallet;
    final setting = PageRouter.networkSettings(wallet.wallet.network);
    return ScaffoldPageView(
      appBar: AppBar(title: Text("wallet_preferences".tr)),
      child: SingleChildScrollView(
        child: ConstraintsBoxView(
          padding: WidgetConstant.paddingHorizontal20,
          child: Column(
            children: [
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
              AppListTile(
                onTap: toggleBrightness,
                leading: ThemeController.appTheme.brightness == Brightness.dark
                    ? const Icon(Icons.light_mode)
                    : const Icon(Icons.dark_mode),
                trailing: Switch(
                  value: ThemeController.appTheme.brightness == Brightness.dark,
                  onChanged: (value) => toggleBrightness(),
                ),
                title: Text("dark_mode".tr),
                subtitle: Text("adjust_app_brightness".tr),
              ),
              AppListTile(
                onTap: () {
                  context
                      .openSliverDialog<Color>(
                          widget: (ctx) => const ColorSelectorModal(),
                          label: "primary_color_palette".tr)
                      .then(changeColor);
                },
                leading: const Icon(Icons.color_lens),
                title: Text("primary_color_palette".tr),
                subtitle: Text("define_primary_of_app".tr),
              ),

              // AppListTile(
              //   onTap: () {
              //     context.toPage(ParingMainWalletView());
              //   },
              //   leading: const Icon(Icons.color_lens),
              //   title: Text("link_device".tr),
              //   subtitle: Text("define_primary_of_app".tr),
              // ),
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
        ),
      ),
    );
  }
}
