import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/types/operations.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/widgets/widgets/live_widgets.dart';
import 'package:on_chain_wallet/future/wallet/transaction/pages/live_form_widget.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';

class StellarTransactionPaymentWidget extends StatelessWidget {
  final StellarPaymentOperationForm form;
  const StellarTransactionPaymentWidget({required this.form, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      LiveFormPickStellarAssetWidget(
        field: form.asset,
        allowNativeAssets: true,
        allowCreateAsset: true,
        onSelectAsset: (asset) => form.onUpdateAsset(asset),
        controller: form.controller,
        onAssetPicked: (context, field, selling) {
          return Column(
            children: [
              LiveFormWidgetStellarAddressWithActivity(
                  field: form.recipient,
                  account: form.controller.account,
                  onTapError: (e) => form.controller.trackAccountActivity(e),
                  onUpdateAddress: form.onUpdateRecipient),
              WidgetConstant.height20,
              LiveFormWidgetAmount(
                onUpdateAmount: (amount, max) => form.onUpdateAmount(amount),
                field: form.amount,
                onUpdateAmountMax: () => form.getMaxInput(),
              )
            ],
          );
        },
      )
    ]);
  }
}
