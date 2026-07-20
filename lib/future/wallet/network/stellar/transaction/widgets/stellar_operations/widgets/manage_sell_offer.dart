import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/setup_amount.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/types/operations.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/widgets/widgets/live_widgets.dart';
import 'package:on_chain_wallet/future/wallet/transaction/pages/live_form_widget.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/constant/networks/stellar.dart';

class StellarTransactionManageSellOfferWidget extends StatelessWidget {
  final StellarManageSellOfferOperationForm form;
  const StellarTransactionManageSellOfferWidget({required this.form, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      LiveFormPickStellarAssetWidget(
        field: form.selling,
        allowNativeAssets: true,
        allowCreateAsset: true,
        controller: form.controller,
        onSelectAsset: (asset) => form.onUpdateSelling(asset),
        onAssetPicked: (context, field, selling) {
          return LiveFormPickStellarAssetWidget(
            field: form.buying,
            allowNativeAssets: true,
            allowCreateAsset: true,
            onSelectAsset: (asset) => form.onUpdateBuying(asset),
            controller: form.controller,
            onAssetPicked: (context, field, buying) {
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                LiveFormWidgetAmount(
                    showZero: true,
                    onUpdateAmount: (amount, max) => form.onUpdateAmount(amount),
                    field: form.amount),
                WidgetConstant.height20,
                LiveFormWidget(
                  field: form.price,
                  builder: (context, field, value) {
                    return ContainerWithBorder(
                        validate: field.hasValue,
                        onRemoveIcon: Icon(Icons.edit, color: context.onPrimaryContainer),
                        child: ConditionalWidget(
                          onActive: (context) => Row(
                            children: [
                              Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  CircleTokenImageView(selling.token,
                                      radius: APPConst.circleRadius25),
                                  Container(
                                      padding: const EdgeInsets.only(left: 20),
                                      child: CircleTokenImageView(buying.token,
                                          radius: APPConst.circleRadius25)),
                                ],
                              ),
                              WidgetConstant.width8,
                              Expanded(
                                  child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(value!.toDecimal(),
                                      style: context.onPrimaryTextTheme.titleMedium),
                                  Text(form.priceMessage ?? '',
                                      style: context.onPrimaryTextTheme.bodySmall),
                                ],
                              )),
                            ],
                          ),
                          enable: field.hasValue,
                          onDeactive: (context) => Text(
                            "tap_to_setup_price".tr,
                            style: context.onPrimaryTextTheme.bodyMedium,
                          ),
                        ),
                        onRemove: () {
                          context
                              .openSliverBottomSheet<BigRational>("setup_price".tr,
                                  child: SetupDecimalExchangeRateInput(
                                    tokenB: selling.token,
                                    tokenA: buying.token,
                                    buttonText: "setup_price".tr,
                                    maxScale: StellarConst.decimal,
                                    min: BigRational.zero,
                                    isBuy: true,
                                    max: StellarConst.maxIssueAmountRational,
                                    subtitle: PageTitleSubtitle(
                                        title: "price".tr,
                                        body: Text("stellar_manage_buy_offer_price".tr)),
                                  ))
                              .then(form.onUpdatePrice);
                        });
                  },
                ),
                WidgetConstant.height20,
                LiveFormWidget(
                  field: form.offerId,
                  builder: (context, field, value) {
                    return ContainerWithBorder(
                        onRemoveIcon: Icon(Icons.edit, color: context.onPrimaryContainer),
                        child: Text(value?.toString() ?? "tap_to_input_value".tr,
                            style: context.onPrimaryTextTheme.bodyMedium),
                        onRemove: () {
                          context
                              .openSliverBottomSheet<BigRational>("setup_offer_id".tr,
                                  child: NumberWriteView(
                                      title: PageTitleSubtitle(
                                          title: "offer_id".tr,
                                          body: Text(
                                              "stellar_manage_sell_offer_offer_id".tr)),
                                      label: "offer_id".tr,
                                      buttonText: "setup_offer_id".tr,
                                      allowDecimal: false,
                                      allowSign: false,
                                      defaultValue:
                                          value == null ? null : BigRational(value),
                                      max: StellarConst.maxIssueAmountRational,
                                      min: BigRational.zero))
                              .then(form.onUpdateOfferId);
                        });
                  },
                )
              ]);
            },
          );
        },
      )
    ]);
  }
}
