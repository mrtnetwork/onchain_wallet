import 'package:flutter/material.dart';
import 'package:on_chain_wallet/crypto/networks/tron/tron.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/operations/resource/frozen_balance.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'fee.dart';

class TronTransactionFreezeBalanceV2ContractWidget extends StatelessWidget {
  final TronTransactionFreezeBalanceV2ContractOperation form;
  const TronTransactionFreezeBalanceV2ContractWidget({required this.form, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      LiveFormWidget(
        field: form.resource,
        builder: (context, field, value) {
          return AppDropDownBottom(
            items: {
              for (final i in TronUtils.tronFrozenReosurce)
                i: Text(i.name.toLowerCase().camelCase)
            },
            hint: "resource".tr,
            onChanged: form.onUpdateResource,
            value: value,
          );
        },
      ),
      WidgetConstant.height20,
      LiveFormWidgetAmount(
        onUpdateAmount: (amount, max) => form.onUpdateAmount(amount),
        field: form.amount,
        onUpdateAmountMax: form.getMaxInput,
      ),
      WidgetConstant.height20,
      LiveFormWidgetMemo(field: form.memo, onUpdateMemo: form.onUpdateMemo),
      WidgetConstant.height20,
      TronTransactionFeeDataView(controller: form),
      TransactionStateSendTransaction(controller: form)
    ]);
  }
}
