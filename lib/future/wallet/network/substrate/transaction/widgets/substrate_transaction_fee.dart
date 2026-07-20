import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/widgets/widgets/json/json/widgets.dart';

typedef ONSELECTSUBSTRATEFEETOKEN = void Function(SubstrateTransferToken? token);

class SubstrateTransactionFeeWidget extends StatelessWidget {
  const SubstrateTransactionFeeWidget(
      {super.key,
      required this.fee,
      this.onRetryFeeEstimate,
      this.feeTokens = const [],
      this.feeToken,
      this.onSelectToken});
  final SubstrateTransactionFeeData fee;
  final DynamicVoid? onRetryFeeEstimate;
  final List<SubstrateTransferToken> feeTokens;
  final SubstrateTransferToken? feeToken;
  final ONSELECTSUBSTRATEFEETOKEN? onSelectToken;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConditionalWidget(
            enable: feeToken != null,
            onActive: (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("fee_token".tr, style: context.textTheme.titleMedium),
                    WidgetConstant.height8,
                    AppDropDownBottomWithBorder(
                      value: feeToken,
                      isDense: false,
                      onChanged: onSelectToken,
                      isExpanded: true,
                      items: {
                        for (final i in feeTokens)
                          i: AccountTokenDetailsWidget(
                              color: context.colors.onPrimaryContainer,
                              token: i.token,
                              // liveBalance: i.balance,
                              radius: APPConst.circleRadius25)
                      },
                    ),
                    WidgetConstant.height20
                  ],
                )),
        Text("transaction_fee".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        APPStreamBuilder(
            value: fee.notifier,
            builder: (context, value) {
              return Shimmer(
                  onActive: (enable, context) {
                    return ContainerWithBorder(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          ConditionalWidget(
                            enable: fee.fee.xcmDeliveriesFee != null,
                            onActive: (context) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ContainerWithBorder(
                                  backgroundColor: context.onPrimaryContainer,
                                  enableTap: false,
                                  onRemove: () {},
                                  onRemoveIcon: TappedTooltipView(
                                      tooltipWidget: ToolTipView(
                                          message: "xcm_deliveries_fee".tr,
                                          child: Icon(Icons.help,
                                              color: context.primaryContainer))),
                                  child: CoinAndMarketPriceView(
                                      balance: fee.fee.xcmDeliveriesFee!,
                                      style: context.primaryTextTheme.titleMedium,
                                      symbolColor: context.primaryContainer,
                                      showTokenImage: true),
                                ),
                                ContainerWithBorder(
                                  backgroundColor: context.onPrimaryContainer,
                                  child: CoinAndMarketPriceView(
                                      balance: fee.fee.fee,
                                      style: context.primaryTextTheme.titleMedium,
                                      symbolColor: context.primaryContainer,
                                      showTokenImage: true),
                                )
                              ],
                            ),
                            onDeactive: (context) => CoinAndMarketPriceView(
                                balance: fee.fee.fee,
                                style: context.onPrimaryTextTheme.titleMedium,
                                symbolColor: context.onPrimaryContainer,
                                showTokenImage: true),
                          ),

                          // ,
                          ConditionalWidget(
                              enable: fee.fee.description != null,
                              onActive: (context) => Text(fee.fee.description ?? '',
                                  style: context.onPrimaryTextTheme.bodySmall)),
                          ConditionalWidget(
                            enable: !fee.fee.dryRunSuccess,
                            onActive: (context) => ErrorTextContainer(
                              error: fee.fee.error,
                              errorIcon: Icons.open_in_new,
                              enableTap: true,
                              oTapError: () => context.openDialogPage(
                                '',
                                child: (context) => JsonView(
                                    text: fee.fee.dryRunInfo, title: 'content'.tr),
                              ),
                            ),
                            onDeactive: (context) => ErrorTextContainer(
                                error: fee.fee.error,
                                enableTap: false,
                                errorIcon: onRetryFeeEstimate == null
                                    ? Icons.error
                                    : Icons.refresh,
                                oTapError: onRetryFeeEstimate),
                          ),
                        ],
                      ),
                    );
                  },
                  enable: fee.fee.isManual || !fee.isPending);
            }),
      ],
    );
  }
}
