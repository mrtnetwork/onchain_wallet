import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

class WalletLoginPageView extends StatefulWidget {
  const WalletLoginPageView({super.key});

  @override
  State<WalletLoginPageView> createState() => _WalletLoginPageViewState();
}

class _WalletLoginPageViewState extends State<WalletLoginPageView>
    with SafeState<WalletLoginPageView> {
  final GlobalKey<FormState> formKey =
      GlobalKey<FormState>(debugLabel: "WalletLoginPageView");
  final GlobalKey<StreamWidgetState> buttonKey =
      GlobalKey<StreamWidgetState>(debugLabel: "WalletLoginPageView_1");
  String? _error;
  String password = "";
  void onChange(String v) {
    password = v;
    resetError();
  }

  void resetError() {
    if (_error != null) {
      updateState(() {
        _error = null;
      });
    }
  }

  void unlock() async {
    final provider = context.watch<WalletProvider>(StateConst.main);

    if (!(formKey.currentState?.validate() ?? false)) return;
    buttonKey.process();
    final login = await provider.wallet.login(password);
    buttonKey.fromMethodResult(login);
    _error = login.error?.tr;
    updateState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: UnfocusableChild(
        child: ConstraintsBoxView(
          padding: WidgetConstant.padding20,
          alignment: Alignment.center,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  CircleAssetsImageView(APPConst.logo),
                  WidgetConstant.height20,
                  AppTextField(
                    obscureText: true,
                    onChanged: onChange,
                    label: "password".tr,
                    disableContextMenu: true,
                    error: _error,
                    validator: (v) {
                      if (StrUtils.isStrongPassword(v)) {
                        return null;
                      }
                      return "password_validator".tr;
                    },
                  ),
                  ButtonProgress(
                    padding: WidgetConstant.paddingVertical40,
                    child: (context) => FixedElevatedButton(
                      onPressed: unlock,
                      child: Text("unlock".tr),
                    ),
                    backToIdle: APPConst.oneSecoundDuration,
                    key: buttonKey,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
