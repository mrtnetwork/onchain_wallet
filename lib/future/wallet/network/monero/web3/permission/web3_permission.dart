import 'package:flutter/material.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/chain_permission.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/permission_view.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/models/authenticated.dart';

class MoneroWeb3PermissionView extends StatefulWidget {
  const MoneroWeb3PermissionView({required this.application, super.key});
  final Web3ApplicationAuthentication application;

  @override
  State<MoneroWeb3PermissionView> createState() => _MoneroWeb3PermissionViewState();
}

class _MoneroWeb3PermissionViewState extends State<MoneroWeb3PermissionView>
    with
        SafeState,
        Web3PermissionState<
            MoneroWeb3PermissionView,
            MoneroAddress,
            MoneroChain,
            IMoneroAddress,
            Web3InternalDefaultNetworkAccount,
            Web3InternalDefaultNetwork,
            Web3InternalDefaultChain>,
        Web3DefaultPermissionState<IMoneroAddress> {
  @override
  Web3ApplicationAuthentication get application => widget.application;

  @override
  NetworkType get type => NetworkType.monero;

  @override
  Widget build(BuildContext context) {
    return UpdateChainPermissionWidget<MoneroAddress, IMoneroAddress, MoneroChain>(
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
