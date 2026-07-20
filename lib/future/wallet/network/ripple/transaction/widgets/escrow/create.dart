import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/operations/escrow/create.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/widgets/memo/memo.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

class RippleTransactionEscrowCreateWidget extends StatelessWidget {
  final RippleTransactionEscrowCreateOperation form;
  const RippleTransactionEscrowCreateWidget({required this.form, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      LiveFormWidgetAmount(
          onUpdateAmount: (amount, max) => form.onUpdateAmount(amount),
          onUpdateAmountMax: form.getMaxInput,
          field: form.amount),
      WidgetConstant.height20,
      LiveFormWidgetReceiverAddress(
          field: form.destination,
          account: form.account,
          onUpdateAddress: form.onUpdateDestination),
      WidgetConstant.height20,
      LiveFormWidget(
        field: form.cancelAfter,
        builder: (context, field, value) {
          return ContainerWithBorder(
            onRemove: () {
              if (value != null) {
                form.onUpdateCancelAfter(null);
                return;
              }
              showAdaptiveDialog<DateTime>(
                context: context,
                useRootNavigator: false,
                builder: (context) {
                  return DatePickerDialog(
                    firstDate: DateTime.now(),
                    lastDate: DateTime(3000),
                    fieldLabelText: field.title.tr,
                  );
                },
              ).then((date) {
                if (date == null) {
                  form.onUpdateCancelAfter(date);
                  return;
                }
                showAdaptiveDialog<TimeOfDay>(
                  context: context,
                  useRootNavigator: false,
                  builder: (context) {
                    return TimePickerDialog(
                      initialTime: TimeOfDay.now(),
                      helpText: date.toOnlyDateStr(),
                    );
                  },
                ).then((time) {
                  if (time == null) {
                    form.onUpdateCancelAfter(date);
                    return;
                  }
                  final DateTime picked =
                      DateTime(date.year, date.month, date.day, time.hour, time.minute);
                  form.onUpdateCancelAfter(picked);
                });
              });
            },
            onRemoveIcon: AddOrRemoveIconWidget(field.hasValue),
            child: APPAnimated(
                onActive: (context) => FullWidthWrapper(
                    key: ValueKey(value),
                    child: Text(
                      value?.toDateAndTime() ?? "tap_to_input_value".tr,
                      style: context.onPrimaryTextTheme.bodyMedium,
                    ))),
          );
        },
      ),
      WidgetConstant.height20,
      LiveFormWidget(
        field: form.finishAfter,
        builder: (context, field, value) {
          return ContainerWithBorder(
            onRemove: () {
              if (value != null) {
                form.onUpdateFinishAfter(null);
                return;
              }
              showAdaptiveDialog<DateTime>(
                context: context,
                useRootNavigator: false,
                builder: (context) {
                  return DatePickerDialog(
                    firstDate: DateTime.now(),
                    lastDate: DateTime(3000),
                    fieldLabelText: field.title.tr,
                  );
                },
              ).then((date) {
                if (date == null) {
                  form.onUpdateFinishAfter(date);
                  return;
                }
                showAdaptiveDialog<TimeOfDay>(
                  context: context,
                  useRootNavigator: false,
                  builder: (context) {
                    return TimePickerDialog(
                      initialTime: TimeOfDay.now(),
                      helpText: date.toOnlyDateStr(),
                    );
                  },
                ).then((time) {
                  if (time == null) {
                    form.onUpdateFinishAfter(date);
                    return;
                  }
                  final DateTime picked =
                      DateTime(date.year, date.month, date.day, time.hour, time.minute);
                  form.onUpdateFinishAfter(picked);
                });
              });
            },
            onRemoveIcon: AddOrRemoveIconWidget(field.hasValue),
            child: APPAnimated(
                onActive: (context) => FullWidthWrapper(
                      key: ValueKey(value),
                      child: Text(
                        value?.toDateAndTime() ?? "tap_to_input_value".tr,
                        style: context.onPrimaryTextTheme.bodyMedium,
                      ),
                    )),
          );
        },
      ),
      WidgetConstant.height20,
      LiveFormWidget(
        field: form.condition,
        builder: (context, field, value) {
          return ContainerWithBorder(
            onRemove: () {
              if (value != null) {
                form.onUpdateCondition(null);
                return;
              }
              context
                  .openSliverBottomSheet<String>(
                    "ripple_escrow_create_fields".tr,
                    child: StringWriterView(
                      defaultValue: field.value,
                      title: PageTitleSubtitle(
                          title: field.title,
                          body: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (field.subtitle != null) Text(field.subtitle!.tr),
                            ],
                          )),
                      buttonText: "setup_input".tr,
                      label: field.title,
                    ),
                  )
                  .then(form.onUpdateCondition);
            },
            onRemoveIcon: AddOrRemoveIconWidget(field.hasValue),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                  child: APPAnimated(
                      onActive: (context) => FullWidthWrapper(
                            key: ValueKey(value?.length),
                            child: Text(field.value ?? "tap_to_input_value".tr,
                                maxLines: 3,
                                style: context.onPrimaryTextTheme.bodyMedium),
                          ))),
              if (!field.hasValue) ...[
                WidgetConstant.width8,
                FilledButton(
                  onPressed: () {
                    context
                        .openSliverDialog<String>(
                            widget: (p0) => const _GenerateFulFillmentView(),
                            label: "fulfillment".tr)
                        .then(form.onUpdateCondition);
                  },
                  child: Text("generate".tr),
                )
              ],
            ]),
          );
        },
      ),
      WidgetConstant.height20,
      RippleTransactionMemoWidget(controller: form),
      WidgetConstant.height20,
      TransactionFeeView(controller: form, onRetryFeeEstimate: form.estimateFee),
      TransactionStateSendTransaction(controller: form)
    ]);
  }
}

class _GenerateFulFillmentView extends StatefulWidget {
  const _GenerateFulFillmentView();

  @override
  State<_GenerateFulFillmentView> createState() => _GenerateFulFillmentViewState();
}

class _GenerateFulFillmentViewState extends State<_GenerateFulFillmentView>
    with SafeState {
  final GlobalKey<StreamWidgetState> progressKey = GlobalKey();
  FulfillmentPreimageSha256? fulFillment;
  void generateFulFillment() async {
    if (progressKey.inProgress) return;
    if (fulFillment != null) {
      fulFillment = null;
      setState(() {});
      await MethodUtils.delayed(duration: Duration(milliseconds: 400));
    }
    progressKey.process();

    final result = await IResult.call(() async {
      final rand = QuickCrypto.generateRandom();
      final fullFillment = FulfillmentPreimageSha256.generate(rand);
      return fullFillment;
    }, delay: APPConst.oneSecoundDuration);
    if (result.isErr) {
      progressKey.error();
    } else {
      fulFillment = result.unwrap();
      progressKey.success();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitleSubtitle(
            title: "create_random_fulfillment".tr,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("fulfillment_desc".tr),
                WidgetConstant.height8,
                Text("fulfillment_desc2".tr)
              ],
            )),
        APPAnimatedSize(
          duration: APPConst.animationDuraion,
          isActive: fulFillment == null,
          onActive: (context) => WidgetConstant.sizedBox,
          onDeactive: (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("fulfillment".tr, style: context.textTheme.titleMedium),
              WidgetConstant.height8,
              ContainerWithBorder(
                  child: CopyableTextWidget(
                      text: fulFillment!.fulfillment,
                      isSensitive: true,
                      color: context.onPrimaryContainer)),
              WidgetConstant.height20,
              Text("condition".tr, style: context.textTheme.titleMedium),
              WidgetConstant.height8,
              ContainerWithBorder(
                  child: CopyableTextWidget(
                      text: fulFillment!.condition,
                      isSensitive: true,
                      color: context.onPrimaryContainer))
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: APPConst.animationDuraion,
              child: Padding(
                padding: WidgetConstant.paddingVertical20,
                child: fulFillment == null
                    ? ButtonProgress(
                        key: progressKey,
                        child: (context) => FilledButton(
                            onPressed: generateFulFillment, child: Text("generate".tr)))
                    : Row(children: [
                        FilledButton(
                            onPressed: () {
                              context
                                  .openSliverDialog<bool>(
                                      widget: (p0) => DialogTextView(
                                            text: "saved_fulfillment_desc".tr,
                                            buttonWidget: const DialogDoubleButtonView(),
                                          ),
                                      label: "fulfillment".tr)
                                  .then((value) {
                                if (value == true && context.mounted) {
                                  context.pop(fulFillment?.condition);
                                }
                              });
                            },
                            child: Text("apply_for_condition".tr)),
                        WidgetConstant.width8,
                        IconButton(
                            onPressed: generateFulFillment,
                            icon: const Icon(Icons.refresh))
                      ]),
              ),
            )
          ],
        )
      ],
    );
  }
}
