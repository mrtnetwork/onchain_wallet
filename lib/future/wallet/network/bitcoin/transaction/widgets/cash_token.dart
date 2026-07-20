import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/transaction/operations/transfer.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';

class LiveFormWidgeCashTokenRemain<T extends Object> extends StatelessWidget {
  final BitcoinTransactionTransferOperation controller;
  const LiveFormWidgeCashTokenRemain(this.controller, {super.key});
  LiveFormField get field => controller.remainingCashTokenAmount;
  @override
  Widget build(BuildContext context) {
    final subtitle = field.subtitle;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      APPStreamBuilder(
        value: controller.remainingCashTokenAmount.value.notifier,
        builder: (context, _) {
          final value = controller.remainingCashTokenAmount.value;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // WidgetConstant.height20,
            APPAnimated(
                isActive: value.tokenRemains.isNotEmpty,
                onActive: (context) =>
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      WidgetConstant.height20,
                      Text(field.title, style: context.textTheme.titleMedium),
                      if (subtitle != null) Text(subtitle),
                      WidgetConstant.height8,
                      ContainerWithBorder(
                        iconAlginment: CrossAxisAlignment.start,
                        enableTap: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ContainerWithBorder(
                                onRemove: () {
                                  context
                                      .selectOrSwitchAccount<IBitcoinAddress>(
                                          account: controller.account, showMultiSig: true)
                                      .then((v) {
                                    if (v == null) return;
                                    controller.onUpdateRemainingTokenAccount(v);
                                  });
                                },
                                onRemoveIcon:
                                    Icon(Icons.edit, color: context.primaryContainer),
                                backgroundColor: context.onPrimaryContainer,
                                child: ReceiptAddressDetailsView(
                                    address: value.recipient,
                                    color: context.primaryContainer)),
                            ListView.builder(
                              physics: WidgetConstant.noScrollPhysics,
                              itemBuilder: (context, index) {
                                final token = value.tokenRemains[index];
                                return ContainerWithBorder(
                                  backgroundColor: context.colors.onPrimaryContainer,
                                  child: APPExpansionListTile(
                                    color: context.colors.onPrimaryContainer,
                                    reverse: context.colors.primaryContainer,
                                    title: CashTokenDetailsView(
                                      token.token,
                                      balance: token.tokenAmount,
                                    ),
                                    children: [
                                      Container(
                                          padding: WidgetConstant.padding10,
                                          decoration: BoxDecoration(
                                              color: context.colors.primaryContainer,
                                              borderRadius: WidgetConstant.border8),
                                          child: _RemainCashTokenView(
                                              token: token,
                                              controller: controller,
                                              transfer: value))
                                    ],
                                  ),
                                );
                              },
                              itemCount: value.tokenRemains.length,
                              shrinkWrap: true,
                            )
                          ],
                        ),
                      ),
                    ])),
            APPAnimated(
                isActive: value.burns.isNotEmpty,
                onActive: (context) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WidgetConstant.height20,
                      Text("burn".tr, style: context.textTheme.titleMedium),
                      Text("tokens_burn_in_transaction_desc".tr),
                      WidgetConstant.height8,
                      ListView.builder(
                        physics: WidgetConstant.noScrollPhysics,
                        itemBuilder: (context, index) {
                          final token = value.burns[index];
                          return ContainerWithBorder(
                            enableTap: false,
                            onRemove: () {
                              controller.onRemoveBurn(token);
                            },
                            onRemoveIcon: Icon(Icons.remove_circle,
                                color: context.colors.onPrimaryContainer),
                            backgroundColor: context.colors.primaryContainer,
                            child: ConditionalWidget(
                                enable: !token.isImmutable && token.cashToken.hasAmount,
                                onDeactive: (context) => CashTokenDetailsView(
                                      token.cashToken,
                                      balance: token.viewAmount,
                                      color: context.colors.onPrimaryContainer,
                                    ),
                                onActive: (context) => APPExpansionListTile(
                                      color: context.colors.onPrimaryContainer,
                                      reverse: context.colors.primaryContainer,
                                      title: CashTokenDetailsView(
                                        token.cashToken,
                                        balance: token.burn,
                                      ),
                                      children: [
                                        Container(
                                            padding: WidgetConstant.padding10,
                                            decoration: BoxDecoration(
                                                color: context.colors.primaryContainer,
                                                borderRadius: WidgetConstant.border8),
                                            child: _BurnCashTokenView(
                                                token: token,
                                                controller: controller,
                                                transfer: value))
                                      ],
                                    )),
                          );
                        },
                        itemCount: value.burns.length,
                        shrinkWrap: true,
                      )
                    ],
                  );
                })
          ]);
        },
      )
    ]);
  }
}

class _RemainCashTokenView extends StatelessWidget {
  final BitcoinCashCashTokenRemainTransfer token;
  final BitcoinRemainCashTokenTransferDetails transfer;
  final BitcoinTransactionTransferOperation controller;
  const _RemainCashTokenView(
      {required this.token, required this.controller, required this.transfer});

  @override
  Widget build(BuildContext context) {
    return APPStreamBuilder(
      value: token.notifier,
      builder: (context, value) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("amount".tr, style: context.onPrimaryTextTheme.titleMedium),
          WidgetConstant.height8,
          ContainerWithBorder(
            backgroundColor: context.colors.onPrimaryContainer,
            onRemove: () {
              final max = controller.getMaxInput();
              final min = controller.getMinInput();
              context
                  .setupAmount(token: token.amount.token, max: max, min: min)
                  .then((amount) {
                if (amount == null) return;
                controller.onUpdateRemindTokenAmount(token, amount);
              });
            },
            validate: token.hasNativeAmount,
            onRemoveIcon: Icon(Icons.edit, color: context.primaryContainer),
            child: CoinAndMarketPriceView(
                balance: token.amount,
                style: context.primaryTextTheme.titleMedium,
                showTokenImage: true,
                symbolColor: context.primaryContainer),
          ),
          ConditionalWidget(
              enable: token.hasAmount,
              onActive: (context) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WidgetConstant.height20,
                      Text("token_amount".tr,
                          style: context.onPrimaryTextTheme.titleMedium),
                      WidgetConstant.height8,
                      ContainerWithBorder(
                        backgroundColor: context.colors.onPrimaryContainer,
                        child: CoinAndMarketPriceView(
                            balance: token.tokenAmount,
                            style: context.primaryTextTheme.titleMedium,
                            showTokenImage: true,
                            symbolColor: context.primaryContainer),
                      ),
                    ],
                  )),
          ConditionalWidget(
              enable: token.isNFT && token.hasCommint,
              onActive: (context) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WidgetConstant.height20,
                      Text("commitment".tr,
                          style: context.onPrimaryTextTheme.titleMedium),
                      WidgetConstant.height8,
                      ContainerWithBorder(
                        backgroundColor: context.colors.onPrimaryContainer,
                        onRemoveIcon:
                            Icon(Icons.edit, color: context.colors.primaryContainer),
                        child: Text(
                          token.token.commitment ?? "",
                          style: context.primaryTextTheme.bodyMedium,
                        ),
                      ),
                    ],
                  )),
          ConditionalWidget(
              enable: token.isNFT,
              onActive: (context) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WidgetConstant.height20,
                      Text("capability".tr,
                          style: context.onPrimaryTextTheme.titleMedium),
                      WidgetConstant.height8,
                      ContainerWithBorder(
                        backgroundColor: context.colors.onPrimaryContainer,
                        child: Text(token.token.capability?.name ?? '',
                            style: context.primaryTextTheme.bodyMedium),
                      ),
                    ],
                  )),
          WidgetConstant.height20,
          Text("operations".tr, style: context.onPrimaryTextTheme.titleMedium),
          WidgetConstant.height8,
          ContainerWithBorder(
            backgroundColor: context.colors.onPrimaryContainer,
            onRemove: () {
              if (token.isImmutable || !token.hasAmount) {
                controller.onUpdateBurnToken(token);
              } else {
                context
                    .setupAmount(
                        token: token.tokenAmount.token, max: token.tokenAmount.balance)
                    .then((amount) {
                  if (amount == null) return;
                  controller.onUpdateBurnToken(token, amount: amount);
                });
              }
            },
            onRemoveIcon: Icon(Icons.add_box, color: context.primaryContainer),
            child: Text("tap_to_create_burn_operation".tr,
                style: context.primaryTextTheme.bodyMedium),
          )
        ]);
      },
    );
  }
}

class _BurnCashTokenView extends StatelessWidget {
  final BitcoinCashCashTokenBurn token;
  final BitcoinRemainCashTokenTransferDetails transfer;
  final BitcoinTransactionTransferOperation controller;
  const _BurnCashTokenView(
      {required this.token, required this.controller, required this.transfer});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("amount".tr, style: context.onPrimaryTextTheme.titleMedium),
      WidgetConstant.height8,
      ContainerWithBorder(
        backgroundColor: context.colors.onPrimaryContainer,
        onRemoveIcon: Icon(Icons.remove, color: context.primaryContainer),
        child: CoinAndMarketPriceView(
            balance: token.burn!,
            style: context.primaryTextTheme.titleMedium,
            showTokenImage: true,
            symbolColor: context.primaryContainer),
      ),
    ]);
  }
}

class CashTokenDetailsView extends StatelessWidget {
  final BCHCashToken token;
  final IntegerBalance? balance;
  final Color? color;
  const CashTokenDetailsView(
    this.token, {
    // this.showBalance = true,
    required this.balance,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AccountTokenDetailsWidget(
        token: token.token,
        balance: token.hasAmount ? balance : null,
        // balance: showBalance && token.hasAmount ? token.balance : null,
        radius: APPConst.circleRadius25,
        color: color ?? context.primaryContainer);
  }
}
