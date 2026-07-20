import 'package:flutter/material.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/chain_permission.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/permission_view.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/models/authenticated.dart';
import 'package:polkadot_dart/polkadot_dart.dart';

class SubstrateWeb3PermissionView extends StatefulWidget {
  const SubstrateWeb3PermissionView({required this.application, super.key});
  final Web3ApplicationAuthentication application;

  @override
  State<SubstrateWeb3PermissionView> createState() => _SubstrateWeb3PermissionViewState();
}

class _SubstrateWeb3PermissionViewState extends State<SubstrateWeb3PermissionView>
    with
        SafeState,
        Web3PermissionState<
            SubstrateWeb3PermissionView,
            BaseSubstrateAddress,
            SubstrateChain,
            ISubstrateAddress,
            Web3InternalDefaultNetworkAccount,
            Web3InternalDefaultNetwork,
            Web3InternalDefaultChain>,
        Web3DefaultPermissionState<ISubstrateAddress> {
  @override
  Web3ApplicationAuthentication get application => widget.application;

  @override
  NetworkType get type => NetworkType.substrate;

  @override
  Widget build(BuildContext context) {
    return UpdateChainPermissionWidget<BaseSubstrateAddress, ISubstrateAddress,
            SubstrateChain>(
        isDefaultAddress: isDefaultAddress,
        chain: chain,
        chains: chains,
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
