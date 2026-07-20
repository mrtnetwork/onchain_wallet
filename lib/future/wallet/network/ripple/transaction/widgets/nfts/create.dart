import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/token_details_view.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/operations/nfts/create_offer.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/widgets/choose_token.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/widgets/memo/memo.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/constant/networks/ripple.dart';

class RippleTransactionNFTokenCreateOfferWidget extends StatelessWidget {
  final RippleTransactionNFTokenCreateOfferOperation form;
  const RippleTransactionNFTokenCreateOfferWidget({required this.form, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      LiveFormWidgetString(
          onUpdateValue: form.onUpdateNFTokenId,
          field: form.nftokenId,
          maxLength: RippleConst.rippleTranactionHashLength,
          minLength: RippleConst.rippleTranactionHashLength,
          fieldName: "ripple_nftoken_create_offer_fields".tr),
      WidgetConstant.height20,
      LiveFormWidgetReceiverAddress(
        field: form.owner,
        account: form.account,
        removable: true,
        onUpdateAddress: (address) => form.onUpdateOwner(address),
      ),
      WidgetConstant.height20,
      LiveFormWidgetReceiverAddress(
        field: form.destination,
        account: form.account,
        removable: true,
        onUpdateAddress: (address) => form.onUpdateDestination(address),
      ),
      WidgetConstant.height20,
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
                              allowNative: true),
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
                            token: value!.issueToken?.token ?? form.network.token,
                            radius: APPConst.circleRadius25,
                            color: context.onPrimaryContainer)),
                  )),
              APPAnimated(
                  isActive: value != null,
                  onActive: (context) =>
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        WidgetConstant.height20,
                        LiveFormWidgetBalanceCore(
                            acceptZero: true,
                            onUpdateAmount: (amount, max) {
                              if (amount is BigRational) {
                                form.onUpdateAmountIssue(amount);
                              } else if (amount is BigInt) {
                                form.onUpdateAmountXrp(amount);
                              }
                            },
                            field: form.amount),
                      ]))
            ],
          );
        },
      ),
      WidgetConstant.height20,
      LiveFormWidget(
        field: form.expiration,
        builder: (context, field, value) {
          return ContainerWithBorder(
            onRemove: () {
              if (value != null) {
                form.onUpdateExpiration(null);
                return;
              }
              showAdaptiveDialog<DateTime>(
                context: context,
                useRootNavigator: false,
                builder: (context) {
                  return DatePickerDialog(
                    firstDate: DateTime.now(),
                    lastDate: DateTime(3000),
                    fieldLabelText: form.expiration.title,
                  );
                },
              ).then((date) {
                if (date == null) {
                  form.onUpdateExpiration(null);
                  return;
                }
                showAdaptiveDialog<TimeOfDay>(
                  context: context,
                  useRootNavigator: false,
                  builder: (context) {
                    return TimePickerDialog(
                      initialTime: TimeOfDay.now(),
                      helpText: date.toOnlyDateStr(),
                    );
                  },
                ).then((time) {
                  if (time == null) {
                    form.onUpdateExpiration(null);
                    return;
                  }
                  final DateTime picked =
                      DateTime(date.year, date.month, date.day, time.hour, time.minute);
                  form.onUpdateExpiration(picked);
                });
              });
            },
            onRemoveIcon: AddOrRemoveIconWidget(value != null),
            child: APPAnimated(
                onActive: (context) => FullWidthWrapper(
                      child: Text(
                        value?.toDateAndTime() ?? "tap_to_input_value".tr,
                        style: context.onPrimaryTextTheme.bodyMedium,
                      ),
                    )),
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
/// 