import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/extension/app_extensions/string.dart';

extension ExtQuickDateTimeFormater on DateTime {
  static String _twoDigits(int n) {
    return n.toString().padLeft(2, "0");
  }

  String toDateAndTimeWithSecound() {
    return "$year-${_twoDigits(month)}-${_twoDigits(day)} "
        "${_twoDigits(hour)}:${_twoDigits(minute)}:${_twoDigits(second)}";
  }

  String toDateAndTime() {
    return "$year-${_twoDigits(month)}-${_twoDigits(day)} "
        "${_twoDigits(hour)}:${_twoDigits(minute)}";
  }

  String toTimeOnlyStr() {
    return "${_twoDigits(hour)}:${_twoDigits(minute)}";
  }

  String toOnlyDateStr() {
    return "$year-${_twoDigits(month)}-${_twoDigits(day)}";
  }

  DateTime toOnlyDate() {
    return DateTime(year, month, day);
  }

  TimeOfDay timeOfDay() {
    return TimeOfDay(hour: hour, minute: minute);
  }
}

extension ExtDurationTranslate on Duration {
  String remainingTime() {
    if (inDays > 0) {
      return "n_days".tr.replaceOne(inDays.toString());
    }
    if (inHours > 0) {
      return "n_hours".tr.replaceOne(inHours.toString());
    }
    return "n_minutes".tr.replaceOne(inMinutes.toString());
  }
}
