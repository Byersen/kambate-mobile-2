/// Contrato opcional v1 en FootballStats.extraStats.detail.
/// El productor pendiente se documenta en docs/football-detail-contract.md.
class FootballDetailModel {
  final String homeParticipantId;
  final String awayParticipantId;
  final List<FootballStatistic> statistics;
  final List<FootballIncident>? timeline;
  final FootballLineup? homeLineup;
  final FootballLineup? awayLineup;

  const FootballDetailModel({
    required this.homeParticipantId,
    required this.awayParticipantId,
    required this.statistics,
    this.timeline,
    this.homeLineup,
    this.awayLineup,
  });

  static FootballDetailModel? parse(Object? value) {
    if (value is! Map<String, dynamic> || value['version'] != 1) return null;
    final home = _text(value['homeParticipantId']);
    final away = _text(value['awayParticipantId']);
    if (home == null || away == null || home == away) return null;
    return FootballDetailModel(
      homeParticipantId: home,
      awayParticipantId: away,
      statistics: _items(value['statistics'], FootballStatistic.parse),
      timeline: value['timeline'] is List
          ? _items(value['timeline'], FootballIncident.parse)
          : null,
      homeLineup: FootballLineup.parse(value['homeLineup']),
      awayLineup: FootballLineup.parse(value['awayLineup']),
    );
  }
}

class FootballStatistic {
  final String label;
  final double? home;
  final double? away;
  final bool percentage;
  const FootballStatistic(this.label, this.home, this.away, this.percentage);

  static FootballStatistic? parse(Map<String, dynamic> json) {
    const labels = {
      'possession': 'Posesión',
      'shots': 'Tiros totales',
      'shotsOnTarget': 'Tiros al arco',
      'corners': 'Córners',
      'fouls': 'Faltas',
      'yellowCards': 'Tarjetas amarillas',
      'redCards': 'Tarjetas rojas',
      'offsides': 'Fuera de juego',
    };
    final key = json['key'];
    final label = labels[key];
    if (label == null) return null;
    final percentage = key == 'possession';
    double? number(Object? value) {
      final n = double.tryParse(value?.toString() ?? '');
      return n != null && n.isFinite && n >= 0 && (!percentage || n <= 100)
          ? n
          : null;
    }

    return FootballStatistic(
      label,
      number(json['home']),
      number(json['away']),
      percentage,
    );
  }

  String display(double? value) => value == null
      ? '—'
      : '${value == value.roundToDouble() ? value.toInt() : value}${percentage ? '%' : ''}';
}

class FootballIncident {
  final String kind;
  final String side;
  final String? minute;
  final String? player;
  final String? secondaryPlayer;
  const FootballIncident(
    this.kind,
    this.side,
    this.minute,
    this.player,
    this.secondaryPlayer,
  );

  static FootballIncident? parse(Map<String, dynamic> json) {
    final kind = json['kind'];
    final side = json['side'];
    if (!['goal', 'yellowCard', 'redCard', 'substitution'].contains(kind) ||
        !['home', 'away'].contains(side)) {
      return null;
    }
    return FootballIncident(
      kind as String,
      side as String,
      _text(json['minute']),
      _text(json['player']),
      _text(json['secondaryPlayer']),
    );
  }
}

class FootballLineup {
  final String? formation;
  final List<FootballPlayer>? starters;
  final List<FootballPlayer>? substitutes;
  const FootballLineup(this.formation, this.starters, this.substitutes);

  static FootballLineup? parse(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    return FootballLineup(
      _text(value['formation']),
      value['starters'] is List
          ? _items(value['starters'], FootballPlayer.parse)
          : null,
      value['substitutes'] is List
          ? _items(value['substitutes'], FootballPlayer.parse)
          : null,
    );
  }
}

class FootballPlayer {
  final String name;
  final String? number;
  final String? position;
  const FootballPlayer(this.name, this.number, this.position);
  static FootballPlayer? parse(Map<String, dynamic> json) {
    final name = _text(json['name']);
    return name == null
        ? null
        : FootballPlayer(name, _text(json['number']), _text(json['position']));
  }
}

String? _text(Object? value) {
  if (value is! String && value is! num) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

List<T> _items<T>(Object? value, T? Function(Map<String, dynamic>) parse) {
  if (value is! List) return [];
  return value
      .whereType<Map<String, dynamic>>()
      .map(parse)
      .whereType<T>()
      .toList();
}
