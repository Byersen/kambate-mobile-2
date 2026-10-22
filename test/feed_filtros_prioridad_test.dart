import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kambate_mobile/core/utils/football_competition_priority.dart';
import 'package:kambate_mobile/features/feed/data/feed_repository.dart';
import 'package:kambate_mobile/features/feed/presentation/screens/feed_screen.dart';
import 'package:kambate_mobile/features/feed/presentation/widgets/scoreboard_row.dart';
import 'package:kambate_mobile/features/feed/presentation/widgets/sport_filter_bar.dart';
import 'package:kambate_mobile/features/feed/providers/feed_provider.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'package:kambate_mobile/models/event_status.dart';
import 'package:kambate_mobile/models/fighter_model.dart';
import 'package:kambate_mobile/models/league_model.dart';
import 'package:kambate_mobile/models/participant_model.dart';
import 'package:kambate_mobile/models/sport_type.dart';
import 'package:kambate_mobile/models/team_model.dart';
import 'support/preview.dart';

class _MockFeedRepository extends FeedRepository {
  _MockFeedRepository(this.events) : super(subscribeToRealtime: false);
  final List<EventModel> events;

  @override
  Future<List<EventModel>> fetchRemoteEvents() async => events;

  @override
  Future<EventModel?> getEventById(String id) async {
    return events.cast<EventModel?>().firstWhere(
      (e) => e?.id == id || e?.externalId == id,
      orElse: () => null,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPreviewFonts);

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({
      'kambate_onboarding_completed_v1': true,
    });
  });

  EventModel buildMatch({
    required String id,
    required SportType sport,
    required String league,
    LeagueModel? leagueModel,
    required DateTime startTime,
    EventStatus status = EventStatus.scheduled,
    String homeName = 'Equipo Local',
    String awayName = 'Equipo Visitante',
    int? homeScore,
    int? awayScore,
  }) {
    return EventModel(
      id: id,
      sport: sport,
      league: league,
      leagueModel: leagueModel,
      status: status,
      startTime: startTime,
      homeTeam: TeamModel(id: 'h-$id', name: homeName),
      awayTeam: TeamModel(id: 'a-$id', name: awayName),
      homeScore: homeScore,
      awayScore: awayScore,
      fighter1: sport == SportType.ufc ? FighterModel(id: 'f1-$id', name: homeName) : null,
      fighter2: sport == SportType.ufc ? FighterModel(id: 'f2-$id', name: awayName) : null,
      participants: [
        ParticipantModel(id: 'p1-$id', name: homeName),
        ParticipantModel(id: 'p2-$id', name: awayName),
      ],
    );
  }

  group('Deporte inicial en Feed y Providers', () {
    test('selectedSportFilterProvider inicia por defecto en Fútbol (SportType.soccer)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(selectedSportFilterProvider), equals(SportType.soccer));
    });

    testWidgets('FeedScreen renderiza inicialmente sólo eventos de Fútbol', (tester) async {
      final now = DateTime.now();
      final soccerEvent = buildMatch(
        id: 'ev-soccer-init',
        sport: SportType.soccer,
        league: 'LaLiga',
        startTime: DateTime(now.year, now.month, now.day, 16, 0),
        homeName: 'Real Madrid',
        awayName: 'Barcelona',
      );
      final nbaEvent = buildMatch(
        id: 'ev-nba-init',
        sport: SportType.nba,
        league: 'NBA',
        startTime: DateTime(now.year, now.month, now.day, 21, 0),
        homeName: 'Lakers',
        awayName: 'Warriors',
      );

      final repo = _MockFeedRepository([soccerEvent, nbaEvent]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: FeedScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Fútbol visible
      expect(find.text('Real Madrid'), findsOneWidget);
      expect(find.text('Barcelona'), findsOneWidget);

      // NBA no visible por defecto
      expect(find.text('Lakers'), findsNothing);
      expect(find.text('Warriors'), findsNothing);
    });
  });

  group('Ausencia de la opción deportiva "Todos" y oferta de los 5 deportes', () {
    test('SportFilterBar.supportedSports contiene exactamente 5 deportes sin Todos', () {
      expect(SportFilterBar.supportedSports, equals([
        SportType.soccer,
        SportType.nba,
        SportType.ufc,
        SportType.lol,
        SportType.valorant,
      ]));
      expect(SportFilterBar.supportedSports.contains(SportType.all), isFalse);
    });

    testWidgets('SportFilterBar no muestra "Todos" pero sí Fútbol, NBA, UFC, LoL y Valorant', (tester) async {
      SportType currentSport = SportType.soccer;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SportFilterBar(
                  selectedSport: currentSport,
                  onSportSelected: (sport) => setState(() => currentSport = sport),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final barFinder = find.byType(SportFilterBar);
      expect(find.descendant(of: barFinder, matching: find.text('Todos')), findsNothing);
      expect(find.descendant(of: barFinder, matching: find.text('Fútbol')), findsOneWidget);
      expect(find.descendant(of: barFinder, matching: find.text('NBA')), findsOneWidget);
      expect(find.descendant(of: barFinder, matching: find.text('UFC')), findsOneWidget);
      expect(find.descendant(of: barFinder, matching: find.text('LoL')), findsOneWidget);
      expect(find.descendant(of: barFinder, matching: find.text('Valorant')), findsOneWidget);
    });

    testWidgets('El selector de estados en FeedScreen sí conserva la opción "Todos"', (tester) async {
      final now = DateTime.now();
      final event = buildMatch(
        id: 'ev-soccer-status',
        sport: SportType.soccer,
        league: 'Premier League',
        startTime: DateTime(now.year, now.month, now.day, 14, 0),
        homeName: 'Arsenal',
        awayName: 'Chelsea',
      );

      final repo = _MockFeedRepository([event]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: FeedScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Existe ChoiceChip 'Todos' para los estados
      expect(find.widgetWithText(ChoiceChip, 'Todos'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'En vivo'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Próximos'), findsOneWidget);
    });
  });

  group('Selección exclusiva por deporte', () {
    testWidgets('Cada selección muestra únicamente eventos de ese deporte', (tester) async {
      final now = DateTime.now();
      final soccer = buildMatch(
        id: 's-1',
        sport: SportType.soccer,
        league: 'LaLiga',
        startTime: DateTime(now.year, now.month, now.day, 12, 0),
        homeName: 'Betis',
        awayName: 'Sevilla',
      );
      final nba = buildMatch(
        id: 'n-1',
        sport: SportType.nba,
        league: 'NBA',
        startTime: DateTime(now.year, now.month, now.day, 13, 0),
        homeName: 'Bulls',
        awayName: 'Heat',
      );
      final ufc = buildMatch(
        id: 'u-1',
        sport: SportType.ufc,
        league: 'UFC',
        startTime: DateTime(now.year, now.month, now.day, 14, 0),
        homeName: 'Topuria',
        awayName: 'Holloway',
      );
      final lol = buildMatch(
        id: 'l-1',
        sport: SportType.lol,
        league: 'LCK',
        startTime: DateTime(now.year, now.month, now.day, 15, 0),
        homeName: 'T1',
        awayName: 'Gen.G',
      );
      final valorant = buildMatch(
        id: 'v-1',
        sport: SportType.valorant,
        league: 'VCT Americas',
        startTime: DateTime(now.year, now.month, now.day, 16, 0),
        homeName: 'Sentinels',
        awayName: 'LOUD',
      );

      final repo = _MockFeedRepository([soccer, nba, ufc, lol, valorant]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: FeedScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Inicial: Fútbol
      expect(find.text('Betis'), findsOneWidget);
      expect(find.text('Bulls'), findsNothing);
      expect(find.text('Topuria'), findsNothing);
      expect(find.text('T1'), findsNothing);
      expect(find.text('Sentinels'), findsNothing);

      // 2. Tocar NBA
      await tester.tap(find.text('NBA').first);
      await tester.pumpAndSettle();
      expect(find.text('Bulls'), findsOneWidget);
      expect(find.text('Betis'), findsNothing);
      expect(find.text('Topuria'), findsNothing);

      // 3. Tocar UFC
      await tester.tap(find.text('UFC').first);
      await tester.pumpAndSettle();
      expect(find.text('Topuria'), findsOneWidget);
      expect(find.text('Bulls'), findsNothing);
      expect(find.text('T1'), findsNothing);

      // 4. Tocar LoL
      await tester.tap(find.text('LoL').first);
      await tester.pumpAndSettle();
      expect(find.text('T1'), findsOneWidget);
      expect(find.text('Topuria'), findsNothing);
      expect(find.text('Sentinels'), findsNothing);

      // 5. Tocar Valorant
      await tester.tap(find.text('Valorant').first);
      await tester.pumpAndSettle();
      expect(find.text('Sentinels'), findsOneWidget);
      expect(find.text('T1'), findsNothing);
      expect(find.text('Betis'), findsNothing);
    });
  });

  group('Prioridad de ligas de fútbol', () {
    test('Jerarquía estricta de las 10 ligas y las demás en FootballCompetitionPriority', () {
      final uclPrio = FootballCompetitionPriority.getLeaguePriority('UEFA Champions League');
      final uelPrio = FootballCompetitionPriority.getLeaguePriority('UEFA Europa League');
      final premierPrio = FootballCompetitionPriority.getLeaguePriority('Premier League');
      final laligaPrio = FootballCompetitionPriority.getLeaguePriority('LaLiga');
      final serieAPrio = FootballCompetitionPriority.getLeaguePriority('Serie A');
      final bundesligaPrio = FootballCompetitionPriority.getLeaguePriority('Bundesliga');
      final ligue1Prio = FootballCompetitionPriority.getLeaguePriority('Ligue 1');
      final chilePrio = FootballCompetitionPriority.getLeaguePriority('Primera División de Chile');
      final argPrio = FootballCompetitionPriority.getLeaguePriority('Liga Profesional');
      final braPrio = FootballCompetitionPriority.getLeaguePriority('Brasileirão');
      final otherPrio = FootballCompetitionPriority.getLeaguePriority('MLS');

      expect(uclPrio, equals(0));
      expect(uelPrio, equals(1));
      expect(premierPrio, equals(2));
      expect(laligaPrio, equals(3));
      expect(serieAPrio, equals(4));
      expect(bundesligaPrio, equals(5));
      expect(ligue1Prio, equals(6));
      expect(chilePrio, equals(7));
      expect(argPrio, equals(8));
      expect(braPrio, equals(9));
      expect(otherPrio, equals(10));

      expect(uclPrio < uelPrio, isTrue);
      expect(uelPrio < premierPrio, isTrue);
      expect(premierPrio < laligaPrio, isTrue);
      expect(laligaPrio < serieAPrio, isTrue);
      expect(serieAPrio < bundesligaPrio, isTrue);
      expect(bundesligaPrio < ligue1Prio, isTrue);
      expect(ligue1Prio < chilePrio, isTrue);
      expect(chilePrio < argPrio, isTrue);
      expect(argPrio < braPrio, isTrue);
      expect(braPrio < otherPrio, isTrue);
    });

    test('Ordena una lista de partidos de fútbol respetando el orden de competiciones', () {
      final now = DateTime.now();

      final matches = [
        buildMatch(
          id: 'mls',
          sport: SportType.soccer,
          league: 'MLS',
          startTime: DateTime(now.year, now.month, now.day, 10, 0),
        ),
        buildMatch(
          id: 'bra',
          sport: SportType.soccer,
          league: 'Brasileirão',
          startTime: DateTime(now.year, now.month, now.day, 11, 0),
        ),
        buildMatch(
          id: 'arg',
          sport: SportType.soccer,
          league: 'Liga Profesional',
          startTime: DateTime(now.year, now.month, now.day, 12, 0),
        ),
        buildMatch(
          id: 'chi',
          sport: SportType.soccer,
          league: 'Primera División de Chile',
          startTime: DateTime(now.year, now.month, now.day, 13, 0),
        ),
        buildMatch(
          id: 'fra',
          sport: SportType.soccer,
          league: 'Ligue 1',
          startTime: DateTime(now.year, now.month, now.day, 14, 0),
        ),
        buildMatch(
          id: 'ger',
          sport: SportType.soccer,
          league: 'Bundesliga',
          startTime: DateTime(now.year, now.month, now.day, 15, 0),
        ),
        buildMatch(
          id: 'ita',
          sport: SportType.soccer,
          league: 'Serie A',
          startTime: DateTime(now.year, now.month, now.day, 16, 0),
        ),
        buildMatch(
          id: 'esp',
          sport: SportType.soccer,
          league: 'LaLiga',
          startTime: DateTime(now.year, now.month, now.day, 17, 0),
        ),
        buildMatch(
          id: 'eng',
          sport: SportType.soccer,
          league: 'Premier League',
          startTime: DateTime(now.year, now.month, now.day, 18, 0),
        ),
        buildMatch(
          id: 'uel',
          sport: SportType.soccer,
          league: 'UEFA Europa League',
          startTime: DateTime(now.year, now.month, now.day, 19, 0),
        ),
        buildMatch(
          id: 'ucl',
          sport: SportType.soccer,
          league: 'UEFA Champions League',
          startTime: DateTime(now.year, now.month, now.day, 20, 0),
        ),
      ];

      final sorted = FootballCompetitionPriority.sortEvents(matches);
      final sortedIds = sorted.map((e) => e.id).toList();

      expect(sortedIds, equals([
        'ucl',
        'uel',
        'eng',
        'esp',
        'ita',
        'ger',
        'fra',
        'chi',
        'arg',
        'bra',
        'mls',
      ]));
    });
  });

  group('Desempate por hora dentro de cada grupo', () {
    test('Partidos de la misma liga se ordenan de forma estable por hora', () {
      final now = DateTime.now();

      final matchUclLate = buildMatch(
        id: 'ucl-2100',
        sport: SportType.soccer,
        league: 'UEFA Champions League',
        startTime: DateTime(now.year, now.month, now.day, 21, 0),
      );
      final matchUclEarly = buildMatch(
        id: 'ucl-1845',
        sport: SportType.soccer,
        league: 'UEFA Champions League',
        startTime: DateTime(now.year, now.month, now.day, 18, 45),
      );
      final matchPremierLate = buildMatch(
        id: 'pl-1500',
        sport: SportType.soccer,
        league: 'Premier League',
        startTime: DateTime(now.year, now.month, now.day, 15, 0),
      );
      final matchPremierEarly = buildMatch(
        id: 'pl-1230',
        sport: SportType.soccer,
        league: 'Premier League',
        startTime: DateTime(now.year, now.month, now.day, 12, 30),
      );

      // Entrada en orden aleatorio
      final input = [matchPremierLate, matchUclLate, matchPremierEarly, matchUclEarly];
      final sorted = FootballCompetitionPriority.sortEvents(input);

      // Debe ordenar: grupo UCL (18:45, luego 21:00), y luego grupo Premier (12:30, luego 15:00)
      expect(sorted.map((e) => e.id).toList(), equals([
        'ucl-1845',
        'ucl-2100',
        'pl-1230',
        'pl-1500',
      ]));
    });

    test('Ligas con igual prioridad (en las demás) desempatan por la hora del primer partido', () {
      final now = DateTime.now();

      final matchLibertadores = buildMatch(
        id: 'libertadores-2000',
        sport: SportType.soccer,
        league: 'Copa Libertadores',
        startTime: DateTime(now.year, now.month, now.day, 20, 0),
      );
      final matchMls = buildMatch(
        id: 'mls-1800',
        sport: SportType.soccer,
        league: 'MLS',
        startTime: DateTime(now.year, now.month, now.day, 18, 0),
      );

      final sorted = FootballCompetitionPriority.sortEvents([matchLibertadores, matchMls]);
      expect(sorted.map((e) => e.id).toList(), equals(['mls-1800', 'libertadores-2000']));
    });

    test('Partidos con la misma hora conservan desempate determinista por ID', () {
      final now = DateTime.now();

      final matchA = buildMatch(
        id: 'match-a',
        sport: SportType.soccer,
        league: 'LaLiga',
        startTime: DateTime(now.year, now.month, now.day, 16, 0),
      );
      final matchB = buildMatch(
        id: 'match-b',
        sport: SportType.soccer,
        league: 'LaLiga',
        startTime: DateTime(now.year, now.month, now.day, 16, 0),
      );

      final sorted = FootballCompetitionPriority.sortEvents([matchB, matchA]);
      expect(sorted.map((e) => e.id).toList(), equals(['match-a', 'match-b']));
    });
  });

  group('Eliminación del bloque alto "Tu jornada deportiva"', () {
    testWidgets('FeedScreen no renderiza el bloque alto ni el texto "Tu jornada deportiva"', (tester) async {
      final now = DateTime.now();
      final match = buildMatch(
        id: 'ev-test-1',
        sport: SportType.soccer,
        league: 'LaLiga',
        startTime: DateTime(now.year, now.month, now.day, 16, 0),
        homeName: 'Girona',
        awayName: 'Valencia',
      );

      final repo = _MockFeedRepository([match]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: FeedScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // 'Tu jornada deportiva' no debe existir
      expect(find.text('Tu jornada deportiva'), findsNothing);

      // El partido y filtros sí están visibles en pantalla
      expect(find.text('Girona'), findsOneWidget);
      expect(find.byType(SportFilterBar), findsOneWidget);
      expect(find.byType(ScoreboardRow), findsOneWidget);
    });

    testWidgets('Al navegar a fecha anterior, "Ir a hoy" se ofrece de forma compacta sin bloque alto', (tester) async {
      final now = DateTime.now();
      final todayMatch = buildMatch(
        id: 'today-1',
        sport: SportType.soccer,
        league: 'LaLiga',
        startTime: DateTime(now.year, now.month, now.day, 16, 0),
        homeName: 'Hoy Equipo 1',
        awayName: 'Hoy Equipo 2',
      );
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final yesterdayMatch = buildMatch(
        id: 'yesterday-1',
        sport: SportType.soccer,
        league: 'LaLiga',
        status: EventStatus.finished,
        startTime: DateTime(yesterday.year, yesterday.month, yesterday.day, 16, 0),
        homeName: 'Ayer Equipo 1',
        awayName: 'Ayer Equipo 2',
      );

      final repo = _MockFeedRepository([todayMatch, yesterdayMatch]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: FeedScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Hoy: no muestra botón Ir a hoy
      expect(find.text('Ir a hoy'), findsNothing);

      // Navegar a ayer
      await tester.tap(find.byTooltip('Día anterior'));
      await tester.pumpAndSettle();

      // En ayer: muestra Ir a hoy pero NO 'Tu jornada deportiva'
      expect(find.text('Ir a hoy'), findsOneWidget);
      expect(find.text('Tu jornada deportiva'), findsNothing);
      expect(find.text('Ayer Equipo 1'), findsOneWidget);

      // Tocar Ir a hoy
      await tester.tap(find.text('Ir a hoy'));
      await tester.pumpAndSettle();

      expect(find.text('Hoy Equipo 1'), findsOneWidget);
      expect(find.text('Ayer Equipo 1'), findsNothing);
    });
  });
}
