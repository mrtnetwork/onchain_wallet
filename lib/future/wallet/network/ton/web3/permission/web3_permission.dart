import 'package:flutter/material.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/chain_permission.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/permission_view.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/models/authenticated.dart';
import 'package:ton_dart/ton_dart.dart';

class TonWeb3PermissionView extends StatefulWidget {
  const TonWeb3PermissionView({required this.application, super.key});
  final Web3ApplicationAuthentication application;

  @override
  State<TonWeb3PermissionView> createState() => _TonWeb3PermissionViewState();
}

class _TonWeb3PermissionViewState extends State<TonWeb3PermissionView>
    with
        SafeState,
        Web3PermissionState<
            TonWeb3PermissionView,
            TonAddress,
            TonChain,
            ITonAddress,
            Web3InternalDefaultNetworkAccount,
            Web3InternalDefaultNetwork,
            Web3InternalDefaultChain>,
        Web3DefaultPermissionState<ITonAddress> {
  @override
  Web3ApplicationAuthentication get application => widget.application;

  @override
  NetworkType get type => NetworkType.ton;

  @override
  Widget build(BuildContext context) {
    return UpdateChainPermissionWidget<TonAddress, ITonAddress, TonChain>(
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
