import 'package:flutter/material.dart';
import 'package:on_chain_wallet/crypto/networks/tron/tron.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/operations/resource/unfreez_balance.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'fee.dart';

class TronTransactionUnFreezeBalanceV2ContractWidget extends StatelessWidget {
  final TronTransactionUnFreezeBalanceV2ContractOperation form;
  const TronTransactionUnFreezeBalanceV2ContractWidget({required this.form, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      LiveFormWidget(
        field: form.resource,
        builder: (context, field, value) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppDropDownBottom(
                items: {
                  for (final i in TronUtils.tronFrozenReosurce)
                    i: Text(i.name.toLowerCase().camelCase)
                },
                hint: "resource".tr,
                onChanged: form.onUpdateResource,
                value: value,
              ),
              WidgetConstant.height20,
              Text("stacke_amount".tr, style: context.textTheme.titleMedium),
              Text("stacking_balance_in_your_account".tr),
              WidgetConstant.height8,
              ContainerWithBorder(
                child: APPAnimated(
                  isActive: true,
                  onActive: (context) => FullWidthWrapper(
                    key: ValueKey(form.stackedBalance.balance),
                    child: CoinAndMarketPriceView(
                      balance: form.stackedBalance,
                      style: context.onPrimaryTextTheme.titleMedium,
                      symbolColor: context.onPrimaryContainer,
                      showTokenImage: true,
                    ),
                  ),
                ),
              ),
              WidgetConstant.height20,
              LiveFormWidgetAmount(
                onUpdateAmount: (amount, max) => form.onUpdateAmount(amount),
                field: form.amount,
                onUpdateAmountMax: form.getMaxInput,
              ),
            ],
          );
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
