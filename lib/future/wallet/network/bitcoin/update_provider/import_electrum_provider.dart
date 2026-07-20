import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/provider/update_network_provider.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/app/core.dart';

class ImportElectrumProviderView extends StatelessWidget {
  const ImportElectrumProviderView({super.key});

  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<BitcoinNetworkClient?, IBitcoinAddress?,
        BitcoinChain>(
      addressRequired: false,
      clientRequired: false,
      childBulder: (wallet, account, client, address) => _ImportElectrumProvider(account),
    );
  }
}

class _ImportElectrumProvider extends StatefulWidget {
  const _ImportElectrumProvider(this.account);
  final BitcoinChain account;

  @override
  State<_ImportElectrumProvider> createState() => __ImportElectrumProviderState();
}

class __ImportElectrumProviderState extends State<_ImportElectrumProvider>
    with
        SafeState<_ImportElectrumProvider>,
        UpdateNetworkProviderState<_ImportElectrumProvider, BitcoinNetworkAddress,
            IBitcoinAddress, BitcoinNetworkClient, TokenCore, NFTCore, BitcoinChain> {
  @override
  BitcoinChain get chain => widget.account;

  @override
  Future<DefaultAPIProvider> validate(DefaultAPIProvider provider) async {
    final client = BitcoinNetworkClient.fromProvider(
        netApi: context.appContext.netApi,
        provider: BitcoinNetworkProvider(provider),
        network: network.cast());
    try {
      final init = await client.validateGenesisHash();
      if (!init) {
        throw AppException("network_genesis_hash_validator");
      }
      return provider;
    } finally {
      client.dispose();
    }
  }
}
