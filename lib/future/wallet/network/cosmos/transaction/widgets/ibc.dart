import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/transaction/operations/ibc.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/transaction/types/transfer.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/transaction/widgets/pick_channel_id.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/transaction/widgets/pick_token.dart';
import 'package:on_chain_wallet/future/wallet/transaction/pages/fee.dart';
import 'package:on_chain_wallet/future/wallet/transaction/pages/live_form_widget.dart';
import 'package:on_chain_wallet/future/wallet/transaction/pages/send_transaction.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/networks/cw20.dart';
import 'transfer.dart';

class CosmosTransactionIbcTransferWidget extends StatelessWidget {
  final CosmosTransactionIbcTransferOperation form;
  const CosmosTransactionIbcTransferWidget({required this.form, super.key});

  @override
  Widget build(BuildContext context) {
    return APPStreamBuilder(
      value: form.pendingIbc.live,
      builder: (context, value) {
        return ConditionalWidget(
            enable: value == null,
            onActive: (context) => _CosmosIbcTransactionFieldsView(form: form),
            onDeactive: (context) => _CosmosCreateIbcTransferView(form: value!));
      },
    );
  }
}

class _CosmosIbcTransactionFieldsView extends StatelessWidget {
  final CosmosTransactionIbcTransferOperation form;
  const _CosmosIbcTransactionFieldsView({required this.form});
  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      LiveFormWidgetList(
        field: form.transfers,
        onCreate: (context, field) {
          return ContainerWithBorder(
            validate: form.transfers.hasValue,
            onRemove: () {
              form.onCreateNewOperation();
            },
            onRemoveIcon: Icon(Icons.add_box, color: context.onPrimaryContainer),
            child: Text("tap_to_add_new_transfer".tr,
                style: context.onPrimaryTextTheme.bodyMedium),
          );
        },
        builder: (context, field, value) {
          return Theme(
            data: context.theme.copyWith(
                dividerColor: context.colors.transparent,
                hoverColor: context.colors.transparent,
                splashColor: context.colors.transparent),
            child: ContainerWithBorder(
                enableTap: false,
                iconAlginment: CrossAxisAlignment.start,
                onRemoveIcon: Icon(Icons.edit, color: context.onPrimaryContainer),
                onRemove: () {
                  form.onEditOperation(value);
                },
                child: APPExpansionListTile(
                  tilePadding: EdgeInsets.zero,
                  title: AccountTokenDetailsWidget(
                    token: value.transfer.token.token,
                    balance: value.transfer.amount,
                    color: context.onPrimaryContainer,
                    radius: APPConst.circleRadius25,
                  ),
                  children: [
                    Container(
                        padding: WidgetConstant.padding10,
                        decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: WidgetConstant.border8),
                        child: _CosmosIbcTransferFieldsView(
                          transfer: value.transfer,
                        ))
                  ],
                )),
          );
        },
      ),
      WidgetConstant.height20,
      LiveFormWidgetMemo(field: form.memo, onUpdateMemo: form.onUpdateMemo),
      WidgetConstant.height20,
      TransactionFeeView(
          controller: form,
          onTapManual: () {
            context
                .openSliverBottomSheet<CosmosTransactionFee>("setup_custom_fee".tr,
                    child: CosmosSetTransferFeeView(
                        currentFee: form.txFee.fee,
                        max: form.getMaxFeeInput(),
                        feeTokens: form.transactionRequirment.feeTokens))
                .then(form.setManualFee);
          }),
      TransactionStateSendTransaction(controller: form)
    ]);
  }
}

class _CosmosCreateIbcTransferView extends StatelessWidget {
  final CosmosIbcTransferForm form;
  const _CosmosCreateIbcTransferView({required this.form});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      Row(children: [
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("setup_transfer".tr, style: context.textTheme.titleMedium),
            Text("add_cosmos_new_ibc_transfer_desc".tr),
          ],
        )),
        IconButton(
            onPressed: () {
              context
                  .openSliverDialog(
                      widget: (context) => DialogTextView(
                          text: "skip_transfer_desc".tr,
                          buttonWidget: DialogDoubleButtonView()),
                      label: 'skip_transfer'.tr)
                  .then((e) {
                if (e != true) return;
                form.controller.onSkipOperation();
              });
            },
            icon: Icon(Icons.cancel))
      ]),
      WidgetConstant.height20,
      LiveFormWidget(
        field: form.destinationChain,
        builder: (context, field, chain) {
          return Column(
            children: [
              AppDropDownBottom(
                  isExpanded: true,
                  onChanged: form.onUpdateDestinationChain,
                  items: {
                    for (final i in form.destinationChains)
                      i: Row(children: [
                        CircleTokenImageView(i.network.token,
                            radius: APPConst.circleRadius12),
                        WidgetConstant.width8,
                        Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [Text(i.network.networkName)],
                        ))
                      ])
                  },
                  hint: field.title,
                  value: chain),
              WidgetConstant.height20,
              APPAnimated(
                  isActive: chain != null,
                  onActive: (context) =>
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        LiveFormWidget(
                          field: form.token,
                          builder: (context, field, value) {
                            return ContainerWithBorder(
                              onRemove: () {
                                context
                                    .openMaxExtendSliverBottomSheet<CW20Token>(
                                      "transfer".tr,
                                      centerContent: false,
                                      bodyBuilder: (sc) => CosmosTransactionPickTokenView(
                                          controller: sc, tokens: form.controller.tokens),
                                    )
                                    .then(form.onUpdateTransferToken);
                              },
                              onRemoveIcon:
                                  Icon(Icons.edit, color: context.onPrimaryContainer),
                              child: AccountTokenDetailsWidget(
                                  token: value.token,
                                  liveBalance: value.streamBalance,
                                  color: context.onPrimaryContainer,
                                  radius: APPConst.circleRadius25),
                            );
                          },
                        ),
                        WidgetConstant.height20,
                        LiveFormWidget(
                          field: form.channelId,
                          builder: (context, field, value) {
                            return ContainerWithBorder(
                              validate: field.hasValue,
                              onRemove: () {
                                context.openMaxExtendSliverBottomSheet("".tr,
                                    bodyBuilder: (scrollController) =>
                                        CosmosPickChannelIdView(
                                          controller: scrollController,
                                          sourceChain: form.controller.account,
                                          destinationChain: chain!,
                                          onSelectChannelId: (p0, p1) {
                                            form.onUpdateChannelId(p1);
                                            context.pop();
                                          },
                                        ));
                              },
                              onRemoveIcon: AddOrEditIconWidget(field.hasValue,
                                  color: context.onPrimaryContainer),
                              child: Text(value ?? "tap_to_input_value".tr,
                                  style: context.onPrimaryTextTheme.bodyMedium),
                            );
                          },
                        ),
                        WidgetConstant.height20,
                        LiveFormWidgetReceiverAddress(
                          field: form.recipient,
                          account: form.destinationChain.value!,
                          onUpdateAddress: form.onUpdateRecipient,
                        ),
                        WidgetConstant.height20,
                        LiveFormWidgetAmount(
                            onUpdateAmountMax: form.getMaxInput,
                            onUpdateAmount: (amount, max) => form.onUpdateAmount(amount),
                            field: form.amount),
                        WidgetConstant.height20,
                        LiveFormWidget(
                          field: form.timeout,
                          builder: (context, field, value) {
                            return ContainerWithBorder(
                              onRemoveIcon:
                                  Icon(Icons.edit, color: context.onPrimaryContainer),
                              onRemove: () async {
                                final time = await showTimePicker(
                                    context: context,
                                    initialTime: form.timeout.value.timeOfDay());
                                form.onUpdateTimeOut(time);
                              },
                              child: Text(form.timeout.value.toDateAndTimeWithSecound(),
                                  style: context.onPrimaryTextTheme.bodyMedium),
                            );
                          },
                        ),
                        WidgetConstant.height20,
                        LiveFormWidget(
                          field: form.memo,
                          builder: (context, field, value) {
                            return ContainerWithBorder(
                              onRemove: () {
                                context
                                    .openSliverBottomSheet<String>(
                                      "transaction_memo".tr,
                                      child: StringWriterView(
                                        defaultValue: value,
                                        title: PageTitleSubtitle(
                                            title: "setup_memo".tr,
                                            body: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text("memo_desc1".tr),
                                                WidgetConstant.height8,
                                                Text("empty_desc".tr),
                                              ],
                                            )),
                                        buttonText: "setup_memo".tr,
                                        label: "memo".tr,
                                      ),
                                    )
                                    .then(form.onUpdateMemo);
                              },
                              onRemoveIcon: ConditionalWidget(
                                enable: !field.hasValue,
                                onDeactive: (context) => Icon(Icons.remove_circle,
                                    color: context.onPrimaryContainer),
                                onActive: (context) => Icon(Icons.add_box,
                                    color: context.onPrimaryContainer),
                              ),
                              child: Text(value ?? "tap_to_add_memo".tr,
                                  style: context.onPrimaryTextTheme.bodyMedium),
                            );
                          },
                        )
                      ]))
            ],
          );
        },
      ),
      APPStreamBuilder(
          value: form.stateStatus,
          builder: (context, value) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ErrorTextContainer(error: value.error),
              AlertTextContainer(message: value.warning),
              Padding(
                padding: WidgetConstant.paddingVertical40,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  FixedElevatedButton(
                      onPressed: form.controller.onUpdateOperations,
                      activePress: value.isReady,
                      child: Text("setup_transfer".tr))
                ]),
              )
            ]);
          })
    ]);
  }
}

class _CosmosIbcTransferFieldsView extends StatelessWidget {
  final CosmosIbcTransfer transfer;
  const _CosmosIbcTransferFieldsView({required this.transfer});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("destination_chain".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      ContainerWithBorder(
          child: AccountTokenDetailsWidget(
              token: transfer.chain.network.token,
              color: context.onPrimaryContainer,
              radius: APPConst.circleRadius25)),
      WidgetConstant.height20,
      Text("channel_id".tr, style: context.textTheme.titleMedium),
      Text("ibc_channel_desc".tr, style: context.textTheme.bodyMedium),
      WidgetConstant.height8,
      ContainerWithBorder(
        child: Text(transfer.channelId, style: context.onPrimaryTextTheme.bodyMedium),
      ),
      WidgetConstant.height20,
      Text("transfer_token".tr, style: context.textTheme.titleMedium),
      Text("select_token_for_transfer".tr, style: context.textTheme.bodyMedium),
      WidgetConstant.height8,
      ContainerWithBorder(
        child: AccountTokenDetailsWidget(
            token: transfer.token.token,
            color: context.onPrimaryContainer,
            radius: APPConst.circleRadius25),
      ),
      WidgetConstant.height20,
      Text("recipient".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      ContainerWithBorder(
          child: ReceiptAddressDetailsView(
              address: transfer.address, color: context.onPrimaryContainer)),
      WidgetConstant.height20,
      Text("amount".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      ContainerWithBorder(
        child: CoinAndMarketPriceView(
            balance: transfer.amount,
            style: context.onPrimaryTextTheme.titleMedium,
            symbolColor: context.onPrimaryContainer,
            showTokenImage: true),
      ),
      WidgetConstant.height20,
      ConditionalWidget(
          enable: transfer.memo != null,
          onActive: (context) =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("setup_memo".tr, style: context.textTheme.titleMedium),
                WidgetConstant.height8,
                ContainerWithBorder(
                  onRemoveIcon: Icon(Icons.edit, color: context.onPrimaryContainer),
                  child: Text(transfer.memo ?? "tap_to_add_memo".tr,
                      style: context.onPrimaryTextTheme.bodyMedium),
                ),
                WidgetConstant.height20,
              ])),
      Text("transaction_timeout".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      ContainerWithBorder(
        onRemoveIcon: Icon(Icons.edit, color: context.onPrimaryContainer),
        child: Text(transfer.timeout.toDateAndTimeWithSecound(),
            style: context.onPrimaryTextTheme.bodyMedium),
      ),
    ]);
  }
}
