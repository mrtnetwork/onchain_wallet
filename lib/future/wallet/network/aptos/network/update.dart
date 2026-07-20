import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/provider/update_network_provider.dart';
import 'package:on_chain_wallet/wallet/api/types/types.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain/aptos/src/address/address/address.dart';

class UpdateAptosProvider extends StatelessWidget {
  const UpdateAptosProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<AptosNetworkClient?, IAptosAddress?, AptosChain>(
        addressRequired: false,
        clientRequired: false,
        childBulder: (wallet, account, client, address) => _UpdateAptosProvider(account));
  }
}

class _UpdateAptosProvider extends StatefulWidget {
  const _UpdateAptosProvider(this.account);
  final AptosChain account;

  @override
  State<_UpdateAptosProvider> createState() => _UpdateAptosProviderState();
}

class _UpdateAptosProviderState extends State<_UpdateAptosProvider>
    with
        SafeState<_UpdateAptosProvider>,
        UpdateNetworkProviderState<_UpdateAptosProvider, AptosAddress, IAptosAddress,
            AptosNetworkClient, TokenCore, NFTCore, AptosChain> {
  @override
  AptosChain get chain => widget.account;

  @override
  Future<DefaultAPIProvider> validate(DefaultAPIProvider provider) async {
    AptosNetworkClient? client;
    try {
      if (provider.service == APIProviderServices.graphQl) {
        client = AptosNetworkClient.fromProvider(
            provider: AptosNetworkProvider(
                graphQl: provider,
                fullNode: provider.copyWith(service: APIProviderServices.aptos)),
            network: chain.network,
            netApi: context.appContext.netApi);
        final correctChainId = await client.validateGraphQl();
        if (!correctChainId) throw AppException("network_incorrect_chain_id");
        return provider;
      }
      if (provider.service == APIProviderServices.aptos) {
        client = AptosNetworkClient.fromProvider(
            netApi: context.appContext.netApi,
            provider: AptosNetworkProvider(
                graphQl: provider.copyWith(service: APIProviderServices.graphQl),
                fullNode: provider),
            network: chain.network);
        final correctChainId = await client.validateFullNode();
        if (!correctChainId) throw AppException("network_incorrect_chain_id");
        return provider;
      }
      throw WalletExceptionConst.invalidProviderInformation;
    } finally {
      client?.dispose();
    }
  }
}
