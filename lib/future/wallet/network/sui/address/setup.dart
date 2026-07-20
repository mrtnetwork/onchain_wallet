import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

class SetupSuiAddressView extends StatefulWidget {
  final AddressDerivationController controller;
  const SetupSuiAddressView({super.key, required this.controller});
  @override
  State<SetupSuiAddressView> createState() => _SetupSuiAddressViewState();
}

class _SetupSuiAddressViewState extends State<SetupSuiAddressView> with SafeState {
  SuiSupportKeyScheme algorithm = SuiSupportKeyScheme.ed25519;

  late final Map<SuiSupportKeyScheme, Widget> algorithmTypesWidget;

  void onChangeAlgorithm(SuiSupportKeyScheme? alg) {
    algorithm = alg ?? algorithm;
    updateState();
  }

  Bip44Coins findCoin(SuiSupportKeyScheme algorithm) {
    final coins = widget.controller.network.coins.cast<Bip44Coins>();
    switch (algorithm) {
      case SuiSupportKeyScheme.ed25519:
        return coins.firstWhere((e) => e == Bip44Coins.sui);
      case SuiSupportKeyScheme.secp256k1:
        return coins.firstWhere((e) => e == Bip44Coins.suiSecp256k1);
      case SuiSupportKeyScheme.secp256r1:
        return coins.firstWhere((e) => e == Bip44Coins.suiSecp256r1);
      case SuiSupportKeyScheme.multisig:
        throw UnimplementedError();
    }
  }

  void generateAddress() async {
    final algorithm = this.algorithm;
    final coin = findCoin(algorithm);
    final keyIndex = await widget.controller
        .getCoin(context: context, seedGeneration: SeedTypes.bip39, selectedCoins: coin);
    if (keyIndex == null || keyIndex.currencyCoin.conf.type != coin.conf.type) {
      return;
    }
    final newAccount =
        SuiNewAddressParams(deriveIndex: keyIndex, coin: coin, keyScheme: algorithm);
    widget.controller.generateAddress(newAccount);
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    algorithmTypesWidget = {
      for (final i in SuiSupportKeyScheme.values)
        if (i != SuiSupportKeyScheme.multisig) i: Text(i.name)
    };
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FixedElevatedButton(
                padding: WidgetConstant.paddingVertical40,
                onPressed: generateAddress,
                child: Text("generate_address".tr))
          ],
        )
      ],
    );
  }
}
