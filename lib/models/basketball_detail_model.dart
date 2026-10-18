/// Contrato opcional v1 en NbaStats.extraStats.detail.
/// Documentado en docs/basketball-detail-contract.md.
class BasketballDetailModel {
  final int version;
  final String homeParticipantId;
  final String awayParticipantId;
  final List<BasketballPeriodScore> periods;
  final List<BasketballStatistic> statistics;
  final BasketballLeaders? leaders;
  final List<BasketballPlayer>? homePlayers;
  final List<BasketballPlayer>? awayPlayers;
  final List<BasketballPlay>? plays;

  const BasketballDetailModel({
    this.version = 1,
    required this.homeParticipantId,
    required this.awayParticipantId,
    required this.periods,
    required this.statistics,
    this.leaders,
    this.homePlayers,
    this.awayPlayers,
    this.plays,
  });

  static BasketballDetailModel? parse(Object? value) {
    if (value is! Map<String, dynamic> || value['version'] != 1) return null;
    final home = _text(value['homeParticipantId']);
    final away = _text(value['awayParticipantId']);
    if (home == null || away == null || home == away) return null;

    return BasketballDetailModel(
      version: 1,
      homeParticipantId: home,
      awayParticipantId: away,
      periods: _items(value['periods'], BasketballPeriodScore.parse),
      statistics: _items(value['statistics'], BasketballStatistic.parse),
      leaders: BasketballLeaders.parse(value['leaders']),
      homePlayers: value['homePlayers'] is List
          ? _items(value['homePlayers'], BasketballPlayer.parse)
          : null,
      awayPlayers: value['awayPlayers'] is List
          ? _items(value['awayPlayers'], BasketballPlayer.parse)
          : null,
      plays: value['plays'] is List
          ? _items(value['plays'], BasketballPlay.parse)
          : null,
    );
  }
}

class BasketballPeriodScore {
  final String period;
  final int? homeScore;
  final int? awayScore;

  const BasketballPeriodScore({
    required this.period,
    this.homeScore,
    this.awayScore,
  });

  static BasketballPeriodScore? parse(Map<String, dynamic> json) {
    final period = _text(json['period']);
    if (period == null) return null;
    return BasketballPeriodScore(
      period: period,
      homeScore: _scoreInt(json['home']),
      awayScore: _scoreInt(json['away']),
    );
  }
}

class BasketballStatistic {
  final String key;
  final String label;
  final double? home;
  final double? away;
  final bool isPercentage;

  const BasketballStatistic({
    required this.key,
    required this.label,
    this.home,
    this.away,
    this.isPercentage = false,
  });

  static const Map<String, ({String label, bool isPercentage})> _knownKeys = {
    'fieldGoalPct': (label: 'Tiros de campo', isPercentage: true),
    'threePointPct': (label: 'Triples', isPercentage: true),
    'freeThrowPct': (label: 'Tiros libres', isPercentage: true),
    'rebounds': (label: 'Rebotes', isPercentage: false),
    'assists': (label: 'Asistencias', isPercentage: false),
    'turnovers': (label: 'Pérdidas', isPercentage: false),
    'steals': (label: 'Robos', isPercentage: false),
    'blocks': (label: 'Bloqueos', isPercentage: false),
    'pointsInPaint': (label: 'Puntos en la pintura', isPercentage: false),
    'fastBreakPoints': (label: 'Puntos de contragolpe', isPercentage: false),
    'secondChancePoints': (label: 'Puntos 2.ª oportunidad', isPercentage: false),
    'fouls': (label: 'Faltas personales', isPercentage: false),
  };

  static BasketballStatistic? parse(Map<String, dynamic> json) {
    final key = _text(json['key']);
    if (key == null) return null;
    final meta = _knownKeys[key] ??
        (
          label: _text(json['label']) ?? key,
          isPercentage: json['isPercentage'] == true ||
              key.toLowerCase().contains('pct'),
        );

    double? parseNumber(Object? val) {
      if (val == null) return null;
      final num? n = val is num
          ? val
          : num.tryParse(val.toString().replaceAll('%', '').trim());
      if (n == null || !n.isFinite || n < 0) return null;
      return n.toDouble();
    }

    return BasketballStatistic(
      key: key,
      label: meta.label,
      home: parseNumber(json['home']),
      away: parseNumber(json['away']),
      isPercentage: meta.isPercentage,
    );
  }

  String display(double? value) {
    if (value == null) return '—';
    if (isPercentage) {
      final formatted = value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(1);
      return '$formatted%';
    }
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }
}

class BasketballLeaders {
  final BasketballLeaderItem? points;
  final BasketballLeaderItem? rebounds;
  final BasketballLeaderItem? assists;

  const BasketballLeaders({
    this.points,
    this.rebounds,
    this.assists,
  });

  static BasketballLeaders? parse(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    return BasketballLeaders(
      points: BasketballLeaderItem.parse(value['points']),
      rebounds: BasketballLeaderItem.parse(value['rebounds']),
      assists: BasketballLeaderItem.parse(value['assists']),
    );
  }
}

class BasketballLeaderItem {
  final BasketballPlayerLeader? home;
  final BasketballPlayerLeader? away;

  const BasketballLeaderItem({this.home, this.away});

  static BasketballLeaderItem? parse(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    return BasketballLeaderItem(
      home: BasketballPlayerLeader.parse(value['home']),
      away: BasketballPlayerLeader.parse(value['away']),
    );
  }
}

class BasketballPlayerLeader {
  final String name;
  final String? number;
  final String value;

  const BasketballPlayerLeader({
    required this.name,
    this.number,
    required this.value,
  });

  static BasketballPlayerLeader? parse(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final name = _text(value['name']);
    final val = _text(value['value']);
    if (name == null || val == null) return null;
    return BasketballPlayerLeader(
      name: name,
      number: _text(value['number']),
      value: val,
    );
  }
}

class BasketballPlayer {
  final String name;
  final String? number;
  final String? position;
  final bool isStarter;
  final int? points;
  final int? rebounds;
  final int? assists;
  final String? minutes;
  final String? fieldGoals;
  final String? threePointers;
  final String? freeThrows;
  final int? steals;
  final int? blocks;
  final int? turnovers;

  const BasketballPlayer({
    required this.name,
    this.number,
    this.position,
    this.isStarter = false,
    this.points,
    this.rebounds,
    this.assists,
    this.minutes,
    this.fieldGoals,
    this.threePointers,
    this.freeThrows,
    this.steals,
    this.blocks,
    this.turnovers,
  });

  static BasketballPlayer? parse(Map<String, dynamic> json) {
    final name = _text(json['name']);
    if (name == null) return null;
    return BasketballPlayer(
      name: name,
      number: _text(json['number']),
      position: _text(json['position']),
      isStarter: json['isStarter'] == true || json['starter'] == true,
      points: _scoreInt(json['points'] ?? json['pts']),
      rebounds: _scoreInt(json['rebounds'] ?? json['reb']),
      assists: _scoreInt(json['assists'] ?? json['ast']),
      minutes: _text(json['minutes'] ?? json['min']),
      fieldGoals: _text(json['fieldGoals'] ?? json['fg']),
      threePointers: _text(json['threePointers'] ?? json['3pt']),
      freeThrows: _text(json['freeThrows'] ?? json['ft']),
      steals: _scoreInt(json['steals'] ?? json['stl']),
      blocks: _scoreInt(json['blocks'] ?? json['blk']),
      turnovers: _scoreInt(json['turnovers'] ?? json['to']),
    );
  }
}

class BasketballPlay {
  final String? id;
  final String text;
  final String? clock;
  final String? period;
  final int? homeScore;
  final int? awayScore;
  final bool scoringPlay;
  final int? scoreValue;
  final String? side;

  const BasketballPlay({
    this.id,
    required this.text,
    this.clock,
    this.period,
    this.homeScore,
    this.awayScore,
    this.scoringPlay = false,
    this.scoreValue,
    this.side,
  });

  static BasketballPlay? parse(Map<String, dynamic> json) {
    final text = _text(json['text']);
    if (text == null) return null;
    return BasketballPlay(
      id: _text(json['id']),
      text: text,
      clock: _text(json['clock']),
      period: _text(json['period']),
      homeScore: _scoreInt(json['homeScore'] ?? json['home_score']),
      awayScore: _scoreInt(json['awayScore'] ?? json['away_score']),
      scoringPlay: json['scoringPlay'] == true || json['scoring_play'] == true,
      scoreValue: _scoreInt(json['scoreValue'] ?? json['score_value']),
      side: _text(json['side']),
    );
  }
}

String? _text(Object? value) {
  if (value is! String && value is! num) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _scoreInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value >= 0 ? value : null;
  final n = int.tryParse(value.toString().trim());
  return n != null && n >= 0 ? n : null;
}

List<T> _items<T>(Object? value, T? Function(Map<String, dynamic>) parse) {
  if (value is! List) return [];
  return value
      .whereType<Map<String, dynamic>>()
      .map(parse)
      .whereType<T>()
      .toList();
}
