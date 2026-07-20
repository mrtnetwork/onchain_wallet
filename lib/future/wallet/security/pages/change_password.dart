import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class ChangeWalletPasswordView extends StatelessWidget {
  const ChangeWalletPasswordView({super.key});
  @override
  Widget build(BuildContext context) {
    return AccessWalletView<WalletCredentialResponseCredential,
            WalletCredentialPasswordRequire>(
        request:
            WalletCredentialPasswordRequire(type: WalletCredentialType.changePassword),
        onAccsess: (credential) {
          return _ChangePasswordView(credential: credential.id);
        },
        title: "change_password".tr,
        subtitle: PageTitleSubtitle(
            title: "change_password".tr,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text("wallet_password_desc".tr)],
            )));
  }
}

class _ChangePasswordView extends StatefulWidget {
  const _ChangePasswordView({required this.credential});

  final WalletCredentialResponseVerify credential;

  @override
  State<_ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<_ChangePasswordView>
    with SafeState<_ChangePasswordView>, ProgressMixin<_ChangePasswordView> {
  final GlobalKey<FormState> form =
      GlobalKey<FormState>(debugLabel: "_ChangePasswordView");
  PasswordStrength passwordStrength = PasswordStrength.weak;

  final FocusNode nextFocus = FocusNode();
  String password = "";
  void onChangePassword(String v) {
    password = v;
    final passwordStrength = PasswordUtils.checkPasswordStrength(v);
    if (passwordStrength != this.passwordStrength) {
      this.passwordStrength = passwordStrength;
      updateState();
    }
  }

  bool _obscureText = true;
  void toggleObscure() {
    _obscureText = !_obscureText;
    updateState(() {});
  }

  String? onValidatePassword(String? value) {
    final passwordStrength = PasswordUtils.checkPasswordStrength(value ?? '');
    if (passwordStrength == PasswordStrength.weak) {
      return "weak_password_validator".tr;
    }
    return null;
  }

  String? confirmForm(String? value) {
    if (value != password) {
      return "p_does_not_match".tr;
    }
    return null;
  }

  void setupPassword() async {
    if (form.ready()) {
      progressKey.progressText("changing_password".tr);
      final model = context.wallet;
      final params = WalletActionChangeWalletPassword(
          credential: widget.credential, newPassword: password);
      final result = await model.wallet.doAction(params);
      if (result.isErr) {
        progressKey.errorText(result.unwrapErr().localizationError);
      } else {
        progressKey.successText("password_changed".tr, backToIdle: false);
        await MethodUtils.delayed();
        navigatorKey?.currentContext?.popToHome();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamPageProgress(
      controller: progressKey,
      builder: (c) => UnfocusableChild(
        child: CustomScrollView(
          shrinkWrap: true,
          slivers: [
            SliverConstraintsBoxView(
              padding: WidgetConstant.paddingHorizontal20,
              sliver: SliverToBoxAdapter(
                child: Form(
                  key: form,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    WidgetConstant.height20,
                    PageTitleSubtitle(
                        title: "wallet_password_desc".tr,
                        body: LargeTextView(
                          ["p_note1".tr, "p_note2".tr, "p_note3".tr, "p_note4".tr],
                        )),
                    AppTextField(
                        obscureText: _obscureText,
                        onChanged: onChangePassword,
                        keyboardType: TextInputType.visiblePassword,
                        textInputAction: TextInputAction.go,
                        disableContextMenu: true,
                        nextFocus: nextFocus,
                        validator: onValidatePassword,
                        errorBuilder: (context, errorText) => WidgetConstant.sizedBox,
                        label: "enter_new_password".tr),
                    PasswordStrengthIndicator(strength: passwordStrength),
                    WidgetConstant.height20,
                    AppTextField(
                      obscureText: _obscureText,
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.done,
                      focusNode: nextFocus,
                      disableContextMenu: true,
                      validator: confirmForm,
                      label: "c_password".tr,
                    ),
                    WidgetConstant.height20,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FixedElevatedButton(
                            padding: WidgetConstant.paddingVertical40,
                            onPressed: setupPassword,
                            child: Text("change_password".tr)),
                      ],
                    )
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
