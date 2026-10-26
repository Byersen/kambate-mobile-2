/// Modelo de dominio y contrato versionado para Worlds de League of Legends y su etapa activa (e.g. Etapa Suiza).
/// Alineado con LolWorldsStageContract v1 del backend.
library;

class LolWorldsCompetitionModel {
  final String? id;
  final String slug;
  final String name;
  final String sport;

  const LolWorldsCompetitionModel({
    this.id,
    required this.slug,
    required this.name,
    this.sport = 'lol',
  });

  factory LolWorldsCompetitionModel.fromJson(Map<String, dynamic> json) {
    return LolWorldsCompetitionModel(
      id: json['id']?.toString(),
      slug: json['slug']?.toString() ?? 'worlds',
      name: json['name']?.toString() ?? 'League of Legends World Championship',
      sport: json['sport']?.toString() ?? 'lol',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'slug': slug,
      'name': name,
      'sport': sport,
    };
  }
}

class LolWorldsSeasonModel {
  final String? id;
  final String slug;
  final String name;
  final int? year;
  final bool isCurrent;

  const LolWorldsSeasonModel({
    this.id,
    required this.slug,
    required this.name,
    this.year,
    this.isCurrent = true,
  });

  factory LolWorldsSeasonModel.fromJson(Map<String, dynamic> json) {
    return LolWorldsSeasonModel(
      id: json['id']?.toString(),
      slug: json['slug']?.toString() ?? 'current',
      name: json['name']?.toString() ?? 'Worlds',
      year: json['year'] is int
          ? json['year'] as int
          : int.tryParse(json['year']?.toString() ?? ''),
      isCurrent: json['isCurrent'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'slug': slug,
      'name': name,
      if (year != null) 'year': year,
      'isCurrent': isCurrent,
    };
  }
}

class LolWorldsStageInfoModel {
  final String id;
  final String slug;
  final String name;
  final String format;
  final String status;
  final int? currentRoundNumber;
  final int? totalRounds;

  const LolWorldsStageInfoModel({
    required this.id,
    required this.slug,
    required this.name,
    required this.format,
    required this.status,
    this.currentRoundNumber,
    this.totalRounds,
  });

  bool get isSwiss => format.toLowerCase() == 'swiss';

  factory LolWorldsStageInfoModel.fromJson(Map<String, dynamic> json) {
    return LolWorldsStageInfoModel(
      id: json['id']?.toString() ?? 'stage-current',
      slug: json['slug']?.toString() ?? 'stage-current',
      name: json['name']?.toString() ?? 'Etapa Actual',
      format: json['format']?.toString() ?? 'swiss',
      status: json['status']?.toString() ?? 'in_progress',
      currentRoundNumber: json['currentRoundNumber'] is int
          ? json['currentRoundNumber'] as int
          : int.tryParse(json['currentRoundNumber']?.toString() ?? ''),
      totalRounds: json['totalRounds'] is int
          ? json['totalRounds'] as int
          : int.tryParse(json['totalRounds']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'name': name,
      'format': format,
      'status': status,
      if (currentRoundNumber != null) 'currentRoundNumber': currentRoundNumber,
      if (totalRounds != null) 'totalRounds': totalRounds,
    };
  }
}

class LolWorldsRoundModel {
  final int roundNumber;
  final String name;
  final String status;
  final List<String> matchIds;

  const LolWorldsRoundModel({
    required this.roundNumber,
    required this.name,
    required this.status,
    this.matchIds = const [],
  });

  factory LolWorldsRoundModel.fromJson(Map<String, dynamic> json) {
    final rawMatchIds = json['matchIds'] as List<dynamic>? ?? [];
    return LolWorldsRoundModel(
      roundNumber: json['roundNumber'] is int
          ? json['roundNumber'] as int
          : int.tryParse(json['roundNumber']?.toString() ?? '1') ?? 1,
      name: json['name']?.toString() ?? 'Ronda',
      status: json['status']?.toString() ?? 'in_progress',
      matchIds: rawMatchIds.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roundNumber': roundNumber,
      'name': name,
      'status': status,
      'matchIds': matchIds,
    };
  }
}

class LolWorldsParticipantModel {
  final String? id;
  final String name;
  final String? code;
  final String? logoUrl;
  final int? score;
  final String? record;

  const LolWorldsParticipantModel({
    this.id,
    required this.name,
    this.code,
    this.logoUrl,
    this.score,
    this.record,
  });

  factory LolWorldsParticipantModel.fromJson(Map<String, dynamic> json) {
    return LolWorldsParticipantModel(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? 'Equipo',
      code: json['code']?.toString(),
      logoUrl: json['logoUrl']?.toString(),
      score: json['score'] is int
          ? json['score'] as int
          : int.tryParse(json['score']?.toString() ?? ''),
      record: json['record']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (code != null) 'code': code,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (score != null) 'score': score,
      if (record != null) 'record': record,
    };
  }
}

class LolWorldsMatchModel {
  final String id;
  final String? externalId;
  final int? roundNumber;
  final String? roundName;
  final DateTime startTime;
  final String status;
  final LolWorldsParticipantModel homeTeam;
  final LolWorldsParticipantModel awayTeam;
  final String? format;
  final String? winnerTeamId;

  const LolWorldsMatchModel({
    required this.id,
    this.externalId,
    this.roundNumber,
    this.roundName,
    required this.startTime,
    required this.status,
    required this.homeTeam,
    required this.awayTeam,
    this.format,
    this.winnerTeamId,
  });

  bool get isFinished => status.toUpperCase() == 'FINISHED';
  bool get isLive => status.toUpperCase() == 'LIVE';
  bool get isScheduled => status.toUpperCase() == 'SCHEDULED';

  factory LolWorldsMatchModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      final dateStr = json['startTime']?.toString() ?? '';
      parsedDate = DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return LolWorldsMatchModel(
      id: json['id']?.toString() ?? 'match-id',
      externalId: json['externalId']?.toString(),
      roundNumber: json['roundNumber'] is int
          ? json['roundNumber'] as int
          : int.tryParse(json['roundNumber']?.toString() ?? ''),
      roundName: json['roundName']?.toString(),
      startTime: parsedDate,
      status: json['status']?.toString() ?? 'SCHEDULED',
      homeTeam: LolWorldsParticipantModel.fromJson(
        json['homeTeam'] is Map<String, dynamic>
            ? json['homeTeam'] as Map<String, dynamic>
            : {},
      ),
      awayTeam: LolWorldsParticipantModel.fromJson(
        json['awayTeam'] is Map<String, dynamic>
            ? json['awayTeam'] as Map<String, dynamic>
            : {},
      ),
      format: json['format']?.toString() ?? 'Bo1',
      winnerTeamId: json['winnerTeamId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (externalId != null) 'externalId': externalId,
      if (roundNumber != null) 'roundNumber': roundNumber,
      if (roundName != null) 'roundName': roundName,
      'startTime': startTime.toIso8601String(),
      'status': status,
      'homeTeam': homeTeam.toJson(),
      'awayTeam': awayTeam.toJson(),
      if (format != null) 'format': format,
      if (winnerTeamId != null) 'winnerTeamId': winnerTeamId,
    };
  }
}

class LolSwissStandingEntryModel {
  final int position;
  final String? teamId;
  final String teamName;
  final String? teamCode;
  final String? teamLogo;
  final int wins;
  final int losses;
  final int? diff;
  final int? gamesWon;
  final int? gamesLost;
  final int? buchholz;
  final String? advancementStatus;
  final String? advancementText;

  const LolSwissStandingEntryModel({
    required this.position,
    this.teamId,
    required this.teamName,
    this.teamCode,
    this.teamLogo,
    required this.wins,
    required this.losses,
    this.diff,
    this.gamesWon,
    this.gamesLost,
    this.buchholz,
    this.advancementStatus,
    this.advancementText,
  });

  bool get isQualified => advancementStatus == 'QUALIFIED';
  bool get isEliminated => advancementStatus == 'ELIMINATED';
  bool get isInContention => advancementStatus == 'IN_CONTENTION';

  String get record => '$wins-$losses';

  factory LolSwissStandingEntryModel.fromJson(Map<String, dynamic> json) {
    return LolSwissStandingEntryModel(
      position: json['position'] is int
          ? json['position'] as int
          : int.tryParse(json['position']?.toString() ?? '1') ?? 1,
      teamId: json['teamId']?.toString(),
      teamName: json['teamName']?.toString() ?? 'Equipo',
      teamCode: json['teamCode']?.toString(),
      teamLogo: json['teamLogo']?.toString(),
      wins: json['wins'] is int
          ? json['wins'] as int
          : int.tryParse(json['wins']?.toString() ?? '0') ?? 0,
      losses: json['losses'] is int
          ? json['losses'] as int
          : int.tryParse(json['losses']?.toString() ?? '0') ?? 0,
      diff: json['diff'] is int
          ? json['diff'] as int
          : int.tryParse(json['diff']?.toString() ?? ''),
      gamesWon: json['gamesWon'] is int
          ? json['gamesWon'] as int
          : int.tryParse(json['gamesWon']?.toString() ?? ''),
      gamesLost: json['gamesLost'] is int
          ? json['gamesLost'] as int
          : int.tryParse(json['gamesLost']?.toString() ?? ''),
      buchholz: json['buchholz'] is int
          ? json['buchholz'] as int
          : int.tryParse(json['buchholz']?.toString() ?? ''),
      advancementStatus: json['advancementStatus']?.toString(),
      advancementText: json['advancementText']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      if (teamId != null) 'teamId': teamId,
      'teamName': teamName,
      if (teamCode != null) 'teamCode': teamCode,
      if (teamLogo != null) 'teamLogo': teamLogo,
      'wins': wins,
      'losses': losses,
      if (diff != null) 'diff': diff,
      if (gamesWon != null) 'gamesWon': gamesWon,
      if (gamesLost != null) 'gamesLost': gamesLost,
      if (buchholz != null) 'buchholz': buchholz,
      if (advancementStatus != null) 'advancementStatus': advancementStatus,
      if (advancementText != null) 'advancementText': advancementText,
    };
  }
}

class LolWorldsStageModel {
  final int version;
  final LolWorldsCompetitionModel competition;
  final LolWorldsSeasonModel season;
  final LolWorldsStageInfoModel? stage;
  final List<LolWorldsRoundModel> rounds;
  final List<LolWorldsMatchModel> matches;
  final List<LolSwissStandingEntryModel> swissStandings;
  final bool hasCoverage;
  final String coverageStatus;
  final String? message;

  const LolWorldsStageModel({
    this.version = 1,
    required this.competition,
    required this.season,
    this.stage,
    this.rounds = const [],
    this.matches = const [],
    this.swissStandings = const [],
    required this.hasCoverage,
    required this.coverageStatus,
    this.message,
  });

  bool get isUnconfigured => coverageStatus == 'UNCONFIGURED_CREDENTIALS';
  bool get isProviderError => coverageStatus == 'PROVIDER_ERROR';
  bool get isRateLimited => coverageStatus == 'RATE_LIMITED';
  bool get isUnauthorized =>
      coverageStatus == 'UNAUTHORIZED' || coverageStatus == 'FORBIDDEN';
  bool get isNoCoverage => coverageStatus == 'NO_COVERAGE';
  bool get hasMatches => matches.isNotEmpty;
  bool get hasSwissStandings => swissStandings.isNotEmpty;
  bool get isPartialCoverage =>
      hasCoverage && (matches.isEmpty != swissStandings.isEmpty);
  bool get isEmpty =>
      !hasCoverage ||
      (stage == null && matches.isEmpty && swissStandings.isEmpty);

  factory LolWorldsStageModel.empty({
    String slug = 'worlds',
    String name = 'League of Legends World Championship',
    String? seasonSlug,
    String? message,
    String coverageStatus = 'NO_COVERAGE',
  }) {
    return LolWorldsStageModel(
      version: 1,
      competition: LolWorldsCompetitionModel(
        slug: slug,
        name: name,
        sport: 'lol',
      ),
      season: LolWorldsSeasonModel(
        slug: seasonSlug ?? 'current',
        name: 'Worlds',
        isCurrent: true,
      ),
      stage: null,
      rounds: const [],
      matches: const [],
      swissStandings: const [],
      hasCoverage: false,
      coverageStatus: coverageStatus,
      message: message,
    );
  }

  factory LolWorldsStageModel.fromJson(Map<String, dynamic> json) {
    final rawRounds = json['rounds'] as List<dynamic>? ?? [];
    final rawMatches = json['matches'] as List<dynamic>? ?? [];
    final rawStandings = json['swissStandings'] as List<dynamic>? ?? [];

    return LolWorldsStageModel(
      version: json['version'] is int ? json['version'] as int : 1,
      competition: LolWorldsCompetitionModel.fromJson(
        json['competition'] is Map<String, dynamic>
            ? json['competition'] as Map<String, dynamic>
            : {},
      ),
      season: LolWorldsSeasonModel.fromJson(
        json['season'] is Map<String, dynamic>
            ? json['season'] as Map<String, dynamic>
            : {},
      ),
      stage: json['stage'] is Map<String, dynamic>
          ? LolWorldsStageInfoModel.fromJson(json['stage'] as Map<String, dynamic>)
          : null,
      rounds: rawRounds
          .whereType<Map<String, dynamic>>()
          .map(LolWorldsRoundModel.fromJson)
          .toList(),
      matches: rawMatches
          .whereType<Map<String, dynamic>>()
          .map(LolWorldsMatchModel.fromJson)
          .toList(),
      swissStandings: rawStandings
          .whereType<Map<String, dynamic>>()
          .map(LolSwissStandingEntryModel.fromJson)
          .toList(),
      hasCoverage: json['hasCoverage'] == true,
      coverageStatus: json['coverageStatus']?.toString() ?? 'NO_COVERAGE',
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'competition': competition.toJson(),
      'season': season.toJson(),
      if (stage != null) 'stage': stage!.toJson(),
      'rounds': rounds.map((r) => r.toJson()).toList(),
      'matches': matches.map((m) => m.toJson()).toList(),
      'swissStandings': swissStandings.map((s) => s.toJson()).toList(),
      'hasCoverage': hasCoverage,
      'coverageStatus': coverageStatus,
      if (message != null) 'message': message,
    };
  }
}
