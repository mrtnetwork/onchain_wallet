import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/widgets/widgets/extensions.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/constant/constant.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/types/types.dart';

class StellarTransactionSetupTimeBoundView extends StatefulWidget {
  final TransactionTimeBound currentTimeBound;
  const StellarTransactionSetupTimeBoundView({required this.currentTimeBound, super.key});

  @override
  State<StellarTransactionSetupTimeBoundView> createState() =>
      _StellarTransactionSetupTimeBoundViewState();
}

class _StellarTransactionSetupTimeBoundViewState
    extends State<StellarTransactionSetupTimeBoundView> with SafeState {
  TransactiomTimeBoundType timeBoundType = TransactiomTimeBoundType.auto;
  DateTime? timeBound;
  late final Map<TransactiomTimeBoundType, Widget> timeboundItems = {
    for (final i in TransactiomTimeBoundType.values) i: Text(i.name.tr),
  };
  final DateTime maximumDate =
      DateTime.now().toLocal().add(StellarConst.maxmimumTimeBound);
  bool isReady = false;

  void onChangeTimeBound(TransactiomTimeBoundType? timeBoundType) {
    if (timeBoundType == null) return;
    this.timeBoundType = timeBoundType;
    if (!this.timeBoundType.isManual) {
      timeBound = null;
    }
    checkIsReady();
    updateState();
  }

  void checkIsReady() {
    if (timeBoundType.isManual) {
      final timeBound = this.timeBound;
      final minimumTime = DateTime.now().toLocal().add(const Duration(minutes: 3));
      if (timeBound == null || timeBound.isBefore(minimumTime)) {
        isReady = false;
        if (timeBound != null) {
          this.timeBound = null;
          context.showAlert("time_is_insufficient".tr);
        }

        return;
      }
    }
    isReady = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    timeBoundType = widget.currentTimeBound.type;
    timeBound = widget.currentTimeBound.time;
    checkIsReady();
  }

  void pickTime() async {
    if (!mounted) return;
    try {
      final date = await showDatePicker(
          context: context, firstDate: DateTime.now().toLocal(), lastDate: maximumDate);
      if (!mounted || date == null) return;
      final now = DateTime.now().toLocal().add(const Duration(minutes: 10)).timeOfDay();
      final time = await showTimePicker(context: context, initialTime: now);
      if (!mounted || time == null) return;
      final minimumTime = DateTime.now().toLocal().add(const Duration(minutes: 3));
      final finalTime = date.copyWith(hour: time.hour, minute: time.minute);
      if (finalTime.isBefore(minimumTime)) {
        context.showAlert("time_is_insufficient".tr);
        return;
      }
      timeBound = finalTime;
    } finally {
      checkIsReady();
      updateState();
    }
  }

  void setup() {
    checkIsReady();
    if (!isReady) return;
    final timebound = TransactionTimeBound(type: timeBoundType, time: timeBound);
    context.pop(timebound);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitleSubtitle(
            title: "time_bound".tr, body: Text("stellar_time_bound_desc".tr)),
        Text("time_bound_type".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        AppDropDownBottom<TransactiomTimeBoundType>(
          items: timeboundItems,
          hint: "time_bound".tr,
          value: timeBoundType,
          onChanged: onChangeTimeBound,
          helperText: timeBoundType.helperText.tr,
        ),
        APPAnimatedSwitcher<TransactiomTimeBoundType>(enable: timeBoundType, widgets: {
          TransactiomTimeBoundType.manual: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WidgetConstant.height20,
                  Text("expiration_time".tr, style: context.textTheme.titleMedium),
                  Text("stellar_time_bound_max_time_desc".tr),
                  WidgetConstant.height8,
                  ContainerWithBorder(
                    onRemoveIcon:
                        Icon(Icons.edit, color: context.colors.onPrimaryContainer),
                    onRemove: pickTime,
                    child: timeBound == null
                        ? Text("tap_to_choose_data".tr,
                            style: context.onPrimaryTextTheme.bodyMedium)
                        : Text(timeBound!.toDateAndTimeWithSecound(),
                            style: context.onPrimaryTextTheme.bodyMedium),
                  )
                ],
              )
        }),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FixedElevatedButton(
              padding: WidgetConstant.paddingVertical40,
              onPressed: setup,
              child: Text("setup_time_bound".tr),
            ),
          ],
        )
      ],
    );
  }
}
