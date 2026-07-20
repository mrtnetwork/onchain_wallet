import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/update_wallet_infos.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class UpdateWalletSettingView extends StatelessWidget {
  const UpdateWalletSettingView({super.key});
  @override
  Widget build(BuildContext context) {
    return AccessWalletView<WalletCredentialResponseVerify, WalletCredentialVerify>(
        request: WalletCredentialVerify(),
        onAccsess: (credential) {
          return _UpdateWalletSettingView(credential: credential);
        },
        title: "wallet_preferences".tr,
        subtitle: PageTitleSubtitle(
            title: "customize_wallet_settings".tr,
            body: Column(
              children: [
                Text("enter_wallet_password_to_continue".tr),
              ],
            )));
  }
}

class _UpdateWalletSettingView extends StatefulWidget {
  const _UpdateWalletSettingView({required this.credential});
  final WalletCredentialResponseVerify credential;

  @override
  State<_UpdateWalletSettingView> createState() => _UpdateWalletSettingViewState();
}

class _UpdateWalletSettingViewState extends State<_UpdateWalletSettingView>
    with SafeState<_UpdateWalletSettingView>, ProgressMixin<_UpdateWalletSettingView> {
  late final IMainWallet hdWallet;
  Future<void> setup(WalletUpdateInfosData walletInfos) async {
    progressKey.progressText("updating".tr);
    final model = context.wallet.wallet;

    final result = await model.doAction(WalletActionUpdateWallet(
        walletInfos: walletInfos, credential: widget.credential));
    if (result.isErr) {
      progressKey.errorText(result.unwrapErr().localizationError);
    } else {
      progressKey.successText("setting_update_successfully".tr, backToIdle: false);
    }
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    final wallet = context.wallet;
    hdWallet = wallet.wallet.wallet;
  }

  @override
  Widget build(BuildContext context) {
    return StreamPageProgress(
      controller: progressKey,
      builder: (c) => Center(
        child: CustomScrollView(
          shrinkWrap: true,
          slivers: [
            SliverToBoxAdapter(
              child: ConstraintsBoxView(
                padding: WidgetConstant.paddingHorizontal20,
                alignment: Alignment.center,
                child: UpdateWalletInfosWidget(
                    wallet: hdWallet,
                    setupButtonTitle: "update_settings".tr,
                    onUpdate: (update) => setup(update)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
