import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/provider/update_network_provider.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/app/core.dart';

class UpdateCosmosProvider extends StatelessWidget {
  const UpdateCosmosProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<CosmosNetworkClient?, ICosmosAddress?,
            CosmosChain>(
        addressRequired: false,
        clientRequired: false,
        childBulder: (wallet, account, client, address) =>
            _UpdateCosmosProvider(account));
  }
}

class _UpdateCosmosProvider extends StatefulWidget {
  const _UpdateCosmosProvider(this.account);
  final CosmosChain account;

  @override
  State<_UpdateCosmosProvider> createState() => _UpdateCosmosProviderState();
}

class _UpdateCosmosProviderState extends State<_UpdateCosmosProvider>
    with
        SafeState<_UpdateCosmosProvider>,
        UpdateNetworkProviderState<_UpdateCosmosProvider, CosmosBaseAddress,
            ICosmosAddress, CosmosNetworkClient, TokenCore, NFTCore, CosmosChain> {
  @override
  CosmosChain get chain => widget.account;

  @override
  Future<DefaultAPIProvider> validate(DefaultAPIProvider provider) async {
    final client = CosmosNetworkClient.fromProvider(
      provider: CosmosNetworkProvider(provider),
      network: network.cast(),
      netApi: context.appContext.netApi,
    );
    try {
      final init = await client.validateNetworkChainId();
      if (!init) {
        throw AppException("network_incorrect_chain_id");
      }
      return provider;
    } finally {
      client.dispose();
    }
  }
}
