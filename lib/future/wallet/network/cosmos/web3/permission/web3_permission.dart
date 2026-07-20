import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/chain_permission.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/permission_view.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/models/authenticated.dart';

class CosmosWeb3PermissionView extends StatefulWidget {
  const CosmosWeb3PermissionView({required this.application, super.key});
  final Web3ApplicationAuthentication application;

  @override
  State<CosmosWeb3PermissionView> createState() => _CosmosWeb3PermissionViewState();
}

class _CosmosWeb3PermissionViewState extends State<CosmosWeb3PermissionView>
    with
        SafeState,
        Web3PermissionState<
            CosmosWeb3PermissionView,
            CosmosBaseAddress,
            CosmosChain,
            ICosmosAddress,
            Web3InternalDefaultNetworkAccount,
            Web3InternalDefaultNetwork,
            Web3InternalDefaultChain>,
        Web3DefaultPermissionState<ICosmosAddress> {
  @override
  Web3ApplicationAuthentication get application => widget.application;

  @override
  NetworkType get type => NetworkType.cosmos;
  @override
  Widget build(BuildContext context) {
    return UpdateChainPermissionWidget<CosmosBaseAddress, ICosmosAddress, CosmosChain>(
        chain: chain,
        isDefaultAddress: isDefaultAddress,
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
