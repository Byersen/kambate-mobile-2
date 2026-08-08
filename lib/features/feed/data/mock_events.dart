import '../../../models/event_model.dart';
import '../../../models/event_status.dart';
import '../../../models/fighter_model.dart';
import '../../../models/league_model.dart';
import '../../../models/season_model.dart';
import '../../../models/sport_type.dart';
import '../../../models/stats_models.dart';
import '../../../models/team_model.dart';

final SeasonModel kCurrentSeason = SeasonModel(
  id: 'season-2025-2026',
  name: 'Temporada 2025-2026',
  slug: '2025-2026',
  isCurrent: true,
);

final List<EventModel> kMockEvents = [
  // 1. Soccer - Live (Tier 1)
  EventModel(
    id: 'soccer-1',
    sport: SportType.soccer,
    league: 'UEFA Champions League',
    leagueModel: const LeagueModel(
      id: 'l-ucl',
      name: 'UEFA Champions League',
      slug: 'ucl',
      tier: 1,
      country: 'Europa',
    ),
    seasonModel: kCurrentSeason,
    status: EventStatus.live,
    startTime: DateTime.now().subtract(const Duration(minutes: 68)),
    currentPeriod: "68'",
    venue: 'Santiago Bernabéu, Madrid',
    homeTeam: const TeamModel(id: 'rm', name: 'Real Madrid', shortName: 'RMA'),
    awayTeam: const TeamModel(id: 'mc', name: 'Manchester City', shortName: 'MCI'),
    homeScore: 2,
    awayScore: 1,
    footballStats: const FootballStatsModel(
      id: 'fs-1',
      homeGoals: 2,
      awayGoals: 1,
      homeCards: 1,
      awayCards: 2,
    ),
    isFavorite: true,
  ),

  // 2. NBA - Live (Tier 1)
  EventModel(
    id: 'nba-1',
    sport: SportType.nba,
    league: 'NBA Regular Season',
    leagueModel: const LeagueModel(
      id: 'l-nba',
      name: 'NBA',
      slug: 'nba',
      tier: 1,
      country: 'Estados Unidos',
    ),
    seasonModel: kCurrentSeason,
    status: EventStatus.live,
    startTime: DateTime.now().subtract(const Duration(minutes: 95)),
    currentPeriod: 'Q4 03:42',
    venue: 'Crypto.com Arena, Los Angeles',
    homeTeam: const TeamModel(id: 'lal', name: 'Los Angeles Lakers', shortName: 'LAL'),
    awayTeam: const TeamModel(id: 'gsw', name: 'Golden State Warriors', shortName: 'GSW'),
    homeScore: 104,
    awayScore: 101,
    nbaStats: const NbaStatsModel(
      id: 'ns-1',
      homePoints: 104,
      awayPoints: 101,
      quarter: 'Q4',
    ),
    isFavorite: true,
  ),

  // 3. LoL - Live (Tier 1)
  EventModel(
    id: 'lol-1',
    sport: SportType.lol,
    league: 'Worlds 2026 - Semifinals',
    leagueModel: const LeagueModel(
      id: 'l-worlds',
      name: 'Worlds 2026',
      slug: 'worlds',
      tier: 1,
      country: 'Internacional',
    ),
    seasonModel: kCurrentSeason,
    status: EventStatus.live,
    startTime: DateTime.now().subtract(const Duration(minutes: 40)),
    currentPeriod: 'Juego 3 (1-1)',
    homeTeam: const TeamModel(id: 't1', name: 'T1 Telecom', shortName: 'T1'),
    awayTeam: const TeamModel(id: 'geng', name: 'Gen.G Esports', shortName: 'GEN'),
    homeScore: 1,
    awayScore: 1,
    esportsStats: const EsportsStatsModel(
      id: 'es-1',
      format: 'Bo5',
      homeScore: 1,
      awayScore: 1,
      map: 'Mapa 3',
    ),
    isFavorite: true,
  ),

  // 4. UFC - Main Event (Scheduled - Tier 1)
  EventModel(
    id: 'ufc-1',
    sport: SportType.ufc,
    league: 'UFC 308: Main Card',
    leagueModel: const LeagueModel(
      id: 'l-ufc-ppv',
      name: 'UFC PPV',
      slug: 'ufc-ppv',
      tier: 1,
      country: 'Internacional',
    ),
    seasonModel: kCurrentSeason,
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

  // 5. Valorant - Scheduled (Tier 1)
  EventModel(
    id: 'val-1',
    sport: SportType.valorant,
    league: 'VCT Champions 2026',
    leagueModel: const LeagueModel(
      id: 'l-vct',
      name: 'VCT Champions',
      slug: 'vct-champions',
      tier: 1,
      country: 'Internacional',
    ),
    seasonModel: kCurrentSeason,
    status: EventStatus.scheduled,
    startTime: DateTime.now().add(const Duration(hours: 5)),
    homeTeam: const TeamModel(id: 'sen', name: 'Sentinels', shortName: 'SEN'),
    awayTeam: const TeamModel(id: 'kru', name: 'KRÜ Esports', shortName: 'KRÜ'),
    esportsStats: const EsportsStatsModel(
      id: 'es-2',
      format: 'Bo3',
      homeScore: 0,
      awayScore: 0,
      map: 'Haven (Pick KRÜ)',
    ),
  ),

  // 6. Soccer - Scheduled Chilean Match (Tier 2 / Local League)
  EventModel(
    id: 'soccer-2',
    sport: SportType.soccer,
    league: 'Primera División de Chile',
    leagueModel: const LeagueModel(
      id: 'l-chile-1',
      name: 'Primera División Chile',
      slug: 'primera-chile',
      tier: 2,
      country: 'Chile',
    ),
    seasonModel: kCurrentSeason,
    status: EventStatus.scheduled,
    startTime: DateTime.now().add(const Duration(hours: 7)),
    venue: 'Estadio Monumental, Santiago',
    homeTeam: const TeamModel(id: 'cc', name: 'Colo-Colo', shortName: 'CC'),
    awayTeam: const TeamModel(id: 'uch', name: 'Universidad de Chile', shortName: 'UCH'),
  ),

  // 7. Soccer - Finished (Tier 1)
  EventModel(
    id: 'soccer-3',
    sport: SportType.soccer,
    league: 'LaLiga EA Sports',
    leagueModel: const LeagueModel(
      id: 'l-laliga',
      name: 'LaLiga EA Sports',
      slug: 'laliga',
      tier: 1,
      country: 'España',
    ),
    seasonModel: kCurrentSeason,
    status: EventStatus.finished,
    startTime: DateTime.now().subtract(const Duration(hours: 4)),
    venue: 'Estadi Olímpic Lluís Companys, Barcelona',
    homeTeam: const TeamModel(id: 'fcb', name: 'FC Barcelona', shortName: 'BAR'),
    awayTeam: const TeamModel(id: 'atm', name: 'Atlético de Madrid', shortName: 'ATM'),
    homeScore: 3,
    awayScore: 1,
    footballStats: const FootballStatsModel(
      id: 'fs-2',
      homeGoals: 3,
      awayGoals: 1,
      homeCards: 2,
      awayCards: 3,
    ),
  ),

  // 8. NBA - Finished (Tier 1)
  EventModel(
    id: 'nba-2',
    sport: SportType.nba,
    league: 'NBA Eastern Conference',
    leagueModel: const LeagueModel(
      id: 'l-nba',
      name: 'NBA',
      slug: 'nba',
      tier: 1,
      country: 'Estados Unidos',
    ),
    seasonModel: kCurrentSeason,
    status: EventStatus.finished,
    startTime: DateTime.now().subtract(const Duration(hours: 6)),
    homeTeam: const TeamModel(id: 'bos', name: 'Boston Celtics', shortName: 'BOS'),
    awayTeam: const TeamModel(id: 'mil', name: 'Milwaukee Bucks', shortName: 'MIL'),
    homeScore: 118,
    awayScore: 112,
    nbaStats: const NbaStatsModel(
      id: 'ns-2',
      homePoints: 118,
      awayPoints: 112,
      quarter: 'Final',
    ),
  ),

  // 9. UFC - Finished (Tier 2 / Fight Night)
  EventModel(
    id: 'ufc-2',
    sport: SportType.ufc,
    league: 'UFC Fight Night: Prelims',
    leagueModel: const LeagueModel(
      id: 'l-ufc-fn',
      name: 'UFC Fight Night',
      slug: 'ufc-fn',
      tier: 2,
      country: 'Estados Unidos',
    ),
    seasonModel: kCurrentSeason,
    status: EventStatus.finished,
    startTime: DateTime.now().subtract(const Duration(hours: 8)),
    fighter1: const FighterModel(
      id: 'f4',
      name: 'Alex Pereira',
      nickname: 'Poatan',
      record: '12-2-0',
      weightClass: 'Semi-Pesado (205 lbs)',
    ),
    fighter2: const FighterModel(
      id: 'f5',
      name: 'Jiri Prochazka',
      nickname: 'BJP',
      record: '30-5-1',
      weightClass: 'Semi-Pesado (205 lbs)',
    ),
    fightResult: 'KO (High Kick) - R2 0:13',
    ufcStats: const UfcStatsModel(
      id: 'us-2',
      winnerName: 'Alex Pereira',
      method: 'KO / TKO',
      round: 2,
      time: '0:13',
    ),
  ),

  // 10. LoL - Scheduled (Tier 2 / Regional League)
  EventModel(
    id: 'lol-2',
    sport: SportType.lol,
    league: 'Liga Latinoamérica (LLA)',
    leagueModel: const LeagueModel(
      id: 'l-lla',
      name: 'Liga Latinoamérica',
      slug: 'lla',
      tier: 2,
      country: 'Latinoamérica',
    ),
    seasonModel: kCurrentSeason,
    status: EventStatus.scheduled,
    startTime: DateTime.now().add(const Duration(hours: 8)),
    homeTeam: const TeamModel(id: 'est', name: 'Estral Esports', shortName: 'EST'),
    awayTeam: const TeamModel(id: 'r7', name: 'Movistar R7', shortName: 'R7'),
    esportsStats: const EsportsStatsModel(
      id: 'es-3',
      format: 'Bo3',
      homeScore: 0,
      awayScore: 0,
    ),
  ),
];
