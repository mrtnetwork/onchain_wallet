import 'package:blockchain_utils/bip/bip/bip.dart';
import 'package:on_chain_swap/on_chain_swap.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/api/service/types/provider.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

class APPSwapConstants {
  static const Map<SwapServiceType, Map<ChainType, List<DefaultAPIProvider>>>
      _swapProviders = {
    SwapServiceType.chainFlip: {
      ChainType.testnet: [
        DefaultAPIProvider.chainFlipDefault(
            url: 'https://chainflip-swap-perseverance.chainflip.io/')
      ],
      ChainType.mainnet: [
        DefaultAPIProvider.chainFlipDefault(url: 'https://chainflip-swap.chainflip.io/')
      ]
    },
    SwapServiceType.thor: {
      ChainType.mainnet: [
        DefaultAPIProvider.thorDefault(url: "https://thornode.ninerealms.com/thorchain"),
      ]
    },
    SwapServiceType.maya: {
      ChainType.mainnet: [
        DefaultAPIProvider.mayaDefault(url: "https://mayanode.mayachain.info/mayachain"),
      ]
    },
    SwapServiceType.skipGo: {
      ChainType.mainnet: [
        DefaultAPIProvider.skipGoDefault(url: "https://api.skip.build"),
      ]
    },
    SwapServiceType.swapKit: {
      ChainType.mainnet: [
        DefaultAPIProvider.swapKitDefault(
            url: "https://api.swapkit.dev",
            auth: BasicProviderAuthenticated.unsafe(
                type: ProviderAuthType.header,
                key: "x-api-key",
                value: "9e1a8dce-8e2d-4cad-9d09-9430df70743c")),
      ]
    },
  };

  static DefaultAPIProvider? getProvider(SwapServiceType service,
      {ChainType chainType = ChainType.mainnet}) {
    return _swapProviders[service]?[chainType]?.firstOrNull;
  }
}
