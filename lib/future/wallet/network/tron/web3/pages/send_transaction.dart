import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/web3/pages/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/widgets/widgets/fee.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/web3/operations/send_transaction.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/web3_request_page_builder.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain/tron/src/models/contract/base_contract/transaction_type.dart';

class Web3TronSignTransactionStateView extends StatelessWidget {
  final WebTronSendTransactionStateController controller;
  const Web3TronSignTransactionStateView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final transactionData = controller.transactionData;
    final info = transactionData.transactionInfo;
    return MultiSliver(children: [
      ReceiptAddressView(
          address: transactionData.owner,
          title: "tron_owner_contract".tr,
          subtitle: "tron_owner_contract_desc".tr),
      WidgetConstant.height20,
      Text("tron_contract".tr, style: context.textTheme.titleMedium),
      Text("tron_transaction_type".tr),
      WidgetConstant.height8,
      ContainerWithBorder(
        child: Text(info.type.name, style: context.onPrimaryTextTheme.bodyMedium),
      ),
      WidgetConstant.height20,
      ConditionalWidget(
          enable: info.destination != null,
          onActive: (context) =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ReceiptAddressView(
                    address: info.destination,
                    title: "destination".tr,
                    subtitle: "tron_transaction_destination_desc".tr),
                WidgetConstant.height20,
              ])),
      ConditionalWidget(
          enable: info.totalTrxAmount != null,
          onActive: (context) =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TransactionAmountView(
                    amount: info.totalTrxAmount,
                    subtitle: "tron_total_spent_desc".tr,
                    token: controller.network.token),
                WidgetConstant.height20,
              ])),
      ConditionalWidget(
          enable: info.type != TransactionContractType.transferContract,
          onActive: (context) =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _TransactionTypeWidgets(info: info, network: controller.network),
                WidgetConstant.height20,
              ])),
      TronTransactionFeeDataView(controller: controller),
      WidgetConstant.height20,
      ConditionalWidget(
          enable: transactionData.feeLimit != null,
          onActive: (context) =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TransactionAmountView(
                    amount: transactionData.feeLimit,
                    token: controller.network.token,
                    title: "fee_limit".tr,
                    subtitle: "tron_fee_limit_desc".tr),
                WidgetConstant.height20
              ])),
      ConditionalWidget(
          enable: transactionData.memo != null,
          onActive: (context) =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("memo".tr, style: context.textTheme.titleMedium),
                WidgetConstant.height8,
                ContainerWithBorder(
                    child: CopyTextIcon(
                        dataToCopy: transactionData.memo!,
                        color: context.colors.onPrimaryContainer,
                        widget: SelectableText(transactionData.memo!,
                            style: context.onPrimaryTextTheme.bodyMedium,
                            maxLines: 3,
                            minLines: 1))),
                WidgetConstant.height20
              ])),
      Text("transaction_id".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      ContainerWithBorder(
          child:
              Text(transactionData.txId, style: context.onPrimaryTextTheme.bodyMedium)),
      Web3StateAcceptRequestView(controller: controller, title: "sign_transaction".tr),
    ]);
  }
}

class _TransactionTypeWidgets extends StatelessWidget {
  final Web3TronTransactionInfo info;
  final WalletNetwork network;
  const _TransactionTypeWidgets({required this.network, required this.info});

  @override
  Widget build(BuildContext context) {
    return switch (info.type) {
      TransactionContractType.transferContract => WidgetConstant.sizedBox,
      TransactionContractType.transferAssetContract =>
        _TransferAssetView(info: info as Web3TronTransferAssetInfo),
      TransactionContractType.freezeBalanceV2Contract =>
        _FreezeBalanceView(info: info as Web3TronFreezeBalanceInfo),
      TransactionContractType.createSmartContract =>
        _CreateContractInfo(info: info as Web3TronCreateContractInfo),
      TransactionContractType.triggerSmartContract => _TriggerSmartContractInfo(
          network: network,
          info: info as Web3TronTriggerSmartContract,
        ),
      _ => _UnknownContractInfo(info: info as Web3TronUnknowContractInfo)
    };
  }
}

class _TransferAssetView extends StatelessWidget {
  const _TransferAssetView(
      {required this.info, this.tokenTitle, this.tokenSubtitle, this.valueSubtitle});
  final Web3TronTransferAssetInfo info;
  final String? tokenTitle;
  final String? tokenSubtitle;
  final String? valueSubtitle;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tokenTitle ?? "token_transfer".tr, style: context.textTheme.titleMedium),
        if (tokenSubtitle != null) Text(tokenSubtitle!.tr),
        WidgetConstant.height8,
        AccountTokenDetailsView(
            token: info.token,
            onSelectWidget: WidgetConstant.sizedBox,
            radius: APPConst.circleRadius25),
        WidgetConstant.height20,
        TransactionAmountView(
            amount: info.amount, token: info.token.token, subtitle: valueSubtitle)
      ],
    );
  }
}

class _FreezeBalanceView extends StatelessWidget {
  const _FreezeBalanceView({required this.info});
  final Web3TronFreezeBalanceInfo info;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("resource".tr, style: context.textTheme.titleMedium),
      Text("trx_stake_type".tr),
      WidgetConstant.height8,
      ContainerWithBorder(
        child: Text(info.resource.name.camelCase,
            style: context.onPrimaryTextTheme.bodyMedium),
      ),
    ]);
  }
}

class _CreateContractInfo extends StatelessWidget {
  const _CreateContractInfo({required this.info});
  final Web3TronCreateContractInfo info;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (info.callValue != null) ...[
          _TransferAssetView(info: info.callValue!),
          WidgetConstant.height20
        ],
        Text("contract_address".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
            child: Text(info.contractAddress.toAddress(),
                style: context.onPrimaryTextTheme.bodyMedium))
      ],
    );
  }
}

class _UnknownContractInfo extends StatelessWidget {
  const _UnknownContractInfo({required this.info});
  final Web3TronUnknowContractInfo info;
  Map<String, dynamic> get data => info.contractFields;
  @override
  Widget build(BuildContext context) {
    if (info.contractFields.isEmpty) return WidgetConstant.sizedBox;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("contract_information".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
          padding: EdgeInsets.zero,
          child: APPExpansionListTile(
            title: Text("information".tr, style: context.onPrimaryTextTheme.bodyMedium),
            children: List.generate(data.length, (index) {
              final key = data.keys.elementAt(index);
              final value = data[key];
              if (value == null) return WidgetConstant.sizedBox;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ContainerWithBorder(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(key.camelCase, style: context.onPrimaryTextTheme.labelLarge),
                        ContainerWithBorder(
                          backgroundColor: context.onPrimaryContainer,
                          constraints: null,
                          child: CopyTextIcon(
                            dataToCopy: value.toString(),
                            isSensitive: false,
                            color: context.colors.primaryContainer,
                            widget: SelectableText(value.toString(),
                                style: context.primaryTextTheme.bodyMedium,
                                maxLines: 4,
                                minLines: 1),
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
      ],
    );
  }
}

class _TriggerSmartContractInfo extends StatelessWidget {
  final Web3TronTriggerSmartContract info;
  final WalletNetwork network;

  EthereumTransactionDataInfo get data => info.dataInfo;
  const _TriggerSmartContractInfo({required this.info, required this.network});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (info.callValue != null) ...[
          _TransferAssetView(
              info: info.callValue!,
              tokenTitle: "tron_call_token".tr,
              tokenSubtitle: "tron_call_token_desc".tr,
              valueSubtitle: "tron_call_token_value_desc".tr),
          WidgetConstant.height20,
        ],
        Text("transaction_type".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.localizationName.tr, style: context.onPrimaryTextTheme.bodyMedium),
            if (data.selector != null)
              Text(data.selector!, style: context.onPrimaryTextTheme.bodyMedium)
          ],
        )),
        WidgetConstant.height20,
        EthereumTransactionDataWidget(data: data, network: network),
      ],
    );
  }
}
