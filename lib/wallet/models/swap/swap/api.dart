import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:on_chain_swap/on_chain_swap.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/api/provider/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/services/default.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/network/params/solana.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';
import 'constants.dart';
import 'models.dart';

class AppSwapServiceApi extends SwapServiceApi {
  AppSwapServiceApi(this.networks, super.services);

  static Future<AppSwapServiceApi> loadApi(
      BaseSwapServiceApiParams params, List<WalletNetwork> networks) async {
    Map<SwapServiceType, SwapService> services = {};
    for (final s in params.services) {
      final SwapService? service = switch (s) {
        SwapServiceType.chainFlip => await params.loadChainFlipService(),
        SwapServiceType.maya => await params.loadMayaService(),
        SwapServiceType.thor => await params.loadThorService(),
        SwapServiceType.skipGo => await params.loadSkipGoService(),
        SwapServiceType.swapKit => await params.loadSwapKitService(),
      };
      if (service == null) continue;
      services[s] = service;
    }
    return AppSwapServiceApi(networks, services);
  }

  final List<WalletNetwork> networks;
  final Map<SwapNetwork, WalletNetwork?> _networks = {};
  Map<WalletNetwork, Set<APPSwapAssets>> _allAssets = {};
  final Map<SwapServiceType, Set<APPSwapAssets>> _localAssets = {};

  NetworkType _findNetowrkType(SwapNetwork network) {
    switch (network.type) {
      case SwapChainType.solana:
        return NetworkType.solana;
      case SwapChainType.polkadot:
        return NetworkType.substrate;
      case SwapChainType.ethereum:
        return NetworkType.ethereum;
      case SwapChainType.bitcoin:
        final bitcoinNetwork = network.cast<SwapBitcoinNetwork>();
        if (bitcoinNetwork.chain == BitcoinCashNetwork.mainnet ||
            bitcoinNetwork.chain == BitcoinCashNetwork.testnet) {
          return NetworkType.bitcoinCash;
        }
        return NetworkType.bitcoinAndForked;
      case SwapChainType.cosmos:
        return NetworkType.cosmos;
      case SwapChainType.tron:
        return NetworkType.tron;
      case SwapChainType.xrp:
        return NetworkType.xrpl;
      case SwapChainType.ada:
        return NetworkType.cardano;
      case SwapChainType.zcash:
        return NetworkType.zcash;
    }
  }

  WalletNetwork? _findNetwork(SwapNetwork network) {
    if (_networks.containsKey(network)) return _networks[network];
    final type = _findNetowrkType(network);
    WalletNetwork? findNetwork() {
      switch (type) {
        case NetworkType.ethereum:
          final ethNetwork = network.cast<SwapEthereumNetwork>();
          return networks
              .whereType<WalletEthereumNetwork>()
              .firstWhereNullable((e) => e.coinParam.chainId == ethNetwork.chainId);
        case NetworkType.cosmos:
          return null;

        case NetworkType.bitcoinAndForked:
          final btcNetwork = network.cast<SwapBitcoinNetwork>();
          return networks.whereType<WalletBitcoinNetwork>().firstWhereNullable((e) =>
              e.coinParam.transacationNetwork == btcNetwork.chain &&
              e.coinParam.chainType == btcNetwork.chainType);

        case NetworkType.solana:
          final solanaNetwork = network.cast<SwapSolanaNetwork>();
          return networks.whereType<WalletSolanaNetwork>().firstWhereNullable((e) {
            if (solanaNetwork.chainType.isMainnet) {
              return e.coinParam.type == SolanaNetworkType.mainnet;
            }
            return e.coinParam.type == SolanaNetworkType.devnet;
          });
        case NetworkType.substrate:
          final genesis = network.cast<SwapSubstrateNetwork>().genesis;
          final substrateChains = networks.whereType<WalletSubstrateNetwork>();
          return substrateChains.firstWhereNullable((e) {
            return StringUtils.hexEqual(genesis, e.genesisBlock);
          });
        case NetworkType.tron:
          final genesis = network.cast<SwapTronNetwork>().genesis;
          final substrateChains = networks.whereType<WalletTronNetwork>();
          return substrateChains.firstWhereNullable((e) {
            return StringUtils.hexEqual(genesis, e.genesisBlock);
          });

        case NetworkType.xrpl:
          final networkId = network.cast<SwapXRPNetwork>().networkId;

          final substrateChains = networks.whereType<WalletXRPNetwork>();
          return substrateChains.firstWhereNullable((e) {
            return networkId == e.coinParam.networkId;
          });
        case NetworkType.zcash:
          final nu6BlockHash = network.cast<SwapZcashNetwork>().nu6BlockHash;
          final substrateChains = networks.whereType<WalletZcashNetwork>();
          return substrateChains.firstWhereNullable((e) {
            return e.getNu6BlockHash() == nu6BlockHash;
          });
        case NetworkType.cardano:
          return null;
        default:
          return null;
      }
    }

    _networks[network] = findNetwork();
    return _networks[network];
  }

  Future<Map<WalletNetwork, Set<APPSwapAssets>>> getAppSourceAssets(
      {bool skipServiceWhenFailed = true}) async {
    final services = this.services;
    List<APPSwapAssets> allAssets = [];
    for (final i in services.entries) {
      try {
        final assets = await i.value.loadAssets();
        final supportAssets = assets.map((e) {
          final network = _findNetwork(e.network);
          if (network == null) return null;
          return APPSwapAssets.fromAsset(asset: e, network: network);
        }).whereType<APPSwapAssets>();
        allAssets.addAll(supportAssets);
        _localAssets[i.key] = supportAssets.toImutableSet;
      } catch (_) {
        if (skipServiceWhenFailed) continue;
        rethrow;
      }
    }
    final Map<WalletNetwork, Set<APPSwapAssets>> networkAssets = {};
    for (final i in allAssets) {
      networkAssets[i.network] ??= {};
      networkAssets[i.network]?.add(i);
    }
    _allAssets = networkAssets.map((k, v) => MapEntry(k, APPSwapUtils.sortAssets(v)));
    return _allAssets.immutable;
  }

  Map<WalletNetwork, Set<APPSwapAssets>> getAppDestAssets(BaseSwapAsset asset) {
    final Map<WalletNetwork, Set<APPSwapAssets>> networkAssets = {};
    final services = this.services;
    for (final i in services.values) {
      final assets = i.getDestAssets(asset);
      for (final entry in assets.entries) {
        final network = _findNetwork(entry.key);
        if (network == null) continue;
        final asset = _allAssets[network]!.where((e) => entry.value.contains(e.asset));
        networkAssets.update(network, (e) => {...e, ...asset},
            ifAbsent: () => asset.toSet());
      }
    }
    return networkAssets.map((k, v) => MapEntry(k, APPSwapUtils.sortAssets(v)));
  }

  Future<List<RouteOrError>> findAppRoute<ASSET extends BaseSwapAsset>({
    required APPSwapAssets sourceAsset,
    required APPSwapAssets destinationAsset,
    required String amountIn,
    String? sourceAddress,
    String? destinationAddress,
  }) async {
    List<RouteOrError> routes = [];
    for (final i in _localAssets.entries) {
      final sAsset = i.value.firstWhereNullable((e) => e == sourceAsset);
      final destAsset = i.value.firstWhereNullable((e) => e == destinationAsset);
      final service = services[i.key];
      if (sAsset == null || destAsset == null || service == null) {
        continue;
      }
      final params = createQuoteParams(
          sourceAsset: sAsset.asset,
          destAsset: destAsset.asset,
          amountIn: amountIn,
          sourceAddress: sourceAddress,
          destinationAddress: destinationAddress);
      try {
        final serviceRoutes = await service.createRoutes(params);
        routes.addAll(serviceRoutes
            .map((e) => RouteOrError.route(provider: sAsset.asset.provider, route: e)));
      } catch (err) {
        routes.add(RouteOrError.error(provider: sAsset.asset.provider, error: err));
      }
    }
    return routes;
  }
}

class DefaultSwapServiceApiParams extends BaseSwapServiceApiParams {
  final ChainType chainType;
  final INetApi netApi;
  final List<SwapKitSwapServiceProvider>? swapKitServiceProviders;

  DefaultSwapServiceApiParams({
    required this.netApi,
    required this.chainType,
    required List<SwapServiceType> services,
    List<SwapKitSwapServiceProvider>? swapKitServiceProviders,
  })  : swapKitServiceProviders = swapKitServiceProviders?.immutable,
        super(services);

  @override
  Future<MayaSwapService?> loadMayaService() async {
    final provider =
        APPSwapConstants.getProvider(SwapServiceType.maya, chainType: chainType);
    if (provider == null) return null;

    return MayaSwapService(
        provider: DefaultProvider(ThorNodeProvider(
            MultiChainServiceClient.fromProvider(provider: provider, netApi: netApi))));
  }

  @override
  Future<SkipGoSwapService?> loadSkipGoService() async {
    final provider =
        APPSwapConstants.getProvider(SwapServiceType.skipGo, chainType: chainType);
    if (provider == null) return null;
    return SkipGoSwapService(
        provider: DefaultProvider(SkipGoApiProvider(
            MultiChainServiceClient.fromProvider(provider: provider, netApi: netApi))));
  }

  @override
  Future<SwapKitSwapService?> loadSwapKitService() async {
    final provider =
        APPSwapConstants.getProvider(SwapServiceType.swapKit, chainType: chainType);
    if (provider == null) return null;
    return SwapKitSwapService(
        providers: swapKitServiceProviders ?? [],
        provider: DefaultProvider(SwapKitProvider(
            MultiChainServiceClient.fromProvider(provider: provider, netApi: netApi))));
  }

  @override
  Future<ThorSwapService?> loadThorService() async {
    final provider =
        APPSwapConstants.getProvider(SwapServiceType.thor, chainType: chainType);
    if (provider == null) return null;
    return ThorSwapService(
        provider: DefaultProvider(ThorNodeProvider(
            MultiChainServiceClient.fromProvider(provider: provider, netApi: netApi))));
  }

  @override
  Future<CfSwapService?> loadChainFlipService() async {
    final provider =
        APPSwapConstants.getProvider(SwapServiceType.chainFlip, chainType: chainType);
    if (provider == null) return null;
    return CfSwapService(
        chainType: chainType,
        provider: DefaultProvider(CfProvider(
            MultiChainServiceClient.fromProvider(provider: provider, netApi: netApi))));
  }
}
