import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/provider/update_network_provider.dart';
import 'package:zcash_dart/zcash.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class UpdateZcashProvider extends StatelessWidget {
  const UpdateZcashProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<ZcashNetworkClient?, IZcashAddress?, ZcashChain>(
        addressRequired: false,
        clientRequired: false,
        childBulder: (wallet, account, client, address) => _UpdateZcashProvider(account));
  }
}

class _UpdateZcashProvider extends StatefulWidget {
  const _UpdateZcashProvider(this.account);
  final ZcashChain account;

  @override
  State<_UpdateZcashProvider> createState() => _UpdateSolanaProviderState();
}

class _UpdateSolanaProviderState extends State<_UpdateZcashProvider>
    with
        SafeState<_UpdateZcashProvider>,
        UpdateNetworkProviderState<_UpdateZcashProvider, ZcashAddress, IZcashAddress,
            ZcashNetworkClient, TokenCore, NFTCore, ZcashChain> {
  @override
  ZcashChain get chain => widget.account;

  @override
  Future<DefaultAPIProvider> validate(DefaultAPIProvider provider) async {
    final client = ZcashNetworkClient.fromProvider(
        netApi: context.appContext.netApi,
        provider: ZcashNetworkProvider(provider),
        network: chain.network);
    try {
      if (await client.validateNu6ActiveHeight()) {
        return provider;
      }
      throw AppException("provider_validation_failed_desc");
    } finally {
      client.dispose();
    }
  }
}
