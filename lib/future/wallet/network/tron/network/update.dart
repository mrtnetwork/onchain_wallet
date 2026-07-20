import 'package:flutter/material.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/provider/update_network_provider.dart';
import 'package:on_chain_wallet/wallet/api/types/types.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class UpdateTronProvider extends StatelessWidget {
  const UpdateTronProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<TronClient?, ITronAddress?, TronChain>(
        addressRequired: false,
        clientRequired: false,
        childBulder: (wallet, account, client, address) => _UpdateTronProvider(account));
  }
}

class _UpdateTronProvider extends StatefulWidget {
  const _UpdateTronProvider(this.account);
  final TronChain account;

  @override
  State<_UpdateTronProvider> createState() => _UpdateTronProviderState();
}

class _UpdateTronProviderState extends State<_UpdateTronProvider>
    with
        SafeState<_UpdateTronProvider>,
        UpdateNetworkProviderState<_UpdateTronProvider, TronAddress, ITronAddress,
            TronClient, TokenCore, NFTCore, TronChain> {
  @override
  TronChain get chain => widget.account;

  @override
  Future<DefaultAPIProvider> validate(DefaultAPIProvider provider) async {
    TronClient? client;
    try {
      if (provider.service == APIProviderServices.ethereumJsonRpc) {
        client = TronClient.fromProvider(
            netApi: context.appContext.netApi,
            provider: TronNetworkProvider(ethereum: provider, node: provider),
            network: chain.network);
        final correctChainId = await client.checkSolidityChainId();
        if (!correctChainId) throw AppException("network_incorrect_chain_id");
        return provider;
      }
      if (provider.service == APIProviderServices.tron) {
        client = TronClient.fromProvider(
            netApi: context.appContext.netApi,
            provider: TronNetworkProvider(ethereum: provider, node: provider),
            network: chain.network);
        final correctChainId = await client.checkGenesis();
        if (!correctChainId) throw AppException("network_genesis_hash_validator");
        return provider;
      }
      throw WalletExceptionConst.invalidProviderInformation;
    } finally {
      client?.dispose();
    }
  }
}
