import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/provider/update_network_provider.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:polkadot_dart/polkadot_dart.dart';
import 'package:on_chain_wallet/app/core.dart';

class UpdateSubstrateProvider extends StatelessWidget {
  const UpdateSubstrateProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<SubstrateNetworkClient?, ISubstrateAddress?,
            SubstrateChain>(
        addressRequired: false,
        clientRequired: false,
        childBulder: (wallet, account, client, address) =>
            _UpdateSubstrateProvider(account));
  }
}

class _UpdateSubstrateProvider extends StatefulWidget {
  const _UpdateSubstrateProvider(this.account);
  final SubstrateChain account;

  @override
  State<_UpdateSubstrateProvider> createState() => _UpdateSolanaProviderState();
}

class _UpdateSolanaProviderState extends State<_UpdateSubstrateProvider>
    with
        SafeState<_UpdateSubstrateProvider>,
        UpdateNetworkProviderState<
            _UpdateSubstrateProvider,
            BaseSubstrateAddress,
            ISubstrateAddress,
            SubstrateNetworkClient,
            TokenCore,
            NFTCore,
            SubstrateChain> {
  @override
  SubstrateChain get chain => widget.account;

  @override
  Future<DefaultAPIProvider> validate(DefaultAPIProvider provider) async {
    final client = SubstrateNetworkClient.fromProvider(
        netApi: context.appContext.netApi,
        provider: SubstrateNetworkProvider(provider),
        network: network.cast());
    try {
      final init = await client.validateNetworkGenesis();
      if (!init) {
        throw AppException("network_genesis_hash_validator");
      }
      return provider;
    } finally {
      client.dispose();
    }
  }
}
