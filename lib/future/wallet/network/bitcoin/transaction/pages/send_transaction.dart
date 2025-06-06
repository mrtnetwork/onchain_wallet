import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/account/pages/account_controller.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/address_details.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/controller/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/transaction/pages/build_transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/controller/impl/transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/transaction/pages/utxo_view.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

class SendBitcoinTransactionView extends StatelessWidget {
  const SendBitcoinTransactionView({super.key});

  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<BitcoinClient, IBitcoinAddress,
        BitcoinChain>(
      addressRequired: true,
      clientRequired: true,
      childBulder: (wallet, account, client, address, onAccountChanged) {
        return StateBuilder<BitcoinStateController>(
          controller: () => BitcoinStateController(
              walletProvider: wallet, account: account, apiProvider: client),
          repositoryId: StateConst.bitcoin,
          builder: (controller) {
            return PopScope(
              canPop: controller.canPopPage,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) {
                  controller.onBackButton();
                }
              },
              child: Scaffold(
                appBar: AppBar(title: Text("build_transacation".tr)),
                floatingActionButton:
                    APPAnimatedSwitcher(enable: controller.page, widgets: {
                  BitcoinTransactionPages.send: (context) => null,
                  BitcoinTransactionPages.account: (context) => APPAnimatedSize(
                      isActive: controller.hasSpender,
                      onActive: (context) => FloatingActionButton.extended(
                          onPressed: controller.hasSpender
                              ? controller.fetchUtxos
                              : null,
                          label: Text("get_unspent_transaction".tr)),
                      onDeactive: (context) => WidgetConstant.sizedBox),
                  BitcoinTransactionPages.utxo: (context) => APPAnimatedSize(
                      isActive: controller.canBuildTransaction,
                      onActive: (context) => FloatingActionButton.extended(
                          onPressed: controller.canBuildTransaction
                              ? controller.onSetupUtxo
                              : null,
                          label: Text("setup_recipients".tr)),
                      onDeactive: (context) => WidgetConstant.sizedBox),
                }),
                body: PageProgress(
                  key: controller.progressKey,
                  backToIdle: APPConst.oneSecoundDuration,
                  initialStatus: StreamWidgetStatus.progress,
                  initialWidget: ProgressWithTextView(
                      text: "retrieving_network_condition".tr),
                  child: (context) => CustomScrollView(
                    slivers: [
                      SliverConstraintsBoxView(
                        padding: WidgetConstant.paddingHorizontal20,
                        sliver: APPSliverAnimatedSwitcher(
                            enable: controller.page,
                            widgets: {
                              BitcoinTransactionPages.send: (context) =>
                                  BitcoinBuildTransactionView(
                                      controller: controller),
                              BitcoinTransactionPages.account: (context) =>
                                  SelectAccountUtxo(controller: controller),
                              BitcoinTransactionPages.utxo: (context) =>
                                  BitcoinTransactionUtxoView(
                                      controller: controller),
                            }),
                      ),
                      WidgetConstant.sliverPaddingVertial40,
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class SelectAccountUtxo extends StatefulWidget {
  const SelectAccountUtxo(
      {super.key,
      required this.controller,
      this.toggleTokenUtxos,
      this.includeTokenUtxos});
  final BitcoinTransactionImpl controller;
  final DynamicVoid? toggleTokenUtxos;
  final bool? includeTokenUtxos;

  @override
  State<SelectAccountUtxo> createState() => _SelectAccountUtxoState();
}

class _SelectAccountUtxoState extends State<SelectAccountUtxo> with SafeState {
  late final List<IBitcoinAddress> addresses = [
    widget.controller.account.address,
    ...widget.controller.account.addresses
        .where((e) => e != widget.controller.account.address)
        .toList()
      ..sort((a, b) => a.address.hasBalance ? 0 : 1)
  ];

  late final IBitcoinAddress currentAccount = addresses.first;
  bool showAll = false;

  void toggleShowAll() {
    showAll = !showAll;
    updateState();
    if (!showAll) {
      bool alert = false;
      for (final i in addresses) {
        if (i == currentAccount) continue;
        if (widget.controller
            .addressSelected(i.networkAddress.addressProgram)) {
          widget.controller.addAccount(i);
          alert = true;
        }
      }
      if (alert) {
        context.showAlert("accounts_removed_from_spending_list".tr);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.controller.isBCH)
              if (widget.includeTokenUtxos != null)
                AppSwitchListTile(
                  value: widget.includeTokenUtxos!,
                  onChanged: (p0) => widget.toggleTokenUtxos!(),
                  title: Text("token_utxos".tr),
                  subtitle: Text("includ_token_utxos".tr),
                ),
            Text("accounts".tr, style: context.textTheme.titleMedium),
            Text("please_selected_acc_spend"
                .tr
                .replaceOne(widget.controller.network.coinParam.token.name)),
            WidgetConstant.height8,
            AppSwitchListTile(
              value: showAll,
              title: Text("display_all_account".tr),
              subtitle: Text("spending_from_multiple_account".tr),
              onChanged: (p0) => toggleShowAll(),
            ),
            WidgetConstant.height8,
            ContainerWithBorder(
                backgroundColor: context.colors.secondary,
                onRemoveIcon: APPCheckBox(
                    backgroundColor: context.colors.onSecondary,
                    color: context.colors.secondary,
                    ignoring: true,
                    value: widget.controller.addressSelected(
                        currentAccount.networkAddress.addressProgram),
                    onChanged: (_) {}),
                onRemove: () {
                  widget.controller.addAccount(currentAccount);
                },
                validate: currentAccount.address.hasBalance,
                child: AddressDetailsView(
                  address: currentAccount,
                  color: context.colors.onSecondary,
                )),
          ],
        ),
      ),
      APPSliverAnimatedSwitcher(enable: showAll, widgets: {
        true: (context) => SliverList.separated(
              separatorBuilder: (context, index) => WidgetConstant.divider,
              itemBuilder: (context, index) {
                final bool isSelected = currentAccount == addresses[index];
                if (isSelected) return WidgetConstant.sizedBox;
                final balance = addresses[index].address.currencyBalance;
                final bool canSpend = balance > BigInt.zero;
                return ContainerWithBorder(
                    validate: canSpend,
                    // validateText: "lacks_an_utxos".tr,
                    onRemoveIcon: Checkbox(
                      value: widget.controller.addressSelected(
                          addresses[index].networkAddress.addressProgram),
                      onChanged: (value) {
                        widget.controller.addAccount(addresses[index]);
                      },
                    ),
                    onRemove: () {
                      widget.controller.addAccount(addresses[index]);
                    },
                    child: AddressDetailsView(
                        address: addresses[index],
                        color: context.colors.onPrimaryContainer));
              },
              itemCount: addresses.length,
            ),
      }),
    ]);
  }
}
