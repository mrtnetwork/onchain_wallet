import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/account/pages/account_controller.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/network/sui/transaction/controller/controller/controller.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/wallet/network/forms/forms.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

class SuiTransactionFieldsView extends StatelessWidget {
  const SuiTransactionFieldsView({super.key, this.field});
  final LiveTransactionForm<SuiTransactionForm>? field;
  @override
  Widget build(BuildContext context) {
    final LiveTransactionForm<SuiTransactionForm> validator =
        field ?? context.getArgruments();
    return NetworkAccountControllerView<SuiClient, ISuiAddress, SuiChain>(
        addressRequired: true,
        clientRequired: true,
        childBulder: (wallet, account, client, address, onAccountChanged) {
          return StateBuilder<SuiTransactionStateController>(
            repositoryId: StateConst.solana,
            controller: () => SuiTransactionStateController(
                walletProvider: wallet,
                account: account,
                validator: validator,
                apiProvider: client),
            builder: (controller) {
              return PageProgress(
                initialStatus: StreamWidgetStatus.progress,
                initialWidget: ProgressWithTextView(
                    text: "retrieving_network_condition".tr),
                backToIdle: APPConst.oneSecoundDuration,
                key: controller.progressKey,
                child: (c) {
                  return CustomScrollView(
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
                                      color: context.onPrimaryContainer),
                                  onRemove: controller.form.enableSwitchAccount
                                      ? () {
                                          context
                                              .selectOrSwitchAccount<
                                                      ISuiAddress>(
                                                  account: controller.account,
                                                  showMultiSig: true)
                                              .then(onAccountChanged);
                                        }
                                      : null,
                                  child: AddressDetailsView(
                                      color: context.onPrimaryContainer,
                                      address: controller.address,
                                      key: ValueKey<ISuiAddress?>(
                                          controller.address)),
                                ),
                                WidgetConstant.height20,
                                _SolanaTransactionFileds(
                                    validator: controller.validator,
                                    controller: controller),
                                AnimatedSize(
                                  duration: APPConst.animationDuraion,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      WidgetConstant.height20,
                                      Text("transaction_fee".tr,
                                          style: context.textTheme.titleMedium),
                                      WidgetConstant.height8,
                                      ContainerWithBorder(
                                          validateText: controller.feeError?.tr,
                                          validate: controller.fee.isSimulate &&
                                              controller.feeError == null,
                                          onRemove: () {},
                                          onTapError: () {
                                            controller.calculateFees();
                                          },
                                          enableTap: false,
                                          onRemoveIcon: ButtonProgress(
                                            key: controller.feeProgressKey,
                                            initialStatus:
                                                StreamWidgetStatus.idle,
                                            child: (context) => Icon(
                                                Icons.circle,
                                                color:
                                                    context.colors.transparent),
                                          ),
                                          child: CoinAndMarketPriceView(
                                            balance: controller.fee.totalFee,
                                            style: context
                                                .onPrimaryTextTheme.titleMedium,
                                            symbolColor:
                                                context.onPrimaryContainer,
                                          )),
                                    ],
                                  ),
                                ),
                                WidgetConstant.height20,
                                InsufficientBalanceErrorView(
                                    verticalMargin:
                                        WidgetConstant.paddingVertical10,
                                    balance: controller.remindAmount),
                                ErrorTextContainer(error: controller.error),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FixedElevatedButton(
                                      activePress:
                                          controller.transactionIsReady,
                                      padding: WidgetConstant.paddingVertical40,
                                      onPressed: () {
                                        controller.sendTransaction(
                                          () {
                                            return context
                                                .openSliverDialog<bool>(
                                                    (context) {
                                              return DialogTextView(
                                                  text: controller
                                                              .feeError !=
                                                          null
                                                      ? "transaction_simulate_failed_desc"
                                                          .tr
                                                      : "transaction_simulate_not_ready_desc"
                                                          .tr,
                                                  buttonWidget:
                                                      DialogDoubleButtonView());
                                            }, "send_transaction".tr);
                                          },
                                        );
                                      },
                                      child: Text("send_transaction".tr),
                                    ),
                                  ],
                                ),
                              ],
                            )),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
        title: validator.validator.name.tr);
  }
}

class _SolanaTransactionFileds extends StatelessWidget {
  const _SolanaTransactionFileds(
      {required this.validator, required this.controller});
  final LiveTransactionForm<SuiTransactionForm> validator;
  final SuiTransactionStateController controller;
  @override
  Widget build(BuildContext context) {
    final field = validator.value as SuiTransferForm;
    return _AptosTransferFields(field: field, controller: controller);
  }
}

class _AptosTransferFields extends StatelessWidget {
  const _AptosTransferFields({required this.field, required this.controller});
  final SuiTransferForm field;
  final SuiTransactionStateController controller;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (field.transactionType.isTokenTransfer)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("token_transfer".tr, style: context.textTheme.titleMedium),
              WidgetConstant.height8,
              TokenDetailsView(
                token: field.token!,
                onSelectWidget: WidgetConstant.sizedBox,
                radius: APPConst.circleRadius25,
                error: field.token!.isFreeze
                    ? "token_balance_frozen_desc".tr
                    : null,
              ),
              WidgetConstant.height20
            ],
          ),
        Text("list_of_recipients".tr, style: context.textTheme.titleMedium),
        Text("amount_for_each_output".tr),
        WidgetConstant.height8,
        Column(
          children: List.generate(field.destination.length, (index) {
            final destination = field.destination.value[index];
            return ContainerWithBorder(
              iconAlginment: CrossAxisAlignment.start,
              onRemoveWidget: IconButton(
                  onPressed: () {
                    field.removeReceiver(destination);
                  },
                  icon: Icon(Icons.remove_circle,
                      color: context.colors.onPrimaryContainer)),
              validate: destination.isReady,
              validateText: destination.hasAmount ? "invalid_address".tr : null,
              enableTap: false,
              onRemove: () {},
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ContainerWithBorder(
                      backgroundColor: context.onPrimaryContainer,
                      child: ReceiptAddressDetailsView(
                          address: destination.address,
                          color: context.primaryContainer)),
                  ContainerWithBorder(
                    onRemove: () {
                      final max =
                          field.max(destination, controller.fee.requiredFee);
                      context
                          .setupAmount(token: field.transferToken, max: max)
                          .then((amount) {
                        field.setupAccountAmount(destination, amount);
                      });
                    },
                    validate: destination.hasAmount,
                    onRemoveIcon:
                        Icon(Icons.edit, color: context.primaryContainer),
                    backgroundColor: context.onPrimaryContainer,
                    child: CoinAndMarketPriceView(
                      balance: destination.balance,
                      style: context.primaryTextTheme.titleMedium,
                      symbolColor: context.primaryContainer,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        ContainerWithBorder(
            validate: field.destination.isNotEmpty,
            onRemove: () {
              context
                  .selectAccount<SuiAddress>(
                      account: controller.account,
                      onFilterAccount: field.filterAccount,
                      multipleSelect: true)
                  .then(
                (value) {
                  field.onAddRecever(value, (s) => context.showAlert(s));
                },
              );
            },
            onRemoveIcon: const Icon(Icons.add_box),
            child: Text("tap_to_add_new_receipment".tr))
      ],
    );
  }
}

// class _TransferSelectReceiver extends StatelessWidget {
//   const _TransferSelectReceiver(
//       {required this.field, required this.controller});
//   final SuiTransferForm field;
//   final SuiTransactionStateController controller;

//   @override
//   Widget build(BuildContext context) {
//     return APPAnimatedSize(
//         isActive: field.canAddReceiver,
//         onActive: (context) => ,
//         onDeactive: (context) => WidgetConstant.sizedBox);
//   }
// }
