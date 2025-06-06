import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/future/wallet/network/forms/tron/forms/resource_v2/forms/unfreez_balance_v2.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/crypto/utils/tron/tron.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';

class TronUnFreezBalanceV2FieldsView extends StatelessWidget {
  const TronUnFreezBalanceV2FieldsView(
      {required this.account,
      required this.address,
      required this.validator,
      super.key});
  final ChainAccount address;
  final TronChain account;
  final TronUnFreezBalanceV2Form validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("resource".tr, style: context.textTheme.titleMedium),
        Text("trx_stake_type".tr),
        WidgetConstant.height8,
        AppDropDownBottom(
          items: {
            for (final i in TronUtils.tronFrozenReosurce)
              i: Text(i.name.toLowerCase().camelCase)
          },
          hint: "resource".tr,
          value: validator.resource.value,
          onChanged: (p0) {
            validator.setValue(validator.resource, p0);
          },
        ),
        AnimatedSwitcher(
          duration: APPConst.animationDuraion,
          child: validator.resource.hasValue
              ? Column(
                  key: ValueKey(validator.resource.value),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WidgetConstant.height20,
                    Text("stacke_amount".tr,
                        style: context.textTheme.titleMedium),
                    Text("stacking_balance_in_your_account".tr),
                    WidgetConstant.height8,
                    ContainerWithBorder(
                        child: CoinAndMarketPriceView(
                            balance: validator.stackedBalance)),
                    WidgetConstant.height20,
                    TransactionAmountView(
                      amount: validator.amount.value,
                      subtitle: "trx_unstake_amount".tr,
                      title: "unfreeze_balance".tr,
                      validate: validator.amount.isCompleted,
                      onTap: () {
                        context
                            .setupAmount(
                                token: account.network.coinParam.token,
                                max: validator.stackedBalance.balance)
                            .then((value) {
                          if (value == null) {
                            validator.setValue(validator.amount, null);
                          } else {
                            validator.setValue(
                                validator.amount,
                                IntegerBalance.token(
                                    value, account.network.token));
                          }
                        });
                      },
                      token: account.network.coinParam.token,
                    ),
                  ],
                )
              : WidgetConstant.sizedBox,
        )
      ],
    );
  }
}
