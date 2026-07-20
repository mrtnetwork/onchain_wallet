import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

class SetupRippleAddressView extends StatefulWidget {
  final AddressDerivationController controller;
  const SetupRippleAddressView({super.key, required this.controller});
  @override
  State<SetupRippleAddressView> createState() => _SetupRippleAddressViewState();
}

class _SetupRippleAddressViewState extends State<SetupRippleAddressView>
    with SafeState<SetupRippleAddressView> {
  RippleKeyScheme algorithm = RippleKeyScheme.ed25519;

  late final Map<RippleKeyScheme, Widget> algorithmTypesWidget;

  void onChangeAlgorithm(RippleKeyScheme? alg) {
    algorithm = alg ?? algorithm;
    updateState();
  }

  XrpAddressType addressTyoe = XrpAddressType.classic;
  bool get isXAddress => addressTyoe == XrpAddressType.xAddress;
  int tag = 0;
  void onChangeTag(int? newTag) {
    if (newTag == null || newTag < 0 || newTag > RippleConst.maxRippleTag - 1) {
      return;
    }
    tag = newTag;
  }

  String? validateTag(String? v) {
    if (!isXAddress) return null;
    final newTag = int.tryParse(v ?? "");
    if (newTag == null || newTag < 0 || newTag > BinaryOps.mask32 - 1) {
      return "tag_validator".tr;
    }
    return null;
  }

  void onSelectAddressType() {
    addressTyoe = isXAddress ? XrpAddressType.classic : XrpAddressType.xAddress;
    updateState();
  }

  void generateAddress() async {
    final selectedCoins =
        widget.controller.network.coins.firstWhere((e) => e.conf.type == algorithm.curve);
    final keyIndex = await widget.controller.getCoin(
        context: context, seedGeneration: SeedTypes.bip39, selectedCoins: selectedCoins);
    if (keyIndex == null || keyIndex.currencyCoin.conf.type != selectedCoins.conf.type) {
      return;
    }
    final newAccount = RippleNewAddressParams(
        deriveIndex: keyIndex, tag: isXAddress ? tag : null, coin: selectedCoins);
    widget.controller.generateAddress(newAccount);
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    algorithmTypesWidget = {for (final i in RippleKeyScheme.values) i: Text(i.name)};
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WidgetConstant.height20,
        Text("key_scheme".tr, style: context.textTheme.titleMedium),
        Text("choose_key_algorithm_desc2".tr),
        WidgetConstant.height8,
        AppDropDownBottom(
            items: algorithmTypesWidget,
            hint: "key_scheme".tr,
            onChanged: onChangeAlgorithm,
            isExpanded: true,
            value: algorithm),
        WidgetConstant.height20,
        AppCheckListTile(
          title: Text("x_address".tr, style: context.textTheme.titleMedium),
          contentPadding: EdgeInsets.zero,
          subtitle: TextAndLinkView(
            text: "x_address_desc".tr,
            url: LinkConst.reviewRippleXAddress,
            linkDesc: "read_more".tr,
          ),
          value: isXAddress,
          onChanged: (v) {
            onSelectAddressType();
          },
        ),
        WidgetConstant.height20,
        APPAnimatedSwitcher(widgets: {
          XrpAddressType.classic: (c) => WidgetConstant.sizedBox,
          XrpAddressType.xAddress: (c) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("tag".tr, style: context.textTheme.titleMedium),
                  Text("enter_tag_desc".tr),
                  WidgetConstant.height8,
                  NumberTextField(
                      label: "tag".tr,
                      onChangeValue: onChangeTag,
                      validator: validateTag,
                      defaultValue: tag,
                      max: BinaryOps.mask32 - 1,
                      min: 0),
                ],
              )
        }, enable: addressTyoe),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FixedElevatedButton(
              padding: WidgetConstant.paddingVertical40,
              onPressed: generateAddress,
              child: Text("generate_address".tr),
            ),
          ],
        )
      ],
    );
  }
}
