import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/widgets/widgets/animated/widgets/animated_size.dart';
import 'package:on_chain_wallet/future/widgets/widgets/paste_icon_widget.dart';
import 'button.dart';
import 'container_with_border.dart';
import 'copy_icon_widget.dart';
import 'text_field.dart';
import 'widget_constant.dart';

class UTF8EncoderView extends StatefulWidget {
  const UTF8EncoderView({super.key});

  @override
  State<UTF8EncoderView> createState() => _UTF8EncoderViewState();
}

class _UTF8EncoderViewState extends State<UTF8EncoderView>
    with SafeState<UTF8EncoderView> {
  String? inHex;

  final GlobalKey<AppTextFieldState> textFieldKey =
      GlobalKey(debugLabel: "_UTF8EncoderViewState");
  late String text = "";
  void onChange(String v) {
    text = v;
    final decode = MethodUtils.fallbackOnException(
        () => BytesUtils.tryToHexString(StringUtils.tryEncode(v), prefix: "0x"),
        logOnDebug: false);
    if (decode != inHex) {
      inHex = decode;
      updateState();
    }
  }

  String? validator(String? v) {
    return null;
  }

  void onPaste(String v) {
    textFieldKey.currentState?.updateText(v);
  }

  void onPressed() {
    if (inHex == null) return;
    if (context.mounted) {
      context.pop(inHex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("utf8_encoder".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height20,
        AppTextField(
          label: "string".tr,
          initialValue: text,
          validator: validator,
          suffixIcon: PasteTextIcon(onPaste: onPaste, isSensitive: false),
          onChanged: onChange,
          key: textFieldKey,
        ),
        APPAnimatedSize(
            isActive: inHex != null,
            onActive: (context) => ContainerWithBorder(
                  child:
                      CopyableTextWidget(text: inHex!, color: context.onPrimaryContainer),
                ),
            onDeactive: (context) => WidgetConstant.sizedBox),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FixedElevatedButton(
                padding: WidgetConstant.paddingVertical40,
                onPressed: onPressed,
                child: Text('setup'.tr))
          ],
        )
      ],
    );
  }
}
