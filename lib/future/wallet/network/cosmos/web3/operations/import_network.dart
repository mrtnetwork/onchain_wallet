import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/network/import/controller/form.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/web3/pages/import_network.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/web3/core/state.dart';
import 'package:on_chain_wallet/wallet/api/api.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/networks/cosmos/params/models/add_new_chain.dart';

class Web3CosmosImportNetworkStateController
    extends Web3CosmosStateController<bool, CosmosNetworkClient?, Web3CosmosAddNewChain> {
  late final form = CosmosAddNewChainFrom(walletProvider.context);
  Web3CosmosImportNetworkStateController(
      {required super.walletProvider, required super.request});

  @override
  Future<Web3RequestResponseData<bool>> getResponse() async {
    final networkParams = await form.createNetwork(
      onUnknownAlgAlert: () async => true,
    );
    if (networkParams == null) {
      throw AppException("some_required_field_not_filled");
    }
    final newNetwork = WalletCosmosNetwork(-1, networkParams.$1);
    final params =
        WalletActionImportNewNetwork(network: newNetwork, providers: [networkParams.$2]);
    (await walletProvider.wallet.doAction(params)).unwrap();
    return Web3RequestResponseData(response: true);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return Web3CosmosImportNetworkStateView(this);
  }

  @override
  TransactionStateStatus getStateStatus() {
    final status = super.getStateStatus();
    if (status.isReady) {
      return TransactionStateStatus.ready(
          warning: form.unknowKeyAlg ? "cosmos_key_alg_desc2".tr : null);
    }
    return status;
  }

  @override
  Future<void> initForm(CosmosNetworkClient? client) async {
    await super.initForm(client);
    await form.initForm();
    form.buildFromWeb3Request(
        chainId: params.chainId,
        rpc: params.rpc,
        feeTokens: params.feeTokens,
        keyAlogrithm: params.keyAlgorithm,
        hrp: params.hrp,
        nativeToken: params.nativeToken,
        name: params.name);
  }

  @override
  void dispose() {
    super.dispose();
    form.dispose();
  }
}
