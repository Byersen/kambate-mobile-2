/// Traduce y normaliza la ronda / fase de un partido para mostrarla en el
/// detalle (ej. "Fecha 12", "Fase de grupos", "Cuartos de final", "Semifinal").
///
/// Acepta valores en inglés provenientes del proveedor ("Regular Season - 12",
/// "Group Stage", "Quarter-finals", "Round of 16") y valores ya en español.
/// Si no reconoce el formato, devuelve el texto original sin alterarlo.
class MatchRoundFormatter {
  const MatchRoundFormatter._();

  static String? format(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final lower = trimmed.toLowerCase();

    // Número suelto → fecha / jornada ("12" → "Fecha 12").
    if (RegExp(r'^\d{1,3}$').hasMatch(lower)) return 'Fecha $trimmed';

    // Fecha / jornada numerada: "Regular Season - 12", "Matchday 12",
    // "Round 12", "Jornada 12", "Fecha 12", "Week 3".
    final numbered = RegExp(
      r'^(?:regular season|matchday|match day|round|jornada|fecha|week|semana)\s*[-–:]?\s*(\d{1,3})$',
    ).firstMatch(lower);
    if (numbered != null) return 'Fecha ${numbered.group(1)}';

    // Fases eliminatorias y de grupos.
    if (lower.contains('round of 32') || lower.contains('dieciseisavos')) {
      return 'Dieciseisavos de final';
    }
    if (lower.contains('round of 16') ||
        lower.contains('octavos') ||
        lower.contains('eighth')) {
      return 'Octavos de final';
    }
    if (lower.contains('quarter') || lower.contains('cuartos')) {
      return 'Cuartos de final';
    }
    if (lower.contains('semi')) return 'Semifinal';
    if (lower.contains('3rd place') ||
        lower.contains('third place') ||
        lower.contains('tercer puesto')) {
      return 'Tercer puesto';
    }
    if (lower == 'final' || lower == 'finals' || lower == 'the final') {
      return 'Final';
    }

    final group = RegExp(r'^group\s+([a-z])$').firstMatch(lower);
    if (group != null) return 'Grupo ${group.group(1)!.toUpperCase()}';
    if (lower.contains('group stage') || lower.contains('group phase')) {
      return 'Fase de grupos';
    }
    if (lower.contains('league phase') ||
        lower.contains('league stage') ||
        lower == 'fase de liga') {
      return 'Fase de liga';
    }
    if (lower.contains('knockout round play') ||
        lower.contains('play-off') ||
        lower.contains('playoff')) {
      return 'Playoffs';
    }
    if (lower == 'regular season') return 'Temporada regular';
    if (lower.contains('preseason') || lower.contains('pre-season')) {
      return 'Pretemporada';
    }

    return trimmed;
  }
}

