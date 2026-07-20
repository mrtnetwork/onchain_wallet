import 'package:flutter/material.dart';
import 'package:on_chain/solidity/address/core.dart';
import 'package:on_chain/tron/tron.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';

import 'package:on_chain_wallet/future/wallet/network/ethereum/transaction/widgets/select_fee.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/web3/operations/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/pages/fee.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/web3_request_page_builder.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/models/network/network.dart';

class Web3EthereumSendTransactionStateView extends StatelessWidget {
  final Web3EthereumSendTransactionStateController controller;

  const Web3EthereumSendTransactionStateView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      _ETHTransactionTransferFields(
        field: controller.transactionData.transactionInfos,
        network: controller.network,
      ),
      WidgetConstant.height20,
      TransactionFeeWidget(
          onTapManual: () {
            context.openSliverBottomSheet("transaction_fee".tr,
                child: EthereumGasOptionsView(fee: controller.txFee));
          },
          fee: controller.txFee,
          getMaxFeeInput: controller.getMaxFeeInput),
      Web3StateAcceptRequestView(controller: controller, title: "send_transaction".tr),
    ]);
  }
}

class _ETHTransactionTransferFields extends StatelessWidget {
  const _ETHTransactionTransferFields({required this.field, required this.network});
  final Web3EthereumTransactionRequestInfos field;
  final WalletEthereumNetwork network;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Transaction Amount", style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
            child: CoinAndMarketPriceView(
                balance: field.value,
                style: context.onPrimaryTextTheme.titleMedium,
                showTokenImage: true,
                symbolColor: context.onPrimaryContainer)),
        WidgetConstant.height20,
        if (field.destination?.networkAddress != null) ...[
          ReceiptAddressView(
              address: field.destination,
              title: field.isContract ? "contract".tr : "recipient".tr),
          WidgetConstant.height20,
        ],
        _EthereumTransactionDataView(data: field.dataInfo, network: network),
      ],
    );
  }
}

class _EthereumTransactionDataView extends StatelessWidget {
  const _EthereumTransactionDataView({required this.data, required this.network});
  final EthereumTransactionDataInfo? data;
  final WalletNetwork network;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("transaction_type".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data?.localizationName.tr ?? "transfer".tr,
                style: context.onPrimaryTextTheme.bodyMedium),
            if (data?.selector != null)
              Text(data!.selector!, style: context.onPrimaryTextTheme.bodyMedium)
          ],
        )),
        if (data != null) ...[
          WidgetConstant.height20,
          EthereumTransactionDataWidget(data: data!, network: network)
        ],
      ],
    );
  }
}

class EthereumTransactionDataWidget extends StatelessWidget {
  const EthereumTransactionDataWidget(
      {required this.data, required this.network, super.key});
  final EthereumTransactionDataInfo data;
  final WalletNetwork network;
  @override
  Widget build(BuildContext context) {
    switch (data.type) {
      case SolidityMethodInfoTypes.creationContract:
        return WidgetConstant.sizedBox;
      case SolidityMethodInfoTypes.unknown:
        final info = data.cast<SolidityUnknownMethodInfo>();
        return _UnknownTransactionDataView(dataHex: info.dataHex);
      case SolidityMethodInfoTypes.unknownData:
        final info = data.cast<UnknownTransactionData>();
        return _UnknownTransactionDataView(
          dataHex: info.dataHex,
          content: info.content,
        );
      case SolidityMethodInfoTypes.erc20:
      case SolidityMethodInfoTypes.erc20Transfer:
        return _EthereumTransactionERC20DataWidget(data: data.cast());
      case SolidityMethodInfoTypes.nameAndInputs:
        return _EthereumTransactionNameAndInputsWidget(
            data: data.cast(), network: network);
    }
  }
}

class _EthereumTransactionNameAndInputsWidget extends StatelessWidget {
  const _EthereumTransactionNameAndInputsWidget(
      {required this.network, required this.data});
  final SolidityNameAndInputValues data;
  final WalletNetwork network;
  @override
  Widget build(BuildContext context) {
    return ContainerWithBorder(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("method_name".tr, style: context.onPrimaryTextTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
          constraints: null,
          backgroundColor: context.onPrimaryContainer,
          child:
              Text(data.localizationName.tr, style: context.primaryTextTheme.bodyMedium),
        ),
        if (data.inputs.isNotEmpty) ...[
          WidgetConstant.height20,
          Text("inputs".tr, style: context.onPrimaryTextTheme.titleMedium),
          WidgetConstant.height8,
          ...List.generate(data.inputs.length, (i) {
            final value = data.inputs[i];
            return ContainerWithBorder(
                backgroundColor: context.onPrimaryContainer,
                constraints: null,
                child: _SolidityTypesView(
                    value: value,
                    network: network,
                    style: context.primaryTextTheme.bodyMedium));
          })
        ],
      ],
    ));
  }
}

class _SolidityTypesView extends StatelessWidget {
  const _SolidityTypesView({required this.value, required this.network, this.style});
  final dynamic value;
  final WalletNetwork network;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(value.toString(), style: style)),
        if (value is SolidityAddress && network.type == NetworkType.tron)
          TappedTooltipView(
            tooltipWidget: ToolTipView(
                tooltipWidget: (context) {
                  final SolidityAddress addr = value;
                  return Container(
                      constraints: const BoxConstraints(
                          maxWidth: APPConst.tooltipConstrainedWidth),
                      color: context.colors.tertiary,
                      child: Text(
                        addr.toTronAddress().toAddress(),
                        style: context.textTheme.bodyMedium
                            ?.copyWith(color: context.colors.onTertiary),
                      ));
                },
                child: Icon(Icons.help, color: style?.color)),
          )
      ],
    );
  }
}

class _EthereumTransactionERC20DataWidget extends StatelessWidget {
  const _EthereumTransactionERC20DataWidget({required this.data});
  final SolidityERC20MethodInfo data;
  @override
  Widget build(BuildContext context) {
    if (data.type == SolidityMethodInfoTypes.erc20) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("token_info".tr, style: context.textTheme.titleMedium),
          WidgetConstant.height8,
          AccountTokenDetailsView(
              token: data.token,
              onSelectWidget: WidgetConstant.sizedBox,
              radius: APPConst.circleRadius25),
          WidgetConstant.height20,
          Text("transaction_data".tr, style: context.textTheme.titleMedium),
          WidgetConstant.height8,
          ContainerWithBorder(
            child: CopyTextIcon(
              color: context.onPrimaryContainer,
              dataToCopy: data.dataHex,
              widget: SelectableText(data.dataHex,
                  style: context.onPrimaryTextTheme.bodyMedium, minLines: 1, maxLines: 3),
            ),
          )
        ],
      );
    } else {
      final SolidityERC20TransferMethodInfo transferData = data.cast();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("token_info".tr, style: context.textTheme.titleMedium),
          WidgetConstant.height8,
          AccountTokenDetailsView(
              token: data.token,
              onSelectWidget: WidgetConstant.sizedBox,
              radius: APPConst.circleRadius25),
          WidgetConstant.height20,
          ReceiptAddressView(address: transferData.to),
          WidgetConstant.height20,
          Text("transfer_amount".tr, style: context.textTheme.titleMedium),
          Text("transfer_token_desc".tr),
          WidgetConstant.height8,
          ContainerWithBorder(
              child: CoinAndMarketPriceView(
                  balance: transferData.value,
                  style: context.onPrimaryTextTheme.titleMedium,
                  symbolColor: context.onPrimaryContainer,
                  showTokenImage: true))
        ],
      );
    }
  }
}

class _UnknownTransactionDataView extends StatelessWidget {
  const _UnknownTransactionDataView({required this.dataHex, this.content});
  final String dataHex;
  final String? content;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("transaction_data".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
          onRemove: () {},
          enableTap: false,
          onRemoveWidget: CopyTextIcon(
              dataToCopy: dataHex, isSensitive: false, color: context.onPrimaryContainer),
          child: OneLineTextWidget(dataHex,
              maxLine: 2, style: context.onPrimaryTextTheme.bodyMedium),
        ),
        if (content != null) ...[
          WidgetConstant.height20,
          Text("content".tr, style: context.textTheme.titleMedium),
          WidgetConstant.height8,
          ContainerWithBorder(
              onRemove: () {},
              enableTap: false,
              onRemoveWidget: CopyTextIcon(
                  dataToCopy: content!,
                  isSensitive: false,
                  color: context.onPrimaryContainer),
              child: OneLineTextWidget(content!,
                  maxLine: 2, style: context.onPrimaryTextTheme.bodyMedium)),
        ],
      ],
    );
  }
}
