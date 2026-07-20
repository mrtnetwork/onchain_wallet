import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/wallet/network/aptos/address/setup.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/address/setup_address.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/address/pages/setup_address.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/stellar.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/address/setup_address.dart';
import 'package:on_chain_wallet/future/wallet/network/sui/address/setup.dart';
import 'package:on_chain_wallet/future/wallet/network/ton/address/address.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'controller.dart';

class SetupGenericAddressView extends StatelessWidget {
  const SetupGenericAddressView({super.key, required this.controller});
  final AddressDerivationController controller;

  @override
  Widget build(BuildContext context) {
    switch (controller.network.type) {
      case NetworkType.xrpl:
        return SetupRippleAddressView(controller: controller);
      case NetworkType.cosmos:
        return SetupCosmosAddressView(controller: controller);
      case NetworkType.stellar:
        return SetupStellarAddressView(controller: controller);
      case NetworkType.ton:
        return SetupTonAddressView(controller: controller);

      case NetworkType.substrate:
        return SetupSubstrateAddressView(controller: controller);
      case NetworkType.aptos:
        return SetupAptosAddressView(controller: controller);
      case NetworkType.sui:
        return SetupSuiAddressView(controller: controller);

      default:
        throw UnimplementedError("invalid network");
    }
  }
}
