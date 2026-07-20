import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/provider/update_network_provider.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:ton_dart/ton_dart.dart';

class UpdateTonProvider extends StatelessWidget {
  const UpdateTonProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<TonNetworkClient?, ITonAddress?, TonChain>(
        addressRequired: false,
        clientRequired: false,
        childBulder: (wallet, account, client, address) => _UpdateTonProvider(account));
  }
}

class _UpdateTonProvider extends StatefulWidget {
  const _UpdateTonProvider(this.account);
  final TonChain account;

  @override
  State<_UpdateTonProvider> createState() => _UpdateSolanaProviderState();
}

class _UpdateSolanaProviderState extends State<_UpdateTonProvider>
    with
        SafeState<_UpdateTonProvider>,
        UpdateNetworkProviderState<_UpdateTonProvider, TonAddress, ITonAddress,
            TonNetworkClient, TokenCore, NFTCore, TonChain> {
  @override
  TonChain get chain => widget.account;

  @override
  Future<DefaultAPIProvider> validate(DefaultAPIProvider provider) async {
    final client = TonNetworkClient.fromProvider(
      provider: TonNetworkProvider(provider),
      network: network.cast(),
      netApi: context.appContext.netApi,
    );
    try {
      final result = await client.validateGlobalId();
      if (!result) {
        throw AppException("provider_validation_failed_desc");
      }
      return provider;
    } finally {
      client.dispose();
    }
  }
}
