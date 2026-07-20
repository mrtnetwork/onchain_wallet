import 'package:flutter/material.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/provider/update_network_provider.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/app/core.dart';

class UpdateMoneroProvider extends StatelessWidget {
  const UpdateMoneroProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<MoneroNetworkClient?, IMoneroAddress?,
            MoneroChain>(
        addressRequired: false,
        clientRequired: false,
        childBulder: (wallet, account, client, address) =>
            _UpdateMoneroProvider(account));
  }
}

class _UpdateMoneroProvider extends StatefulWidget {
  const _UpdateMoneroProvider(this.account);
  final MoneroChain account;

  @override
  State<_UpdateMoneroProvider> createState() => _UpdateMoneroProviderState();
}

class _UpdateMoneroProviderState extends State<_UpdateMoneroProvider>
    with
        SafeState<_UpdateMoneroProvider>,
        UpdateNetworkProviderState<_UpdateMoneroProvider, MoneroAddress, IMoneroAddress,
            MoneroNetworkClient, TokenCore, NFTCore, MoneroChain> {
  @override
  MoneroChain get chain => widget.account;

  @override
  Future<DefaultAPIProvider> validate(DefaultAPIProvider provider) async {
    final client = MoneroNetworkClient.fromProvider(
      provider: MoneroNetworkProvider(provider),
      network: network.cast(),
      netApi: context.appContext.netApi,
    );
    try {
      final tracker = await chain.getChainTracker();
      final height = tracker
          .map<int>((e) => e.defaultTracker.offsets.currentHeight)
          .unwrapOr((_) => 0);
      final init = await client.validateNetworkGenesis(latestFetchedHeight: height);
      if (!init) {
        throw AppException("network_genesis_hash_validator");
      }
      return provider;
    } finally {
      client.dispose();
    }
  }
}
