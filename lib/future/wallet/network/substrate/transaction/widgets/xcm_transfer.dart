import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/operations/xcm_transfer.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/types/xcm_types.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/widgets/prick_token.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/widgets/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/widgets/substrate_transaction_fee.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/future/widgets/widgets/json/json/widgets.dart';
import 'package:on_chain_wallet/wallet/chain/chain/chain.dart';
import 'package:polkadot_dart/polkadot_dart.dart';

class SubstrateTransactionXCMTransferWidget extends StatelessWidget {
  final SubstrateTransactionXCMTransferOperation form;
  final BuildContext mainContext;
  const SubstrateTransactionXCMTransferWidget(
      {required this.form, required this.mainContext, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      WidgetConstant.height20,
      LiveFormWidget(
          field: form.destination,
          builder: (context, field, value) {
            return APPAnimated(
              onDeactive: (context) => ContainerWithBorder(
                  onRemoveWidget: AddOrEditIconWidget(false),
                  onRemove: () {
                    context
                        .openSliverDialog<SubstrateChain>(
                            label: "destination_network".tr,
                            sliver: (context) => _SelectDestinationChain(form.routes))
                        .then(form.onUpdateDestination);
                  },
                  child: Text("tap_to_choose_destination".tr)),
              isActive: value != null,
              onActive: (context) => APPStreamBuilder(
                  value: value!.notifier,
                  builder: (context, _) {
                    return _TransferForm(
                      form: form,
                      transfer: value,
                      mainContext: mainContext,
                    );
                  }),
            );
          }),
    ]);
  }
}

class _TransferForm extends StatelessWidget {
  final SubstrateTransactionXCMTransferOperation form;
  final SubstrateXCMTransferDetails transfer;
  final BuildContext mainContext;
  const _TransferForm(
      {required this.form, required this.transfer, required this.mainContext});
  @override
  Widget build(Object context) {
    final destinationChain = transfer.destinationChain;
    return ConditionalWidget(
      enable: !transfer.initStatus.isIdle,
      onActive: (context) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ContainerWithBorder(
            onRemoveIcon: EditOrRemoveIconWidget(false),
            onRemove: () {
              context
                  .openSliverDialog<SubstrateChain>(
                      label: "destination_network".tr,
                      sliver: (context) => _SelectDestinationChain(form.routes))
                  .then(form.onUpdateDestination);
            },
            child: AccountTokenDetailsWidget(
                token: destinationChain.network.network.token,
                radius: APPConst.circleRadius25),
          ),
          WidgetConstant.height20,
          Shimmer(
              enable: !transfer.initStatus.isPending,
              onActive: (enable, context) {
                return ConditionalWidget(
                    onDeactive: (context) => ErrorTextContainer(
                          error: transfer.status.error,
                          enableTap: false,
                          oTapError: () => transfer.init(),
                        ),
                    enable: !transfer.initStatus.isError,
                    onActive: (context) =>
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          ReceiptAddressView(
                            onTap: () {
                              context
                                  .selectAccount<BaseSubstrateAddress>(
                                      account: transfer.destinationChain.network)
                                  .then(
                                (v) {
                                  final address = v?.firstOrNull;
                                  form.onUpdateReceipt(transfer, address);
                                },
                              );
                            },
                            address: transfer.receipt,
                          ),
                          WidgetConstant.height20,
                          FormWidgetList(
                              title: "transfers".tr,
                              subtitle: "list_of_transfers".tr,
                              values: transfer.transfers,
                              onCreate: (context) {
                                if (!transfer.allowAddTransfer) return null;
                                return ContainerWithBorder(
                                  validate: transfer.transfers.isNotEmpty,
                                  onRemoveWidget: AddOrEditIconWidget(false),
                                  onRemove: () {
                                    context
                                        .openMaxExtendSliverBottomSheet<
                                            SubstrateTokenDetails>(
                                          "fee_token".tr,
                                          centerContent: false,
                                          bodyBuilder: (sc) =>
                                              SubstrateTransactionPickTokenView(
                                                  controller: sc,
                                                  onFilter: transfer.onFilterToken,
                                                  tokens: transfer.availableTokens
                                                      .map((e) => e.tokenDetails)
                                                      .toList()),
                                        )
                                        .then((v) => form.onUpdateToken(transfer, v));
                                  },
                                  child: Text("tap_to_select_token".tr,
                                      style: context.onPrimaryTextTheme.bodyMedium),
                                );
                              },
                              builder: (context, amount) {
                                return CustomizedContainer(
                                  onTapStackIcon: () {
                                    form.onRemoveTransfer(transfer, amount);
                                  },
                                  onStackIcon: Icons.remove_circle,
                                  validate: amount.hasAmount && amount.minReached,
                                  validateText: amount.minError,
                                  enableTap: false,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ContainerWithBorder(
                                        backgroundColor: context.onPrimaryContainer,
                                        child: AccountTokenDetailsWidget(
                                            color: context.primaryContainer,
                                            token: amount.token.token,
                                            liveBalance:
                                                amount.token.tokenDetails.balance,
                                            radius: APPConst.circleRadius25),
                                      ),
                                      ContainerWithBorder(
                                          validate: amount.hasAmount,
                                          onRemove: () {
                                            context
                                                .setupAmount(
                                                    token: amount.token.token,
                                                    min: amount.minAmount.balance,
                                                    max: form.getMaxInput(amount))
                                                .then((v) {
                                              if (v == null) {
                                                return;
                                              }
                                              form.onUpdateAmount(
                                                  transfer, amount, v, false);
                                            });
                                          },
                                          // validate: transfer.hasAmount,
                                          onRemoveIcon: Icon(Icons.edit,
                                              color: context.primaryContainer),
                                          backgroundColor: context.onPrimaryContainer,
                                          child: CoinAndMarketPriceView(
                                              balance: amount.amount,
                                              style: context.primaryTextTheme.titleMedium,
                                              showTokenImage: true,
                                              symbolColor: context.primaryContainer)),
                                    ],
                                  ),
                                );
                              }),
                          ConditionalWidget(
                            enable: transfer.haveTransfer,
                            onActive: (context) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                WidgetConstant.height20,
                                Text("destination_fee".tr,
                                    style: context.textTheme.titleMedium),
                                Text("choose_token_for_fee_on_destination_desc".tr),
                                WidgetConstant.height8,
                                ConditionalWidget(
                                  enable: transfer.feeTokens.isNotEmpty,
                                  onActive: (context) {
                                    return AppDropDownBottomWithBorder(
                                      isDense: false,
                                      isExpanded: true,
                                      value: transfer.destinationFee?.token,
                                      onChanged: (v) =>
                                          form.onUpdateDestinationFeeToken(transfer, v),
                                      items: {
                                        for (final i in transfer.feeTokens)
                                          i: AccountTokenDetailsWidget(
                                              color: context.onPrimaryContainer,
                                              token: i.token,
                                              radius: APPConst.circleRadius25)
                                      },
                                    );
                                  },
                                  onDeactive: (context) => ErrorTextContainer(
                                      error:
                                          "no_tokens_available_for_paying_fees_destination_desc"
                                              .tr),
                                )
                              ],
                            ),
                          ),
                          _FullDryRunView(transfer),
                          _TransferGenericWidgets(form: form, mainContext: mainContext),
                        ]));
              })
        ]);
      },
    );
  }
}

class _FullDryRunView extends StatelessWidget {
  final SubstrateXCMTransferDetails transfer;
  const _FullDryRunView(this.transfer);

  @override
  Widget build(BuildContext context) {
    return APPStreamBuilder(
      value: transfer.dryRun.notifier,
      builder: (context, _) {
        return ConditionalWidget(
          enable: !transfer.dryRun.status.isIdle,
          onActive: (context) => Shimmer(
              onActive: (enable, context) {
                final dryRun = transfer.dryRun;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WidgetConstant.height20,
                    Text("simulate_transaction".tr, style: context.textTheme.titleMedium),
                    Text("dry_run_local_destination_desc".tr),
                    WidgetConstant.height8,
                    ConditionalWidgets<SubstrateXCMDestinationFeeStatus>(
                      enable: dryRun.status,
                      widgets: {
                        SubstrateXCMDestinationFeeStatus.failed: (context) =>
                            ErrorTextContainer(
                                error: dryRun.error ?? "transaction_simulation_failed".tr,
                                enableTap: false,
                                errorIcon:
                                    dryRun.xcmDryRun == null ? null : Icons.open_in_full,
                                oTapError: () {
                                  if (dryRun.xcmDryRun == null) {
                                    transfer.onStateUpdated();
                                    return;
                                  }
                                  context.openDialogPage('',
                                      child: (context) => JsonView(
                                          text: dryRun.xcmDryRun!.toJson(),
                                          title: 'content'.tr));
                                }),
                        SubstrateXCMDestinationFeeStatus.unsuported: (context) =>
                            AlertTextContainer(
                                enableTap: false, message: "unsupport_simulation".tr),
                        SubstrateXCMDestinationFeeStatus.pending: (context) =>
                            ShimmerWidget(),
                        SubstrateXCMDestinationFeeStatus.success: (context) {
                          final dryRun = transfer.dryRun.xcmDryRun;
                          if (dryRun == null) return WidgetConstant.sizedBox;
                          return Column(children: [
                            _DryRrunView(dryRun.call),
                            ...List.generate(
                                dryRun.routes.length,
                                (i) =>
                                    _DryRrunView(transfer.dryRun.xcmDryRun!.routes[i])),
                            _DryRunFees(
                                title: "xcm_deliveries_fee".tr, fees: dryRun.localFees),
                            _DryRunFees(
                                title: "destination_fee".tr,
                                fees: dryRun.destinationFees),
                          ]);
                        }
                      },
                    ),
                  ],
                );
              },
              enable: !transfer.dryRun.status.isPending),
        );
      },
    );
  }
}

class _DryRrunView extends StatelessWidget {
  final SubstrateXCMCallDryRun dryRun;
  const _DryRrunView(this.dryRun);

  @override
  Widget build(BuildContext context) {
    return ContainerWithBorder(
        validate: dryRun.status.isSuccess,
        child: Column(children: [
          ConditionalWidget(
            enable: dryRun.network != null,
            onActive: (context) => ContainerWithBorder(
              backgroundColor: context.onPrimaryContainer,
              child: Text(dryRun.network!.networkName,
                  style: context.primaryTextTheme.bodyMedium),
            ),
          ),
          ConditionalWidget(
              enable: dryRun.dryRunContent != null,
              onActive: (context) => ContainerWithBorder(
                    backgroundColor: context.onPrimaryContainer,
                    onRemoveIcon:
                        Icon(Icons.open_in_full, color: context.primaryContainer),
                    onRemove: () {
                      context.openDialogPage('',
                          child: (context) =>
                              JsonView(text: dryRun.dryRunContent!, title: 'content'.tr));
                    },
                    child: Text("content".tr, style: context.primaryTextTheme.bodyMedium),
                  )),
          ConditionalWidgets(enable: dryRun.status, widgets: {
            SubstrateXCMDryRunStatus.unsuported: (context) => AlertTextContainer(
                  message: dryRun.network == null
                      ? "unknown_network".tr
                      : "unsupport_simulation".tr,
                  enableTap: false,
                ),
            SubstrateXCMDryRunStatus.failed: (context) => ErrorTextContainer(
                  error: "transaction_simulation_failed".tr,
                  enableTap: false,
                ),
            SubstrateXCMDryRunStatus.feeFailed: (context) => ErrorTextContainer(
                  error: "fee_estimate_failed".tr,
                  enableTap: false,
                ),
          }),
        ]));
  }
}

class _TransferGenericWidgets extends StatelessWidget {
  final SubstrateTransactionXCMTransferOperation form;
  final BuildContext mainContext;
  const _TransferGenericWidgets({required this.form, required this.mainContext});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WidgetConstant.height20,
        ConditionalWidget(
            enable: form.supportBatch,
            onActive: (context) =>
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  WidgetConstant.height20,
                  LiveFormWidgetList(
                      field: form.memos,
                      builder: (context, field, value) => ContainerWithBorder(
                          onRemove: () {
                            form.onRemoveMemo(value);
                          },
                          onRemoveIcon: Icon(Icons.remove_circle,
                              color: context.onPrimaryContainer),
                          child:
                              Text(value, style: context.onPrimaryTextTheme.bodyMedium)),
                      onCreate: (context, field) {
                        return ContainerWithBorder(
                            onRemoveIcon:
                                Icon(Icons.add_box, color: context.onPrimaryContainer),
                            onRemove: () {
                              context
                                  .openSliverBottomSheet<String>(
                                    "transaction_memo".tr,
                                    child: StringWriterView(
                                        title: PageTitleSubtitle(
                                            title: "setup_memo".tr,
                                            body: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text("memo_desc1".tr),
                                                WidgetConstant.height8,
                                                Text("empty_desc".tr),
                                              ],
                                            )),
                                        buttonText: "setup_memo".tr,
                                        label: "memo".tr),
                                  )
                                  .then(form.onUpdateMemo);
                            },
                            child: Text("tap_to_add_memo".tr,
                                style: context.onPrimaryTextTheme.bodyMedium));
                      }),
                ])),
        WidgetConstant.height20,
        APPStreamBuilder(
          value: form.feeToken.live,
          builder: (context, v) {
            return SubstrateTransactionFeeWidget(
                fee: form.txFee,
                onSelectToken: form.onUpdateFeeToken,
                onRetryFeeEstimate: form.estimateFee,
                feeToken: v,
                feeTokens: form.feeTokens);
          },
        ),
        SubstrateTransactionStateSendTransaction<ISubstrateXCMTransactionData>(
            controller: form, mainContext: mainContext)
      ],
    );
  }
}

class _SelectDestinationChain extends StatelessWidget {
  final List<SubstrateChain> chains;
  const _SelectDestinationChain(this.chains);

  @override
  Widget build(BuildContext context) {
    return SliverConstraintsBoxView(
      padding: WidgetConstant.padding20,
      sliver: MultiSliver(children: [
        Text("destination_network".tr, style: context.textTheme.titleMedium),
        Text("choose_network_transfer_to_desc".tr),
        WidgetConstant.height8,
        EmptyItemSliverWidgetView(
          isEmpty: chains.isEmpty,
          itemBuilder: (context) {
            return SliverList.separated(
                itemCount: chains.length,
                itemBuilder: (context, index) {
                  final chain = chains[index];
                  return ContainerWithBorder(
                    onRemoveWidget: WidgetConstant.sizedBox,
                    onRemove: () => context.pop(chain),
                    child: AccountTokenDetailsWidget(
                        token: chain.network.token, radius: APPConst.circleRadius25),
                  );
                },
                separatorBuilder: (context, index) => const Divider());
          },
        ),
      ]),
    );
  }
}

class _DryRunFees extends StatelessWidget {
  final String title;
  final List<SubstrateXCMTransferToken> fees;
  const _DryRunFees({required this.title, required this.fees});

  @override
  Widget build(BuildContext context) {
    return ConditionalWidget(
      enable: fees.isNotEmpty,
      onActive: (context) => ContainerWithBorder(
        child: APPExpansionListTile(
          margin: WidgetConstant.padding5,
          title: Text(title.tr, style: context.primaryTextTheme.bodyMedium),
          color: context.onPrimaryContainer,
          reverse: context.primaryContainer,
          children: [
            ContainerWithBorder(
              child: Column(
                children: List.generate(
                  fees.length,
                  (index) {
                    final amount = fees[index];
                    return ContainerWithBorder(
                      backgroundColor: context.onPrimaryContainer,
                      child: CoinAndMarketPriceView(
                          balance: amount.amount,
                          showTokenImage: true,
                          disableTooltip: false,
                          style: context.primaryTextTheme.titleMedium,
                          symbolColor: context.primaryContainer),
                    );
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
