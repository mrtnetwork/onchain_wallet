import 'package:flutter/material.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/chain_permission.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/permission_view.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/models/authenticated.dart';
import 'package:on_chain/aptos/aptos.dart';

class AptosWeb3PermissionView extends StatefulWidget {
  const AptosWeb3PermissionView({required this.application, super.key});
  final Web3ApplicationAuthentication application;

  @override
  State<AptosWeb3PermissionView> createState() => _AptosWeb3PermissionViewState();
}

class _AptosWeb3PermissionViewState extends State<AptosWeb3PermissionView>
    with
        SafeState,
        Web3PermissionState<
            AptosWeb3PermissionView,
            AptosAddress,
            AptosChain,
            IAptosAddress,
            Web3InternalDefaultNetworkAccount,
            Web3InternalDefaultNetwork,
            Web3InternalDefaultChain>,
        Web3DefaultPermissionState<IAptosAddress> {
  @override
  Web3ApplicationAuthentication get application => widget.application;
  @override
  NetworkType get type => NetworkType.aptos;

  @override
  Widget build(BuildContext context) {
    return UpdateChainPermissionWidget<AptosAddress, IAptosAddress, AptosChain>(
        isDefaultAddress: isDefaultAddress,
        chain: chain,
        chains: chains,
        onUpdateState: updateState,
        hasPermission: hasPermission,
        addresses: chain.addresses,
        addAccount: addAccount,
        onChangeChain: onChangeChain,
        onChangeDefaultAccount: onChangeDefaultPermission,
        activities: activities,
        menuItems: menuItems);
  }
}
