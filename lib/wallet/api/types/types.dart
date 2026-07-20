import 'package:blockchain_utils/service/models/params.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';

enum APIProviderServices {
  electrum(value: 0, name: "Electrum API"),
  blockfrost(value: 1, name: "Blockfrost API"),
  ethereumJsonRpc(value: 2, name: "Ethereum API"),
  solanaJsonRpc(value: 3, name: "Solana API"),
  substrateJsonRpc(value: 4, name: "Substrate API"),
  tonCenter(value: 5, name: "Ton Center API"),
  tonApi(value: 6, name: "Ton API"),
  tendermint(value: 7, name: "Cosmos RPC API/Tendermint"),
  ripple(value: 8, name: "Ripple API"),
  horizon(value: 9, name: "Stellar Horizon API"),
  stellarRpc(value: 10, name: "Stellar RPC API"),
  monero(value: 11, name: "Monero Daemon API"),
  tron(value: 12, name: "Tron Node API"),
  aptos(value: 13, name: "Aptos Node API"),
  graphQl(value: 14, name: "Aptos GraphQL API"),
  sui(value: 15, name: "SUI Node API"),
  walletD(value: 16, name: "Zcash Walletd API"),
  mempool(value: 17, name: "Mempool API"),
  blockCypher(value: 18, name: "BlockCypher API"),
  chainFlip(value: 19, name: "ChainFlip API"),
  thor(value: 20, name: "Thor API"),
  maya(value: 21, name: "Maya API"),
  skipGo(value: 22, name: "Skip Go API"),
  swapKit(value: 23, name: "Swap Kit API"),
  moneroWalletRpc(value: 24, name: "Monero Wallet API"),
  cosmosRest(value: 25, name: "Cosmos Rest API"),
  cosmosGrpc(value: 26, name: "Cosmos GRPC API"),
  ;

  final int value;
  final String name;
  const APIProviderServices({required this.value, required this.name});

  static APIProviderServices fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw AppInternalError.internalError("APIProviderServices"),
    );
  }

  String? get helperUrl {
    return switch (this) {
      APIProviderServices.blockfrost => "https://blockfrost.io/",
      APIProviderServices.ethereumJsonRpc =>
        "https://ethereum.org/en/developers/docs/apis/json-rpc/",
      APIProviderServices.solanaJsonRpc => "https://solana.com/docs/rpc",
      APIProviderServices.substrateJsonRpc =>
        "https://wiki.polkadot.network/docs/maintain-endpoints",
      APIProviderServices.tonCenter => "https://toncenter.com/",
      APIProviderServices.tonApi => "https://tonapi.io/",
      APIProviderServices.tendermint => "https://docs.tendermint.com/v0.34/rpc/",
      APIProviderServices.ripple =>
        "https://xrpl.org/docs/references/http-websocket-apis",
      APIProviderServices.horizon => "https://developers.stellar.org/docs/data/horizon",
      APIProviderServices.monero => "https://docs.getmonero.org/rpc-library/monerod-rpc/",
      APIProviderServices.tron =>
        "https://developers.tron.network/docs/nodes-and-clients",
      APIProviderServices.aptos =>
        "https://aptos.dev/en/build/apis/fullnode-rest-api-reference",
      APIProviderServices.graphQl => "https://aptos.dev/en/build/indexer",
      APIProviderServices.sui => "https://docs.sui.io/sui-api-ref",
      APIProviderServices.mempool => "https://mempool.space/",
      APIProviderServices.blockCypher => "https://www.blockcypher.com/",
      APIProviderServices.moneroWalletRpc =>
        "https://www.getmonero.org/resources/developer-guides/wallet-rpc.html",
      APIProviderServices.stellarRpc =>
        "https://developers.stellar.org/docs/data/apis/rpc",
      APIProviderServices.electrum =>
        "https://electrum-protocol.readthedocs.io/en/latest/",
      APIProviderServices.walletD =>
        "https://zcash.readthedocs.io/en/latest/lightwalletd/index.html",
      _ => null
    };
  }

  List<ServiceProtocol> get supportProtocols {
    return switch (this) {
      APIProviderServices.electrum => [
          ServiceProtocol.websocket,
          ServiceProtocol.ssl,
          ServiceProtocol.tcp
        ],
      APIProviderServices.ethereumJsonRpc => [
          ServiceProtocol.http,
          ServiceProtocol.websocket
        ],
      APIProviderServices.substrateJsonRpc => [
          ServiceProtocol.http,
          ServiceProtocol.websocket
        ],
      APIProviderServices.ripple => [ServiceProtocol.http, ServiceProtocol.websocket],
      APIProviderServices.walletD || APIProviderServices.cosmosGrpc => [
          ServiceProtocol.grpc
        ],
      _ => [ServiceProtocol.http]
    };
  }

  static List<APIProviderServices> byNetwork(NetworkType network) {
    return switch (network) {
      NetworkType.bitcoinAndForked => [
          APIProviderServices.electrum,
          APIProviderServices.mempool,
          APIProviderServices.blockCypher
        ],
      NetworkType.bitcoinCash => [APIProviderServices.electrum],
      NetworkType.xrpl => [APIProviderServices.ripple],
      NetworkType.ethereum => [APIProviderServices.ethereumJsonRpc],
      NetworkType.tron => [APIProviderServices.ethereumJsonRpc, APIProviderServices.tron],
      NetworkType.solana => [APIProviderServices.solanaJsonRpc],
      NetworkType.cardano => [APIProviderServices.blockfrost],
      NetworkType.cosmos => [
          APIProviderServices.tendermint,
          APIProviderServices.cosmosRest,
          APIProviderServices.cosmosGrpc
        ],
      NetworkType.ton => [APIProviderServices.tonApi, APIProviderServices.tonCenter],
      NetworkType.substrate => [APIProviderServices.substrateJsonRpc],
      NetworkType.stellar => [
          APIProviderServices.horizon,
          APIProviderServices.stellarRpc
        ],
      NetworkType.monero => [APIProviderServices.monero],
      NetworkType.aptos => [APIProviderServices.aptos, APIProviderServices.graphQl],
      NetworkType.sui => [APIProviderServices.sui],
      NetworkType.zcash => [APIProviderServices.walletD],
    };
  }

  List<NetworkType> get supportNetworks {
    return switch (this) {
      APIProviderServices.electrum => [
          NetworkType.bitcoinAndForked,
          NetworkType.bitcoinCash,
        ],
      APIProviderServices.blockfrost => [NetworkType.cardano],
      APIProviderServices.ethereumJsonRpc => [NetworkType.ethereum, NetworkType.tron],
      APIProviderServices.solanaJsonRpc => [NetworkType.solana],
      APIProviderServices.substrateJsonRpc => [NetworkType.substrate],
      APIProviderServices.tonCenter => [NetworkType.ton],
      APIProviderServices.tonApi => [NetworkType.ton],
      APIProviderServices.tendermint ||
      APIProviderServices.cosmosGrpc ||
      APIProviderServices.cosmosRest =>
        [NetworkType.cosmos],
      APIProviderServices.ripple => [NetworkType.xrpl],
      APIProviderServices.horizon => [NetworkType.stellar],
      APIProviderServices.stellarRpc => [NetworkType.stellar],
      APIProviderServices.monero => [NetworkType.monero],
      APIProviderServices.tron => [NetworkType.tron],
      APIProviderServices.aptos => [NetworkType.aptos],
      APIProviderServices.graphQl => [NetworkType.aptos],
      APIProviderServices.sui => [NetworkType.sui],
      APIProviderServices.walletD => [NetworkType.zcash],
      APIProviderServices.mempool => [NetworkType.bitcoinAndForked],
      APIProviderServices.blockCypher => [NetworkType.bitcoinAndForked],
      _ => [],
    };
  }
}

class ServiceUrlInfo {
  final String url;
  final List<ServiceProtocol> protocols;
  final NetMode mode;
  const ServiceUrlInfo({required this.url, required this.protocols, required this.mode});
}
