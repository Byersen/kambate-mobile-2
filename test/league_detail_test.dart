import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kambate_mobile/features/feed/data/feed_repository.dart';
import 'package:kambate_mobile/features/feed/providers/feed_provider.dart';
import 'package:kambate_mobile/features/league_detail/data/league_detail_repository.dart';
import 'package:kambate_mobile/features/league_detail/presentation/screens/league_detail_screen.dart';
import 'package:kambate_mobile/features/league_detail/providers/league_detail_provider.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'package:kambate_mobile/models/event_status.dart';
import 'package:kambate_mobile/models/league_detail_model.dart';
import 'package:kambate_mobile/models/league_model.dart';
import 'package:kambate_mobile/models/season_model.dart';
import 'package:kambate_mobile/models/sport_type.dart';
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

  group('LeagueDetailModel - Contrato y Serialización', () {
    test('Parsea JSON completo con grupos de posiciones y goleadores', () {
      final json = {
        'version': 1,
        'leagueId': 'league-uuid-esp1',
        'leagueSlug': 'esp.1',
        'leagueName': 'Spanish LALIGA',
        'seasonId': 'season-uuid-2024',
        'seasonSlug': '2024-2025',
        'seasonName': 'Temporada 2024-2025',
        'hasStandingsCoverage': true,
        'hasLeadersCoverage': true,
        'groups': [
          {
            'name': 'General',
            'entries': [
              {
                'position': 1,
                'teamId': '83',
                'participantId': 'uuid-barcelona',
                'teamName': 'Barcelona',
                'teamLogo': 'https://a.espncdn.com/barcelona.png',
                'playedGames': 9,
                'points': 27,
                'won': 9,
                'drawn': 0,
                'lost': 0,
                'goalsFor': 39,
                'goalsAgainst': 9,
                'goalDifference': 30,
                'note': 'Champions League',
                'isPromotion': true,
              },
            ],
          },
        ],
        'topScorers': [
          {
            'rank': 1,
            'athleteId': '231050',
            'playerName': 'Raphinha',
            'playerPhoto': 'https://a.espncdn.com/raphinha.png',
            'teamId': '83',
            'teamName': 'Barcelona',
            'teamLogo': 'https://a.espncdn.com/barcelona.png',
            'participantId': 'uuid-barcelona',
            'goals': 12,
            'playedGames': 8,
            'assists': 3,
          },
        ],
      };

      final model = LeagueDetailModel.fromJson(json);

      expect(model.version, 1);
      expect(model.leagueId, 'league-uuid-esp1');
      expect(model.leagueSlug, 'esp.1');
      expect(model.seasonId, 'season-uuid-2024');
      expect(model.hasStandingsCoverage, isTrue);
      expect(model.hasLeadersCoverage, isTrue);
      expect(model.groups.length, 1);

      final entry = model.groups.first.entries.first;
      expect(entry.position, 1);
      expect(entry.teamId, '83');
      expect(entry.participantId, 'uuid-barcelona');
      expect(entry.teamName, 'Barcelona');
      expect(entry.playedGames, 9);
      expect(entry.points, 27);
      expect(entry.goalDifference, 30);
      expect(entry.isPromotion, isTrue);

      final scorer = model.topScorers.first;
      expect(scorer.rank, 1);
      expect(scorer.athleteId, '231050');
      expect(scorer.playerName, 'Raphinha');
      expect(scorer.teamName, 'Barcelona');
      expect(scorer.goals, 12);
      expect(scorer.assists, 3);
    });

    test('LeagueDetailModel.empty genera modelo sin cobertura y sin filas ficticias', () {
      final empty = LeagueDetailModel.empty(
        leagueSlug: 'ufc',
        leagueName: 'UFC',
        leagueId: 'league-uuid-ufc',
      );

      expect(empty.hasStandingsCoverage, isFalse);
      expect(empty.hasLeadersCoverage, isFalse);
      expect(empty.groups, isEmpty);
      expect(empty.topScorers, isEmpty);
      expect(empty.isEmpty, isTrue);
    });

    test('resolveLeagueSlug resuelve nombres a slugs oficiales de ESPN/Kambate', () {
      expect(LeagueDetailRepository.resolveLeagueSlug('LaLiga'), 'esp.1');
      expect(LeagueDetailRepository.resolveLeagueSlug('Spanish LALIGA'), 'esp.1');
      expect(LeagueDetailRepository.resolveLeagueSlug('Premier League'), 'eng.1');
      expect(LeagueDetailRepository.resolveLeagueSlug('Champions League'), 'uefa.champions');
      expect(LeagueDetailRepository.resolveLeagueSlug('NBA'), 'nba');
      expect(LeagueDetailRepository.resolveLeagueSlug('UFC'), 'ufc');
      expect(LeagueDetailRepository.resolveLeagueSlug('LCK'), 'lol');
      expect(LeagueDetailRepository.resolveLeagueSlug('VCT Americas'), 'vct-americas');
    });
  });

  group('LeagueDetailScreen - Presentación UI y Estados de Cobertura', () {
    final mockRealDetail = LeagueDetailModel(
      version: 1,
      leagueId: 'league-esp1',
      leagueSlug: 'esp.1',
      leagueName: 'LaLiga',
      seasonId: 'season-2024',
      seasonSlug: '2024-2025',
      hasStandingsCoverage: true,
      hasLeadersCoverage: true,
      groups: const [
        LeagueStandingGroupModel(
          name: 'General',
          entries: [
            LeagueStandingEntryModel(
              position: 1,
              teamId: '83',
              participantId: 'part-barca',
              teamName: 'Barcelona Real',
              playedGames: 10,
              points: 28,
              won: 9,
              drawn: 1,
              lost: 0,
              goalsFor: 32,
              goalsAgainst: 8,
              goalDifference: 24,
              note: 'Champions League',
              isPromotion: true,
            ),
            LeagueStandingEntryModel(
              position: 2,
              teamId: '86',
              participantId: 'part-madrid',
              teamName: 'Real Madrid',
              playedGames: 10,
              points: 24,
              won: 7,
              drawn: 3,
              lost: 0,
              goalsFor: 21,
              goalsAgainst: 7,
              goalDifference: 14,
              note: 'Champions League',
              isPromotion: true,
            ),
          ],
        ),
      ],
      topScorers: const [
        LeagueScorerModel(
          rank: 1,
          athleteId: '101',
          playerName: 'Goleador Estrella',
          teamId: '83',
          teamName: 'Barcelona Real',
          goals: 11,
          playedGames: 9,
          assists: 4,
        ),
      ],
    );

    final mockNoCoverageDetail = LeagueDetailModel.empty(
      leagueSlug: 'sin-cobertura',
      leagueName: 'Liga Secundaria',
      leagueId: 'league-sec',
    );

    Future<void> pumpAndFlush(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 200));
    }

    testWidgets('Muestra tabla real y NO contiene "Equipo A" ni disclaimer de demostración', (tester) async {
      final container = ProviderContainer(
        overrides: [
          leagueDetailProvider.overrideWith((ref, params) async => mockRealDetail),
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
              leagueId: 'league-esp1',
            ),
          ),
        ),
      );

      await pumpAndFlush(tester);

      // Cambiar a la pestaña "Tabla"
      await tester.tap(find.text('Tabla'));
      await pumpAndFlush(tester);

      // Verificar que los datos reales se muestran
      expect(find.text('Barcelona Real'), findsOneWidget);
      expect(find.text('Real Madrid'), findsOneWidget);
      expect(find.text('28'), findsOneWidget);
      expect(find.text('+24'), findsOneWidget);

      // Verificar que los datos ficticios y etiquetas de demostración fueron eliminados por completo
      expect(find.text('Equipo A'), findsNothing);
      expect(find.text('Equipo B'), findsNothing);
      expect(find.text('Equipo C'), findsNothing);
      expect(find.textContaining('demostración'), findsNothing);
      expect(find.textContaining('demo'), findsNothing);
    });

    testWidgets('Muestra goleadores reales en pestaña Estadísticas y elimina "Jugador 1"', (tester) async {
      final container = ProviderContainer(
        overrides: [
          leagueDetailProvider.overrideWith((ref, params) async => mockRealDetail),
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
              leagueId: 'league-esp1',
            ),
          ),
        ),
      );

      await pumpAndFlush(tester);

      // Cambiar a la pestaña "Estadísticas"
      await tester.tap(find.text('Estadísticas'));
      await pumpAndFlush(tester);

      // Verificar que el goleador real se muestra
      expect(find.text('GOLEADORES'), findsOneWidget);
      expect(find.text('Goleador Estrella'), findsOneWidget);
      expect(find.text('11 G'), findsOneWidget);

      // Verificar que las filas de demostración fueron eliminadas
      expect(find.text('Jugador 1'), findsNothing);
      expect(find.text('Jugador 2'), findsNothing);
    });

    testWidgets('Liga sin cobertura muestra estado "no disponible" claro en Tabla y Estadísticas', (tester) async {
      final container = ProviderContainer(
        overrides: [
          leagueDetailProvider.overrideWith((ref, params) async => mockNoCoverageDetail),
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
              leagueName: 'Liga Secundaria',
              sport: SportType.soccer,
              leagueSlug: 'sin-cobertura',
              leagueId: 'league-sec',
            ),
          ),
        ),
      );

      await pumpAndFlush(tester);

      // Verificar pestaña Tabla sin cobertura
      await tester.tap(find.text('Tabla'));
      await pumpAndFlush(tester);

      expect(find.text('Posiciones no disponibles'), findsOneWidget);
      expect(find.text('Equipo A'), findsNothing);

      // Verificar pestaña Estadísticas sin cobertura
      await tester.tap(find.text('Estadísticas'));
      await pumpAndFlush(tester);

      expect(find.text('Goleadores no disponibles'), findsOneWidget);
      expect(find.text('Jugador 1'), findsNothing);
    });

    testWidgets('Pestaña partidos conserva el filtro correcto por liga y temporada', (tester) async {
      final sampleEvents = [
        EventModel(
          id: 'event-1',
          sport: SportType.soccer,
          league: 'LaLiga',
          leagueModel: const LeagueModel(
            id: 'league-esp1',
            name: 'LaLiga',
            slug: 'esp.1',
          ),
          seasonModel: const SeasonModel(
            id: 'season-2024',
            name: 'Temporada 2024-2025',
            slug: '2024-2025',
          ),
          status: EventStatus.scheduled,
          startTime: DateTime.now().add(const Duration(hours: 2)),
          homeTeam: const TeamModel(id: '1', name: 'Barcelona Real'),
          awayTeam: const TeamModel(id: '2', name: 'Real Madrid'),
        ),
        EventModel(
          id: 'event-2',
          sport: SportType.soccer,
          league: 'Premier League',
          leagueModel: const LeagueModel(
            id: 'league-eng1',
            name: 'Premier League',
            slug: 'eng.1',
          ),
          seasonModel: const SeasonModel(
            id: 'season-2024',
            name: 'Temporada 2024-2025',
            slug: '2024-2025',
          ),
          status: EventStatus.scheduled,
          startTime: DateTime.now().add(const Duration(hours: 3)),
          homeTeam: const TeamModel(id: '3', name: 'Arsenal'),
          awayTeam: const TeamModel(id: '4', name: 'Chelsea'),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          leagueDetailProvider.overrideWith((ref, params) async => mockRealDetail),
          feedRepositoryProvider.overrideWithValue(FakeFeedRepository(sampleEvents)),
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
              leagueId: 'league-esp1',
              seasonId: 'season-2024',
            ),
          ),
        ),
      );

      await pumpAndFlush(tester);

      // Cambiar a la pestaña "Partidos"
      await tester.tap(find.text('Partidos'));
      await pumpAndFlush(tester);

      expect(find.text('Barcelona Real'), findsOneWidget);
      expect(find.text('Real Madrid'), findsOneWidget);

      // El partido de Premier League no debe aparecer porque está filtrado
      expect(find.text('Arsenal'), findsNothing);
      expect(find.text('Chelsea'), findsNothing);
    });
  });
}
