import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/transaction/widgets/pick_token.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/web3/operations/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/web3/types/fee.dart';
import 'package:on_chain_wallet/future/wallet/transaction/pages/live_form_widget.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/web3_request_page_builder.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/networks/cw20.dart';

class Web3CosmosSignOrSendTransactionsStateView extends StatelessWidget {
  final WebCosmosSignTransactionStateController controller;
  const Web3CosmosSignOrSendTransactionsStateView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final transactionData = controller.transactionData;
    final messages = transactionData.messages;
    return MultiSliver(children: [
      Text("messages".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      ListView.separated(
          shrinkWrap: true,
          physics: WidgetConstant.noScrollPhysics,
          itemBuilder: (context, index) {
            final msg = messages[index];
            return APPExpansionListTile(
              title: Text(msg.typeUrl),
              children: [
                ContainerWithBorder(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WidgetConstant.height20,
                      Text("content".tr, style: context.onPrimaryTextTheme.titleMedium),
                      WidgetConstant.height8,
                      ContainerWithBorder(
                          onRemove: () {
                            context.openDialogPage(
                              "message_content".tr,
                              child: (context) => APPTextView(
                                  text: msg.value, title: "message_content".tr),
                            );
                          },
                          onRemoveIcon: Icon(Icons.code, color: context.primaryContainer),
                          backgroundColor: context.onPrimaryContainer,
                          child: SelectableText(msg.value,
                              style: context.primaryTextTheme.bodyMedium,
                              maxLines: 3,
                              minLines: 1)),
                    ],
                  ),
                )
              ],
            );
          },
          separatorBuilder: (context, index) => WidgetConstant.divider,
          itemCount: messages.length),
      APPStreamBuilder(
          value: controller.fee.notifier,
          builder: (context, _) {
            final fee = controller.fee;
            return ConditionalWidget(
                enable: fee.allowSimulate,
                onActive: (context) =>
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      WidgetConstant.height20,
                      Text("simulate_transaction".tr,
                          style: context.textTheme.titleMedium),
                      WidgetConstant.height8,
                      Shimmer(
                          onActive: (enable, context) {
                            return APPAnimated(
                              isActive: true,
                              onActive: (context) => ConditionalWidget(
                                  key: ValueKey(fee.simulateStatus),
                                  enable: fee.simulateStatus.isSuccess,
                                  onActive: (context) {
                                    return _SimulateView(fee.simulate!.simulate!);
                                  },
                                  onDeactive: (context) => ContainerWithBorder(
                                        errorIcon: Icons.refresh,
                                        validate: fee.simulateStatus.isSuccess,
                                        validateText: fee.simulate?.simulateError,
                                        onTapError: () {
                                          controller.simulateTransaction();
                                        },
                                        child: APPAnimatedSwitcher<
                                            CosmosWeb3TransactionFeeStatus>(
                                          enable: fee.simulateStatus,
                                          widgets: {
                                            CosmosWeb3TransactionFeeStatus.pending:
                                                (context) => FullWidthWrapper(
                                                    child: Text(
                                                        "transaction_simulate_please_wait"
                                                            .tr,
                                                        style: context.onPrimaryTextTheme
                                                            .bodyMedium)),
                                            CosmosWeb3TransactionFeeStatus.failed:
                                                (context) => FullWidthWrapper(
                                                      child: Text(
                                                          "transaction_simulation_failed"
                                                              .tr,
                                                          style: context
                                                              .onPrimaryTextTheme
                                                              .bodyMedium),
                                                    ),
                                          },
                                        ),
                                      )),
                            );
                          },
                          enable: !fee.simulateStatus.isProgress)
                    ]));
          }),
      WidgetConstant.height20,
      LiveFormWidgetMemo(
          field: controller.memo,
          onUpdateMemo: controller.onUpdateMemo,
          onRemoveMemo: controller.onRemoveMemo),
      WidgetConstant.height20,
      _FeeView(form: controller),
      Web3StateAcceptRequestView(controller: controller, title: "sign_transaction".tr),
    ]);
  }
}

class _FeeView extends StatelessWidget {
  CosmosWeb3TransactionFeeInfo get feeInfo => form.fee;
  final WebCosmosSignTransactionStateController form;
  const _FeeView({required this.form});

  @override
  Widget build(BuildContext context) {
    return APPStreamBuilder(
      value: feeInfo.notifier,
      builder: (context, value) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("transaction_fee".tr, style: context.textTheme.titleMedium),
            WidgetConstant.height8,
            ContainerWithBorder(
              validate: feeInfo.status.isReady,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WidgetConstant.height20,
                  Text("gas_limit".tr, style: context.onPrimaryTextTheme.titleMedium),
                  WidgetConstant.height8,
                  ContainerWithBorder(
                    backgroundColor: context.onPrimaryContainer,
                    onRemoveIcon: Icon(Icons.edit, color: context.primaryContainer),
                    onRemove: () {
                      context
                          .openSliverBottomSheet<BigRational>(
                            "gas_limit".tr,
                            child: NumberWriteView(
                                defaultValue: feeInfo.gasLimitAsBigRational,
                                allowDecimal: false,
                                allowSign: false,
                                title: PageTitleSubtitle(
                                    title: "gas_limit".tr,
                                    body: Text("cosmos_gas_limit_desc".tr)),
                                buttonText: "setup_input".tr,
                                label: "gas_limit".tr),
                          )
                          .then(feeInfo.onUpdateGasLimit);
                    },
                    child: Text(form.fee.gasLimit.toString(),
                        style: context.primaryTextTheme.bodyMedium),
                  ),
                  WidgetConstant.height20,
                  Text("fee_tokens".tr, style: context.onPrimaryTextTheme.titleMedium),
                  WidgetConstant.height8,
                  ListView.separated(
                      physics: WidgetConstant.noScrollPhysics,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        final fee = feeInfo.fees[index];
                        return ContainerWithBorder(
                          onRemove: () {},
                          enableTap: false,
                          onRemoveIcon: IconButton(
                              onPressed: () {
                                feeInfo.onRemoveFee(fee);
                              },
                              icon: Icon(Icons.remove_circle,
                                  color: context.primaryContainer)),
                          backgroundColor: context.onPrimaryContainer,
                          child: Column(children: [
                            ContainerWithBorder(
                              backgroundColor: context.primaryContainer,
                              child: AccountTokenDetailsWidget(
                                  token: fee.token.token,
                                  color: context.onPrimaryContainer,
                                  radius: APPConst.circleRadius25),
                            ),
                            ContainerWithBorder(
                                backgroundColor: context.primaryContainer,
                                validate: fee.hasAmount,
                                onRemoveIcon:
                                    Icon(Icons.edit, color: context.onPrimaryContainer),
                                onRemove: () {
                                  context
                                      .setupAmount(
                                          title: "fee_amount".tr,
                                          token: fee.token.token,
                                          max: fee.token.balance.balance)
                                      .then((v) => feeInfo.onUpdateFeeAmount(fee, v));
                                },
                                child: CoinAndMarketPriceView(
                                    balance: fee.feeAmount,
                                    style: context.onPrimaryTextTheme.titleMedium,
                                    symbolColor: context.onPrimaryContainer)),
                          ]),
                        );
                      },
                      separatorBuilder: (context, index) => WidgetConstant.divider,
                      itemCount: feeInfo.fees.length),
                  APPAnimated(
                      isActive: feeInfo.allowAddFee,
                      onDeactive: (context) => WidgetConstant.sizedBox,
                      onActive: (context) => ContainerWithBorder(
                            backgroundColor: context.onPrimaryContainer,
                            onRemoveIcon:
                                Icon(Icons.add_box, color: context.primaryContainer),
                            child: Text("tap_to_add_new_fee_token".tr,
                                style: context.primaryTextTheme.bodyMedium),
                            onRemove: () {
                              context
                                  .openMaxExtendSliverBottomSheet<CW20Token>(
                                    "fee_token".tr,
                                    centerContent: false,
                                    bodyBuilder: (sc) => CosmosTransactionPickTokenView(
                                        tokens: feeInfo.feeTokens, controller: sc),
                                  )
                                  .then(feeInfo.onAddFeeToken);
                            },
                          )),
                  WidgetConstant.height20,
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SimulateView extends StatelessWidget {
  final CosmosWeb3SimulateInfos simulate;
  const _SimulateView(this.simulate);

  @override
  Widget build(BuildContext context) {
    return APPExpansionListTile(
      title: Text("transaction_simulation_success".tr,
          style: context.onPrimaryTextTheme.bodyMedium),
      children: [
        ContainerWithBorder(
            backgroundColor: context.onPrimaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("gas_limit".tr, style: context.primaryTextTheme.titleMedium),
                WidgetConstant.height8,
                ContainerWithBorder(
                  child: Text(simulate.gasUsed.toString(),
                      style: context.onPrimaryTextTheme.bodyMedium),
                ),
                if (simulate.log != null) ...[
                  WidgetConstant.height8,
                  Text("log".tr, style: context.primaryTextTheme.titleMedium),
                  WidgetConstant.height8,
                  ContainerWithBorder(
                    child: CopyableTextWidget(
                      text: simulate.log ?? '',
                      color: context.onPrimaryContainer,
                      widget: SelectableText(
                        simulate.log ?? '',
                        minLines: 1,
                        maxLines: 3,
                        style: context.onPrimaryTextTheme.bodyMedium,
                      ),
                    ),
                  ),
                ],
                if (simulate.events.isNotEmpty) ...[
                  WidgetConstant.height20,
                  Text("events".tr, style: context.primaryTextTheme.titleMedium),
                  WidgetConstant.height8,
                  ContainerWithBorder(
                    onRemoveIcon: Icon(
                      Icons.open_in_new,
                      color: context.onPrimaryContainer,
                    ),
                    onRemove: () {
                      context.openSliverDialog(
                          sliver: (context) => _EventsView(simulate.events),
                          label: "events".tr);
                    },
                    child: Text("tap_to_show_events".tr,
                        style: context.onPrimaryTextTheme.bodyMedium),
                  ),
                ],
                if (simulate.messageResponse.isNotEmpty) ...[
                  WidgetConstant.height20,
                  Text("messages_response".tr,
                      style: context.primaryTextTheme.titleMedium),
                  WidgetConstant.height8,
                  ContainerWithBorder(
                    onRemoveIcon: Icon(
                      Icons.open_in_new,
                      color: context.onPrimaryContainer,
                    ),
                    onRemove: () {
                      context.openSliverDialog(
                          widget: (context) =>
                              _MessageResponseView(simulate.messageResponse),
                          label: "messages_response".tr);
                    },
                    child: Text("tap_to_show_response".tr,
                        style: context.onPrimaryTextTheme.bodyMedium),
                  ),
                ],
              ],
            ))
      ],
    );
  }
}

class _EventsView extends StatelessWidget {
  final List<CosmosWeb3SimulateEvent> events;
  const _EventsView(this.events);

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
        itemBuilder: (context, index) {
          final event = events[index];
          return ContainerWithBorder(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("type".tr, style: context.onPrimaryTextTheme.titleMedium),
                WidgetConstant.height8,
                ContainerWithBorder(
                  backgroundColor: context.onPrimaryContainer,
                  child: CopyableTextWidget(
                    text: event.type,
                    color: context.primaryContainer,
                    widget: SelectableText(event.type,
                        style: context.primaryTextTheme.bodyMedium),
                  ),
                ),
                WidgetConstant.height20,
                Text("key".tr, style: context.onPrimaryTextTheme.titleMedium),
                WidgetConstant.height8,
                ContainerWithBorder(
                  backgroundColor: context.onPrimaryContainer,
                  child: CopyableTextWidget(
                    text: event.key,
                    color: context.primaryContainer,
                    widget: SelectableText(event.key,
                        style: context.primaryTextTheme.bodyMedium),
                  ),
                ),
                WidgetConstant.height20,
                Text("value".tr, style: context.onPrimaryTextTheme.titleMedium),
                WidgetConstant.height8,
                ContainerWithBorder(
                  backgroundColor: context.onPrimaryContainer,
                  child: CopyableTextWidget(
                    text: event.value,
                    color: context.primaryContainer,
                    widget: SelectableText(event.value,
                        style: context.primaryTextTheme.bodyMedium),
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (context, index) {
          return WidgetConstant.divider;
        },
        itemCount: events.length);
  }
}

class _MessageResponseView extends StatelessWidget {
  final List<CosmosWeb3SimulateMessageResponse> messages;
  const _MessageResponseView(this.messages);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        shrinkWrap: true,
        physics: WidgetConstant.noScrollPhysics,
        itemBuilder: (context, index) {
          final message = messages[index];
          return ContainerWithBorder(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("type".tr, style: context.onPrimaryTextTheme.titleMedium),
                WidgetConstant.height8,
                ContainerWithBorder(
                  backgroundColor: context.onPrimaryContainer,
                  child: CopyableTextWidget(
                    text: message.typeUrl,
                    color: context.primaryContainer,
                    widget: SelectableText(
                      message.typeUrl,
                      style: context.primaryTextTheme.bodyMedium,
                      minLines: 1,
                      maxLines: 5,
                    ),
                  ),
                ),
                WidgetConstant.height20,
                Text("content".tr, style: context.onPrimaryTextTheme.titleMedium),
                WidgetConstant.height8,
                ContainerWithBorder(
                  backgroundColor: context.onPrimaryContainer,
                  child: CopyableTextWidget(
                    text: message.response,
                    color: context.primaryContainer,
                    widget: SelectableText(
                      message.response,
                      style: context.primaryTextTheme.bodyMedium,
                      minLines: 1,
                      maxLines: 5,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (context, index) {
          return WidgetConstant.divider;
        },
        itemCount: messages.length);
  }
}
