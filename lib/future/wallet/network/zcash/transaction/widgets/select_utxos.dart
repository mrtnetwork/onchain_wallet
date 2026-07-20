import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/helper/utxo_lock_time.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/address_details.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/transaction/controllers/utxos.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/transaction/types/types.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';

class ZcashTransactionSelectUtxos extends StatelessWidget {
  final ZcashTransactionUtxosController form;
  const ZcashTransactionSelectUtxos(this.form, {super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: Text("choose_utxos".tr),
          actions: [
            APPStreamBuilder(
              value: form.accountUtxos,
              builder: (context, value) {
                return TextButton.icon(
                  onPressed: () => form.toggleAllUtxos(context.showAlert),
                  label: Text("choose_all".tr),
                  icon: APPAnimated(
                      isActive: form.allUtxosSelected,
                      onActive: (context) => Icon(Icons.check_box),
                      onDeactive: (context) =>
                          Icon(Icons.check_box_outline_blank_outlined)),
                );
              },
            )
          ],
        ),
        SliverConstraintsBoxView(
            padding: WidgetConstant.padding20,
            sliver: APPStreamBuilder(
                value: form.accountUtxos,
                builder: (context, addresses) {
                  return MultiSliver(
                    children: [
                      SliverToBoxAdapter(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          APPAnimated(
                              isActive: !form.hasUtxos,
                              onActive: (context) => AlertTextContainer(
                                  message:
                                      "update_utxo_durning_build_transaction_desc".tr,
                                  enableTap: false)),
                          APPAnimated(
                              isActive: form.unsyncedAlert,
                              onActive: (context) => AlertTextContainer(
                                    message: "account_utxos_not_synced_desc".tr,
                                    enableTap: false,
                                  )),
                        ],
                      )),
                      SliverList.separated(
                          separatorBuilder: (context, index) => WidgetConstant.divider,
                          itemBuilder: (context, index) {
                            final addressUtxos = addresses[index];
                            return APPStreamBuilder(
                              value: addressUtxos.notifier,
                              builder: (context, value) => Shimmer(
                                  onActive: (enable, context) => DisabledWidget(
                                        ignoring: true,
                                        disabled: !addressUtxos.hasUtxos,
                                        onActive: (context, _) => ContainerWithBorder(
                                          onRemoveWidget: switch (addressUtxos.status) {
                                            ZcashAccountUtxosStatusPending() => Icon(
                                                Icons.sync,
                                                color: context.onPrimaryContainer,
                                              ),
                                            ZcashAccountUtxosStatusErr(:final message) =>
                                              IconButton(
                                                  tooltip: message,
                                                  onPressed: () {
                                                    form.getAccountsUtxos(
                                                        accountUtxos: [addressUtxos]);
                                                  },
                                                  icon: Icon(Icons.error,
                                                      color: context.colors.error)),
                                            _ => IconButton(
                                                onPressed: () {
                                                  if (!addressUtxos.hasUtxos) {
                                                    context.showAlert(
                                                        "no_available_utxos_found".tr);
                                                    return;
                                                  }
                                                  context.openDialogPage(
                                                    "",
                                                    child: (context) => _SelectUtxos(
                                                        form: form, utxos: addressUtxos),
                                                  );
                                                },
                                                icon: Icon(Icons.open_in_new_sharp,
                                                    color: context.onPrimaryContainer))
                                          },
                                          enableTap: addressUtxos.status.isSuccess,
                                          onRemove: () {
                                            context.openDialogPage(
                                              "",
                                              child: (context) => _SelectUtxos(
                                                  form: form, utxos: addressUtxos),
                                            );
                                          },
                                          child: AddressDetailsView(
                                            address: addressUtxos.address,
                                            chain: form.account,
                                          ),
                                        ),
                                      ),
                                  enable: !addressUtxos.isPending),
                            );
                          },
                          itemCount: addresses.length)
                    ],
                  );
                }))
      ],
    );
  }
}

class _SelectUtxos extends StatelessWidget {
  final ZcashTransactionUtxosController form;
  final ZcashAccountFetchedUtxos utxos;

  const _SelectUtxos({required this.form, required this.utxos});

  @override
  Widget build(BuildContext context) {
    return APPStreamBuilder(
        value: utxos.notifier,
        builder: (context, v) {
          final utxoData = utxos.utxos?.utxosWithBalance ?? [];
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: Text("choose_utxos".tr),
                actions: [
                  TextButton.icon(
                    onPressed: () => form.toggleAllAddressUtxos(utxos, context.showAlert),
                    label: Text("choose_all".tr),
                    icon: APPAnimated(
                        isActive: utxos.allSelected,
                        onActive: (context) => Icon(Icons.check_box),
                        onDeactive: (context) =>
                            Icon(Icons.check_box_outline_blank_outlined)),
                  ),
                ],
              ),
              EmptyItemSliverWidgetView(
                isEmpty: utxoData.isEmpty,
                itemBuilder: (context) => SliverConstraintsBoxView(
                    padding: WidgetConstant.padding20,
                    sliver: MultiSliver(
                      children: [
                        SliverPinnedHeaderSurface(
                          child: ContainerWithBorder(
                            child: CoinAndMarketPriceView(
                                balance: utxos.totalUtxo,
                                symbolColor: context.onPrimaryContainer,
                                showTokenImage: true,
                                style: context.onPrimaryTextTheme.titleMedium),
                          ),
                        ),
                        SliverList.builder(
                          itemCount: utxoData.length,
                          itemBuilder: (context, pos) {
                            final utxo = utxoData[pos];
                            final txId = utxo.utxo.txId().txId;
                            final bool coinbase = utxo.utxo.utxo.coinbase;
                            final confirmation = utxo.utxo.confirmation;
                            return ContainerWithBorder(
                              onRemove: () {
                                form.addUtxo(
                                  address: utxos,
                                  utxo: utxo,
                                  onErr: (s) => context.showAlert(s.tr),
                                );
                              },
                              onRemoveWidget: switch (confirmation.confirmed) {
                                true when !form.accountSynced && utxo.protocol.sheilded =>
                                  ToolTipView(
                                    message:
                                        "spending_sheild_utxos_synchronization_required_desc"
                                            .tr,
                                    child: Icon(Icons.sync_disabled_rounded,
                                        color: context.primaryContainer),
                                  ),
                                true => APPCheckBox(
                                    value: utxos.isSelected(utxo),
                                    backgroundColor: context.primaryContainer,
                                    color: context.onPrimaryContainer,
                                  ),
                                false => confirmation.tooltip(context.primaryContainer),
                              },
                              backgroundColor: context.onPrimaryContainer,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(
                                        child: Text(
                                      utxo.address.protocol.name.tr,
                                      style: context.primaryTextTheme.labelLarge,
                                    )),
                                    RichText(
                                      text: TextSpan(
                                        text: coinbase ? "coinbase".tr : "at".tr,
                                        children: [
                                          TextSpan(
                                              text: " (${utxo.utxo.utxo.blockHeight})")
                                        ],
                                        style: context.primaryTextTheme.labelSmall,
                                      ),
                                    )
                                  ]),
                                  OneLineTextWidget(txId,
                                      style: context.primaryTextTheme.bodyMedium),
                                  CoinAndMarketPriceView(
                                      showTokenImage: true,
                                      balance: utxo.amount,
                                      style: context.primaryTextTheme.titleMedium,
                                      symbolColor: context.primaryContainer),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    )),
              )
            ],
          );
        });
  }
}
