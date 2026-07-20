import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:cosmos_sdk/proto_messages/cosmos/bank/v1beta1/src/query.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/http_authenticated.dart';
import 'package:on_chain_wallet/future/widgets/widgets/text_field.dart';
import 'package:on_chain_wallet/wallet/api/types/types.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

typedef ONADDORUPDATECOSMOSTOKEN = Future<CosmosFeeToken?> Function(
    CosmosFeeToken? token);

class CosmosAddNewChainFrom
    with DisposableMixin, CosmosCustomRequest, StreamStateController {
  final MainAppContext context;
  @override
  INetApi get netApi => context.netApi;
  CosmosAddNewChainFrom(this.context);
  final GlobalKey<AppTextFieldState> explorerFieldKey = GlobalKey();
  final GlobalKey<AppTextFieldState> transactionFieldKey = GlobalKey();
  final GlobalKey<FormState> formKey = GlobalKey();

  String explorerAddressLink = "";
  String explorerTransaction = "";
  String? networkName;
  String hrp = '';
  String chainId = '';
  RPCURL? rpcUrl;
  int slip44 = CosmosConst.defaultSlip44;
  List<CosmosFeeToken> feeTokens = [];
  CosmosFeeToken? nativeToken;
  List<CosmosKeysAlg> _supportedAlgs = [];
  List<CosmosKeysAlg> get supportedAlgs => _supportedAlgs;
  Map<CosmosKeysAlg, Widget> keyAlgos = {};
  ChainType? _chainType;
  APIProviderServices service = APIProviderServices.tendermint;
  List<APIProviderServices> services = [
    APIProviderServices.tendermint,
    APIProviderServices.cosmosGrpc,
    APIProviderServices.cosmosRest
  ];

  // bool imutableKeyAlg = false;
  bool unknowKeyAlg = false;
  bool supportedKeyAlg = false;
  CosmosKeysAlg? _selectedAlg;
  CosmosKeysAlg? get selectedAlg => _selectedAlg;
  CosmosKeysAlg? keyAlg;
  final GlobalKey<HTTPServiceProviderFieldsState> serviceProviderStateKey =
      GlobalKey(debugLabel: "_MoneroSyncOptionsViewState_serviceProviderStateKey");

  void setNativeToken(CosmosFeeToken token) {
    nativeToken = token;
  }

  void onChangeService(APIProviderServices? service) {
    if (service == null || !services.contains(service)) return;
    this.service = service;
  }

  void setFeeTokens(List<CosmosFeeToken> feeTokens) {
    this.feeTokens = feeTokens;
  }

  void setChainId(String chainId) {
    this.chainId = chainId;
  }

  void setRpcUrl(String url) {
    rpcUrl = RPCURL(url: url);
  }

  Map<CosmosKeysAlg, Widget> buildKeyAlgos() {
    return {for (final i in _supportedAlgs) i: Text(i.alg)};
  }

  CosmosSdkChain? _chain;
  CosmosSdkChainChains? _chains;
  CosmosSdkChainChains? get chains => _chains;
  void buildFromWeb3Request(
      {required String chainId,
      required String rpc,
      String? name,
      String? hrp,
      List<String>? keyAlogrithm,
      CosmosFeeToken? nativeToken,
      List<CosmosFeeToken>? feeTokens,
      ChainType? chainType}) {
    final chains = _chains;

    CosmosSdkChain? chain;
    switch (chainType) {
      case ChainType.testnet:
        chain = chains?.testnet.firstWhereOrNull((e) => e.chainId == chainId);
        break;
      case ChainType.mainnet:
        chain = chains?.mainnet.firstWhereOrNull((e) => e.chainId == chainId);
        break;
      default:
        chain = chains?.mainnet.firstWhereOrNull((e) => e.chainId == chainId);
        chain ??= chains?.testnet.firstWhereOrNull((e) => e.chainId == chainId);
        break;
    }
    buildFrom(chain);
    if (chainType != null) {
      _chainType = chainType;
    }
    _buildRpc(rpc);
    if (keyAlogrithm != null) {
      _buildAlgo(keyAlogrithm);
    }
    if (name != null) {
      networkName = name;
    }
    if (hrp != null) {
      this.hrp = hrp;
    }
    if (nativeToken != null) {
      this.nativeToken = nativeToken;
    }
    if (feeTokens != null && feeTokens.isNotEmpty) {
      this.feeTokens = feeTokens;
    }
  }

  void buildFrom(CosmosSdkChain? chain) {
    _chain = chain;
    networkName = chain?.path;
    explorerAddressLink = chain?.explorers.accountPage ?? '';
    explorerTransaction = chain?.explorers.txPage ?? '';
    hrp = chain?.bech32Prefix ?? '';
    slip44 = chain?.slip44 ?? CosmosConst.defaultSlip44;
    _chainType = chain?.type;
    if (chain == null) {
      nativeToken = null;
      feeTokens = [];
    } else {
      nativeToken = CosmosFeeToken(
          token: Token(
            name: chain.native.name,
            symbol: chain.native.symbol,
            decimal: chain.native.decimals,
            assetLogo: APPImage.network(chain.native.imagePng),
            market: chain.native.coingeckoId == null
                ? null
                : CoingeckoCoin(apiId: chain.native.coingeckoId!),
          ),
          denom: chain.native.denom,
          lowGasPrice: BigRational.tryParse(chain.native.highGasPrice.toString()) ??
              CosmosConst.lowGasPrice,
          highGasPrice: BigRational.tryParse(chain.native.highGasPrice.toString()) ??
              CosmosConst.highGasPrice,
          averageGasPrice:
              BigRational.tryParse(chain.native.averageGasPrice.toString()) ??
                  CosmosConst.avarageGasPrice);

      feeTokens = chain.fees.map((e) {
        return CosmosFeeToken(
            token: Token(
              name: e.name,
              symbol: e.symbol,
              decimal: e.decimals,
              assetLogo: APPImage.network(e.imagePng),
              market: e.coingeckoId == null ? null : CoingeckoCoin(apiId: e.coingeckoId!),
            ),
            denom: e.denom,
            lowGasPrice:
                BigRational.tryParse(e.lowGasPrice.toString()) ?? CosmosConst.lowGasPrice,
            highGasPrice: BigRational.tryParse(e.highGasPrice.toString()) ??
                CosmosConst.highGasPrice,
            averageGasPrice: BigRational.tryParse(e.averageGasPrice.toString()) ??
                CosmosConst.avarageGasPrice);
      }).toList();
    }
    _buildAlgo(chain?.supportedAlgs.map((e) => e.name).toList() ?? []);
    final rpc = chain?.bestApis.firstOrNull;
    _buildRpc(rpc?.url, service: rpc?.api);
  }

  void _buildRpc(String? url, {CosmosProviderApi? service}) {
    this.service = switch (service) {
      CosmosProviderApi.rest => APIProviderServices.cosmosRest,
      CosmosProviderApi.grpc => APIProviderServices.cosmosGrpc,
      _ => APIProviderServices.tendermint
    };
    if (url != null) {
      rpcUrl = RPCURL(url: url);
    } else {
      rpcUrl = null;
    }
  }

  void _buildAlgo(List<String> chainAlg) {
    keyAlg = null;
    if (chainAlg.isEmpty) {
      unknowKeyAlg = true;
      supportedKeyAlg = true;
      _supportedAlgs = CosmosKeysAlgs.supportedAlgs
          .map((e) => CosmosKeysAlg._(alg: e.name.camelCase, key: e))
          .toList();
    } else {
      unknowKeyAlg = false;
      _supportedAlgs = chainAlg.map((e) => CosmosKeysAlg(e)).toList();
      supportedKeyAlg = _supportedAlgs.any((e) => e.supported);
    }
    keyAlgos = buildKeyAlgos();
  }

  Future<CosmosSdkChainChains> loadChains() async {
    final json = await context.platformUtls.loadAssets(APPConst.cosmosChainRegistery);
    final result = json.mapCatch((e) => CosmosSdkChainChains.deserialize(bytes: e));
    return result.fold(
      onOk: (value) => value,
      onErr: (error) => CosmosSdkChainChains(mainnet: [], testnet: []),
    );
  }

  Future<void> onUpdateNativeToken(ONADDORUPDATECOSMOSTOKEN onTap) async {
    final t = await onTap(nativeToken);
    if (t == null) return;
    nativeToken = t;
    notify();
  }

  Future<void> onRemoveFeeToken(
      CosmosFeeToken token, FuncFutureNullableBool onRemove) async {
    final r = await onRemove();
    if (!(r ?? false)) return;
    feeTokens.remove(token);
    notify();
  }

  Future<void> onAddNewToken(
      ONADDORUPDATECOSMOSTOKEN onTap, DynamicVoid onTokenExists) async {
    final t = await onTap(null);
    if (t == null) return;
    if (feeTokens.any((e) => e.denom == t.denom)) {
      onTokenExists();

      return;
    }
    feeTokens.add(t);
    notify();
  }

  void onChangeKeyAlgs(CosmosKeysAlg? alg) {
    if (alg == null) return;
    keyAlg = alg;
    notify();
  }

  void onChangeCoinType(int? v) {
    if (v == null) return;
    slip44 = v;
  }

  String? validateCoinType(String? v) {
    if (v?.trim().isEmpty ?? true) return null;
    final parse = int.tryParse(v ?? "");
    if (parse == null || parse < 0 || parse > Bip32KeyDataConst.keyIndexMaxVal) {
      return "slip_44_desc".tr;
    }
    return null;
  }

  String? onValidateKeyAlgorithm(CosmosKeysAlg? alg) {
    if (alg == null) return "select_key_algorithm_desc".tr;
    return null;
  }

  void onChangeHrp(String v) {
    hrp = v;
  }

  void onChangeExplorerAddress(String v) {
    explorerAddressLink = v;
  }

  void onChangeExplorerTransaction(String v) {
    explorerTransaction = v;
  }

  String? validateAddressLink(String? v) {
    if (v?.trim().isEmpty ?? true) return null;
    final link = StrUtils.validateUri(v);
    if (link == null) return "validate_link_desc".tr;
    return null;
  }

  String? onValidateHrp(String? v) {
    if (v?.isEmpty ?? true) return null;
    if (APPConst.hrpRegex.hasMatch(v!)) return null;
    return "enter_network_hrp_validator".tr;
  }

  Future<void> initForm() async {
    _chains = await loadChains();
  }

  (CosmosNetworkParams, RPCURL, bool)? _buildCoinParams(ChainType chainType) {
    final rpc = rpcUrl;
    if (nativeToken == null || feeTokens.isEmpty || rpc == null) return null;
    List<CosmosKeysAlgs> supportedAlgs = [];
    if (unknowKeyAlg) {
      final key = keyAlg?.key;
      if (key != null) {
        supportedAlgs.add(key);
      }
    } else {
      supportedAlgs =
          this.supportedAlgs.where((e) => e.supported).map((e) => e.key).toList().cast();
    }
    if (supportedAlgs.isEmpty) return null;

    final network = CosmosNetworkParams(
        token: nativeToken!.token,
        chainType: chainType,
        hrp: hrp,
        denom: nativeToken!.denom,
        feeTokens: feeTokens,
        networkType: CosmosNetworkTypes.forked,
        chainId: chainId,
        keysAlgs: supportedAlgs,
        bip32CoinType: slip44,
        addressExplorer: StrUtils.isDomain(explorerAddressLink)
            ? explorerAddressLink.nullOnEmpty
            : null,
        transactionExplorer: StrUtils.isDomain(explorerTransaction)
            ? explorerTransaction.nullOnEmpty
            : null,
        chainRegisteryName: networkName);

    return (network, rpc, unknowKeyAlg);
  }

  RPCURL? getRpcUrl() {
    rpcUrl = serviceProviderStateKey.currentState?.getEndpoint();
    if (rpcUrl == null) return null;
    return rpcUrl;
  }

  Future<(CosmosClient, String?)> getClient(RPCURL url) async {
    final provider =
        DefaultAPIProvider.create(url: url.url, service: service, auth: url.auth);
    final client = CosmosClient.fromProvider(provider: provider, netApi: netApi);
    try {
      final bech32 = await client.networkBech32();
      return (client, bech32);
    } catch (e) {
      client.dispose();
      rethrow;
    }
  }

  Future<(CosmosNetworkParams, DefaultAPIProvider)> _buildNetwork(
      {required RPCURL url,
      required CosmosNetworkParams param,
      required bool unKnownKeyAlgorithm,
      required CosmosSdkChain? chain}) async {
    final (service, bech32) = await getClient(url);
    try {
      String hrp = param.hrp;
      if (bech32 == null) {
        if (hrp.isEmpty) {
          throw AppException("unable_to_retrieve_hrp");
        }
      } else {
        if (hrp.isEmpty) {
          hrp = bech32;
        }
      }
      await service.tryGetAccount(
          CosmosBaseAddress.fromBytes(QuickCrypto.generateRandom(), hrp: hrp));
      final nativeToken = await IResult.call(
          () => service.query(QueryDenomMetadataRequest(denom: param.denom)));
      if (nativeToken.isErr) {
        await service.totalSupply(param.denom);
      }
      for (final i in param.feeTokens) {
        if (i.denom == param.denom) continue;
        await service.totalSupply(i.denom);
      }
      final chainId = await service.chainId();
      CosmosNetworkTypes networkTypes = param.networkType;
      if (param.keysAlgs.any((e) => e.isEthereum)) {
        networkTypes = CosmosNetworkTypes.ethermint;
      }
      param = param.copyWith(
          chainId: chainId,
          hrp: hrp,
          networkType: networkTypes,
          keysAlgs: param.keysAlgs);
      return (param, service.provider.service.provider);
    } finally {
      service.dispose();
    }
  }

  Future<(CosmosNetworkParams, DefaultAPIProvider)?> createNetwork(
      {required FuncFutureNullableBool onUnknownAlgAlert, ChainType? chainType}) async {
    if (unknowKeyAlg) {
      final ok = await onUnknownAlgAlert();
      if (ok != true) return null;
    }
    final param = _buildCoinParams(chainType ?? _chainType ?? ChainType.mainnet);
    if (param == null) return null;

    return await _buildNetwork(
        url: param.$2, param: param.$1, unKnownKeyAlgorithm: param.$3, chain: _chain);
  }
}

class CosmosKeysAlg {
  final String alg;
  final CosmosKeysAlgs? key;
  bool get supported => key != null;
  const CosmosKeysAlg._({required this.alg, required this.key});
  factory CosmosKeysAlg(String alg) {
    CosmosKeysAlgs? key;
    try {
      key = CosmosKeysAlgs.fromSupportedAlgs(alg);
    } catch (_) {}
    return CosmosKeysAlg._(alg: alg.camelCase, key: key);
  }
}
