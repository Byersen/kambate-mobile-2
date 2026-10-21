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
      isCombat ? (fighter1?.name ?? 'Peleador 1') : (homeTeam?.name ?? 'Local');
  String get participant2Name => isCombat
      ? (fighter2?.name ?? 'Peleador 2')
      : (awayTeam?.name ?? 'Visitante');

  LolDetailModel? get lolDetail =>
      LolDetailModel.parse(esportsStats?.extraStats?['detail']);

  ValorantDetailModel? get valorantDetail =>
      ValorantDetailModel.parse(esportsStats?.extraStats?['detail']);

  UfcCardModel? get ufcCard =>
      UfcCardModel.parse(ufcStats?.extraStats?['card']) ??
      UfcCardModel.parse(ufcStats?.extraStats?['detail']) ??
      UfcCardModel.parse(metadata?['card']) ??
      UfcCardModel.parse(metadata?['detail']);

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
    final sport = SportType.fromString(rawSport);

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

    FootballStatsModel? footballStats;
    if (json['footballStats'] is Map<String, dynamic>) {
      footballStats = FootballStatsModel.fromJson(
        json['footballStats'] as Map<String, dynamic>,
      );
    } else if (json['football_stats'] is Map<String, dynamic>) {
      footballStats = FootballStatsModel.fromJson(
        json['football_stats'] as Map<String, dynamic>,
      );
    }

    NbaStatsModel? nbaStats;
    if (json['nbaStats'] is Map<String, dynamic>) {
      nbaStats = NbaStatsModel.fromJson(
        json['nbaStats'] as Map<String, dynamic>,
      );
    } else if (json['nba_stats'] is Map<String, dynamic>) {
      nbaStats = NbaStatsModel.fromJson(
        json['nba_stats'] as Map<String, dynamic>,
      );
    }

    UfcStatsModel? ufcStats;
    if (json['ufcStats'] is Map<String, dynamic>) {
      ufcStats = UfcStatsModel.fromJson(
        json['ufcStats'] as Map<String, dynamic>,
      );
    } else if (json['ufc_stats'] is Map<String, dynamic>) {
      ufcStats = UfcStatsModel.fromJson(
        json['ufc_stats'] as Map<String, dynamic>,
      );
    }

    EsportsStatsModel? esportsStats;
    if (json['esportsStats'] is Map<String, dynamic>) {
      esportsStats = EsportsStatsModel.fromJson(
        json['esportsStats'] as Map<String, dynamic>,
      );
    } else if (json['esports_stats'] is Map<String, dynamic>) {
      esportsStats = EsportsStatsModel.fromJson(
        json['esports_stats'] as Map<String, dynamic>,
      );
    }

    final footballDetail = FootballDetailModel.parse(
      footballStats?.extraStats?['detail'],
    );
    if (sport == SportType.soccer && footballDetail != null) {
      final home = participants
          .where((p) => p.id == footballDetail.homeParticipantId)
          .firstOrNull;
      final away = participants
          .where((p) => p.id == footballDetail.awayParticipantId)
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
      r'^\s*(\d+)\s*[-–:]\s*(\d+)\s*$',
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
      score: json['score']?.toString(),
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
