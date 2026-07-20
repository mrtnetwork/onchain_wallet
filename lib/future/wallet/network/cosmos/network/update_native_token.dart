import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/text_field/input_formaters.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class UpdateCosmosTokenView extends StatefulWidget {
  final CosmosFeeToken? token;
  final bool isFeeToken;
  final String? title;
  final String? subtitle;
  const UpdateCosmosTokenView(
      {this.token, this.title, this.subtitle, this.isFeeToken = false, super.key});

  @override
  State<UpdateCosmosTokenView> createState() => _UpdateCosmosTokenViewState();
}

class _UpdateCosmosTokenViewState extends State<UpdateCosmosTokenView>
    with SafeState<UpdateCosmosTokenView> {
  String tokenDenom = '';
  String tokenName = '';
  String tokenSymbol = '';
  int decimals = CosmosConst.maxTokenExponent;

  BigRational? minGasPrice;
  BigRational? avarageGasPrice;
  BigRational? highGasPrice;

  final GlobalKey<FormState> formKey =
      GlobalKey(debugLabel: "_UpdateCosmosTokenViewState_formKey");

  void onChangeDenom(String v) {
    tokenDenom = v;
  }

  String? onValidateTokenDenom(String? v) {
    if ((v?.isEmpty ?? true) || v!.isEmpty) {
      return "token_denom_validator".tr;
    }
    return null;
  }

  void onChangeTokenName(String v) {
    tokenName = v;
  }

  String? onValidateTokenName(String? v) {
    if ((v?.isEmpty ?? true) || v!.length < 3) {
      return "token_name_validator".tr;
    }
    return null;
  }

  void onChangeTokenSymbol(String v) {
    tokenSymbol = v;
  }

  String? onValidateTokenSymbol(String? v) {
    if ((v?.isEmpty ?? true) || v!.isEmpty || v.length > 6) {
      return "symbol_validator".tr;
    }
    return null;
  }

  void onSetup() {
    if (!formKey.ready()) return;

    final t = CosmosFeeToken(
        token: Token(
          name: tokenName,
          symbol: tokenSymbol,
          decimal: decimals,
        ),
        denom: tokenDenom,
        averageGasPrice: avarageGasPrice ?? BigRational.zero,
        lowGasPrice: minGasPrice,
        highGasPrice: highGasPrice);
    context.pop(t);
  }

  void onChangeTokenDecimals(int? tokenDecimals) {
    if (tokenDecimals == null) return;
    decimals = tokenDecimals;
  }

  String? onValidateTokenDecimals(String? v) {
    final decimals = int.tryParse(v ?? '');
    if (decimals == null) return "enter_valid_number".tr;
    if (decimals.isNegative || decimals > CosmosConst.maxTokenExponent) {
      return "token_decimal_max18_validator".tr;
    }
    return null;
  }

  void onChangeMinGasPrice(String v) {
    minGasPrice = BigRational.tryParse(v);
  }

  void onChangeAvarageGasPrice(String v) {
    avarageGasPrice = BigRational.tryParse(v);
  }

  void onChangeHighGasPrice(String v) {
    highGasPrice = BigRational.tryParse(v);
  }

  String? onValidateGasPrice(String? v) {
    if (v != null) {
      final p = BigRational.tryParse(v);
      if (p != null && !p.isNegative) return null;
    }
    return "gas_price_validator".tr;
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    decimals = widget.token?.token.decimal ?? CosmosConst.maxTokenExponent;
    tokenDenom = widget.token?.denom ?? '';
    tokenName = widget.token?.token.name ?? '';
    tokenSymbol = widget.token?.token.symbol ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitleSubtitle(
              title: "token_info".tr, body: Text("cosmos_update_token_desc".tr)),
          Text("denom".tr, style: context.textTheme.titleMedium),
          Text("token_demination_desc".tr),
          WidgetConstant.height8,
          AppTextField(
              initialValue: tokenDenom,
              onChanged: onChangeDenom,
              validator: onValidateTokenDenom,
              label: "denom".tr),
          WidgetConstant.height20,
          Text("token_name".tr, style: context.textTheme.titleMedium),
          WidgetConstant.height8,
          AppTextField(
              initialValue: tokenName,
              onChanged: onChangeTokenName,
              validator: onValidateTokenName,
              label: "network_name".tr),
          WidgetConstant.height20,
          Text("symbol".tr, style: context.textTheme.titleMedium),
          Text("symbol_desc".tr),
          WidgetConstant.height8,
          AppTextField(
              initialValue: tokenSymbol,
              onChanged: onChangeTokenSymbol,
              validator: onValidateTokenSymbol,
              label: "symbol".tr),
          WidgetConstant.height20,
          Text("decimals".tr, style: context.textTheme.titleMedium),
          Text("change_token_decimal_desc".tr),
          WidgetConstant.height8,
          NumberTextField(
              label: "decimals".tr,
              defaultValue: decimals,
              onChangeValue: onChangeTokenDecimals,
              validator: onValidateTokenDecimals,
              max: CosmosConst.maxTokenExponent,
              min: 0),
          if (widget.isFeeToken) ...[
            WidgetConstant.height20,
            Text("min_gas_price".tr, style: context.textTheme.titleMedium),
            Text("comsos_gas_price_desc".tr),
            WidgetConstant.height8,
            AppTextField(
              keyboardType: TextInputType.numberWithOptions(signed: false, decimal: true),
              label: "min_gas_price".tr,
              hint: "example_s".tr.replaceOne(APPConst.exampleDouble),
              onChanged: onChangeMinGasPrice,
              validator: onValidateGasPrice,
              inputFormatters: [
                BigRetionalTextInputFormatter(
                    allowSign: false, allowDecimal: true, maxScale: decimals)
              ],
            ),
            WidgetConstant.height20,
            Text("avarage_gas_price".tr, style: context.textTheme.titleMedium),
            Text("comsos_gas_price_desc".tr),
            WidgetConstant.height8,
            AppTextField(
              keyboardType: TextInputType.numberWithOptions(signed: false, decimal: true),
              label: "avarage_gas_price".tr,
              hint: "example_s".tr.replaceOne(APPConst.exampleDouble),
              onChanged: onChangeAvarageGasPrice,
              validator: onValidateGasPrice,
              inputFormatters: [
                BigRetionalTextInputFormatter(
                    allowSign: false, allowDecimal: true, maxScale: decimals)
              ],
            ),
            WidgetConstant.height20,
            Text("high_gas_price".tr, style: context.textTheme.titleMedium),
            Text("comsos_gas_price_desc".tr),
            WidgetConstant.height8,
            AppTextField(
              keyboardType: TextInputType.numberWithOptions(signed: false, decimal: true),
              label: "high_gas_price".tr,
              onChanged: onChangeHighGasPrice,
              validator: onValidateGasPrice,
              hint: "example_s".tr.replaceOne(APPConst.exampleDouble),
              inputFormatters: [
                BigRetionalTextInputFormatter(
                    allowSign: false, allowDecimal: true, maxScale: decimals)
              ],
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FixedElevatedButton(
                  padding: WidgetConstant.paddingVertical40,
                  onPressed: onSetup,
                  child:
                      Text(widget.token == null ? "setup_token".tr : "update_token".tr))
            ],
          )
        ],
      ),
    );
  }
}
