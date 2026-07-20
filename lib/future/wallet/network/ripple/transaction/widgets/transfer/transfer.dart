import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/token_details_view.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/operations/transfer/transfer.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/widgets/memo/memo.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/widgets/choose_token.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/constant/networks/ripple.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

class RippleTransactionTransferWidget extends StatelessWidget {
  final RippleTransactionPaymentOperation form;
  const RippleTransactionTransferWidget({required this.form, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      LiveFormWidget(
        field: form.token,
        builder: (context, field, value) {
          return ContainerWithBorder(
              onRemove: () {
                context
                    .openMaxExtendSliverBottomSheet<RipplePickedAsset>(
                      "choose_payment_currency".tr,
                      bodyBuilder: (controller) => RipplePickToken(
                          account: form.account,
                          address: form.address,
                          controller: controller,
                          tokens: form.tokens,
                          allowCreate: true,
                          allowNative: true),
                    )
                    .then(form.onUpdateToken);
              },
              onRemoveIcon: Icon(Icons.edit, color: context.onPrimaryContainer),
              child: APPAnimated(
                isActive: true,
                onActive: (context) => AccountTokenDetailsWidget(
                    key: ValueKey(value),
                    token: value.value.token,
                    radius: APPConst.circleRadius25,
                    color: context.onPrimaryContainer,
                    liveBalance: value),
              ));
        },
      ),
      WidgetConstant.height20,
      LiveFormWidgetReceiverAddress(
          onUpdateAddress: form.onUpdateRecipient,
          field: form.recipient,
          account: form.account),
      WidgetConstant.height20,
      LiveFormWidgetBalanceCore(
          onUpdateAmountMax: () => form.getMaxInput(),
          onUpdateAmount: (amount, max) {
            if (amount is BigRational) {
              form.onUpdateAmountToken(amount);
            } else if (amount is BigInt) {
              form.onUpdateAmountXrp(amount);
            }
          },
          field: form.amount),
      WidgetConstant.height20,
      LiveFormWidget(
        field: form.invoiceId,
        builder: (context, field, value) {
          return ContainerWithBorder(
              onRemove: () {
                context
                    .openSliverBottomSheet<String>(
                  "invoiceid".tr,
                  child: StringWriterView(
                      defaultValue: form.invoiceId.value,
                      maxLength: RippleConst.rippleTranactionHashLength,
                      minLength: RippleConst.rippleTranactionHashLength,
                      title: PageTitleSubtitle(
                          title: "invoiceid".tr,
                          body: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("ripple_payment_invoiceid".tr),
                            ],
                          )),
                      buttonText: "setup_input".tr,
                      label: "invoiceid".tr),
                )
                    .then(
                  (value) {
                    if (value == null) return;
                    form.onUpdateInvoiceId(value);
                  },
                );
              },
              onRemoveIcon: AddOrEditIconWidget(value != null),
              child: Text(value ?? "tap_to_input_value".tr,
                  maxLines: 3, style: context.onPrimaryTextTheme.bodyMedium));
        },
      ),
      WidgetConstant.height20,
      LiveFormWidget(
        field: form.flag,
        builder: (context, field, value) {
          return AppDropDownBottom(
            items: <PaymentFlag, Widget>{
              for (final i in PaymentFlag.values) i: Text(i.name)
            },
            value: value,
            key: ValueKey(value),
            hint: "none".tr,
            onChanged: (v) {
              if (v == null) return;
              form.onUpdateFlag(v);
            },
            icon: value != null
                ? InkWell(
                    onTap: () {
                      form.onUpdateFlag(null);
                    },
                    child: const Icon(Icons.remove_circle))
                : null,
          );
        },
      ),
      WidgetConstant.height20,
      RippleTransactionMemoWidget(controller: form),
      WidgetConstant.height20,
      TransactionFeeView(controller: form, onRetryFeeEstimate: form.estimateFee),
      TransactionStateSendTransaction(controller: form)
    ]);
  }
}
