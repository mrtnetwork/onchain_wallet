import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/crypto/networks/tron/tron.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/operations/resource/delegated_resource.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'fee.dart';

class TronTransactionDelegateResourceContractWidget extends StatelessWidget {
  final TronTransactionDelegateResourceContractOperation form;
  const TronTransactionDelegateResourceContractWidget({required this.form, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      LiveFormWidget(
        field: form.resource,
        builder: (context, field, value) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AppDropDownBottom(items: {
              for (final i in TronUtils.tronFrozenReosurce)
                i: Text(i.name.toLowerCase().camelCase)
            }, hint: "resource".tr, value: value, onChanged: form.onUpdateResource),
            WidgetConstant.height20,
            Text("delegatable_amount".tr, style: context.textTheme.titleMedium),
            Text("delegatable_amount_desc".tr),
            WidgetConstant.height8,
            ContainerWithBorder(
                child: APPAnimated(
                    isActive: true,
                    onActive: (context) => FullWidthWrapper(
                          key: ValueKey(form.maxResourceBalance.amoumt),
                          child: CoinAndMarketPriceView(
                              balance: form.maxResourceBalance.amoumt,
                              showTokenImage: true,
                              symbolColor: context.onPrimaryContainer,
                              style: context.onPrimaryTextTheme.titleMedium),
                        ))),
            WidgetConstant.height20,
            LiveFormWidgetReceiverAddress(
              field: form.destination,
              account: form.account,
              onUpdateAddress: form.onUpdateDestination,
            ),
            WidgetConstant.height20,
            LiveFormWidgetAmount(
                onUpdateAmountMax: () => form.maxResourceBalance.amoumt.balance,
                onUpdateAmount: (amount, max) => form.onUpdateAmount(amount),
                field: form.amount),
            WidgetConstant.height20,
            LiveFormWidget(
              field: form.lockResource,
              builder: (context, field, value) {
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ContainerWithBorder(
                      child: Switch(
                    value: value,
                    onChanged: (value) {
                      form.onUpdateLock(value);
                    },
                  )),
                  APPAnimated(
                      isActive: value,
                      onActive: (context) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            WidgetConstant.height20,
                            LiveFormWidget(
                              field: form.lockPeriod,
                              builder: (context, field, value) {
                                return ContainerWithBorder(
                                    onRemoveIcon: Icon(Icons.edit,
                                        color: context.onPrimaryContainer),
                                    onRemove: () {
                                      context
                                          .openSliverBottomSheet<BigRational>(
                                            "delegated_resource".tr,
                                            child: NumberWriteView(
                                              defaultValue: value,
                                              max: TronUtils.maxDelegatedLockPeriod,
                                              allowDecimal: false,
                                              allowSign: false,
                                              title: PageTitleSubtitle(
                                                  title: "lock_period".tr,
                                                  body: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text("tron_delegate_lock_time_desc"
                                                          .tr),
                                                    ],
                                                  )),
                                              buttonText: "setup_input".tr,
                                              label: "lock_period".tr,
                                            ),
                                          )
                                          .then(form.onUpdateLockPeriod);
                                    },
                                    child: Row(
                                      children: [
                                        Expanded(
                                            child: RichText(
                                                text: TextSpan(
                                                    style: context
                                                        .onPrimaryTextTheme.bodyMedium,
                                                    children: [
                                              TextSpan(
                                                  text: value?.toString().to3Digits ??
                                                      "tap_to_input_value".tr),
                                              if (value != null) ...[
                                                TextSpan(
                                                    style: context
                                                        .onPrimaryTextTheme.bodySmall,
                                                    text:
                                                        " (${TronUtils.delegatedLockPeriodToDateTime(value.toBigInt()).toDateAndTime()})")
                                              ],
                                            ]))),
                                        ToolTipView(
                                          message: "tron_delegate_lock_time_desc2".tr,
                                          waitDuration: null,
                                          child: Icon(Icons.help,
                                              color: context.onPrimaryContainer),
                                        )
                                      ],
                                    ));
                              },
                            ),
                          ],
                        );
                      })
                ]);
              },
            ),
            WidgetConstant.height20,
          ]);
        },
      ),
      WidgetConstant.height20,
      LiveFormWidgetMemo(field: form.memo, onUpdateMemo: form.onUpdateMemo),
      WidgetConstant.height20,
      TronTransactionFeeDataView(controller: form),
      TransactionStateSendTransaction(controller: form)
    ]);
  }
}
