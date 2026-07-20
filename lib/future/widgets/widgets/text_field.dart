import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputFormatter;
import 'package:on_chain_wallet/app/core.dart' show MethodUtils, StrUtils;
import 'package:on_chain_wallet/app/models/models/typedef.dart'
    show NullStringString, StringVoid, DynamicVoid;
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

class AppTextField extends StatefulWidget {
  const AppTextField(
      {super.key,
      this.minlines,
      this.maxLines,
      this.label,
      this.onChanged,
      this.hint,
      this.error,
      this.validator,
      this.inputFormatters,
      this.suffix,
      this.helperText,
      this.keyboardType,
      this.textDirection,
      this.padding = WidgetConstant.paddingVertical8,
      this.obscureText = false,
      this.suffixIcon,
      this.prefix,
      this.prefixIcon,
      this.textInputAction,
      this.focusNode,
      this.nextFocus,
      this.disableContextMenu = false,
      this.filled = true,
      this.initialValue,
      this.style,
      this.textAlign = TextAlign.start,
      this.readOnly = false,
      this.pasteIcon = false,
      this.isSensitive,
      this.helperStyle,
      this.onSubmitField,
      this.controller,
      this.constraints,
      this.enableInteractiveSelection = true,
      this.autofocus = false,
      this.canRequestFocus = true,
      this.errorBuilder,
      this.onTap,
      this.authoValidateMode = AutovalidateMode.always});
  final AutovalidateMode authoValidateMode;
  final TextEditingController? controller;
  final bool autofocus;
  final bool canRequestFocus;
  final String? label;
  final String? hint;
  final String? error;
  final StringVoid? onChanged;
  final StringVoid? onSubmitField;
  final NullStringString? validator;
  final FormFieldErrorBuilder? errorBuilder;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;
  final String? helperText;
  final TextInputType? keyboardType;
  final TextDirection? textDirection;
  final EdgeInsets padding;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefix;
  final Widget? prefixIcon;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final bool disableContextMenu;
  final int? minlines;
  final int? maxLines;
  final bool filled;
  final String? initialValue;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool readOnly;
  final bool pasteIcon;
  final bool? isSensitive;
  final TextStyle? helperStyle;
  final BoxConstraints? constraints;
  final DynamicVoid? onTap;
  final bool enableInteractiveSelection;
  @override
  State<AppTextField> createState() => AppTextFieldState();
}

class AppTextFieldState extends State<AppTextField> with SafeState<AppTextField> {
  late TextDirection? direction = widget.textDirection;
  late TextEditingController controller;
  late bool obscureText = widget.obscureText;
  void listener() {
    widget.onChanged?.call(controller.text);
  }

  void onChaangeObscureText() {
    obscureText = !obscureText;
    updateState();
  }

  void onChange(String value) {
    if (widget.textDirection != null) return;
    if (value.trim().isEmpty) {
      if (direction != null) {
        direction = null;
        updateState();
      }
    } else if (StrUtils.startsWithRtl(value)) {
      if (direction != TextDirection.rtl) {
        direction = TextDirection.rtl;
        updateState();
      }
    } else {
      if (direction != TextDirection.ltr) {
        direction = TextDirection.ltr;
        updateState();
      }
    }
  }

  void onSubmitField(String v) {
    widget.nextFocus?.requestFocus();
    widget.onSubmitField?.call(v);
  }

  void updateText(String text) {
    if (widget.readOnly) return;
    controller.text = text;
  }

  void clear() {
    controller.clear();
  }

  String getValue() => controller.text;

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? TextEditingController();
    controller.addListener(listener);
    if (widget.controller == null && widget.initialValue != null) {
      MethodUtils.executeAfterDelay(() async {
        controller.text = widget.initialValue ?? "";
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (widget.controller == null) {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: TextFormField(
        textAlign: widget.textAlign,
        controller: controller,
        inputFormatters: widget.inputFormatters,
        validator: widget.validator,
        autofillHints: const [],
        onChanged: onChange,
        textDirection: direction,
        enableInteractiveSelection: widget.enableInteractiveSelection,
        autovalidateMode: widget.authoValidateMode,
        keyboardType: widget.keyboardType,
        focusNode: widget.focusNode,
        errorBuilder: widget.errorBuilder,
        obscureText: obscureText,
        style: widget.style,
        readOnly: widget.readOnly,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: onSubmitField,
        minLines: widget.minlines,
        selectionControls: MaterialTextSelectionControls(),
        maxLines: widget.obscureText ? 1 : widget.maxLines,
        autofocus: widget.autofocus,
        canRequestFocus: widget.canRequestFocus,
        onTap: widget.onTap,
        contextMenuBuilder: widget.disableContextMenu
            ? null
            : (context, editableTextState) {
                return AdaptiveTextSelectionToolbar.editableText(
                    editableTextState: editableTextState);
              },
        decoration: InputDecoration(
            filled: widget.filled,
            prefix: widget.prefix,
            prefixIcon: widget.prefixIcon,
            helperStyle: widget.helperStyle,
            constraints: widget.constraints,
            helperMaxLines: 2,
            errorMaxLines: 2,
            helperText: widget.helperText,
            labelText: widget.label,
            border: OutlineInputBorder(
                borderRadius: WidgetConstant.border8, borderSide: BorderSide.none),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.obscureText)
                  ObscureIcon(show: obscureText, onTap: onChaangeObscureText),
                if (widget.pasteIcon && !widget.readOnly)
                  PasteTextIcon(
                      onPaste: updateText, isSensitive: widget.isSensitive ?? false),
                if (widget.suffixIcon != null) widget.suffixIcon!,
              ],
            ),
            hintText: widget.hint,
            errorText: widget.error),
      ),
    );
  }
}
