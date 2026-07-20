import 'package:blockchain_utils/bip/bip/bip.dart';
import 'package:blockchain_utils/service/models/params.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/http_authenticated.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/network/import/controller/controller.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class ImportEthereumNetwork extends StatefulWidget {
  const ImportEthereumNetwork({super.key});

  @override
  State<ImportEthereumNetwork> createState() => _ImportEthereumNetworkState();
}

class _ImportEthereumNetworkState extends State<ImportEthereumNetwork>
    with SafeState<ImportEthereumNetwork> {
  late final EthereumAddNewChainFrom form;
  final pageKey = StreamPageProgressController();

  Future<void> import() async {
    final ready = form.isReady();
    if (!ready) return;
    pageKey.progressText("checking_rpc_network_info".tr);
    final result = await IResult.call(() async {
      return await form.buildNetwork();
    });
    if (result.isErr) {
      pageKey.errorText(result.unwrapErr().localizationError,
          showBackButton: true, backToIdle: false);
      return;
    }
    final params = result.unwrap();
    if (params == null) {
      pageKey.backToIdle();
      return;
    }
    pageKey.progressText("updating_network".tr);
    final import = await context.wallet.wallet.doAction(WalletActionImportNewNetwork(
        network: WalletEthereumNetwork(-1, params.$1), providers: [params.$2]));
    if (import.isErr) {
      pageKey.errorText(import.unwrapErr().localizationError,
          showBackButton: true, backToIdle: false);
      return;
    }
    pageKey.successText("network_imported_to_your_wallet".tr, backToIdle: false);
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    final walletProvider = context.wallet;
    form = EthereumAddNewChainFrom(context.appContext.netApi);
    final ethChains = walletProvider.wallet.getChains<EthereumChain>();
    final existsChainIds = ethChains.map((e) => e.chainId).toList();
    form.initForm(existsChainIds: existsChainIds);
  }

  @override
  void safeDispose() {
    super.safeDispose();
    form.dispose();
    pageKey.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("import_evm_network".tr)),
      body: StreamPageProgress(
        controller: pageKey,
        builder: (context) => CustomScrollView(
          slivers: [
            SliverConstraintsBoxView(
                padding: WidgetConstant.paddingHorizontal20,
                sliver:
                    ImportEthereumNetworkFieldsView(form: form, onCreateNetwork: import)),
          ],
        ),
      ),
    );
  }
}

class ImportEthereumNetworkFieldsView extends StatelessWidget {
  const ImportEthereumNetworkFieldsView(
      {super.key, required this.form, this.onCreateNetwork});
  final EthereumAddNewChainFrom form;
  final DynamicVoid? onCreateNetwork;

  @override
  Widget build(BuildContext context) {
    return APPStreamBuilder(
        value: form.notifier,
        builder: (context, _) {
          return SliverToBoxAdapter(
              // crossAxisAlignment: CrossAxisAlignment.start,
              child: Form(
            key: form.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("chain_id".tr, style: context.textTheme.titleMedium),
                Text("chain_id_of_network".tr),
                WidgetConstant.height8,
                ConditionalWidget(
                    enable: form.editableChainId,
                    onDeactive: (context) => ContainerWithBorder(
                          child: Text(form.chainId.toString(),
                              style: context.onPrimaryTextTheme.bodyMedium),
                        ),
                    onActive: (context) => BigNumberTextField(
                          label: "chain_id".tr,
                          defaultValue: form.chainId,
                          min: BigInt.zero,
                          onChange: form.onChangeChainId,
                          readOnly: !form.editableChainId,
                          validator: form.validateChainId,
                          maxWidth: null,
                        )),
                WidgetConstant.height20,
                Text("chain_type".tr, style: context.textTheme.titleMedium),
                WidgetConstant.height8,
                AppDropDownBottom(
                    items: {for (final i in ChainType.values) i: Text(i.name.tr)},
                    hint: "chain_type".tr,
                    onChanged: form.onChangeChainType,
                    value: form.chainType),
                WidgetConstant.height20,
                Text("network_name".tr, style: context.textTheme.titleMedium),
                Text("network_name_desc".tr),
                WidgetConstant.height8,
                AppTextField(
                    initialValue: form.networkName,
                    onChanged: form.onChangeNetworkName,
                    validator: form.validateNetworkName,
                    label: "network_name".tr),
                WidgetConstant.height20,
                Text("symbol".tr, style: context.textTheme.titleMedium),
                Text("symbol_desc".tr),
                WidgetConstant.height8,
                AppTextField(
                    initialValue: form.symbol,
                    onChanged: form.onChangeSymbol,
                    validator: form.validateSymbol,
                    label: "symbol".tr),
                WidgetConstant.height20,
                Text("coin_type".tr, style: context.textTheme.titleMedium),
                LargeTextView(["slip_44_desc".tr, "coin_type_desc2".tr], maxLine: 1),
                WidgetConstant.height8,
                NumberTextField(
                    key: ValueKey(form.chainType),
                    label: "coin_type".tr,
                    defaultValue: form.coinType,
                    onChangeValue: form.onChangeCoinType,
                    validator: form.validateCoinType,
                    max: Bip32KeyDataConst.keyIndexMaxVal,
                    min: 0,
                    maxWidth: null),
                WidgetConstant.height20,
                Text("network_explorer_address_link".tr,
                    style: context.textTheme.titleMedium),
                LargeTextView(["network_evm_explorer_address_desc".tr], maxLine: 1),
                WidgetConstant.height8,
                AppTextField(
                  key: form.explorerFieldKey,
                  initialValue: form.explorerAddressLink,
                  onChanged: form.onChangeExplorerAddress,
                  validator: form.validateAddressLink,
                  label: "network_explorer_address_link".tr,
                  pasteIcon: true,
                ),
                WidgetConstant.height20,
                Text("network_explorer_transaction_link".tr,
                    style: context.textTheme.titleMedium),
                LargeTextView(["network_evm_explorer_transaction_desc".tr], maxLine: 1),
                WidgetConstant.height8,
                AppTextField(
                  key: form.transactionFieldKey,
                  initialValue: form.explorerAddressLink,
                  onChanged: form.onChangeExplorerTransaction,
                  validator: form.validateAddressLink,
                  label: "network_explorer_transaction_link".tr,
                  pasteIcon: true,
                ),
                ConditionalWidget(
                    enable: form.existsProviders.isNotEmpty,
                    onActive: (context) =>
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          WidgetConstant.height20,
                          Text("providers".tr, style: context.textTheme.titleMedium),
                          Text("select_provider_to_use".tr),
                          WidgetConstant.height8,
                          ...List.generate(form.existsProviders.length, (index) {
                            final provider = form.existsProviders[index];
                            final selected = form.selectedProvider == provider;

                            return ContainerWithBorder(
                                onRemove: () {
                                  form.onTapProvider(provider);
                                },
                                onRemoveIcon: APPAnimated(
                                    isActive: selected,
                                    onDeactive: (context) => WidgetConstant.sizedBox,
                                    onActive: (context) => Icon(Icons.check_circle,
                                        color: context.onPrimaryContainer)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(provider.protocol.value.tr,
                                        style: context.onPrimaryTextTheme.labelLarge),
                                    Text(provider.url,
                                        style: context.onPrimaryTextTheme.bodyMedium,
                                        maxLines: 2),
                                  ],
                                ));
                          }),
                        ])),
                WidgetConstant.height20,
                Text("providers".tr, style: context.textTheme.titleMedium),
                LargeTextView(["network_title_http_wss_url".tr], maxLine: 2),
                WidgetConstant.height8,
                HTTPServiceProviderFields(
                    key: form.rpcKey,
                    protocols: [ServiceProtocol.http, ServiceProtocol.websocket],
                    initialUrl: form.rpcUrl,
                    onChangeUrl: form.onChangeRpcUrl),
                ConditionalWidget(
                    enable: onCreateNetwork != null,
                    onActive: (context) => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FixedElevatedButton(
                                padding: WidgetConstant.paddingVertical40,
                                onPressed: onCreateNetwork,
                                child: Text("import".tr))
                          ],
                        ))
              ],
            ),
          ));
        });
  }
}
