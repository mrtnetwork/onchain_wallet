import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

enum _Pages { restore, content }

class RestoreBackupView extends StatefulWidget {
  const RestoreBackupView({super.key, this.accepted});
  final WalletBackupTypes? accepted;

  @override
  State<RestoreBackupView> createState() => _RestoreBackupViewState();
}

class _RestoreBackupViewState extends State<RestoreBackupView> with SafeState {
  final StreamPageProgressController progressKey = StreamPageProgressController();
  final GlobalKey<FormState> form = GlobalKey(debugLabel: "_RestoreBackupViewState_2");
  bool showContet = false;
  BackupDataPickerContent? content = BackupDataPickerContent();
  String password = "";
  String? restored;
  _Pages page = _Pages.restore;
  final GlobalKey<BackupDataPickerViewState> backupKey =
      GlobalKey(debugLabel: "_RestoreBackupViewState.backupKey");

  void onChangePassword(String v) {
    password = v;
  }

  void onShowContet() {
    showContet = true;
    updateState();
  }

  bool isValid(String? v) {
    if (v == null) return false;
    return v.trim().length > 100;
  }

  String? bcakupForm(String? v) {
    if (isValid(v)) return null;
    return "bcakup_validator".tr;
  }

  String? passwordForm(String? v) {
    if (v?.isEmpty ?? true) {
      return "password_validator_desc".tr;
    }
    return null;
  }

  Future<void> onRestore() async {
    if (!form.ready()) return;
    final backup = backupKey.currentState?.getDataString();
    if (backup == null) return;
    progressKey.progressText("restoring_backup_please_wait".tr);
    final wallet = context.wallet;
    final result = await wallet.wallet
        .doAction(WalletActionDecryptWalletBackup(backup: backup, password: password));
    if (result.isErr) {
      progressKey.errorText(result.unwrapErr().localizationError,
          backToIdle: false, showBackButton: true);
    } else {
      final keyType = result.unwrap().type;
      bool isCorrectKey = true;
      final accepted = widget.accepted;
      if (accepted != null) {
        isCorrectKey =
            (keyType == accepted || keyType.isPrivateKey && accepted.isPrivateKey);
      }
      if (!isCorrectKey) {
        progressKey.errorText("different_backup_type_detected".tr,
            backToIdle: false, showBackButton: true);
      } else {
        restored = result.unwrap().key;
        page = _Pages.content;
        progressKey.backToIdle();
      }
    }
  }

  void onSubmit() {
    if (restored == null) return;
    context.pop(restored);
  }

  @override
  void safeDispose() {
    super.safeDispose();
    progressKey.dispose();
    content = null;
    password = '';
    restored = null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamPageProgress(
      controller: progressKey,
      builder: (c) => ConstraintsBoxView(
        padding: WidgetConstant.paddingHorizontal20,
        child: Column(
          children: [
            APPAnimatedSwitcher(enable: page, widgets: {
              _Pages.restore: (c) => _RestoreBackupRestorePage(this),
              _Pages.content: (c) => _RestoreBackupContentPage(this),
            }),
          ],
        ),
      ),
    );
  }
}

class _RestoreBackupContentPage extends StatelessWidget {
  const _RestoreBackupContentPage(this.state);
  final _RestoreBackupViewState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitleSubtitle(
            title: "restore_encrypted_backup".tr,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("backup_restored_desc".tr),
                WidgetConstant.height8,
              ],
            )),
        SecureContentView(content: state.restored ?? "", isSensitive: true),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FixedElevatedButton(
                padding: WidgetConstant.paddingVertical40,
                onPressed: state.onSubmit,
                child: Text("submit".tr))
          ],
        )
      ],
    );
  }
}

class _RestoreBackupRestorePage extends StatelessWidget {
  const _RestoreBackupRestorePage(this.state);
  final _RestoreBackupViewState state;
  @override
  Widget build(BuildContext context) {
    return Form(
      key: state.form,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          PageTitleSubtitle(
              title: "restore_encrypted_backup".tr, body: Text("restore_backup_desc".tr)),
          BackupDataPickerView(
            key: state.backupKey,
            content: state.content,
          ),
          WidgetConstant.height20,
          AppTextField(
              label: "input_backup_password".tr,
              validator: state.passwordForm,
              onChanged: state.onChangePassword,
              initialValue: state.password,
              obscureText: true),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FixedElevatedButton(
                padding: WidgetConstant.paddingVertical40,
                onPressed: state.onRestore,
                child: Text("restore_backup".tr),
              )
            ],
          )
        ],
      ),
    );
  }
}
