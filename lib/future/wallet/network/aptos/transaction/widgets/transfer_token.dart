import 'package:flutter/material.dart';
import 'package:on_chain/aptos/src/address/address/address.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/extension/app_extensions/context.dart';
import 'package:on_chain_wallet/future/state_managment/extension/app_extensions/string.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/token_details_view.dart';
import 'package:on_chain_wallet/future/wallet/network/aptos/transaction/operations/transfer_token.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart' show WidgetConstant;
import 'package:on_chain_wallet/future/widgets/widgets/sliver/widgets/multi.dart';
import 'package:on_chain_wallet/wallet/models/networks/aptos/aptos.dart';

class AptosTransactionTransferTokenWidget extends StatelessWidget {
  final AptosTransactionTransferTokenOperation form;
  const AptosTransactionTransferTokenWidget({required this.form, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      Text("token_transfer".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      AccountTokenDetailsView(token: form.token, radius: APPConst.circleRadius25),
      WidgetConstant.height20,
      LiveFormWidgetList(
        field: form.recipients,
        onCreate: (context, field) => form.recipients.hasValue
            ? null
            : LiveWidgetAddNewTransferDetails<AptosAddress>(
                onUpdateAddresses: form.onUpdateRecipients,
                account: form.account,
                isReady: field.hasValue,
                onFilterAccount: form.filterAccount,
                multipleSelect: false),
        builder: (context, field, value) =>
            LiveWidgetTransferDetails<AptosTransferDetails>(
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
