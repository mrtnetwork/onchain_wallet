import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';

class TransactionFeeView<FEE extends TransactionFeeData> extends StatelessWidget {
  const TransactionFeeView(
      {super.key,
      this.onTapManual,
      required this.controller,
      this.onRetryFeeEstimate,
      this.errorBuilder});
  final TRANSACTIONSTATECONTROLLERFEE<FEE> controller;
  final DynamicVoid? onTapManual;
  final DynamicVoid? onRetryFeeEstimate;
  final TRANSACTIONFEEERRORBUILDER<FEE>? errorBuilder;
  FEE get fee => controller.txFee;
  @override
  Widget build(BuildContext context) {
    return TransactionFeeWidget<FEE>(
        fee: fee,
        onTapManual: onTapManual,
        getMaxFeeInput: controller.getMaxFeeInput,
        onRetryFeeEstimate: onRetryFeeEstimate);
  }
}

typedef TRANSACTIONFEEERRORBUILDER<FEE extends TransactionFeeData> = Widget Function(
    BuildContext contet, FEE fee);

class TransactionFeeWidget<FEE extends TransactionFeeData> extends StatelessWidget {
  const TransactionFeeWidget(
      {super.key,
      required this.fee,
      required this.getMaxFeeInput,
      this.onTapManual,
      this.onRetryFeeEstimate,
      this.errorBuilder});
  final FEE fee;
  final DynamicVoid? onTapManual;
  final GETMAXFEEINPUT getMaxFeeInput;
  final DynamicVoid? onRetryFeeEstimate;
  final TRANSACTIONFEEERRORBUILDER<FEE>? errorBuilder;

  @override
  Widget build(BuildContext context) {
    bool initiallyExpanded = false;
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
                    return ConditionalWidget(
                      enable: fee.fee.isDefault,
                      onActive: (context) => ContainerWithBorder(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            CoinAndMarketPriceView(
                                balance: fee.fee.fee,
                                style: context.onPrimaryTextTheme.titleMedium,
                                symbolColor: context.onPrimaryContainer,
                                showTokenImage: true),
                            ConditionalWidget(
                                enable: fee.fee.description != null,
                                onActive: (context) => Text(fee.fee.description ?? '',
                                    style: context.onPrimaryTextTheme.bodySmall)),
                            ConditionalWidget(
                                enable: errorBuilder != null,
                                onDeactive: (context) => ErrorTextContainer(
                                    error: fee.fee.error,
                                    errorIcon: onRetryFeeEstimate == null
                                        ? Icons.error
                                        : Icons.refresh,
                                    enableTap: false,
                                    oTapError: onRetryFeeEstimate),
                                onActive: (context) => errorBuilder!(context, fee)),
                          ],
                        ),
                      ),
                      onDeactive: (context) {
                        final dynamicFee = (fee as TransactionDynamicFeeData);
                        return APPAnimated(
                            isActive: true,
                            onActive: (context) => APPExpansionListTile(
                                  key: ValueKey(fee.fee),
                                  initiallyExpanded: initiallyExpanded,
                                  onExpansionChanged: (p0) {
                                    initiallyExpanded = p0;
                                  },
                                  enabled: dynamicFee.allowChangeFee,
                                  title: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Text(fee.fee.type.value.tr,
                                          style: context.onPrimaryTextTheme.titleMedium),
                                      WidgetConstant.height8,
                                      ContainerWithBorder(
                                        backgroundColor: context.onPrimaryContainer,
                                        child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              CoinAndMarketPriceView(
                                                  balance: fee.fee.fee,
                                                  style: context
                                                      .primaryTextTheme.titleMedium,
                                                  symbolColor: context.primaryContainer,
                                                  showTokenImage: true),
                                              ConditionalWidget(
                                                  enable: fee.fee.description != null,
                                                  onActive: (context) => Text(
                                                      fee.fee.description ?? '',
                                                      style: context
                                                          .primaryTextTheme.bodySmall)),
                                              ConditionalWidget(
                                                  enable: fee.fee.hasError,
                                                  onActive: (context) => ConditionalWidget(
                                                      enable: errorBuilder != null,
                                                      onDeactive: (context) =>
                                                          ErrorTextContainer(
                                                              error: fee.fee.error,
                                                              enableTap: false,
                                                              errorIcon:
                                                                  onRetryFeeEstimate ==
                                                                          null
                                                                      ? Icons.error
                                                                      : Icons.refresh,
                                                              oTapError:
                                                                  onRetryFeeEstimate),
                                                      onActive: (context) =>
                                                          errorBuilder!(context, fee))),
                                            ]),
                                      )
                                    ],
                                  ),
                                  children: [
                                    ConditionalWidget(
                                        enable: (fee as TransactionDynamicFeeData)
                                            .allowChangeFee,
                                        onActive: (context) => _Fees(
                                            fee: fee as TransactionDynamicFeeData,
                                            onTapManual: onTapManual,
                                            getMaxFeeInput: getMaxFeeInput))
                                  ],
                                ));
                      },
                    );
                  },
                  enable: fee.fee.isManual || !fee.isPending);
            }),
      ],
    );
  }
}

typedef GETMAXFEEINPUT = BigInt Function();

class _Fees extends StatelessWidget {
  final TransactionDynamicFeeData fee;
  final GETMAXFEEINPUT getMaxFeeInput;
  final DynamicVoid? onTapManual;
  const _Fees({required this.fee, required this.getMaxFeeInput, this.onTapManual});

  @override
  Widget build(BuildContext context) {
    final selectableFees = fee.fees.where((e) => !e.isManual).toList();
    final manual = fee.fees.firstWhereOrNull((e) => e.isManual);
    return AppGroupRadioBuilder<TransactionFee?>(
      groupValue: fee.fee,
      onChanged: (v) {
        if (v == null) return;
        fee.setFee(v);
      },
      builder: (context) =>
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ...selectableFees.map((e) => AppRadioListTile<TransactionFee?>(
              // groupValue: fee.fee,
              value: e,
              // onChanged: (v) {
              //   fee.setFee(e);
              // },
              secondary: e.error == null
                  ? null
                  : TappedTooltipView(
                      triggerOnHover: true,
                      tooltipWidget: ToolTipView(
                        message: e.error,
                        child: Icon(Icons.error),
                      )),
              title: Text(e.type.value.tr, style: context.onPrimaryTextTheme.labelLarge),
              subtitle: CoinAndMarketPriceView(
                  balance: e.fee,
                  style: context.onPrimaryTextTheme.titleMedium,
                  symbolColor: context.onPrimaryContainer),
            )),
        InkWell(
          onTap: () {
            final onTapManual = this.onTapManual;
            if (onTapManual != null) {
              onTapManual();
              return;
            }
            final max = getMaxFeeInput();
            context
                .setupAmount(
                    token: fee.feeToken, title: "setup_transaction_fee".tr, max: max)
                .then((value) {
              if (value == null) return;
              fee.setupManualFee(value);
            });
          },
          child: IgnorePointer(
            child: AppRadioListTile<TransactionFee?>(
              value: manual,
              subtitle: manual == null
                  ? null
                  : CoinAndMarketPriceView(
                      balance: manual.fee,
                      style: context.onPrimaryTextTheme.titleMedium,
                      symbolColor: context.onPrimaryContainer),
              title: Text(TxFeeTypes.manually.value.tr,
                  style: context.onPrimaryTextTheme.labelLarge),
            ),
          ),
        )
      ]),
    );
  }
}
