import 'package:intl/intl.dart';

class AppDateFormatter {
  /// Format a DateTime to Chilean local friendly string
  /// Examples: "Hoy • 15:30", "Mañana • 20:00", "08 Ago • 18:00"
  static String formatEventTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final eventDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final timeStr = DateFormat('HH:mm').format(dateTime);

    if (eventDay == today) {
      return 'Hoy • $timeStr';
    } else if (eventDay == tomorrow) {
      return 'Mañana • $timeStr';
    } else {
      final dateStr = DateFormat('dd MMM', 'es').format(dateTime);
      return '$dateStr • $timeStr';
    }
  }

  /// Date only string (e.g. "Viernes 08 Agosto")
  static String formatDate(DateTime dateTime) {
    return DateFormat('EEEE dd MMMM', 'es').format(dateTime);
  }

  /// Full readable date with timezone context
  static String formatFullDate(DateTime dateTime) {
    return '${DateFormat('EEEE dd MMMM, HH:mm', 'es').format(dateTime)} (CLT)';
  }
}
