import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/token_details_view.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/operations/nfts/accept_offer.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/widgets/choose_token.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/widgets/memo/memo.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/constant/networks/ripple.dart';

class RippleTransactionNFTAcceptOfferWidget extends StatelessWidget {
  final RippleTransactionNFTAcceptOfferOperation form;
  const RippleTransactionNFTAcceptOfferWidget({required this.form, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      LiveFormWidgetString(
          maxLength: RippleConst.rippleTranactionHashLength,
          minLength: RippleConst.rippleTranactionHashLength,
          onUpdateValue: form.onUpdateNFTokenSellOffer,
          field: form.nftokenSellOffer,
          removable: true,
          fieldName: "ripple_nftoken_accept_offer_fields".tr),
      WidgetConstant.height20,
      LiveFormWidgetString(
          maxLength: RippleConst.rippleTranactionHashLength,
          minLength: RippleConst.rippleTranactionHashLength,
          onUpdateValue: form.onUpdateNFTokenBuyOffer,
          removable: true,
          field: form.nftokenBuyOffer,
          fieldName: "ripple_nftoken_accept_offer_fields".tr),
      WidgetConstant.height20,
      LiveFormWidget(
        field: form.token,
        builder: (context, field, value) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ContainerWithBorder(
                  onRemove: () {
                    if (value != null) {
                      form.onUpdateToken(null);
                      return;
                    }
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
                  validate: true,
                  onRemoveIcon: AddOrRemoveIconWidget(value != null),
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
                            acceptZero: false,
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
      RippleTransactionMemoWidget(controller: form),
      WidgetConstant.height20,
      TransactionFeeView(controller: form, onRetryFeeEstimate: form.estimateFee),
      TransactionStateSendTransaction(controller: form)
    ]);
  }
}
