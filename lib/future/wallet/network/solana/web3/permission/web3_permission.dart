import 'package:flutter/material.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/chain_permission.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/permission_view.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/models/authenticated.dart';
import 'package:on_chain/solana/solana.dart';

class SolanaWeb3PermissionView extends StatefulWidget {
  const SolanaWeb3PermissionView({required this.application, super.key});
  final Web3ApplicationAuthentication application;

  @override
  State<SolanaWeb3PermissionView> createState() => _SolanaWeb3PermissionViewState();
}

class _SolanaWeb3PermissionViewState extends State<SolanaWeb3PermissionView>
    with
        SafeState,
        Web3PermissionState<
            SolanaWeb3PermissionView,
            SolAddress,
            SolanaChain,
            ISolanaAddress,
            Web3InternalDefaultNetworkAccount,
            Web3InternalDefaultNetwork,
            Web3InternalDefaultChain>,
        Web3DefaultPermissionState<ISolanaAddress> {
  @override
  Web3ApplicationAuthentication get application => widget.application;

  @override
  NetworkType get type => NetworkType.solana;

  @override
  Widget build(BuildContext context) {
    return UpdateChainPermissionWidget<SolAddress, ISolanaAddress, SolanaChain>(
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
