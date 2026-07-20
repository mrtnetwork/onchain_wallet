import 'dart:async';

import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class AccountTokensView<TOKEN extends TokenCore, ACCOUNT extends APPCHAINTOKEN<TOKEN>>
    extends StatefulWidget {
  const AccountTokensView(
      {super.key,
      required this.account,
      this.importTokenPage,
      required this.transferBuilder});
  final String? importTokenPage;
  final APPCHAINACCOUNT<ACCOUNT> account;
  final TOKENTRANSFERBUILDER<TOKEN> transferBuilder;

  @override
  State<AccountTokensView<TOKEN, ACCOUNT>> createState() =>
      _AccountTokensViewState<TOKEN, ACCOUNT>();
}

class _AccountTokensViewState<TOKEN extends TokenCore,
        ACCOUNT extends APPCHAINTOKEN<TOKEN>>
    extends State<AccountTokensView<TOKEN, ACCOUNT>>
    with SafeState<AccountTokensView<TOKEN, ACCOUNT>> {
  StreamSubscription<ChainEvent>? _listener;
  ACCOUNT get address => widget.account.addressSync;
  List<TOKEN>? tokens;
  Future<void> getAccountTokens() async {
    final result = await address.getAccountTokens();
    result.watch(
      onErr: (error) {
        tokens = [];
        updateState();
        context.showAlert(error.localizationError);
      },
      onOk: (tokens) {
        this.tokens = tokens;
        updateState();
      },
    );
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    _listener = widget.account.stream.listen((e) async {
      if (e.type == DefaultChainNotify.token) {
        getAccountTokens();
      }
    });
    getAccountTokens();
  }

  @override
  void safeDispose() {
    super.safeDispose();
    _listener?.cancel();
    _listener = null;
  }

  @override
  Widget build(BuildContext context) {
    return AccountTabbarScrollWidget(slivers: [
      Shimmer(
          sliver: true,
          onActive: (enable, context) {
            return ConditionalWidgetWithValue(
                value: tokens,
                onNull: (context) => ShimmerBox(),
                onValue: (context, tokens) => MultiSliver(children: [
                      EmptyItemSliverWidgetView(
                          isEmpty: tokens.isEmpty,
                          onEmpty: (context) => Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.token, size: APPConst.double80),
                                  WidgetConstant.height8,
                                  Text("no_tokens_found".tr),
                                  WidgetConstant.height20,
                                  FilledButton(
                                      onPressed: () {
                                        context.to(PageRouter.manageTokens);
                                      },
                                      child: Text("monitor_my_tokens".tr))
                                ],
                              ),
                          itemBuilder: (context) => SliverToBoxAdapter(
                              child: AppListTile(
                                  leading: const Icon(Icons.token),
                                  onTap: () {
                                    context.to(PageRouter.manageTokens);
                                  },
                                  title: Text("manage_tokens".tr),
                                  subtitle: Text("add_or_remove_tokens".tr)))),
                      SliverList.builder(
                          itemBuilder: (context, index) {
                            final token = tokens[index];
                            return AccountTokenDetailsView(
                              token: token,
                              onSelectWidget: WidgetConstant.sizedBox,
                              onSelect: () {
                                context.openDialogPage<TokenAction>("token_info".tr,
                                    child: (ctx) => TokenDetailsModalView<TOKEN, ACCOUNT>(
                                        token: token,
                                        address: address,
                                        account: widget.account,
                                        addressTokens: tokens,
                                        transferBuilder: widget.transferBuilder));
                              },
                            );
                          },
                          itemCount: tokens.length,
                          addAutomaticKeepAlives: false,
                          addRepaintBoundaries: false)
                    ]));
          },
          enable: tokens != null)
    ]);
  }
}
