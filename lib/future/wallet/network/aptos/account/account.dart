import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/network/aptos/transaction/transaction.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class AptosAccountPageView extends StatelessWidget {
  const AptosAccountPageView({required this.chainAccount, super.key});
  final AptosChain chainAccount;
  @override
  Widget build(BuildContext context) {
    return TabBarView(physics: WidgetConstant.noScrollPhysics, children: [
      _AptosServices(account: chainAccount),
      AccountTokensView<AptosFATokens, IAptosAddress>(
        account: chainAccount,
        transferBuilder: (token) {
          return AptosTransactionTransferTokenOperation(
              address: chainAccount.addressSync,
              account: chainAccount,
              walletProvider: context.wallet,
              token: token);
        },
      ),
      AccountTransactionActivityView<AptosWalletTransaction, IAptosAddress>(
          account: chainAccount, address: chainAccount.addressSync)
    ]);
  }
}

class _AptosServices extends StatelessWidget {
  const _AptosServices({required this.account});
  final AptosChain account;
  IAptosAddress get address => account.addressSync;

  @override
  Widget build(BuildContext context) {
    return AccountTabbarScrollWidget(slivers: [
      SliverToBoxAdapter(
        child: Column(
          children: [
            AppListTile(
              trailing: const Icon(Icons.arrow_forward),
              title: Text("aptos_key_conversion".tr),
              subtitle: Text("aptos_key_conversion_desc".tr),
              onTap: () {
                context.to(PageRouter.aptosKeyConversion);
              },
            ),
          ],
        ),
      ),
    ]);
  }
}
