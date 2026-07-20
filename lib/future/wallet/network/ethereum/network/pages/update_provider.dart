import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/provider/update_network_provider.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain/ethereum/ethereum.dart';
import 'package:on_chain_wallet/app/core.dart';

class UpdateEthereumProvider extends StatelessWidget {
  const UpdateEthereumProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<EthereumNetworkClient?, IEthereumAddress?,
            EthereumChain>(
        addressRequired: false,
        clientRequired: false,
        childBulder: (wallet, account, client, address) =>
            _UpdateEthereumProvider(account));
  }
}

class _UpdateEthereumProvider extends StatefulWidget {
  const _UpdateEthereumProvider(this.account);
  final EthereumChain account;

  @override
  State<_UpdateEthereumProvider> createState() => _UpdateSolanaProviderState();
}

class _UpdateSolanaProviderState extends State<_UpdateEthereumProvider>
    with
        SafeState<_UpdateEthereumProvider>,
        UpdateNetworkProviderState<_UpdateEthereumProvider, ETHAddress, IEthereumAddress,
            EthereumNetworkClient, TokenCore, NFTCore, EthereumChain> {
  @override
  EthereumChain get chain => widget.account;

  @override
  Future<DefaultAPIProvider> validate(DefaultAPIProvider provider) async {
    final client = EthereumNetworkClient.fromProvider(
      provider: EthereumNetworkProvider(provider),
      network: network.cast(),
      netApi: context.appContext.netApi,
    );
    try {
      final init = await client.checkNetworkChainId();
      if (!init) {
        throw AppException("network_incorrect_chain_id");
      }
      return provider;
    } finally {
      client.dispose();
    }
  }
}
