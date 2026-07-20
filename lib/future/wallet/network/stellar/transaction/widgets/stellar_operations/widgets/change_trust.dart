import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/types/operations.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/widgets/widgets/live_widgets.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';

class StellarTransactionChangeTrustOperationWidget extends StatelessWidget {
  final StellarChangeTrustOperationForm form;
  const StellarTransactionChangeTrustOperationWidget(
      {required this.form, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      LiveFormPickStellarAssetWidget(
        field: form.asset,
        allowNativeAssets: false,
        allowCreateAsset: true,
        onSelectAsset: (asset) => form.onUpdateAsset(asset),
        controller: form.controller,
        onAssetPicked: (context, field, value) {
          return LiveFormWidgetAmount(
              onUpdateAmount: (amount, max) => form.onUpdateLimit(amount),
              onUpdateAmountMax: form.getMaxInput,
              field: form.limit);
        },
      )
    ]);
  }
}
