import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class SetupCosmosAddressView extends StatefulWidget {
  final AddressDerivationController controller;
  const SetupCosmosAddressView({super.key, required this.controller});
  @override
  State<SetupCosmosAddressView> createState() => _SetupCosmosAddressViewState();
}

class _SetupCosmosAddressViewState extends State<SetupCosmosAddressView> with SafeState {
  WalletCosmosNetwork get network => widget.controller.network.cast();
  late final List<CosmosKeysAlgs> keyAlgs;
  Map<CosmosKeysAlgs, Widget> algsItems = {};
  late CosmosKeysAlgs keyAlg;

  Map<CosmosKeysAlgs, Widget> buildAlgs() {
    return {for (final i in keyAlgs) i: Text(i.name.camelCase)};
  }

  void onChangeAlg(CosmosKeysAlgs? keyAlg) {
    if (keyAlg == null) return;
    this.keyAlg = keyAlg;
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    keyAlgs = network.coinParam.keysAlgs;
    keyAlg = keyAlgs.first;
    algsItems = buildAlgs();
  }

  void generateAddress() async {
    final selectedAlg = keyAlg;
    final coin = selectedAlg.coin(network.coinParam.chainType);
    final keyIndex = await widget.controller
        .getCoin(context: context, seedGeneration: SeedTypes.bip39, selectedCoins: coin);
    if (keyIndex == null) return;

    final newAccount = CosmosNewAddressParams(
        deriveIndex: keyIndex,
        coin: widget.controller.network.coins.firstWhere(
            (element) => element.conf.type == keyIndex.currencyCoin.conf.type),
        algorithm: selectedAlg);
    widget.controller.generateAddress(newAccount);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("key_alg".tr),
        Text("cosmos_key_alg_desc".tr),
        WidgetConstant.height8,
        AppDropDownBottom(
            items: algsItems, hint: "key_alg".tr, onChanged: onChangeAlg, value: keyAlg),
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
