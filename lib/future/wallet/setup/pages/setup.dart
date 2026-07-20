import 'dart:async';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/update_wallet_infos.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';

import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/setup/controller/setup_wallet.dart';
import 'package:on_chain_wallet/future/wallet/setup/pages/backup.dart';
import 'package:on_chain_wallet/future/wallet/setup/pages/exists_mnemonic.dart';
import 'package:on_chain_wallet/future/wallet/setup/pages/generate_mnemonic.dart';
import 'package:on_chain_wallet/future/wallet/setup/pages/terms.dart';
import 'package:on_chain_wallet/future/wallet/setup/types/types.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/models/access/wallet_access.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/backup.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/hd_wallet.dart';

class SubWalletSetupPageView extends StatelessWidget {
  const SubWalletSetupPageView({super.key});

  @override
  Widget build(BuildContext context) {
    return AccessWalletView<WalletCredentialResponseLogin, WalletCredentialLogin>(
      request: WalletCredentialLogin.instance,
      onAccsess: (_) {
        return WalletSetupPageWidget(type: APPWalletType.subwallet);
      },
    );
  }
}

// enum _Wallet
class WalletSetupPageWidget extends StatefulWidget {
  const WalletSetupPageWidget({super.key, this.type = APPWalletType.mainwallet});
  final APPWalletType type;
  @override
  State<WalletSetupPageWidget> createState() => _WalletSetupPageWidgetState();
}

class _WalletSetupPageWidgetState extends State<WalletSetupPageWidget>
    with SafeState<WalletSetupPageWidget> {
  StreamSubscription<void>? listener;
  late final SetupWalletStateController controller;

  @override
  void onInitOnce() {
    super.onInitOnce();
    controller =
        SetupWalletStateController(walletProvider: context.wallet, type: widget.type);
    listener = controller.stream.listen((_) => updateState());
  }

  @override
  void safeDispose() {
    super.safeDispose();
    listener?.cancel();
    listener = null;
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("setup".tr), centerTitle: false),
      body: UnfocusableChild(
        child: StreamPageProgress(
          controller: controller.pageController,
          builder: (context) => Center(
            child: CustomScrollView(
              shrinkWrap: true,
              slivers: [
                SliverConstraintsBoxView(
                  padding: WidgetConstant.padding20,
                  sliver: APPSliverAnimatedSwitcher<WalletStupPage>(
                      enable: controller.page,
                      widgets: {
                        WalletStupPage.main: (context) => ConditionalWidget(
                              enable: controller.type.isMainWallet,
                              onActive: (context) => _OnSetupWalletPassword(controller),
                              onDeactive: (context) => _SetupSubWalletOptions(controller),
                            ),
                        WalletStupPage.mainWalletSetting: (context) => SliverToBoxAdapter(
                              child: _MainWalletSettingsView(controller),
                            )
                      }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnSetupWalletPassword extends StatelessWidget {
  final SetupWalletStateController controller;
  const _OnSetupWalletPassword(this.controller);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Form(
        key: controller.passwordFormKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("setup_password".tr, style: context.textTheme.titleMedium),
            Text("input_you_wallet_password".tr),
            WidgetConstant.height8,
            AppTextField(
                obscureText: true,
                onChanged: controller.onChangePassword,
                initialValue: controller.password,
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.go,
                disableContextMenu: true,
                nextFocus: controller.nextFocus,
                validator: controller.onValidatePassword,
                errorBuilder: (context, errorText) {
                  return WidgetConstant.sizedBox;
                },
                label: "e_password".tr),
            PasswordStrengthIndicator(strength: controller.passwordStrength),
            WidgetConstant.height20,
            AppTextField(
              obscureText: true,
              onChanged: controller.onChangeConfirmPassword,
              initialValue: controller.confirmPassword,
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.done,
              focusNode: controller.nextFocus,
              disableContextMenu: true,
              validator: controller.onValidateConfirmPassword,
              label: "c_password".tr,
            ),
            WidgetConstant.height20,
            AppListTile(
              title: Text("use_mnemonic".tr),
              subtitle: Text("e_mnemonic".tr),
              trailing: const Icon(Icons.arrow_forward),
              leading: const Icon(Icons.add_circle),
              onTap: () async {
                return controller.onSetupMainWalletPassword(
                  (allowType, mode) async {
                    return context.toPage<GeneratedMnemonic>(ExistsMnemonicView(),
                        argruments: allowType);
                  },
                  () {
                    return context.openSliverDialog(
                        label: "security_tips".tr,
                        widget: (context) => StupWalletTerms(),
                        dismissible: false);
                  },
                );
              },
            ),
            const Divider(),
            AppListTile(
              title: Text("generate_mnemonic".tr),
              subtitle: Text("g_mnemonic".tr),
              trailing: const Icon(Icons.arrow_forward),
              leading: const Icon(Icons.key),
              onTap: () async {
                return controller.onSetupMainWalletPassword(
                  (allowType, mode) async {
                    return context.toPage<GeneratedMnemonic>(SetupMnemonicView(),
                        argruments: allowType);
                  },
                  () {
                    return context.openSliverDialog(
                        label: "security_tips".tr,
                        widget: (context) => StupWalletTerms(),
                        dismissible: false);
                  },
                );
              },
            ),
            const Divider(),
            AppListTile(
              title: Text("restore_backup".tr),
              leading: const Icon(Icons.backup),
              subtitle: Text("restore_backuo_desc".tr),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () async {
                return controller.onRestoreMainWalletPassword(
                  (password) async {
                    return context.toPage<VerifiedMainWalletBackup>(
                        RestoreWalletBackupView(),
                        argruments: password);
                  },
                );
              },
            ),
            // const Divider(),
            // AppListTile(
            //   title: Text("external_wallet".tr),
            //   leading: const Icon(Icons.wallet),
            //   subtitle: Text("connect_to_external_wallet".tr),
            //   trailing: const Icon(Icons.arrow_forward),
            //   onTap: () async {
            //     return controller.onConnectToExternalWallet(
            //       (password) async {
            //         return context.toPage<ExternalWalletData>(ExternalWalletParingView(),
            //             argruments: password);
            //       },
            //     );
            //   },
            // )
          ],
        ),
      ),
    );
  }
}

class _MainWalletSettingsView extends StatefulWidget {
  const _MainWalletSettingsView(this.controller);
  final SetupWalletStateController controller;

  @override
  State<_MainWalletSettingsView> createState() => __MainWalletSettingsViewState();
}

class __MainWalletSettingsViewState extends State<_MainWalletSettingsView>
    with SafeState<_MainWalletSettingsView> {
  IMainWallet get wallet => widget.controller.mainWallet!;
  // late List<String> walletIds;
  Future<void> setup(WalletUpdateInfosData walletInfos) async {
    await widget.controller.onSetupMainWallet(walletInfos);
  }

  @override
  Widget build(BuildContext context) {
    return UpdateWalletInfosWidget(wallet: wallet, onUpdate: (update) => setup(update));
  }
}

class _SetupSubWalletOptions extends StatelessWidget {
  final SetupWalletStateController controller;
  const _SetupSubWalletOptions(this.controller);
  IMainWallet get mainWallet => controller.mainWallet!;
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Form(
        key: controller.passwordFormKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("mainwallet".tr, style: context.textTheme.titleMedium),
            Text("sub_wallet_import_to_current_main_wallet_desc".tr),
            WidgetConstant.height8,
            ContainerWithBorder(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mainWallet.name, style: context.textTheme.labelLarge),
                  Text(mainWallet.created.toString(), style: context.textTheme.bodySmall)
                ],
              ),
            ),
            WidgetConstant.height20,
            Text("sub_wallet_name".tr, style: context.textTheme.titleMedium),
            Text("enter_sub_wallet_name".tr),
            WidgetConstant.height8,
            AppTextField(
                onChanged: controller.onChangeSubWalletName,
                initialValue: controller.subWalletName,
                validator: controller.onValidateWalletName,
                label: "sub_wallet_name".tr),
            WidgetConstant.height20,
            AppListTile(
              title: Text("use_mnemonic".tr),
              subtitle: Text("e_mnemonic".tr),
              trailing: const Icon(Icons.arrow_forward),
              leading: const Icon(Icons.add_circle),
              onTap: () {
                controller.onSetupSubWallet(
                  (allowType, mode) async {
                    return context.toPage<GeneratedMnemonic>(ExistsMnemonicView(),
                        argruments: allowType);
                  },
                  () {
                    return context.openSliverDialog(
                        label: "security_tips".tr,
                        widget: (context) => StupWalletTerms(),
                        dismissible: false);
                  },
                );
              },
            ),
            const Divider(),
            AppListTile(
              title: Text("generate_mnemonic".tr),
              subtitle: Text("g_mnemonic".tr),
              trailing: const Icon(Icons.arrow_forward),
              leading: const Icon(Icons.key),
              onTap: () {
                controller.onSetupSubWallet(
                  (allowType, mode) async {
                    return context.toPage<GeneratedMnemonic>(SetupMnemonicView(),
                        argruments: allowType);
                  },
                  () {
                    return context.openSliverDialog(
                        label: "security_tips".tr,
                        widget: (context) => StupWalletTerms(),
                        dismissible: false);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
