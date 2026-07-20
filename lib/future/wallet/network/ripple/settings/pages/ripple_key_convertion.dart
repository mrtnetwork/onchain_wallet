import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/account/controller/account_controller.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/importing_custom_key_view.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/crypto/crypto.dart';
import 'package:xrpl_dart/xrpl_dart.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

enum _KeyType {
  seed,
  entropy;

  String get example {
    if (this == _KeyType.seed) return APPConst.exampleBase58;
    return APPConst.exampleHex;
  }
}

class RippleKeyConversionView extends StatelessWidget {
  const RippleKeyConversionView({super.key});
  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<XRPNetworkClient?, IXRPAddress?, XRPChain>(
      title: "ripple_key_conversion".tr,
      addressRequired: false,
      clientRequired: false,
      childBulder: (wallet, account, client, address) {
        return _RippleKeyConversionView(account.network);
      },
    );
  }
}

class _RippleKeyConversionView extends StatefulWidget {
  const _RippleKeyConversionView(this.network);
  final WalletXRPNetwork network;

  @override
  State<_RippleKeyConversionView> createState() => __RippleKeyConversionViewState();
}

class __RippleKeyConversionViewState extends State<_RippleKeyConversionView>
    with SafeState<_RippleKeyConversionView>, ProgressMixin<_RippleKeyConversionView> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final GlobalKey<AppTextFieldState> keyController =
      GlobalKey<AppTextFieldState>(debugLabel: "__RippleKeyConversionViewState");
  XRPKeyAlgorithm algorithm = XRPKeyAlgorithm.secp256k1;
  _KeyType keyType = _KeyType.seed;

  String key = "";

  void onChangeKey(String v) => key = v;

  void onChangeKeyAlgorithm(XRPKeyAlgorithm? updateAlgorithm) {
    algorithm = updateAlgorithm ?? algorithm;
    setState(() {});
  }

  void onChangeKeyType(_KeyType? updateKeyType) {
    keyType = updateKeyType ?? keyType;
    setState(() {});
  }

  String? validate(String? v) {
    if (v == null || v.length < BlockchainConst.minimumKeysLength) {
      return "ripple_seed_entropy_validator".tr.replaceOne(keyType.name);
    }

    return null;
  }

  ImportCustomKeys? generatedKey;

  void onSubmit() async {
    if (!formKey.ready()) return;
    progressKey.progressText("generating_private_key".tr);
    final result = await IResult.call(() async {
      final value = keyController.currentState?.getValue();
      XRPPrivateKey key;
      switch (keyType) {
        case _KeyType.seed:
          key = RippleUtils.seedToPrivateKey(value!);
          break;
        default:
          key = RippleUtils.entropyToPrivateKey(value!, algorithm);
          break;
      }
      return ImportCustomKeys.fromPrivateKey(
          privateKey: key.toBytes(),
          coin: widget.network.coins
              .firstWhere((element) => element.conf.type == key.algorithm.curveType));
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
      child: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: StreamPageProgress(
          controller: progressKey,
          builder: (context) => UnfocusableChild(
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
                                    title: "ripple_key_conversion".tr,
                                    body: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("ripple_key_conversion_desc".tr),
                                        WidgetConstant.height8,
                                        Text("secret_key_conversion_desc2".tr),
                                      ],
                                    )),
                                Text("ripple_key_type".tr,
                                    style: context.textTheme.titleMedium),
                                Text("inidicate_type_of_ripple_key".tr),
                                WidgetConstant.height8,
                                AppDropDownBottom(
                                    items: {
                                      for (final i in _KeyType.values) i: Text(i.name.tr)
                                    },
                                    value: keyType,
                                    hint: "ripple_key_type".tr,
                                    onChanged: onChangeKeyType),
                                WidgetConstant.height20,
                                APPAnimatedSize(
                                    isActive: keyType == _KeyType.entropy,
                                    onActive: (c) => Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("key_algorithm".tr,
                                                style: context.textTheme.titleMedium),
                                            Text("choose_key_algorithm_desc".tr),
                                            WidgetConstant.height8,
                                            AppDropDownBottom(
                                              items: {
                                                for (final i in XRPKeyAlgorithm.values)
                                                  i: Text(i.curveType.name.camelCase)
                                              },
                                              value: algorithm,
                                              hint: "key_algorithm".tr,
                                              onChanged: onChangeKeyAlgorithm,
                                            ),
                                            WidgetConstant.height20,
                                          ],
                                        ),
                                    onDeactive: (c) => WidgetConstant.sizedBox),
                                Text("ripple_key".tr,
                                    style: context.textTheme.titleMedium),
                                Text("select_ripple_seed_or_entropy".tr),
                                WidgetConstant.height8,
                                AppTextField(
                                  key: keyController,
                                  label: keyType.name.tr,
                                  initialValue: key,
                                  onChanged: onChangeKey,
                                  validator: validate,
                                  obscureText: true,
                                  hint: "example_s".tr.replaceOne(keyType.example),
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
