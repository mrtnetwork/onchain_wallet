import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/transaction/types/types.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';

class BCHCashTokenDetailsView extends StatelessWidget {
  const BCHCashTokenDetailsView({
    super.key,
    required this.token,
    required this.color,
  });
  final BCHCashToken token;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final CashToken cashToken = token.cashToken;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(cashToken.hasNFT ? "nft".tr : "ft".tr,
            style: context.textTheme.labelLarge?.copyWith(color: color)),
        OneLineTextWidget(cashToken.category,
            style: context.textTheme.bodyMedium?.copyWith(color: color)),
        if (cashToken.hasAmount)
          CoinAndMarketPriceView(
              balance: token.balance,
              symbolColor: color,
              style: context.textTheme.labelLarge?.copyWith(color: color))
      ],
    );
  }
}
