import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/provider/update_network_provider.dart';
import 'package:on_chain_wallet/wallet/api/types/types.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:stellar_dart/stellar_dart.dart';

class UpdateStellarProvider extends StatelessWidget {
  const UpdateStellarProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<StellarClient?, IStellarAddress?, StellarChain>(
        addressRequired: false,
        clientRequired: false,
        childBulder: (wallet, account, client, address) =>
            _UpdateStellarProvider(account));
  }
}

class _UpdateStellarProvider extends StatefulWidget {
  const _UpdateStellarProvider(this.account);
  final StellarChain account;

  @override
  State<_UpdateStellarProvider> createState() => _UpdateSolanaProviderState();
}

class _UpdateSolanaProviderState extends State<_UpdateStellarProvider>
    with
        SafeState<_UpdateStellarProvider>,
        UpdateNetworkProviderState<_UpdateStellarProvider, StellarAddress,
            IStellarAddress, StellarClient, TokenCore, NFTCore, StellarChain> {
  @override
  StellarChain get chain => widget.account;

  @override
  Future<DefaultAPIProvider> validate(DefaultAPIProvider provider) async {
    StellarClient? client;
    try {
      if (provider.service == APIProviderServices.horizon) {
        client = StellarClient.fromProvider(
            netApi: context.appContext.netApi,
            provider: StellarNetworkProvider(
                horizon: provider,
                soroban: provider.copyWith(service: APIProviderServices.stellarRpc)),
            network: chain.network);
        final correctChainId = await client.validateHorizon();
        if (!correctChainId) throw AppException("provider_validation_failed_desc");
        return provider;
      }
      if (provider.service == APIProviderServices.stellarRpc) {
        client = StellarClient.fromProvider(
            netApi: context.appContext.netApi,
            provider: StellarNetworkProvider(
                horizon: provider.copyWith(service: APIProviderServices.horizon),
                soroban: provider),
            network: chain.network);
        final correctChainId = await client.validateSoroban();
        if (!correctChainId) throw AppException("provider_validation_failed_desc");
        return provider;
      }
      throw WalletExceptionConst.invalidProviderInformation;
    } finally {
      client?.dispose();
    }
  }
}
