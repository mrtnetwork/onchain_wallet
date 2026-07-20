import 'package:flutter/material.dart';
import 'package:on_chain/ethereum/src/address/evm_address.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/transaction/operations/ibc.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/transaction/operations/transfer.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

List<PopupMenuItem<int>> cosmosAccountMenuButton(
    {required CosmosChain account, required BuildContext context, required int value}) {
  if (!account.haveAddress) return [];
  final address = account.addressSyncOrNull?.ethAddress;
  if (address != null) {
    return [
      PopupMenuItem<int>(
        value: value,
        onTap: () {
          context.openSliverDialog(
              widget: (context) => _ShowEthAddress(address: address),
              label: "ethereum_address".tr);
        },
        child: AppListTile(
          trailing: const Icon(Icons.north_east_sharp),
          title: Text("ethereum_address".tr, style: context.textTheme.labelMedium),
        ),
      ),
    ];
  }
  return [];
}

class _ShowEthAddress extends StatelessWidget {
  const _ShowEthAddress({required this.address});
  final ETHAddress address;
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ContainerWithBorder(
        onRemove: () {},
        enableTap: false,
        onRemoveWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CopyTextIcon(
                dataToCopy: address.address,
                color: context.onPrimaryContainer,
                isSensitive: false),
            BarcodeImageIconView(
                data: address.address,
                color: context.onPrimaryContainer,
                isSensitive: false)
          ],
        ),
        child: Text(address.address),
      ),
    ]);
  }
}

class CosmosAccountPageView extends StatelessWidget {
  const CosmosAccountPageView({required this.chainAccount, super.key});
  final CosmosChain chainAccount;
  @override
  Widget build(BuildContext context) {
    return TabBarView(physics: WidgetConstant.noScrollPhysics, children: [
      _CosmosAccountPageView(chainAccount),
      AccountTokensView(
          account: chainAccount,
          transferBuilder: (p0) {
            return CosmosTransactionTransferOperation(
                walletProvider: context.wallet,
                account: chainAccount,
                address: chainAccount.addressSync);
          }),
      AccountTransactionActivityView<CosmosWalletTransaction, ICosmosAddress>(
          account: chainAccount, address: chainAccount.addressSync)
    ]);
  }
}

class _CosmosAccountPageView extends StatelessWidget {
  const _CosmosAccountPageView(this.chainAccount);
  final CosmosChain chainAccount;

  @override
  Widget build(BuildContext context) {
    return AccountTabbarScrollWidget(slivers: [
      SliverToBoxAdapter(
        child: Column(children: [
          AppListTile(
            title: Text("ibc_transfer".tr),
            subtitle: Text("ibc_desc".tr),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              final operation = CosmosTransactionIbcTransferOperation(
                  walletProvider: context.wallet,
                  account: chainAccount,
                  address: chainAccount.addressSync);
              context.to(PageRouter.transaction, argruments: operation);
            },
          )
        ]),
      )
    ]);
  }
}
