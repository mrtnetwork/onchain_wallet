import 'dart:async';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:cosmos_sdk/proto_messages/cosmos/bank/v1beta1/src/query.dart';
import 'package:cosmos_sdk/proto_messages/cosmos/base/v1beta1/src/coin.dart';
import 'package:cosmos_sdk/proto_messages/ibc/core/channel/v1/src/channel.dart';
import 'package:cosmos_sdk/proto_messages/ibc/core/channel/v1/src/query.dart';
import 'package:cosmos_sdk/proto_messages/ibc/core/client/v1/src/query.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_swap/on_chain_swap.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/api/client/core/client.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/cosmos/models/models.dart';
import 'package:on_chain_wallet/wallet/api/provider/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/types/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/services/default.dart';
import 'package:on_chain_wallet/wallet/api/service/types/network_providers.dart';
import 'package:on_chain_wallet/wallet/api/types/types.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/constant/networks/cosmos.dart';
import 'package:on_chain_wallet/wallet/models/network/network.dart';
import 'package:on_chain_wallet/wallet/models/networks/cosmos/cosmos.dart';
import 'package:on_chain_wallet/wallet/models/token/token.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/cosmos.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

mixin CosmosCustomRequest {
  INetApi get netApi;
  static final _lock = SafeAtomicLock();

  static final Map<ChainType, List<CCRChainData>> _chains = {
    ChainType.mainnet: [],
    ChainType.testnet: [],
  };
  static List<PingPubChain>? _testnetChains;
  static List<PingPubChain>? _mainnetChains;

  static List<CosmosDirectoryChain>? _testnetCosmosDirectoryChains;
  static List<CosmosDirectoryChain>? _mainnetCosmosDirectoryChains;

  static CCRChainData? _getLocalChain(
      {required ChainType chainType, required String name}) {
    return _chains[chainType]?.firstWhereOrNull((e) => e.chain.chainName == name);
  }

  Future<IResult<List<PingPubChain>>> _getChains(String uri) async {
    final r = await netApi.httpGet<List<Map<String, dynamic>>>(uri,
        responseType: StreamEncoding.listOfMap);
    return r.mapCatchAsync((e) => CCRUtilities.readChainDirectories(e));
  }

  Future<IResult<List<CosmosDirectoryChain>>> _getCosmsmosChains(String uri) async {
    final r =
        await netApi.httpGet<Map<String, dynamic>>(uri, responseType: StreamEncoding.map);
    return r.mapCatchAsync((e) {
      final List<Map<String, dynamic>> data =
          e.valueEnsureAsList<Map<String, dynamic>>("chains");
      return data.map((e) => CosmosDirectoryChain.fromJson(e)).toList();
    });
  }

  Future<IResult<List<CosmosDirectoryChain>>> _getCosmosDirectoryChains(
      {ChainType chain = ChainType.mainnet}) async {
    switch (chain) {
      case ChainType.mainnet:
        final mainnetCosmosDirectoryChains = _mainnetCosmosDirectoryChains;
        if (mainnetCosmosDirectoryChains != null) {
          return ResultOk(mainnetCosmosDirectoryChains);
        }
        final result = await _getCosmsmosChains(CCRConst.cosmosDirectoryUri);
        return result.map((e) {
          _mainnetCosmosDirectoryChains = e;
          return e;
        });
      case ChainType.testnet:
        final testnetCosmosDirectoryChains = _testnetCosmosDirectoryChains;
        if (testnetCosmosDirectoryChains != null) {
          return ResultOk(testnetCosmosDirectoryChains);
        }
        final result = await _getCosmsmosChains(CCRConst.cosmosTestnetDirectoryUri);
        return result.map((e) {
          _testnetCosmosDirectoryChains = e;
          return e;
        });
    }
  }

  Future<IResult<CosmosDirectoryChain?>> _getCosmosDirectoryChain(
      {required String? chainId, ChainType chain = ChainType.mainnet}) async {
    final data = await _getCosmosDirectoryChains(chain: chain);
    return data.map((data) => data.firstWhereNullable((e) => e.chainId == chainId));
  }

  Future<IResult<List<PingPubChain>>> getCosmosChains(
      {ChainType chain = ChainType.mainnet}) async {
    final baseUrl = _getChainUrl(chain);
    return _lock.run(() async {
      switch (chain) {
        case ChainType.mainnet:
          final mainnetChains = _mainnetChains;
          if (mainnetChains != null) {
            return ResultOk(mainnetChains);
          }
          final result = await _getChains(baseUrl);
          return result.map((e) {
            _mainnetChains = e;
            return e;
          });
        case ChainType.testnet:
          final testnetChains = _testnetChains;
          if (testnetChains != null) {
            return ResultOk(testnetChains);
          }
          final result = await _getChains(baseUrl);
          return result.map((e) {
            _testnetChains = e;
            return e;
          });
      }
    });
  }

  String _getChainUrl(ChainType chain) {
    if (chain.isMainnet) {
      return CCRConst.chainRegisteryUri;
    }
    return CCRConst.chainRegisteryUriTestnets;
  }

  Future<IResult<(CCRChainData, CosmosDirectoryChain?)>> getChainData(
    String chainName, {
    ChainType chainType = ChainType.mainnet,
  }) async {
    return _lock.run(() async {
      final localChain = _getLocalChain(chainType: chainType, name: chainName);
      if (localChain != null) {
        final cosmosDirectoryChain =
            await _getCosmosDirectoryChain(chainId: localChain.chain.chainId);
        return cosmosDirectoryChain
            .map((cosmosDirectoryChain) => (localChain, cosmosDirectoryChain));
      }
      final baseUrl = _getChainUrl(chainType);
      Uri uri = CCRUtilities.getChainUri(
          baseUrl: baseUrl, chain: chainName, schema: CCRSchemaType.chain);
      final chains = await netApi.httpGet<Map<String, dynamic>>(uri.toString(),
          responseType: StreamEncoding.map);
      return chains.andThenAsync((result) async {
        final chain = CCRChain.fromJson(result);
        uri = CCRUtilities.getChainUri(
            baseUrl: baseUrl, chain: chainName, schema: CCRSchemaType.assetlist);
        final assets = await netApi.httpGet<Map<String, dynamic>>(uri.toString(),
            responseType: StreamEncoding.map);
        return assets.andThenAsync((result) async {
          final asset = CCRAssetList.fromJson(result);
          final chainData = CCRChainData(chain: chain, assetList: asset);
          _chains[chainType]?.add(chainData);
          final cosmosDirectoryChain =
              await _getCosmosDirectoryChain(chainId: chainData.chain.chainId);
          return cosmosDirectoryChain
              .map((cosmosDirectoryChain) => (chainData, cosmosDirectoryChain));
        });
      });
    });
  }

  Future<CCRAsset?> findAsset(
      {required String denom,
      required String? chainName,
      ChainType chainType = ChainType.mainnet}) async {
    if (chainName == null) return null;
    final chain = await getChainData(chainName, chainType: chainType);
    return chain.fold(
      onOk: (chain) => chain.$1.assetList.assets.firstWhereOrNull((e) => e.base == denom),
      onErr: (error) {
        error.logError(runtime: runtimeType, function: "findAsset");
        return null;
      },
    );
  }
}

class CosmosNetworkClient extends NetworkClient<CosmosWalletTransaction, BaseNetworkToken,
        CosmosBaseAddress, WalletCosmosNetwork>
    with
        CosmosCustomRequest,
        CosmosQuickServiceApi<
            DefaultProvider<CosmosProvider<MultiChainServiceClient>,
                IServiceRequestParams>>
    implements
        BaseSwapCosmosClient {
  @override
  final CosmosNetworkProvider networkProvider;
  @override
  INetApi get netApi => provider.netApi;
  @override
  final List<CosmosProviderApi> supportedApis;

  CosmosNetworkClient(
      {required this.provider,
      required super.network,
      required this.networkProvider,
      required this.supportedApis});
  @override
  final DefaultProvider<CosmosProvider<MultiChainServiceClient>, IServiceRequestParams>
      provider;

  factory CosmosNetworkClient.fromProvider({
    required CosmosNetworkProvider provider,
    required WalletCosmosNetwork network,
    required INetApi netApi,
  }) {
    return CosmosNetworkClient(
      network: network,
      networkProvider: provider,
      supportedApis: [provider.cosmosService()],
      provider: DefaultProvider(CosmosProvider(MultiChainServiceClient.fromProvider(
          provider: provider.provider, netApi: netApi))),
    );
  }
  factory CosmosNetworkClient.fromService(
      {required CosmosNetworkProvider provider,
      required WalletCosmosNetwork network,
      required MultiChainServiceClient service}) {
    assert(service.provider == provider.provider);
    return CosmosNetworkClient(
      network: network,
      networkProvider: provider,
      supportedApis: [provider.cosmosService()],
      provider: DefaultProvider(CosmosProvider(service)),
    );
  }

  Future<IbcChannelStatus?> getIbcChannelStatus(String channelName,
      {String prot = CosmosConst.transferIbcPort}) async {
    try {
      final result =
          await query(QueryChannelRequest(portId: prot, channelId: channelName));
      final counterpartyChannelId = result.channel?.counterparty?.channelId;
      final counterpartyPort = result.channel?.counterparty?.portId;

      if (counterpartyChannelId == null || counterpartyPort == null) return null;
      if (result.channel?.state != State.stateOpen) {
        return IbcChannelStatus(
            channel: result.channel!,
            clientStatus: KnownIbcClientStatus.statusUnknown,
            counterpartyChannelId: counterpartyChannelId,
            counterpartyPort: counterpartyPort);
      }
      final status = await getIbcClinetState(channelName, prot: prot);
      return IbcChannelStatus(
          channel: result.channel!,
          clientStatus: KnownIbcClientStatus.fromStatus(status),
          counterpartyChannelId: counterpartyChannelId,
          counterpartyPort: counterpartyPort);
    } on APIError catch (e) {
      if (CosmosProviderUtils.itemNotFound(e.errorCode)) {
        return null;
      }
      rethrow;
    }
  }

  Future<String?> getIbcClinetState(String channelName,
      {String prot = CosmosConst.transferIbcPort}) async {
    try {
      final clientId = await query(
          QueryChannelClientStateRequest(portId: prot, channelId: channelName));
      final id = clientId.identifiedClientState?.clientId;
      if (id == null) return null;
      final status = await query(QueryClientStatusRequest(clientId: id));
      return status.status;
    } on APIError catch (e) {
      if (CosmosProviderUtils.itemNotFound(e.errorCode)) {
        return null;
      }
      rethrow;
    }
  }

  Future<CW20Token?> getTokenMetadata(String denom, {BigInt? amount}) async {
    final request = QueryDenomMetadataRequest(denom: denom);
    final result = await query(request);
    final metadata = result.metadata;
    if (metadata == null) return null;
    final denomUnit =
        metadata.denomUnits.firstWhereNullable((e) => e.denom == metadata.display);
    if (denomUnit == null) return null;
    final name = metadata.name ?? metadata.symbol ?? denomUnit.denom;

    if (name == null) return null;
    final symbol = metadata.symbol ?? denomUnit.denom ?? name;
    return CW20Token.create(
        balance: amount ?? BigInt.zero,
        token: Token(
            name: CosmosConst.extractFactoryTokenName(name),
            symbol: CosmosConst.extractFactoryTokenName(symbol),
            decimal: denomUnit.exponent ?? 0),
        denom: denom);
  }

  Future<List<CosmosChainAsset>> getAddressTokens(ICosmosAddress address) async {
    final addrTokens = (await address.getAccountTokens()).unwrap();
    List<Coin> balances = await getAddressCoins(address.networkAddress);
    balances = balances.where((e) => e.denom != network.coinParam.denom).toList();
    final List<CosmosChainAsset> tokens = [];

    for (final i in balances) {
      final denom = i.denom;
      if (denom == null) continue;
      final exists = addrTokens.any((e) => e.denom == i.denom);
      if (exists) continue;
      final token = (await IResult.call(
              () async => await getTokenMetadata(denom, amount: i.getAmount())))
          .ok();
      if (token != null) {
        tokens.add(CosmosChainAsset.cw20Token(token));
      } else {
        final amount = BigintUtils.parse(i.getAmount());
        final asset = await findAsset(
            denom: denom,
            chainName: network.coinParam.chainRegisteryName,
            chainType: network.coinParam.chainType);
        if (asset != null) {
          tokens.add(CosmosChainAsset.ccrAsset(asset: asset, coin: i, balance: amount));
        } else {
          tokens.add(CosmosChainAsset.unknown(coin: i, balance: amount));
        }
      }
    }
    return tokens;
  }

  Future<ThorNodeNetworkConstants> getThorNodeConstants() async {
    if (network.coinParam.networkConstantUri == null) {
      throw APIErrorConst.invalidRequestUrl;
    }
    final constantsJson = await netApi.httpGet<Map<String, dynamic>>(
        network.coinParam.networkConstantUri!,
        responseType: StreamEncoding.map);
    final constants = ThorNodeNetworkConstants.fromJson(
        constantsJson.unwrap().valueEnsureAsMap<String, dynamic>("int_64_values"));
    return constants;
  }

  Future<bool> validateNetworkChainId() async {
    final chainId = await this.chainId();
    return chainId == network.coinParam.chainId;
  }

  @override
  Future<CosmosSwapTransactionRequirment> getSwapTransactionRequirment(
      CosmosBaseAddress address, int totalMessages) async {
    final cosmosAccount = await getAccount(address);
    BigInt? fixedFee;
    if (network.coinParam.networkType == CosmosNetworkTypes.thorAndForked) {
      const Map<String, int> fees = {
        "thorchain-1": 2000000,
        "mayachain-mainnet-v1": 2000000000
      };
      final fee = await IResult.call(
        () async {
          final networkConst = await getThorNodeConstants();
          return BigInt.from(networkConst.nativeTransactionFee);
        },
        mode: LoggerMode.info,
        onError: (exception, trace) => AppLogData(
            err: exception,
            trace: trace.toString(),
            function: "getSwapTransactionRequirment",
            runtime: runtimeType),
      );
      fixedFee = fee.unwrapOr((_) {
        final fee = fees[network.coinParam.chainId];
        if (fee == null) {
          throw AppInternalError.internalError("getSwapTransactionRequirment",
              reason: "Unknown forked network chainId ${network.coinParam.chainId}");
        }
        return BigInt.from(fee);
      });
    }
    return CosmosSwapTransactionRequirment(
        account: cosmosAccount, fixedNativeGas: fixedFee);
  }

  @override
  CosmosSwapNetworkReuirment get chainInfo => CosmosSwapNetworkReuirment(
      native: CosmosSwapCoin(denom: network.coinParam.denom),
      feeTokens: network.coinParam.feeTokens
          .map((e) => CosmosSwapFeeCoin(
              denom: e.denom, averageGasPrice: e.getAverageGasPrice().balance))
          .toList());

  Future<void> _fetchTokenMetadata(CosmosNetworkToken token) async {
    if (!token.status.allowRetry) return;
    token.setPending();
    final metadata = await IResult.call(() async {
      final result = await query(QueryDenomMetadataRequest(denom: token.token.denom));
      final metadata = result.metadata;
      final display = metadata?.display;
      if (metadata == null || display == null) return null;
      final denomUnit = metadata.denomUnits.firstWhereOrNull((e) => e.denom == display);
      final denom = denomUnit?.denom;
      if (denomUnit == null || denom == null) return null;
      return Token(
          name: CosmosConst.extractFactoryTokenName(
              metadata.name ?? metadata.symbol ?? denom),
          symbol: CosmosConst.extractFactoryTokenName(metadata.symbol ?? denom),
          decimal: denomUnit.exponent ?? 0);
    });
    if (metadata.ok() != null) {
      token.updaetTokenMetadata(metadata.unwrap()!);
      return;
    }
    final asset = await findAsset(
        denom: token.token.denom,
        chainName: network.coinParam.chainRegisteryName,
        chainType: network.coinParam.chainType);
    final decimal = asset?.denomUnits.firstWhereOrNull((e) => e.denom == asset.display);
    if (asset != null && decimal != null) {
      final updateToken =
          Token(name: asset.name, symbol: asset.symbol, decimal: decimal.exponent);
      token.updaetTokenMetadata(updateToken);
      return;
    }
    token.setError();
  }

  @override
  Stream<List<BaseNetworkToken>> getAccountTokensStream(CosmosBaseAddress address) {
    final controller = SafeStreamController<List<CosmosNetworkToken>>(
        name: "CosmosNetworkClient.getAccountTokensStream");

    void add(List<CW20Token> tokens) {
      if (!controller.isClosed) {
        final cTokens = tokens.map((e) => CosmosNetworkToken(token: e)).toList();
        controller.add(cTokens);
        for (final i in cTokens) {
          _fetchTokenMetadata(i);
        }
      }
    }

    void error(Object err) {
      if (!controller.isClosed) controller.addError(err);
    }

    void close() {
      if (!controller.isClosed) controller.close();
    }

    Future<void> fetchTokens() async {
      try {
        final result = await IResult.call(() async {
          return getAddressCoins(address);
        });

        if (result.isErr) {
          error(result.unwrapErr().exception);
          close();
          return;
        }
        final balances = result
            .unwrap()
            .where((e) => e.denom != null && e.denom != network.coinParam.denom)
            .map((e) => CW20Token.create(
                balance: BigintUtils.parse(e.getAmount()),
                token: Token(name: e.denom, symbol: e.denom, decimal: 6),
                denom: e.getDenom()))
            .toList();
        add(balances);
      } catch (e) {
        error(e);
      } finally {
        close();
      }
    }

    controller.onListenListener(fetchTokens);
    controller.onCancelListener(close);
    return controller.stream();
  }

  @override
  List<MultiChainServiceClient> services() {
    return [provider.service];
  }

  @override
  Future<bool> verifyService(DefaultAPIProvider provider) async {
    if (provider == this.provider.service.provider) {
      return validateNetworkChainId();
    }
    return false;
  }

  @override
  Future<WalletTransactionStatus> transactionStatus(
      CosmosWalletTransaction transaction) async {
    try {
      await getTransaction(transaction.txId);
      return WalletTransactionStatus.block;
    } on RPCError catch (e) {
      if (CosmosProviderUtils.itemNotFound(e.errorCode)) {
        return WalletTransactionStatus.unknown;
      }
      rethrow;
    }
  }
}

class CosmosClient
    with
        CosmosQuickServiceApi<
            DefaultProvider<CosmosProvider<MultiChainServiceClient>,
                IServiceRequestParams>> {
  @override
  final List<CosmosProviderApi> supportedApis;
  CosmosClient({
    required this.provider,
    required this.supportedApis,
  });
  @override
  final DefaultProvider<CosmosProvider<MultiChainServiceClient>, IServiceRequestParams>
      provider;

  factory CosmosClient.fromProvider({
    required DefaultAPIProvider provider,
    required INetApi netApi,
  }) {
    return CosmosClient(
      supportedApis: switch (provider.service) {
        APIProviderServices.tendermint => [CosmosProviderApi.tendermint],
        APIProviderServices.cosmosRest => [CosmosProviderApi.rest],
        APIProviderServices.cosmosGrpc => [CosmosProviderApi.grpc],
        _ => throw AppInternalError.internalError("CosmosClient.fromProvider",
            reason: "Invalid cosmos provider service.",
            details: {"service": provider.service.name})
      },
      provider: DefaultProvider(CosmosProvider(
          MultiChainServiceClient.fromProvider(provider: provider, netApi: netApi))),
    );
  }

  void dispose() {
    provider.service.dispose();
  }
}
