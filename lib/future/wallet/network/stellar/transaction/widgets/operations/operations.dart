import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/types/operations.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/widgets/widgets/create_memo.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/widgets/widgets/extensions.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/widgets/widgets/timebound.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/constant/networks/stellar.dart';
import 'package:stellar_dart/stellar_dart.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/types/types.dart';

class StellarTransactionGlobalOperationWidget extends StatelessWidget {
  final StellarTransactionStateController form;
  const StellarTransactionGlobalOperationWidget({required this.form, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      APPStreamBuilder(
        value: form.pendingOperation.live,
        builder: (context, value) {
          return APPAnimated(
              isActive: value != null,
              onActive: (context) =>
                  _StellarTransactionOperationFormBuilder(form: value!, controller: form),
              onDeactive: (context) => _StellarTransactionFieldsView(form));
        },
      ),
    ]);
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
      OperationType.pathPaymentStrictReceive => _PathPaymentStrictReceiveOperationView(
          operation: operation as StellarPathPaymentStrictReceiveOperation),
      OperationType.pathPaymentStrictSend => _PathPaymentStrictSendOperationView(
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

class _StellarTransactionFieldsView extends StatelessWidget {
  final StellarTransactionStateController form;
  const _StellarTransactionFieldsView(this.form);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      LiveFormWidgetList(
        field: form.operations,
        onCreate: (context, field) {
          return ContainerWithBorder(
            validate: form.operations.hasValue,
            onRemove: () {
              context
                  .openDialogPage<OperationType>('',
                      child: (context) => _SelectStellarOperationView())
                  .then(form.onCreateNewOperation);
            },
            onRemoveIcon: Icon(Icons.add_box, color: context.onPrimaryContainer),
            child: Text("tap_to_add_new_operation".tr,
                style: context.onPrimaryTextTheme.bodyMedium),
          );
        },
        builder: (context, field, value) {
          return Theme(
            data: context.theme.copyWith(
                dividerColor: context.colors.transparent,
                hoverColor: context.colors.transparent,
                splashColor: context.colors.transparent),
            child: ContainerWithBorder(
                enableTap: false,
                iconAlginment: CrossAxisAlignment.start,
                onRemoveIcon: Icon(Icons.edit, color: context.onPrimaryContainer),
                onRemove: () {
                  form.onEditOperation(value);
                },
                child: APPExpansionListTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(value.operation.type.translate.tr,
                      style: context.onPrimaryTextTheme.bodyMedium),
                  children: [
                    Container(
                        padding: WidgetConstant.padding10,
                        decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: WidgetConstant.border8),
                        child:
                            StellarTransactionOperationView(operation: value.operation))
                  ],
                )),
          );
        },
      ),
      WidgetConstant.height20,
      LiveFormWidget(
        field: form.memo,
        builder: (context, field, value) {
          return APPAnimated(
            isActive: true,
            onActive: (context) => ContainerWithBorder(
                key: ValueKey(value),
                onRemove: () {
                  if (value != null) {
                    form.onRemoveMemo();
                    return;
                  }
                  context
                      .openSliverBottomSheet<StellarMemo>("create_memo".tr,
                          child: CreateStellarMemoView(memo: value))
                      .then(form.onUpdateMemo);
                },
                onRemoveIcon: ConditionalWidget(
                  onActive: (context) =>
                      Icon(Icons.remove_circle, color: context.onPrimaryContainer),
                  onDeactive: (context) =>
                      Icon(Icons.add_box, color: context.onPrimaryContainer),
                  enable: field.hasValue,
                ),
                child: APPAnimated(
                    isActive: true,
                    onActive: (context) => FullWidthWrapper(
                        child: _StellarMemoView(value, key: ValueKey(value))))),
          );
        },
      ),
      WidgetConstant.height20,
      LiveFormWidget(
        field: form.timebound,
        builder: (context, field, value) {
          return ContainerWithBorder(
              onRemove: () {
                context
                    .openSliverBottomSheet<TransactionTimeBound>("setup_time_bound".tr,
                        child:
                            StellarTransactionSetupTimeBoundView(currentTimeBound: value))
                    .then(form.onUpdateTimeBound);
              },
              onRemoveIcon: Icon(Icons.edit, color: context.onPrimaryContainer),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value.type.name.tr, style: context.onPrimaryTextTheme.labelLarge),
                  switch (value.type) {
                    TransactiomTimeBoundType.auto => Text(
                        "stellar_time_bound_auto_desc".tr,
                        style: context.onPrimaryTextTheme.bodyMedium,
                      ),
                    TransactiomTimeBoundType.none => Text(
                        "stellar_time_bound_none_desc".tr,
                        style: context.onPrimaryTextTheme.bodyMedium,
                      ),
                    _ => Text(value.time!.toDateAndTimeWithSecound(),
                        style: context.onPrimaryTextTheme.bodyMedium)
                  },
                ],
              ));
        },
      ),
      WidgetConstant.height20,
      TransactionFeeView(controller: form),
      TransactionStateSendTransaction(controller: form)
    ]);
  }
}

class _StellarTransactionOperationFormBuilder extends StatelessWidget {
  const _StellarTransactionOperationFormBuilder(
      {required this.form, required this.controller});
  final StellarTransactionOperationForm form;
  final StellarTransactionStateController controller;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        context
            .openSliverDialog(
                widget: (context) => DialogTextView(
                    text: "skip_operations_desc".tr,
                    buttonWidget: DialogDoubleButtonView()),
                label: 'skip_create_operations'.tr)
            .then((e) {
          if (e != true) return;
          controller.onSkipOperation();
        });
      },
      canPop: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("setup_operation".tr, style: context.textTheme.titleMedium),
              Text("add_stellar_new_operation_desc".tr),
            ],
          )),
          IconButton(
              onPressed: () {
                context
                    .openSliverDialog(
                        widget: (context) => DialogTextView(
                            text: "skip_operations_desc".tr,
                            buttonWidget: DialogDoubleButtonView()),
                        label: 'skip_create_operations'.tr)
                    .then((e) {
                  if (e != true) return;
                  controller.onSkipOperation();
                });
              },
              icon: Icon(Icons.cancel))
        ]),
        WidgetConstant.height20,
        Text("operation".tr, style: context.textTheme.titleMedium),
        ContainerWithBorder(
            child: Text(form.type.name, style: context.onPrimaryTextTheme.bodyMedium)),
        WidgetConstant.height20,
        form.builder(context),
        APPStreamBuilder(
            value: form.status,
            builder: (context, value) {
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ErrorTextContainer(error: value.error, enableTap: false),
                AlertTextContainer(message: value.warning, enableTap: false),
                Padding(
                  padding: WidgetConstant.paddingVertical40,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    FixedElevatedButton(
                        onPressed: controller.onUpdateOperations,
                        activePress: value.isReady,
                        child: Text("setup_operation".tr))
                  ]),
                )
              ]);
            })
      ]),
    );
  }
}

class _StellarMemoView extends StatelessWidget {
  const _StellarMemoView(this.memo, {super.key});
  final StellarMemoDetils? memo;
  @override
  Widget build(BuildContext context) {
    if (memo == null) {
      return Text("tap_to_create_memo".tr, style: context.onPrimaryTextTheme.bodyMedium);
    }
    return Text(memo?.val ?? '', style: context.onPrimaryTextTheme.bodyMedium);
  }
}

class _SelectStellarOperationView extends StatelessWidget {
  const _SelectStellarOperationView();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
            title: Text("transaction_operation".tr), pinned: true, centerTitle: false),
        SliverConstraintsBoxView(
          padding: WidgetConstant.paddingHorizontal20,
          sliver: SliverList.separated(
              itemBuilder: (context, index) {
                final element = StellarConst.supportedOperations.elementAt(index);
                return AppListTile(
                  title: Text(element.translate.tr),
                  onTap: () => context.pop(element),
                  subtitle: Text(element.description),
                  maxLine: 3,
                  trailing: const Icon(Icons.arrow_forward),
                );
              },
              separatorBuilder: (context, index) => WidgetConstant.divider,
              itemCount: StellarConst.supportedOperations.length),
        )
      ],
    );
  }
}

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
            child: AccountTokenDetailsWidget(
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
            child: AccountTokenDetailsWidget(
          token: operation.asset.token,
          balance: operation.asset.tokenBalance,
          color: context.onPrimaryContainer,
          radius: APPConst.circleRadius25,
        )),
        WidgetConstant.height20,
        ReceiptAddressView(address: operation.destination),
        WidgetConstant.height20,
        TransactionAmountView(amount: operation.amount, token: operation.asset.token),
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
            child: AccountTokenDetailsWidget(
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
        ReceiptAddressView(address: operation.destination, title: "destination".tr),
        WidgetConstant.height20,
        Text("destination_asset".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
          child: AccountTokenDetailsWidget(
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
              child: AccountTokenDetailsWidget(
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
            child: AccountTokenDetailsWidget(
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
        ReceiptAddressView(address: operation.destination, title: "destination".tr),
        WidgetConstant.height20,
        Text("destination_asset".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
          enableTap: false,
          child: AccountTokenDetailsWidget(
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
              child: AccountTokenDetailsWidget(
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
            child: AccountTokenDetailsWidget(
          token: operation.asset.token,
          balance: operation.asset.tokenBalance,
          color: context.colors.onPrimaryContainer,
          radius: APPConst.circleRadius25,
        )),
        WidgetConstant.height20,
        ReceiptAddressView(address: operation.destination),
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
            child: AccountTokenDetailsWidget(
          token: operation.asset.token,
          balance: operation.asset.tokenBalance,
          radius: APPConst.circleRadius25,
        )),
        WidgetConstant.height20,
        TransactionAmountView(
            amount: operation.amount, token: operation.asset.token, title: "amount".tr),
        WidgetConstant.height20,
        Text("buying".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
          child: AccountTokenDetailsWidget(
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
