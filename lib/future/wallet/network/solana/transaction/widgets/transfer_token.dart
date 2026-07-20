import 'package:flutter/material.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/transaction/operations/transfer_token.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';

class SolanaTransactionTransferTokenWidget extends StatelessWidget {
  final SolanaTransactionTransferTokenOperation form;
  const SolanaTransactionTransferTokenWidget({required this.form, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      Text("token_transfer".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      AccountTokenDetailsView(token: form.token, radius: APPConst.circleRadius25),
      WidgetConstant.height20,
      LiveFormWidgetList(
        field: form.recipients,
        onCreate: (context, field) => LiveWidgetAddNewTransferDetails<SolAddress>(
            onUpdateAddresses: form.onUpdateRecipients,
            account: form.account,
            onFilterAccount: form.filterAccount,
            isReady: field.hasValue,
            multipleSelect: true),
        builder: (context, field, value) =>
            LiveWidgetTransferDetails<SolanaTransferDetails>(
                transfer: value,
                onRemove: form.onRemoveRecipients,
                onUpdateAmount: form.onUpdateAmount,
                onUpdateAmountMax: form.getMaxInput),
      ),
      WidgetConstant.height20,
      LiveFormWidgetMemo(
        field: form.memo,
        onUpdateMemo: form.onUpdateMemo,
        onRemoveMemo: form.onRemoveMemo,
      ),
      WidgetConstant.height20,
      TransactionFeeView(controller: form, onRetryFeeEstimate: form.estimateFee),
      TransactionStateSendTransaction(controller: form)
    ]);
  }
}
