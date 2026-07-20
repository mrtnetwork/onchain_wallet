import 'dart:async';
import 'package:flutter/material.dart';
import 'package:on_chain_bridge/models/files/picked_file_data.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/address_details.dart';
import 'package:on_chain_wallet/future/wallet/setup/controller/form.dart';
import 'package:on_chain_wallet/future/wallet/setup/types/types.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/backup.dart';

class RestoreWalletBackupView extends StatefulWidget {
  const RestoreWalletBackupView({super.key});

  @override
  State<RestoreWalletBackupView> createState() => _MnemonicViewState();
}

class _MnemonicViewState extends State<RestoreWalletBackupView>
    with SafeState<RestoreWalletBackupView> {
  StreamSubscription<void>? listener;
  late final WalletBackupStateController controller;

  @override
  void onInitOnce() {
    super.onInitOnce();
    final password = context.getArgruments<String>();
    controller =
        WalletBackupStateController(walletProvider: context.wallet, password: password);
    listener = controller.stream.listen((v) => updateState());
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
      appBar: AppBar(
        title: Text("restore_backup".tr),
      ),
      body: UnfocusableChild(
        child: StreamPageProgress(
          controller: controller.pageController,
          builder: (context) => CustomScrollView(
            slivers: [
              SliverConstraintsBoxView(
                  padding: WidgetConstant.padding20,
                  sliver: APPSliverAnimatedSwitcher(enable: controller.page, widgets: {
                    WalletBackupPage.backup: (context) => _SetupBackupView(controller),
                    WalletBackupPage.review: (context) =>
                        _BackupVerifyReview(controller.backupData!),
                  }))
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupBackupView extends StatelessWidget {
  final WalletBackupStateController controller;
  const _SetupBackupView(this.controller);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("backup".tr, style: context.textTheme.titleMedium),
            WidgetConstant.height8,
            BackupDataPickerView(
                encoding: PickFileContentEncoding.hex, key: controller.backupKey),
            WidgetConstant.height20,
            Text("password".tr, style: context.textTheme.titleMedium),
            Text("input_backup_password".tr),
            WidgetConstant.height8,
            AppTextField(
                label: "input_backup_password".tr,
                validator: controller.onValidateBackupPassword,
                onChanged: controller.onChangeBackupPassword,
                initialValue: controller.backupPassword,
                obscureText: true),
            WidgetConstant.height20,
            Text("mn_password".tr, style: context.textTheme.titleMedium),
            Text("enter_passphrase_desc".tr),
            WidgetConstant.height8,
            AppCheckListTile(
                value: controller.usePassphrase,
                title: Text("enable_mnemonic_password".tr),
                subtitle: Text("mnemonic_passphrase_desc".tr),
                onChanged: controller.onChangeUsePassphrase),
            APPAnimated(
                isActive: controller.usePassphrase,
                onActive: (context) =>
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      WidgetConstant.height20,
                      AppTextField(
                        label: "mn_password".tr,
                        obscureText: true,
                        nextFocus: controller.nextFocus,
                        disableContextMenu: true,
                        initialValue: controller.passphrase,
                        onChanged: controller.onChangePassphrase,
                        validator: controller.onValidatePassphrase,
                      ),
                    ])),
            WidgetConstant.height20,
            AppCheckListTile(
                contentPadding: EdgeInsets.zero,
                value: controller.verifyBackupContent,
                title: Text("verify_backup".tr),
                subtitle: Text("verify_backup_desc".tr),
                onChanged: controller.onChangeVerifyBackup),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              FixedElevatedButton(
                  padding: WidgetConstant.paddingVertical40,
                  onPressed: controller.validateBackup,
                  child: Text("review_backup".tr))
            ])
          ],
        ),
      ),
    );
  }
}

class _BackupVerifyReview extends StatelessWidget {
  const _BackupVerifyReview(this.backup);
  // final _EnterMnemonicBackupViewState state;
  final VerifiedMainWalletBackup backup;
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitleSubtitle(
            title: "verification_backup_review".tr,
            body: Text("verification_backup_desc".tr),
          ),
          Text("status".tr, style: context.textTheme.titleMedium),
          WidgetConstant.height8,
          ContainerWithBorder(
            onRemove: () {},
            enableTap: false,
            onRemoveWidget: _BackupStatusIcon(backup.verifiedChecksum),
            child: _BackupStatusText(backup.verifiedChecksum),
          ),
          if (backup.verifiedChecksum != false) ...[
            WidgetConstant.height20,
            Text("total_accounts".tr, style: context.textTheme.titleMedium),
            WidgetConstant.height8,
            ContainerWithBorder(
              child: Text(backup.totalAccounts.toString(),
                  style: context.onPrimaryTextTheme.bodyMedium),
            ),
            if (backup.hasFailedAccount) ...[
              WidgetConstant.height20,
              Text("unverified_account".tr, style: context.textTheme.titleMedium),
              Text("unverified_account_desc".tr),
              WidgetConstant.height8,
              ContainerWithBorder(
                child: Column(
                  children: List.generate(backup.invalidAddresses.length, (i) {
                    final addr = backup.invalidAddresses[i];
                    return ContainerWithBorder(
                        backgroundColor: context.onPrimaryContainer,
                        child: AddressDetailsView(
                          title: addr.network.networkName,
                          address: backup.invalidAddresses[i],
                          color: context.primaryContainer,
                          showBalance: false,
                        ));
                  }),
                ),
              )
            ],
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FixedElevatedButton(
                padding: WidgetConstant.paddingVertical40,
                onPressed: () => context.pop(backup),
                child: Text("setup".tr),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _BackupStatusIcon extends StatelessWidget {
  const _BackupStatusIcon(this.verify);
  final bool? verify;
  @override
  Widget build(BuildContext context) {
    switch (verify) {
      case true:
        return Icon(Icons.check_circle, color: context.colors.green);
      case false:
        return Icon(Icons.error, color: context.colors.error);
      default:
        return Icon(Icons.question_mark_sharp, color: context.colors.orange);
    }
  }
}

class _BackupStatusText extends StatelessWidget {
  const _BackupStatusText(this.verify);
  final bool? verify;
  @override
  Widget build(BuildContext context) {
    final style = context.onPrimaryTextTheme.bodyMedium;
    switch (verify) {
      case true:
        return Text("backup_verification_success_desc".tr, style: style);
      case false:
        return Text("backup_verification_failed_desc".tr, style: style);
      default:
        return Text("unsuported_legacy_backup".tr, style: style);
    }
  }
}
