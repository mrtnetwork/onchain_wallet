import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';
import 'package:on_chain_wallet/wallet/api/types/types.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class SubstrateImportChainView extends StatelessWidget {
  const SubstrateImportChainView({super.key});

  @override
  Widget build(BuildContext context) {
    return AccessWalletView<WalletCredentialResponseLogin, WalletCredentialLogin>(
      request: WalletCredentialLogin.instance,
      appbar: AppBar(title: Text("import_network".tr)),
      onAccsess: (_) {
        return _ImportSubstrateNetwork();
      },
    );
  }
}

enum _Page { rpc, fields, review }

mixin AddSubstrateChainState<T extends StatefulWidget> on SafeState<T> {
  final StreamPageProgressController pageProgressKey = StreamPageProgressController();
  final GlobalKey<FormState> formKey =
      GlobalKey(debugLabel: "AddSubstrateChainState_formKey");
  final GlobalKey<HTTPServiceProviderFieldsState> rpcKey =
      GlobalKey(debugLabel: "AddSubstrateChainState_rpcKey");
  (SubstrateNetworkParams, DefaultAPIProvider)? network;
  SubstrateChainMetadata? metadata;
  RPCURL? uri;
  bool get canPop => pageProgressKey.isSuccess || _page == _Page.rpc;

  _Page _page = _Page.rpc;
  bool isWalletNetwork = false;
  bool isDefaultNetwork = false;
  int decimal = 10;
  String symbol = '';
  String networkName = '';
  String explorerAddressLink = "";
  String explorerTransaction = "";

  void clearState() {
    uri = null;
    decimal = 10;
    symbol = '';
    networkName = '';
    explorerAddressLink = "";
    explorerTransaction = "";
    network = null;
    metadata = null;
    _page = _Page.rpc;
    updateState();
  }

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

  String? validateAddressLink(String? v) {
    if (v?.trim().isEmpty ?? true) return null;
    final link = StrUtils.validateUri(v);
    if (link == null) return "validate_link_desc".tr;
    return null;
  }

  String? validateNetworkName(String? v) {
    if ((v?.isEmpty ?? true) || v!.length < 2 || v.length > 25) {
      return "network_name_validator".tr;
    }
    return null;
  }

  String? validateCoinType(String? v) {
    if (v?.trim().isEmpty ?? true) return null;
    final parse = int.tryParse(v ?? "");
    if (parse == null || parse < 0 || parse > Bip32KeyDataConst.keyIndexMaxVal) {
      return "slip_44_desc".tr;
    }
    return null;
  }

  void onChangeDecimals(int? v) {
    decimal = v ?? 0;
  }

  String? validateDecimals(String? v) {
    final parse = int.tryParse(v ?? "");
    if (parse == null || parse < 0 || parse > APPSubstrateConst.maxDecimals) {
      return "token_decimal_maxn_validator"
          .tr
          .replaceOne(APPSubstrateConst.maxDecimals.toString());
    }
    return null;
  }

  String? validateChainId(String? v) {
    final toInt = BigInt.tryParse(v ?? "");
    if (toInt == null) return "chain_id_validator".tr;
    return null;
  }

  String? validateRpcUrl(String? v) {
    final path = StrUtils.validateUri(v, schame: ["http", "https", "ws", "wss"]);
    if (path == null) return "rpc_url_validator".tr;
    return null;
  }

  String? validateSymbol(String? v) {
    if ((v?.isEmpty ?? true) || v!.isEmpty || v.length > 6) {
      return "symbol_validator".tr;
    }
    return null;
  }

  bool get showRemoveIcon => isWalletNetwork && !isDefaultNetwork;
  Future<void> getNetworkInfromation() async {
    if (!formKey.ready()) return;
    final url = uri = rpcKey.currentState?.getEndpoint();
    if (url == null) return;
    pageProgressKey.progressText("checking_rpc_network_info".tr);
    final provider = DefaultAPIProvider.create(
        url: url.url, service: APIProviderServices.substrateJsonRpc, auth: url.auth);
    final client = SubstrateClient.fromProviders(
      provider: provider,
      netApi: context.appContext.netApi,
    );
    final init = await IResult.call(() async {
      final api = await client.loadApi();
      if (api == null) return null;
      // final substrateNetwork = BaseSubstrateNetwork.fromGenesis(api.genesis);
      final systemProperties = await client.systemProperties();
      final systemChain = await client.systemChain();
      return (api, systemProperties, systemChain);
    });
    client.dispose();
    if (init.isErr) {
      pageProgressKey.errorText(init.unwrapErr().localizationError,
          backToIdle: false, showBackButton: true);
    } else if (init.ok() == null) {
      pageProgressKey.errorText("unsuported_network_metadata".tr);
    } else {
      final chainData = init.unwrap();
      final chainInfo = chainData!.$1;
      final internalController = chainInfo.controller;

      metadata = chainInfo;
      networkName = internalController?.network.networkName ?? chainData.$3 ?? '';
      if (internalController != null) {
        symbol = internalController.defaultNativeAsset.symbol ?? '';
        decimal = internalController.defaultNativeAsset.decimals ?? decimal;
      } else {
        final token = chainData.$2?.tokens.firstOrNull;
        if (token != null) {
          symbol = token.tokenSymbol;
          decimal = token.decimals;
        }
      }
      _page = _Page.fields;
      pageProgressKey.backToIdle();
    }
  }

  Future<void> checkNetwork() async {
    if (!formKey.ready()) return;
    final uri = this.uri;
    final chainInfo = metadata;

    if (uri == null || chainInfo == null) return;
    pageProgressKey.progressText("create_network_please_wait".tr);
    final network = await IResult.call(() async {
      final provider = DefaultAPIProvider.create(
          url: uri.url, service: APIProviderServices.substrateJsonRpc, auth: uri.auth);
      metadata = chainInfo;
      final network = SubstrateNetworkParams(
        token: Token(name: networkName, symbol: symbol, decimal: decimal),
        chainType: ChainType.mainnet,
        ss58Format: chainInfo.ss58Prefix,
        substrateChainType: chainInfo.extrinsic.crypto.type,
        addressExplorer: explorerAddressLink.nullOnEmpty,
        transactionExplorer: explorerTransaction.nullOnEmpty,
        gnesisBlock: chainInfo.genesis,
        keyAlgorithms: chainInfo.extrinsic.crypto.cryptoAlgoritms,
        specVersion: chainInfo.specVersion,
        consensusRole: chainInfo.internalNetwork?.role,
        relaySystem: chainInfo.internalNetwork?.relaySystem,
      );
      return (network, provider);
    }, delay: APPConst.oneSecoundDuration);
    if (network.isErr) {
      pageProgressKey.errorText(network.unwrapErr().localizationError,
          backToIdle: false, showBackButton: true);
      return;
    }
    this.network = network.unwrap();
    _page = _Page.review;
    pageProgressKey.backToIdle();
    updateState();
  }

  Future<void> addOrUpdateChain() async {
    final params = this.network;
    if (params == null) return;
    pageProgressKey.progressText("add_or_updating_wallet_network".tr);
    final wallet = context.wallet;
    final network = WalletSubstrateNetwork(-1, params.$1);
    final import = await (wallet.wallet.doAction(
        WalletActionImportNewNetwork(network: network, providers: [params.$2])));
    if (import.isErr) {
      pageProgressKey.errorText(import.unwrapErr().localizationError,
          backToIdle: false, showBackButton: true);
    } else {
      pageProgressKey.successText("network_imported_to_your_wallet".tr,
          backToIdle: false);
    }
  }

  void onBackButton(bool _, Object? __) {
    if (!canPop) {
      clearState();
    }
  }

  @override
  void safeDispose() {
    super.safeDispose();
    pageProgressKey.dispose();
  }
}

class _ImportSubstrateNetwork extends StatefulWidget {
  const _ImportSubstrateNetwork();
  @override
  State<_ImportSubstrateNetwork> createState() => __ImportSubstrateNetworkState();
}

class __ImportSubstrateNetworkState extends State<_ImportSubstrateNetwork>
    with
        SafeState<_ImportSubstrateNetwork>,
        AddSubstrateChainState<_ImportSubstrateNetwork> {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      canPop: canPop,
      onPopInvokedWithResult: onBackButton,
      child: UnfocusableChild(
        child: StreamPageProgress(
          controller: pageProgressKey,
          // backToIdle: APPConst.oneSecoundDuration,
          builder: (c) => CustomScrollView(
            slivers: [
              SliverConstraintsBoxView(
                  padding: WidgetConstant.padding20,
                  sliver: APPSliverAnimatedSwitcher<_Page>(enable: _page, widgets: {
                    _Page.rpc: (context) => SubstrateAddChainRPCFieldsView(state: this),
                    _Page.fields: (context) => SubstrateAddChainFieldsView(state: this),
                    _Page.review: (context) {
                      return SubstrateAddChainInfoView(
                          onAddChain: addOrUpdateChain,
                          network: network!.$1,
                          metadata: metadata!);
                    }
                  }))
            ],
          ),
        ),
      ),
    );
  }
}

class SubstrateAddChainRPCFieldsView extends StatelessWidget {
  const SubstrateAddChainRPCFieldsView({required this.state, super.key});
  final AddSubstrateChainState state;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitleSubtitle(
              title: "import_new_network".tr,
              body: LargeTextView(
                  ["import_new_network_desc1".tr, "import_new_network_desc2".tr])),
          WidgetConstant.height20,
          Text("providers".tr, style: context.textTheme.titleMedium),
          LargeTextView(
            ["network_title_http_wss_url".tr],
            maxLine: 2,
          ),
          WidgetConstant.height8,
          HTTPServiceProviderFields(
              key: state.rpcKey,
              protocols: [ServiceProtocol.http, ServiceProtocol.websocket],
              initialUrl: state.uri),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FixedElevatedButton(
                  padding: WidgetConstant.paddingVertical40,
                  onPressed: state.getNetworkInfromation,
                  child: Text("continue".tr))
            ],
          )
        ],
      ),
    );
  }
}

class SubstrateAddChainFieldsView extends StatelessWidget {
  const SubstrateAddChainFieldsView({required this.state, super.key});
  final AddSubstrateChainState state;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitleSubtitle(
              title: "import_new_network".tr,
              body: LargeTextView(
                  ["import_new_network_desc1".tr, "import_new_network_desc2".tr])),
          Text("network_name".tr, style: context.textTheme.titleMedium),
          Text("network_name_desc".tr),
          WidgetConstant.height8,
          AppTextField(
            initialValue: state.networkName,
            onChanged: state.onChangeNetworkName,
            validator: state.validateNetworkName,
            label: "network_name".tr,
          ),
          WidgetConstant.height20,
          Text("symbol".tr, style: context.textTheme.titleMedium),
          Text("symbol_desc".tr),
          WidgetConstant.height8,
          AppTextField(
              initialValue: state.symbol,
              onChanged: state.onChangeSymbol,
              validator: state.validateSymbol,
              label: "symbol".tr),
          WidgetConstant.height20,
          Text("decimals".tr, style: context.textTheme.titleMedium),
          Text("solana_mint_decimal_desc".tr),
          ErrorTextContainer(
              error: "change_token_decimal_desc3".tr,
              enableTap: false,
              showErrorIcon: false),
          WidgetConstant.height8,
          NumberTextField(
              label: "decimals".tr,
              defaultValue: state.decimal,
              onChangeValue: state.onChangeDecimals,
              validator: state.validateDecimals,
              max: APPSubstrateConst.maxDecimals,
              min: 0),
          WidgetConstant.height20,
          Text("network_explorer_address_link".tr, style: context.textTheme.titleMedium),
          LargeTextView(["network_evm_explorer_address_desc".tr], maxLine: 1),
          WidgetConstant.height8,
          AppTextField(
            initialValue: state.explorerAddressLink,
            onChanged: state.onChangeExplorerAddress,
            validator: state.validateAddressLink,
            label: "network_explorer_address_link".tr,
            pasteIcon: true,
          ),
          WidgetConstant.height20,
          Text("network_explorer_transaction_link".tr,
              style: context.textTheme.titleMedium),
          LargeTextView(["network_evm_explorer_transaction_desc".tr], maxLine: 1),
          WidgetConstant.height8,
          AppTextField(
            initialValue: state.explorerAddressLink,
            onChanged: state.onChangeExplorerTransaction,
            validator: state.validateAddressLink,
            label: "network_explorer_transaction_link".tr,
            pasteIcon: true,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FixedElevatedButton(
                  padding: WidgetConstant.paddingVertical40,
                  onPressed: state.checkNetwork,
                  child: Text("continue".tr))
            ],
          )
        ],
      ),
    );
  }
}

class SubstrateAddChainInfoView extends StatelessWidget {
  const SubstrateAddChainInfoView(
      {super.key,
      required this.network,
      this.metadata,
      required this.onAddChain,
      this.buttonText});
  final SubstrateNetworkParams network;
  final SubstrateChainMetadata? metadata;
  final DynamicVoid onAddChain;
  final String? buttonText;

  @override
  Widget build(BuildContext context) {
    final keyAlgorithms = network.keyAlgorithms.map((e) => e.name).join(", ");
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (metadata != null) ...[
            ErrorTextContainer(error: "import_network_experimental_feature_desc".tr),
            WidgetConstant.height20,
          ],
          Text("network_name".tr, style: context.textTheme.titleMedium),
          WidgetConstant.height8,
          ContainerWithBorder(
            child: Text(network.token.name, style: context.onPrimaryTextTheme.bodyMedium),
          ),
          WidgetConstant.height20,
          Text("symbol".tr, style: context.textTheme.titleMedium),
          WidgetConstant.height8,
          ContainerWithBorder(
              child: Text(network.token.symbol,
                  style: context.onPrimaryTextTheme.bodyMedium)),
          WidgetConstant.height20,
          Text("decimals".tr, style: context.textTheme.titleMedium),
          WidgetConstant.height8,
          ContainerWithBorder(
              child: Text(network.token.decimal.toString(),
                  style: context.onPrimaryTextTheme.bodyMedium)),
          WidgetConstant.height20,
          Text("spec_version".tr, style: context.textTheme.titleMedium),
          WidgetConstant.height8,
          ContainerWithBorder(
              child: Text(network.specVersion.toString(),
                  style: context.onPrimaryTextTheme.bodyMedium)),
          if (!network.substrateChainType.isEthereum) ...[
            WidgetConstant.height20,
            Text("key_algorithms".tr, style: context.textTheme.titleMedium),
            WidgetConstant.height8,
            ContainerWithBorder(
                child: Text(keyAlgorithms, style: context.onPrimaryTextTheme.bodyMedium)),
          ],
          WidgetConstant.height20,
          Text("ss58_prefix".tr, style: context.textTheme.titleMedium),
          WidgetConstant.height8,
          ContainerWithBorder(
              child: Text(network.ss58Format.toString(),
                  style: context.onPrimaryTextTheme.bodyMedium)),
          if (metadata != null) ...[
            if (!metadata!.supportNativeTransfer) ...[
              WidgetConstant.height20,
              ErrorTextContainer(error: "substrate_disable_transfer_option_desc".tr),
            ],
            if (!metadata!.supportAccountTemplate) ...[
              WidgetConstant.height20,
              ErrorTextContainer(error: "substrate_unsuported_account_template_desc".tr),
            ],
          ],
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            FixedElevatedButton(
                padding: WidgetConstant.paddingVertical40,
                onPressed: onAddChain,
                child: Text(buttonText ?? "import_network".tr))
          ]),
        ],
      ),
    );
  }
}
