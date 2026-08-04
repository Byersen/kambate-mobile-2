import 'event_status.dart';
import 'fighter_model.dart';
import 'sport_type.dart';
import 'team_model.dart';

class EventModel {
  final String id;
  final SportType sport;
  final String league;
  final EventStatus status;
  final DateTime startTime;
  final String? currentPeriod; // e.g. "74'", "Q3 05:12", "Round 2", "Map 2"
  final String? venue;

  // For Team Sports (Soccer, NBA, LoL, Valorant)
  final TeamModel? homeTeam;
  final TeamModel? awayTeam;
  final int? homeScore;
  final int? awayScore;

  // For Combat Sports (UFC / MMA)
  final FighterModel? fighter1;
  final FighterModel? fighter2;
  final String? fightResult; // e.g. "KO / TKO - R2 3:15"

  final bool isFavorite;
  final Map<String, dynamic>? metadata;

  const EventModel({
    required this.id,
    required this.sport,
    required this.league,
    required this.status,
    required this.startTime,
    this.currentPeriod,
    this.venue,
    this.homeTeam,
    this.awayTeam,
    this.homeScore,
    this.awayScore,
    this.fighter1,
    this.fighter2,
    this.fightResult,
    this.isFavorite = false,
    this.metadata,
  });

  bool get isLive => status == EventStatus.live;
  bool get isCombat => sport == SportType.ufc;

  String get participant1Name => isCombat ? (fighter1?.name ?? 'Peleador 1') : (homeTeam?.name ?? 'Local');
  String get participant2Name => isCombat ? (fighter2?.name ?? 'Peleador 2') : (awayTeam?.name ?? 'Visitante');

  EventModel copyWith({
    String? id,
    SportType? sport,
    String? league,
    EventStatus? status,
    DateTime? startTime,
    String? currentPeriod,
    String? venue,
    TeamModel? homeTeam,
    TeamModel? awayTeam,
    int? homeScore,
    int? awayScore,
    FighterModel? fighter1,
    FighterModel? fighter2,
    String? fightResult,
    bool? isFavorite,
    Map<String, dynamic>? metadata,
  }) {
    return EventModel(
      id: id ?? this.id,
      sport: sport ?? this.sport,
      league: league ?? this.league,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      currentPeriod: currentPeriod ?? this.currentPeriod,
      venue: venue ?? this.venue,
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      fighter1: fighter1 ?? this.fighter1,
      fighter2: fighter2 ?? this.fighter2,
      fightResult: fightResult ?? this.fightResult,
      isFavorite: isFavorite ?? this.isFavorite,
      metadata: metadata ?? this.metadata,
    );
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final sport = SportType.fromString(json['sport']?.toString() ?? json['discipline']?.toString());
    final status = EventStatus.fromString(json['status']?.toString());

    DateTime parsedDate;
    try {
      parsedDate = json['start_time'] != null
          ? DateTime.parse(json['start_time'].toString())
          : (json['startTime'] != null
              ? DateTime.parse(json['startTime'].toString())
              : DateTime.now());
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return EventModel(
      id: json['id']?.toString() ?? '',
      sport: sport,
      league: json['league']?.toString() ?? json['tournament']?.toString() ?? 'Competición',
      status: status,
      startTime: parsedDate,
      currentPeriod: json['current_period']?.toString() ?? json['currentPeriod']?.toString(),
      venue: json['venue']?.toString(),
      homeTeam: json['home_team'] != null
          ? TeamModel.fromJson(json['home_team'] as Map<String, dynamic>)
          : (json['homeTeam'] != null ? TeamModel.fromJson(json['homeTeam'] as Map<String, dynamic>) : null),
      awayTeam: json['away_team'] != null
          ? TeamModel.fromJson(json['away_team'] as Map<String, dynamic>)
          : (json['awayTeam'] != null ? TeamModel.fromJson(json['awayTeam'] as Map<String, dynamic>) : null),
      homeScore: json['home_score'] is int
          ? json['home_score'] as int
          : int.tryParse(json['home_score']?.toString() ?? ''),
      awayScore: json['away_score'] is int
          ? json['away_score'] as int
          : int.tryParse(json['away_score']?.toString() ?? ''),
      fighter1: json['fighter1'] != null ? FighterModel.fromJson(json['fighter1'] as Map<String, dynamic>) : null,
      fighter2: json['fighter2'] != null ? FighterModel.fromJson(json['fighter2'] as Map<String, dynamic>) : null,
      fightResult: json['fight_result']?.toString() ?? json['fightResult']?.toString(),
      isFavorite: json['is_favorite'] == true || json['isFavorite'] == true,
      metadata: json['metadata'] is Map<String, dynamic> ? json['metadata'] as Map<String, dynamic> : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sport': sport.id,
      'league': league,
      'status': status.id,
      'start_time': startTime.toIso8601String(),
      'current_period': currentPeriod,
      'venue': venue,
      'home_team': homeTeam?.toJson(),
      'away_team': awayTeam?.toJson(),
      'home_score': homeScore,
      'away_score': awayScore,
      'fighter1': fighter1?.toJson(),
      'fighter2': fighter2?.toJson(),
      'fight_result': fightResult,
      'is_favorite': isFavorite,
      'metadata': metadata,
    };
  }
}
