import 'package:flutter/widgets.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/credential.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/hd_wallet.dart';

typedef OnUpdateWidget = void Function(WalletUpdateInfosData);

class UpdateWalletInfosWidget extends StatefulWidget {
  const UpdateWalletInfosWidget(
      {this.setupButtonTitle, required this.onUpdate, required this.wallet, super.key});
  final IMainWallet wallet;
  final String? setupButtonTitle;
  final OnUpdateWidget onUpdate;

  @override
  State<UpdateWalletInfosWidget> createState() => _UpdateWalletInfosWidgetState();
}

class _UpdateWalletInfosWidgetState extends State<UpdateWalletInfosWidget>
    with SafeState<UpdateWalletInfosWidget> {
  bool supportPlatformCredential = true;
  final GlobalKey<FormState> formKey =
      GlobalKey<FormState>(debugLabel: "SetupWalletPassword");
  late String name = widget.wallet.name;
  late bool reqPassword = widget.wallet.requiredPassword;
  late WalletLockTime locktime = widget.wallet.locktime;
  late bool protectWallet = widget.wallet.protectWallet;
  late ShimmerAction<WalletPlatformCredential?> platformCredential;

  late final Map<WalletLockTime, Widget> lockTimeWidget = {
    for (final i in WalletLockTime.values) i: Text(i.viewName.tr)
  };

  void onChangeName(String v) {
    name = v;
  }

  void onChangeReqPassword(bool? v) {
    reqPassword = v ?? reqPassword;
    updateState();
  }

  void onChangeProtectWallet(bool? v) {
    protectWallet = !protectWallet;
    updateState();
  }

  String? onValidateWalletName(String? v) {
    if (v == null || v.trim().isEmpty || v.length < 3 || v.length > 15) {
      return "wallet_name_validator".tr;
    }
    return null;
  }

  void setup() async {
    if (!formKey.ready()) return;
    widget.onUpdate(WalletUpdateInfosData(
        name: name,
        lockTime: locktime,
        requirmentPassword: reqPassword,
        protectWallet: protectWallet,
        platformCredential: platformCredential.object));
  }

  void onChangeLockTime(WalletLockTime? time) {
    if (time == null) return;
    locktime = time;
  }

  Future<void> togglePlatformCredential() async {
    if (platformCredential.object != null) {
      platformCredential = ShimmerAction(object: null);
    } else {
      platformCredential.setAction(false);
      final credential = await context.appContext.platformCrypto.createPlatformCredential(
          name: name,
          appName: APPConst.name,
          displayName: name,
          accountId: widget.wallet.key,
          reason: "authenticate".tr);
      credential.watch(
        onErr: (error) => context.showAlert(error.localizationError),
        onOk: (credential) {
          if (credential == null) {
            context.showAlert("no_biometric_enrolled".tr);
          }
          platformCredential = ShimmerAction(object: credential);
        },
      );
      platformCredential.setAction(true);
    }
    updateState();
  }

  Future<void> init() async {
    platformCredential = ShimmerAction(object: widget.wallet.platformCredential);
    if (platformCredential.object == null) {
      final supportPlatformCredential =
          await context.appContext.platformCrypto.supportPlatformCredential();
      supportPlatformCredential.watch(
        onErr: (error) => context.showAlert(error.localizationError),
        onOk: (value) {
          this.supportPlatformCredential = value;
        },
      );
    }

    platformCredential.setAction(true);
    updateState();
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    init();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("wallet_name".tr, style: context.textTheme.titleMedium),
            Text("wallet_identifier_name".tr),
            WidgetConstant.height8,
            AppTextField(
                initialValue: name,
                label: "wallet_name".tr,
                onChanged: onChangeName,
                validator: onValidateWalletName),
            WidgetConstant.height20,
            Text("automatic_loc".tr, style: context.textTheme.titleMedium),
            Text("wallet_locktime_desc".tr),
            WidgetConstant.height8,
            AppDropDownBottom(
                items: lockTimeWidget,
                hint: "automatic_loc".tr,
                value: locktime,
                onChanged: onChangeLockTime),
            WidgetConstant.height20,
            AppCheckListTile(
              contentPadding: EdgeInsets.zero,
              value: reqPassword,
              maxLine: 6,
              onChanged: onChangeReqPassword,
              title:
                  Text("password_requirement".tr, style: context.textTheme.titleMedium),
              subtitle: Text("wallet_password_requirement_desc2".tr),
            ),
            WidgetConstant.height20,
            AppCheckListTile(
              contentPadding: EdgeInsets.zero,
              value: protectWallet,
              onChanged: onChangeProtectWallet,
              title: Text("protect_wallet".tr, style: context.textTheme.titleMedium),
              subtitle: Text("required_password_to_sign_transaction".tr),
            ),
            ConditionalWidget(
                enable: supportPlatformCredential,
                onActive: (context) =>
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      WidgetConstant.height20,
                      AppCheckListTile(
                        contentPadding: EdgeInsets.zero,
                        value: platformCredential.object != null,
                        onChanged: (_) => togglePlatformCredential(),
                        title: Text("enable_device_authentication".tr,
                            style: context.textTheme.titleMedium),
                        subtitle: Text("enable_device_authentication_desc".tr),
                      ),
                    ])),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FixedElevatedButton(
                  padding: WidgetConstant.paddingVertical40,
                  onPressed: setup,
                  child: Text(widget.setupButtonTitle ?? "setup".tr),
                ),
              ],
            )
          ],
        ));
  }
}
