import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/provider/update_network_provider.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:xrpl_dart/xrpl_dart.dart';
import 'package:on_chain_wallet/app/core.dart';

class UpdateRippleProviderView extends StatelessWidget {
  const UpdateRippleProviderView({super.key});

  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<XRPNetworkClient?, IXRPAddress?, XRPChain>(
        addressRequired: false,
        clientRequired: false,
        childBulder: (wallet, account, client, address) =>
            _UpdateRippleProvider(account));
  }
}

class _UpdateRippleProvider extends StatefulWidget {
  const _UpdateRippleProvider(this.account);
  final XRPChain account;

  @override
  State<_UpdateRippleProvider> createState() => _UpdateRippleProviderState();
}

class _UpdateRippleProviderState extends State<_UpdateRippleProvider>
    with
        SafeState<_UpdateRippleProvider>,
        UpdateNetworkProviderState<_UpdateRippleProvider, XRPBaseAddress, IXRPAddress,
            XRPNetworkClient, TokenCore, NFTCore, XRPChain> {
  @override
  XRPChain get chain => widget.account;

  @override
  Future<DefaultAPIProvider> validate(DefaultAPIProvider provider) async {
    final client = XRPNetworkClient.fromProvider(
        netApi: context.appContext.netApi,
        provider: XRPNetworkProvider(provider),
        network: network.cast());
    try {
      final init = await client.validateNetworkId();
      if (!init) {
        throw AppException("ripple_provider_network_id_validator");
      }
      return provider;
    } finally {
      client.dispose();
    }
  }
}
