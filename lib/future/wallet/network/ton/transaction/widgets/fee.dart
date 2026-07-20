import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/ton/transaction/controllers/fee.dart';
import 'package:on_chain_wallet/future/wallet/network/ton/transaction/types/types.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';

class TonTransactionFeeDataView extends StatelessWidget {
  const TonTransactionFeeDataView({super.key, required this.controller});
  final TonTransactionFeeController controller;
  TonTransactionFeeData get fee => controller.txFee;
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
              return Shimmer(
                  onActive: (enable, context) {
                    return ContainerWithBorder(
                      validate: fee.fee.error == null && fee.fee.success,
                      onRemove: fee.fee.error == null ? () {} : null,
                      enableTap: false,
                      validateText: fee.fee.error ??
                          "some_action_failed".tr.replaceOne(
                              fee.fee.resultDescription ?? "unknown_error".tr),
                      onRemoveWidget: ConditionalWidget(
                        enable: fee.fee.error == null,
                        onActive: (context) => TappedTooltipView(
                            tooltipWidget: ToolTipView(
                          backgroundColor: context.colors.inverseSurface,
                          child: Icon(Icons.help),
                          tooltipWidget: (context) =>
                              ToolTipConstrainedBox(child: _TonFeeInfos(fee.fee)),
                        )),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text(fee.fee.type.value.tr,
                              style: context.onPrimaryTextTheme.labelLarge),
                          CoinAndMarketPriceView(
                              balance: fee.fee.fee,
                              style: context.onPrimaryTextTheme.titleMedium,
                              symbolColor: context.onPrimaryContainer)
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

class _TonFeeInfos extends StatelessWidget {
  final TonTransactionFee fee;
  const _TonFeeInfos(this.fee);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: APPConst.tooltipConstrainedWidth),
      child: Column(
        children: [
          Row(children: [
            Expanded(
                child: Text(
              "storage_fee".tr,
              style: context.textTheme.labelMedium
                  ?.copyWith(color: context.colors.onInverseSurface),
            )),
            CoinAndMarketPriceView(
              balance: fee.storageFee,
              style: context.textTheme.titleMedium
                  ?.copyWith(color: context.colors.onInverseSurface),
              symbolColor: context.colors.onInverseSurface,
            ),
          ]),
          Divider(color: context.colors.onInverseSurface),
          Row(children: [
            Expanded(
                child: Text(
              "action_fee".tr,
              style: context.textTheme.labelMedium
                  ?.copyWith(color: context.colors.onInverseSurface),
            )),
            CoinAndMarketPriceView(
              balance: fee.actionPhase,
              style: context.textTheme.titleMedium
                  ?.copyWith(color: context.colors.onInverseSurface),
              symbolColor: context.colors.onInverseSurface,
            ),
          ]),
          Divider(color: context.colors.onInverseSurface),
          Row(children: [
            Expanded(
                child: Text(
              "gas_fee".tr,
              style: context.textTheme.labelMedium
                  ?.copyWith(color: context.colors.onInverseSurface),
            )),
            CoinAndMarketPriceView(
              balance: fee.gasFee,
              style: context.textTheme.titleMedium
                  ?.copyWith(color: context.colors.onInverseSurface),
              symbolColor: context.colors.onInverseSurface,
            ),
          ]),
        ],
      ),
    );
  }
}
