import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:flutter/widgets.dart';
import 'package:on_chain_wallet/app/core.dart' show APPConst;
import 'package:on_chain_wallet/app/models/models/typedef.dart' show NullStringString;
import 'package:on_chain_wallet/future/text_field/input_formaters.dart';
import 'button.dart';
import 'constraints_box_view.dart';
import 'paste_icon_widget.dart';
import 'text_field.dart';
import 'widget_constant.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

class NumberWriteView extends StatefulWidget {
  const NumberWriteView({
    super.key,
    required this.title,
    required this.label,
    required this.buttonText,
    this.allowDecimal = true,
    this.defaultValue,
    this.min,
    this.max,
    this.regExp,
    this.allowSign = true,
    this.customForm,
  });
  final Widget title;
  final String label;
  final String buttonText;
  final BigRational? min;
  final BigRational? max;
  final RegExp? regExp;
  final BigRational? defaultValue;
  // final int? maxPrecision;
  final bool allowDecimal;
  final bool allowSign;
  final NullStringString? customForm;

  @override
  State<NumberWriteView> createState() => _NumberWriteViewState();
}

class _NumberWriteViewState extends State<NumberWriteView> with SafeState {
  final GlobalKey<AppTextFieldState> textFieldKey =
      GlobalKey(debugLabel: "_NumberWriteViewState");
  final GlobalKey<FormState> formKey = GlobalKey(debugLabel: "_NumberWriteViewState_1");
  late String text = widget.defaultValue?.toString() ?? "0";
  void onChange(String v) {
    text = v;
  }

  String? validator(String? v) {
    final val = BigRational.tryParse(v ?? "");
    if (val == null) {
      return "enter_valid_number".tr;
    }
    if (widget.regExp != null) {
      if (!widget.regExp!.hasMatch(v!)) {
        return "regular_exception_validate_desc".tr.replaceOne(widget.regExp!.pattern);
      }
    }
    if (widget.min != null) {
      if (val < widget.min!) {
        return "minium_numnber_validator".tr.replaceOne(widget.min!.toString().to3Digits);
      }
    }
    if (widget.max != null) {
      if (val > widget.max!) {
        return "maximum_number_validator".tr.replaceOne(widget.max!.toString().to3Digits);
      }
    }
    return null;
  }

  void onPaste(String v) {
    textFieldKey.currentState?.updateText(v);
  }

  void onPressed() {
    if (!formKey.ready()) return;
    final parse = BigRational.tryParse(text);

    if (context.mounted && parse != null) {
      context.pop(parse);
    }
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
          ConstraintsBoxView(
            padding: WidgetConstant.paddingHorizontal20,
            maxWidth: APPConst.maxTextFieldWidth,
            child: AppTextField(
              label: widget.label,
              minlines: 1,
              maxLines: 2,
              initialValue: text,
              keyboardType: TextInputType.numberWithOptions(
                  decimal: widget.allowDecimal, signed: widget.allowSign),
              inputFormatters: [
                BigRetionalTextInputFormatter(
                    allowDecimal: widget.allowDecimal,
                    allowSign: widget.min?.isNegative ?? true),
              ],
              validator: widget.customForm ?? validator,
              suffixIcon: PasteTextIcon(onPaste: onPaste, isSensitive: false),
              textAlign: TextAlign.center,
              onChanged: onChange,
              key: textFieldKey,
            ),
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
