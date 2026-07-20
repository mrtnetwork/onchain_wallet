import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/bip/slip/slip44/slip44.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/ethereum/utils.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/http_authenticated.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/api/types/types.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

class EthereumAddNewChainFrom with DisposableMixin, StreamStateController {
  final INetApi netApi;
  EthereumAddNewChainFrom(this.netApi);
  final StreamPageProgressController pageProgressKey = StreamPageProgressController();
  final GlobalKey<AppTextFieldState> uriFieldKey = GlobalKey();
  final GlobalKey<AppTextFieldState> explorerFieldKey = GlobalKey();
  final GlobalKey<FormState> formKey = GlobalKey();
  final GlobalKey<AppTextFieldState> transactionFieldKey = GlobalKey();
  final GlobalKey<HTTPServiceProviderFieldsState> rpcKey = GlobalKey();
  final buttonKey = GlobalKey();
  List<DefaultAPIProvider> _existsProviders = [];
  List<DefaultAPIProvider> get existsProviders => _existsProviders;
  ChainType chainType = ChainType.mainnet;
  bool isManualCoinType = false;
  bool _editableChainId = true;
  bool get editableChainId => _editableChainId;
  RPCURL? rpcUrl;
  List<BigInt> _existsChainIds = [];
  List<BigInt> get existsChainIds => _existsChainIds;
  String symbol = '';
  String networkName = '';
  BigInt chainId = BigInt.one;
  int coinType = Slip44.ethereum;
  String explorerAddressLink = "";
  String explorerTransaction = "";
  APPImage? image;

  DefaultAPIProvider? selectedProvider;

  void onChangeSymbol(String v) {
    symbol = v;
  }

  void onChangeChainType(ChainType? chainType) {
    if (chainType == null || isManualCoinType) return;
    if (!isManualCoinType) {
      coinType = switch (chainType) {
        ChainType.testnet => Slip44.testnet,
        ChainType.mainnet => Slip44.ethereum
      };
    }
    this.chainType = chainType;
    notify();
  }

  void onChangeNetworkName(String v) {
    networkName = v;
  }

  void onChangeExplorerAddress(String v) {
    explorerAddressLink = v;
  }

  void onChangeExplorerTransaction(String v) {
    explorerTransaction = v;
  }

  // String? chainError;
  void onChangeChainId(BigInt chainId) {
    if (!editableChainId) return;
    this.chainId = chainId;
  }

  void onChangeCoinType(int? v) {
    if (v == null) return;
    if (v != coinType) {
      isManualCoinType = true;
    }
    coinType = v;
  }

  void onChangeRpcUrl(String v) {
    if (selectedProvider != null && v != selectedProvider?.url) {
      selectedProvider = null;
      notify();
    }
  }

  String? validateCoinType(String? v) {
    if (v?.trim().isEmpty ?? true) return null;
    final parse = int.tryParse(v ?? "");
    if (parse == null || parse < 0 || parse > Bip32KeyDataConst.keyIndexMaxVal) {
      return "slip_44_desc".tr;
    }
    return null;
  }

  String? validateChainId(String? v) {
    final toInt = BigInt.tryParse(v ?? "");
    if (toInt == null) return "chain_id_validator".tr;
    if (existsChainIds.contains(toInt)) {
      return "network_chain_id_already_exist".tr;
    }
    return null;
  }

  String? validateNetworkName(String? v) {
    if ((v?.isEmpty ?? true) || v!.length < 2 || v.length > 25) {
      return "network_name_validator".tr;
    }
    return null;
  }

  String? validateSymbol(String? v) {
    if ((v?.isEmpty ?? true) || v!.isEmpty || v.length > 6) {
      return "symbol_validator".tr;
    }
    return null;
  }

  String? validateAddressLink(String? v) {
    if (v?.trim().isEmpty ?? true) return null;
    final link = StrUtils.validateUri(v);
    if (link == null) return "validate_link_desc".tr;
    return null;
  }

  void onTapProvider(DefaultAPIProvider provider) async {
    rpcUrl = RPCURL(url: provider.url, auth: provider.auth);
    selectedProvider = provider;
    notify();
    buttonKey.ensureKeyVisible();
  }

  bool isReady() {
    final rpcUrl = rpcKey.currentState?.getEndpoint();
    if (!formKey.ready() || rpcUrl == null) return false;
    return true;
  }

  void initForm(
      {List<BigInt> existsChainIds = const [],
      BigInt? chainId,
      String? networkName,
      String? name,
      String? symbol,
      List<String>? blockExplorerUrls,
      List<String>? iconUrls,
      List<String>? rpcUrls}) {
    _editableChainId = chainId == null;
    this.chainId = chainId ?? this.chainId;
    this.networkName = networkName ?? this.networkName;
    this.symbol = symbol ?? this.symbol;
    explorerAddressLink = blockExplorerUrls?.firstOrNull ?? '';
    explorerTransaction = blockExplorerUrls?.firstOrNull ?? '';
    image = iconUrls?.map((e) => APPImage.network(e)).firstOrNull;
    final validRpcs =
        rpcUrls?.where((e) => ServicePorotocolUtils.isHttoOrWebsocket(e)).toList();
    _existsProviders = validRpcs
            ?.map((e) => DefaultAPIProvider.create(
                url: e, service: APIProviderServices.ethereumJsonRpc))
            .toList() ??
        [];
    _existsChainIds = existsChainIds.immutable;
  }

  Future<(EthereumNetworkParams, DefaultAPIProvider)?> buildNetwork() async {
    if (!isReady()) return null;
    final rpcUrl = rpcKey.currentState?.getEndpoint();
    if (rpcUrl == null) return null;
    final provider = DefaultAPIProvider.create(
        url: rpcUrl.url, service: APIProviderServices.ethereumJsonRpc, auth: rpcUrl.auth);
    final chain = chainId;

    final client = EthereumClient.fromProviders(provider: provider, netApi: netApi);
    try {
      final info = await client.getNetworkInfo();
      final params = EthereumNetworkParams(
          transactionExplorer: explorerTransaction.nullOnEmpty,
          addressExplorer: explorerAddressLink.nullOnEmpty,
          token: Token(name: networkName, symbol: symbol, decimal: EthereumUtils.decimal),
          chainId: chain,
          supportEIP1559: info.$2,
          defaultNetwork: false,
          chainType: chainType,
          bip32CoinType: coinType);
      return (params, provider);
    } finally {
      client.dispose();
    }
  }

  @override
  void dispose() {
    super.dispose();
    pageProgressKey.dispose();
  }
}
