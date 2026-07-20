import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/extension/app_extensions/string.dart';

typedef ONUPDATEVALUE<T> = bool Function(T previous, T current);
typedef ONVALIDATEERROR<T, E extends Object?> = String? Function(
    LiveFormField<T, E> field, T value);
typedef ONCHECKFIELDFILLED<T> = bool Function(T value);

class LiveFormField<IN extends Object?, OUT extends Object?> {
  LiveFormField({
    required this.title,
    this.onUpdateValue,
    this.subtitle,
    this.optional = false,
    this.onValidateError,
    required IN value,
  }) : live = StreamValue(value, name: "LiveFormField");

  bool get hasValue => value != null;
  bool get complete => optional || value != null;
  bool get isReady => complete && validate == null;
  bool get hasError => !complete || validate != null;

  final ONVALIDATEERROR<IN, OUT>? onValidateError;
  final ONUPDATEVALUE<IN>? onUpdateValue;
  final String title;
  final String? subtitle;
  final bool optional;
  final StreamValue<IN> live;

  // String? _validate;
  String? get validate => _getError();
  IN get value => live.value;

  void setValue(IN v) {
    if (v == live.value) return;
    if (optional && v == null) {
      live.silent = v;
      notify();
      return;
    }
    final onUpdateValue = this.onUpdateValue;
    if (onUpdateValue != null && !onUpdateValue(value, v)) return;
    live.silent = v;
    notify();
  }

  void dispose() {
    live.dispose();
  }

  String? _getError() {
    if (!optional && this.value == null) {
      return "field_is_required".tr.replaceOne(title.tr);
    }
    final onValidateError = this.onValidateError;
    if (onValidateError != null) {
      return onValidateError(this, live.value);
    }
    final value = live.value;
    if (value != null) return null;
    if (optional) return null;
    return "field_is_required".tr.replaceOne(title.tr);
  }

  void notify() {
    live.notify();
  }

  OUT get output => value as OUT;
}

typedef ONUPDATEFIELDSVALUE<T> = bool Function(List<T> values, T current);
typedef ONVALIDATEFIELDSERROR<T> = String? Function(List<T> value);
typedef ONUPDATEVALUEFIELDS<T> = bool Function(T value);

class LiveFormFields<T extends Object> extends LiveFormField<List<T>, List<T>> {
  LiveFormFields({
    required super.title,
    super.subtitle,
    super.optional = false,
    super.onValidateError,
    this.onUpdateValueFields,
    this.maxLength,
    List<T> value = const [],
  }) : super(value: [...value]);
  final ONUPDATEVALUEFIELDS<T>? onUpdateValueFields;
  final int? maxLength;

  @override
  bool get hasValue => value.isNotEmpty;
  @override
  bool get complete => optional || value.isNotEmpty;

  @override
  List<T> get value => live.value;
  void addValue(T v) {
    if (live.value.contains(v)) return;
    final onUpdateValueFields = this.onUpdateValueFields;
    if (onUpdateValueFields != null && !onUpdateValueFields(v)) {
      return;
    }

    live.value.add(v);
    notify();
  }

  void addValues(List<T> values) {
    for (final v in values) {
      if (live.value.contains(v)) continue;
      live.value.add(v);
    }
    notify();
  }

  void setValues(List<T> values) {
    live.silent = values;
    notify();
  }

  void removeValue(T value) {
    final r = live.value.remove(value);
    assert(r, "object does not exists.");
    notify();
  }

  void replace(T value, T newValue) {
    final index = this.value.indexWhere((e) => identical(value, e));
    assert(!index.isNegative, "item not found.");
    if (index.isNegative) return;
    live.value[index] = newValue;
    live.notify();
  }

  @override
  void dispose() {
    live.dispose();
  }

  @override
  String? _getError() {
    if (!optional && this.value.isEmpty) {
      return "field_is_required".tr.replaceOne(title.tr);
    }
    final maxLength = this.maxLength;
    if (maxLength != null && this.value.length > maxLength) {
      return "maximum_item_for_field"
          .tr
          .replaceOne(maxLength.toString())
          .replaceTwo(title);
    }
    final onValidateError = this.onValidateError;
    if (onValidateError != null) {
      return onValidateError(this, live.value);
    }
    final value = live.value;
    if (value.isNotEmpty) return null;
    if (optional) return null;
    return "field_is_required".tr.replaceOne(title.tr);
  }

  void clear() {
    live.silent = [];
    notify();
  }

  @override
  void notify() {
    live.notify();
  }
}
