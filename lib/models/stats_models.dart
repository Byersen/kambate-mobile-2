class FootballStatsModel {
  final String id;
  final String? eventId;
  final int? homeGoals;
  final int? awayGoals;
  final int? homeCards;
  final int? awayCards;
  final Map<String, dynamic>? extraStats;

  const FootballStatsModel({
    required this.id,
    this.eventId,
    this.homeGoals,
    this.awayGoals,
    this.homeCards,
    this.awayCards,
    this.extraStats,
  });

  factory FootballStatsModel.fromJson(Map<String, dynamic> json) {
    return FootballStatsModel(
      id: json['id']?.toString() ?? '',
      eventId: json['event_id']?.toString() ?? json['eventId']?.toString(),
      homeGoals: json['home_goals'] is int
          ? json['home_goals'] as int
          : (json['homeGoals'] is int
                ? json['homeGoals'] as int
                : int.tryParse(
                    json['home_goals']?.toString() ??
                        json['homeGoals']?.toString() ??
                        '',
                  )),
      awayGoals: json['away_goals'] is int
          ? json['away_goals'] as int
          : (json['awayGoals'] is int
                ? json['awayGoals'] as int
                : int.tryParse(
                    json['away_goals']?.toString() ??
                        json['awayGoals']?.toString() ??
                        '',
                  )),
      homeCards: json['home_cards'] is int
          ? json['home_cards'] as int
          : (json['homeCards'] is int
                ? json['homeCards'] as int
                : int.tryParse(
                    json['home_cards']?.toString() ??
                        json['homeCards']?.toString() ??
                        '',
                  )),
      awayCards: json['away_cards'] is int
          ? json['away_cards'] as int
          : (json['awayCards'] is int
                ? json['awayCards'] as int
                : int.tryParse(
                    json['away_cards']?.toString() ??
                        json['awayCards']?.toString() ??
                        '',
                  )),
      extraStats: json['extra_stats'] is Map<String, dynamic>
          ? json['extra_stats'] as Map<String, dynamic>
          : (json['extraStats'] is Map<String, dynamic>
                ? json['extraStats'] as Map<String, dynamic>
                : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'home_goals': homeGoals,
      'away_goals': awayGoals,
      'home_cards': homeCards,
      'away_cards': awayCards,
      'extra_stats': extraStats,
    };
  }
}

class NbaStatsModel {
  final String id;
  final String? eventId;
  final int? homePoints;
  final int? awayPoints;
  final String? quarter;
  final Map<String, dynamic>? extraStats;

  const NbaStatsModel({
    required this.id,
    this.eventId,
    this.homePoints,
    this.awayPoints,
    this.quarter,
    this.extraStats,
  });

  factory NbaStatsModel.fromJson(Map<String, dynamic> json) {
    int? parsePoints(Object? val) {
      if (val == null) return null;
      if (val is int) return val;
      return int.tryParse(val.toString().trim());
    }

    return NbaStatsModel(
      id: json['id']?.toString() ?? '',
      eventId: json['event_id']?.toString() ?? json['eventId']?.toString(),
      homePoints: parsePoints(json['home_points'] ?? json['homePoints']),
      awayPoints: parsePoints(json['away_points'] ?? json['awayPoints']),
      quarter: json['quarter']?.toString(),
      extraStats: json['extra_stats'] is Map<String, dynamic>
          ? json['extra_stats'] as Map<String, dynamic>
          : (json['extraStats'] is Map<String, dynamic>
                ? json['extraStats'] as Map<String, dynamic>
                : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'home_points': homePoints,
      'away_points': awayPoints,
      'quarter': quarter,
      'extra_stats': extraStats,
    };
  }
}

class UfcStatsModel {
  final String id;
  final String? eventId;
  final String? method;
  final int? round;
  final String? time;
  final String? winnerName;
  final Map<String, dynamic>? extraStats;

  const UfcStatsModel({
    required this.id,
    this.eventId,
    this.method,
    this.round,
    this.time,
    this.winnerName,
    this.extraStats,
  });

  String? get winMethod => method;

  factory UfcStatsModel.fromJson(Map<String, dynamic> json) {
    return UfcStatsModel(
      id: json['id']?.toString() ?? '',
      eventId: json['event_id']?.toString() ?? json['eventId']?.toString(),
      method:
          json['method']?.toString() ??
          json['win_method']?.toString() ??
          json['winMethod']?.toString(),
      round: json['round'] is int
          ? json['round'] as int
          : int.tryParse(json['round']?.toString() ?? ''),
      time: json['time']?.toString(),
      winnerName:
          json['winner_name']?.toString() ?? json['winnerName']?.toString(),
      extraStats: json['extra_stats'] is Map<String, dynamic>
          ? json['extra_stats'] as Map<String, dynamic>
          : (json['extraStats'] is Map<String, dynamic>
                ? json['extraStats'] as Map<String, dynamic>
                : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'method': method,
      'round': round,
      'time': time,
      'winner_name': winnerName,
      'extra_stats': extraStats,
    };
  }
}

class EsportsStatsModel {
  final String id;
  final String? eventId;
  final int? homeScore;
  final int? awayScore;
  final String? format;
  final String? map;
  final Map<String, dynamic>? extraStats;

  const EsportsStatsModel({
    required this.id,
    this.eventId,
    this.homeScore,
    this.awayScore,
    this.format,
    this.map,
    this.extraStats,
  });

  int? get homeMapScore => homeScore;
  int? get awayMapScore => awayScore;
  String? get currentMap => map;

  factory EsportsStatsModel.fromJson(Map<String, dynamic> json) {
    int? parseScore(Object? s1, Object? s2, Object? s3) {
      if (s1 is int) return s1;
      if (s2 is int) return s2;
      if (s3 is int) return s3;
      final raw = s1 ?? s2 ?? s3;
      if (raw == null) return null;
      return int.tryParse(raw.toString().trim());
    }

    return EsportsStatsModel(
      id: json['id']?.toString() ?? '',
      eventId: json['event_id']?.toString() ?? json['eventId']?.toString(),
      homeScore: parseScore(
        json['home_score'],
        json['homeScore'],
        json['home_map_score'],
      ),
      awayScore: parseScore(
        json['away_score'],
        json['awayScore'],
        json['away_map_score'],
      ),
      format: json['format']?.toString(),
      map:
          json['map']?.toString() ??
          json['current_map']?.toString() ??
          json['currentMap']?.toString(),
      extraStats: json['extra_stats'] is Map<String, dynamic>
          ? json['extra_stats'] as Map<String, dynamic>
          : (json['extraStats'] is Map<String, dynamic>
                ? json['extraStats'] as Map<String, dynamic>
                : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'home_score': homeScore,
      'away_score': awayScore,
      'format': format,
      'map': map,
      'extra_stats': extraStats,
    };
  }
}
