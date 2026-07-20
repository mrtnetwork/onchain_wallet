import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/transaction/widgets/select_utxos.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/web3/operations/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/web3_request_page_builder.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';

class Web3ZcashSignTransactionStateView extends StatelessWidget {
  final WebZcashSignTransactionStateController controller;
  const Web3ZcashSignTransactionStateView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final transactionData = controller.fixedTransactionData;
    return MultiSliver(children: [
      LiveFormWidget(
        field: controller.totalUtxos,
        builder: (context, field, value) {
          return ContainerWithBorder(
            onRemove: () {
              context.openDialogPage(
                  child: (context) => ZcashTransactionSelectUtxos(controller), "");
            },
            onRemoveIcon: AddOrEditIconWidget(controller.hasUtxos),
            validate: controller.hasUtxos,
            child: ConditionalWidget(
              onDeactive: (context) => Text("tap_to_choose_utxos".tr,
                  style: context.onPrimaryTextTheme.bodyMedium),
              enable: controller.hasUtxos,
              onActive: (context) =>
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CoinAndMarketPriceView(
                    balance: controller.totalUtxos.value,
                    symbolColor: context.onPrimaryContainer,
                    showTokenImage: true,
                    style: context.onPrimaryTextTheme.titleMedium)
              ]),
            ),
          );
        },
      ),
      WidgetConstant.height20,
      Text("recipients".tr, style: context.onPrimaryTextTheme.titleMedium),
      WidgetConstant.height8,
      ...List.generate(transactionData.recipients.length, (index) {
        final re = transactionData.recipients[index];
        return ContainerWithBorder(
          enableTap: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ContainerWithBorder(
                  backgroundColor: context.onPrimaryContainer,
                  child: ReceiptAddressDetailsView(
                      address: re.address, color: context.primaryContainer)),
              ContainerWithBorder(
                  backgroundColor: context.onPrimaryContainer,
                  child: Text(re.protocol.name.tr,
                      style: context.primaryTextTheme.bodyMedium)),
              ConditionalWidgetWithValue(
                  value: re.memo?.content,
                  onValue: (context, memo) => ContainerWithBorder(
                      backgroundColor: context.onPrimaryContainer,
                      child: OneLineTextWidget(memo,
                          style: context.primaryTextTheme.bodyMedium))),
              ContainerWithBorder(
                  onRemoveIcon: Icon(Icons.edit, color: context.primaryContainer),
                  backgroundColor: context.onPrimaryContainer,
                  child: CoinAndMarketPriceView(
                      balance: re.amount,
                      showTokenImage: true,
                      style: context.primaryTextTheme.titleMedium,
                      symbolColor: context.primaryContainer)),
            ],
          ),
        );
      }),
      WidgetConstant.height20,
      LiveFormWidget(
        field: controller.remainingAmount,
        builder: (context, field, value) {
          return APPStreamBuilder(
              value: value.notifier,
              builder: (context, _) {
                return DisabledWidget(
                    disabled: !value.hasAmount,
                    ignoring: true,
                    onActive: (context, _) => ContainerWithBorder(
                          iconAlginment: CrossAxisAlignment.start,
                          enableTap: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ContainerWithBorder(
                                  onRemove: () {
                                    context
                                        .selectOrSwitchAccount<IZcashAddress>(
                                            account: controller.account,
                                            showMultiSig: true)
                                        .then((v) {
                                      if (v == null) return;
                                      controller.onUpdateRemainingAccount(v);
                                    });
                                  },
                                  onRemoveIcon:
                                      Icon(Icons.edit, color: context.primaryContainer),
                                  backgroundColor: context.onPrimaryContainer,
                                  child: ReceiptAddressDetailsView(
                                      address: value.recipient,
                                      color: context.primaryContainer)),
                              AppDropDownBottomWithBorder(
                                key: ValueKey(value.recipient),
                                backgroundColor: context.onPrimaryContainer,
                                reverseColor: context.primaryContainer,
                                isExpanded: true,
                                onChanged: (protocol) {
                                  controller.onUpdateRemainingPorocol(protocol);
                                },
                                value: value.addrProtocol,
                                label: "protocol".tr,
                                isDense: false,
                                selectedItemBuilder: {
                                  for (final i in value.supportedProtocols)
                                    i: Text(i.name.tr)
                                },
                                items: {
                                  for (final i in value.supportedProtocols)
                                    i: Text(i.name.tr,
                                        style: context.primaryTextTheme.bodyMedium)
                                },
                              ),
                              ConditionalWidget(
                                  enable: value.allowMemo,
                                  onActive: (context) => ContainerWithBorder(
                                      backgroundColor: context.onPrimaryContainer,
                                      onRemoveWidget: AddOrRemoveIconWidget(
                                        value.hasMemo,
                                        color: context.primaryContainer,
                                      ),
                                      onRemove: () {
                                        if (value.hasMemo) {
                                          value.onRemoveMemo();
                                          return;
                                        }
                                        context
                                            .openSliverBottomSheet<String>(
                                                "transaction_memo".tr,
                                                child: StringWriterView(
                                                    title: PageTitleSubtitle(
                                                        title: "setup_memo".tr,
                                                        body: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment.start,
                                                          children: [
                                                            Text("memo_desc1".tr),
                                                          ],
                                                        )),
                                                    buttonText: "setup_memo".tr,
                                                    label: "memo".tr,
                                                    customForm: value.onValidateMemo))
                                            .then(value.onUpdateMemo);
                                      },
                                      child: APPAnimatedWithValue<String>(
                                        value: value.memo?.content,
                                        isExpanded: true,
                                        onValue: (context, value) => OneLineTextWidget(
                                            value,
                                            style: context.primaryTextTheme.bodyMedium),
                                        onNull: (context) => Text("tap_to_add_memo".tr,
                                            style: context.primaryTextTheme.bodyMedium),
                                      ))),
                              ContainerWithBorder(
                                  validate: !value.amount.isNegative,
                                  onRemoveIcon:
                                      Icon(Icons.edit, color: context.primaryContainer),
                                  backgroundColor: context.onPrimaryContainer,
                                  child: CoinAndMarketPriceView(
                                      balance: value.amount,
                                      showTokenImage: true,
                                      style: context.primaryTextTheme.titleMedium,
                                      symbolColor: context.primaryContainer)),
                            ],
                          ),
                        ));
              });
        },
      ),
      ConditionalWidget(
          enable: transactionData.transparentMemos.isNotEmpty,
          onActive: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("transparent_memos".tr, style: context.textTheme.titleMedium),
                  WidgetConstant.height8,
                  ...List.generate(transactionData.transparentMemos.length, (index) {
                    final memo = transactionData.transparentMemos[index];
                    return ContainerWithBorder(
                        child: OneLineTextWidget(memo.memo.content,
                            style: context.onPrimaryTextTheme.bodyMedium));
                  })
                ],
              )),
      WidgetConstant.height20,
      TransactionFeeWidget(
          fee: controller.txFee,
          onRetryFeeEstimate: controller.estimateFee,
          getMaxFeeInput: controller.getMaxFeeInput),
      Web3StateAcceptRequestView(controller: controller, title: "send_transaction".tr),
    ]);
  }
}
