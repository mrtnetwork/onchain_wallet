import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/widgets/prick_token.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/widgets/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/widgets/substrate_transaction_fee.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:polkadot_dart/polkadot_dart.dart';

class SubstrateTransactionTransferWidget extends StatelessWidget {
  final SubstrateTransactionTransferOperation form;
  final BuildContext mainContext;
  const SubstrateTransactionTransferWidget(
      {required this.form, required this.mainContext, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      WidgetConstant.height20,
      LiveFormWidgetList(
          field: form.recipients,
          onCreate: (context, field) {
            if (!form.allowAddTransfer) return null;
            return LiveWidgetAddNewTransferDetails<BaseSubstrateAddress>(
                onUpdateAddresses: form.onUpdateRecipients,
                account: form.account,
                isReady: field.hasValue,
                onFilterAccount: form.filterAccount,
                multipleSelect: true);
          },
          builder: (context, field, value) {
            return APPStreamBuilder(
                value: value.notifier,
                builder: (context, _) {
                  return CustomizedContainer(
                    onTapStackIcon: () {
                      form.onRemoveRecipients(value);
                    },
                    onStackIcon: Icons.remove_circle,
                    reverseColor: context.colors.onPrimaryContainer,
                    validate: value.hasAmount,
                    enableTap: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ConditionalWidget(
                            enable: value.token.transferMethod.isNotEmpty,
                            onActive: (context) => AppDropDownBottomWithBorder<
                                    SubstrateCallPalletTransferMethod>(
                                  backgroundColor: context.onPrimaryContainer,
                                  reverseColor: context.primaryContainer,
                                  key: ValueKey(value.token),
                                  items: {
                                    for (final i in value.token.transferMethod)
                                      i: Text(i.method.camelCase,
                                          style: context.primaryTextTheme.bodyMedium)
                                  },
                                  selectedItemBuilder: {
                                    for (final i in value.token.transferMethod)
                                      i: Text(i.method.camelCase)
                                  },
                                  value: value.method,
                                  onChanged: (v) => form.onUpdateTransferMethod(value, v),
                                )),
                        ContainerWithBorder(
                            backgroundColor: context.onPrimaryContainer,
                            child: ReceiptAddressDetailsView(
                                address: value.recipient,
                                color: context.primaryContainer)),
                        ConditionalWidget(
                            enable: form.supportAssetTransfer,
                            onActive: (context) => ContainerWithBorder(
                                  backgroundColor: context.onPrimaryContainer,
                                  onRemove: () {
                                    context
                                        .openMaxExtendSliverBottomSheet<
                                            SubstrateTokenDetails>(
                                          "fee_token".tr,
                                          centerContent: false,
                                          bodyBuilder: (sc) =>
                                              SubstrateTransactionPickTokenView(
                                                  controller: sc,
                                                  tokens: form.tokens
                                                      .map((e) => e.tokenDetails)
                                                      .toList()),
                                        )
                                        .then((v) => form.onUpdateToken(value, v));
                                  },
                                  onRemoveIcon: AddOrEditIconWidget(true,
                                      color: context.primaryContainer),
                                  child: AccountTokenDetailsWidget(
                                      color: context.primaryContainer,
                                      token: value.token.token,
                                      liveBalance: value.token.tokenDetails.balance,
                                      radius: APPConst.circleRadius25),
                                )),
                        ContainerWithBorder(
                            onRemove: () {
                              final max = form.getMaxInput(value);
                              context
                                  .setupAmount(token: value.token.token, max: max)
                                  .then((amount) {
                                if (amount == null) return;
                                form.onUpdateAmount(value, amount, amount == max);
                              });
                            },
                            // validate: transfer.hasAmount,
                            onRemoveIcon:
                                Icon(Icons.edit, color: context.primaryContainer),
                            backgroundColor: context.onPrimaryContainer,
                            child: CoinAndMarketPriceView(
                                balance: value.amount,
                                style: context.primaryTextTheme.titleMedium,
                                showTokenImage: true,
                                symbolColor: context.primaryContainer)),
                      ],
                    ),
                  );
                });
          }),
      ConditionalWidget(
          enable: form.supportBatch,
          onActive: (context) =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                WidgetConstant.height20,
                LiveFormWidgetList(
                    field: form.memos,
                    builder: (context, field, value) => ContainerWithBorder(
                        onRemove: () {
                          form.onRemoveMemo(value);
                        },
                        onRemoveIcon:
                            Icon(Icons.remove_circle, color: context.onPrimaryContainer),
                        child: Text(value, style: context.onPrimaryTextTheme.bodyMedium)),
                    onCreate: (context, field) {
                      return ContainerWithBorder(
                          onRemoveIcon:
                              Icon(Icons.add_box, color: context.onPrimaryContainer),
                          onRemove: () {
                            context
                                .openSliverBottomSheet<String>(
                                  "transaction_memo".tr,
                                  child: StringWriterView(
                                      title: PageTitleSubtitle(
                                          title: "setup_memo".tr,
                                          body: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text("memo_desc1".tr),
                                              WidgetConstant.height8,
                                              Text("empty_desc".tr),
                                            ],
                                          )),
                                      buttonText: "setup_memo".tr,
                                      label: "memo".tr),
                                )
                                .then(form.onUpdateMemo);
                          },
                          child: Text("tap_to_add_memo".tr,
                              style: context.onPrimaryTextTheme.bodyMedium));
                    }),
              ])),
      WidgetConstant.height20,
      APPStreamBuilder(
        value: form.feeToken.live,
        builder: (context, v) {
          return SubstrateTransactionFeeWidget(
              fee: form.txFee,
              onSelectToken: form.onUpdateFeeToken,
              onRetryFeeEstimate: form.estimateFee,
              feeToken: v,
              feeTokens: form.feeTokens);
        },
      ),
      SubstrateTransactionStateSendTransaction(
        controller: form,
        mainContext: mainContext,
      )
    ]);
  }
}
