import 'package:blockchain_utils/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';

import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:xrpl_dart/xrpl_dart.dart';
import 'package:on_chain_wallet/future/wallet/network/forms/forms.dart';

import 'choose_token.dart';

class RipplePaymentFieldsView extends StatelessWidget {
  const RipplePaymentFieldsView(
      {required this.account,
      required this.address,
      required this.client,
      required this.validator,
      super.key});
  final ChainAccount address;
  final RippleChain account;
  final RipplePaymentForm validator;
  final RippleClient client;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("token_transfer".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
            onRemove: () {
              context
                  .openMaxExtendSliverBottomSheet<XRPPickedAssets>(
                    "choose_payment_currency".tr,
                    bodyBuilder: (controller) => RippleSelectTokenView(
                      account: account,
                      scrollController: controller,
                      client: client,
                    ),
                  )
                  .then(validator.setToken);
            },
            onRemoveIcon: Icon(Icons.edit, color: context.onPrimaryContainer),
            child:
                ConditionalWidgets(enable: validator.token != null, widgets: {
              true: (context) => TokenDetailsWidget(
                  token: validator.token!,
                  radius: APPConst.circleRadius25,
                  color: context.onPrimaryContainer,
                  liveBalance:
                      validator.issueToken?.accountToken?.streamBalance),
              false: (context) => TokenDetailsWidget(
                  token: account.network.token,
                  radius: APPConst.circleRadius25,
                  color: context.onPrimaryContainer,
                  liveBalance: address.address.balance),
            })),
        WidgetConstant.height20,
        ReceiptAddressView(
          address: validator.destination.value,
          onTap: () {
            context.selectAccount<XRPAddress>(account: account).then(
              (value) {
                validator.setValue(validator.destination, value?.firstOrNull);
              },
            );
          },
        ),
        WidgetConstant.height20,
        TransactionAmountView(
          amount: validator.amount.value,
          validate: validator.amount.isCompleted,
          onTap: () {
            if (validator.issueToken == null) {
              context
                  .setupAmount(
                      token: account.network.coinParam.token,
                      max: address.address.currencyBalance)
                  .then((value) {
                if (value == null) {
                  validator.setValue(validator.amount, null);
                } else {
                  validator.setValue(validator.amount,
                      IntegerBalance.token(value, account.network.token));
                }
              });
            } else {
              context
                  .openSliverBottomSheet<BigRational>(
                "setup_output_amount".tr,
                child: SetupDecimalTokenAmountView(
                  token: validator.token!,
                  max: validator.issueToken?.accountToken?.currencyBalance,
                  min: BigRational.zero,
                  subtitle: validator.destination.hasValue
                      ? ReceiptAddressView(
                          address: validator.destination.value, onTap: null)
                      : const SizedBox(),
                ),
              )
                  .then((value) {
                validator.setValue(
                    validator.amount,
                    value == null
                        ? null
                        : DecimalBalance.fromRational(
                            validator.token! as NonDecimalToken, value));
              });
            }
          },
          token: validator.token ?? account.network.token,
        ),
        WidgetConstant.height20,
        Text("invoiceid".tr, style: context.textTheme.titleMedium),
        Text("ripple_payment_invoiceid".tr),
        WidgetConstant.height8,
        ContainerWithBorder(
          onRemove: () {
            context
                .openSliverBottomSheet<String>(
                  validator.validatorName.tr,
                  child: StringWriterView(
                    defaultValue: validator.invoiceId.value,
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
                    label: "invoiceid".tr,
                  ),
                )
                .then(
                  (value) => validator.setValue(validator.invoiceId, value),
                );
          },
          onRemoveIcon: AddOrEditIconWidget(validator.invoiceId.hasValue),
          child: Text(validator.invoiceId.value ?? "tap_to_input_value".tr,
              maxLines: 3, style: context.onPrimaryTextTheme.bodyMedium),
        ),
        WidgetConstant.height20,
        Text("payment_flags".tr, style: context.textTheme.titleMedium),
        Text("ripple_payment_flags".tr),
        WidgetConstant.height8,
        AppDropDownBottom(
          items: <PaymentFlag, Widget>{
            for (final i in PaymentFlag.values) i: Text(i.name)
          },
          value: validator.flag.value,
          key: ValueKey(validator.flag.value),
          hint: "none".tr,
          onChanged: (v) {
            validator.setValue(validator.flag, v);
          },
          icon: validator.flag.hasValue
              ? InkWell(
                  onTap: () {
                    validator.setValue(validator.flag, null);
                  },
                  child: const Icon(Icons.remove_circle))
              : null,
        )
      ],
    );
  }
}
