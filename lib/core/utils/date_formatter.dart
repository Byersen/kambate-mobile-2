class AppDateFormatter {
  static const List<String> _weekDaysEs = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  static const List<String> _monthsShortEs = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  static const List<String> _monthsFullEs = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  /// Check if two dates represent the exact same calendar day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Get day name relative to current day ('Ayer', 'Hoy', 'Mañana', or 'Lunes', 'Martes'...)
  static String getRelativeDayName(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final diffInDays = target.difference(today).inDays;

    if (diffInDays == -1) {
      return 'Ayer';
    } else if (diffInDays == 0) {
      return 'Hoy';
    } else if (diffInDays == 1) {
      return 'Mañana';
    } else {
      final weekdayIndex = target.weekday - 1;
      return _weekDaysEs[weekdayIndex % 7];
    }
  }

  /// Short day and month string (e.g. "08 ago", "10 ago")
  static String formatShortDayMonth(DateTime dateTime) {
    final dayStr = dateTime.day.toString().padLeft(2, '0');
    final monthStr = _monthsShortEs[(dateTime.month - 1) % 12];
    return '$dayStr $monthStr';
  }

  /// Combined title for carousel card (e.g. "Hoy, 08 ago", "Lunes, 10 ago")
  static String formatCarouselLabel(DateTime dateTime) {
    final relName = getRelativeDayName(dateTime);
    final shortDate = formatShortDayMonth(dateTime);
    return '$relName, $shortDate';
  }

  /// Format event time with relative day context ("Hoy • 15:30", "10 ago • 20:00")
  static String formatEventTime(DateTime dateTime) {
    final relName = getRelativeDayName(dateTime);
    final hourStr = dateTime.hour.toString().padLeft(2, '0');
    final minStr = dateTime.minute.toString().padLeft(2, '0');
    final timeStr = '$hourStr:$minStr';

    if (relName == 'Hoy' || relName == 'Ayer' || relName == 'Mañana') {
      return '$relName • $timeStr';
    } else {
      final shortDate = formatShortDayMonth(dateTime);
      return '$shortDate • $timeStr';
    }
  }

  /// Date only string (e.g. "Viernes 08 Agosto")
  static String formatDate(DateTime dateTime) {
    final weekday = _weekDaysEs[(dateTime.weekday - 1) % 7];
    final dayStr = dateTime.day.toString().padLeft(2, '0');
    final month = _monthsFullEs[(dateTime.month - 1) % 12];
    return '$weekday $dayStr $month';
  }

  /// Full readable date with timezone context
  static String formatFullDate(DateTime dateTime) {
    final weekday = _weekDaysEs[(dateTime.weekday - 1) % 7];
    final dayStr = dateTime.day.toString().padLeft(2, '0');
    final month = _monthsFullEs[(dateTime.month - 1) % 12];
    final hourStr = dateTime.hour.toString().padLeft(2, '0');
    final minStr = dateTime.minute.toString().padLeft(2, '0');
    return '$weekday $dayStr $month, $hourStr:$minStr (CLT)';
  }
}
