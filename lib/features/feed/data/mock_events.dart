import '../../../models/event_model.dart';
import '../../../models/event_status.dart';
import '../../../models/fighter_model.dart';
import '../../../models/sport_type.dart';
import '../../../models/team_model.dart';

final List<EventModel> kMockEvents = [
  // 1. Soccer - Live
  EventModel(
    id: 'soccer-1',
    sport: SportType.soccer,
    league: 'UEFA Champions League',
    status: EventStatus.live,
    startTime: DateTime.now().subtract(const Duration(minutes: 68)),
    currentPeriod: "68'",
    venue: 'Santiago Bernabéu, Madrid',
    homeTeam: const TeamModel(id: 'rm', name: 'Real Madrid', shortName: 'RMA'),
    awayTeam: const TeamModel(id: 'mc', name: 'Manchester City', shortName: 'MCI'),
    homeScore: 2,
    awayScore: 1,
    isFavorite: true,
  ),

  // 2. NBA - Live
  EventModel(
    id: 'nba-1',
    sport: SportType.nba,
    league: 'NBA Regular Season',
    status: EventStatus.live,
    startTime: DateTime.now().subtract(const Duration(minutes: 95)),
    currentPeriod: 'Q4 03:42',
    venue: 'Crypto.com Arena, Los Angeles',
    homeTeam: const TeamModel(id: 'lal', name: 'Los Angeles Lakers', shortName: 'LAL'),
    awayTeam: const TeamModel(id: 'gsw', name: 'Golden State Warriors', shortName: 'GSW'),
    homeScore: 104,
    awayScore: 101,
  ),

  // 3. UFC - Main Event (Scheduled)
  EventModel(
    id: 'ufc-1',
    sport: SportType.ufc,
    league: 'UFC 308: Main Card',
    status: EventStatus.scheduled,
    startTime: DateTime.now().add(const Duration(hours: 3, minutes: 30)),
    venue: 'Etihad Arena, Abu Dhabi',
    fighter1: const FighterModel(
      id: 'f1',
      name: 'Ilia Topuria',
      nickname: 'El Matador',
      record: '15-0-0',
      weightClass: 'Pluma (145 lbs)',
    ),
    fighter2: const FighterModel(
      id: 'f2',
      name: 'Max Holloway',
      nickname: 'Blessed',
      record: '26-7-0',
      weightClass: 'Pluma (145 lbs)',
    ),
    isFavorite: true,
  ),

  // 4. LoL - Live
  EventModel(
    id: 'lol-1',
    sport: SportType.lol,
    league: 'Worlds 2026 - Semifinals',
    status: EventStatus.live,
    startTime: DateTime.now().subtract(const Duration(minutes: 40)),
    currentPeriod: 'Juego 3 (1-1)',
    homeTeam: const TeamModel(id: 't1', name: 'T1 Telecom', shortName: 'T1'),
    awayTeam: const TeamModel(id: 'geng', name: 'Gen.G Esports', shortName: 'GEN'),
    homeScore: 1,
    awayScore: 1,
    isFavorite: true,
  ),

  // 5. Valorant - Scheduled
  EventModel(
    id: 'val-1',
    sport: SportType.valorant,
    league: 'VCT Champions 2026',
    status: EventStatus.scheduled,
    startTime: DateTime.now().add(const Duration(hours: 5)),
    homeTeam: const TeamModel(id: 'sen', name: 'Sentinels', shortName: 'SEN'),
    awayTeam: const TeamModel(id: 'kru', name: 'KRÜ Esports', shortName: 'KRÜ'),
  ),

  // 6. Soccer - Scheduled Chilean Match
  EventModel(
    id: 'soccer-2',
    sport: SportType.soccer,
    league: 'Primera División de Chile',
    status: EventStatus.scheduled,
    startTime: DateTime.now().add(const Duration(hours: 7)),
    venue: 'Estadio Monumental, Santiago',
    homeTeam: const TeamModel(id: 'cc', name: 'Colo-Colo', shortName: 'CC'),
    awayTeam: const TeamModel(id: 'uch', name: 'Universidad de Chile', shortName: 'UCH'),
  ),

  // 7. NBA - Finished
  EventModel(
    id: 'nba-2',
    sport: SportType.nba,
    league: 'NBA Eastern Conference',
    status: EventStatus.finished,
    startTime: DateTime.now().subtract(const Duration(hours: 6)),
    homeTeam: const TeamModel(id: 'bos', name: 'Boston Celtics', shortName: 'BOS'),
    awayTeam: const TeamModel(id: 'mil', name: 'Milwaukee Bucks', shortName: 'MIL'),
    homeScore: 118,
    awayScore: 112,
  ),
];
