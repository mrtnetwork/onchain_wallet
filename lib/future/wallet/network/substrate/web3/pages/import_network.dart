import 'package:blockchain_utils/service/models/params.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/http_authenticated.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/web3/operations/import_network.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/web3_request_page_builder.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class Web3SubstrateImportNetworkStateView extends StatelessWidget {
  final Web3SubstrateImportOrUpdateNetworkStateController controller;
  const Web3SubstrateImportNetworkStateView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return ConditionalWidget(
        enable: controller.chain != null,
        onDeactive: (context) => _ImportNewNetwork(controller: controller),
        onActive: (context) => _ReviewNetworkInformation(
            network: controller.chain!.network.coinParam,
            controller: controller));
  }
}

class _ImportNewNetwork extends StatelessWidget {
  final Web3SubstrateImportOrUpdateNetworkStateController controller;
  const _ImportNewNetwork({required this.controller});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      SliverToBoxAdapter(
        child: Form(
          key: controller.formKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("network_name".tr, style: context.textTheme.titleMedium),
            Text("network_name_desc".tr),
            WidgetConstant.height8,
            AppTextField(
              initialValue: controller.networkName,
              onChanged: controller.onChangeNetworkName,
              validator: controller.onValidateNetworkName,
              label: "network_name".tr,
            ),
            WidgetConstant.height20,
            Text("symbol".tr, style: context.textTheme.titleMedium),
            Text("symbol_desc".tr),
            WidgetConstant.height8,
            AppTextField(
                initialValue: controller.symbol,
                onChanged: controller.onChangeSymbol,
                validator: controller.onValidateSymbol,
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
                defaultValue: controller.decimal,
                onChangeValue: controller.onChangeDecimals,
                validator: controller.onValidateDecimals,
                max: APPSubstrateConst.maxDecimals,
                maxWidth: null,
                min: 0),
            WidgetConstant.height20,
            Text("network_explorer_address_link".tr,
                style: context.textTheme.titleMedium),
            LargeTextView(["network_evm_explorer_address_desc".tr], maxLine: 1),
            WidgetConstant.height8,
            AppTextField(
              initialValue: controller.explorerAddressLink,
              onChanged: controller.onChangeExplorerAddress,
              validator: controller.onValidateAddressLink,
              label: "network_explorer_address_link".tr,
              pasteIcon: true,
            ),
            WidgetConstant.height20,
            Text("network_explorer_transaction_link".tr,
                style: context.textTheme.titleMedium),
            LargeTextView(["network_evm_explorer_transaction_desc".tr],
                maxLine: 1),
            WidgetConstant.height8,
            AppTextField(
              initialValue: controller.explorerAddressLink,
              onChanged: controller.onChangeExplorerTransaction,
              validator: controller.onValidateAddressLink,
              label: "network_explorer_transaction_link".tr,
              pasteIcon: true,
            ),
            WidgetConstant.height20,
            Text("providers".tr, style: context.textTheme.titleMedium),
            LargeTextView(
              ["network_title_http_wss_url".tr],
              maxLine: 2,
            ),
            WidgetConstant.height8,
            HTTPServiceProviderFields(
                key: controller.rpcKey,
                protocols: [ServiceProtocol.http, ServiceProtocol.websocket],
                initialUrl: controller.uri),
            Web3StateAcceptRequestView(
                controller: controller,
                onAcceptRequest: controller.onImportNewNetwork,
                title: "import_network".tr),
          ]),
        ),
      )
    ]);
  }
}

class _ReviewNetworkInformation extends StatelessWidget {
  final SubstrateNetworkParams network;
  final Web3SubstrateImportOrUpdateNetworkStateController controller;
  const _ReviewNetworkInformation(
      {required this.network, required this.controller});

  @override
  Widget build(BuildContext context) {
    final keyAlgorithms = network.keyAlgorithms.map((e) => e.name).join(", ");
    return MultiSliver(children: [
      PageTitleSubtitle(
          title: "update_metadata".tr,
          body: Text('substrate_update_metadata_desc'.tr)),
      Text("network_name".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      ContainerWithBorder(
        child: Text(network.token.name,
            style: context.onPrimaryTextTheme.bodyMedium),
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
      ConditionalWidget(
        enable: !network.substrateChainType.isEthereum,
        onActive: (context) =>
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          WidgetConstant.height20,
          Text("key_algorithms".tr, style: context.textTheme.titleMedium),
          WidgetConstant.height8,
          ContainerWithBorder(
              child: Text(keyAlgorithms,
                  style: context.onPrimaryTextTheme.bodyMedium)),
        ]),
      ),
      WidgetConstant.height20,
      Text("ss58_prefix".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      ContainerWithBorder(
          child: Text(network.ss58Format.toString(),
              style: context.onPrimaryTextTheme.bodyMedium)),
      Web3StateAcceptRequestView(
          controller: controller, title: "update_metadata".tr),
    ]);
  }
}
