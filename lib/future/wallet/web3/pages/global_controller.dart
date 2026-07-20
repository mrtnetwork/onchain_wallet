import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';

import 'package:on_chain_wallet/future/wallet/web3/global/core/controller.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/widgets/parogress.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/wallet/models/access/wallet_access.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';
import 'client_info.dart';

typedef CbWeb3GlobalPageBuilder<T extends Web3GlobalRequestStateContoller> = Widget
    Function(BuildContext context, T controller);

class Web3GlobalPageRequestControllerView<T extends Web3GlobalRequestStateContoller>
    extends StatelessWidget {
  const Web3GlobalPageRequestControllerView(
      {super.key,
      required this.request,
      required this.builder,
      required this.controller,
      this.width = APPConst.maxViewWidth});
  final CbWeb3GlobalPageBuilder<T> builder;
  final T Function() controller;
  final Web3GlobalRequest request;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        request.onPopRequestPage();
      },
      child: AccessWalletView<WalletCredentialResponseLogin, WalletCredentialLogin>(
        request: WalletCredentialLogin.instance,
        appbar: AppBar(
          centerTitle: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(request.params.method.name.tr),
              Text(request.params.method.name, style: context.textTheme.bodySmall)
            ],
          ),
        ),
        subtitle:
            Web3ApplicationView(permission: request.authenticated, info: request.info),
        onAccsess: (_) {
          return StateBuilder(
              disposeStrategy: StateBuilderDisposeStrategy.onDispose,
              controller: controller,
              builder: (controller) {
                return StreamWeb3PageProgress(
                    controller: controller.controller,
                    initialWidget:
                        ProgressWithTextView(text: "web3_retrieval_requirment".tr),
                    builder: (context) => builder(context, controller));
              },
              repositoryId: request.info.requestId);
        },
      ),
    );
  }
}
