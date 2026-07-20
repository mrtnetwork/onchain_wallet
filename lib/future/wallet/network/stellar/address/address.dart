import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

class SetupStellarAddressView extends StatefulWidget {
  final AddressDerivationController controller;
  const SetupStellarAddressView({super.key, required this.controller});
  @override
  State<SetupStellarAddressView> createState() => _SetupStellarAddressViewState();
}

class _SetupStellarAddressViewState extends State<SetupStellarAddressView>
    with SafeState {
  StellarAddressType addressTyoe = StellarAddressType.pubkey;
  bool get isMuxedAddress => addressTyoe == StellarAddressType.muxedAddress;
  BigInt id = BigInt.zero;
  void onChangeTag(BigInt newTag) {
    if (newTag.isNegative || newTag > BinaryOps.maxU64) return;
    id = newTag;
  }

  String? validateTag(String? v) {
    if (!isMuxedAddress) return null;
    final newTag = BigInt.tryParse(v ?? "");
    if (newTag == null || newTag.isNegative || newTag > BinaryOps.maxU64) {
      return "uint64_validator".tr.tr.replaceOne("id".tr);
    }
    return null;
  }

  void onSelectAddressType() {
    addressTyoe =
        isMuxedAddress ? StellarAddressType.pubkey : StellarAddressType.muxedAddress;
    setState(() {});
  }

  void generateAddress() async {
    final keyIndex = await widget.controller.getCoin(
        context: context,
        seedGeneration: SeedTypes.bip39,
        selectedCoins: widget.controller.network.coins.first);
    if (keyIndex == null) return;

    final newAccount = StellarNewAddressParams(
      deriveIndex: keyIndex,
      id: isMuxedAddress ? id : null,
      coin: widget.controller.network.coins.first,
    );
    widget.controller.generateAddress(newAccount);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppCheckListTile(
          title: Text("muxed_address".tr, style: context.textTheme.titleMedium),
          contentPadding: EdgeInsets.zero,
          subtitle: TextAndLinkView(
              text: "stellar_muxed_address_desc".tr,
              url: LinkConst.reviewStellarMuxedAddress),
          value: isMuxedAddress,
          onChanged: (v) {
            onSelectAddressType();
          },
        ),
        WidgetConstant.height20,
        APPAnimatedSwitcher<StellarAddressType>(widgets: {
          StellarAddressType.pubkey: (c) => WidgetConstant.sizedBox,
          StellarAddressType.muxedAddress: (c) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("id".tr, style: context.textTheme.titleMedium),
                  Text("enter_stellar_muxed_id_desc".tr),
                  WidgetConstant.height8,
                  BigNumberTextField(
                      label: "id".tr,
                      onChange: onChangeTag,
                      validator: validateTag,
                      defaultValue: id,
                      max: BinaryOps.maxU64,
                      min: BigInt.zero),
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
