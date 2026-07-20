import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/account/controller/account_controller.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/importing_custom_key_view.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/crypto/crypto.dart';
import 'package:xrpl_dart/xrpl_dart.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

class StellarKeyConversionView extends StatelessWidget {
  const StellarKeyConversionView({super.key});
  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<StellarClient?, IStellarAddress?, StellarChain>(
      addressRequired: false,
      clientRequired: false,
      title: "stellar_key_conversion".tr,
      childBulder: (wallet, account, client, address) {
        return _StellarConversionView(account.network);
      },
    );
  }
}

class _StellarConversionView extends StatefulWidget {
  const _StellarConversionView(this.network);
  final WalletStellarNetwork network;

  @override
  State<_StellarConversionView> createState() => __StellarKeyConversionViewState();
}

class __StellarKeyConversionViewState extends State<_StellarConversionView>
    with SafeState<_StellarConversionView>, ProgressMixin<_StellarConversionView> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final GlobalKey<AppTextFieldState> keyController =
      GlobalKey<AppTextFieldState>(debugLabel: "__StellarKeyConversionViewState");
  XRPKeyAlgorithm algorithm = XRPKeyAlgorithm.secp256k1;

  String key = "";

  void onChangeKey(String v) => key = v;

  void onChangeKeyAlgorithm(XRPKeyAlgorithm? updateAlgorithm) {
    algorithm = updateAlgorithm ?? algorithm;
    setState(() {});
  }

  String? validate(String? v) {
    if (v == null || v.length != StellarConst.stellarBase32SecretKeyLength) {
      return "stellar_base32_secret_key_validator".tr;
    }

    return null;
  }

  ImportCustomKeys? generatedKey;

  void onSubmit() async {
    if (!formKey.ready()) return;
    progressKey.progressText("generating_private_key".tr);
    final result = await IResult.call(() async {
      final value = keyController.currentState?.getValue();
      final key = StellarUtils.stellarBase32SecretKeyToImportKey(value);
      return ImportCustomKeys.fromPrivateKey(
          privateKey: key, coin: widget.network.coins.first);
    });
    if (result.isErr) {
      progressKey.errorText(result.unwrapErr().localizationError, backToIdle: true);
    } else {
      generatedKey = result.unwrap();
      progressKey.success();
    }
  }

  void onBackButton(bool didPop, _) {
    if (!didPop) {
      generatedKey = null;
      key = "";
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: generatedKey == null,
      onPopInvokedWithResult: onBackButton,
      child: StreamPageProgress(
        controller: progressKey,
        builder: (c) => Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: UnfocusableChild(
            child: CustomScrollView(
              slivers: [
                SliverConstraintsBoxView(
                    padding: WidgetConstant.paddingHorizontal20,
                    sliver:
                        APPSliverAnimatedSwitcher(enable: generatedKey != null, widgets: {
                      false: (c) => SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PageTitleSubtitle(
                                    title: "stellar_key_conversion".tr,
                                    body: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("stellar_key_conversion_desc".tr),
                                        WidgetConstant.height8,
                                        Text("secret_key_conversion_desc2".tr),
                                      ],
                                    )),
                                Text("secret_key".tr,
                                    style: context.textTheme.titleMedium),
                                Text("stellar_base32_secret_key_desc2".tr),
                                WidgetConstant.height8,
                                AppTextField(
                                  key: keyController,
                                  label: "secret_key".tr,
                                  initialValue: key,
                                  onChanged: onChangeKey,
                                  validator: validate,
                                  obscureText: true,
                                  pasteIcon: true,
                                  isSensitive: true,
                                  hint: "example_s".tr.replaceOne(APPConst.exampleBase32),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FixedElevatedButton(
                                      padding: WidgetConstant.paddingVertical40,
                                      onPressed: onSubmit,
                                      child: Text("generate".tr),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                      true: (c) => ImportCustomKeyToWalletView(keypair: generatedKey!)
                    })),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
