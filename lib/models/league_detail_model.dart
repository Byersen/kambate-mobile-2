class LeagueStandingEntryModel {
  final int position;
  final String? teamId;
  final String? participantId;
  final String teamName;
  final String? teamLogo;
  final int playedGames;
  final int points;
  final int? won;
  final int? drawn;
  final int? lost;
  final int? goalsFor;
  final int? goalsAgainst;
  final int? goalDifference;
  final String? note;
  final bool isPromotion;

  const LeagueStandingEntryModel({
    required this.position,
    this.teamId,
    this.participantId,
    required this.teamName,
    this.teamLogo,
    required this.playedGames,
    required this.points,
    this.won,
    this.drawn,
    this.lost,
    this.goalsFor,
    this.goalsAgainst,
    this.goalDifference,
    this.note,
    this.isPromotion = false,
  });

  factory LeagueStandingEntryModel.fromJson(Map<String, dynamic> json) {
    return LeagueStandingEntryModel(
      position: json['position'] is int
          ? json['position'] as int
          : int.tryParse(json['position']?.toString() ?? '1') ?? 1,
      teamId: json['teamId']?.toString(),
      participantId: json['participantId']?.toString(),
      teamName: json['teamName']?.toString() ?? 'Equipo',
      teamLogo: json['teamLogo']?.toString(),
      playedGames: json['playedGames'] is int
          ? json['playedGames'] as int
          : int.tryParse(json['playedGames']?.toString() ?? '0') ?? 0,
      points: json['points'] is int
          ? json['points'] as int
          : int.tryParse(json['points']?.toString() ?? '0') ?? 0,
      won: json['won'] is int
          ? json['won'] as int
          : int.tryParse(json['won']?.toString() ?? ''),
      drawn: json['drawn'] is int
          ? json['drawn'] as int
          : int.tryParse(json['drawn']?.toString() ?? ''),
      lost: json['lost'] is int
          ? json['lost'] as int
          : int.tryParse(json['lost']?.toString() ?? ''),
      goalsFor: json['goalsFor'] is int
          ? json['goalsFor'] as int
          : int.tryParse(json['goalsFor']?.toString() ?? ''),
      goalsAgainst: json['goalsAgainst'] is int
          ? json['goalsAgainst'] as int
          : int.tryParse(json['goalsAgainst']?.toString() ?? ''),
      goalDifference: json['goalDifference'] is int
          ? json['goalDifference'] as int
          : int.tryParse(json['goalDifference']?.toString() ?? ''),
      note: json['note']?.toString(),
      isPromotion: json['isPromotion'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      if (teamId != null) 'teamId': teamId,
      if (participantId != null) 'participantId': participantId,
      'teamName': teamName,
      if (teamLogo != null) 'teamLogo': teamLogo,
      'playedGames': playedGames,
      'points': points,
      if (won != null) 'won': won,
      if (drawn != null) 'drawn': drawn,
      if (lost != null) 'lost': lost,
      if (goalsFor != null) 'goalsFor': goalsFor,
      if (goalsAgainst != null) 'goalsAgainst': goalsAgainst,
      if (goalDifference != null) 'goalDifference': goalDifference,
      if (note != null) 'note': note,
      'isPromotion': isPromotion,
    };
  }
}

class LeagueStandingGroupModel {
  final String name;
  final List<LeagueStandingEntryModel> entries;

  const LeagueStandingGroupModel({
    required this.name,
    required this.entries,
  });

  factory LeagueStandingGroupModel.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'] as List<dynamic>? ?? [];
    return LeagueStandingGroupModel(
      name: json['name']?.toString() ?? 'General',
      entries: rawEntries
          .whereType<Map<String, dynamic>>()
          .map(LeagueStandingEntryModel.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'entries': entries.map((e) => e.toJson()).toList(),
    };
  }
}

class LeagueScorerModel {
  final int rank;
  final String? athleteId;
  final String playerName;
  final String? playerPhoto;
  final String? teamId;
  final String teamName;
  final String? teamLogo;
  final String? participantId;
  final int goals;
  final int? playedGames;
  final int? assists;

  const LeagueScorerModel({
    required this.rank,
    this.athleteId,
    required this.playerName,
    this.playerPhoto,
    this.teamId,
    required this.teamName,
    this.teamLogo,
    this.participantId,
    required this.goals,
    this.playedGames,
    this.assists,
  });

  factory LeagueScorerModel.fromJson(Map<String, dynamic> json) {
    return LeagueScorerModel(
      rank: json['rank'] is int
          ? json['rank'] as int
          : int.tryParse(json['rank']?.toString() ?? '1') ?? 1,
      athleteId: json['athleteId']?.toString(),
      playerName: json['playerName']?.toString() ?? 'Jugador',
      playerPhoto: json['playerPhoto']?.toString(),
      teamId: json['teamId']?.toString(),
      teamName: json['teamName']?.toString() ?? '',
      teamLogo: json['teamLogo']?.toString(),
      participantId: json['participantId']?.toString(),
      goals: json['goals'] is int
          ? json['goals'] as int
          : int.tryParse(json['goals']?.toString() ?? '0') ?? 0,
      playedGames: json['playedGames'] is int
          ? json['playedGames'] as int
          : int.tryParse(json['playedGames']?.toString() ?? ''),
      assists: json['assists'] is int
          ? json['assists'] as int
          : int.tryParse(json['assists']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      if (athleteId != null) 'athleteId': athleteId,
      'playerName': playerName,
      if (playerPhoto != null) 'playerPhoto': playerPhoto,
      if (teamId != null) 'teamId': teamId,
      'teamName': teamName,
      if (teamLogo != null) 'teamLogo': teamLogo,
      if (participantId != null) 'participantId': participantId,
      'goals': goals,
      if (playedGames != null) 'playedGames': playedGames,
      if (assists != null) 'assists': assists,
    };
  }
}

class LeagueDetailModel {
  final int version;
  final String? leagueId;
  final String leagueSlug;
  final String leagueName;
  final String? seasonId;
  final String? seasonSlug;
  final String? seasonName;
  final bool hasStandingsCoverage;
  final bool hasLeadersCoverage;
  final List<LeagueStandingGroupModel> groups;
  final List<LeagueScorerModel> topScorers;

  const LeagueDetailModel({
    this.version = 1,
    this.leagueId,
    required this.leagueSlug,
    required this.leagueName,
    this.seasonId,
    this.seasonSlug,
    this.seasonName,
    required this.hasStandingsCoverage,
    required this.hasLeadersCoverage,
    this.groups = const [],
    this.topScorers = const [],
  });

  bool get isEmpty =>
      (!hasStandingsCoverage || groups.isEmpty) &&
      (!hasLeadersCoverage || topScorers.isEmpty);

  factory LeagueDetailModel.empty({
    required String leagueSlug,
    required String leagueName,
    String? leagueId,
    String? seasonId,
    String? seasonSlug,
    String? seasonName,
  }) {
    return LeagueDetailModel(
      version: 1,
      leagueId: leagueId,
      leagueSlug: leagueSlug,
      leagueName: leagueName,
      seasonId: seasonId,
      seasonSlug: seasonSlug,
      seasonName: seasonName,
      hasStandingsCoverage: false,
      hasLeadersCoverage: false,
      groups: const [],
      topScorers: const [],
    );
  }

  factory LeagueDetailModel.fromJson(Map<String, dynamic> json) {
    final rawGroups = json['groups'] as List<dynamic>? ?? [];
    final rawScorers = json['topScorers'] as List<dynamic>? ?? [];

    return LeagueDetailModel(
      version: json['version'] is int ? json['version'] as int : 1,
      leagueId: json['leagueId']?.toString(),
      leagueSlug: json['leagueSlug']?.toString() ?? '',
      leagueName: json['leagueName']?.toString() ?? '',
      seasonId: json['seasonId']?.toString(),
      seasonSlug: json['seasonSlug']?.toString(),
      seasonName: json['seasonName']?.toString(),
      hasStandingsCoverage: json['hasStandingsCoverage'] == true,
      hasLeadersCoverage: json['hasLeadersCoverage'] == true,
      groups: rawGroups
          .whereType<Map<String, dynamic>>()
          .map(LeagueStandingGroupModel.fromJson)
          .toList(),
      topScorers: rawScorers
          .whereType<Map<String, dynamic>>()
          .map(LeagueScorerModel.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      if (leagueId != null) 'leagueId': leagueId,
      'leagueSlug': leagueSlug,
      'leagueName': leagueName,
      if (seasonId != null) 'seasonId': seasonId,
      if (seasonSlug != null) 'seasonSlug': seasonSlug,
      if (seasonName != null) 'seasonName': seasonName,
      'hasStandingsCoverage': hasStandingsCoverage,
      'hasLeadersCoverage': hasLeadersCoverage,
      'groups': groups.map((g) => g.toJson()).toList(),
      'topScorers': topScorers.map((s) => s.toJson()).toList(),
    };
  }
}
