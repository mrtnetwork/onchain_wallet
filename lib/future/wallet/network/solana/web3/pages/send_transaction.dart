import 'package:flutter/material.dart';
import 'package:on_chain/solana/src/rpc/models/models/simulate_transaction_response.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/web3/operations/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/web3/types/transaction.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/web3_request_page_builder.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';

class Web3SolanaSignOrSendTransactionsStateView extends StatelessWidget {
  final WebSolanaSignTransactionStateController controller;
  const Web3SolanaSignOrSendTransactionsStateView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final transactionData = controller.transactionData;
    return MultiSliver(children: [
      ConditionalWidget(
          enable: transactionData.isMultipleTransaction,
          onActive: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("transactions".tr, style: context.textTheme.titleMedium),
                  Text("multiple_transaction_desc".tr),
                  WidgetConstant.height20,
                ],
              )),
      SliverPadding(
        padding: transactionData.isMultipleTransaction
            ? WidgetConstant.paddingHorizontal20
            : EdgeInsets.zero,
        sliver: SliverList.separated(
            separatorBuilder: (context, index) => WidgetConstant.divider,
            itemBuilder: (context, index) {
              final message = transactionData.messagess[index];
              return _SolanaWeb3MessageView(message: message, controller: controller);
            },
            itemCount: transactionData.messagess.length),
      ),
      WidgetConstant.height20,
      Text("total_transaction_fee".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      APPStreamBuilder(
        value: controller.totalFee,
        builder: (context, value) {
          return Shimmer(
              onActive: (e, context) => ContainerWithBorder(
                    enableTap: false,
                    onRemove: () {},
                    onRemoveIcon: ConditionalWidget(
                        enable: controller.hasFeeError,
                        onActive: (context) =>
                            Icon(Icons.error, color: context.colors.onPrimaryContainer)),
                    child: CoinAndMarketPriceView(
                        balance: value,
                        style: context.onPrimaryTextTheme.titleMedium,
                        symbolColor: context.onPrimaryContainer,
                        showTokenImage: true),
                  ),
              enable: controller.stateStatus.value.isReady);
        },
      ),
      Web3StateAcceptRequestView(
          controller: controller,
          title: transactionData.isSend
              ? (transactionData.isMultipleTransaction
                  ? "send_transactions".tr
                  : "send_transaction".tr)
              : (transactionData.isMultipleTransaction
                  ? "sign_transactions".tr
                  : "sign_transaction".tr)),
    ]);
  }
}

class _SolanaWeb3MessageView extends StatelessWidget {
  const _SolanaWeb3MessageView({required this.message, required this.controller});
  final SolanaWeb3TransactionInfo message;
  final WebSolanaSignTransactionStateController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("account".tr, style: context.textTheme.titleMedium),
        Text("web3_request_account_desc".tr),
        WidgetConstant.height8,
        ContainerWithBorder(
            child: AddressDetailsView(
          address: message.signer,
          color: context.onPrimaryContainer,
        )),
        WidgetConstant.height20,
        Text("instructions".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
            child: APPExpansionListTile(
          title: Text("instructions".tr, style: context.onPrimaryTextTheme.bodyMedium),
          children: List.generate(message.instructions.length, (index) {
            final instruction = message.instructions[index];
            final isLastIndex = index == message.instructions.length - 1;
            return Container(
              // color: ,
              decoration: BoxDecoration(
                  color: context.colors.onPrimaryContainer,
                  borderRadius: WidgetConstant.border8),
              padding: WidgetConstant.padding10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("program_id".tr, style: context.primaryTextTheme.titleMedium),
                  Text(instruction.layout.instruction.name,
                      style: context.primaryTextTheme.bodyMedium),
                  WidgetConstant.height8,
                  ContainerWithBorder(
                      child: CopyTextIcon(
                    dataToCopy: instruction.programAddress.address,
                    color: context.onPrimaryContainer,
                    widget: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          instruction.layout.instruction.programName,
                          style: context.onPrimaryTextTheme.labelLarge,
                        ),
                        OneLineTextWidget(instruction.programAddress.address,
                            style: context.onPrimaryTextTheme.bodyMedium)
                      ],
                    ),
                  )),
                  if (instruction.content != null) ...[
                    WidgetConstant.height20,
                    Text("content".tr, style: context.primaryTextTheme.titleMedium),
                    WidgetConstant.height8,
                    APPExpansionListTile(
                        color: context.primaryContainer,
                        reverse: context.onPrimaryContainer,
                        title: Text("content".tr,
                            style: context.onPrimaryTextTheme.bodyMedium),
                        children: [
                          ListView.separated(
                              shrinkWrap: true,
                              physics: WidgetConstant.noScrollPhysics,
                              itemBuilder: (context, index) {
                                final key = instruction.content!.keys.elementAt(index);
                                final value = instruction.content![key];
                                if (value == null) {
                                  return WidgetConstant.sizedBox;
                                }
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ContainerWithBorder(
                                      backgroundColor: context.onPrimaryContainer,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(key.camelCase,
                                              style:
                                                  context.primaryTextTheme.titleMedium),
                                          WidgetConstant.height8,
                                          ContainerWithBorder(
                                              backgroundColor:
                                                  context.colors.primaryContainer,
                                              constraints: null,
                                              child: LargeTextContainer(
                                                  color: context.onPrimaryContainer,
                                                  text: value.toString())),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                              separatorBuilder: (context, index) =>
                                  Divider(color: context.onPrimaryContainer),
                              itemCount: instruction.content!.length)
                        ]),
                  ],
                  if (!isLastIndex) ...[
                    Divider(color: context.colors.onPrimaryContainer),
                    WidgetConstant.height8,
                  ]
                ],
              ),
            );
          }),
        )),
        WidgetConstant.height20,
        Text("simulate_transaction".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        APPStreamBuilder(
            value: message.notifier,
            builder: (context, _) {
              final status = message.status;
              return Shimmer(
                  onActive: (e, context) => ContainerWithBorder(
                        onRemoveWidget: IconButton(
                          onPressed: status.canRetry ? message.simulate : null,
                          icon: switch (status) {
                            SolanaWeb3SimulationStatus.pending => WidgetConstant.sizedBox,
                            SolanaWeb3SimulationStatus.success =>
                              Icon(Icons.check_circle, color: context.onPrimaryContainer),
                            SolanaWeb3SimulationStatus.error =>
                              Icon(Icons.error, color: context.colors.error),
                            SolanaWeb3SimulationStatus.simulateError =>
                              Icon(Icons.error, color: context.colors.error),
                            SolanaWeb3SimulationStatus.idle =>
                              Icon(Icons.refresh, color: context.onPrimaryContainer)
                          },
                        ),
                        enableTap: status.canRetry,
                        onRemove: () {
                          if (status.canRetry) {
                            message.simulate();
                          }
                        },
                        child: _SimulateInfo(message),
                      ),
                  enable: !message.status.isPending);
            }),
        WidgetConstant.height20,
        Text("transaction_fee".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        APPStreamBuilder(
          value: message.notifier,
          builder: (context, value) {
            // final status = message.status;
            final feeStatus = message.feeStatus;
            return Shimmer(
                onActive: (_, context) => ContainerWithBorder(
                      onRemoveWidget: IconButton(
                        onPressed: feeStatus.canRetry ? message.getFee : null,
                        icon: switch (feeStatus) {
                          SolanaWeb3FeeStatus.pending => SizedBox(
                              width: APPConst.double20,
                              height: APPConst.double20,
                              child: CircularProgressIndicator(
                                  color: context.onPrimaryContainer),
                            ),
                          SolanaWeb3FeeStatus.success =>
                            Icon(Icons.check_circle, color: context.onPrimaryContainer),
                          SolanaWeb3FeeStatus.error =>
                            Icon(Icons.error, color: context.colors.error),
                          SolanaWeb3FeeStatus.idle =>
                            Icon(Icons.refresh, color: context.onPrimaryContainer)
                        },
                      ),
                      onRemove: () {
                        if (feeStatus.canRetry) {
                          message.getFee();
                        }
                      },
                      child: _FeeInfo(message: message),
                    ),
                enable: !message.feeStatus.isPending);
          },
        ),
        APPStreamBuilder(
            value: message.notifier,
            builder: (context, _) =>
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  WidgetConstant.height20,
                  Text("change_balance".tr, style: context.textTheme.titleMedium),
                  Text("solana_change_balance_desc".tr),
                  WidgetConstant.height8,
                  ContainerWithBorder(
                    onRemove:
                        controller.transactionData.isMultipleWithSameOwner ? () {} : null,
                    enableTap: false,
                    onRemoveWidget: TappedTooltipView(
                        tooltipWidget: ToolTipView(
                            message: "solana_change_balance_desc2".tr,
                            child: Icon(Icons.warning, color: context.colors.tertiary))),
                    child: CoinAndMarketPriceView(
                        balance: message.accountChange,
                        style: context.onPrimaryTextTheme.titleMedium,
                        symbolColor: context.onPrimaryContainer,
                        showTokenImage: true),
                  ),
                ])),
      ],
    );
  }
}

class _SimulateInfo extends StatelessWidget {
  const _SimulateInfo(this.message);
  final SolanaWeb3TransactionInfo message;
  SimulateTranasctionResponse get simulate => message.simulateInfo;
  @override
  Widget build(BuildContext context) {
    final status = message.status;
    return Theme(
      data: context.theme.copyWith(dividerColor: context.colors.transparent),
      child: APPAnimatedSwitcher(enable: status, widgets: {
        SolanaWeb3SimulationStatus.success: (context) => APPExpansionListTile(
              title: Text("transaction_simulation_success".tr,
                  style: context.onPrimaryTextTheme.bodyMedium),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ContainerWithBorder(
                        backgroundColor: context.onPrimaryContainer,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.max,
                            children: List.generate(simulate.logs?.length ?? 0, (index) {
                              final log = simulate.logs![index];
                              return Text(log,
                                  style: context.primaryTextTheme.bodyMedium);
                            })),
                      ),
                    ),
                  ],
                )
              ],
            ),
        SolanaWeb3SimulationStatus.simulateError: (context) => APPExpansionListTile(
              trailing: TappedTooltipView(
                  tooltipWidget: ToolTipView(
                message: simulate.err?.toString() ?? "",
                child: Icon(Icons.error, color: context.onPrimaryContainer),
              )),
              title: Text("transaction_simulation_failed".tr,
                  style: context.onPrimaryTextTheme.bodyMedium),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ContainerWithBorder(
                        backgroundColor: context.onPrimaryContainer,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.max,
                            children: List.generate(simulate.logs?.length ?? 0, (index) {
                              final log = simulate.logs![index];
                              return Text(log,
                                  style: context.primaryTextTheme.bodyMedium);
                            })),
                      ),
                    ),
                  ],
                )
              ],
            ),
        SolanaWeb3SimulationStatus.pending: (context) => FullWidthWrapper(
            child: Text("transaction_simulate_please_wait".tr,
                style: context.onPrimaryTextTheme.bodyMedium)),
        SolanaWeb3SimulationStatus.error: (context) => FullWidthWrapper(
            child: Text("transaction_simulation_failed_retry".tr,
                style: context.onPrimaryTextTheme.bodyMedium)),
      }),
    );
  }
}

class _FeeInfo extends StatelessWidget {
  const _FeeInfo({required this.message});
  final SolanaWeb3TransactionInfo message;
  @override
  Widget build(BuildContext context) {
    final status = message.feeStatus;
    return Theme(
      data: context.theme.copyWith(dividerColor: context.colors.transparent),
      child: APPAnimatedSwitcher<SolanaWeb3FeeStatus>(
          width: context.mediaQuery.size.width,
          enable: status,
          widgets: {
            SolanaWeb3FeeStatus.success: (context) => CoinAndMarketPriceView(
                balance: message.fee,
                style: context.onPrimaryTextTheme.titleMedium,
                showTokenImage: true,
                symbolColor: context.onPrimaryContainer),
            SolanaWeb3FeeStatus.pending: (context) => Text(
                  "estimating_fee_please_wait".tr,
                  style: context.onPrimaryTextTheme.bodyMedium,
                ),
            SolanaWeb3FeeStatus.error: (context) => Text("fee_estimate_failed".tr,
                style: context.onPrimaryTextTheme.bodyMedium),
          }),
    );
  }
}
