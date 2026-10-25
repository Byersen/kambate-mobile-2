import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kambate_mobile/features/feed/presentation/screens/feed_screen.dart';
import 'package:kambate_mobile/features/feed/presentation/widgets/scoreboard_row.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'package:kambate_mobile/models/event_status.dart';
import 'package:kambate_mobile/models/league_model.dart';
import 'package:kambate_mobile/models/sport_type.dart';
import 'package:kambate_mobile/models/stats_models.dart';
import 'package:kambate_mobile/models/team_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final baseTime = DateTime(2026, 10, 24, 15, 0);

  group('Tarea 29 — Lógica unitaria de groupEventsByCompetition', () {
    test('usa EventModel.leagueModel.id real como clave cuando existe', () {
      final ev1 = EventModel(
        id: 'ev-1',
        sport: SportType.soccer,
        league: 'La Liga',
        leagueModel: const LeagueModel(
          id: 'real-league-esp1',
          name: 'LaLiga EA Sports',
          slug: 'esp.1',
        ),
        status: EventStatus.scheduled,
        startTime: baseTime,
      );

      final groups = FeedScreen.groupEventsByCompetition([ev1]);
      expect(groups, hasLength(1));
      expect(groups.first.key, 'league_id:real-league-esp1');
      expect(groups.first.name, 'LaLiga EA Sports');
    });

    test('usa fallback explícito y estable para registros sin relación de liga sin inventar IDs', () {
      final evNoLeague = EventModel(
        id: 'ev-no-league',
        sport: SportType.soccer,
        league: 'Torneo Amateur Regional',
        leagueModel: null,
        status: EventStatus.scheduled,
        startTime: baseTime,
      );

      final groups = FeedScreen.groupEventsByCompetition([evNoLeague]);
      expect(groups, hasLength(1));
      expect(groups.first.key, 'no_league_id:soccer:torneo amateur regional');
      expect(groups.first.name, 'Torneo Amateur Regional');
    });

    test('competiciones homónimas de deportes distintos permanecen separadas en fallbacks', () {
      final evSoccer = EventModel(
        id: 'ev-soccer-superliga',
        sport: SportType.soccer,
        league: 'Superliga',
        status: EventStatus.scheduled,
        startTime: baseTime,
      );
      final evLol = EventModel(
        id: 'ev-lol-superliga',
        sport: SportType.lol,
        league: 'Superliga',
        status: EventStatus.scheduled,
        startTime: baseTime.add(const Duration(hours: 1)),
      );

      final groups = FeedScreen.groupEventsByCompetition([evSoccer, evLol]);
      expect(groups, hasLength(2));
      expect(groups[0].key, 'no_league_id:soccer:superliga');
      expect(groups[0].sport, SportType.soccer);
      expect(groups[1].key, 'no_league_id:lol:superliga');
      expect(groups[1].sport, SportType.lol);
    });

    test('competiciones homónimas con IDs reales diferentes permanecen separadas', () {
      final ev1 = EventModel(
        id: 'ev-cup-1',
        sport: SportType.soccer,
        league: 'Copa Nacional',
        leagueModel: const LeagueModel(
          id: 'league-uuid-aaa',
          name: 'Copa Nacional',
          slug: 'copa-a',
        ),
        status: EventStatus.scheduled,
        startTime: baseTime,
      );
      final ev2 = EventModel(
        id: 'ev-cup-2',
        sport: SportType.soccer,
        league: 'Copa Nacional',
        leagueModel: const LeagueModel(
          id: 'league-uuid-bbb',
          name: 'Copa Nacional',
          slug: 'copa-b',
        ),
        status: EventStatus.scheduled,
        startTime: baseTime.add(const Duration(minutes: 30)),
      );

      final groups = FeedScreen.groupEventsByCompetition([ev1, ev2]);
      expect(groups, hasLength(2));
      expect(groups[0].key, 'league_id:league-uuid-aaa');
      expect(groups[1].key, 'league_id:league-uuid-bbb');
    });

    test('deduplicación estricta por ID de evento: cada partido aparece solo una vez', () {
      final evOriginal = EventModel(
        id: 'duplicate-match-id',
        sport: SportType.soccer,
        league: 'Premier League',
        leagueModel: const LeagueModel(id: 'eng.1', name: 'Premier League', slug: 'eng.1'),
        status: EventStatus.scheduled,
        startTime: baseTime,
        homeTeam: const TeamModel(id: 't-1', name: 'Arsenal'),
        awayTeam: const TeamModel(id: 't-2', name: 'Chelsea'),
      );
      final evRepeated = EventModel(
        id: 'duplicate-match-id',
        sport: SportType.soccer,
        league: 'Premier League',
        leagueModel: const LeagueModel(id: 'eng.1', name: 'Premier League', slug: 'eng.1'),
        status: EventStatus.scheduled,
        startTime: baseTime,
        homeTeam: const TeamModel(id: 't-1', name: 'Arsenal'),
        awayTeam: const TeamModel(id: 't-2', name: 'Chelsea'),
      );

      final groups = FeedScreen.groupEventsByCompetition([evOriginal, evRepeated]);
      expect(groups, hasLength(1));
      expect(groups.first.events, hasLength(1));
      expect(groups.first.events.first.id, 'duplicate-match-id');
    });

    test('orden determinista de eventos dentro del grupo por hora, con tiebreaker por ID ante empate', () {
      final evLate = EventModel(
        id: 'match-c-late',
        sport: SportType.soccer,
        league: 'Premier League',
        leagueModel: const LeagueModel(id: 'eng.1', name: 'Premier League', slug: 'eng.1'),
        status: EventStatus.scheduled,
        startTime: baseTime.add(const Duration(hours: 2)),
      );
      final evTiedB = EventModel(
        id: 'match-b-tied',
        sport: SportType.soccer,
        league: 'Premier League',
        leagueModel: const LeagueModel(id: 'eng.1', name: 'Premier League', slug: 'eng.1'),
        status: EventStatus.scheduled,
        startTime: baseTime,
      );
      final evTiedA = EventModel(
        id: 'match-a-tied',
        sport: SportType.soccer,
        league: 'Premier League',
        leagueModel: const LeagueModel(id: 'eng.1', name: 'Premier League', slug: 'eng.1'),
        status: EventStatus.scheduled,
        startTime: baseTime,
      );

      // Enviados en orden desordenado
      final groups = FeedScreen.groupEventsByCompetition([evLate, evTiedB, evTiedA]);
      expect(groups, hasLength(1));
      final groupEvents = groups.first.events;
      expect(groupEvents, hasLength(3));
      // match-a-tied debe preceder a match-b-tied ante misma hora
      expect(groupEvents[0].id, 'match-a-tied');
      expect(groupEvents[1].id, 'match-b-tied');
      expect(groupEvents[2].id, 'match-c-late');
    });

    test('no genera grupos vacíos', () {
      final groups = FeedScreen.groupEventsByCompetition([]);
      expect(groups, isEmpty);
    });

    test('resuelve logo real y ronda/fase real cuando existen y los omite cleanly cuando no existen', () {
      final evWithLogoAndPhase = EventModel(
        id: 'ev-ucl',
        sport: SportType.soccer,
        league: 'UEFA Champions League',
        leagueModel: const LeagueModel(
          id: 'ucl-id',
          name: 'UEFA Champions League',
          slug: 'uefa.champions',
          logoUrl: 'https://a.espncdn.com/i/leaguelogos/soccer/500/2.png',
        ),
        status: EventStatus.live,
        startTime: baseTime,
        footballStats: const FootballStatsModel(
          id: 'fs-1',
          extraStats: {'phase': 'Fase de Liga'},
        ),
      );

      final evWithoutLogoOrPhase = EventModel(
        id: 'ev-nba-plain',
        sport: SportType.nba,
        league: 'NBA',
        leagueModel: const LeagueModel(id: 'nba-id', name: 'NBA', slug: 'nba'),
        status: EventStatus.scheduled,
        startTime: baseTime,
      );

      final groups = FeedScreen.groupEventsByCompetition([evWithLogoAndPhase, evWithoutLogoOrPhase]);
      expect(groups, hasLength(2));

      expect(groups[0].logoUrl, 'https://a.espncdn.com/i/leaguelogos/soccer/500/2.png');
      expect(groups[0].roundOrPhase, 'Fase de Liga');

      expect(groups[1].logoUrl, isNull);
      expect(groups[1].roundOrPhase, isNull);
    });

    test('soporte consistente para los 5 deportes: fútbol, NBA, UFC, LoL y Valorant', () {
      final soccerEv = EventModel(
        id: 'sport-soccer',
        sport: SportType.soccer,
        league: 'LaLiga EA Sports',
        leagueModel: const LeagueModel(id: 'esp.1', name: 'LaLiga EA Sports', slug: 'esp.1'),
        status: EventStatus.live,
        startTime: baseTime,
      );
      final nbaEv = EventModel(
        id: 'sport-nba',
        sport: SportType.nba,
        league: 'NBA',
        leagueModel: const LeagueModel(id: 'nba', name: 'NBA', slug: 'nba'),
        status: EventStatus.scheduled,
        startTime: baseTime.add(const Duration(hours: 1)),
      );
      final ufcEv = EventModel(
        id: 'sport-ufc',
        sport: SportType.ufc,
        league: 'UFC',
        leagueModel: const LeagueModel(id: 'ufc', name: 'UFC', slug: 'ufc'),
        status: EventStatus.live,
        startTime: baseTime.add(const Duration(hours: 2)),
        ufcStats: const UfcStatsModel(id: 'ufc-s', round: 3),
      );
      final lolEv = EventModel(
        id: 'sport-lol',
        sport: SportType.lol,
        league: 'LCK',
        leagueModel: const LeagueModel(id: 'lck', name: 'LCK', slug: 'lck'),
        status: EventStatus.scheduled,
        startTime: baseTime.add(const Duration(hours: 3)),
        esportsStats: const EsportsStatsModel(id: 'lol-s', format: 'Bo3'),
      );
      final valEv = EventModel(
        id: 'sport-val',
        sport: SportType.valorant,
        league: 'VCT Americas',
        leagueModel: const LeagueModel(id: 'vct', name: 'VCT Americas', slug: 'vct'),
        status: EventStatus.scheduled,
        startTime: baseTime.add(const Duration(hours: 4)),
        esportsStats: const EsportsStatsModel(id: 'val-s', format: 'Bo3'),
      );

      final groups = FeedScreen.groupEventsByCompetition([soccerEv, nbaEv, ufcEv, lolEv, valEv]);
      expect(groups, hasLength(5));
      expect(groups.map((g) => g.sport).toList(), [
        SportType.soccer,
        SportType.nba,
        SportType.ufc,
        SportType.lol,
        SportType.valorant,
      ]);
      expect(groups[2].roundOrPhase, 'Ronda 3');
      expect(groups[3].roundOrPhase, 'Bo3');
      expect(groups[4].roundOrPhase, 'Bo3');
    });
  });

  group('Tarea 29 — Presentación visual de grupos de competición en widgets', () {
    testWidgets('Muestra cabeceras visuales de competición con logo, nombre y ronda/fase sin grupos vacíos', (tester) async {
      final events = [
        EventModel(
          id: 'ucl-match-1',
          sport: SportType.soccer,
          league: 'UEFA Champions League',
          leagueModel: const LeagueModel(
            id: 'ucl-league-id',
            name: 'UEFA Champions League',
            slug: 'uefa.champions',
            country: 'Europa',
            logoUrl: 'https://a.espncdn.com/i/leaguelogos/soccer/500/2.png',
          ),
          status: EventStatus.scheduled,
          startTime: baseTime,
          homeTeam: const TeamModel(id: 't-real', name: 'Real Madrid'),
          awayTeam: const TeamModel(id: 't-city', name: 'Manchester City'),
          footballStats: const FootballStatsModel(
            id: 'fs-1',
            extraStats: {'phase': 'Fase de Liga'},
          ),
        ),
        EventModel(
          id: 'ucl-match-2',
          sport: SportType.soccer,
          league: 'UEFA Champions League',
          leagueModel: const LeagueModel(
            id: 'ucl-league-id',
            name: 'UEFA Champions League',
            slug: 'uefa.champions',
            country: 'Europa',
            logoUrl: 'https://a.espncdn.com/i/leaguelogos/soccer/500/2.png',
          ),
          status: EventStatus.scheduled,
          startTime: baseTime.add(const Duration(hours: 2)),
          homeTeam: const TeamModel(id: 't-barca', name: 'Barcelona'),
          awayTeam: const TeamModel(id: 't-bayern', name: 'Bayern'),
          footballStats: const FootballStatsModel(
            id: 'fs-2',
            extraStats: {'phase': 'Fase de Liga'},
          ),
        ),
        EventModel(
          id: 'laliga-match-1',
          sport: SportType.soccer,
          league: 'LaLiga EA Sports',
          leagueModel: const LeagueModel(
            id: 'laliga-league-id',
            name: 'LaLiga EA Sports',
            slug: 'esp.1',
            country: 'España',
          ),
          status: EventStatus.scheduled,
          startTime: baseTime.add(const Duration(minutes: 30)),
          homeTeam: const TeamModel(id: 't-atm', name: 'Atlético'),
          awayTeam: const TeamModel(id: 't-sev', name: 'Sevilla'),
        ),
      ];

      final groups = FeedScreen.groupEventsByCompetition(events);
      expect(groups, hasLength(2));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverList.separated(
                  itemCount: 2,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final g = groups[index];
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Cabecera de competición
                        Container(
                          key: ValueKey('header_${g.key}'),
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Text(g.name),
                              if (g.country != null) Text(' • ${g.country}'),
                              if (g.roundOrPhase != null) Text(g.roundOrPhase!),
                            ],
                          ),
                        ),
                        // Partidos asociados en tres columnas de la tarea 28
                        for (final ev in g.events)
                          ScoreboardRow(
                            key: ValueKey(ev.id),
                            event: ev,
                            onTap: () {},
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Cabeceras presentes
      expect(find.text('UEFA Champions League'), findsOneWidget);
      expect(find.text(' • Europa'), findsOneWidget);
      expect(find.text('Fase de Liga'), findsOneWidget);

      expect(find.text('LaLiga EA Sports'), findsOneWidget);
      expect(find.text(' • España'), findsOneWidget);

      // Partidos presentes con ScoreboardRow intacto
      expect(find.byType(ScoreboardRow), findsNWidgets(3));
      expect(find.text('Real Madrid'), findsOneWidget);
      expect(find.text('Manchester City'), findsOneWidget);
      expect(find.text('Barcelona'), findsOneWidget);
      expect(find.text('Bayern'), findsOneWidget);
      expect(find.text('Atlético'), findsOneWidget);
      expect(find.text('Sevilla'), findsOneWidget);
    });

    testWidgets('Tarjetas ScoreboardRow dentro de los grupos preservan las tres columnas', (tester) async {
      final evLive = EventModel(
        id: 'ev-3col-live',
        sport: SportType.soccer,
        league: 'Premier League',
        leagueModel: const LeagueModel(id: 'eng.1', name: 'Premier League', slug: 'eng.1'),
        status: EventStatus.live,
        startTime: baseTime,
        currentPeriod: "45+2'",
        homeTeam: const TeamModel(id: 't-liv', name: 'Liverpool'),
        awayTeam: const TeamModel(id: 't-che', name: 'Chelsea'),
        homeScore: 1,
        awayScore: 0,
      );

      final groups = FeedScreen.groupEventsByCompetition([evLive]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                for (final g in groups) ...[
                  SliverToBoxAdapter(
                    child: Text(g.name),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ScoreboardRow(
                        key: ValueKey(g.events[index].id),
                        event: g.events[index],
                        onTap: () {},
                      ),
                      childCount: g.events.length,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Columna 1: Equipos
      expect(find.text('Liverpool'), findsOneWidget);
      expect(find.text('Chelsea'), findsOneWidget);
      // Columna 2: Marcadores alineados
      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      // Columna 3: Minuto en vivo (sin punto rojo)
      expect(find.text('45+2′'), findsOneWidget);
      expect(find.byKey(const ValueKey('scoreboard_live_dot')), findsNothing);
    });
  });
}
