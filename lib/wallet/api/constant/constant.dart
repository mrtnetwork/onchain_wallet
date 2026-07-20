import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/service/models/params.dart';
import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_wallet/network/constants/constants.dart';
import 'package:on_chain_wallet/wallet/api/api.dart';
import 'package:on_chain_wallet/wallet/api/types/types.dart';
import 'package:on_chain_wallet/wallet/models/network/network.dart';
import 'package:on_chain_wallet/wallet/models/networks/tron/models/chain_type.dart'
    show TronChainType;
import 'package:on_chain_wallet/network/net_api/api.dart';

class ProvidersConst {
  static const List<String> supportedElectrumVersion = ["1", "3"];

  static const String userAgent = "OnChain/0.8.0";
  static const String tonApiName = "Ton API";
  static const String aptosGraphQlName = "Aptos GraphQL";
  static ({DefaultAPIProvider solidity, DefaultAPIProvider node})
      getOrDefaultTronDefaultProvider(
    TronChainType chain,
    List<DefaultAPIProvider> providers,
  ) {
    final solidity = providers.firstWhere(
      (e) => e.service == APIProviderServices.ethereumJsonRpc,
      orElse: () {
        return _providers[chain.id]!
            .firstWhere((e) => e.service == APIProviderServices.ethereumJsonRpc);
      },
    );
    final node = providers.firstWhere(
      (e) => e.service == APIProviderServices.tron,
      orElse: () {
        return _providers[chain.id]!
            .firstWhere((e) => e.service == APIProviderServices.tron);
      },
    );
    return (solidity: solidity, node: node);
  }

  static const String defaultidentifierName = "default-";
  static const Map<int, List<DefaultAPIProvider>> _providers = {
    0: <DefaultAPIProvider>[
      DefaultAPIProvider.defaultMempool(
        url: BtcApiConst.mempoolMainBaseURL,
      ),
      DefaultAPIProvider.defaultBlockCypher(
        url: BtcApiConst.blockCypherMainBaseURL,
      ),
      DefaultAPIProvider.defaultElectrum(
          url: "142.93.6.38:50002", protocol: ServiceProtocol.ssl),
      DefaultAPIProvider.defaultElectrum(
          url: "wss://bitcoin.aranguren.org:50004", protocol: ServiceProtocol.websocket),
      DefaultAPIProvider.defaultElectrum(
          url: "104.248.139.211:50002", protocol: ServiceProtocol.ssl),
    ],
    1: <DefaultAPIProvider>[
      DefaultAPIProvider.defaultElectrum(
          url: "wss://testnet.aranguren.org:51004", protocol: ServiceProtocol.websocket),
      DefaultAPIProvider.defaultElectrum(
          url: "testnet.aranguren.org:51002", protocol: ServiceProtocol.ssl),
      DefaultAPIProvider.defaultMempool(
        url: BtcApiConst.mempoolBaseURL,
      ),
    ],
    5: <DefaultAPIProvider>[
      DefaultAPIProvider.defaultElectrum(
          url: "testnet4-electrumx.wakiyamap.dev:51002", protocol: ServiceProtocol.ssl),
      DefaultAPIProvider.defaultElectrum(
          url: "testnet4-electrumx.wakiyamap.dev:51001", protocol: ServiceProtocol.tcp),
      DefaultAPIProvider.defaultElectrum(
          url: "wss://blackie.c3-soft.com:57012", protocol: ServiceProtocol.websocket),
      DefaultAPIProvider.defaultMempool(
        url: BtcApiConst.mempoolTestnet4BaseURL,
      ),
    ],
    2: <DefaultAPIProvider>[
      DefaultAPIProvider.defaultBlockCypher(
        url: BtcApiConst.blockCypherLitecoinBaseUri,
      ),
      DefaultAPIProvider.defaultElectrum(
          url: "wss://electrum.qortal.link:50004", protocol: ServiceProtocol.websocket),
      DefaultAPIProvider.defaultElectrum(
          url: "wss://46.101.3.154:50004", protocol: ServiceProtocol.websocket),
      DefaultAPIProvider.defaultElectrum(
          url: "46.101.3.154:50002", protocol: ServiceProtocol.ssl),
      DefaultAPIProvider.defaultElectrum(
          url: "backup.electrum-ltc.org:443", protocol: ServiceProtocol.ssl),
    ],
    7: <DefaultAPIProvider>[
      DefaultAPIProvider.defaultElectrum(
          url: "electrum-ltc.bysh.me:51002", protocol: ServiceProtocol.ssl),
      DefaultAPIProvider.defaultElectrum(
          url: "electrum.ltc.xurious.com:51002", protocol: ServiceProtocol.ssl),
    ],
    3: <DefaultAPIProvider>[
      DefaultAPIProvider.defaultElectrum(
          url: "electrum.qortal.link:54002", protocol: ServiceProtocol.ssl),
      DefaultAPIProvider.defaultElectrum(
          url: "wss://electrum.qortal.link:54004", protocol: ServiceProtocol.websocket),
      DefaultAPIProvider.defaultBlockCypher(
        url: BtcApiConst.blockCypherDogeBaseUri,
      ),
    ],
    8: <DefaultAPIProvider>[],
    9: <DefaultAPIProvider>[
      DefaultAPIProvider.defaultElectrum(
          url: "electrumx.bitcoinsv.io:50002", protocol: ServiceProtocol.ssl),
    ],
    4: <DefaultAPIProvider>[
      DefaultAPIProvider.defaultBlockCypher(
        url: BtcApiConst.blockCypherDashBaseUri,
      ),
    ],
    10: <DefaultAPIProvider>[
      DefaultAPIProvider.defaultElectrum(
          url: "wss://electrum.imaginary.cash:50004",
          protocol: ServiceProtocol.websocket),
      DefaultAPIProvider.defaultElectrum(
          url: "electrum.imaginary.cash:50002", protocol: ServiceProtocol.ssl),

      ///
      DefaultAPIProvider.defaultElectrum(
          url: "wss://bch.loping.net:50004", protocol: ServiceProtocol.websocket),
      DefaultAPIProvider.defaultElectrum(
          url: "bch.loping.net:50002", protocol: ServiceProtocol.ssl),
    ],
    11: <DefaultAPIProvider>[
      DefaultAPIProvider.defaultElectrum(
          url: "ws://cbch.loping.net:62103", protocol: ServiceProtocol.websocket),
      DefaultAPIProvider.defaultElectrum(
          url: "ws://cbch.loping.net:62104", protocol: ServiceProtocol.websocket),
      DefaultAPIProvider.defaultElectrum(
          url: "cbch.loping.net:62102", protocol: ServiceProtocol.ssl),
      DefaultAPIProvider.defaultElectrum(
          url: "chipnet.imaginary.cash:50002", protocol: ServiceProtocol.ssl)
    ],
    12: <DefaultAPIProvider>[
      DefaultAPIProvider.defaultElectrum(
          url: "electrum.pepeblocks.com:50002", protocol: ServiceProtocol.ssl),
      DefaultAPIProvider.defaultElectrum(
          url: "electrum.pepeblocks.com:50001", protocol: ServiceProtocol.tcp),
      DefaultAPIProvider.defaultElectrum(
          url: "wss://electrum.pepeblocks.com:50004",
          protocol: ServiceProtocol.websocket),
      DefaultAPIProvider.defaultElectrum(
          url: "electrum.pepelum.site:50002", protocol: ServiceProtocol.ssl),
      DefaultAPIProvider.defaultElectrum(
          url: "electrum.pepelum.site:50001", protocol: ServiceProtocol.tcp),
      DefaultAPIProvider.defaultElectrum(
          url: "wss://electrum.pepelum.site:50004", protocol: ServiceProtocol.websocket),
      DefaultAPIProvider.defaultElectrum(
          url: "electrum.pepe.tips:50002", protocol: ServiceProtocol.ssl),
      DefaultAPIProvider.defaultElectrum(
          url: "electrum.pepe.tips:50001", protocol: ServiceProtocol.tcp),
      DefaultAPIProvider.defaultElectrum(
          url: "wss://electrum.pepe.tips:50004", protocol: ServiceProtocol.websocket)
    ],
    30: <DefaultAPIProvider>[
      DefaultAPIProvider.defaultRipple(
        url: "https://xrplcluster.com/",
        protocol: ServiceProtocol.http,
      ),
      DefaultAPIProvider.defaultRipple(
        url: "wss://xrplcluster.com/",
        protocol: ServiceProtocol.websocket,
      ),
    ],
    31: <DefaultAPIProvider>[
      DefaultAPIProvider.defaultRipple(
        url: "https://s.altnet.rippletest.net:51234/",
        protocol: ServiceProtocol.http,
      ),
      DefaultAPIProvider.defaultRipple(
        url: "wss://s.altnet.rippletest.net:51233",
        protocol: ServiceProtocol.websocket,
      ),
    ],
    32: <DefaultAPIProvider>[
      DefaultAPIProvider.defaultRipple(
        url: "https://s.devnet.rippletest.net:51234/",
        protocol: ServiceProtocol.http,
      ),
      DefaultAPIProvider.defaultRipple(
        url: "wss://s.devnet.rippletest.net:51233",
        protocol: ServiceProtocol.websocket,
      ),
    ],
    33: <DefaultAPIProvider>[
      DefaultAPIProvider.solanaDefault(
        url: "https://api.mainnet-beta.solana.com",
      )
    ],
    34: <DefaultAPIProvider>[
      DefaultAPIProvider.solanaDefault(
        url: "https://api.testnet.solana.com",
      )
    ],
    35: <DefaultAPIProvider>[
      DefaultAPIProvider.solanaDefault(
        url: "https://api.devnet.solana.com",
      )
    ],
    50: <DefaultAPIProvider>[
      DefaultAPIProvider.blockfrostDefault(
        url: "https://cardano-mainnet.blockfrost.io/api/v0/",
        auth: BasicProviderAuthenticated.unsafe(
            type: ProviderAuthType.header,
            key: "project_id",
            value: "mainnetolePdeWQLX8TrfG9V6RVaAshQi4pWzbU"),
      )
    ],
    51: <DefaultAPIProvider>[
      DefaultAPIProvider.blockfrostDefault(
          url: "https://cardano-preprod.blockfrost.io/api/v0/",
          auth: BasicProviderAuthenticated.unsafe(
              type: ProviderAuthType.header,
              key: "project_id",
              value: "preprodMVwzqm4PuBDBSfEULoMzoj5QZcy5o3z5"))
    ],
    100: <DefaultAPIProvider>[
      DefaultAPIProvider.ethereumDefault(
          url: "wss://ethereum.publicnode.com", protocol: ServiceProtocol.websocket),
      DefaultAPIProvider.ethereumDefault(
          url: "https://ethereum.publicnode.com", protocol: ServiceProtocol.http),
    ],
    101: <DefaultAPIProvider>[
      DefaultAPIProvider.ethereumDefault(
          url: "https://ethereum-sepolia.publicnode.com", protocol: ServiceProtocol.http),
    ],
    102: <DefaultAPIProvider>[
      DefaultAPIProvider.ethereumDefault(
          url: "https://polygon-bor.publicnode.com", protocol: ServiceProtocol.http)
    ],
    103: <DefaultAPIProvider>[
      DefaultAPIProvider.ethereumDefault(
          url: "https://polygon-mumbai-bor.publicnode.com",
          protocol: ServiceProtocol.http),
    ],
    104: <DefaultAPIProvider>[
      DefaultAPIProvider.ethereumDefault(
          url: "https://bsc.publicnode.com", protocol: ServiceProtocol.http),
    ],
    105: <DefaultAPIProvider>[
      DefaultAPIProvider.ethereumDefault(
          url: "https://bsc-testnet.publicnode.com", protocol: ServiceProtocol.http),
    ],
    200: <DefaultAPIProvider>[
      DefaultAPIProvider.tendermintDefault(
        url: "https://cosmos-rpc.publicnode.com:443",
      ),
    ],
    206: <DefaultAPIProvider>[
      DefaultAPIProvider.tendermintDefault(
        url: "https://rpc.testnet.osmosis.zone/",
      ),
    ],
    207: <DefaultAPIProvider>[
      DefaultAPIProvider.tendermintDefault(
        url: "https://rpc.osmosis.zone/",
      ),
    ],
    201: <DefaultAPIProvider>[
      DefaultAPIProvider.tendermintDefault(
        url: "https://rpc.provider-sentry-02.ics-testnet.polypore.xyz",
      ),
    ],
    202: <DefaultAPIProvider>[
      DefaultAPIProvider.tendermintDefault(
        url: "https://tendermint.mayachain.info",
      ),
    ],
    203: <DefaultAPIProvider>[
      DefaultAPIProvider.tendermintDefault(
        url: "https://rpc.thorchain.liquify.com/",
      ),
    ],
    204: <DefaultAPIProvider>[
      DefaultAPIProvider.tendermintDefault(
        url: "https://kujira-testnet-rpc.polkachu.com/",
      ),
    ],
    205: <DefaultAPIProvider>[
      DefaultAPIProvider.tendermintDefault(
        url: "https://rpc.cosmos.directory/kujira",
      ),
    ],
    300: <DefaultAPIProvider>[
      DefaultAPIProvider.tonDefault(
          url: "https://tonapi.io",
          service: APIProviderServices.tonApi,
          requestCooldown: NetworkConst.hightRequestCooldown),
      DefaultAPIProvider.tonDefault(
          url: "https://toncenter.com",
          service: APIProviderServices.tonCenter,
          auth: BasicProviderAuthenticated.unsafe(
              type: ProviderAuthType.header,
              key: "X-API-Key",
              value: "cc8597229bb486a012f29743732b56c2331aff7f87c3d2cb84d456a04213b3ac")),
    ],
    301: <DefaultAPIProvider>[
      DefaultAPIProvider.tonDefault(
          url: "https://testnet.tonapi.io",
          service: APIProviderServices.tonApi,
          requestCooldown: NetworkConst.hightRequestCooldown),
      DefaultAPIProvider.tonDefault(
          url: "https://testnet.toncenter.com",
          service: APIProviderServices.tonCenter,
          auth: BasicProviderAuthenticated.unsafe(
              type: ProviderAuthType.header,
              key: "X-API-Key",
              value: "d3800f756738ac7b39599914b8a84465960ff869f555c2317664c9a62529baf3")),
    ],
    400: <DefaultAPIProvider>[
      DefaultAPIProvider.substateDefault(
          protocol: ServiceProtocol.http, url: "https://rpc.polkadot.io"),
    ],
    401: <DefaultAPIProvider>[
      DefaultAPIProvider.substateDefault(
          protocol: ServiceProtocol.websocket,
          url: "wss://polkadot-asset-hub-rpc.polkadot.io"),
    ],
    402: <DefaultAPIProvider>[
      DefaultAPIProvider.substateDefault(
          protocol: ServiceProtocol.websocket,
          url: "wss://polkadot-bridge-hub-rpc.polkadot.io"),
    ],

    ///
    450: <DefaultAPIProvider>[
      DefaultAPIProvider.substateDefault(
          protocol: ServiceProtocol.http, url: "https://kusama-rpc.polkadot.io"),
    ],
    451: <DefaultAPIProvider>[
      DefaultAPIProvider.substateDefault(
          protocol: ServiceProtocol.websocket, url: "wss://westend-rpc.polkadot.io"),
      DefaultAPIProvider.substateDefault(
          protocol: ServiceProtocol.http, url: "https://westend-rpc.polkadot.io"),
    ],
    452: <DefaultAPIProvider>[
      DefaultAPIProvider.substateDefault(
          protocol: ServiceProtocol.websocket, url: "wss://westmint-rpc.dwellir.com:443"),
    ],
    453: <DefaultAPIProvider>[
      DefaultAPIProvider.substateDefault(
          protocol: ServiceProtocol.websocket,
          url: "wss://kusama-asset-hub-rpc.polkadot.io"),
    ],
    454: <DefaultAPIProvider>[
      DefaultAPIProvider.substateDefault(
          protocol: ServiceProtocol.websocket,
          url: "wss://kusama-bridge-hub-rpc.polkadot.io"),
    ],
    455: <DefaultAPIProvider>[
      DefaultAPIProvider.substateDefault(
          protocol: ServiceProtocol.websocket,
          url: "wss://westend-bridge-hub-rpc.polkadot.io:443"),
    ],
    461: <DefaultAPIProvider>[
      DefaultAPIProvider.substateDefault(
          protocol: ServiceProtocol.websocket, url: "wss://moonbase-rpc.dwellir.com"),
      DefaultAPIProvider.substateDefault(
          protocol: ServiceProtocol.websocket,
          url: "wss://moonbeam-alpha.api.onfinality.io:443/public-ws"),
    ],
    460: <DefaultAPIProvider>[
      DefaultAPIProvider.substateDefault(
          protocol: ServiceProtocol.websocket, url: "wss://moonbeam-rpc.dwellir.com"),
      DefaultAPIProvider.substateDefault(
          protocol: ServiceProtocol.websocket,
          url: "wss://moonbeam.api.onfinality.io/public"),
    ],
    462: <DefaultAPIProvider>[
      DefaultAPIProvider.substateDefault(
          protocol: ServiceProtocol.websocket, url: "wss://moonriver-rpc.dwellir.com"),
      DefaultAPIProvider.substateDefault(
          protocol: ServiceProtocol.websocket,
          url: "wss://moonriver.api.onfinality.io/public"),
    ],
    463: <DefaultAPIProvider>[
      DefaultAPIProvider.substateDefault(
          protocol: ServiceProtocol.websocket, url: "wss://astar-rpc.dwellir.com"),
      DefaultAPIProvider.substateDefault(
          protocol: ServiceProtocol.websocket,
          url: "wss://astar.api.onfinality.io/public"),
    ],
    464: <DefaultAPIProvider>[
      DefaultAPIProvider.substateDefault(
          protocol: ServiceProtocol.websocket, url: "wss://centrifuge-rpc.dwellir.com"),
    ],
    465: <DefaultAPIProvider>[
      DefaultAPIProvider.substateDefault(
          protocol: ServiceProtocol.websocket, url: "wss://acala-rpc-0.aca-api.network"),
    ],
    466: <DefaultAPIProvider>[
      DefaultAPIProvider.substateDefault(
          protocol: ServiceProtocol.websocket, url: "wss://rpc-pdot.chainflip.io:443"),
    ],
    467: <DefaultAPIProvider>[
      DefaultAPIProvider.substateDefault(
          protocol: ServiceProtocol.websocket,
          url: "wss://assethub.perseverance.chainflip.io"),
    ],
    468: <DefaultAPIProvider>[
      DefaultAPIProvider.substateDefault(
          protocol: ServiceProtocol.websocket, url: "wss://hydration.ibp.network"),
    ],
    469: <DefaultAPIProvider>[
      DefaultAPIProvider.substateDefault(
          protocol: ServiceProtocol.websocket,
          url: "wss://bifrost-polkadot.dotters.network"),
    ],

    /// wss%3A%2F%2Ffullnode.centrifuge.io
    600: <DefaultAPIProvider>[
      DefaultAPIProvider.stellarDefault(
        url: "https://horizon.stellar.org",
        service: APIProviderServices.horizon,
      ),
      DefaultAPIProvider.stellarDefault(
          service: APIProviderServices.stellarRpc,
          url: "https://soroban-rpc.mainnet.stellar.gateway.fm"),
    ],
    601: <DefaultAPIProvider>[
      DefaultAPIProvider.stellarDefault(
        url: "https://horizon-testnet.stellar.org",
        service: APIProviderServices.horizon,
      ),
      DefaultAPIProvider.stellarDefault(
          service: APIProviderServices.stellarRpc,
          url: "https://soroban-testnet.stellar.org"),
    ],
    700: <DefaultAPIProvider>[
      DefaultAPIProvider.moneroDefault(url: "http://node.xmr.rocks:18089"),
      DefaultAPIProvider.moneroDefault(url: "http://node.tools.rino.io:18081"),
    ],
    701: <DefaultAPIProvider>[
      DefaultAPIProvider.moneroDefault(url: "http://3.10.182.182:38081"),
      DefaultAPIProvider.moneroDefault(url: "http://stagenet.tools.rino.io:38081"),
      DefaultAPIProvider.moneroDefault(url: "http://singapore.node.xmr.pm:38081"),
      DefaultAPIProvider.moneroDefault(url: "https://stagenet.xmr.ditatompel.com"),
    ],
    702: <DefaultAPIProvider>[
      DefaultAPIProvider.moneroDefault(url: "http://127.0.0.1:18081"),
    ],
    1001: <DefaultAPIProvider>[
      DefaultAPIProvider.tronDefault(
        url: "https://api.trongrid.io",
      ),
      DefaultAPIProvider.ethereumDefault(
          url: "https://api.trongrid.io/jsonrpc", protocol: ServiceProtocol.http),
    ],
    1002: <DefaultAPIProvider>[
      DefaultAPIProvider.tronDefault(
        url: "https://api.shasta.trongrid.io",
      ),
      DefaultAPIProvider.ethereumDefault(
          url: "https://api.shasta.trongrid.io/jsonrpc", protocol: ServiceProtocol.http),
    ],
    1003: <DefaultAPIProvider>[
      DefaultAPIProvider.tronDefault(
        url: "https://nile.trongrid.io",
      ),
      DefaultAPIProvider.ethereumDefault(
          url: "https://nile.trongrid.io/jsonrpc", protocol: ServiceProtocol.http),
    ],
    106: <DefaultAPIProvider>[
      DefaultAPIProvider.ethereumDefault(
          url: "https://api.avax.network/ext/bc/C/rpc", protocol: ServiceProtocol.http),
    ],
    107: <DefaultAPIProvider>[
      DefaultAPIProvider.ethereumDefault(
          url: "wss://arbitrum-one-rpc.publicnode.com",
          protocol: ServiceProtocol.websocket),
      DefaultAPIProvider.ethereumDefault(
          url: "https://arb1.arbitrum.io/rpc", protocol: ServiceProtocol.http),
      DefaultAPIProvider.ethereumDefault(
          url: "https://arbitrum-one-rpc.publicnode.com", protocol: ServiceProtocol.http),
    ],
    108: <DefaultAPIProvider>[
      DefaultAPIProvider.ethereumDefault(
          url: "wss://base-rpc.publicnode.com", protocol: ServiceProtocol.websocket),
      DefaultAPIProvider.ethereumDefault(
          url: "https://base-rpc.publicnode.com", protocol: ServiceProtocol.http),
      DefaultAPIProvider.ethereumDefault(
          url: "https://mainnet.base.org", protocol: ServiceProtocol.http)
    ],
    109: <DefaultAPIProvider>[
      DefaultAPIProvider.ethereumDefault(
          url: "https://mainnet.optimism.io", protocol: ServiceProtocol.http),
      DefaultAPIProvider.ethereumDefault(
          url: "https://optimism-rpc.publicnode.com", protocol: ServiceProtocol.http)
    ],
    110: <DefaultAPIProvider>[
      DefaultAPIProvider.ethereumDefault(
          url: "wss://arbitrum-sepolia-rpc.publicnode.com",
          protocol: ServiceProtocol.websocket),
      DefaultAPIProvider.ethereumDefault(
          url: "https://arbitrum-sepolia-rpc.publicnode.com",
          protocol: ServiceProtocol.http),
    ],
    111: <DefaultAPIProvider>[
      DefaultAPIProvider.ethereumDefault(
          url: "wss://wss.api.moonbeam.network", protocol: ServiceProtocol.websocket),
      DefaultAPIProvider.ethereumDefault(
          url: "https://moonbeam-rpc.publicnode.com", protocol: ServiceProtocol.http),
    ],
    112: <DefaultAPIProvider>[
      DefaultAPIProvider.ethereumDefault(
          url: "wss://moonriver-rpc.publicnode.com", protocol: ServiceProtocol.websocket),
      DefaultAPIProvider.ethereumDefault(
          url: "https://rpc.api.moonriver.moonbeam.network",
          protocol: ServiceProtocol.http),
    ],
    800: <DefaultAPIProvider>[
      DefaultAPIProvider.suiDefault(url: "https://fullnode.mainnet.sui.io:443"),
      DefaultAPIProvider.suiDefault(url: "https://sui-rpc.publicnode.com")
    ],
    801: <DefaultAPIProvider>[
      DefaultAPIProvider.suiDefault(url: "https://fullnode.devnet.sui.io:443")
    ],
    802: <DefaultAPIProvider>[
      DefaultAPIProvider.suiDefault(url: "https://fullnode.testnet.sui.io:443")
    ],
    810: <DefaultAPIProvider>[
      DefaultAPIProvider.aptosDefault(
          url: "https://api.mainnet.aptoslabs.com/v1/",
          service: APIProviderServices.aptos),
      DefaultAPIProvider.aptosDefault(
          url: "https://api.mainnet.aptoslabs.com/v1/graphql",
          service: APIProviderServices.graphQl),
    ],
    811: <DefaultAPIProvider>[
      DefaultAPIProvider.aptosDefault(
          url: "https://api.testnet.aptoslabs.com/v1/",
          service: APIProviderServices.aptos),
      DefaultAPIProvider.aptosDefault(
          url: "https://api.testnet.aptoslabs.com/v1/graphql",
          service: APIProviderServices.graphQl),
    ],
    812: <DefaultAPIProvider>[
      DefaultAPIProvider.aptosDefault(
          url: "https://api.devnet.aptoslabs.com/v1/",
          service: APIProviderServices.aptos),
      DefaultAPIProvider.aptosDefault(
          url: "https://api.devnet.aptoslabs.com/v1/graphql",
          service: APIProviderServices.graphQl),
    ],
    900: <DefaultAPIProvider>[
      DefaultAPIProvider.zcashDefault(url: "https://zec.rocks"),
    ],
    901: <DefaultAPIProvider>[
      DefaultAPIProvider.zcashDefault(url: "https://testnet.zec.rocks"),
    ],
    902: <DefaultAPIProvider>[
      DefaultAPIProvider.zcashDefault(url: "http://localhost:9067"),
    ]
  };

  static List<T> getDefaultProvider<T extends DefaultAPIProvider>({
    required WalletNetwork network,
    required AppPlatform platform,
  }) {
    final providers = _providers[network.value] ?? [];
    return providers
        .whereType<T>()
        .where((element) => element.protocol.platforms.contains(platform))
        .toList();
  }
}
