/// Formateador de nombres de equipos de la NBA a sus sobrenombres / nicknames oficiales.
///
/// Convierte nombres completos (ej. "Milwaukee Bucks", "Miami Heat", "Chicago Bulls",
/// "Los Angeles Lakers") en sus versiones compactas ("Bucks", "Heat", "Bulls", "Lakers").
class NbaTeamFormatter {
  const NbaTeamFormatter._();

  static const Map<String, String> _nicknamesByNormalizedName = {
    // Atlanta Hawks
    'atlanta hawks': 'Hawks',
    'atl hawks': 'Hawks',
    'hawks': 'Hawks',

    // Boston Celtics
    'boston celtics': 'Celtics',
    'bos celtics': 'Celtics',
    'celtics': 'Celtics',

    // Brooklyn Nets
    'brooklyn nets': 'Nets',
    'bkn nets': 'Nets',
    'nets': 'Nets',

    // Charlotte Hornets
    'charlotte hornets': 'Hornets',
    'cha hornets': 'Hornets',
    'hornets': 'Hornets',

    // Chicago Bulls
    'chicago bulls': 'Bulls',
    'chi bulls': 'Bulls',
    'bulls': 'Bulls',

    // Cleveland Cavaliers
    'cleveland cavaliers': 'Cavaliers',
    'cle cavaliers': 'Cavaliers',
    'cavaliers': 'Cavaliers',
    'cavs': 'Cavaliers',

    // Dallas Mavericks
    'dallas mavericks': 'Mavericks',
    'dal mavericks': 'Mavericks',
    'mavericks': 'Mavericks',
    'mavs': 'Mavericks',

    // Denver Nuggets
    'denver nuggets': 'Nuggets',
    'den nuggets': 'Nuggets',
    'nuggets': 'Nuggets',

    // Detroit Pistons
    'detroit pistons': 'Pistons',
    'det pistons': 'Pistons',
    'pistons': 'Pistons',

    // Golden State Warriors
    'golden state warriors': 'Warriors',
    'gs warriors': 'Warriors',
    'gsw warriors': 'Warriors',
    'warriors': 'Warriors',

    // Houston Rockets
    'houston rockets': 'Rockets',
    'hou rockets': 'Rockets',
    'rockets': 'Rockets',

    // Indiana Pacers
    'indiana pacers': 'Pacers',
    'ind pacers': 'Pacers',
    'pacers': 'Pacers',

    // Los Angeles Clippers
    'los angeles clippers': 'Clippers',
    'la clippers': 'Clippers',
    'lac clippers': 'Clippers',
    'clippers': 'Clippers',

    // Los Angeles Lakers
    'los angeles lakers': 'Lakers',
    'la lakers': 'Lakers',
    'lal lakers': 'Lakers',
    'lakers': 'Lakers',

    // Memphis Grizzlies
    'memphis grizzlies': 'Grizzlies',
    'mem grizzlies': 'Grizzlies',
    'grizzlies': 'Grizzlies',

    // Miami Heat
    'miami heat': 'Heat',
    'miami heats': 'Heat',
    'mia heat': 'Heat',
    'heat': 'Heat',
    'heats': 'Heat',

    // Milwaukee Bucks
    'milwaukee bucks': 'Bucks',
    'mil bucks': 'Bucks',
    'bucks': 'Bucks',

    // Minnesota Timberwolves
    'minnesota timberwolves': 'Timberwolves',
    'min timberwolves': 'Timberwolves',
    'timberwolves': 'Timberwolves',
    'wolves': 'Timberwolves',

    // New Orleans Pelicans
    'new orleans pelicans': 'Pelicans',
    'nop pelicans': 'Pelicans',
    'pelicans': 'Pelicans',

    // New York Knicks
    'new york knicks': 'Knicks',
    'nyk knicks': 'Knicks',
    'knicks': 'Knicks',

    // Oklahoma City Thunder
    'oklahoma city thunder': 'Thunder',
    'okc thunder': 'Thunder',
    'thunder': 'Thunder',

    // Orlando Magic
    'orlando magic': 'Magic',
    'orl magic': 'Magic',
    'magic': 'Magic',

    // Philadelphia 76ers
    'philadelphia 76ers': '76ers',
    'phi 76ers': '76ers',
    'philly 76ers': '76ers',
    '76ers': '76ers',
    'sixers': '76ers',

    // Phoenix Suns
    'phoenix suns': 'Suns',
    'phx suns': 'Suns',
    'suns': 'Suns',

    // Portland Trail Blazers
    'portland trail blazers': 'Trail Blazers',
    'por trail blazers': 'Trail Blazers',
    'trail blazers': 'Trail Blazers',
    'blazers': 'Trail Blazers',

    // Sacramento Kings
    'sacramento kings': 'Kings',
    'sac kings': 'Kings',
    'kings': 'Kings',

    // San Antonio Spurs
    'san antonio spurs': 'Spurs',
    'sas spurs': 'Spurs',
    'spurs': 'Spurs',

    // Toronto Raptors
    'toronto raptors': 'Raptors',
    'tor raptors': 'Raptors',
    'raptors': 'Raptors',

    // Utah Jazz
    'utah jazz': 'Jazz',
    'uta jazz': 'Jazz',
    'jazz': 'Jazz',

    // Washington Wizards
    'washington wizards': 'Wizards',
    'was wizards': 'Wizards',
    'wizards': 'Wizards',
  };

  /// Retorna el sobrenombre / nickname del equipo si es reconocido como franquicia de la NBA.
  /// En caso contrario, retorna el nombre recibido sin alterarlo.
  static String format(String? rawName) {
    if (rawName == null) return '';
    final trimmed = rawName.trim();
    if (trimmed.isEmpty) return trimmed;

    final normalized = trimmed.toLowerCase();

    // 1. Coincidencia exacta
    final exact = _nicknamesByNormalizedName[normalized];
    if (exact != null) return exact;

    // 2. Coincidencia por subcadena / sufijo de franquicia
    for (final entry in _nicknamesByNormalizedName.entries) {
      if (normalized.endsWith(entry.key) || normalized.contains(entry.key)) {
        return entry.value;
      }
    }

    return trimmed;
  }
}

