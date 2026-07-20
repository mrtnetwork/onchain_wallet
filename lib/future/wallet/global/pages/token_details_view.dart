import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/token/token.dart';

class AccountTokenDetailsView extends StatelessWidget {
  const AccountTokenDetailsView({
    super.key,
    required this.token,
    this.onTapError,
    this.onSelect,
    this.onSelectWidget,
    this.onSelectIcon,
    this.textColor,
    this.radius = 40,
    this.showBalance = true,
    this.enableTap = true,
    this.showTokenAddress = true,
    this.error,
  });
  final TokenCore token;
  final DynamicVoid? onSelect;
  final DynamicVoid? onTapError;
  final Widget? onSelectWidget;
  final Widget? onSelectIcon;
  final String? error;
  // final Color? backgroundColor;
  final Color? textColor;
  final double radius;
  final bool showBalance;
  final bool enableTap;
  final bool showTokenAddress;
  @override
  Widget build(BuildContext context) {
    return ContainerWithBorder(
      onRemove: onSelect,
      onRemoveIcon: onSelectIcon,
      onRemoveWidget: onSelectWidget,
      enableTap: enableTap,
      onTapError: onTapError,
      validate: error == null,
      validateText: error,
      child: AccountTokenDetailsWidget(
          token: token.token,
          tokenAddress: showTokenAddress ? token.issuer : null,
          color: textColor ?? context.colors.onPrimaryContainer,
          radius: radius,
          liveBalance: showBalance ? token.streamBalance : null),
    );
  }
}

class TokenDetailsView extends StatelessWidget {
  const TokenDetailsView({
    super.key,
    required this.token,
    this.onTapError,
    this.onSelect,
    this.onSelectWidget,
    this.onSelectIcon,
    this.textColor,
    this.radius = APPConst.circleRadius25,
    this.enableTap = true,
    this.error,
  });
  final Token token;
  final DynamicVoid? onSelect;
  final DynamicVoid? onTapError;
  final Widget? onSelectWidget;
  final Widget? onSelectIcon;
  final String? error;
  // final Color? backgroundColor;
  final Color? textColor;
  final double radius;
  final bool enableTap;
  @override
  Widget build(BuildContext context) {
    return ContainerWithBorder(
      onRemove: onSelect,
      onRemoveIcon: onSelectIcon,
      onRemoveWidget: onSelectWidget,
      enableTap: enableTap,
      onTapError: onTapError,
      validate: error == null,
      validateText: error,
      child: AccountTokenDetailsWidget(
          token: token,
          color: textColor ?? context.colors.onPrimaryContainer,
          radius: radius),
    );
  }
}

class AccountTokenDetailsWidget extends StatelessWidget {
  final APPToken token;
  final double radius;
  final Color? color;
  final StreamValue<BalanceCore>? liveBalance;
  final BalanceCore? balance;
  final String? tokenAddress;
  const AccountTokenDetailsWidget(
      {required this.token,
      this.liveBalance,
      this.balance,
      this.radius = APPConst.double40,
      this.color,
      this.tokenAddress,
      super.key});

  @override
  Widget build(BuildContext context) {
    final bool sameNameSymbol = token.nameView == token.symbolView;
    return Row(
      children: [
        CircleTokenImageView(token, radius: radius),
        WidgetConstant.width8,
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(token.nameView,
                style: context.textTheme.labelLarge?.copyWith(color: color)),
            if (tokenAddress != null)
              OneLineTextWidget(tokenAddress!,
                  style: context.textTheme.bodyMedium?.copyWith(color: color)),
            ConditionalWidget(
                onDeactive: (context) => sameNameSymbol
                    ? WidgetConstant.sizedBox
                    : Text(token.symbolView,
                        style: context.textTheme.labelSmall?.copyWith(color: color)),
                onActive: (context) {
                  return ConditionalWidget(
                      enable: liveBalance != null,
                      onActive: (context) => CoinAndMarketLivePriceView(
                            liveBalance: liveBalance!,
                            style: context.textTheme.titleMedium?.copyWith(color: color),
                            symbolColor: color,
                          ),
                      onDeactive: (context) => CoinAndMarketPriceView(
                            balance: balance!,
                            style: context.textTheme.titleMedium?.copyWith(color: color),
                            symbolColor: color,
                          ));
                },
                enable: liveBalance != null || balance != null),
          ],
        )),
      ],
    );
  }
}
