import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/chain_permission.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/permission_view.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/models/authenticated.dart';

class BitcoinCashWeb3PermissionView extends StatefulWidget {
  const BitcoinCashWeb3PermissionView({required this.application, super.key});
  final Web3ApplicationAuthentication application;

  @override
  State<BitcoinCashWeb3PermissionView> createState() =>
      _BitcoinCashWeb3PermissionViewState();
}

class _BitcoinCashWeb3PermissionViewState extends State<BitcoinCashWeb3PermissionView>
    with
        SafeState,
        Web3PermissionState<
            BitcoinCashWeb3PermissionView,
            BitcoinNetworkAddress,
            BitcoinChain,
            IBitcoinAddress,
            Web3InternalDefaultNetworkAccount,
            Web3InternalDefaultNetwork,
            Web3InternalDefaultChain>,
        Web3DefaultPermissionState<IBitcoinAddress> {
  @override
  Web3ApplicationAuthentication get application => widget.application;

  @override
  NetworkType get type => NetworkType.bitcoinCash;

  @override
  Widget build(BuildContext context) {
    return UpdateChainPermissionWidget<BitcoinNetworkAddress, IBitcoinAddress,
            BitcoinChain>(
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
