import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/token_details_view.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/operations/trust_set/trust_set.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/widgets/choose_token.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/widgets/memo/memo.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/constant/networks/ripple.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

class RippleTransactionTrustSetWidget extends StatelessWidget {
  final RippleTransactionTrustSetOperation form;
  const RippleTransactionTrustSetWidget({required this.form, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      LiveFormWidget(
        field: form.token,
        builder: (context, field, value) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ContainerWithBorder(
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
                              allowNative: false),
                        )
                        .then(form.onUpdateToken);
                  },
                  validate: value != null,
                  onRemoveIcon: Icon(Icons.edit, color: context.onPrimaryContainer),
                  child: APPAnimated(
                    isActive: true,
                    onActive: (context) => ConditionalWidget(
                        onDeactive: (context) => FullWidthWrapper(
                              child: Text("tap_to_select_token".tr,
                                  style: context.onPrimaryTextTheme.bodyMedium),
                            ),
                        enable: value != null,
                        onActive: (context) => AccountTokenDetailsWidget(
                            key: ValueKey(value),
                            token: value!.token,
                            radius: APPConst.circleRadius25,
                            color: context.onPrimaryContainer,
                            balance: value.balance)),
                  )),
              APPAnimated(
                  isActive: value != null,
                  onActive: (context) =>
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        WidgetConstant.height20,
                        LiveFormWidgetBalanceCore(
                            acceptZero: true,
                            onUpdateAmount: (amount, max) {
                              form.onUpdateAmount(amount);
                            },
                            field: form.amount),
                      ]))
            ],
          );
        },
      ),
      WidgetConstant.height20,
      LiveFormWidget(
        field: form.qualityIn,
        builder: (context, field, value) {
          return ContainerWithBorder(
            onRemoveIcon: AddOrEditIconWidget(field.hasValue),
            validate: field.complete,
            onRemove: () {
              context
                  .openSliverBottomSheet<BigRational>(
                    "trust_set_fields".tr,
                    child: NumberWriteView(
                      defaultValue: field.value,
                      max: RippleConst.max32UnsignedRational,
                      allowDecimal: false,
                      allowSign: false,
                      title: PageTitleSubtitle(
                          title: field.title,
                          body: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (field.subtitle != null) Text(field.subtitle!),
                            ],
                          )),
                      buttonText: "setup_input".tr,
                      label: field.title,
                    ),
                  )
                  .then(form.onUpdateQualityIn);
            },
            child: Text(field.value?.toString().to3Digits ?? "tap_to_input_value".tr,
                style: context.onPrimaryTextTheme.bodyMedium),
          );
        },
      ),
      WidgetConstant.height20,
      LiveFormWidget(
        field: form.qualityOut,
        builder: (context, field, value) {
          return ContainerWithBorder(
            onRemoveIcon: AddOrEditIconWidget(field.hasValue),
            validate: field.complete,
            onRemove: () {
              context
                  .openSliverBottomSheet<BigRational>(
                    "trust_set_fields".tr,
                    child: NumberWriteView(
                      defaultValue: field.value,
                      max: RippleConst.max32UnsignedRational,
                      allowDecimal: false,
                      allowSign: false,
                      title: PageTitleSubtitle(
                          title: field.title,
                          body: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (field.subtitle != null) Text(field.subtitle!),
                            ],
                          )),
                      buttonText: "setup_input".tr,
                      label: field.title,
                    ),
                  )
                  .then(form.onUpdateQualityOut);
            },
            child: Text(field.value?.toString().to3Digits ?? "tap_to_input_value".tr,
                style: context.onPrimaryTextTheme.bodyMedium),
          );
        },
      ),
      WidgetConstant.height20,
      LiveFormWidget(
        field: form.flag,
        builder: (context, field, value) {
          return AppDropDownBottom(
            items: <TrustSetFlag, Widget>{
              for (final i in TrustSetFlag.values) i: Text(i.name)
            },
            value: field.value,
            key: ValueKey(field.value),
            onChanged: (v) {
              form.onUpdateFlag(v);
            },
            hint: "none".tr,
            icon: field.hasValue
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
