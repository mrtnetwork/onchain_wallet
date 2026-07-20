import 'package:flutter/material.dart';
import 'package:on_chain/solidity/abi/abi.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/web3/operations/typed_data.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/web3_request_page_builder.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/models/networks/ethereum/models/typed_data.dart';

class Web3EthereumSignTypedDataStateView extends StatelessWidget {
  const Web3EthereumSignTypedDataStateView({required this.controller, super.key});
  final Web3EthereumSignTypedDataStateController controller;
  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      Text("version".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      ContainerWithBorder(
        child: Text(controller.params.typedData.version.name.toString(),
            style: context.onPrimaryTextTheme.bodyMedium),
      ),
      _EIP712FieldsView(
        typedData: controller.params.typedData,
        domain: controller.params.domain,
      ),
      WidgetConstant.height20,
      Text("message".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      ContainerWithBorder(
        enableTap: false,
        padding: EdgeInsets.zero,
        child: APPExpansionListTile(
          title: Text("message".tr, style: context.onPrimaryTextTheme.bodyMedium),
          children: List.generate(controller.params.typedDataJson.length, (index) {
            final key = controller.params.typedDataJson.keys.elementAt(index);
            final value = controller.params.typedDataJson[key];
            if (value == null) return WidgetConstant.sizedBox;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ContainerWithBorder(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        key.camelCase,
                        style: context.onPrimaryTextTheme.labelLarge,
                      ),
                      ContainerWithBorder(
                        backgroundColor: context.colors.onPrimaryContainer,
                        constraints: null,
                        child: CopyTextIcon(
                          dataToCopy: value.toString(),
                          isSensitive: false,
                          color: context.colors.primaryContainer,
                          widget: SelectableText(
                            value.toString(),
                            style: context.primaryTextTheme.bodyMedium,
                            maxLines: 4,
                            minLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
      Web3StateAcceptRequestView(controller: controller, title: "sign_message".tr),
    ]);
  }
}

class _EIP712FieldsView extends StatelessWidget {
  const _EIP712FieldsView({required this.typedData, required this.domain});
  final EIP712Base typedData;
  final EIP712Domain? domain;
  @override
  Widget build(BuildContext context) {
    if (typedData.version.version > 1) {
      final Eip712TypedData eip712 = typedData as Eip712TypedData;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WidgetConstant.height20,
          Text("primary_type".tr, style: context.textTheme.titleMedium),
          WidgetConstant.height8,
          ContainerWithBorder(
            onRemove: () {},
            onRemoveWidget:
                CopyTextIcon(dataToCopy: eip712.primaryType, isSensitive: false),
            enableTap: false,
            child: Text(eip712.primaryType, style: context.onPrimaryTextTheme.bodyMedium),
          ),
          _EIP712DomainView(domain)
        ],
      );
    }
    return WidgetConstant.sizedBox;
  }
}

class _EIP712DomainView extends StatelessWidget {
  const _EIP712DomainView(this.domain);
  final EIP712Domain? domain;
  @override
  Widget build(BuildContext context) {
    if (domain == null) return WidgetConstant.sizedBox;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WidgetConstant.height20,
        Text("domain".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("name".tr, style: context.onPrimaryTextTheme.labelLarge),
            ContainerWithBorder(
                backgroundColor: context.onPrimaryContainer,
                child: Text(domain!.name, style: context.primaryTextTheme.bodyMedium)),
            WidgetConstant.height20,
            Text("version".tr, style: context.onPrimaryTextTheme.titleMedium),
            ContainerWithBorder(
                backgroundColor: context.onPrimaryContainer,
                child: Text(domain!.version, style: context.primaryTextTheme.bodyMedium)),
            WidgetConstant.height20,
            Text("verifying_contract".tr, style: context.onPrimaryTextTheme.titleMedium),
            ContainerWithBorder(
                backgroundColor: context.onPrimaryContainer,
                onRemove: () {},
                onRemoveWidget: CopyTextIcon(
                    dataToCopy: domain!.verifyingContract.address,
                    isSensitive: false,
                    color: context.primaryContainer),
                child: Text(domain!.verifyingContract.address,
                    style: context.primaryTextTheme.bodyMedium)),
          ],
        )),
        WidgetConstant.height20,
      ],
    );
  }
}
