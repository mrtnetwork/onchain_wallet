import 'package:flutter/material.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/chain_permission.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/permission_view.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/models/authenticated.dart';
import 'package:stellar_dart/stellar_dart.dart';

class StellarWeb3PermissionView extends StatefulWidget {
  const StellarWeb3PermissionView({required this.application, super.key});
  final Web3ApplicationAuthentication application;

  @override
  State<StellarWeb3PermissionView> createState() => _StellarWeb3PermissionViewState();
}

class _StellarWeb3PermissionViewState extends State<StellarWeb3PermissionView>
    with
        SafeState,
        Web3PermissionState<
            StellarWeb3PermissionView,
            StellarAddress,
            StellarChain,
            IStellarAddress,
            Web3InternalDefaultNetworkAccount,
            Web3InternalDefaultNetwork,
            Web3InternalDefaultChain>,
        Web3DefaultPermissionState<IStellarAddress> {
  @override
  Web3ApplicationAuthentication get application => widget.application;

  @override
  NetworkType get type => NetworkType.stellar;

  @override
  Widget build(BuildContext context) {
    return UpdateChainPermissionWidget<StellarAddress, IStellarAddress, StellarChain>(
        chain: chain,
        chains: chains,
        isDefaultAddress: isDefaultAddress,
        onUpdateState: updateState,
        hasPermission: hasPermission,
        addAccount: addAccount,
        addresses: chain.addresses,
        onChangeChain: onChangeChain,
        onChangeDefaultAccount: onChangeDefaultPermission,
        activities: activities,
        menuItems: menuItems);
  }
}
