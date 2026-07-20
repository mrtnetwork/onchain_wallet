import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/transaction/operations/transfer.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

import 'cash_token.dart';
import 'select_utxos.dart';

class BitcoinTransactionTransferTokenWidget extends StatelessWidget {
  final BitcoinTransactionTransferOperation form;
  const BitcoinTransactionTransferTokenWidget({required this.form, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      LiveFormWidget(
        field: form.totalUtxos,
        builder: (context, field, value) {
          return ContainerWithBorder(
            onRemove: () {
              context.openDialogPage(
                  child: (context) => BitcoinTransactionSelectUtxos(form), "");
            },
            onRemoveIcon: AddOrEditIconWidget(form.hasUtxos),
            validate: form.hasUtxos,
            child: ConditionalWidget(
              onDeactive: (context) => Text("tap_to_choose_utxos".tr),
              enable: form.hasUtxos,
              onActive: (context) =>
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CoinAndMarketPriceView(
                    balance: form.totalUtxos.value,
                    symbolColor: context.onPrimaryContainer,
                    showTokenImage: true,
                    style: context.onPrimaryTextTheme.titleMedium)
              ]),
            ),
          );
        },
      ),
      WidgetConstant.height20,
      LiveFormWidgetList(
        field: form.recipients,
        onCreate: (context, field) =>
            LiveWidgetAddNewTransferDetails<BitcoinNetworkAddress>(
                onUpdateAddresses: form.onUpdateRecipients,
                account: form.account,
                isReady: field.hasValue,
                onFilterAccount: form.filterAccount,
                multipleSelect: true),
        builder: (context, field, value) => APPStreamBuilder(
          value: value.notifier,
          builder: (context, _) {
            return CustomizedContainer(
              onStackIcon: Icons.remove_circle,
              onTapStackIcon: () => form.onRemoveRecipients(value),
              validate: value.isReady,
              enableTap: false,
              validateText: value.status.error,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ContainerWithBorder(
                      backgroundColor: context.onPrimaryContainer,
                      child: ReceiptAddressDetailsView(
                          address: value.recipient, color: context.primaryContainer)),
                  ContainerWithBorder(
                      onRemove: () {
                        final max = form.getMaxInput(value);
                        final min = form.getMinInput();
                        context
                            .setupAmount(token: value.amount.token, max: max, min: min)
                            .then((amount) {
                          if (amount == null) return;
                          form.onUpdateRecipientAmount(value, amount, amount == max);
                        });
                      },
                      validate: value.hasAmount,
                      onRemoveIcon: Icon(Icons.edit, color: context.primaryContainer),
                      backgroundColor: context.onPrimaryContainer,
                      child: CoinAndMarketPriceView(
                          balance: value.amount,
                          showTokenImage: true,
                          style: context.primaryTextTheme.titleMedium,
                          symbolColor: context.primaryContainer)),
                  APPAnimated(
                    isActive: value.hasToken,
                    onActive: (context) => CustomizedContainer(
                      enableTap: false,
                      backgroundColor: context.colors.onPrimaryContainer,
                      reverseColor: context.colors.primaryContainer,
                      validate: value.token!.isReady,
                      // enableTap: false,
                      onTapStackIcon: value.hasToken
                          ? () {
                              form.onRemoveTransferToken(value, value.token!);
                            }
                          : null,
                      onStackIcon: Icons.remove_circle,
                      child: APPExpansionListTile(
                        title: CashTokenDetailsView(value.token!.cashToken,
                            balance: value.token!.viewAmount),
                        color: context.colors.onPrimaryContainer,
                        reverse: context.colors.primaryContainer,
                        children: [
                          if (value.token != null)
                            Container(
                              padding: WidgetConstant.padding10,
                              decoration: BoxDecoration(
                                  color: context.colors.primaryContainer,
                                  borderRadius: WidgetConstant.border8),
                              child: _CashTokenTransferForm(
                                  transfer: value, controller: form),
                            )
                        ],
                      ),
                    ),
                    onDeactive: (context) => APPStreamBuilder(
                      value: form.remainingCashTokenAmount.live,
                      builder: (context, cashToken) {
                        return ConditionalWidget(
                            enable: cashToken.tokenRemains.isNotEmpty,
                            onActive: (cotext) => ContainerWithBorder(
                                  backgroundColor: context.onPrimaryContainer,
                                  onRemoveIcon: Icon(Icons.add_box,
                                      color: context.primaryContainer),
                                  child: Text("select_token_for_transfer".tr,
                                      style: context.primaryTextTheme.bodyMedium),
                                  onRemove: () {
                                    context
                                        .openSliverDialog<BCHCashToken>(
                                            sliver: (context) =>
                                                _SelectCashTokensView(cashToken),
                                            label: 'choose_token'.tr)
                                        .then(
                                            (v) => form.onUpdateTransferToken(value, v));
                                  },
                                ));
                      },
                    ),
                  ),
                  AlertTextContainer(message: value.status.warning, enableTap: false)
                ],
              ),
            );
          },
        ),
      ),
      ConditionalWidget(
        enable: form.supportCashToken,
        onActive: (context) => Column(children: [
          WidgetConstant.height20,
          LiveFormWidgeCashTokenRemain(form),
        ]),
      ),
      WidgetConstant.height20,
      LiveFormWidget(
        field: form.remainingAmount,
        builder: (context, field, value) {
          return ContainerWithBorder(
            iconAlginment: CrossAxisAlignment.start,
            enableTap: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ContainerWithBorder(
                    onRemove: () {
                      context
                          .selectOrSwitchAccount<IBitcoinAddress>(
                              account: form.account, showMultiSig: true)
                          .then((v) {
                        if (v == null) return;
                        form.onUpdateRemainingAccount(v);
                      });
                    },
                    onRemoveIcon: Icon(Icons.edit, color: context.primaryContainer),
                    backgroundColor: context.onPrimaryContainer,
                    child: ReceiptAddressDetailsView(
                        address: value.recipient, color: context.primaryContainer)),
                ContainerWithBorder(
                    validate: !value.amount.isNegative,
                    onRemoveIcon: Icon(Icons.edit, color: context.primaryContainer),
                    backgroundColor: context.onPrimaryContainer,
                    child: CoinAndMarketPriceView(
                        balance: value.amount,
                        showTokenImage: true,
                        style: context.primaryTextTheme.titleMedium,
                        symbolColor: context.primaryContainer)),
              ],
            ),
          );
        },
      ),
      ConditionalWidget(
          enable: form.supportRbf,
          onActive: (context) => Column(
                children: [
                  WidgetConstant.height20,
                  LiveFormWidget(
                    field: form.rbf,
                    builder: (context, field, value) {
                      return ContainerWithBorder(
                          child: Switch(value: value, onChanged: form.onUpdateRBF));
                    },
                  ),
                ],
              )),
      WidgetConstant.height20,
      LiveFormWidgetList(
          field: form.memos,
          builder: (context, field, value) => ContainerWithBorder(
              onRemove: () {
                form.onRemoveMemo(value);
              },
              onRemoveIcon: Icon(Icons.remove_circle, color: context.onPrimaryContainer),
              child: Text(value.memo, style: context.onPrimaryTextTheme.bodyMedium)),
          onCreate: (context, field) {
            if (form.canAddNewMemo) {
              return ContainerWithBorder(
                  onRemoveIcon: Icon(Icons.add_box, color: context.onPrimaryContainer),
                  onRemove: () {
                    context
                        .openSliverBottomSheet<String>("transaction_memo".tr,
                            child: StringWriterView(
                                title: PageTitleSubtitle(
                                    title: "setup_memo".tr,
                                    body: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("memo_desc1".tr),
                                      ],
                                    )),
                                buttonText: "setup_memo".tr,
                                label: "memo".tr,
                                customForm: form.onValidateMemo))
                        .then(form.onUpdateMemo);
                  },
                  child: Text("tap_to_add_memo".tr,
                      style: context.onPrimaryTextTheme.bodyMedium));
            }
            return null;
          }),
      WidgetConstant.height20,
      LiveFormWidget(
        field: form.ordering,
        builder: (context, field, value) {
          return ContainerWithBorder(
            child: AppDropDownBottom(
              isExpanded: true,
              onChanged: form.onUpdateOrdering,
              value: value,
              isDense: false,
              items: {
                for (final i in TransactionOrdering.values)
                  i: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(i.name.tr, style: context.textTheme.labelLarge),
                    Text(i.desc.tr, style: context.textTheme.bodySmall),
                  ])
              },
            ),
          );
        },
      ),
      WidgetConstant.height20,
      TransactionFeeView(controller: form, onRetryFeeEstimate: form.estimateFee),
      TransactionStateSendTransaction(controller: form),
    ]);
  }
}

class _SelectCashTokensView extends StatelessWidget {
  final BitcoinRemainCashTokenTransferDetails cashtokens;
  const _SelectCashTokensView(this.cashtokens);

  @override
  Widget build(BuildContext context) {
    return SliverConstraintsBoxView(
      padding: WidgetConstant.padding20,
      sliver: MultiSliver(
        children: [
          AlertTextContainer(
              message: "assets_balance_not_supported_desc".tr, enableTap: false),
          SliverList.builder(
              itemBuilder: (context, index) {
                final token = cashtokens.tokenRemains[index];
                return ContainerWithBorder(
                    onRemove: () {
                      context.pop(token.token);
                    },
                    onRemoveWidget: WidgetConstant.sizedBox,
                    child: AccountTokenDetailsWidget(
                      token: token.token.token,
                      radius: APPConst.circleRadius25,
                      balance: token.tokenAmount,
                    ));
              },
              itemCount: cashtokens.tokenRemains.length),
        ],
      ),
    );
  }
}

class _CashTokenTransferForm extends StatelessWidget {
  final BitcoinTransactionTransferOperation controller;
  final BitcoinTransferDetails transfer;
  BitcoinCashCashTokenTransfer get token => transfer.token!;
  const _CashTokenTransferForm({required this.controller, required this.transfer});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ConditionalWidget(
          enable: token.cashToken.hasAmount,
          onActive: (context) => ConditionalWidget(
              enable: token.cashToken.isImmutable,
              onActive: (context) => ContainerWithBorder(
                    backgroundColor: context.colors.onPrimaryContainer,
                    child: CoinAndMarketPriceView(
                      balance: token.cashToken.balance,
                      style: context.primaryTextTheme.titleMedium,
                      symbolColor: context.primaryContainer,
                    ),
                  ),
              onDeactive: (context) => LiveFormWidgetAmount(
                  color: context.colors.onPrimaryContainer,
                  reverse: context.colors.primaryContainer,
                  onUpdateAmount: token.isImmutable
                      ? null
                      : (amount, max) =>
                          controller.onUpdateTrasferTokenAmount(transfer, amount),
                  onUpdateAmountMax: () => controller.remainingCashTokenAmount.value
                      .getTokenRemainAmount(token),
                  field: token.tokenAmount))),
      ConditionalWidget(
          enable: token.isNFT,
          onActive: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WidgetConstant.height20,
                  LiveFormWidget(
                      color: context.colors.onPrimaryContainer,
                      builder: (context, field, value) {
                        return ContainerWithBorder(
                          onRemoveIcon:
                              Icon(Icons.edit, color: context.colors.onSecondary),
                          onRemove: token.isImmutable
                              ? null
                              : () {
                                  context
                                      .openSliverBottomSheet<String>(
                                        "update_commitment".tr,
                                        child: StringWriterView(
                                          defaultValue: value,
                                          maxLength: RippleConst.maxDomainLength,
                                          customForm: token.onValidateCommitment,
                                          title: PageTitleSubtitle(
                                              title: "commitment".tr,
                                              body: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text("commitment_desc".tr),
                                                  WidgetConstant.height8,
                                                  Text("empty_desc".tr)
                                                ],
                                              )),
                                          buttonText: "setup_input".tr,
                                          label: "commitment".tr,
                                        ),
                                      )
                                      .then(token.onUpdateCommitment);
                                },
                          backgroundColor: context.colors.onPrimaryContainer,
                          child: ConditionalWidget(
                            enable: token.isMutable,
                            onDeactive: (context) => Text(
                              value ?? "without_commitment".tr,
                              style: context.primaryTextTheme.bodyMedium,
                            ),
                            onActive: (context) => Text(
                              value ?? "tap_to_add_commitment".tr,
                              style: context.primaryTextTheme.bodyMedium,
                            ),
                          ),
                        );
                      },
                      field: token.commitment),
                ],
              )),
      ConditionalWidget(
          enable: token.isNFT,
          onActive: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WidgetConstant.height20,
                  LiveFormWidget(
                      builder: (context, field, value) {
                        return ContainerWithBorder(
                          backgroundColor: context.colors.onPrimaryContainer,
                          child: ConditionalWidget(
                            enable: !token.isImmutable,
                            onDeactive: (context) => Text(value?.name ?? "",
                                style: context.primaryTextTheme.bodyMedium),
                            onActive: (context) => AppDropDownBottom(items: {
                              for (final i in CashTokenCapability.values)
                                i: Text(i.name.tr)
                            }, value: value, onChanged: token.onUpdateCapability),
                          ),
                        );
                      },
                      field: token.capability),
                ],
              )),
    ]);
  }
}
