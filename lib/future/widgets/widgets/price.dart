import 'dart:async';

import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/widgets/widgets/assets_image.dart';
import 'package:on_chain_wallet/wallet/wallet.dart'
    show APPToken, BalanceCore, IntegerBalance;

import 'tooltip/widgets/tooltip.dart';
import 'widget_constant.dart';

class PriceTooltipWidget extends StatelessWidget {
  const PriceTooltipWidget(this.amount, {super.key});
  final BalanceCore amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
        constraints: const BoxConstraints(maxWidth: 300),
        child: RichText(
            text: TextSpan(
                style: theme.textTheme.titleLarge
                    ?.copyWith(color: theme.colorScheme.onTertiaryContainer),
                children: [
              TextSpan(text: amount.viewPrice),
              const TextSpan(text: " "),
              TextSpan(
                  text: amount.token.symbolView,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onTertiaryContainer)),
              TextSpan(
                  text: " (${amount.token.nameView}) ",
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.onTertiaryContainer)),
            ])));
  }
}

class CoinAndMarketPriceView extends StatefulWidget {
  const CoinAndMarketPriceView({
    super.key,
    required this.balance,
    this.style,
    this.symbolColor,
    this.disableTooltip = false,
    this.showTokenImage = false,
    this.enableMarketPrice = true,
    this.isExpanded = false,
  });

  final BalanceCore balance;
  final TextStyle? style;
  final Color? symbolColor;
  final bool disableTooltip;
  final bool showTokenImage;
  final bool enableMarketPrice;
  final bool isExpanded;

  @override
  State<CoinAndMarketPriceView> createState() => _CoinAndMarketPriceViewState();
}

class _CoinAndMarketPriceViewState extends State<CoinAndMarketPriceView>
    with SafeState<CoinAndMarketPriceView> {
  late BalanceCore balance;
  APPToken get token => balance.token;
  StreamSubscription<Currency>? _marketAmountSubscription;
  IntegerBalance? marketPrice;
  String? price;

  IntegerBalance? onMarketPriceChange(String? price) {
    if (price == null) return null;
    final token = balance.token;
    final wallet = context.wallet;
    return wallet.currency.amount(price, token);
  }

  void onUpdateMarketInfo(Currency _) {
    final marketPrice = onMarketPriceChange(balance.price);
    if (marketPrice != this.marketPrice) {
      this.marketPrice = marketPrice;
      updateState();
    }
  }

  void init() {
    balance = widget.balance;
    price = balance.price;
    final marketId = balance.token.market;
    if (marketId != null) {
      _marketAmountSubscription =
          context.wallet.currency.currency.stream.listen(onUpdateMarketInfo);
    }
    marketPrice = onMarketPriceChange(price);
    updateState();
  }

  @override
  void didUpdateWidget(covariant CoinAndMarketPriceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (balance != widget.balance || balance.price != price) {
      _marketAmountSubscription?.cancel();
      _marketAmountSubscription = null;
      init();
    }
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    init();
  }

  @override
  void safeDispose() {
    super.safeDispose();
    _marketAmountSubscription?.cancel();
    _marketAmountSubscription = null;
  }

  @override
  Widget build(BuildContext context) {
    return ToolTipView(
      tooltipWidget: widget.disableTooltip ? null : (c) => PriceTooltipWidget(balance),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (widget.showTokenImage) ...[
                  CircleTokenImageView(balance.token, radius: 10),
                  WidgetConstant.width8,
                ],
                Flexible(
                  child: RichText(
                      textDirection: TextDirection.ltr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                          style: widget.style ?? context.textTheme.labelLarge,
                          children: [
                            TextSpan(text: balance.viewPrice),
                            const TextSpan(text: " "),
                          ])),
                ),
                Text(token.symbolView,
                    style: context.textTheme.labelSmall
                        ?.copyWith(color: widget.symbolColor ?? context.colors.primary)),
              ],
            ),
            if (widget.enableMarketPrice)
              CoinPriceView(
                  balance: marketPrice,
                  symbolColor: widget.symbolColor,
                  disableTooltip: false,
                  style: null),
          ],
        ),
      ),
    );
  }
}

class CoinPriceView extends StatelessWidget {
  const CoinPriceView(
      {super.key,
      required this.balance,
      this.symbolColor,
      this.style,
      this.disableTooltip = false,
      this.isExpanded = false});
  final IntegerBalance? balance;
  final TextStyle? style;
  final Color? symbolColor;
  final bool disableTooltip;
  final bool isExpanded;
  @override
  Widget build(BuildContext context) {
    final balance = this.balance;
    if (balance == null || balance.isZero) return WidgetConstant.sizedBox;
    return ToolTipView(
      tooltipWidget: disableTooltip ? null : (c) => PriceTooltipWidget(balance),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Flexible(
                  child: RichText(
                      textDirection: TextDirection.ltr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                          style: style ??
                              context.textTheme.labelSmall?.copyWith(color: symbolColor),
                          children: [
                            TextSpan(text: balance.viewPrice),
                            const TextSpan(text: " "),
                          ])),
                ),
                Text(
                  balance.token.symbolView,
                  style: context.textTheme.labelSmall
                      ?.copyWith(color: symbolColor ?? context.colors.primary),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MarketPriceView extends StatelessWidget {
  const MarketPriceView(
      {super.key,
      required this.balance,
      this.symbolColor,
      this.style,
      this.disableTooltip = false});
  final BalanceCore? balance;
  final TextStyle? style;
  final Color? symbolColor;
  final bool disableTooltip;
  @override
  Widget build(BuildContext context) {
    final wallet = context.wallet;
    final balance = this.balance;
    if (balance == null || balance.isZero) return WidgetConstant.sizedBox;
    final market = wallet.currency.amount(balance.price, balance.token);
    if (market == null || market.isZero) return WidgetConstant.sizedBox;
    return ToolTipView(
      tooltipWidget: disableTooltip ? null : (c) => PriceTooltipWidget(market),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: RichText(
                      textDirection: TextDirection.ltr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                          style: style ??
                              context.textTheme.labelSmall?.copyWith(color: symbolColor),
                          children: [
                            TextSpan(text: market.viewPrice),
                            const TextSpan(text: " "),
                          ])),
                ),
                Text(
                  market.token.symbolView,
                  style: context.textTheme.labelSmall
                      ?.copyWith(color: symbolColor ?? context.colors.primary),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CoinAndMarketLivePriceView extends StatefulWidget {
  const CoinAndMarketLivePriceView(
      {super.key,
      required this.liveBalance,
      this.style,
      this.symbolColor,
      this.disableTooltip = false,
      this.showTokenImage = false,
      this.enableMarketPrice = true,
      this.isExpanded = false});

  final StreamValue<BalanceCore> liveBalance;
  final TextStyle? style;
  final Color? symbolColor;
  final bool disableTooltip;
  final bool showTokenImage;
  final bool enableMarketPrice;
  final bool isExpanded;

  @override
  State<CoinAndMarketLivePriceView> createState() => _CoinAndMarketLivePriceViewState();
}

class _CoinAndMarketLivePriceViewState extends State<CoinAndMarketLivePriceView>
    with SafeState<CoinAndMarketLivePriceView> {
  late BalanceCore balance;
  APPToken get token => balance.token;
  // late BalanceCore amount;
  StreamSubscription<BalanceCore>? _amountSubscription;
  StreamSubscription<Currency>? _marketAmountSubscription;
  IntegerBalance? marketPrice;
  String? price;

  BalanceCore? onAmountChange() {
    if (balance.price != price) {
      return balance;
    }
    return null;
  }

  IntegerBalance? onMarketPriceChange(String? price) {
    if (price == null) return null;
    final token = balance.token;
    final wallet = context.wallet;
    final marketPrice = wallet.currency.amount(price, token);
    return marketPrice;
  }

  // final balance = widget.liveBalance.value;

  void onUpdateMarketInfo(Currency _) {
    final marketPrice = onMarketPriceChange(price);
    if (marketPrice != this.marketPrice) {
      this.marketPrice = marketPrice;
      updateState();
    }
  }

  void onUpdateBalance(BalanceCore _) {
    final amount = onAmountChange();
    if (amount == null) return;
    price = amount.price;
    marketPrice = onMarketPriceChange(price);
    updateState();
  }

  void init() {
    balance = widget.liveBalance.value;
    price = balance.price;
    _amountSubscription = widget.liveBalance.stream.listen(onUpdateBalance);
    final marketId = balance.token.market;
    if (marketId != null) {
      _marketAmountSubscription =
          context.wallet.currency.currency.stream.listen(onUpdateMarketInfo);
    }
    marketPrice = onMarketPriceChange(price);
    updateState();
  }

  @override
  void didUpdateWidget(covariant CoinAndMarketLivePriceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.liveBalance.value != balance || balance.price != price) {
      _amountSubscription?.cancel();
      _marketAmountSubscription?.cancel();
      _amountSubscription = null;
      _marketAmountSubscription = null;
      init();
    }
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    init();
  }

  @override
  void safeDispose() {
    super.safeDispose();
    _amountSubscription?.cancel();
    _marketAmountSubscription?.cancel();
    _amountSubscription = null;
    _marketAmountSubscription = null;
  }

  @override
  Widget build(BuildContext context) {
    return ToolTipView(
      tooltipWidget: widget.disableTooltip ? null : (c) => PriceTooltipWidget(balance),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (widget.showTokenImage) ...[
                  CircleTokenImageView(balance.token, radius: 10),
                  WidgetConstant.width8,
                ],
                Flexible(
                  child: RichText(
                      textDirection: TextDirection.ltr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                          style: widget.style ?? context.textTheme.labelLarge,
                          children: [
                            TextSpan(text: balance.viewPrice),
                            const TextSpan(text: " "),
                          ])),
                ),
                Text(token.symbolView,
                    style: context.textTheme.labelSmall
                        ?.copyWith(color: widget.symbolColor ?? context.colors.primary)),
              ],
            ),
            if (widget.enableMarketPrice)
              CoinPriceView(
                  balance: marketPrice,
                  symbolColor: widget.symbolColor,
                  disableTooltip: false,
                  style: null),
          ],
        ),
      ),
    );
  }
}
