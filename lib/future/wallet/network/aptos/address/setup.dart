import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/wallet/models/networks/aptos/models/types.dart';

class SetupAptosAddressView extends StatefulWidget {
  final AddressDerivationController controller;
  const SetupAptosAddressView({super.key, required this.controller});
  @override
  State<SetupAptosAddressView> createState() => _SetupAptosAddressViewState();
}

class _SetupAptosAddressViewState extends State<SetupAptosAddressView> with SafeState {
  AptosSupportKeyScheme algorithm = AptosSupportKeyScheme.ed25519;

  late final Map<AptosSupportKeyScheme, Widget> algorithmTypesWidget;

  void onChangeAlgorithm(AptosSupportKeyScheme? alg) {
    algorithm = alg ?? algorithm;
    updateState();
  }

  Bip44Coins findCoin(AptosSupportKeyScheme algorithm) {
    final coins = widget.controller.network.coins.cast<Bip44Coins>();
    switch (algorithm) {
      case AptosSupportKeyScheme.ed25519:
        return coins.firstWhere((e) => e == Bip44Coins.aptos);
      case AptosSupportKeyScheme.signleKeyEd25519:
        return coins.firstWhere((e) => e == Bip44Coins.aptosEd25519SingleKey);
      case AptosSupportKeyScheme.signleKeySecp256k1:
        return coins.firstWhere((e) => e == Bip44Coins.aptosSecp256k1SingleKey);
      default:
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
        AptosNewAddressParams(deriveIndex: keyIndex, coin: coin, keyScheme: algorithm);
    widget.controller.generateAddress(newAccount);
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    algorithmTypesWidget = {
      for (final i in AptosSupportKeyScheme.values)
        if (!i.isMultisig) i: Text(i.name)
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
