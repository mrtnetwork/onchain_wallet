import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/transaction/operations/transfer_token.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';

class ETHAccountPageView extends StatelessWidget {
  const ETHAccountPageView({required this.chainAccount, super.key});
  final EthereumChain chainAccount;
  @override
  Widget build(BuildContext context) {
    return TabBarView(physics: WidgetConstant.noScrollPhysics, children: [
      _EtherumServices(chainAccount),
      AccountTokensView<ETHERC20Token, IEthereumAddress>(
        account: chainAccount,
        importTokenPage: PageRouter.importERC20Token,
        transferBuilder: (p0) {
          return EthereumTransactionTransferTokenOperation(
              address: chainAccount.addressSync,
              account: chainAccount,
              walletProvider: context.wallet,
              token: p0);
        },
      ),
      AccountTransactionActivityView<EthWalletTransaction, IEthereumAddress>(
          account: chainAccount, address: chainAccount.addressSync)
    ]);
  }
}

class _EtherumServices extends StatelessWidget {
  final EthereumChain account;
  const _EtherumServices(this.account);

  @override
  Widget build(BuildContext context) {
    return AccountTabbarScrollWidget(slivers: [
      SliverToBoxAdapter(
        child: AppListTile(
          title: Text("import_erc20_token".tr),
          onTap: () {
            context.to(PageRouter.importERC20Token);
          },
        ),
      ),
    ]);
  }
}
