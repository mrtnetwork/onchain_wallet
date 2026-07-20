import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_chain_wallet/app/core.dart';

import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

class BigRangeTextInputFormatter extends TextInputFormatter {
  final BigInt min;
  final BigInt? max;

  BigRangeTextInputFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newString = newValue.text;

    if (newString.isNotEmpty) {
      final BigInt? enteredNumber = BigInt.tryParse(newString);
      if (enteredNumber != null) {
        if (enteredNumber < min) {
          return BigRetionalTextInputFormatter._buildOldValue(oldValue);
        } else if (max != null && enteredNumber > max!) {
          return BigRetionalTextInputFormatter._buildOldValue(oldValue);
        } else {
          newString = enteredNumber.toString();
        }
      } else {
        return BigRetionalTextInputFormatter._buildOldValue(oldValue);
      }
    } else {
      newString = min.toString();
    }
    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}

class RangeTextInputFormatter extends TextInputFormatter {
  final int min;
  final int? max;

  RangeTextInputFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newString = newValue.text;

    if (newString.isNotEmpty) {
      final int? enteredNumber = int.tryParse(newString);
      if (enteredNumber != null) {
        if (enteredNumber < min) {
          return BigRetionalTextInputFormatter._buildOldValue(oldValue);
        } else if (max != null && enteredNumber > max!) {
          return BigRetionalTextInputFormatter._buildOldValue(oldValue);
        } else {
          newString = enteredNumber.toString();
        }
      } else {
        return BigRetionalTextInputFormatter._buildOldValue(oldValue);
      }
    } else {
      newString = min.toString();
    }
    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}

class ValidIntegerTextInputFormatter extends TextInputFormatter {
  ValidIntegerTextInputFormatter();
  static TextEditingValue _buildOldValue(TextEditingValue oldValue) {
    final int? enteredNumber = IntUtils.tryParse(oldValue.text);
    if (enteredNumber == null) {
      return const TextEditingValue(
        text: "",
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    return oldValue;
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newString = newValue.text.trim();

    if (newString.isNotEmpty) {
      final int? enteredNumber = IntUtils.tryParse(newString);
      if (enteredNumber == null) {
        return _buildOldValue(oldValue);
      }
    } else {
      newString = '';
    }
    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}

class BigRetionalTextInputFormatter extends TextInputFormatter {
  // final BigRational? min;
  final BigRational? max;
  final int? maxScale;
  final bool allowDecimal;
  final bool allowSign;

  BigRetionalTextInputFormatter(
      {this.max, this.maxScale, this.allowSign = true, this.allowDecimal = true});

  static TextEditingValue _buildOldValue(TextEditingValue oldValue) {
    final BigRational? enteredNumber = BigRational.tryParse(oldValue.text);
    if (enteredNumber == null) {
      return const TextEditingValue(
          text: "", selection: TextSelection.collapsed(offset: 0));
    }
    return oldValue;
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final String newString = newValue.text;
    if (newString.isNotEmpty) {
      final BigRational? enteredNumber = BigRational.tryParse(newString);
      if (enteredNumber != null) {
        if (max != null && enteredNumber > max!) {
          return _buildOldValue(oldValue);
        } else if (maxScale != null && enteredNumber.scale > maxScale!) {
          return _buildOldValue(oldValue);
        } else if (!allowDecimal &&
            (enteredNumber.isDecimal || newString.contains("."))) {
          return _buildOldValue(oldValue);
        } else if (!allowSign && enteredNumber.isNegative) {
          return _buildOldValue(oldValue);
        }
      } else {
        return _buildOldValue(oldValue);
      }
    }
    return TextEditingValue(
        text: newString, selection: TextSelection.collapsed(offset: newString.length));
  }
}

class CurrencyTextEdittingController extends TextEditingController {
  String? _symbol;
  final bool showMarketPrice;
  CurrencyTextEdittingController({super.text = '', this.showMarketPrice = true});

  String getText() {
    return text.replaceAll(",", '');
  }

  void setSymbol(String symbol) {
    _symbol = symbol;
  }

  @override
  void dispose() {
    super.dispose();
    _symbol = null;
  }

  @override
  TextSpan buildTextSpan(
      {required BuildContext context, TextStyle? style, required bool withComposing}) {
    assert(!value.composing.isValid || !withComposing || value.isComposingRangeValid);
    final symbol = _symbol;
    // If the composing range is out of range for the current text, ignore it to
    // preserve the tree integrity, otherwise in release mode a RangeError will
    // be thrown and this EditableText will be built with a broken subtree.
    final bool composingRegionOutOfRange = !value.isComposingRangeValid || !withComposing;

    if (composingRegionOutOfRange) {
      if (symbol == null) {
        return TextSpan(style: style, text: text);
      }
      return TextSpan(
        style: style,
        children: [
          TextSpan(style: style, text: text.trim().isEmpty ? '0.0' : text),
          WidgetSpan(
              child: Opacity(
                  opacity: 0.4,
                  child: Text(" $symbol", style: context.textTheme.labelLarge))),
        ],
      );
    }

    final TextStyle composingStyle =
        style?.merge(const TextStyle(decoration: TextDecoration.underline)) ??
            const TextStyle(decoration: TextDecoration.underline);
    return TextSpan(
      style: style,
      children: <TextSpan>[
        TextSpan(text: value.composing.textBefore(value.text)),
        TextSpan(style: composingStyle, text: value.composing.textInside(value.text)),
        TextSpan(text: value.composing.textAfter(value.text)),
      ],
    );
  }
}

class BigRetionalWithSeperatorTextInputFormatter extends TextInputFormatter {
  final BigRational? min;
  final BigRational? max;
  final int? maxScale;
  final bool allowDecimal;
  final bool allowSign;
  final String sperator;
  static final leadingZero = RegExp(r'^0{2,}');
  final RegExp? scale;
  static final RegExp speratorRegex = RegExp(',');

  BigRetionalWithSeperatorTextInputFormatter({
    this.min,
    this.max,
    this.maxScale,
    this.allowSign = true,
    this.allowDecimal = true,
    this.sperator = ',',
  }) : scale = maxScale == null || maxScale == 0 ? null : RegExp(r'\.(\d+)$');

  static TextEditingValue _buildOldValue(TextEditingValue oldValue,
      {String sperator = ','}) {
    final String newString = oldValue.text.replaceAll(sperator, '');
    final BigRational? enteredNumber = BigRational.tryParse(newString);
    if (enteredNumber == null) {
      return const TextEditingValue(
          text: "", selection: TextSelection.collapsed(offset: 0));
    }
    return oldValue;
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    bool isEnd = newValue.text.length == newValue.selection.end;
    String newString = newValue.text.replaceAll(sperator, '');
    if (newString.isNotEmpty) {
      final BigRational? enteredNumber = BigRational.tryParse(newString);
      if (newString == ".") {
        newString = "0.";
      } else if (enteredNumber != null) {
        final match = scale?.firstMatch(newString);
        if (match != null) {
          if (match.group(1)!.length > maxScale!) {
            return _buildOldValue(oldValue);
          }
        }
        if (leadingZero.hasMatch(newString)) {
          return _buildOldValue(oldValue);
        }
        if (min != null && enteredNumber < min!) {
          return _buildOldValue(oldValue);
        } else if (max != null && enteredNumber > max!) {
          return _buildOldValue(oldValue);
        } else if (maxScale != null && enteredNumber.scale > maxScale!) {
          return _buildOldValue(oldValue);
        } else if (!allowDecimal &&
            (enteredNumber.isDecimal || newString.contains("."))) {
          return _buildOldValue(oldValue);
        } else if (!allowSign && enteredNumber.isNegative) {
          return _buildOldValue(oldValue);
        }
      } else {
        return _buildOldValue(oldValue);
      }
    }
    final newTxt =
        StrUtils.to3Digits(newString, allowEmptyFractional: true, separator: sperator);
    if (!isEnd) {
      final current = newValue.text.substring(0, newValue.selection.end);
      final commaCount = speratorRegex.allMatches(current).length;
      final s = newTxt.substring(0, newValue.selection.end);
      final scommaCount = speratorRegex.allMatches(s).length;
      final ss = scommaCount - commaCount;
      return TextEditingValue(
          text: newTxt,
          selection: TextSelection.collapsed(offset: newValue.selection.end + ss));
    }
    return TextEditingValue(
        text: newTxt, selection: TextSelection.collapsed(offset: newTxt.length));
  }
}

class WebViewTextEditingController extends TextEditingController {
  WebViewTextEditingController({super.text = ''});

  String getText() {
    return text.replaceAll(",", '');
  }

  void setSymbol(String symbol) {}

  @override
  TextSpan buildTextSpan(
      {required BuildContext context, TextStyle? style, required bool withComposing}) {
    assert(!value.composing.isValid || !withComposing || value.isComposingRangeValid);
    // final symbol = _symbol;
    // If the composing range is out of range for the current text, ignore it to
    // preserve the tree integrity, otherwise in release mode a RangeError will
    // be thrown and this EditableText will be built with a broken subtree.
    final bool composingRegionOutOfRange = !value.isComposingRangeValid || !withComposing;

    if (composingRegionOutOfRange) {
      return TextSpan(style: style, text: text);
    }

    final TextStyle composingStyle =
        style?.merge(const TextStyle(decoration: TextDecoration.underline)) ??
            const TextStyle(decoration: TextDecoration.underline);
    return TextSpan(
      style: style,
      children: <TextSpan>[
        TextSpan(text: value.composing.textBefore(value.text)),
        TextSpan(style: composingStyle, text: value.composing.textInside(value.text)),
        TextSpan(text: value.composing.textAfter(value.text)),
      ],
    );
  }
}

class UrlSchemeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Let the user type freely if text is shorter than "http://"
    if (text.length < 7) {
      return newValue;
    }

    // Check if the text starts with http:// or https:// (case insensitive)
    final lower = text.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return newValue;
    }

    // Auto-prepend https://
    final newText = 'https://$text';
    final offset = newValue.selection.baseOffset + 'https://'.length;

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
