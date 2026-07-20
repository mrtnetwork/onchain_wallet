import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/controllers/fee.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/types/types.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';

class TronTransactionFeeDataView extends StatelessWidget {
  const TronTransactionFeeDataView({super.key, required this.controller});
  final TronTransactionFeeController controller;
  TronTransactionFeeData get fee => controller.txFee;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("transaction_fee".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        APPStreamBuilder(
            value: fee.notifier,
            builder: (context, value) {
              return APPAnimated(
                isActive: true,
                onActive: (context) => Shimmer(
                    key: ValueKey(fee.fee),
                    onActive: (enable, context) {
                      final isError = fee.fee.error != null;
                      return ContainerWithBorder(
                        validate: !isError,
                        onRemove: isError ? null : () {},
                        enableTap: false,
                        onTapError: controller.estimateFee,
                        validateText: fee.fee.error,
                        onRemoveWidget: ConditionalWidget(
                          enable: fee.fee.error == null && fee.fee.isSimulate,
                          onActive: (context) => TappedTooltipView(
                              tooltipWidget: ToolTipView(
                                  backgroundColor: context.colors.inverseSurface,
                                  child: Icon(Icons.help),
                                  tooltipWidget: (context) => ToolTipConstrainedBox(
                                      child: _TronFeeInfoWidget(fee: fee.fee)))),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Text(fee.fee.type.value.tr,
                                style: context.onPrimaryTextTheme.labelLarge),
                            CoinAndMarketPriceView(
                                balance: fee.fee.totalBurn,
                                style: context.onPrimaryTextTheme.titleMedium,
                                symbolColor: context.onPrimaryContainer)
                          ],
                        ),
                      );
                    },
                    enable: fee.fee.isManual || !fee.isPending),
              );
            }),
      ],
    );
  }
}

class _TronFeeInfoWidget extends StatelessWidget {
  const _TronFeeInfoWidget({required this.fee});
  final TronTransactionFee fee;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "bandwidth".tr,
              style: context.textTheme.labelMedium
                  ?.copyWith(color: context.colors.onInverseSurface),
            ),
            RichText(
                text: TextSpan(
                    style: context.textTheme.bodyMedium
                        ?.copyWith(color: context.colors.onInverseSurface),
                    children: [
                  TextSpan(text: fee.consumedBandwidth.toString()),
                  const TextSpan(text: "/"),
                  TextSpan(text: fee.stackedBandWidth.toString()),
                ])),
          ],
        ),
        WidgetConstant.height8,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "energy".tr,
              style: context.textTheme.labelMedium
                  ?.copyWith(color: context.colors.onInverseSurface),
            ),
            RichText(
                text: TextSpan(
                    style: context.textTheme.bodyMedium
                        ?.copyWith(color: context.colors.onInverseSurface),
                    children: [
                  TextSpan(text: fee.connsumedEnergy.toString()),
                  const TextSpan(text: "/"),
                  TextSpan(text: fee.stackedEnergy.toString()),
                ])),
          ],
        ),
        WidgetConstant.height8,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "trx_burned_for_resource".tr,
              style: context.textTheme.labelMedium
                  ?.copyWith(color: context.colors.onInverseSurface),
            ),
            CoinAndMarketPriceView(
                balance: fee.burnedForResource,
                symbolColor: context.colors.onInverseSurface,
                style: context.textTheme.labelLarge
                    ?.copyWith(color: context.colors.onInverseSurface))
          ],
        ),
        Divider(color: context.colors.onInverseSurface),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "total_burn".tr,
              style: context.textTheme.labelMedium
                  ?.copyWith(color: context.colors.onInverseSurface),
            ),
            CoinAndMarketPriceView(
              balance: fee.totalBurn,
              style: context.textTheme.labelLarge
                  ?.copyWith(color: context.colors.onInverseSurface),
              symbolColor: context.colors.onInverseSurface,
              showTokenImage: true,
            ),
          ],
        ),
      ],
    );
  }
}
