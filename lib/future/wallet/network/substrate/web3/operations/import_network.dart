import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/conf/core/coin_conf.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/web3/pages/import_network.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/web3/core/state.dart';
import 'package:on_chain_wallet/wallet/api/api.dart';
import 'package:on_chain_wallet/wallet/api/types/types.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/constant/networks/substrate.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/network/params/substrate.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/networks/substrate/constant/constants/exception.dart';
import 'package:on_chain_wallet/web3/web3/networks/substrate/params/models/add_chain.dart';

class Web3SubstrateImportOrUpdateNetworkStateController
    extends Web3SubstrateStateController<bool, SubstrateNetworkClient?,
        Web3SubstrateAddNewChain> {
  SubstrateChain? _chain;
  SubstrateChain? get chain => _chain;
  Web3SubstrateImportOrUpdateNetworkStateController(
      {required super.walletProvider, required super.request});

  final GlobalKey<FormState> formKey =
      GlobalKey(debugLabel: "Web3SubstrateImportOrUpdateNetworkStateController");
  final GlobalKey<HTTPServiceProviderFieldsState> rpcKey =
      GlobalKey(debugLabel: "Web3SubstrateImportOrUpdateNetworkStateController rpcKey");
  RPCURL? uri;

  bool isWalletNetwork = false;
  bool isDefaultNetwork = false;
  int decimal = 10;
  String symbol = '';
  String networkName = '';
  String explorerAddressLink = "";
  String explorerTransaction = "";
  void onChangeSymbol(String v) {
    symbol = v;
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

  void onChangeDecimals(int? v) {
    decimal = v ?? 0;
  }

  String? onValidateDecimals(String? v) {
    final parse = int.tryParse(v ?? "");
    if (parse == null || parse < 0 || parse > APPSubstrateConst.maxDecimals) {
      return "token_decimal_maxn_validator"
          .tr
          .replaceOne(APPSubstrateConst.maxDecimals.toString());
    }
    return null;
  }

  String? onValidateChainId(String? v) {
    final toInt = BigInt.tryParse(v ?? "");
    if (toInt == null) return "chain_id_validator".tr;
    return null;
  }

  String? onValidateRpcUrl(String? v) {
    final path = StrUtils.validateUri(v, schame: ["http", "https", "ws", "wss"]);
    if (path == null) return "rpc_url_validator".tr;
    return null;
  }

  String? onValidateSymbol(String? v) {
    if ((v?.isEmpty ?? true) || v!.isEmpty || v.length > 6) {
      return "symbol_validator".tr;
    }
    return null;
  }

  String? onValidateAddressLink(String? v) {
    if (v?.trim().isEmpty ?? true) return null;
    final link = StrUtils.validateUri(v);
    if (link == null) return "validate_link_desc".tr;
    return null;
  }

  String? onValidateNetworkName(String? v) {
    if ((v?.isEmpty ?? true) || v!.length < 2 || v.length > 25) {
      return "network_name_validator".tr;
    }
    return null;
  }

  String? onValidateCoinType(String? v) {
    if (v?.trim().isEmpty ?? true) return null;
    final parse = int.tryParse(v ?? "");
    if (parse == null || parse < 0 || parse > Bip32KeyDataConst.keyIndexMaxVal) {
      return "slip_44_desc".tr;
    }
    return null;
  }

  void onImportNewNetwork({BuildContext? context}) {
    if (!formKey.ready()) return;
    final rpcUrl = rpcKey.currentState?.getEndpoint();
    if (rpcUrl == null) return;
    super.acceptRequest(context: context);
  }

  @override
  Future<Web3RequestResponseData<bool>> getResponse() async {
    final chain = this.chain;
    if (chain != null) {
      final client = (await chain.client()).unwrap();
      if (chain.network.genesisBlock != params.genesisHash) {
        throw Web3SubstrateExceptionConstant.differentRuntimeMetadata;
      }
      SubstrateNetworkParams updateParams = chain.network.coinParam;
      if (updateParams.specVersion == client.metadata.specVersion) {
        return Web3RequestResponseData(response: true);
      }
      updateParams = updateParams.updateSpecVersion(client.metadata.specVersion);
      final updateNetwork = chain.network.copyWith(coinParam: updateParams);
      (await walletProvider.wallet
              .doAction(WalletActionUpdateNetwork(network: updateNetwork)))
          .unwrap();
      return Web3RequestResponseData(response: true);
    }
    final rpcUrl = rpcKey.currentState?.getEndpoint();
    if (rpcUrl == null) {
      throw AppException("invalid_provider_infomarion".tr);
    }
    final provider = DefaultAPIProvider.create(
        url: rpcUrl.url,
        service: APIProviderServices.substrateJsonRpc,
        auth: rpcUrl.auth);
    final client = SubstrateClient.fromProviders(
        provider: provider, netApi: walletProvider.wallet.config.netApi);
    final init = await IResult.call(() async => client.loadApi());
    client.dispose();
    if (init.isErr) {
      throw AppException(init.unwrapErr().localizationError);
    } else if (init.ok() == null) {
      throw AppException("unsuported_network_metadata".tr);
    } else {
      final chainInfo = init.unwrap()!;
      final coinParam = SubstrateNetworkParams(
          token: Token(name: networkName, symbol: symbol, decimal: decimal),
          // providers: [provider],
          chainType: ChainType.mainnet,
          ss58Format: chainInfo.ss58Prefix,
          substrateChainType: chainInfo.extrinsic.crypto.type,
          addressExplorer: explorerAddressLink,
          transactionExplorer: explorerTransaction,
          gnesisBlock: chainInfo.genesis,
          relaySystem: chainInfo.internalNetwork?.relaySystem,
          consensusRole: chainInfo.internalNetwork?.role,
          keyAlgorithms: chainInfo.extrinsic.crypto.cryptoAlgoritms,
          specVersion: chainInfo.specVersion);
      final network = WalletSubstrateNetwork(-1, coinParam);
      (await walletProvider.wallet.doAction(
              WalletActionImportNewNetwork(network: network, providers: [provider])))
          .unwrap();
      return Web3RequestResponseData(response: true);
    }
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return Web3SubstrateImportNetworkStateView(this);
  }

  @override
  Future<void> initForm(SubstrateNetworkClient? client) async {
    await super.initForm(client);
    _chain = walletProvider.wallet
        .getChains<SubstrateChain>()
        .firstWhereOrNull((e) => e.network.genesisBlock == params.genesisHash);
    decimal = params.tokenDecimals;
    symbol = params.tokenSymbol;
    networkName = params.chain;
    final rpcUrl = params.rpcUrl;
    DefaultAPIProvider? provider;
    if (rpcUrl != null) {
      provider = DefaultAPIProvider.create(
          url: rpcUrl, service: APIProviderServices.substrateJsonRpc);
      uri = RPCURL(url: provider.url, auth: provider.auth);
    }
  }
}
