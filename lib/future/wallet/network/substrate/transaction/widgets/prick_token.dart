import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/token_details_view.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/types/types.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';

typedef SUBSTRATEPICKTOKENFILTER = String? Function(SubstrateTokenDetails);

class SubstrateTransactionPickTokenView extends StatefulWidget {
  const SubstrateTransactionPickTokenView(
      {required this.tokens, required this.controller, this.onFilter, super.key});
  final List<SubstrateTokenDetails> tokens;
  final SUBSTRATEPICKTOKENFILTER? onFilter;
  final ScrollController controller;

  @override
  State<SubstrateTransactionPickTokenView> createState() =>
      _SubstrateTransactionPickTokenViewState();
}

class _SubstrateTransactionPickTokenViewState
    extends State<SubstrateTransactionPickTokenView>
    with SafeState<SubstrateTransactionPickTokenView> {
  List<_SubstrateTokenDetailsWithError> tokens = [];
  void buildTokens() {
    final filter = widget.onFilter;
    tokens = widget.tokens
        .map((e) => _SubstrateTokenDetailsWithError(
            token: e, error: filter == null ? null : filter(e)))
        .toList();
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    buildTokens();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('pick_token'.tr)),
      body: CustomScrollView(
        controller: widget.controller,
        slivers: [
          SliverConstraintsBoxView(
              padding: WidgetConstant.paddingHorizontal20,
              sliver: MultiSliver(children: [
                EmptyItemSliverWidgetView(
                    isEmpty: tokens.isEmpty,
                    icon: Icons.token,
                    itemBuilder: (context) => SliverList.separated(
                          itemCount: tokens.length,
                          itemBuilder: (context, index) {
                            final token = tokens[index];
                            return Opacity(
                              opacity: switch (token.error) {
                                null => 1,
                                _ => APPConst.disabledOpacity
                              },
                              child: ContainerWithBorder(
                                enableTap: token.error == null,
                                onRemove: () {
                                  context.pop(token.token);
                                },
                                onRemoveWidget: switch (token.error) {
                                  null => WidgetConstant.sizedBox,
                                  _ => TappedTooltipView(
                                      tooltipWidget: ToolTipView(
                                          message: token.error,
                                          child: Icon(
                                            Icons.error,
                                            color: context.onPrimaryContainer,
                                          )))
                                },
                                child: AccountTokenDetailsWidget(
                                    token: token.token.token,
                                    liveBalance: token.token.balance,
                                    radius: APPConst.circleRadius25),
                              ),
                            );
                          },
                          separatorBuilder: (context, index) => WidgetConstant.divider,
                        ))
              ])),
        ],
      ),
    );
  }
}

class _SubstrateTokenDetailsWithError {
  final SubstrateTokenDetails token;
  final String? error;
  const _SubstrateTokenDetailsWithError({required this.token, required this.error});
}
