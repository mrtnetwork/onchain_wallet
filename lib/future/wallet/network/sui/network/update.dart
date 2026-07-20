import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/provider/update_network_provider.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain/sui/sui.dart';
import 'package:on_chain_wallet/app/core.dart';

class UpdateSuiProvider extends StatelessWidget {
  const UpdateSuiProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<SuiNetworkClient?, ISuiAddress?, SuiChain>(
        addressRequired: false,
        clientRequired: false,
        childBulder: (wallet, account, client, address) => _UpdateSuiProvider(account));
  }
}

class _UpdateSuiProvider extends StatefulWidget {
  const _UpdateSuiProvider(this.account);
  final SuiChain account;

  @override
  State<_UpdateSuiProvider> createState() => _UpdateSuiProviderState();
}

class _UpdateSuiProviderState extends State<_UpdateSuiProvider>
    with
        SafeState<_UpdateSuiProvider>,
        UpdateNetworkProviderState<_UpdateSuiProvider, SuiAddress, ISuiAddress,
            SuiNetworkClient, TokenCore, NFTCore, SuiChain> {
  @override
  SuiChain get chain => widget.account;

  @override
  Future<DefaultAPIProvider> validate(DefaultAPIProvider provider) async {
    final client = SuiNetworkClient.fromProvider(
      provider: SuiNetworkProvider(provider),
      network: network.cast(),
      netApi: context.appContext.netApi,
    );
    try {
      final init = await client.validateNetworkIdentifier();
      if (!init) {
        throw AppException("network_genesis_hash_validator");
      }
      return provider;
    } finally {
      client.dispose();
    }
  }
}
