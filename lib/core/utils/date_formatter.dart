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

  /// Check if two dates represent the exact same calendar day in local time
  static bool isSameDay(DateTime a, DateTime b) {
    final localA = a.toLocal();
    final localB = b.toLocal();
    return localA.year == localB.year &&
        localA.month == localB.month &&
        localA.day == localB.day;
  }

  /// Get day name relative to current day ('Ayer', 'Hoy', 'Mañana', or 'Lunes', 'Martes'...)
  static String getRelativeDayName(DateTime dateTime) {
    final localTarget = dateTime.toLocal();
    final localNow = DateTime.now();
    // Noon-based calculation prevents off-by-one errors during daylight saving time (DST) shifts
    final todayNoon = DateTime(localNow.year, localNow.month, localNow.day, 12);
    final targetNoon = DateTime(
      localTarget.year,
      localTarget.month,
      localTarget.day,
      12,
    );

    final diffInDays =
        (targetNoon.difference(todayNoon).inHours / 24).round();

    if (diffInDays == -1) {
      return 'Ayer';
    } else if (diffInDays == 0) {
      return 'Hoy';
    } else if (diffInDays == 1) {
      return 'Mañana';
    } else {
      final weekdayIndex = targetNoon.weekday - 1;
      return _weekDaysEs[weekdayIndex % 7];
    }
  }

  /// Short day and month string (e.g. "08 ago", "10 ago")
  static String formatShortDayMonth(DateTime dateTime) {
    final local = dateTime.toLocal();
    final dayStr = local.day.toString().padLeft(2, '0');
    final monthStr = _monthsShortEs[(local.month - 1) % 12];
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
    final local = dateTime.toLocal();
    final relName = getRelativeDayName(local);
    final hourStr = local.hour.toString().padLeft(2, '0');
    final minStr = local.minute.toString().padLeft(2, '0');
    final timeStr = '$hourStr:$minStr';

    if (relName == 'Hoy') {
      return timeStr;
    } else if (relName == 'Ayer' || relName == 'Mañana') {
      return '$relName • $timeStr';
    } else {
      final shortDate = formatShortDayMonth(local);
      return '$shortDate • $timeStr';
    }
  }

  /// Date only string (e.g. "Viernes 08 Agosto")
  static String formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final weekday = _weekDaysEs[(local.weekday - 1) % 7];
    final dayStr = local.day.toString().padLeft(2, '0');
    final month = _monthsFullEs[(local.month - 1) % 12];
    return '$weekday $dayStr $month';
  }

  /// Full readable date with timezone context
  static String formatFullDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final weekday = _weekDaysEs[(local.weekday - 1) % 7];
    final dayStr = local.day.toString().padLeft(2, '0');
    final month = _monthsFullEs[(local.month - 1) % 12];
    final hourStr = local.hour.toString().padLeft(2, '0');
    final minStr = local.minute.toString().padLeft(2, '0');
    final tz = local.timeZoneName.isNotEmpty ? ' (${local.timeZoneName})' : '';
    return '$weekday $dayStr $month, $hourStr:$minStr$tz';
  }
}
