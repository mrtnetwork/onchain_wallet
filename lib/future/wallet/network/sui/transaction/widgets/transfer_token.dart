import 'package:flutter/material.dart';
import 'package:on_chain/sui/sui.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/future/wallet/wallet.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';

class SuiTransactionTransferTokenWidget extends StatelessWidget {
  final SuiTransactionTransferTokenOperation form;
  const SuiTransactionTransferTokenWidget({required this.form, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      Text("token_transfer".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      ContainerWithBorder(
        child: AccountTokenDetailsWidget(
            token: form.token.token,
            liveBalance: form.token.streamBalance,
            radius: APPConst.circleRadius25),
      ),
      WidgetConstant.height20,
      LiveFormWidgetList(
        field: form.recipients,
        onCreate: (context, field) => LiveWidgetAddNewTransferDetails<SuiAddress>(
            onUpdateAddresses: form.onUpdateRecipients,
            account: form.account,
            onFilterAccount: form.filterAccount,
            isReady: field.hasValue,
            multipleSelect: true),
        builder: (context, field, value) => LiveWidgetTransferDetails<SuiTransferDetails>(
            transfer: value,
            onRemove: form.onRemoveRecipient,
            onUpdateAmount: form.onUpdateAmount,
            onUpdateAmountMax: form.getMaxInput),
      ),
      WidgetConstant.height20,
      TransactionFeeView(controller: form, onRetryFeeEstimate: form.estimateFee),
      TransactionStateSendTransaction(controller: form)
    ]);
  }
}
