import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:on_chain_wallet/future/wallet/network/ton/transaction/controller/impl/fee_impl.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';

class TonTransactionFeeView extends StatelessWidget {
  const TonTransactionFeeView(this.fee, {super.key});
  final TonFeeImpl fee;
  @override
  Widget build(BuildContext context) {
    return APPAnimatedSwitcher(enable: true, widgets: {
      true: (c) => Column(
            key: ValueKey<StreamWidgetStatus>(fee.feeStatus),
            children: [
              ContainerWithBorder(
                onRemove: fee.onTapErrorEstimate,
                enableTap: false,
                onRemoveIcon: _FeeDetailsIconView(status: fee.feeStatus),
                iconAlginment: CrossAxisAlignment.start,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("transaction_fee".tr,
                        style: context.onPrimaryTextTheme.titleMedium),
                    WidgetConstant.height8,
                    ContainerWithBorder(
                      backgroundColor: context.onPrimaryContainer,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FeeDetailsView(status: fee.feeStatus, fee: fee),
                          ErrorTextContainer(
                            error: fee.feeDetails.success
                                ? null
                                : "some_action_failed".tr.replaceOne(
                                    fee.feeDetails.resultDescription ??
                                        "unknown_error".tr),
                          )
                        ],
                      ),
                    ),
                    if (fee.feeDetails.hasInternalFee) ...[
                      WidgetConstant.height20,
                      Text("other_fees".tr,
                          style: context.onPrimaryTextTheme.titleMedium),
                      Text("ton_transaction_fee_desc2".tr,
                          style: context.onPrimaryTextTheme.bodyMedium),
                      WidgetConstant.height8,
                      ...List.generate(
                        fee.feeDetails.internalMessages.length,
                        (index) {
                          final intFee = fee.feeDetails.internalMessages[index];
                          return ContainerWithBorder(
                            backgroundColor: context.onPrimaryContainer,
                            enableTap: false,
                            validate: intFee.success,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CoinAndMarketPriceView(
                                  balance: intFee.total,
                                  style: context.primaryTextTheme.titleMedium,
                                  symbolColor: context.primaryContainer,
                                ),
                                ErrorTextContainer(
                                  error: intFee.success
                                      ? null
                                      : "some_action_failed".tr.replaceOne(
                                          intFee.resultDescription ??
                                              "unknown_error".tr),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                    WidgetConstant.height20,
                    Text(
                      "total_fees".tr,
                      style: context.onPrimaryTextTheme.titleMedium,
                    ),
                    ContainerWithBorder(
                        backgroundColor: context.colors.onPrimaryContainer,
                        child: CoinAndMarketPriceView(
                          balance: fee.feeDetails.totalFee,
                          style: context.primaryTextTheme.titleMedium,
                          symbolColor: context.primaryContainer,
                        )),
                  ],
                ),
              ),
            ],
          )
    });
  }
}

class _FeeDetailsView extends StatelessWidget {
  const _FeeDetailsView({required this.status, required this.fee});
  final StreamWidgetStatus status;
  final TonFeeImpl fee;
  @override
  Widget build(BuildContext context) {
    switch (status) {
      case StreamWidgetStatus.success:
        return CoinAndMarketPriceView(
          balance: fee.feeDetails.fee,
          style: context.primaryTextTheme.titleMedium,
          symbolColor: context.primaryContainer,
        );
      case StreamWidgetStatus.error:
        return ErrorTextContainer(
            error: fee.feeError?.tr ?? "estimate_fee_error_desc".tr);
      case StreamWidgetStatus.idle:
        return Text(
          "transaction_is_not_ready".tr,
          style: context.primaryTextTheme.bodyMedium,
        );
      default:
        return Text(
          "estimating_fee_please_wait".tr,
          style: context.primaryTextTheme.bodyMedium,
        );
    }
  }
}

class _FeeDetailsIconView extends StatelessWidget {
  const _FeeDetailsIconView({required this.status});
  final StreamWidgetStatus? status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case StreamWidgetStatus.success:
        return WidgetConstant.checkCircle;
      case StreamWidgetStatus.error:
        return WidgetConstant.errorIcon;
      case StreamWidgetStatus.idle:
        return Icon(Icons.circle, color: context.colors.transparent);
      case StreamWidgetStatus.progress:
        return CircularProgressIndicator(color: context.onPrimaryContainer);
      default:
        return WidgetConstant.sizedBox;
    }
  }
}
