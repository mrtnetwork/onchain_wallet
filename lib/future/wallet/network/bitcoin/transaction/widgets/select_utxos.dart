import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/helper/utxo_lock_time.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/address_details.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/transaction/controllers/utxos.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/transaction/types/types.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';

class BitcoinTransactionSelectUtxos extends StatelessWidget {
  final BitcoinTransactionUtxosController form;
  const BitcoinTransactionSelectUtxos(this.form, {super.key});

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
                  onPressed: () => form.toggleAllUtxos((err) => context.showAlert(err)),
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
                              isActive: false,
                              // isActive: form.unsyncedAlert,
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
                              builder: (context, _) => Shimmer(
                                  onActive: (enable, context) => DisabledWidget(
                                        disabled: addressUtxos.isPending,
                                        ignoring: true,
                                        onActive: (context, _) => ContainerWithBorder(
                                          onRemoveWidget: switch (addressUtxos.status) {
                                            BitcoinAccountUtxosStatusPending() => Icon(
                                                Icons.sync,
                                                color: context.onPrimaryContainer,
                                              ),
                                            BitcoinAccountUtxosStatusErr(
                                              :final message
                                            ) =>
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
  final BitcoinTransactionUtxosController form;
  final BitcoinAccountFetchedUtxos utxos;

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
                    onPressed: () => form.toggleAllUtxos((err) => context.showAlert(err)),
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
                            final txId = utxo.utxo.utxo.txHash;
                            final bool coinbase = utxo.utxo.coinbase;
                            final confirmation = utxo.utxo.confirmation;
                            return ContainerWithBorder(
                              onRemove: () {
                                form.addUtxo(
                                  address: utxos,
                                  utxo: utxo,
                                  onErr: (err) => context.showAlert(err),
                                );
                              },
                              onRemoveWidget: switch (confirmation.confirmed) {
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
                                    RichText(
                                      text: TextSpan(
                                        text: coinbase
                                            ? "coinbase".tr
                                            : switch (utxo.inMempool) {
                                                false => "at".tr,
                                                true => "mempool".tr
                                              },
                                        children: [
                                          if (!utxo.inMempool)
                                            TextSpan(text: " (${utxo.blockHeight}) ")
                                        ],
                                        style: context.primaryTextTheme.labelSmall,
                                      ),
                                    )
                                  ]),
                                  OneLineTextWidget(txId,
                                      style: context.primaryTextTheme.bodyMedium),
                                  CoinAndMarketPriceView(
                                      showTokenImage: true,
                                      balance: utxo.balance,
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
