import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/provider/update_network_provider.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain/solana/src/address/sol_address.dart';
import 'package:on_chain_wallet/app/core.dart';

class UpdateSolanaProvider extends StatelessWidget {
  const UpdateSolanaProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<SolanaNetworkClient?, ISolanaAddress?,
            SolanaChain>(
        addressRequired: false,
        clientRequired: false,
        childBulder: (wallet, account, client, address) =>
            _UpdateSolanaProvider(account));
  }
}

class _UpdateSolanaProvider extends StatefulWidget {
  const _UpdateSolanaProvider(this.account);
  final SolanaChain account;

  @override
  State<_UpdateSolanaProvider> createState() => _UpdateSolanaProviderState();
}

class _UpdateSolanaProviderState extends State<_UpdateSolanaProvider>
    with
        SafeState<_UpdateSolanaProvider>,
        UpdateNetworkProviderState<_UpdateSolanaProvider, SolAddress, ISolanaAddress,
            SolanaNetworkClient, TokenCore, NFTCore, SolanaChain> {
  @override
  SolanaChain get chain => widget.account;

  @override
  Future<DefaultAPIProvider> validate(DefaultAPIProvider provider) async {
    final client = SolanaNetworkClient.fromProvider(
        netApi: context.appContext.netApi,
        provider: SolanaNetworkProvider(provider),
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
