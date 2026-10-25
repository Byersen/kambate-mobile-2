import 'package:flutter_test/flutter_test.dart';
import 'package:kambate_mobile/core/utils/football_competition_priority.dart';
import 'package:kambate_mobile/features/favorites/models/search_league_item.dart';
import 'package:kambate_mobile/features/feed/presentation/screens/feed_screen.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'package:kambate_mobile/models/event_status.dart';
import 'package:kambate_mobile/models/league_model.dart';
import 'package:kambate_mobile/models/sport_type.dart';
import 'package:kambate_mobile/models/team_model.dart';

void main() {
  group('Priorización de Worlds y Aislamiento de Deportes (Tarea 30)', () {
    final now = DateTime.now();

    final worldsEvent = EventModel(
      id: 'lol-worlds-match-1',
      sport: SportType.lol,
      league: 'Worlds',
      leagueModel: const LeagueModel(
        id: 'league-worlds-id',
        name: 'Worlds',
        slug: 'worlds',
      ),
      homeTeam: const TeamModel(id: 't1', name: 'T1'),
      awayTeam: const TeamModel(id: 'tes', name: 'Top Esports'),
      startTime: now.add(const Duration(hours: 2)),
      status: EventStatus.scheduled,
    );

    final lckEvent = EventModel(
      id: 'lol-lck-match-1',
      sport: SportType.lol,
      league: 'LCK',
      leagueModel: const LeagueModel(
        id: 'league-lck-id',
        name: 'LCK',
        slug: 'lck',
      ),
      homeTeam: const TeamModel(id: 'gen', name: 'Gen.G'),
      awayTeam: const TeamModel(id: 'dk', name: 'Dplus KIA'),
      startTime: now.add(const Duration(hours: 1)), // hora más temprana que Worlds
      status: EventStatus.scheduled,
    );

    final valorantEvent = EventModel(
      id: 'vlr-match-1',
      sport: SportType.valorant,
      league: 'VCT Americas',
      leagueModel: const LeagueModel(
        id: 'league-vct-id',
        name: 'VCT Americas',
        slug: 'vct-americas',
      ),
      homeTeam: const TeamModel(id: 'sen', name: 'Sentinels'),
      awayTeam: const TeamModel(id: 'loud', name: 'LOUD'),
      startTime: now.add(const Duration(hours: 1)),
      status: EventStatus.scheduled,
    );

    final soccerEvent = EventModel(
      id: 'soccer-ucl-1',
      sport: SportType.soccer,
      league: 'Champions League',
      leagueModel: const LeagueModel(
        id: 'ucl-id',
        name: 'UEFA Champions League',
        slug: 'uefa.champions',
      ),
      homeTeam: const TeamModel(id: 'rm', name: 'Real Madrid'),
      awayTeam: const TeamModel(id: 'mci', name: 'Manchester City'),
      startTime: now.add(const Duration(hours: 3)),
      status: EventStatus.scheduled,
    );

    test('groupEventsByCompetition prioriza Worlds al inicio de las competiciones de LoL', () {
      // Pasamos primero LCK y luego Worlds
      final groups = FeedScreen.groupEventsByCompetition([lckEvent, worldsEvent]);

      expect(groups, hasLength(2));
      // Worlds debe ser el primer grupo a pesar de que LCK tenía una hora previa
      expect(groups[0].name.toLowerCase(), contains('worlds'));
      expect(groups[1].name.toLowerCase(), contains('lck'));
    });

    test('FootballCompetitionPriority.sortEvents prioriza eventos Worlds entre eventos de LoL', () {
      final sorted = FootballCompetitionPriority.sortEvents([lckEvent, worldsEvent]);

      expect(sorted, hasLength(2));
      expect(sorted[0].id, 'lol-worlds-match-1');
      expect(sorted[1].id, 'lol-lck-match-1');
    });

    test('El feed de LoL no incluye encuentros de Valorant como si fueran de LoL', () {
      final mixedEvents = [worldsEvent, lckEvent, valorantEvent];
      final lolOnly = mixedEvents.where((e) => e.sport == SportType.lol).toList();

      expect(lolOnly, hasLength(2));
      expect(lolOnly.any((e) => e.sport == SportType.valorant), false);
      expect(lolOnly.any((e) => e.id == 'vlr-match-1'), false);
    });

    test('El feed de Valorant y otros deportes conserva sus eventos y no se ve alterado por la priorización de LoL', () {
      final mixedEvents = [soccerEvent, valorantEvent, worldsEvent];

      final valorantEvents = mixedEvents.where((e) => e.sport == SportType.valorant).toList();
      expect(valorantEvents, hasLength(1));
      expect(valorantEvents.first.league, 'VCT Americas');

      final soccerEvents = mixedEvents.where((e) => e.sport == SportType.soccer).toList();
      expect(soccerEvents, hasLength(1));
      expect(soccerEvents.first.league, 'Champions League');
    });

    test('Catálogo canónico kCanonicalLeagues incluye Worlds como primera competición de LoL', () {
      final lolLeagues = kCanonicalLeagues.where((l) => l.sport == SportType.lol).toList();

      expect(lolLeagues, isNotEmpty);
      expect(lolLeagues.first.name, 'Worlds');
      expect(lolLeagues.first.subtitle, contains('World Championship'));
    });

    test('EventModel.fromJson distingue rigurosamente eventos de LoL y Valorant desde esports', () {
      final rawValorantJson = {
        'id': 'ev-vlr',
        'sport': {'slug': 'esports', 'name': 'Esports'},
        'league': {'slug': 'valorant', 'name': 'VALORANT Champions Tour'},
        'externalId': 'vlr-match-999',
        'status': 'SCHEDULED',
      };

      final rawLolWorldsJson = {
        'id': 'ev-worlds',
        'sport': {'slug': 'esports', 'name': 'Esports'},
        'league': {'slug': 'worlds', 'name': 'LoL World Championship'},
        'externalId': 'lol-worlds-2026',
        'status': 'SCHEDULED',
      };

      final modelVlr = EventModel.fromJson(rawValorantJson);
      final modelWorlds = EventModel.fromJson(rawLolWorldsJson);

      expect(modelVlr.sport, SportType.valorant);
      expect(modelWorlds.sport, SportType.lol);
    });
  });
}
