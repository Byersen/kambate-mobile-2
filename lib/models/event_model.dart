import 'basketball_detail_model.dart';
import 'event_status.dart';
import 'fighter_model.dart';
import 'football_detail_model.dart';
import 'league_model.dart';
import 'lol_detail_model.dart';
import 'participant_model.dart';
import 'season_model.dart';
import 'sport_type.dart';
import 'stats_models.dart';
import 'team_model.dart';
import 'ufc_card_model.dart';
import 'valorant_detail_model.dart';

class EventModel {
  final String id;
  final String? externalId;
  final SportType sport;
  final String league;
  final LeagueModel? leagueModel;
  final SeasonModel? seasonModel;
  final EventStatus status;
  final DateTime startTime;
  final String? currentPeriod;
  final String? venue;
  final String? score;

  final List<ParticipantModel> participants;

  final TeamModel? homeTeam;
  final TeamModel? awayTeam;
  final int? homeScore;
  final int? awayScore;

  final FighterModel? fighter1;
  final FighterModel? fighter2;
  final String? fightResult;

  final FootballStatsModel? footballStats;
  final NbaStatsModel? nbaStats;
  final UfcStatsModel? ufcStats;
  final EsportsStatsModel? esportsStats;

  final bool isFavorite;
  final Map<String, dynamic>? metadata;

  const EventModel({
    required this.id,
    this.externalId,
    required this.sport,
    required this.league,
    this.leagueModel,
    this.seasonModel,
    required this.status,
    required this.startTime,
    this.currentPeriod,
    this.venue,
    this.score,
    this.participants = const [],
    this.homeTeam,
    this.awayTeam,
    this.homeScore,
    this.awayScore,
    this.fighter1,
    this.fighter2,
    this.fightResult,
    this.footballStats,
    this.nbaStats,
    this.ufcStats,
    this.esportsStats,
    this.isFavorite = false,
    this.metadata,
  });

  bool get isLive => status == EventStatus.live;
  bool get isCombat => sport == SportType.ufc;

  String get participant1Name =>
      isCombat ? (fighter1?.name ?? 'Peleador 1') : (homeTeam?.name ?? 'Por definir');
  String get participant2Name => isCombat
      ? (fighter2?.name ?? 'Peleador 2')
      : (awayTeam?.name ?? 'Por definir');

  LolDetailModel? get lolDetail =>
      LolDetailModel.parse(esportsStats?.extraStats?['detail']);

  ValorantDetailModel? get valorantDetail =>
      ValorantDetailModel.parse(esportsStats?.extraStats?['detail']);

  UfcCardModel? get ufcCard =>
      UfcCardModel.parse(ufcStats?.extraStats?['card']) ??
      UfcCardModel.parse(ufcStats?.extraStats?['detail']) ??
      UfcCardModel.parse(metadata?['card']) ??
      UfcCardModel.parse(metadata?['detail']);

  String? get leagueLogoUrl {
    final fromModel = leagueModel?.logoUrl;
    if (fromModel != null && fromModel.isNotEmpty) return fromModel;
    final fromFootball = footballStats?.extraStats?['leagueLogo']?.toString() ??
        footballStats?.extraStats?['league_logo']?.toString();
    if (fromFootball != null && fromFootball.isNotEmpty) return fromFootball;
    final fromMeta = metadata?['leagueLogo']?.toString() ??
        metadata?['league_logo']?.toString();
    if (fromMeta != null && fromMeta.isNotEmpty) return fromMeta;
    return null;
  }

  String? get roundOrPhase {
    final explicit = footballStats?.extraStats?['round']?.toString() ??
        footballStats?.extraStats?['phase']?.toString() ??
        footballStats?.extraStats?['jornada']?.toString() ??
        esportsStats?.extraStats?['phase']?.toString() ??
        metadata?['round']?.toString() ??
        metadata?['phase']?.toString() ??
        metadata?['jornada']?.toString();
    if (explicit != null && explicit.trim().isNotEmpty) return explicit.trim();

    if (sport == SportType.lol || sport == SportType.valorant) {
      final format = esportsStats?.format ??
          valorantDetail?.format ??
          lolDetail?.format;
      if (format != null && format.trim().isNotEmpty) return format.trim();
    }

    if (sport == SportType.ufc) {
      if (ufcStats?.round != null && ufcStats!.round! > 0) {
        return 'Ronda ${ufcStats!.round}';
      }
    }

    final seasonSlug = seasonModel?.slug;
    if (seasonSlug != null &&
        !RegExp(r'^\d{4}(-\d{2,4})?$').hasMatch(seasonSlug) &&
        !seasonSlug.contains('regular')) {
      if (seasonSlug == 'league-phase') return 'Fase de Liga';
      if (seasonSlug.contains('group')) return 'Fase de Grupos';
      if (seasonSlug.contains('playoff')) return 'Playoffs';
    }

    return null;
  }

  EventModel copyWith({
    String? id,
    String? externalId,
    SportType? sport,
    String? league,
    LeagueModel? leagueModel,
    SeasonModel? seasonModel,
    EventStatus? status,
    DateTime? startTime,
    String? currentPeriod,
    String? venue,
    String? score,
    List<ParticipantModel>? participants,
    TeamModel? homeTeam,
    TeamModel? awayTeam,
    int? homeScore,
    int? awayScore,
    FighterModel? fighter1,
    FighterModel? fighter2,
    String? fightResult,
    FootballStatsModel? footballStats,
    NbaStatsModel? nbaStats,
    UfcStatsModel? ufcStats,
    EsportsStatsModel? esportsStats,
    bool? isFavorite,
    Map<String, dynamic>? metadata,
  }) {
    return EventModel(
      id: id ?? this.id,
      externalId: externalId ?? this.externalId,
      sport: sport ?? this.sport,
      league: league ?? this.league,
      leagueModel: leagueModel ?? this.leagueModel,
      seasonModel: seasonModel ?? this.seasonModel,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      currentPeriod: currentPeriod ?? this.currentPeriod,
      venue: venue ?? this.venue,
      score: score ?? this.score,
      participants: participants ?? this.participants,
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      fighter1: fighter1 ?? this.fighter1,
      fighter2: fighter2 ?? this.fighter2,
      fightResult: fightResult ?? this.fightResult,
      footballStats: footballStats ?? this.footballStats,
      nbaStats: nbaStats ?? this.nbaStats,
      ufcStats: ufcStats ?? this.ufcStats,
      esportsStats: esportsStats ?? this.esportsStats,
      isFavorite: isFavorite ?? this.isFavorite,
      metadata: metadata ?? this.metadata,
    );
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    String? rawSport;
    if (json['sport'] is Map<String, dynamic>) {
      rawSport =
          json['sport']['slug']?.toString() ??
          json['sport']['name']?.toString();
    } else {
      rawSport = json['sport']?.toString() ?? json['discipline']?.toString();
    }
    var sport = SportType.fromString(rawSport);

    if (sport == SportType.all) {
      final leagueSlug = (json['league'] is Map<String, dynamic>
              ? json['league']['slug']?.toString()
              : null) ??
          (json['league_model'] is Map<String, dynamic>
              ? json['league_model']['slug']?.toString()
              : null) ??
          json['leagueSlug']?.toString();
      final leagueName = (json['league'] is Map<String, dynamic>
              ? json['league']['name']?.toString()
              : json['league']?.toString()) ??
          '';
      final externalId = json['externalId']?.toString() ??
          json['external_id']?.toString() ??
          '';

      final combined =
          '${leagueSlug ?? ''} $leagueName $externalId'.toLowerCase();
      if (combined.contains('valorant') ||
          combined.contains('vct') ||
          combined.contains('vlr')) {
        sport = SportType.valorant;
      } else if (combined.contains('lol') ||
          combined.contains('league of legends') ||
          combined.contains('lck') ||
          combined.contains('lec') ||
          combined.contains('lpl') ||
          combined.contains('lcs') ||
          combined.contains('cblol') ||
          combined.contains('lla') ||
          combined.contains('worlds') ||
          combined.contains('msi')) {
        sport = SportType.lol;
      }
    }

    final status = EventStatus.fromString(json['status']?.toString());

    DateTime parsedDate;
    try {
      if (json['startDate'] != null) {
        String dateStr = json['startDate'].toString();
        if (!RegExp(
          r'(Z|[+-]\d{2}:?\d{2})$',
          caseSensitive: false,
        ).hasMatch(dateStr)) {
          dateStr += 'Z'; // Force UTC parsing
        }
        parsedDate = DateTime.parse(dateStr).toLocal();
      } else if (json['start_time'] != null) {
        String dateStr = json['start_time'].toString();
        if (!RegExp(
          r'(Z|[+-]\d{2}:?\d{2})$',
          caseSensitive: false,
        ).hasMatch(dateStr)) {
          dateStr += 'Z';
        }
        parsedDate = DateTime.parse(dateStr).toLocal();
      } else if (json['startTime'] != null) {
        String dateStr = json['startTime'].toString();
        if (!RegExp(
          r'(Z|[+-]\d{2}:?\d{2})$',
          caseSensitive: false,
        ).hasMatch(dateStr)) {
          dateStr += 'Z';
        }
        parsedDate = DateTime.parse(dateStr).toLocal();
      } else {
        parsedDate = DateTime.now();
      }
    } catch (_) {
      parsedDate = DateTime.now();
    }

    LeagueModel? leagueModel;
    String leagueName = 'Competición';
    if (json['league_model'] is Map<String, dynamic>) {
      leagueModel = LeagueModel.fromJson(
        json['league_model'] as Map<String, dynamic>,
      );
      leagueName = leagueModel.name;
    } else if (json['league'] is Map<String, dynamic>) {
      leagueModel = LeagueModel.fromJson(
        json['league'] as Map<String, dynamic>,
      );
      leagueName = leagueModel.name;
    } else if (json['league'] != null) {
      leagueName = json['league'].toString();
    } else if (json['tournament'] != null) {
      leagueName = json['tournament'].toString();
    }

    SeasonModel? seasonModel;
    if (json['season_model'] is Map<String, dynamic>) {
      seasonModel = SeasonModel.fromJson(
        json['season_model'] as Map<String, dynamic>,
      );
    } else if (json['season'] is Map<String, dynamic>) {
      seasonModel = SeasonModel.fromJson(
        json['season'] as Map<String, dynamic>,
      );
    }

    List<ParticipantModel> participants = [];
    if (json['participants'] is List) {
      participants = (json['participants'] as List)
          .map((p) => ParticipantModel.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    TeamModel? homeTeam;
    TeamModel? awayTeam;
    if (json['home_team'] != null) {
      homeTeam = TeamModel.fromJson(json['home_team'] as Map<String, dynamic>);
    } else if (json['homeTeam'] != null) {
      homeTeam = TeamModel.fromJson(json['homeTeam'] as Map<String, dynamic>);
    } else if (participants.isNotEmpty && sport != SportType.ufc) {
      homeTeam = TeamModel(
        id: participants[0].id,
        name: participants[0].name,
        shortName: participants[0].shortName,
        logoUrl: participants[0].logoUrl,
      );
    }

    if (json['away_team'] != null) {
      awayTeam = TeamModel.fromJson(json['away_team'] as Map<String, dynamic>);
    } else if (json['awayTeam'] != null) {
      awayTeam = TeamModel.fromJson(json['awayTeam'] as Map<String, dynamic>);
    } else if (participants.length > 1 && sport != SportType.ufc) {
      awayTeam = TeamModel(
        id: participants[1].id,
        name: participants[1].name,
        shortName: participants[1].shortName,
        logoUrl: participants[1].logoUrl,
      );
    }

    FighterModel? fighter1;
    FighterModel? fighter2;
    if (json['fighter1'] != null) {
      fighter1 = FighterModel.fromJson(
        json['fighter1'] as Map<String, dynamic>,
      );
    } else if (participants.isNotEmpty && sport == SportType.ufc) {
      fighter1 = FighterModel(
        id: participants[0].id,
        name: participants[0].name,
        photoUrl: participants[0].photoUrl ?? participants[0].logoUrl,
        record: participants[0].record,
        country: participants[0].country,
      );
    }

    if (json['fighter2'] != null) {
      fighter2 = FighterModel.fromJson(
        json['fighter2'] as Map<String, dynamic>,
      );
    } else if (participants.length > 1 && sport == SportType.ufc) {
      fighter2 = FighterModel(
        id: participants[1].id,
        name: participants[1].name,
        photoUrl: participants[1].photoUrl ?? participants[1].logoUrl,
        record: participants[1].record,
        country: participants[1].country,
      );
    }

    dynamic rawFootball = json['footballStats'] ?? json['football_stats'];
    if (rawFootball is List && rawFootball.isNotEmpty) {
      rawFootball = rawFootball.first;
    }
    FootballStatsModel? footballStats;
    if (rawFootball is Map<String, dynamic>) {
      footballStats = FootballStatsModel.fromJson(rawFootball);
    }

    dynamic rawNba = json['nbaStats'] ?? json['nba_stats'];
    if (rawNba is List && rawNba.isNotEmpty) {
      rawNba = rawNba.first;
    }
    NbaStatsModel? nbaStats;
    if (rawNba is Map<String, dynamic>) {
      nbaStats = NbaStatsModel.fromJson(rawNba);
    }

    dynamic rawUfc = json['ufcStats'] ?? json['ufc_stats'];
    if (rawUfc is List && rawUfc.isNotEmpty) {
      rawUfc = rawUfc.first;
    }
    UfcStatsModel? ufcStats;
    if (rawUfc is Map<String, dynamic>) {
      ufcStats = UfcStatsModel.fromJson(rawUfc);
    }

    dynamic rawEsports = json['esportsStats'] ?? json['esports_stats'];
    if (rawEsports is List && rawEsports.isNotEmpty) {
      rawEsports = rawEsports.first;
    }
    EsportsStatsModel? esportsStats;
    if (rawEsports is Map<String, dynamic>) {
      esportsStats = EsportsStatsModel.fromJson(rawEsports);
    }

    final footballDetail = FootballDetailModel.parse(
      footballStats?.extraStats?['detail'],
    );
    if (sport == SportType.soccer) {
      ParticipantModel? home;
      ParticipantModel? away;
      if (footballDetail != null) {
        home = participants
            .where((p) => p.id == footballDetail.homeParticipantId)
            .firstOrNull;
        away = participants
            .where((p) => p.id == footballDetail.awayParticipantId)
            .firstOrNull;
      }
      final extra = footballStats?.extraStats;
      if (home == null && extra != null) {
        final homeId = extra['homeTeamId']?.toString();
        if (homeId != null && homeId.isNotEmpty) {
          home = participants
              .where((p) =>
                  p.externalId == 'football-team-$homeId' ||
                  p.externalId == homeId ||
                  (p.externalId?.endsWith('-$homeId') ?? false))
              .firstOrNull;
        }
      }
      if (away == null && extra != null) {
        final awayId = extra['awayTeamId']?.toString();
        if (awayId != null && awayId.isNotEmpty) {
          away = participants
              .where((p) =>
                  p.externalId == 'football-team-$awayId' ||
                  p.externalId == awayId ||
                  (p.externalId?.endsWith('-$awayId') ?? false))
              .firstOrNull;
        }
      }
      if (home != null && away != null) {
        homeTeam = TeamModel(
          id: home.id,
          name: home.name,
          shortName: home.shortName,
          logoUrl: home.logoUrl,
        );
        awayTeam = TeamModel(
          id: away.id,
          name: away.name,
          shortName: away.shortName,
          logoUrl: away.logoUrl,
        );
      }
    }

    final basketballDetail = BasketballDetailModel.parse(
      nbaStats?.extraStats?['detail'],
    );
    if (sport == SportType.nba && basketballDetail != null) {
      final home = participants
          .where((p) => p.id == basketballDetail.homeParticipantId)
          .firstOrNull;
      final away = participants
          .where((p) => p.id == basketballDetail.awayParticipantId)
          .firstOrNull;
      if (home != null && away != null) {
        homeTeam = TeamModel(
          id: home.id,
          name: home.name,
          shortName: home.shortName,
          logoUrl: home.logoUrl,
        );
        awayTeam = TeamModel(
          id: away.id,
          name: away.name,
          shortName: away.shortName,
          logoUrl: away.logoUrl,
        );
      }
    }

    final lolDetail = LolDetailModel.parse(
      esportsStats?.extraStats?['detail'],
    );
    if (sport == SportType.lol && lolDetail != null) {
      final home = participants
          .where((p) => p.id == lolDetail.homeParticipantId)
          .firstOrNull;
      final away = participants
          .where((p) => p.id == lolDetail.awayParticipantId)
          .firstOrNull;
      if (home != null && away != null) {
        homeTeam = TeamModel(
          id: home.id,
          name: home.name,
          shortName: home.shortName,
          logoUrl: home.logoUrl,
        );
        awayTeam = TeamModel(
          id: away.id,
          name: away.name,
          shortName: away.shortName,
          logoUrl: away.logoUrl,
        );
      }
    }

    final valorantDetail = ValorantDetailModel.parse(
      esportsStats?.extraStats?['detail'],
    );
    if (sport == SportType.valorant && valorantDetail != null) {
      final home = participants
          .where((p) => p.id == valorantDetail.homeParticipantId)
          .firstOrNull;
      final away = participants
          .where((p) => p.id == valorantDetail.awayParticipantId)
          .firstOrNull;
      if (home != null && away != null) {
        homeTeam = TeamModel(
          id: home.id,
          name: home.name,
          shortName: home.shortName,
          logoUrl: home.logoUrl,
        );
        awayTeam = TeamModel(
          id: away.id,
          name: away.name,
          shortName: away.shortName,
          logoUrl: away.logoUrl,
        );
      }
    }

    int? homeScore = json['home_score'] is int
        ? json['home_score'] as int
        : int.tryParse(json['home_score']?.toString() ?? '');
    final scoreParts = RegExp(
      r'(\d+)\s*[-–:]\s*(\d+)',
    ).firstMatch(json['score']?.toString() ?? '');
    homeScore ??= scoreParts != null ? int.parse(scoreParts.group(1)!) : null;
    homeScore ??=
        footballStats?.homeGoals ??
        nbaStats?.homePoints ??
        esportsStats?.homeScore;

    int? awayScore = json['away_score'] is int
        ? json['away_score'] as int
        : int.tryParse(json['away_score']?.toString() ?? '');
    awayScore ??= scoreParts != null ? int.parse(scoreParts.group(2)!) : null;
    awayScore ??=
        footballStats?.awayGoals ??
        nbaStats?.awayPoints ??
        esportsStats?.awayScore;

    String? score = json['score']?.toString();
    if (status == EventStatus.scheduled) {
      homeScore = null;
      awayScore = null;
      score = null;
    } else if (status == EventStatus.finished || status == EventStatus.live) {
      if (homeScore != null &&
          awayScore != null &&
          (score == null || score == 'vs' || score.trim().isEmpty)) {
        score = '$homeScore - $awayScore';
      } else if (score == 'vs') {
        score = null;
      }
    }

    return EventModel(
      id: json['id']?.toString() ?? '',
      externalId:
          json['external_id']?.toString() ?? json['externalId']?.toString(),
      sport: sport,
      league: leagueName,
      leagueModel: leagueModel,
      seasonModel: seasonModel,
      status: status,
      startTime: parsedDate,
      currentPeriod:
          json['current_period']?.toString() ??
          json['currentPeriod']?.toString() ??
          footballStats?.extraStats?['clock']?.toString() ??
          nbaStats?.extraStats?['clock']?.toString() ??
          nbaStats?.extraStats?['quarter']?.toString() ??
          nbaStats?.quarter,
      venue: json['venue']?.toString() ??
          footballStats?.extraStats?['venue']?.toString() ??
          nbaStats?.extraStats?['venue']?.toString(),
      score: score,
      participants: participants,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeScore: homeScore,
      awayScore: awayScore,
      fighter1: fighter1,
      fighter2: fighter2,
      fightResult:
          json['fight_result']?.toString() ??
          json['fightResult']?.toString() ??
          ufcStats?.method,
      footballStats: footballStats,
      nbaStats: nbaStats,
      ufcStats: ufcStats,
      esportsStats: esportsStats,
      isFavorite: json['is_favorite'] == true || json['isFavorite'] == true,
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'external_id': externalId,
      'sport': sport.id,
      'league': league,
      'league_model': leagueModel?.toJson(),
      'season_model': seasonModel?.toJson(),
      'status': status.id,
      'start_time': startTime.toUtc().toIso8601String(),
      'startDate': startTime.toUtc().toIso8601String(),
      'current_period': currentPeriod,
      'venue': venue,
      'score': score,
      'participants': participants.map((p) => p.toJson()).toList(),
      'home_team': homeTeam?.toJson(),
      'away_team': awayTeam?.toJson(),
      'home_score': homeScore,
      'away_score': awayScore,
      'fighter1': fighter1?.toJson(),
      'fighter2': fighter2?.toJson(),
      'fight_result': fightResult,
      'football_stats': footballStats?.toJson(),
      'nba_stats': nbaStats?.toJson(),
      'ufc_stats': ufcStats?.toJson(),
      'esports_stats': esportsStats?.toJson(),
      'is_favorite': isFavorite,
      'metadata': metadata,
    };
  }
}
