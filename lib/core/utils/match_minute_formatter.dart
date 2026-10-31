import '../../models/event_model.dart';
import '../../models/sport_type.dart';

/// Formateador reutilizable del minuto o estado de juego para eventos deportivos en vivo.
///
/// Soporta:
/// - Fútbol:
///   - En entretiempo (HT, Halftime, Entretiempo, Descanso): retorna "ET".
///   - En disputa: extrae de forma segura el minuto real ("23′", "45+2′", etc.).
/// - NBA:
///   - En entretiempo (Halftime, HT): retorna "ET".
///   - En disputa: formatea cuarto y minuto de juego ("C1 - 3:20", "C4 - 12:24", "OT - 2:15", etc.).
///
/// Retorna `null` si:
/// - El evento no está en vivo (`!event.isLive`).
/// - No hay datos de tiempo/cuarto disponibles o es otro deporte sin contrato equivalente.
class MatchMinuteFormatter {
  const MatchMinuteFormatter._();

  /// Formatea el minuto real o estado de juego si está disponible y tiene semántica válida.
  static String? format(EventModel event) {
    if (!event.isLive) return null;

    if (event.sport == SportType.soccer) {
      return formatSoccer(event);
    }

    if (event.sport == SportType.nba) {
      return formatNba(event);
    }

    return null;
  }

  /// Formateador específico para eventos de fútbol en vivo.
  static String? formatSoccer(EventModel event) {
    final extra = event.footballStats?.extraStats;

    // 1. Verificar si está en entretiempo (HT / Entretiempo / Descanso)
    for (final raw in [
      event.currentPeriod,
      extra?['statusDetail']?.toString(),
      extra?['clock']?.toString(),
      extra?['period']?.toString(),
    ]) {
      if (isHalftime(raw)) return 'ET';
    }

    // 2. Extraer minuto real transcurrido
    for (final raw in [
      extra?['clock']?.toString(),
      event.currentPeriod,
      extra?['statusDetail']?.toString(),
    ]) {
      final minute = formatRawMinute(raw);
      if (minute != null) return minute;
    }

    return null;
  }

  /// Formateador específico para eventos de NBA / básquetbol en vivo.
  /// Formato: "C{cuarto} - {minuto}:{segundos}" (ej. "C1 - 3:20", "C4 - 12:24", "OT - 2:15").
  static String? formatNba(EventModel event) {
    final nbaStats = event.nbaStats;
    final extra = nbaStats?.extraStats;

    // 1. Verificar si está en entretiempo
    for (final raw in [
      event.currentPeriod,
      extra?['statusDetail']?.toString(),
      extra?['period']?.toString(),
      nbaStats?.quarter?.toString(),
      extra?['clock']?.toString(),
    ]) {
      if (isHalftime(raw)) return 'ET';
    }

    // 2. Resolver cuarto y reloj
    final quarter = _resolveNbaQuarter(
      nbaStats?.quarter?.toString(),
      extra?['quarter']?.toString(),
      extra?['period']?.toString(),
      event.currentPeriod,
    );

    final clock = _resolveNbaClock(
      extra?['clock']?.toString(),
      event.currentPeriod,
      extra?['period']?.toString(),
    );

    if (quarter != null && clock != null) {
      return '$quarter - $clock';
    }
    if (quarter != null) {
      return quarter;
    }
    if (clock != null) {
      return clock;
    }

    return null;
  }

  /// Determina si un valor textual representa entretiempo (halftime / descanso).
  static bool isHalftime(String? raw) {
    if (raw == null) return false;
    final trimmed = raw.trim().toLowerCase();
    if (trimmed.isEmpty) return false;

    return trimmed == 'ht' ||
        trimmed == 'halftime' ||
        trimmed == 'half time' ||
        trimmed == 'half-time' ||
        trimmed == 'entretiempo' ||
        trimmed == 'descanso' ||
        trimmed == 'medio tiempo' ||
        trimmed == 'mediotiempo' ||
        trimmed == 'et';
  }

  /// Extrae el cuarto formateado ("C1", "C2", "C3", "C4", "OT", "OT2", etc.).
  static String? parseQuarter(String? raw) {
    if (raw == null) return null;
    final clean = raw.trim();
    if (clean.isEmpty) return null;
    final lower = clean.toLowerCase();

    // Overtime
    if (lower.contains('ot3') || lower.contains('3ot')) return 'OT3';
    if (lower.contains('ot2') ||
        lower.contains('2ot') ||
        lower.contains('2.ª prórroga') ||
        lower.contains('2da prorroga')) {
      return 'OT2';
    }
    if (lower.contains('ot') ||
        lower.contains('overtime') ||
        lower.contains('prórroga') ||
        lower.contains('prorroga') ||
        lower.contains('1ot') ||
        lower.contains('ot1')) {
      return 'OT';
    }

    // C1..C4 o Q1..Q4 directo
    final cqMatch = RegExp(r'\b[cqCQ]([1-4])\b').firstMatch(clean);
    if (cqMatch != null) {
      return 'C${cqMatch.group(1)}';
    }

    // Ordinal o palabra: "1st", "2nd", "3rd", "4th", "1.er cuarto", "4.° cuarto", etc.
    final ordinalMatch = RegExp(
      r'\b([1-4])(?:st|nd|rd|th|\.?[e°]r|\.?[td]o)?\s*(?:cuarto|quarter|qtr|q|c)?\b',
      caseSensitive: false,
    ).firstMatch(clean);
    if (ordinalMatch != null) {
      return 'C${ordinalMatch.group(1)}';
    }

    // Número entero suelto
    final num = int.tryParse(clean);
    if (num != null) {
      if (num >= 1 && num <= 4) return 'C$num';
      if (num == 5) return 'OT';
      if (num > 5) return 'OT${num - 4}';
    }

    // Búsqueda simple
    if (lower.contains('1st')) return 'C1';
    if (lower.contains('2nd')) return 'C2';
    if (lower.contains('3rd')) return 'C3';
    if (lower.contains('4th')) return 'C4';

    return null;
  }

  /// Extrae y normaliza el reloj de juego ("3:20", "12:24", "4:12", etc.).
  ///
  /// Remueve ceros iniciales en minutos cuando son menores a 10 (ej. "03:20" -> "3:20"),
  /// conservando minutos de dos dígitos ("12:24") o cero ("0:45").
  static String? parseClock(String? raw) {
    if (raw == null) return null;
    final clean = raw.trim();
    if (clean.isEmpty) return null;

    final match = RegExp(
      r'(?:^|[^\d:])(\d{1,2}):(\d{2})(?:\.\d+)?(?:[^\d:]|$)',
    ).firstMatch(clean);
    if (match != null) {
      final minutes = int.tryParse(match.group(1)!);
      final seconds = match.group(2)!;
      if (minutes != null) {
        return '$minutes:$seconds';
      }
    }

    return null;
  }

  static String? _resolveNbaQuarter(
    String? q1,
    String? q2,
    String? period,
    String? currentPeriod,
  ) {
    for (final raw in [q1, q2, period, currentPeriod]) {
      if (raw == null || raw.trim().isEmpty) continue;
      final q = parseQuarter(raw);
      if (q != null) return q;
    }
    return null;
  }

  static String? _resolveNbaClock(
    String? clock,
    String? currentPeriod,
    String? period,
  ) {
    for (final raw in [clock, currentPeriod, period]) {
      if (raw == null || raw.trim().isEmpty) continue;
      final c = parseClock(raw);
      if (c != null) return c;
    }
    return null;
  }

  /// Parsea y formatea un reloj crudo entregado por el proveedor de fútbol.
  ///
  /// Conserva fielmente formatos de tiempo añadido (e.g. "90+3'", "90+3′", "90+3" -> "90+3′")
  /// sin inventar minutos adicionales ni calcular sumas arbitrarias.
  static String? formatRawMinute(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // Rechazar estados que no corresponden a un minuto en disputa (descanso, final, etc.)
    final lower = trimmed.toLowerCase();
    if (lower == 'ht' ||
        lower == 'halftime' ||
        lower == 'descanso' ||
        lower == 'entretiempo' ||
        lower == 'ft' ||
        lower == 'final' ||
        lower == 'finalizado' ||
        lower == 'et' ||
        lower == 'prórroga' ||
        lower == 'prorroga' ||
        lower == 'pen' ||
        lower == 'penales' ||
        lower == 'canc' ||
        lower == 'aplaz' ||
        lower == 'postponed' ||
        lower == 'canceled' ||
        lower == 'suspended') {
      return null;
    }

    // 1. Tiempo añadido (stoppage time): e.g. "90+3'", "90+3′", "90+3", "45+2'", "105+1'"
    final addedTimeMatch =
        RegExp(r"^(\d{1,3})['′]?\s*\+\s*(\d{1,2})['′]?$").firstMatch(trimmed);
    if (addedTimeMatch != null) {
      final base = addedTimeMatch.group(1)!;
      final added = addedTimeMatch.group(2)!;
      return '$base+$added′';
    }

    // 2. Minuto estándar transcurrido: e.g. "23'", "23′", "23", "67'"
    final standardMatch = RegExp(r"^(\d{1,3})['′]?$").firstMatch(trimmed);
    if (standardMatch != null) {
      final minute = int.tryParse(standardMatch.group(1)!);
      if (minute != null && minute >= 1 && minute <= 150) {
        return '$minute′';
      }
    }

    // 3. Minuto con segundos en cero del proveedor: e.g. "23:00" -> "23′"
    final colonMatch = RegExp(r'^(\d{1,3}):00$').firstMatch(trimmed);
    if (colonMatch != null) {
      final minute = int.tryParse(colonMatch.group(1)!);
      if (minute != null && minute >= 1 && minute <= 150) {
        return '$minute′';
      }
    }

    return null;
  }
}
