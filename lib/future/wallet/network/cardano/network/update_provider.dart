import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/provider/update_network_provider.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/app/core.dart';

class UpdateCardanoProvider extends StatelessWidget {
  const UpdateCardanoProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<ADANetworkClient?, ICardanoAddress?, ADAChain>(
        addressRequired: false,
        clientRequired: false,
        childBulder: (wallet, account, client, address) =>
            _UpdateCardanoProvider(account));
  }
}

class _UpdateCardanoProvider extends StatefulWidget {
  const _UpdateCardanoProvider(this.account);
  final ADAChain account;

  @override
  State<_UpdateCardanoProvider> createState() => _UpdateSolanaProviderState();
}

class _UpdateSolanaProviderState extends State<_UpdateCardanoProvider>
    with
        SafeState<_UpdateCardanoProvider>,
        UpdateNetworkProviderState<_UpdateCardanoProvider, ADAAddress, ICardanoAddress,
            ADANetworkClient, TokenCore, NFTCore, ADAChain> {
  @override
  ADAChain get chain => widget.account;

  @override
  Future<DefaultAPIProvider> validate(DefaultAPIProvider provider) async {
    final client = ADANetworkClient.fromProvider(
        netApi: context.appContext.netApi,
        provider: CardanoNetworkProvider(provider),
        network: network.cast());
    try {
      final init = await client.validateNetworkMagicNumber();
      if (!init) {
        throw AppException("cardano_network_magic_validator");
      }
      return provider;
    } finally {
      client.dispose();
    }
  }
}
