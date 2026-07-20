import 'package:blockchain_utils/bip/bip/conf/bip/bip_coins.dart';
import 'package:blockchain_utils/bip/bip/conf/core/coins.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/substrate/conf/substrate_coins.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:polkadot_dart/polkadot_dart.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

enum _SubstrateKeyAlgorithm {
  sr25519(name: "Sr25519", value: 0),
  ecdsa(name: "Ecdsa", value: 1),
  ed25519(name: "Ed25519", value: 2),
  ethereum(name: "Ethereum", value: 3),
  ed25519Slip(name: "Ed25519(SLIP)", value: 2);

  final String name;
  final int value;
  const _SubstrateKeyAlgorithm({required this.name, required this.value});
  SubstrateKeyAlgorithm get algorithm {
    return SubstrateKeyAlgorithm.fromValue(value);
  }
}

class SetupSubstrateAddressView extends StatefulWidget {
  final AddressDerivationController controller;
  const SetupSubstrateAddressView({super.key, required this.controller});
  @override
  State<SetupSubstrateAddressView> createState() => _SetupSubstrateAddressViewState();
}

class _SetupSubstrateAddressViewState extends State<SetupSubstrateAddressView>
    with SafeState {
  _SubstrateKeyAlgorithm algorithm = _SubstrateKeyAlgorithm.ed25519Slip;
  late final List<_SubstrateKeyAlgorithm> supportedAlgorithms;

  late final Map<_SubstrateKeyAlgorithm, Widget> algorithmTypesWidget;

  void onChangeAlgorithm(_SubstrateKeyAlgorithm? alg) {
    if (!supportedAlgorithms.contains(alg)) return;
    algorithm = alg ?? algorithm;
    updateState();
  }

  CryptoCoins findCoin() {
    final coins = widget.controller.network.coins;
    switch (algorithm) {
      case _SubstrateKeyAlgorithm.ethereum:
        return coins
            .whereType<BipCoins>()
            .firstWhere((e) => e.conf.type == EllipticCurveTypes.secp256k1);

      case _SubstrateKeyAlgorithm.ed25519Slip:
        return coins
            .whereType<BipCoins>()
            .firstWhere((e) => e.conf.type == EllipticCurveTypes.ed25519);
      default:
        return coins
            .whereType<SubstrateCoins>()
            .firstWhere((element) => element.conf.type == algorithm.algorithm.curve);
    }
  }

  void generateAddress() async {
    final coin = findCoin();
    final keyIndex = await widget.controller.getCoin(
        context: context,
        seedGeneration: coin is BipCoins ? SeedTypes.bip39 : SeedTypes.bip39Entropy,
        selectedCoins: coin);
    if (keyIndex == null || keyIndex.currencyCoin.conf.type != coin.conf.type) {
      return;
    }
    final newAccount = SubstrateNewAddressParams(deriveIndex: keyIndex);
    widget.controller.generateAddress(newAccount);
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    final network = widget.controller.network.cast<WalletSubstrateNetwork>();
    supportedAlgorithms = network.coinParam.keyAlgorithms
        .map((e) => _SubstrateKeyAlgorithm.values.where((i) => e.value == i.value))
        .expand((e) => e)
        .toList();
    algorithm = supportedAlgorithms.firstWhere(
      (e) => e == _SubstrateKeyAlgorithm.ed25519Slip,
      orElse: () => supportedAlgorithms.first,
    );
    algorithmTypesWidget = {for (final i in supportedAlgorithms) i: Text(i.name)};
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WidgetConstant.height20,
        Text("keypair_type".tr, style: context.textTheme.titleMedium),
        TextAndLinkView(
          text: "choose_key_algorithm_desc2".tr,
          url: LinkConst.reviewSubstrateSignatureSchame,
          linkDesc: "read_more".tr,
        ),
        WidgetConstant.height8,
        AppDropDownBottom(
            items: algorithmTypesWidget,
            hint: "keypair_type".tr,
            onChanged: onChangeAlgorithm,
            isExpanded: true,
            value: algorithm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FixedElevatedButton(
                padding: WidgetConstant.paddingVertical40,
                onPressed: generateAddress,
                child: Text("generate_address".tr)),
          ],
        )
      ],
    );
  }
}
