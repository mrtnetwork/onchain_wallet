import 'package:blockchain_utils/utils/binary/binary_operation.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/transaction/operations/transfer.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:zcash_dart/zcash.dart';
import 'select_utxos.dart';

class ZcashTransactionTransferTokenWidget extends StatelessWidget {
  final ZcashTransactionTransferOperation form;
  final BuildContext mainContext;
  const ZcashTransactionTransferTokenWidget(
      {required this.mainContext, required this.form, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      LiveFormWidget(
        field: form.totalUtxos,
        builder: (context, field, value) {
          return CustomizedContainer(
            onRemove: form.hasUtxos
                ? null
                : () {
                    context.openDialogPage(
                        child: (context) => ZcashTransactionSelectUtxos(form), "");
                  },
            onStackIcon: Icons.edit,
            onTapStackIcon: form.hasUtxos
                ? () {
                    context.openDialogPage(
                        child: (context) => ZcashTransactionSelectUtxos(form), "");
                  }
                : null,
            onRemoveIcon: AddOrEditIconWidget(form.hasUtxos),
            validate: form.hasUtxos,
            child: ConditionalWidget(
              onDeactive: (context) => Text("tap_to_choose_utxos".tr),
              enable: form.hasUtxos,
              onActive: (context) {
                return CoinAndMarketPriceView(
                    balance: form.totalUtxos.value,
                    symbolColor: context.onPrimaryContainer,
                    showTokenImage: true,
                    style: context.onPrimaryTextTheme.titleMedium);
              },
            ),
          );
        },
      ),
      WidgetConstant.height20,
      LiveFormWidgetList(
        field: form.recipients,
        onCreate: (context, field) => LiveWidgetAddNewTransferDetails<ZcashAddress>(
            onUpdateAddresses: (addresses) => form.onUpdateRecipients(
                  addresses,
                  (err) => context.showAlert(err),
                ),
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
                  AppDropDownBottomWithBorder(
                    backgroundColor: context.onPrimaryContainer,
                    reverseColor: context.primaryContainer,
                    isExpanded: true,
                    onChanged: (protocol) {
                      form.onUpdateRecipientProtocol(value, protocol);
                    },
                    value: value.addrProtocol,
                    label: "protocol".tr,
                    isDense: false,
                    selectedItemBuilder: {
                      for (final i in value.supportedProtocols) i: Text(i.name.tr)
                    },
                    items: {
                      for (final i in value.supportedProtocols)
                        i: Text(i.name.tr, style: context.primaryTextTheme.bodyMedium)
                    },
                  ),
                  ConditionalWidget(
                      enable: value.allowMemo,
                      onActive: (context) => ContainerWithBorder(
                          backgroundColor: context.onPrimaryContainer,
                          onRemoveWidget: AddOrRemoveIconWidget(
                            value.hasMemo,
                            color: context.primaryContainer,
                          ),
                          onRemove: () {
                            if (value.hasMemo) {
                              value.onRemoveMemo();
                              return;
                            }
                            context
                                .openSliverBottomSheet<String>("transaction_memo".tr,
                                    child: StringWriterView(
                                        title: PageTitleSubtitle(
                                            title: "setup_memo".tr,
                                            body: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text("memo_desc1".tr),
                                              ],
                                            )),
                                        buttonText: "setup_memo".tr,
                                        label: "memo".tr,
                                        customForm: value.onValidateMemo))
                                .then(value.onUpdateMemo);
                          },
                          child: APPAnimatedWithValue<String>(
                            value: value.memo?.content,
                            isExpanded: true,
                            onValue: (context, value) => OneLineTextWidget(value,
                                style: context.primaryTextTheme.bodyMedium),
                            onNull: (context) => Text("tap_to_add_memo".tr,
                                style: context.primaryTextTheme.bodyMedium),
                          ))),
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
                  AlertTextContainer(message: value.status.warning, enableTap: false)
                ],
              ),
            );
          },
        ),
      ),
      WidgetConstant.height20,
      LiveFormWidget(
        field: form.remainingAmount,
        builder: (context, field, value) {
          return APPStreamBuilder(
              value: value.notifier,
              builder: (context, _) {
                return DisabledWidget(
                    disabled: !value.hasAmount,
                    ignoring: true,
                    onActive: (context, _) => ContainerWithBorder(
                          iconAlginment: CrossAxisAlignment.start,
                          enableTap: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ContainerWithBorder(
                                  onRemove: () {
                                    context
                                        .selectOrSwitchAccount<IZcashAddress>(
                                            account: form.account, showMultiSig: true)
                                        .then((v) {
                                      if (v == null) return;
                                      form.onUpdateRemainingAccount(v);
                                    });
                                  },
                                  onRemoveIcon:
                                      Icon(Icons.edit, color: context.primaryContainer),
                                  backgroundColor: context.onPrimaryContainer,
                                  child: ReceiptAddressDetailsView(
                                      address: value.recipient,
                                      color: context.primaryContainer)),
                              AppDropDownBottomWithBorder(
                                backgroundColor: context.onPrimaryContainer,
                                reverseColor: context.primaryContainer,
                                isExpanded: true,
                                onChanged: (protocol) {
                                  form.onUpdateRemainingPorocol(protocol);
                                },
                                value: value.addrProtocol,
                                label: "protocol".tr,
                                isDense: false,
                                selectedItemBuilder: {
                                  for (final i in value.supportedProtocols)
                                    i: Text(i.name.tr)
                                },
                                items: {
                                  for (final i in value.supportedProtocols)
                                    i: Text(i.name.tr,
                                        style: context.primaryTextTheme.bodyMedium)
                                },
                              ),
                              // ConditionalWidget(
                              //     enable: value.addrProtocol.isTransparent,
                              //     onActive: (context) => ContainerWithBorder(
                              //           onRemoveWidget: AddOrRemoveIconWidget(
                              //             value.hasMemo,
                              //             color: context.primaryContainer,
                              //           ),
                              //           onRemove: () {
                              //             if (value.hasLocktime) {
                              //               value.onRemoveLocktime();
                              //               return;
                              //             }
                              // context
                              //     .openMaxExtendSliverBottomSheet<
                              //         Bip68Configuration>(
                              //       "",
                              //       bodyBuilder: (controller) =>
                              //           UtxoSetupBip68View(controller),
                              //     )
                              //     .then(value.onChangeLocktime);
                              //           },
                              //           child: APPAnimated(
                              //               onActive: (context) => Text(
                              //                     key: ValueKey(value.locktime),
                              //                     switch (value.locktime) {
                              //                       null => "tap_to_setup_timelock".tr,
                              //                       Bip68ConfigurationBlocks(
                              //                         :final blocks
                              //                       ) =>
                              //                         "n_blocks"
                              //                             .tr
                              //                             .replaceOne(blocks.toString()),
                              //                       Bip68ConfigurationTimelock(
                              //                         :final bip64Minutes
                              //                       ) =>
                              //                         "n_minutes".tr.replaceOne(
                              //                             bip64Minutes.toString()),
                              //                     },
                              //                     style:
                              //                         context.primaryTextTheme.bodyMedium,
                              //                   )),
                              //         )),

                              ConditionalWidget(
                                  enable: value.allowMemo,
                                  onActive: (context) => ContainerWithBorder(
                                      backgroundColor: context.onPrimaryContainer,
                                      onRemoveWidget: AddOrRemoveIconWidget(
                                        value.hasMemo,
                                        color: context.primaryContainer,
                                      ),
                                      onRemove: () {
                                        if (value.hasMemo) {
                                          value.onRemoveMemo();
                                          return;
                                        }
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
                                                          ],
                                                        )),
                                                    buttonText: "setup_memo".tr,
                                                    label: "memo".tr,
                                                    customForm: value.onValidateMemo))
                                            .then(value.onUpdateMemo);
                                      },
                                      child: APPAnimatedWithValue<String>(
                                        value: value.memo?.content,
                                        isExpanded: true,
                                        onValue: (context, value) => OneLineTextWidget(
                                            value,
                                            style: context.primaryTextTheme.bodyMedium),
                                        onNull: (context) => Text("tap_to_add_memo".tr,
                                            style: context.primaryTextTheme.bodyMedium),
                                      ))),
                              ContainerWithBorder(
                                  validate: !value.amount.isNegative,
                                  onRemoveIcon:
                                      Icon(Icons.edit, color: context.primaryContainer),
                                  backgroundColor: context.onPrimaryContainer,
                                  child: CoinAndMarketPriceView(
                                      balance: value.amount,
                                      showTokenImage: true,
                                      style: context.primaryTextTheme.titleMedium,
                                      symbolColor: context.primaryContainer)),
                            ],
                          ),
                        ));
              });
        },
      ),
      WidgetConstant.height20,
      LiveFormWidgetList(
          field: form.memos,
          builder: (context, field, value) => ContainerWithBorder(
              enableTap: false,
              onRemove: () {},
              onRemoveIcon: IconButton(
                  onPressed: () => form.onRemoveMemo(value),
                  icon: Icon(Icons.remove_circle, color: context.onPrimaryContainer)),
              child: OneLineTextWidget(value.memo.content,
                  style: context.onPrimaryTextTheme.bodyMedium)),
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
      TransactionFeeView(controller: form, onRetryFeeEstimate: form.estimateFee),
      TransactionStateSendTransaction(
        controller: form,
        mainContext: mainContext,
      ),
    ]);
  }
}

class UtxoSetupBip68View extends StatefulWidget {
  final ScrollController controller;
  const UtxoSetupBip68View(this.controller, {super.key});

  @override
  State<UtxoSetupBip68View> createState() => _UtxoLockTimeConfigurationViewState();
}

class _UtxoLockTimeConfigurationViewState extends State<UtxoSetupBip68View>
    with SafeState<UtxoSetupBip68View> {
  int maxNumber = BinaryOps.mask16;
  //  int maxMinutes =
  GlobalKey<FormState> formKey = GlobalKey();
  bool basedTimeStamp = false;
  int value = 0;
  void onToggleType() {
    basedTimeStamp = !basedTimeStamp;
    value = 0;
    if (basedTimeStamp) {
      maxNumber = ((BinaryOps.mask16 * 512) ~/ 60);
    }
    updateState();
  }

  void onChangeValue(int? value) {
    this.value = value ?? 0;
  }

  String? validateLocktime(String? value) {
    final v = int.tryParse(value ?? "");
    if (v == null) return "";
    if (basedTimeStamp) {
      if (v.isNegative || v > maxNumber) {
        return "locktime_must_between_0_n_minutes".replaceOne(maxNumber.toString());
      }
    } else {
      if (v.isNegative || v > maxNumber) {
        return "locktime_must_between_0_n_blocks".replaceOne(maxNumber.toString());
      }
    }
    return null;
  }

  void setup() {
    if (!formKey.ready()) return;
    final timelock = switch (basedTimeStamp) {
      true => Bip68ConfigurationTimelock(value),
      false => Bip68ConfigurationBlocks(value),
    };
    context.pop(timelock);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("utxo_timelock".tr),
      ),
      body: CustomScrollView(
        controller: widget.controller,
        slivers: [
          SliverConstraintsBoxView(
            padding: WidgetConstant.padding20,
            sliver: SliverToBoxAdapter(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PageTitleSubtitle(
                        title: "utxo_timelock".tr,
                        body: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("utxo_timelock_desc".tr),
                            Text(basedTimeStamp
                                ? "utxo_timelock_based_time_desc".tr
                                : "utxo_timelock_based_blocks_desc".tr),
                          ],
                        )),
                    AppCheckListTile(
                      value: basedTimeStamp,
                      title: Text("utxo_time_based_lock".tr),
                      subtitle: Text("utxo_time_based_lock_desc".tr),
                      onChanged: (p0) => onToggleType(),
                    ),
                    WidgetConstant.height20,
                    NumberTextField(
                      label: basedTimeStamp
                          ? "utxo_lock_duration_minutes".tr
                          : "utxo_lock_height_blocks".tr,
                      helperText: basedTimeStamp
                          ? "utxo_lock_helper_minutes_n_desc"
                              .tr
                              .replaceOne(maxNumber.toString())
                          : "utxo_lock_helper_blocks_n_desc"
                              .tr
                              .replaceOne(maxNumber.toString()),
                      max: maxNumber,
                      min: 0,
                      key: ValueKey<int>(maxNumber),
                      onChangeValue: onChangeValue,
                      validator: (v) => validateLocktime(v),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FixedElevatedButton(
                            padding: WidgetConstant.paddingVertical40,
                            onPressed: setup,
                            child: Text("utxo_setup_time_lock".tr)),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
