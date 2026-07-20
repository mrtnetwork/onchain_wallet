import 'package:flutter/widgets.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/transaction/types/types.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

class CardanoTransactionMemoWriteView extends StatefulWidget {
  const CardanoTransactionMemoWriteView({
    super.key,
    required this.title,
    required this.label,
    required this.buttonText,
    required this.labeles,
    this.customForm,
    this.defaultValue,
  });
  final Widget title;
  final String label;
  final String buttonText;
  final String? defaultValue;
  final NullStringString? customForm;
  final List<BigInt> labeles;

  @override
  State<CardanoTransactionMemoWriteView> createState() =>
      _CardanoTransactionMemoWriteViewState();
}

class _CardanoTransactionMemoWriteViewState extends State<CardanoTransactionMemoWriteView>
    with SafeState {
  final GlobalKey<AppTextFieldState> textFieldKey =
      GlobalKey(debugLabel: "_StringWriterViewState");
  final GlobalKey<FormState> formKey = GlobalKey(debugLabel: "_StringWriterViewState_1");
  late String text = widget.defaultValue ?? "";
  BigInt label = BigInt.one;

  BigInt findNextLabe() {
    BigInt l = label;
    if (widget.labeles.contains(l)) {
      while (true) {
        l += BigInt.one;
        if (widget.labeles.contains(l)) continue;
        break;
      }
    }
    return l;
  }

  void onChangeLabel(int? val) {
    if (val == null || val.isNegative) return;
    label = BigInt.from(val);
  }

  String? validateLabel(String? v) {
    final val = int.tryParse(v ?? "");
    if (val == null || val.isNegative) {
      return "enther_valid_un_label".tr;
    }
    label = BigInt.from(val);
    if (widget.labeles.contains(label)) {
      return "label_already_exists".tr;
    }
    return null;
  }

  void onChange(String v) {
    text = v;
  }

  void onPaste(String v) {
    textFieldKey.currentState?.updateText(v);
  }

  void onPressed() {
    if (!formKey.ready()) return;
    if (context.mounted) {
      context.pop(ADATransactionMemo(tag: label, text: text));
    }
  }

  @override
  void initState() {
    super.initState();
    label = findNextLabe();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.title,
          WidgetConstant.height20,
          NumberTextField(
            label: "metadatum_label".tr,
            onChangeValue: onChangeLabel,
            validator: validateLabel,
            max: null,
            min: 0,
            defaultValue: label.toInt(),
          ),
          WidgetConstant.height20,
          AppTextField(
            label: widget.label,
            minlines: 2,
            maxLines: 5,
            initialValue: text,
            validator: widget.customForm,
            suffixIcon: PasteTextIcon(
              onPaste: onPaste,
              isSensitive: false,
            ),
            onChanged: onChange,
            key: textFieldKey,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FixedElevatedButton(
                padding: WidgetConstant.paddingVertical20,
                onPressed: onPressed,
                child: Text(widget.buttonText),
              )
            ],
          )
        ],
      ),
    );
  }
}
