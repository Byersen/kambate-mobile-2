import '../../models/event_model.dart';
import '../../models/sport_type.dart';

/// Formateador reutilizable del minuto transcurrido para eventos deportivos en vivo.
///
/// Diseñado para extraer de forma segura y consistente el minuto real del partido
/// proporcionado por los proveedores (ESPN, etc.) sin calcularlo a partir de la
/// fecha/hora de inicio, ni alterar semánticas de otros deportes.
class MatchMinuteFormatter {
  const MatchMinuteFormatter._();

  /// Formatea el minuto real de juego si está disponible y tiene semántica válida.
  ///
  /// Retorna una cadena con el minuto formateado, e.g. "23′", "67′", "90+3′" (usando el símbolo de prima ′).
  ///
  /// Retorna `null` si:
  /// - El evento no está en vivo (`!event.isLive`).
  /// - El deporte no proporciona un minuto transcurrido de partido equivalente (e.g. NBA tiene cuenta regresiva
  ///   por cuarto, UFC tiene reloj por asalto, Esports tiene tiempos de partida/rondas).
  /// - El proveedor no entrega un minuto que pueda interpretarse con seguridad (e.g. "HT", "Entretiempo", etc.).
  static String? format(EventModel event) {
    if (!event.isLive) return null;

    // Solo fútbol expone actualmente un contrato con minuto transcurrido de partido.
    // Otros deportes (NBA, UFC, LoL, Valorant) manejan relojes de cuarto/asalto o índices de ronda.
    if (event.sport != SportType.soccer) {
      return null;
    }

    final raw = event.currentPeriod ??
        event.footballStats?.extraStats?['clock']?.toString();

    return formatRawMinute(raw);
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
        RegExp(r"^(\d{1,3})\s*\+\s*(\d{1,2})['′]?$").firstMatch(trimmed);
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
