import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/network/import/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/web3/pages/import_network.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/web3/core/state.dart';
import 'package:on_chain_wallet/wallet/api/api.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/networks/ethereum/params/models/add_eth_chain.dart';

class Web3EthereumImportNetworkStateController extends Web3EthereumStateController<String,
    EthereumNetworkClient?, Web3EthereumAddNewChain> {
  late final form = EthereumAddNewChainFrom(walletProvider.wallet.config.netApi);
  Web3EthereumImportNetworkStateController(
      {required super.walletProvider, required super.request});

  void importNetwork({BuildContext? context}) {
    final ready = form.isReady();
    if (!ready) return;
    acceptRequest(context: context);
  }

  @override
  Future<Web3RequestResponseData<String>> getResponse() async {
    final result = await IResult.call(() async {
      final params = await form.buildNetwork();
      final newNetwork = WalletEthereumNetwork(-1, params!.$1);
      (await walletProvider.wallet.doAction(
              WalletActionImportNewNetwork(network: newNetwork, providers: [params.$2])))
          .unwrap();
      return Web3RequestResponseData<String>(
          response: newNetwork.coinParam.chainId.toRadix16);
    });
    if (result.isErr) {
      throw AppException(result.unwrapErr().localizationError);
    }
    return result.unwrap();
  }

  @override
  Future<void> initForm(EthereumNetworkClient? client) async {
    await super.initForm(client);
    final ethChains = walletProvider.wallet.getChains<EthereumChain>();
    final existsChainIds = ethChains.map((e) => e.chainId).toList();
    form.initForm(
        existsChainIds: existsChainIds,
        chainId: params.newChainId,
        blockExplorerUrls: params.blockExplorerUrls,
        iconUrls: params.iconUrls,
        name: params.name,
        networkName: params.chainName,
        rpcUrls: params.rpcUrls,
        symbol: params.symbol);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return Web3EthereumImportNetworkStateView(this);
  }

  @override
  void dispose() {
    super.dispose();
    form.dispose();
  }
}
