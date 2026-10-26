import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kambate_mobile/features/feed/data/feed_repository.dart';
import 'package:kambate_mobile/features/feed/providers/feed_provider.dart';
import 'package:kambate_mobile/features/league_detail/presentation/screens/league_detail_screen.dart';
import 'package:kambate_mobile/features/league_detail/providers/league_detail_provider.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'package:kambate_mobile/models/event_status.dart';
import 'package:kambate_mobile/models/league_detail_model.dart';
import 'package:kambate_mobile/models/league_model.dart';
import 'package:kambate_mobile/models/season_model.dart';
import 'package:kambate_mobile/models/sport_type.dart';
import 'package:kambate_mobile/models/stats_models.dart';
import 'package:kambate_mobile/models/team_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeFeedRepository extends FeedRepository {
  final List<EventModel> eventsList;
  FakeFeedRepository(this.eventsList) : super(subscribeToRealtime: false);

  @override
  Future<List<EventModel>> fetchRemoteEvents() async => eventsList;

  @override
  Future<List<EventModel>> getEvents({
    SportType? sport,
    int? leagueTier,
    bool forceRefresh = false,
  }) async {
    return eventsList;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpAndFlush(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('Tarea 33: Resumen de jornada, tabla y goleadores en detalle de fútbol', () {
    testWidgets('1. Jornada con ronda: muestra nombre de jornada oficial y partidos asociados', (tester) async {
      final roundEvents = [
        EventModel(
          id: 'ev-1',
          sport: SportType.soccer,
          league: 'LaLiga',
          leagueModel: const LeagueModel(id: 'esp1', name: 'LaLiga', slug: 'esp.1'),
          seasonModel: const SeasonModel(id: 's2024', name: 'Temporada 2024-2025', slug: '2024-2025'),
          status: EventStatus.scheduled,
          startTime: DateTime.now().add(const Duration(hours: 1)),
          homeTeam: const TeamModel(id: '1', name: 'Athletic Club'),
          awayTeam: const TeamModel(id: '2', name: 'Getafe'),
          footballStats: const FootballStatsModel(
            id: 'fs-1',
            extraStats: {'round': 'Jornada 10'},
          ),
        ),
        EventModel(
          id: 'ev-2',
          sport: SportType.soccer,
          league: 'LaLiga',
          leagueModel: const LeagueModel(id: 'esp1', name: 'LaLiga', slug: 'esp.1'),
          seasonModel: const SeasonModel(id: 's2024', name: 'Temporada 2024-2025', slug: '2024-2025'),
          status: EventStatus.scheduled,
          startTime: DateTime.now().add(const Duration(hours: 3)),
          homeTeam: const TeamModel(id: '3', name: 'Sevilla'),
          awayTeam: const TeamModel(id: '4', name: 'Osasuna'),
          footballStats: const FootballStatsModel(
            id: 'fs-1',
            extraStats: {'round': 'Jornada 10'},
          ),
        ),
      ];

      final detail = LeagueDetailModel(
        version: 1,
        leagueId: 'esp1',
        leagueSlug: 'esp.1',
        leagueName: 'LaLiga',
        hasStandingsCoverage: true,
        hasLeadersCoverage: true,
        groups: const [
          LeagueStandingGroupModel(
            name: 'General',
            entries: [
              LeagueStandingEntryModel(position: 1, teamName: 'Barcelona', playedGames: 9, points: 27),
            ],
          ),
        ],
        topScorers: const [
          LeagueScorerModel(rank: 1, playerName: 'Raphinha', teamName: 'Barcelona', goals: 13),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          leagueDetailProvider.overrideWith((ref, params) async => detail),
          feedRepositoryProvider.overrideWithValue(FakeFeedRepository(roundEvents)),
        ],
      );
      addTearDown(container.dispose);
      await container.read(feedNotifierProvider.notifier).loadEvents();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LeagueDetailScreen(
              leagueName: 'LaLiga',
              sport: SportType.soccer,
              leagueSlug: 'esp.1',
              leagueId: 'esp1',
            ),
          ),
        ),
      );
      await pumpAndFlush(tester);

      // 1. Debe mostrarse la etiqueta oficial de la jornada entregada por la fuente
      expect(find.text('JORNADA 10'), findsOneWidget);

      // 2. Deben aparecer los partidos de esa jornada
      expect(find.text('Athletic Club'), findsOneWidget);
      expect(find.text('Getafe'), findsOneWidget);
      expect(find.text('Sevilla'), findsOneWidget);
      expect(find.text('Osasuna'), findsOneWidget);

      // 3. Orden de secciones: Partidos, Tabla y Goleadores visibles en la misma vista de resumen
      expect(find.text('TABLA DE POSICIONES'), findsOneWidget);
      expect(find.text('Ver tabla completa'), findsOneWidget);
      expect(find.text('GOLEADORES'), findsOneWidget);
      expect(find.text('Raphinha'), findsOneWidget);
    });

    testWidgets('2. Jornada sin ronda: no inventa jornada y muestra agrupación neutral PARTIDOS', (tester) async {
      final noRoundEvents = [
        EventModel(
          id: 'ev-no-round',
          sport: SportType.soccer,
          league: 'Premier League',
          leagueModel: const LeagueModel(id: 'eng1', name: 'Premier League', slug: 'eng.1'),
          status: EventStatus.scheduled,
          startTime: DateTime.now().add(const Duration(hours: 2)),
          homeTeam: const TeamModel(id: '10', name: 'Liverpool'),
          awayTeam: const TeamModel(id: '11', name: 'Everton'),
          // Sin round ni phase ni jornada
        ),
      ];

      final detail = LeagueDetailModel(
        version: 1,
        leagueSlug: 'eng.1',
        leagueName: 'Premier League',
        hasStandingsCoverage: true,
        hasLeadersCoverage: false,
        groups: const [
          LeagueStandingGroupModel(
            name: 'General',
            entries: [
              LeagueStandingEntryModel(position: 1, teamName: 'Liverpool', playedGames: 9, points: 21),
            ],
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          leagueDetailProvider.overrideWith((ref, params) async => detail),
          feedRepositoryProvider.overrideWithValue(FakeFeedRepository(noRoundEvents)),
        ],
      );
      addTearDown(container.dispose);
      await container.read(feedNotifierProvider.notifier).loadEvents();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LeagueDetailScreen(
              leagueName: 'Premier League',
              sport: SportType.soccer,
              leagueSlug: 'eng.1',
            ),
          ),
        ),
      );
      await pumpAndFlush(tester);

      // Cabecera neutral: 'PARTIDOS', NO 'Jornada'
      expect(find.text('PARTIDOS'), findsOneWidget);
      expect(find.textContaining('Jornada'), findsNothing);
      expect(find.text('Liverpool'), findsWidgets);
      expect(find.text('Everton'), findsOneWidget);
    });

    testWidgets('3. Varias agrupaciones de tabla: muestra secciones separadas por grupo sin mezclar tablas', (tester) async {
      final multiGroupDetail = LeagueDetailModel(
        version: 1,
        leagueSlug: 'arg.1',
        leagueName: 'Liga Profesional',
        hasStandingsCoverage: true,
        hasLeadersCoverage: false,
        groups: [
          LeagueStandingGroupModel(
            name: 'Zona A',
            entries: List.generate(
              7,
              (i) => LeagueStandingEntryModel(
                position: i + 1,
                teamName: 'Equipo Zona A ${i + 1}',
                playedGames: 10,
                points: 20 - i,
              ),
            ),
          ),
          LeagueStandingGroupModel(
            name: 'Zona B',
            entries: List.generate(
              6,
              (i) => LeagueStandingEntryModel(
                position: i + 1,
                teamName: 'Equipo Zona B ${i + 1}',
                playedGames: 10,
                points: 18 - i,
              ),
            ),
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          leagueDetailProvider.overrideWith((ref, params) async => multiGroupDetail),
          feedRepositoryProvider.overrideWithValue(FakeFeedRepository([])),
        ],
      );
      addTearDown(container.dispose);
      await container.read(feedNotifierProvider.notifier).loadEvents();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LeagueDetailScreen(
              leagueName: 'Liga Profesional',
              sport: SportType.soccer,
              leagueSlug: 'arg.1',
            ),
          ),
        ),
      );
      await pumpAndFlush(tester);

      // Deben verse los títulos de ambos grupos
      expect(find.text('ZONA A'), findsOneWidget);
      expect(find.text('ZONA B'), findsOneWidget);

      // En el resumen de cada grupo se muestran como máximo 5 puestos
      expect(find.text('Equipo Zona A 1'), findsOneWidget);
      expect(find.text('Equipo Zona A 5'), findsOneWidget);
      expect(find.text('Equipo Zona A 6'), findsNothing); // Puesto 6 no debe aparecer en resumen

      expect(find.text('Equipo Zona B 1'), findsOneWidget);
      expect(find.text('Equipo Zona B 5'), findsOneWidget);
      expect(find.text('Equipo Zona B 6'), findsNothing); // Puesto 6 no debe aparecer en resumen

      // Botón "Ver tabla completa" inmediatamente debajo de cada grupo
      expect(find.text('Ver tabla completa'), findsNWidgets(2));
    });

    testWidgets('4. Menos de cinco puestos en tabla: muestra puestos reales sin filas ficticias', (tester) async {
      final shortGroupDetail = LeagueDetailModel(
        version: 1,
        leagueSlug: 'torneo.corto',
        leagueName: 'Torneo Triangular',
        hasStandingsCoverage: true,
        hasLeadersCoverage: false,
        groups: const [
          LeagueStandingGroupModel(
            name: 'General',
            entries: [
              LeagueStandingEntryModel(position: 1, teamName: 'Colo-Colo', playedGames: 2, points: 6),
              LeagueStandingEntryModel(position: 2, teamName: 'U de Chile', playedGames: 2, points: 3),
              LeagueStandingEntryModel(position: 3, teamName: 'U Católica', playedGames: 2, points: 0),
            ],
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          leagueDetailProvider.overrideWith((ref, params) async => shortGroupDetail),
          feedRepositoryProvider.overrideWithValue(FakeFeedRepository([])),
        ],
      );
      addTearDown(container.dispose);
      await container.read(feedNotifierProvider.notifier).loadEvents();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LeagueDetailScreen(
              leagueName: 'Torneo Triangular',
              sport: SportType.soccer,
              leagueSlug: 'torneo.corto',
            ),
          ),
        ),
      );
      await pumpAndFlush(tester);

      expect(find.text('Colo-Colo'), findsOneWidget);
      expect(find.text('U de Chile'), findsOneWidget);
      expect(find.text('U Católica'), findsOneWidget);
      expect(find.text('Equipo A'), findsNothing);
      expect(find.text('Equipo B'), findsNothing);
      expect(find.text('Ver tabla completa'), findsOneWidget);
    });

    testWidgets('5. Menos de cinco goleadores: muestra jugadores reales respetando rank y sin inventar', (tester) async {
      final shortScorersDetail = LeagueDetailModel(
        version: 1,
        leagueSlug: 'esp.1',
        leagueName: 'LaLiga',
        hasStandingsCoverage: false,
        hasLeadersCoverage: true,
        topScorers: const [
          LeagueScorerModel(rank: 1, playerName: 'Kylian Mbappé', teamName: 'Real Madrid', goals: 8),
          LeagueScorerModel(rank: 2, playerName: 'Robert Lewandowski', teamName: 'Barcelona', goals: 7),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          leagueDetailProvider.overrideWith((ref, params) async => shortScorersDetail),
          feedRepositoryProvider.overrideWithValue(FakeFeedRepository([])),
        ],
      );
      addTearDown(container.dispose);
      await container.read(feedNotifierProvider.notifier).loadEvents();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LeagueDetailScreen(
              leagueName: 'LaLiga',
              sport: SportType.soccer,
              leagueSlug: 'esp.1',
            ),
          ),
        ),
      );
      await pumpAndFlush(tester);

      expect(find.text('GOLEADORES'), findsOneWidget);
      expect(find.text('Kylian Mbappé'), findsOneWidget);
      expect(find.text('8 G'), findsOneWidget);
      expect(find.text('Robert Lewandowski'), findsOneWidget);
      expect(find.text('7 G'), findsOneWidget);
      expect(find.text('Jugador 1'), findsNothing);
      expect(find.text('Jugador 2'), findsNothing);
    });

    testWidgets('6. Cobertura parcial o ausente: maneja estados limpios sin romper el resto de la vista', (tester) async {
      final partialDetail = LeagueDetailModel(
        version: 1,
        leagueSlug: 'liga-parcial',
        leagueName: 'Liga Parcial',
        hasStandingsCoverage: false,
        hasLeadersCoverage: false,
        groups: const [],
        topScorers: const [],
      );

      final container = ProviderContainer(
        overrides: [
          leagueDetailProvider.overrideWith((ref, params) async => partialDetail),
          feedRepositoryProvider.overrideWithValue(FakeFeedRepository([])),
        ],
      );
      addTearDown(container.dispose);
      await container.read(feedNotifierProvider.notifier).loadEvents();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LeagueDetailScreen(
              leagueName: 'Liga Parcial',
              sport: SportType.soccer,
              leagueSlug: 'liga-parcial',
            ),
          ),
        ),
      );
      await pumpAndFlush(tester);

      // Sin partidos disponibles
      expect(find.text('Sin partidos disponibles'), findsOneWidget);
      // Posiciones no disponibles
      expect(find.text('Posiciones no disponibles'), findsOneWidget);
      // Goleadores no disponibles
      expect(find.text('Goleadores no disponibles'), findsOneWidget);
      // Sin filas de demostración
      expect(find.textContaining('demo'), findsNothing);
      expect(find.textContaining('demostración'), findsNothing);
    });

    testWidgets('7. Navegación a tabla completa: pulsar "Ver tabla completa" expone todas las posiciones', (tester) async {
      final fullDetail = LeagueDetailModel(
        version: 1,
        leagueSlug: 'esp.1',
        leagueName: 'LaLiga',
        hasStandingsCoverage: true,
        hasLeadersCoverage: true,
        groups: [
          LeagueStandingGroupModel(
            name: 'General',
            entries: List.generate(
              10,
              (i) => LeagueStandingEntryModel(
                position: i + 1,
                teamName: 'Equipo $i',
                playedGames: 10,
                points: 30 - i * 2,
              ),
            ),
          ),
        ],
        topScorers: const [
          LeagueScorerModel(rank: 1, playerName: 'Pichichi', teamName: 'Equipo 0', goals: 15),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          leagueDetailProvider.overrideWith((ref, params) async => fullDetail),
          feedRepositoryProvider.overrideWithValue(FakeFeedRepository([])),
        ],
      );
      addTearDown(container.dispose);
      await container.read(feedNotifierProvider.notifier).loadEvents();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LeagueDetailScreen(
              leagueName: 'LaLiga',
              sport: SportType.soccer,
              leagueSlug: 'esp.1',
            ),
          ),
        ),
      );
      await pumpAndFlush(tester);

      // En el resumen sólo se ven los primeros 5 equipos (0 a 4)
      expect(find.text('Equipo 0'), findsWidgets);
      expect(find.text('Equipo 4'), findsOneWidget);
      expect(find.text('Equipo 5'), findsNothing);
      expect(find.text('Equipo 9'), findsNothing);

      // Pulsar el botón "Ver tabla completa"
      final buttonFinder = find.byKey(const ValueKey('btn_ver_tabla_completa'));
      expect(buttonFinder, findsOneWidget);
      await tester.tap(buttonFinder);
      await pumpAndFlush(tester);

      // Ahora en la pestaña Tabla completa se exponen todas las posiciones
      expect(find.text('Equipo 5'), findsOneWidget);
      expect(find.text('Equipo 9'), findsOneWidget);
    });
  });
}
