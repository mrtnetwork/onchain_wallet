import 'package:blockchain_utils/networks/types/address.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/crypto/crypto.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';

import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

typedef ONUPDATETOKEN = void Function(BuildContext context, Token updatedToken);

class UpdateTokenDetailsView<NETWORKADDRESS extends IAddress, TOKEN extends TokenCore,
    CHAINACCOUNT extends ChainAccount> extends StatefulWidget {
  const UpdateTokenDetailsView({
    super.key,
    this.accountToken,
    required this.token,
    required this.account,
    required this.address,
    required this.scrollController,
    this.title,
    this.onUpdateToken,
  });
  final TOKEN? accountToken;
  final APPToken token;
  final APPCHAINACCOUNT<CHAINACCOUNT> account;
  final CHAINACCOUNT address;
  final ScrollController? scrollController;
  final ONUPDATETOKEN? onUpdateToken;
  final Widget? title;

  @override
  State<UpdateTokenDetailsView> createState() => _UpdateTokenDetailsViewState();
}

class _UpdateTokenDetailsViewState extends State<UpdateTokenDetailsView>
    with SafeState<UpdateTokenDetailsView> {
  final GlobalKey<AppTextFieldState> nameTextFieldKey =
      GlobalKey(debugLabel: "_UpdateTokenDetailsViewState_nameTextFieldKey");
  final GlobalKey<AppTextFieldState> symbolTextFieldKey =
      GlobalKey(debugLabel: "_UpdateTokenDetailsViewState_symbolTextFieldKey");
  final GlobalKey<AppTextFieldState> apiIdTextField =
      GlobalKey(debugLabel: "_UpdateTokenDetailsViewState_apiIdTextField");

  final GlobalKey<FormState> formKey =
      GlobalKey(debugLabel: "_UpdateTokenDetailsViewState");
  final StreamPageProgressController progressKey = StreamPageProgressController();
  APPToken get token => widget.token;
  late String tokenName = token.name;
  late String tokenSymbol = token.symbol;
  late String apiId = token.market?.apiId ?? "";
  int decimal = 0;
  bool canChangeDecimal = false;
  int? tokenDecimal;

  @override
  void onInitOnce() {
    super.onInitOnce();
    canChangeDecimal = _canChangeDecimal();
    if (canChangeDecimal || widget.account.network.type == NetworkType.stellar) {
      decimal = (widget.token as Token).decimal;
      tokenDecimal = decimal;
    }
  }

  String? onValidateDecimal(String? v) {
    if (!canChangeDecimal) return "";
    final parse = int.tryParse(v ?? "");
    if (parse == null || parse < 0 || parse > BlockchainConst.maxTokenDecimal) {
      return "token_decimals_validator".tr;
    }
    return null;
  }

  void onChangeDicmal(int? v) {
    decimal = v ?? 0;
  }

  void onChangeApiId(String v) {
    apiId = v;
  }

  void onTokenNameChange(String v) {
    tokenName = v;
  }

  void onTokenSymbolChange(String v) {
    tokenSymbol = v;
  }

  String? tokenNamevalidator(String? v) {
    final val = v?.trim() ?? "";
    if (val.length < 3) {
      return "token_name_validator".tr;
    }
    return null;
  }

  String? tokenSymbolvalidator(String? v) {
    final val = v?.trim() ?? "";
    if (val.length < 2) {
      return "token_symbol_validator".tr;
    }
    return null;
  }

  String? apiIdForm(String? v) {
    if (v?.isEmpty ?? true) return null;
    if (v!.length < 2) {
      return "coingecko_api_id_validator".tr;
    }
    return null;
  }

  void onUpdate() async {
    if (!formKey.ready()) return;
    final apiId = apiIdTextField.currentState!.getValue();
    final wallet = context.wallet;
    int? currectDecimal = tokenDecimal;
    if (canChangeDecimal && currectDecimal != decimal) {
      currectDecimal = decimal;
      final alert = await context.openSliverDialog(
          widget: (ctx) => DialogTextView(
                buttonWidget:
                    AsyncDialogDoubleButtonView(firstButtonLabel: "change_decimals".tr),
                widget: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("change_token_decimal_desc".tr),
                    WidgetConstant.height8,
                    Text(
                      "change_token_decimal_desc2"
                          .tr
                          .replaceOne(tokenDecimal.toString())
                          .replaceTwo(currectDecimal!.toString()),
                      style: context.textTheme.titleLarge,
                    )
                  ],
                ),
              ),
          label: "token_decimals".tr);
      if (alert != true) return;
    }
    CoingeckoCoin? market = token.market;
    if (apiId.isNotEmpty) {
      if (apiId != token.market?.apiId) {
        progressKey.progressText("retrieving_token_price".tr);
        final result = await wallet.currency.getCoinPrice(apiId);
        if (result.ok() == null) {
          progressKey.errorText(result.err()?.localizationError ?? "invalid_api_id".tr,
              backToIdle: true);
          return;
        }
        market = CoingeckoCoin(apiId: result.unwrap()!.id);
      }
    } else {
      market = null;
    }
    final updateToken = Token(
        name: tokenName,
        symbol: tokenSymbol,
        decimal: currectDecimal ?? 0,
        market: market,
        assetLogo: token.assetLogo);
    if (widget.accountToken == null) {
      widget.onUpdateToken?.call(context, updateToken);
    } else {
      progressKey.progressText("updating_token".tr);
      final update = await widget.account.updateToken(
          token: widget.accountToken!,
          updatedToken: updateToken,
          address: widget.address);
      update.watch(
        onErr: (error) => progressKey.errorText(error.localizationError,
            backToIdle: false, showBackButton: true),
      );
      if (update.isErr) return;
    }
    progressKey.successText("token_updated_successfully".tr, backToIdle: false);
  }

  bool _canChangeDecimal() {
    switch (widget.account.network.type) {
      case NetworkType.stellar:
      case NetworkType.xrpl:
        return false;
      default:
        return true;
    }
  }

  @override
  void safeDispose() {
    super.safeDispose();
    progressKey.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("update_token".tr)),
      body: Form(
        key: formKey,
        child: StreamPageProgress(
          controller: progressKey,
          initialWidget: ProgressWithTextView(text: "retrieving_token_information".tr),
          builder: (c) => CustomScrollView(
            controller: widget.scrollController,
            slivers: [
              SliverConstraintsBoxView(
                padding: WidgetConstant.paddingHorizontal20,
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      widget.title ??
                          PageTitleSubtitle(
                              title: "update_token_information".tr,
                              body: Text("update_token_desc".tr)),
                      WidgetConstant.height20,
                      AppTextField(
                          label: "name".tr,
                          minlines: 1,
                          initialValue: tokenName,
                          validator: tokenNamevalidator,
                          onChanged: onTokenNameChange,
                          key: nameTextFieldKey),
                      WidgetConstant.height20,
                      AppTextField(
                          label: "symbol".tr,
                          minlines: 1,
                          initialValue: tokenName,
                          validator: tokenSymbolvalidator,
                          onChanged: onTokenSymbolChange,
                          key: symbolTextFieldKey),
                      WidgetConstant.height20,
                      Text("live_price".tr, style: context.textTheme.titleMedium),
                      Text("coin_gecko_desc".tr),
                      WidgetConstant.height8,
                      AppTextField(
                        label: "api_id".tr,
                        key: apiIdTextField,
                        validator: apiIdForm,
                        onChanged: onChangeApiId,
                        initialValue: apiId,
                      ),
                      WidgetConstant.height20,
                      if (canChangeDecimal) ...[
                        Text("token_decimals".tr, style: context.textTheme.titleMedium),
                        Text("change_token_decimal_desc".tr),
                        WidgetConstant.height8,
                        NumberTextField(
                            label: "decimals".tr,
                            validator: onValidateDecimal,
                            onChangeValue: onChangeDicmal,
                            defaultValue: decimal,
                            max: BlockchainConst.maxTokenDecimal,
                            min: 0),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FixedElevatedButton(
                            padding: WidgetConstant.paddingVertical40,
                            onPressed: onUpdate,
                            child: Text("update_token".tr),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
