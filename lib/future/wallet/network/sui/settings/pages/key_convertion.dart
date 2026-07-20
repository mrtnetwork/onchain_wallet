import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/account/controller/account_controller.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/importing_custom_key_view.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/crypto/crypto.dart';
import 'package:on_chain/sui/sui.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

class SuiKeyConversionView extends StatelessWidget {
  const SuiKeyConversionView({super.key});
  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<SuiNetworkClient?, ISuiAddress?, SuiChain>(
      title: "sui_key_conversion".tr,
      addressRequired: false,
      clientRequired: false,
      childBulder: (wallet, account, client, address) {
        return _SuiConversionView(account.network);
      },
    );
  }
}

class _SuiConversionView extends StatefulWidget {
  const _SuiConversionView(this.network);
  final WalletSuiNetwork network;

  @override
  State<_SuiConversionView> createState() => __SuiKeyConversionViewState();
}

class __SuiKeyConversionViewState extends State<_SuiConversionView>
    with SafeState<_SuiConversionView>, ProgressMixin<_SuiConversionView> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final GlobalKey<AppTextFieldState> keyController =
      GlobalKey<AppTextFieldState>(debugLabel: "__SuiKeyConversionViewState");
  String key = "";

  void onChangeKey(String v) => key = v;

  String? validate(String? v) {
    final key = MethodUtils.fallbackOnException(
        () => SuiCryptoUtils.decodeSuiSecretKey(v ?? ''),
        logOnDebug: false);
    if (key == null) {
      return "invalid_sui_secret_key".tr;
    }

    return null;
  }

  ImportCustomKeys? generatedKey;

  void onSubmit() async {
    if (!formKey.ready()) return;
    progressKey.progressText("generating_private_key".tr);
    final result = await IResult.call(() async {
      final value = keyController.currentState?.getValue();
      final key = SuiCryptoUtils.decodeSuiSecretKey(value ?? '');
      final coin =
          widget.network.coins.firstWhere((e) => e.conf.type == key.$1.curveType);
      return ImportCustomKeys.fromPrivateKey(privateKey: key.$2, coin: coin);
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
      updateState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: generatedKey == null,
      onPopInvokedWithResult: onBackButton,
      child: StreamPageProgress(
        controller: progressKey,
        builder: (context) => Form(
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
                                    title: "sui_key_conversion".tr,
                                    body: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [Text("sui_key_conversion_desc".tr)],
                                    )),
                                Text("secret_key".tr,
                                    style: context.textTheme.titleMedium),
                                Text("sui_bech32_secret_key_desc2".tr),
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
                                  hint: "example_s".tr.replaceOne(APPConst.exampleBase58),
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
