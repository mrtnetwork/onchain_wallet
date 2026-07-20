import 'package:flutter/material.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/chain_permission.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/permission_view.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/models/authenticated.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

class RippleWeb3PermissionView extends StatefulWidget {
  const RippleWeb3PermissionView({required this.application, super.key});
  final Web3ApplicationAuthentication application;

  @override
  State<RippleWeb3PermissionView> createState() => _RippleWeb3PermissionViewState();
}

class _RippleWeb3PermissionViewState extends State<RippleWeb3PermissionView>
    with
        SafeState,
        Web3PermissionState<
            RippleWeb3PermissionView,
            XRPBaseAddress,
            XRPChain,
            IXRPAddress,
            Web3InternalDefaultNetworkAccount,
            Web3InternalDefaultNetwork,
            Web3InternalDefaultChain>,
        Web3DefaultPermissionState<IXRPAddress> {
  @override
  Web3ApplicationAuthentication get application => widget.application;

  @override
  NetworkType get type => NetworkType.xrpl;

  @override
  Widget build(BuildContext context) {
    return UpdateChainPermissionWidget<XRPBaseAddress, IXRPAddress, XRPChain>(
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
