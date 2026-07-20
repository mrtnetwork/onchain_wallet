import 'package:flutter/material.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/chain_permission.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/permission_view.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';
import 'package:on_chain/tron/src/address/tron_address.dart';

class TronWeb3PermissionView extends StatefulWidget {
  const TronWeb3PermissionView({required this.application, super.key});
  final Web3ApplicationAuthentication application;

  @override
  State<TronWeb3PermissionView> createState() => _TronWeb3PermissionViewState();
}

class _TronWeb3PermissionViewState extends State<TronWeb3PermissionView>
    with
        SafeState,
        Web3PermissionState<
            TronWeb3PermissionView,
            TronAddress,
            TronChain,
            ITronAddress,
            Web3InternalDefaultNetworkAccount,
            Web3InternalDefaultNetwork,
            Web3InternalDefaultChain>,
        Web3DefaultPermissionState<ITronAddress> {
  @override
  Web3ApplicationAuthentication get application => widget.application;
  @override
  NetworkType get type => NetworkType.tron;

  @override
  Widget build(BuildContext context) {
    return UpdateChainPermissionWidget<TronAddress, ITronAddress, TronChain>(
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
