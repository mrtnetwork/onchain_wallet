import 'package:flutter/material.dart';
import 'package:on_chain/ada/src/address/era/core/address.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/transaction/operations/transfer.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/transaction/widgets/memo_write_view.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/transaction/widgets/transaction_certificate_view.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';

import 'select_utxos.dart';

class ADATransactionTransferWidget extends StatelessWidget {
  final ADATransactionTransferOperation form;
  const ADATransactionTransferWidget({required this.form, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      LiveFormWidget(
        field: form.totalUtxos,
        builder: (context, field, value) {
          return ContainerWithBorder(
            onRemove: () {
              context.openDialogPage(
                  child: (context) => ADATransactionSelectUtxos(form), "");
            },
            onRemoveIcon: AddOrEditIconWidget(form.hasUtxos),
            validate: form.hasUtxos,
            child: ConditionalWidget(
              onDeactive: (context) => Text("tap_to_choose_utxos".tr,
                  style: context.onPrimaryTextTheme.bodyMedium),
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
        onCreate: (context, field) => LiveWidgetAddNewTransferDetails<ADAAddress>(
            onUpdateAddresses: form.onUpdateRecipients,
            account: form.account,
            isReady: field.hasValue,
            onFilterAccount: form.filterAccount,
            multipleSelect: true),
        builder: (context, field, value) {
          return APPStreamBuilder(
            value: value.notifier,
            builder: (context, _) {
              return CustomizedContainer(
                onTapStackIcon: () => form.onRemoveRecipients(value),
                validateText: value.status.error,
                validate: value.isReady,
                enableTap: false,
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
                          final min = value.getMinAmount();
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
                          style: context.primaryTextTheme.titleMedium,
                          symbolColor: context.primaryContainer,
                          showTokenImage: true,
                        )),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: WidgetConstant.noScrollPhysics,
                      itemCount: value.transfers.length,
                      itemBuilder: (context, index) {
                        final transfer = value.transfers[index];
                        return CustomizedContainer(
                          enableTap: false,
                          backgroundColor: context.colors.onPrimaryContainer,
                          reverseColor: context.colors.primaryContainer,
                          validate: transfer.hasAmount,
                          validateText: value.status.error,
                          iconAlginment: CrossAxisAlignment.start,
                          onTapStackIcon: () =>
                              form.onRemoveTransferAsset(value, transfer),
                          // onStackIcon: Icon(Icons.remove_circle,
                          //     color: context.colors.primaryContainer),
                          child: APPExpansionListTile(
                            title: ADATokenDetailsView(transfer.token,
                                balance: transfer.amount),
                            color: context.colors.onPrimaryContainer,
                            reverse: context.colors.primaryContainer,
                            children: [
                              Container(
                                padding: WidgetConstant.padding10,
                                decoration: BoxDecoration(
                                    color: context.colors.primaryContainer,
                                    borderRadius: WidgetConstant.border8),
                                child: _ADAAssetTransferForm(
                                  transfer: value,
                                  controller: form,
                                  token: transfer,
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                    APPStreamBuilder(
                      value: form.remainingAmount.live,
                      builder: (context, token) {
                        return ConditionalWidget(
                            enable: token.tokenRemains.isNotEmpty,
                            onActive: (cotext) => ContainerWithBorder(
                                  backgroundColor: context.onPrimaryContainer,
                                  onRemoveIcon: Icon(Icons.add_box,
                                      color: context.primaryContainer),
                                  child: Text("select_token_for_transfer".tr,
                                      style: context.primaryTextTheme.bodyMedium),
                                  onRemove: () {
                                    context
                                        .openSliverDialog<ADATransferAssetDetails>(
                                            sliver: (context) => _SelectADAAssetsView(
                                                token: token, transfer: value),
                                            label: 'choose_token'.tr)
                                        .then(
                                            (v) => form.onUpdateTransferAsset(value, v));
                                  },
                                ));
                      },
                    ),
                    AlertTextContainer(message: value.status.warning, enableTap: false)
                  ],
                ),
              );
            },
          );
        },
      ),
      WidgetConstant.height20,
      LiveFormWidgetList(
        field: form.certificates,
        onCreate: (context, field) {
          return ContainerWithBorder(
            onRemoveIcon: Icon(Icons.edit, color: context.onPrimaryContainer),
            child: Text("tap_to_add_certificate".tr,
                style: context.onPrimaryTextTheme.bodyMedium),
            onRemove: () {
              context
                  .openMaxExtendSliverBottomSheet<ADATransactionCertificate>(
                    "certificate".tr,
                    child: CardanoTransactionCertificateView(form.account),
                  )
                  .then(form.onUpdateCertificate);
            },
          );
        },
        builder: (context, field, value) {
          return ContainerWithBorder(
              iconAlginment: CrossAxisAlignment.start,
              onRemoveIcon: Icon(Icons.remove_circle, color: context.onPrimaryContainer),
              onRemove: () {
                form.onRemoveCertificate(value);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value.type.viewName.tr,
                      style: context.onPrimaryTextTheme.titleMedium),
                  WidgetConstant.height8,
                  ContainerWithBorder(
                    backgroundColor: context.onPrimaryContainer,
                    child: ReceiptAddressDetailsView(
                        address: value.rewardAccount, color: context.primaryContainer),
                  )
                ],
              ));
        },
      ),
      WidgetConstant.height20,
      LiveFormWidget(
        field: form.remainingAmount,
        builder: (context, field, value) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              APPStreamBuilder(
                value: value.notifier,
                builder: (context, _) {
                  return ContainerWithBorder(
                    iconAlginment: CrossAxisAlignment.start,
                    enableTap: false,
                    validate: value.isReady,
                    validateText: value.status.error,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ContainerWithBorder(
                            onRemove: () {
                              context
                                  .selectOrSwitchAccount<ICardanoAddress>(
                                      account: form.account,
                                      showMultiSig: true,
                                      filter: form.onRemainingAccountFilter)
                                  .then(form.onUpdateRemainingAccount);
                            },
                            onRemoveIcon:
                                Icon(Icons.edit, color: context.primaryContainer),
                            backgroundColor: context.onPrimaryContainer,
                            child: APPAnimated(
                                isActive: true,
                                onActive: (context) => ReceiptAddressDetailsView(
                                    key: ValueKey(value.recipient),
                                    address: value.recipient,
                                    color: context.primaryContainer))),
                        ContainerWithBorder(
                            validate: !value.amount.isNegative,
                            onRemoveIcon:
                                Icon(Icons.edit, color: context.primaryContainer),
                            backgroundColor: context.onPrimaryContainer,
                            child: CoinAndMarketPriceView(
                                balance: value.amount,
                                style: context.primaryTextTheme.titleMedium,
                                symbolColor: context.primaryContainer)),
                        ListView.builder(
                          itemCount: value.tokenRemains.length,
                          shrinkWrap: true,
                          physics: WidgetConstant.noScrollPhysics,
                          itemBuilder: (context, index) {
                            final token = value.tokenRemains[index];
                            if (!token.hasAmount) {
                              return WidgetConstant.sizedBox;
                            }
                            return ContainerWithBorder(
                              backgroundColor: context.colors.onPrimaryContainer,
                              child:
                                  ADATokenDetailsView(token.token, balance: token.amount),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              )
            ],
          );
        },
      ),
      WidgetConstant.height20,
      LiveFormWidgetList(
        field: form.memos,
        onCreate: (context, field) {
          return ContainerWithBorder(
              onRemoveIcon: Icon(Icons.add_box, color: context.onPrimaryContainer),
              onRemove: () {
                context
                    .openSliverBottomSheet<ADATransactionMemo>("transaction_memo".tr,
                        child: CardanoTransactionMemoWriteView(
                          labeles: field.value.map((e) => e.tag).toList(),
                          title: PageTitleSubtitle(
                              title: "setup_memo".tr,
                              body: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [Text("memo_desc1".tr)],
                              )),
                          buttonText: "setup_memo".tr,
                          label: "memo".tr,
                        ))
                    .then(form.onUpdateMemo);
              },
              child: Text("tap_to_add_memo".tr,
                  style: context.onPrimaryTextTheme.bodyMedium));
        },
        builder: (context, field, value) {
          return ContainerWithBorder(
              iconAlginment: CrossAxisAlignment.start,
              onRemove: () {
                form.onRemoveMemo(value);
              },
              onRemoveIcon: Icon(Icons.remove_circle, color: context.onPrimaryContainer),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ContainerWithBorder(
                      backgroundColor: context.onPrimaryContainer,
                      child: Text(value.tag.toString(),
                          style: context.primaryTextTheme.labelLarge)),
                  ContainerWithBorder(
                    backgroundColor: context.onPrimaryContainer,
                    child: Text(value.text, style: context.primaryTextTheme.bodyMedium),
                  )
                ],
              ));
        },
      ),
      WidgetConstant.height20,
      TransactionFeeView(controller: form, onRetryFeeEstimate: form.estimateFee),
      TransactionStateSendTransaction(controller: form)
    ]);
  }
}

class ADATokenDetailsView extends StatelessWidget {
  final ADAAssetToken token;
  final IntegerBalance? balance;
  final Color? color;
  const ADATokenDetailsView(this.token, {required this.balance, this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return AccountTokenDetailsWidget(
        token: token.token,
        balance: balance,
        radius: APPConst.circleRadius25,
        color: color ?? context.primaryContainer);
  }
}

class _SelectADAAssetsView extends StatefulWidget {
  final ADARemainTransferDetails token;
  final ADATransferDetails transfer;
  const _SelectADAAssetsView({required this.token, required this.transfer});

  @override
  State<_SelectADAAssetsView> createState() => _SelectADAAssetsViewState();
}

class _SelectADAAssetsViewState extends State<_SelectADAAssetsView>
    with SafeState<_SelectADAAssetsView> {
  List<ADATransferAssetDetails> tokens = [];

  @override
  void onInitOnce() {
    super.onInitOnce();
    tokens = widget.token.tokenRemains
        .where((e) => !widget.transfer.transfers.any((i) => i.token == e.token))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return SliverConstraintsBoxView(
      padding: WidgetConstant.padding20,
      sliver: MultiSliver(
        children: [
          AlertTextContainer(
              message: "assets_balance_not_supported_desc".tr, enableTap: false),
          EmptyItemSliverWidgetView(
            isEmpty: tokens.isEmpty,
            itemBuilder: (context) {
              return SliverList.builder(
                  itemBuilder: (context, index) {
                    final t = tokens[index];
                    return ContainerWithBorder(
                        onRemove: () {
                          context.pop(t);
                        },
                        onRemoveWidget: WidgetConstant.sizedBox,
                        child: AccountTokenDetailsWidget(
                            token: t.token.token,
                            radius: APPConst.circleRadius25,
                            balance: t.amount));
                  },
                  itemCount: tokens.length);
            },
          ),
        ],
      ),
    );
  }
}

class _ADAAssetTransferForm extends StatelessWidget {
  final ADATransactionTransferOperation controller;
  final ADATransferDetails transfer;
  final ADATransferAssetDetails token;

  const _ADAAssetTransferForm(
      {required this.controller, required this.transfer, required this.token});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ContainerWithBorder(
          validate: token.hasAmount,
          backgroundColor: context.onPrimaryContainer,
          onRemove: () {
            final max = controller.remainingAmount.value.getMaxInput(token);
            context.setupAmount(token: token.token.token, max: max).then((v) {
              if (v == null) return;
              controller.onUpdateTrasferAssetAmount(transfer, token, v);
            });
          },
          onRemoveIcon: AddOrEditIconWidget(
            token.hasAmount,
            color: context.primaryContainer,
          ),
          child: ConditionalWidget(
              enable: token.hasAmount,
              onActive: (context) => CoinAndMarketPriceView(
                  balance: token.amount,
                  style: context.primaryTextTheme.titleMedium,
                  showTokenImage: true,
                  symbolColor: context.primaryContainer),
              onDeactive: (context) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("tap_to_enter_amount".tr,
                          style: context.primaryTextTheme.bodyMedium)
                    ],
                  )))
    ]);
  }
}
