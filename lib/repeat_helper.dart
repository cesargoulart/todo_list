// FILE: repeat_helper.dart

import 'todo.dart';

enum RepeatInterval { none, weekly, monthly, yearly }

class RepeatHelper {
  static DateTime? getNextRepeatDate(DateTime? currentDate, RepeatInterval interval) {
    if (currentDate == null) return null;

    switch (interval) {
      case RepeatInterval.weekly:
        return currentDate.add(Duration(days: 7));
      case RepeatInterval.monthly:
        return DateTime(currentDate.year, currentDate.month + 1, currentDate.day);
      case RepeatInterval.yearly:
        return DateTime(currentDate.year + 1, currentDate.month, currentDate.day);
      case RepeatInterval.none:
      default:
        return null;
    }
  }
}