import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/account/pages/account_controller.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/controller/controller.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:stellar_dart/stellar_dart.dart';
import 'widgets/fee.dart';
import 'widgets/create_memo.dart';
import 'widgets/memo_view.dart';
import 'operations/operations.dart';
import 'widgets/timebound.dart';

class StellarTransactionFieldsView extends StatelessWidget {
  const StellarTransactionFieldsView({super.key});
  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<StellarClient, IStellarAddress,
        StellarChain>(
      addressRequired: true,
      clientRequired: true,
      title: "send_transaction".tr,
      childBulder: (wallet, account, client, address, onAccountChanged) =>
          StateBuilder<StellarTransactionStateController>(
              repositoryId: StateConst.stellar,
              controller: () => StellarTransactionStateController(
                  walletProvider: wallet,
                  account: account,
                  apiProvider: client),
              builder: (controller) {
                return PageProgress(
                  key: controller.progressKey,
                  initialStatus: PageProgressStatus.progress,
                  initialWidget: ProgressWithTextView(
                      text: "retrieving_network_condition".tr),
                  backToIdle: APPConst.oneSecoundDuration,
                  child: (c) => CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: ConstraintsBoxView(
                          padding: WidgetConstant.padding20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("account".tr,
                                  style: context.textTheme.titleMedium),
                              WidgetConstant.height8,
                              ContainerWithBorder(
                                onRemoveIcon: Icon(Icons.edit,
                                    color: context.colors.onPrimaryContainer),
                                child: AddressDetailsView(
                                    address: controller.address,
                                    key: ValueKey<IStellarAddress?>(
                                        controller.address),
                                    color: context.onPrimaryContainer),
                                onRemove: () {
                                  context
                                      .selectOrSwitchAccount<IStellarAddress>(
                                          account: controller.account,
                                          showMultiSig: true)
                                      .then(onAccountChanged);
                                },
                              ),
                              WidgetConstant.height20,
                              Text("add_operation".tr,
                                  style: context.textTheme.titleMedium),
                              WidgetConstant.height8,
                              ListView.separated(
                                itemBuilder: (context, index) {
                                  final operation = controller.customOperations
                                      .elementAt(index);
                                  return Theme(
                                    data: context.theme.copyWith(
                                        dividerColor:
                                            context.colors.transparent,
                                        hoverColor: context.colors.transparent,
                                        splashColor:
                                            context.colors.transparent),
                                    child: ContainerWithBorder(
                                        enableTap: false,
                                        iconAlginment: CrossAxisAlignment.start,
                                        onRemoveIcon: Icon(Icons.edit,
                                            color: context.onPrimaryContainer),
                                        onRemove: () {
                                          controller.removeOperation(
                                            operation: operation,
                                            callback: (operation) {
                                              return context
                                                  .openMaxExtendSliverBottomSheet<
                                                          StellarTransactionOperation>(
                                                      child:
                                                          StellarCreateTransactionOperationsView(
                                                              controller:
                                                                  controller,
                                                              updateOperation:
                                                                  operation),
                                                      "update_operation".tr);
                                            },
                                          );
                                        },
                                        child: APPExpansionListTile(
                                          tilePadding: EdgeInsets.zero,
                                          title: Text(
                                              operation.type.translate.tr,
                                              style: context.onPrimaryTextTheme
                                                  .bodyMedium),
                                          children: [
                                            Container(
                                                padding:
                                                    WidgetConstant.padding10,
                                                decoration: BoxDecoration(
                                                    color:
                                                        context.colors.surface,
                                                    borderRadius:
                                                        WidgetConstant.border8),
                                                child:
                                                    StellarTransactionOperationView(
                                                        operation: operation))
                                          ],
                                        )),
                                  );
                                },
                                itemCount: controller.customOperations.length,
                                shrinkWrap: true,
                                physics: WidgetConstant.noScrollPhysics,
                                separatorBuilder: (context, index) =>
                                    WidgetConstant.divider,
                              ),
                              ContainerWithBorder(
                                validate:
                                    controller.customOperations.isNotEmpty,
                                onRemove: () {
                                  context
                                      .openMaxExtendSliverBottomSheet<
                                              StellarTransactionOperation>(
                                          child:
                                              StellarCreateTransactionOperationsView(
                                                  controller: controller),
                                          "setup_operation".tr)
                                      .then(controller.addOperation);
                                },
                                onRemoveIcon: Icon(
                                  Icons.add_box,
                                  color: context.onPrimaryContainer,
                                ),
                                child: Text("tap_to_add_new_operation".tr,
                                    style:
                                        context.onPrimaryTextTheme.bodyMedium),
                              ),
                              WidgetConstant.height20,
                              StellarMemosView(
                                memo: controller.memo,
                                onTapMemo: () {
                                  controller.onSetupMemo((p0) async => context
                                      .openSliverBottomSheet<StellarMemo>(
                                          "create_memo".tr,
                                          child:
                                              CreateStellarMemoView(memo: p0)));
                                },
                              ),
                              WidgetConstant.height20,
                              Text("time_bound".tr,
                                  style: context.textTheme.titleMedium),
                              Text("stellar_time_bound_desc".tr),
                              WidgetConstant.height8,
                              ContainerWithBorder(
                                  onRemove: () {
                                    context
                                        .openSliverBottomSheet<
                                                TransactionTimeBound>(
                                            "setup_time_bound".tr,
                                            child:
                                                StellarTransactionSetupTimeBoundView(
                                                    currentTimeBound:
                                                        controller.timebound))
                                        .then(controller.setTimeBound);
                                  },
                                  onRemoveIcon: Icon(Icons.edit,
                                      color: context.onPrimaryContainer),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(controller.timebound.type.name.tr,
                                          style: context
                                              .onPrimaryTextTheme.labelLarge),
                                      switch (controller.timebound.type) {
                                        TransactiomTimeBoundType.auto => Text(
                                            "stellar_time_bound_auto_desc".tr,
                                            style: context
                                                .onPrimaryTextTheme.bodyMedium,
                                          ),
                                        TransactiomTimeBoundType.none => Text(
                                            "stellar_time_bound_none_desc".tr,
                                            style: context
                                                .onPrimaryTextTheme.bodyMedium,
                                          ),
                                        _ => Text(
                                            controller.timebound.time!
                                                .toDateAndTimeWithSecound(),
                                            style: context
                                                .onPrimaryTextTheme.bodyMedium,
                                          )
                                      },
                                    ],
                                  )),
                              WidgetConstant.height20,
                              Text("transaction_fee".tr,
                                  style: context.textTheme.titleMedium),
                              WidgetConstant.height8,
                              StellarTransactionFeeView(controller),
                              ErrorTextContainer(
                                  error: controller.error?.tr,
                                  verticalMargin:
                                      WidgetConstant.paddingVertical10),
                              InsufficientBalanceErrorView(
                                  verticalMargin:
                                      WidgetConstant.paddingVertical10,
                                  balance: controller.remindAmount),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FixedElevatedButton(
                                      padding: WidgetConstant.paddingVertical40,
                                      onPressed: controller.isReady
                                          ? () {
                                              controller
                                                  .signAndSendTransaction();
                                            }
                                          : null,
                                      child: Text("send_transaction".tr)),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
    );
  }
}

class StellarTransactionOperationView extends StatelessWidget {
  final StellarTransactionOperation operation;
  const StellarTransactionOperationView({required this.operation, super.key});

  @override
  Widget build(BuildContext context) {
    return switch (operation.type) {
      OperationType.changeTrust =>
        _ChangeTrustOperationView(operation as StellarChangeTrustOperation),
      OperationType.payment =>
        _PaymentOperationView(operation: operation as StellarPaymentOperation),
      OperationType.pathPaymentStrictReceive =>
        _PathPaymentStrictReceiveOperationView(
            operation: operation as StellarPathPaymentStrictReceiveOperation),
      OperationType.pathPaymentStrictSend =>
        _PathPaymentStrictSendOperationView(
            operation: operation as StellarPathPaymentStrictSendOperation),
      OperationType.createAccount => _CreateAccountOperationView(
          operation: operation as StellarCreateAccountOperation),
      OperationType.manageSellOffer ||
      OperationType.manageBuyOffer =>
        _ManageSellOfferOperationView(
            operation: operation as StellarManageSellOfferOperation),
      _ => WidgetConstant.sizedBox
    };
  }
}

///_CreateAccountOperationView

class _ChangeTrustOperationView extends StatelessWidget {
  final StellarChangeTrustOperation operation;
  const _ChangeTrustOperationView(this.operation);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("asset".tr, style: context.textTheme.titleMedium),
        Text("modify_trust_line_desc".tr),
        WidgetConstant.height8,
        ContainerWithBorder(
            child: TokenDetailsWidget(
          token: operation.asset.token,
          radius: APPConst.circleRadius25,
          color: context.onPrimaryContainer,
        )),
        WidgetConstant.height20,
        Text("limit".tr, style: context.textTheme.titleMedium),
        Text("change_trust_limit".tr),
        Text("stellar_change_trust_limit_zero_desc".tr),
        WidgetConstant.height8,
        ContainerWithBorder(
            child: CoinAndMarketPriceView(
          balance: operation.limit,
          style: context.onPrimaryTextTheme.titleMedium,
          symbolColor: context.onPrimaryContainer,
        ))
      ],
    );
  }
}

class _PaymentOperationView extends StatelessWidget {
  final StellarPaymentOperation operation;
  const _PaymentOperationView({required this.operation});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("asset".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
            child: TokenDetailsWidget(
          token: operation.asset.token,
          balance: operation.asset.tokenBalance,
          color: context.onPrimaryContainer,
          radius: APPConst.circleRadius25,
        )),
        WidgetConstant.height20,
        ReceiptAddressView(address: operation.destination.address),
        WidgetConstant.height20,
        TransactionAmountView(
            amount: operation.amount, token: operation.asset.token),
      ],
    );
  }
}

class _PathPaymentStrictReceiveOperationView extends StatelessWidget {
  final StellarPathPaymentStrictReceiveOperation operation;
  const _PathPaymentStrictReceiveOperationView({required this.operation});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("send_asset".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
            child: TokenDetailsWidget(
          token: operation.asset.token,
          balance: operation.asset.tokenBalance,
          color: context.onPrimaryContainer,
          radius: APPConst.circleRadius25,
        )),
        WidgetConstant.height20,
        TransactionAmountView(
            amount: operation.sendAmount,
            token: operation.asset.token,
            title: "send_max".tr),
        WidgetConstant.height20,
        ReceiptAddressView(
            address: operation.destination.address, title: "destination".tr),
        WidgetConstant.height20,
        Text("destination_asset".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
          child: TokenDetailsWidget(
            token: operation.destAsset.token,
            radius: APPConst.circleRadius25,
            color: context.colors.onPrimaryContainer,
            tokenAddress: operation.destAsset.issuer,
          ),
        ),
        WidgetConstant.height20,
        TransactionAmountView(
          amount: operation.destAmount,
          token: operation.destAsset.token,
          title: "destination_amount".tr,
        ),
        if (operation.paths.isNotEmpty) ...[
          WidgetConstant.height20,
          Text("path".tr, style: context.textTheme.titleMedium),
          WidgetConstant.height8,
          ...List.generate(operation.paths.length, (index) {
            final asset = operation.paths.elementAt(index);
            return ContainerWithBorder(
              child: TokenDetailsWidget(
                token: asset.token,
                radius: APPConst.circleRadius25,
                color: context.colors.onPrimaryContainer,
                tokenAddress: asset.issuer,
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _PathPaymentStrictSendOperationView extends StatelessWidget {
  final StellarPathPaymentStrictSendOperation operation;
  const _PathPaymentStrictSendOperationView({required this.operation});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("send_asset".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
            child: TokenDetailsWidget(
          token: operation.asset.token,
          balance: operation.asset.tokenBalance,
          color: context.onPrimaryContainer,
          radius: APPConst.circleRadius25,
        )),
        WidgetConstant.height20,
        TransactionAmountView(
            amount: operation.sendAmount,
            token: operation.asset.token,
            title: "send_amount".tr),
        WidgetConstant.height20,
        ReceiptAddressView(
            address: operation.destination.address, title: "destination".tr),
        WidgetConstant.height20,
        Text("destination_asset".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
          enableTap: false,
          child: TokenDetailsWidget(
            token: operation.destAsset.token,
            radius: APPConst.circleRadius25,
            tokenAddress: operation.destAsset.issuer,
            color: context.colors.onPrimaryContainer,
          ),
        ),
        WidgetConstant.height20,
        TransactionAmountView(
          amount: operation.destMin,
          token: operation.destAsset.token,
          title: "minimum_destination_amount".tr,
        ),
        if (operation.paths.isNotEmpty) ...[
          WidgetConstant.height20,
          Text("path".tr, style: context.textTheme.titleMedium),
          WidgetConstant.height8,
          ...List.generate(operation.paths.length, (index) {
            final asset = operation.paths.elementAt(index);
            return ContainerWithBorder(
              child: TokenDetailsWidget(
                  token: asset.token,
                  radius: APPConst.circleRadius25,
                  color: context.colors.onPrimaryContainer,
                  tokenAddress: asset.issuer),
            );
          }),
        ],
      ],
    );
  }
}

class _CreateAccountOperationView extends StatelessWidget {
  final StellarCreateAccountOperation operation;
  const _CreateAccountOperationView({required this.operation});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("asset".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
            child: TokenDetailsWidget(
          token: operation.asset.token,
          balance: operation.asset.tokenBalance,
          color: context.colors.onPrimaryContainer,
          radius: APPConst.circleRadius25,
        )),
        WidgetConstant.height20,
        ReceiptAddressView(address: operation.destination.address),
        WidgetConstant.height20,
        TransactionAmountView(
            title: "starting_balance".tr,
            amount: operation.startingBalance,
            token: operation.asset.token),
      ],
    );
  }
}

class _ManageSellOfferOperationView extends StatelessWidget {
  final StellarManageSellOfferOperation operation;
  const _ManageSellOfferOperationView({required this.operation});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("selling".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
            child: TokenDetailsWidget(
          token: operation.asset.token,
          balance: operation.asset.tokenBalance,
          radius: APPConst.circleRadius25,
        )),
        WidgetConstant.height20,
        TransactionAmountView(
            amount: operation.amount,
            token: operation.asset.token,
            title: "amount".tr),
        WidgetConstant.height20,
        Text("buying".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
          child: TokenDetailsWidget(
            token: operation.buying.token,
            radius: APPConst.circleRadius25,
            color: context.onPrimaryContainer,
            tokenAddress: operation.buying.issuer,
          ),
        ),
        WidgetConstant.height20,
        Text("price".tr, style: context.textTheme.titleMedium),
        ContainerWithBorder(
          child: Row(
            children: [
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  CircleTokenImageView(
                    operation.asset.token,
                    radius: APPConst.circleRadius25,
                  ),
                  Container(
                    padding: const EdgeInsets.only(left: 20),
                    child: CircleTokenImageView(
                      operation.buying.token,
                      radius: APPConst.circleRadius25,
                    ),
                  ),
                ],
              ),
              WidgetConstant.width8,
              Expanded(
                  child: Text(operation.priceView,
                      style: context.onPrimaryTextTheme.bodyMedium)),
            ],
          ),
        ),
        WidgetConstant.height20,
        Text("offer_id".tr, style: context.textTheme.titleMedium),
        ContainerWithBorder(
          onRemoveIcon: Icon(Icons.edit, color: context.onPrimaryContainer),
          child: Text(operation.offerId.toString(),
              style: context.onPrimaryTextTheme.bodyMedium),
        ),
      ],
    );
  }
}
