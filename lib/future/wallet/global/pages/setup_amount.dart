import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:flutter/material.dart';

import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/text_field/input_formaters.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

class SetupNetworkAmount extends StatefulWidget {
  const SetupNetworkAmount({super.key, required this.token, this.max, required this.min});

  final BigInt? max;
  final BigInt min;
  final Token token;

  @override
  State<SetupNetworkAmount> createState() => _SetupNetworkAmountState();
}

class _SetupNetworkAmountState extends State<SetupNetworkAmount>
    with SafeState<SetupNetworkAmount> {
  late StreamValue<IntegerBalance> balance =
      StreamValue(IntegerBalance.zero(widget.token), name: "SetupNetworkAmount");
  bool isMax = false;
  bool isMin = false;
  final CurrencyTextEdittingController controller = CurrencyTextEdittingController();
  late final BigInt? maxValue = widget.max == null
      ? null
      : widget.max!.isNegative
          ? BigInt.zero
          : widget.max;
  late final bool enableMin = widget.min > BigInt.zero;

  final GlobalKey<FormState> form =
      GlobalKey<FormState>(debugLabel: "SetupNetworkAmount");
  late final String? maxString =
      PriceUtils.tryEncodePrice(maxValue, widget.token.decimal);
  late final String? minString =
      PriceUtils.tryEncodePrice(widget.min, widget.token.decimal);

  String? validator(String? v) {
    if (v == null) {
      if (widget.token.decimal == 0) {
        return "int_validator".tr;
      }
      return "decimal_int_validator".tr;
    }
    v = StrUtils.removeSeperator(v);
    final toBigit = PriceUtils.tryDecodePrice(v, widget.token.decimal);
    balance.value.updateBalance(toBigit ?? BigInt.zero);
    balance.notify();
    if (toBigit == null) {
      if (widget.token.decimal == 0) {
        return "int_validator".tr;
      }
      return "decimal_int_validator".tr;
    }
    if (maxValue != null && toBigit > maxValue!) {
      return "price_less_than"
          .tr
          .replaceOne(PriceUtils.priceWithCoinName(maxString!, widget.token.symbolView));
    } else if (toBigit < widget.min) {
      return "price_greather_than"
          .tr
          .replaceOne(PriceUtils.priceWithCoinName(minString!, widget.token.symbolView));
    }
    return null;
  }

  void onChanged() {
    final price = controller.getText();
    if (maxValue == null && !enableMin) return;
    final toBigit = PriceUtils.tryDecodePrice<BigInt?>(price, widget.token.decimal);
    final equal = toBigit == maxValue;
    if (equal != isMax) {
      updateState(() {
        isMax = equal;
      });
    }
    if (enableMin) {
      final equalMin = toBigit == widget.min;
      if (isMin != equalMin) {
        updateState(() {
          isMin = equalMin;
        });
      }
    }
  }

  void onTapMax() {
    final p = PriceUtils.tryEncodePrice(maxValue, widget.token.decimal,
        amoutDecimal: widget.token.decimal);
    if (p != null) {
      controller.text = p;
    }
  }

  void onTapMin() {
    final p = PriceUtils.tryEncodePrice(widget.min, widget.token.decimal,
        amoutDecimal: widget.token.decimal);
    if (p != null) {
      controller.text = p;
    }
  }

  void onSetup() {
    if (!form.ready()) return;
    final BigInt? toBigit =
        PriceUtils.tryDecodePrice(controller.getText(), widget.token.decimal);
    if (toBigit == null) return;
    if (mounted) {
      context.pop(toBigit);
    }
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    controller.setSymbol(widget.token.symbolView);
    controller.addListener(onChanged);
  }

  @override
  void safeDispose() {
    super.safeDispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  CircleTokenImageView(widget.token, radius: 60),
                  WidgetConstant.height8,
                  OneLineTextWidget(widget.token.nameView,
                      style: context.textTheme.labelLarge)
                ],
              ),
            ],
          ),
          WidgetConstant.height20,
          Theme(
            data: context.theme.copyWith(
              inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(
                borderRadius: WidgetConstant.border25,
              )),
            ),
            child: Align(
              alignment: Alignment.center,
              child: ConstraintsBoxView(
                maxWidth: 350,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        AppTextField(
                          style: context.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: false),
                          textAlign: TextAlign.start,
                          controller: controller,
                          enableInteractiveSelection: true,
                          maxLines: 1,
                          constraints: BoxConstraints(minHeight: 70),
                          inputFormatters: [
                            BigRetionalWithSeperatorTextInputFormatter(
                                maxScale: balance.value.token.decimal)
                          ],
                          validator: validator,
                        ),
                        Positioned(
                          top: 50,
                          left: 10,
                          child: APPStreamBuilder(
                              value: balance,
                              builder: (context, value) =>
                                  MarketPriceView(balance: value)),
                        ),
                      ],
                    ),
                    if (maxValue != null || enableMin) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (enableMin) ...[
                            FilledButton(
                              onPressed: onTapMin,
                              style: TextButton.styleFrom(
                                  backgroundColor: isMin
                                      ? context.colors.errorContainer
                                      : Colors.transparent,
                                  foregroundColor: isMin
                                      ? context.colors.onErrorContainer
                                      : context.colors.onSurface,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: WidgetConstant.border8)),
                              child: Text("min".tr),
                            ),
                            if (maxValue != null) WidgetConstant.width8,
                          ],
                          if (maxValue != null)
                            FilledButton(
                              onPressed: onTapMax,
                              style: TextButton.styleFrom(
                                  backgroundColor: isMax
                                      ? context.colors.errorContainer
                                      : Colors.transparent,
                                  foregroundColor: isMax
                                      ? context.colors.onErrorContainer
                                      : context.colors.onSurface,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: WidgetConstant.border8)),
                              child: Text("max".tr),
                            ),
                        ],
                      )
                    ],
                  ],
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FixedElevatedButton(
                  padding: WidgetConstant.paddingVertical40,
                  onPressed: onSetup,
                  child: Text("setup_amount".tr))
            ],
          )
        ],
      ),
    );
  }
}

class SetupDecimalTokenAmountView extends StatefulWidget {
  const SetupDecimalTokenAmountView(
      {super.key,
      required this.token,
      required this.min,
      this.subtitle,
      this.subtitleText,
      this.max,
      this.buttonText});
  final Widget? subtitle;
  final String? subtitleText;
  final BigRational? max;
  final BigRational min;
  final String? buttonText;
  final NonDecimalToken token;

  @override
  State<SetupDecimalTokenAmountView> createState() => _SetupDecimalTokenAmountViewState();
}

class _SetupDecimalTokenAmountViewState extends State<SetupDecimalTokenAmountView>
    with SafeState {
  final GlobalKey<FormState> form =
      GlobalKey<FormState>(debugLabel: "_SetupDecimalTokenAmountViewState");
  final CurrencyTextEdittingController controller = CurrencyTextEdittingController();
  late StreamValue<DecimalBalance> balance = StreamValue(
      DecimalBalance.zero(widget.token),
      name: "_SetupDecimalTokenAmountViewState");

  BigRational? maxValue;
  bool enableMin = false;
  String? maxString;
  String? minString;

  bool isMax = false;
  bool isMin = false;
  String? onValidatePrice(String? v) {
    if (v == null) return "decimal_int_validator".tr;
    final rational = BigRational.tryParse(StrUtils.removeSeperator(v));
    if (rational == null) {
      return "decimal_int_validator".tr;
    }
    balance.value.updateBalance(rational);
    balance.notify();
    if (widget.max != null && rational > widget.max!) {
      return "price_less_than"
          .tr
          .replaceOne(PriceUtils.priceWithCoinName(maxString!, widget.token.symbol));
    } else if (rational < widget.min) {
      return "price_greather_than"
          .tr
          .replaceOne(PriceUtils.priceWithCoinName(minString!, widget.token.symbol));
    }
    return null;
  }

  String price = "0.0";
  void onChanged() {
    price = controller.getText();
  }

  void onSetup() {
    if (!form.ready()) return;
    final rational = BigRational.tryParse(price);
    if (rational == null) return;
    if (mounted) {
      context.pop(rational);
    }
  }

  void onTapMax() {
    final maxString = this.maxString;
    if (maxString != null) {
      controller.text = maxString;
    }
  }

  void onTapMin() {
    final minString = this.minString;
    if (minString != null) {
      controller.text = minString;
    }
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    final max = widget.max;
    maxValue = max == null
        ? null
        : max.isNegative
            ? BigRational.zero
            : max;
    final min = widget.min;
    enableMin = min > BigRational.zero;
    maxString = max?.toDecimal();
    minString = min.toDecimal();
    controller.setSymbol(widget.token.symbolView);
    controller.addListener(onChanged);
  }

  @override
  void safeDispose() {
    super.safeDispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.subtitle != null || widget.subtitleText != null)
            widget.subtitle ?? Text(widget.subtitleText ?? ""),
          WidgetConstant.height20,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  CircleTokenImageView(widget.token, radius: 60),
                  OneLineTextWidget(widget.token.nameView,
                      style: context.textTheme.labelLarge)
                ],
              ),
            ],
          ),
          WidgetConstant.height20,
          Theme(
            data: context.theme.copyWith(
              inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(
                borderRadius: WidgetConstant.border25,
              )),
            ),
            child: Align(
              alignment: Alignment.center,
              child: ConstraintsBoxView(
                maxWidth: 350,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        AppTextField(
                            style: context.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true, signed: false),
                            textAlign: TextAlign.start,
                            controller: controller,
                            enableInteractiveSelection: true,
                            maxLines: 1,
                            constraints: BoxConstraints(minHeight: 70),
                            inputFormatters: [
                              BigRetionalWithSeperatorTextInputFormatter()
                            ],
                            validator: onValidatePrice),
                        Positioned(
                          top: 50,
                          left: 10,
                          child: APPStreamBuilder(
                              value: balance,
                              builder: (context, value) =>
                                  MarketPriceView(balance: value)),
                        ),
                      ],
                    ),
                    ConditionalWidget(
                        enable: maxValue != null || enableMin,
                        onActive: (context) => Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (enableMin) ...[
                                  FilledButton(
                                      onPressed: onTapMin,
                                      style: TextButton.styleFrom(
                                          backgroundColor: isMin
                                              ? context.colors.errorContainer
                                              : Colors.transparent,
                                          foregroundColor: isMin
                                              ? context.colors.onErrorContainer
                                              : context.colors.onSurface,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: WidgetConstant.border8)),
                                      child: Text("min".tr)),
                                  if (maxValue != null) WidgetConstant.width8,
                                ],
                                if (maxValue != null)
                                  FilledButton(
                                    onPressed: onTapMax,
                                    style: TextButton.styleFrom(
                                        backgroundColor: isMax
                                            ? context.colors.errorContainer
                                            : Colors.transparent,
                                        foregroundColor: isMax
                                            ? context.colors.onErrorContainer
                                            : context.colors.onSurface,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: WidgetConstant.border8)),
                                    child: Text("max".tr),
                                  ),
                              ],
                            )),
                  ],
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FixedElevatedButton(
                  padding: WidgetConstant.paddingVertical40,
                  onPressed: onSetup,
                  child: Text(widget.buttonText ?? "setup_output_amount".tr))
            ],
          )
        ],
      ),
    );
  }
}

class SetupDecimalExchangeRateInput extends StatefulWidget {
  const SetupDecimalExchangeRateInput(
      {super.key,
      required this.tokenA,
      required this.tokenB,
      required this.isBuy,
      this.subtitle,
      this.subtitleText,
      this.max,
      this.min,
      this.buttonText,
      this.maxScale});
  final Widget? subtitle;
  final String? subtitleText;
  final BigRational? max;
  final BigRational? min;
  final String? buttonText;
  final Token tokenA;
  final Token tokenB;
  final int? maxScale;
  final bool isBuy;

  @override
  State<SetupDecimalExchangeRateInput> createState() =>
      _SetupDecimalExchangeRateInputState();
}

class _SetupDecimalExchangeRateInputState extends State<SetupDecimalExchangeRateInput>
    with SafeState {
  final CurrencyTextEdittingController controller =
      CurrencyTextEdittingController(text: "0.0");
  final GlobalKey<FormState> form =
      GlobalKey<FormState>(debugLabel: "_SetupDecimalExchangeRateInputState");
  late final String? maxString = widget.max?.toDecimal();
  late final String? minString = widget.min?.toDecimal();
  String? validator(String? v) {
    if (v == null) return "decimal_int_validator".tr;
    v = StrUtils.removeSeperator(v);
    final rational = BigRational.tryParse(v);
    if (rational == null) {
      return "decimal_int_validator".tr;
    }
    if (widget.max != null && rational > widget.max!) {
      return "price_less_than".tr.replaceOne(widget.max!.toDecimal(digits: 8));
    } else if (widget.min != null && rational < widget.min!) {
      return "price_greather_than".tr.replaceOne(widget.min!.toDecimal(digits: 8));
    }
    return null;
  }

  String price = "0.0";
  void onChaanged(String v) {
    price = StrUtils.removeSeperator(v);
    buildHelper(price);
  }

  String? helper;
  void buildHelper(String val) {
    final currentHelper = helper;
    final rational = BigRational.tryParse(price);
    if (rational == null) {
      helper = null;
    } else {
      if (widget.isBuy) {
        helper = "exchange_entred_price_buy_desc"
            .tr
            .replaceOne(PriceUtils.priceWithCoinName(
                rational.toDecimal().to3Digits, widget.tokenA.symbol))
            .replaceTwo(widget.tokenB.symbol);
      } else {
        helper = "exchange_entred_price_desc"
            .tr
            .replaceOne(PriceUtils.priceWithCoinName(
                rational.toDecimal().to3Digits, widget.tokenA.symbol))
            .replaceTwo(widget.tokenB.symbol);
      }
    }
    if (helper != currentHelper) {
      updateState();
    }
  }

  void onSetup() {
    if (!form.ready()) return;
    final rational = BigRational.tryParse(price);
    if (rational == null) return;
    context.pop(rational);
  }

  @override
  void initState() {
    super.initState();
    controller.setSymbol("${widget.tokenA.symbol}/${widget.tokenB.symbol}");
  }

  @override
  void safeDispose() {
    super.safeDispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.subtitle != null || widget.subtitleText != null)
            widget.subtitle ?? Text(widget.subtitleText ?? ""),
          WidgetConstant.height20,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  CircleTokenImageView(widget.tokenB, radius: APPConst.largeCircleRadius),
                  Container(
                    padding: const EdgeInsets.only(left: 40),
                    child: CircleTokenImageView(widget.tokenA,
                        radius: APPConst.largeCircleRadius),
                  ),
                ],
              ),
            ],
          ),
          WidgetConstant.height20,
          Theme(
            data: context.theme.copyWith(
              inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(borderRadius: WidgetConstant.border25)),
            ),
            child: Align(
              alignment: Alignment.center,
              child: ConstraintsBoxView(
                maxWidth: 350,
                child: AppTextField(
                    style: context.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: false),
                    textAlign: TextAlign.center,
                    controller: controller,
                    inputFormatters: [
                      BigRetionalWithSeperatorTextInputFormatter(
                          min: widget.min,
                          max: widget.max,
                          allowSign: false,
                          allowDecimal: true,
                          maxScale: widget.maxScale),
                    ],
                    validator: validator,
                    initialValue: price,
                    onChanged: onChaanged,
                    helperText: helper),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FixedElevatedButton(
                  padding: WidgetConstant.paddingVertical40,
                  onPressed: onSetup,
                  child: Text(widget.buttonText ?? "setup_output_amount".tr))
            ],
          )
        ],
      ),
    );
  }
}
