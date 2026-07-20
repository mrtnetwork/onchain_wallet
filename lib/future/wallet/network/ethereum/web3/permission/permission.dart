import 'package:flutter/material.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/chain_permission.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/permission_view.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/models/authenticated.dart';
import 'package:on_chain/ethereum/src/address/evm_address.dart';

class EthereumWeb3PermissionView extends StatefulWidget {
  const EthereumWeb3PermissionView({required this.application, super.key});
  final Web3ApplicationAuthentication application;

  @override
  State<EthereumWeb3PermissionView> createState() => _EthereumWeb3PermissionViewState();
}

class _EthereumWeb3PermissionViewState extends State<EthereumWeb3PermissionView>
    with
        SafeState,
        Web3PermissionState<
            EthereumWeb3PermissionView,
            ETHAddress,
            EthereumChain,
            IEthereumAddress,
            Web3InternalDefaultNetworkAccount,
            Web3InternalDefaultNetwork,
            Web3InternalDefaultChain>,
        Web3DefaultPermissionState<IEthereumAddress> {
  @override
  Web3ApplicationAuthentication get application => widget.application;
  // @override
  // Web3EthereumChain createNewChainPermission() {
  //   return Web3EthereumChain.create(id: chain.network.value);
  // }

  // @override
  // Web3EthereumChainAccount createNewAccountPermission(
  //     IEthereumAddress address, bool isDefault) {
  //   return Web3EthereumChainAccount.fromChainAccount(
  //       address: address, id: chain.network.value, defaultAddress: isDefault);
  // }

  @override
  NetworkType get type => NetworkType.ethereum;

  @override
  Widget build(BuildContext context) {
    return UpdateChainPermissionWidget<ETHAddress, IEthereumAddress, EthereumChain>(
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
