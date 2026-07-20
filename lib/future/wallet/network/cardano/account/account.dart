import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/transaction_activity.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain/ada/src/address/era/shelly/ada_reward_address.dart';

List<PopupMenuItem<int>> cardanoAccountMenuButton(
    {required ADAChain account, required BuildContext context, required int value}) {
  if (!account.haveAddress) return [];
  final address = account.addressSync;
  if (!address.isRewardAddress && address.rewardAddress != null) {
    return [
      PopupMenuItem<int>(
        value: value,
        onTap: () {
          context.openSliverDialog(
              widget: (context) => _ShowRewardAddress(chainAccount: account.addressSync),
              label: "reward_address".tr);
        },
        child: AppListTile(
          trailing: const Icon(Icons.north_east_sharp),
          title: Text("reward_address".tr, style: context.textTheme.labelMedium),
        ),
      ),
    ];
  }
  return [];
}

class CardanoAccountPageView extends StatelessWidget {
  const CardanoAccountPageView({required this.chainAccount, super.key});
  final ADAChain chainAccount;
  @override
  Widget build(BuildContext context) {
    return TabBarView(physics: WidgetConstant.noScrollPhysics, children: [
      _CardanoAccountPage(chainAccount: chainAccount),
      AccountTransactionActivityView<ADAWalletTransaction, ICardanoAddress>(
          account: chainAccount, address: chainAccount.addressSync)
    ]);
  }
}

class _CardanoAccountPage extends StatelessWidget {
  const _CardanoAccountPage({required this.chainAccount});
  final ADAChain chainAccount;

  @override
  Widget build(BuildContext context) {
    return AccountTabbarScrollWidget(slivers: []);
  }
}

class _ShowRewardAddress extends StatelessWidget {
  const _ShowRewardAddress({required this.chainAccount});
  final ICardanoAddress chainAccount;
  @override
  Widget build(BuildContext context) {
    final ADARewardAddress? rewardAddress = chainAccount.rewardAddress;
    if (rewardAddress == null) return WidgetConstant.sizedBox;
    return Column(children: [
      ContainerWithBorder(
        onRemove: () {},
        enableTap: false,
        onRemoveWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CopyTextIcon(
                dataToCopy: rewardAddress.address,
                color: context.onPrimaryContainer,
                isSensitive: false),
            BarcodeImageIconView(
                data: rewardAddress.address,
                color: context.onPrimaryContainer,
                isSensitive: false)
          ],
        ),
        child: Text(rewardAddress.address),
      ),
    ]);
  }
}
