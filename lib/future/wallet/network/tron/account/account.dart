import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/tranasction.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';

class TronAccountPageView extends StatelessWidget {
  const TronAccountPageView({required this.chainAccount, super.key});
  final TronChain chainAccount;
  @override
  Widget build(BuildContext context) {
    return NotificationListener(
      onNotification: (notification) => false,
      child: TabBarView(physics: WidgetConstant.noScrollPhysics, children: [
        _Services(chainAccount),
        AccountTokensView<TronToken, ITronAddress>(
          account: chainAccount,
          // importPage: ,
          transferBuilder: (p0) {
            if (p0.tronTokenType.isTrc10) {
              return TronTransactionTransferTRC10TokenOperation(
                  walletProvider: context.wallet,
                  account: chainAccount,
                  address: chainAccount.addressSync,
                  token: p0 as TronTRC10Token);
            }
            return TronTransactionTransferTRC20TokenOperation(
                walletProvider: context.wallet,
                account: chainAccount,
                address: chainAccount.addressSync,
                token: p0 as TronTRC20Token);
          },
        ),
        AccountTransactionActivityView<TronWalletTransaction, ITronAddress>(
            account: chainAccount, address: chainAccount.addressSync)
      ]),
    );
  }
}

class _Services extends StatelessWidget {
  const _Services(this.chainAccount);
  final TronChain chainAccount;
  ITronAddress get account => chainAccount.addressSync;
  @override
  Widget build(BuildContext context) {
    return AccountTabbarScrollWidget(slivers: [
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppListTile(
              title: Text("import_trc20_token".tr),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                context.to(PageRouter.importTronToken);
              },
            ),
            WidgetConstant.divider,
            AppListTile(
              title: Text("update_account_permission".tr),
              subtitle: Text("update_account_permissions".tr),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                final r = TronTransactionAccountPermissionUpdateContractOperation(
                    walletProvider: context.wallet,
                    account: chainAccount,
                    address: account);
                context.to(PageRouter.transaction, argruments: r);
              },
            ),
            AppListTile(
              title: Text("update_account".tr),
              subtitle: Text("modify_account_name".tr),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                final r = TronTransactionAccountUpdateContractOperation(
                    walletProvider: context.wallet,
                    account: chainAccount,
                    address: account);
                context.to(PageRouter.transaction, argruments: r);
              },
            ),
            WidgetConstant.divider,
            AppListTile(
              title: Text("tron_stack_v2".tr),
              trailing: const Icon(Icons.arrow_forward),
              subtitle: Text("frozen_balance".tr),
              onTap: () {
                final r = TronTransactionFreezeBalanceV2ContractOperation(
                    walletProvider: context.wallet,
                    account: chainAccount,
                    address: account);
                context.to(PageRouter.transaction, argruments: r);
              },
            ),
            AppListTile(
              title: Text("tron_unstack_v2".tr),
              trailing: const Icon(Icons.arrow_forward),
              subtitle: Text("unfreeze_balance".tr),
              onTap: () {
                final r = TronTransactionUnFreezeBalanceV2ContractOperation(
                    walletProvider: context.wallet,
                    account: chainAccount,
                    address: account);
                context.to(PageRouter.transaction, argruments: r);
              },
            ),
            AppListTile(
              title: Text("delegated_resource".tr),
              subtitle: Text("delegate_resource_desc".tr),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                final r = TronTransactionDelegateResourceContractOperation(
                    walletProvider: context.wallet,
                    account: chainAccount,
                    address: account);
                context.to(PageRouter.transaction, argruments: r);
              },
            ),
            AppListTile(
              title: Text("undelegated_resource".tr),
              subtitle: Text("undelegated_resource_desc".tr),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                final r = TronTransactionUnDelegateResourceContractOperation(
                    walletProvider: context.wallet,
                    account: chainAccount,
                    address: account);
                context.to(PageRouter.transaction, argruments: r);
              },
            ),
            WidgetConstant.divider,
            AppListTile(
              title: Text("create_witness".tr),
              subtitle: Text("create_witness_desc".tr),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                final r = TronTransactionWitnessCreateContractOperation(
                    walletProvider: context.wallet,
                    account: chainAccount,
                    address: account);
                context.to(PageRouter.transaction, argruments: r);
              },
            ),
            AppListTile(
              title: Text("update_witness".tr),
              subtitle: Text("update_witness_desc".tr),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                final r = TronTransactionWitnessUpdateContractOperation(
                    walletProvider: context.wallet,
                    account: chainAccount,
                    address: account);
                context.to(PageRouter.transaction, argruments: r);
              },
            ),
          ],
        ),
      )
    ]);
  }
}
