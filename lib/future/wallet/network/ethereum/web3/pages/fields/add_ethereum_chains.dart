import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/network/pages/import.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/web3/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/forms/ethereum/forms/web3/add_ethereum_chain.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/view_controller.dart';
import 'package:on_chain_wallet/wallet/web3/web3.dart';

class EthereumWeb3AddEthereumChainView extends StatelessWidget {
  const EthereumWeb3AddEthereumChainView(
      {required this.wallet, super.key, required this.request});
  final Web3EthereumRequest<String, Web3EthereumAddNewChain> request;
  final WalletProvider wallet;
  @override
  Widget build(BuildContext context) {
    return Web3NetworkPageRequestControllerView(
      width: null,
      request: request,
      controller: () =>
          Web3EthereumGlobalRequestController<String, Web3EthereumAddNewChain>(
              walletProvider: wallet, request: request),
      builder: (context, controller) => [
        SliverFillRemaining(
            child: ImportEthereumNetwork.fromWeb3(
                controller.form as Web3EthereumAddNewChainForm))
      ],
    );
  }
}
