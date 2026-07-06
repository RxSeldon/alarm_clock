/// Pure formatting helpers, kept separate from widgets so the same logic can
/// be unit tested without touching the widget tree (Single Responsibility).
class TimeFormatter {
  const TimeFormatter._();

  static const List<String> _weekdayShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _weekdayLong = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// "07:42:05" digits of the 12-hour clock face; pair with [period].
  static String clock12(DateTime time) {
    final int displayHour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    return '${_two(displayHour)}:${_two(time.minute)}:${_two(time.second)}';
  }

  /// "AM" / "PM" suffix for the clock face.
  static String period(DateTime time) => time.hour >= 12 ? 'PM' : 'AM';

  /// "Thursday, July 2" style date line.
  static String longDate(DateTime time) =>
      '${_weekdayLong[time.weekday - 1]}, ${_months[time.month - 1]} ${time.day}';

  /// "07:42 AM" style 12-hour label used for alarm rows/pickers.
  static String alarmTime(int hour, int minute) {
    final String period = hour >= 12 ? 'PM' : 'AM';
    final int displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '${_two(displayHour)}:${_two(minute)} $period';
  }

  /// "Mon Wed Fri" / "Every day" / "One time" summary of repeat days.
  static String repeatSummary(Set<int> days) {
    if (days.isEmpty) return 'One time';
    if (days.length == 7) return 'Every day';
    final List<int> sorted = days.toList()..sort();
    return sorted.map((int d) => _weekdayShort[d - 1]).join('  ');
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
