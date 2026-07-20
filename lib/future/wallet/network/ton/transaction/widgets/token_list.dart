import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';

class TonTransactionSelectTokenList extends StatefulWidget {
  const TonTransactionSelectTokenList(
      {required this.account, required this.tokens, super.key});
  final ITonAddress account;
  final List<TonJettonToken> tokens;

  @override
  State<TonTransactionSelectTokenList> createState() =>
      _TonTransactionSelectTokenListState();
}

class _TonTransactionSelectTokenListState extends State<TonTransactionSelectTokenList> {
  void onTapToken(TokenCore? token) {
    if (token == null) return;
    if (token is! TonJettonToken) return;
    context.pop(token);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tokens.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.token, size: APPConst.double80, color: context.colors.onSurface),
          WidgetConstant.height8,
          Text("no_jettons_found".tr),
        ],
      );
    }
    return ConstraintsBoxView(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitleSubtitle(
          title: "jetton_transfer".tr,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("select_jetton_desc".tr),
              WidgetConstant.height8,
              Text("ton_jetton_transfer_desc".tr),
            ],
          ),
        ),
        AccountTokenListView(
            tokens: widget.tokens,
            onTapToken: onTapToken,
            onRemoveWidget: WidgetConstant.sizedBox),
      ],
    ));
  }
}
