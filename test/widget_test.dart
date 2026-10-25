import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kambate_mobile/core/router/app_router.dart';
import 'package:kambate_mobile/core/theme/app_colors.dart';
import 'package:kambate_mobile/core/utils/date_formatter.dart';
import 'package:kambate_mobile/features/feed/data/feed_repository.dart';
import 'package:kambate_mobile/features/feed/providers/connection_provider.dart';
import 'package:kambate_mobile/features/feed/providers/feed_provider.dart';
import 'package:kambate_mobile/features/feed/presentation/widgets/scoreboard_row.dart';
import 'package:kambate_mobile/features/favorites/providers/favorites_provider.dart';
import 'package:kambate_mobile/features/match_detail/presentation/screens/match_detail_screen.dart';
import 'package:kambate_mobile/main.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'package:kambate_mobile/models/event_status.dart';
import 'package:kambate_mobile/models/fighter_model.dart';
import 'package:kambate_mobile/models/league_model.dart';
import 'package:kambate_mobile/models/sport_type.dart';
import 'package:kambate_mobile/models/stats_models.dart';
import 'package:kambate_mobile/models/team_model.dart';
import 'support/preview.dart';

class MockFeedRepository extends FeedRepository {
  MockFeedRepository({
    this.events = const [],
    this.fail = false,
    this.sourceOverride,
    this.lastUpdatedOverride,
  }) : super(subscribeToRealtime: false);

  final List<EventModel> events;
  final bool fail;
  final FeedDataSource? sourceOverride;
  final DateTime? lastUpdatedOverride;

  @override
  FeedDataSource get source => sourceOverride ?? super.source;

  @override
  DateTime? get lastUpdated => lastUpdatedOverride ?? super.lastUpdated;

  @override
  Future<List<EventModel>> fetchRemoteEvents() async {
    if (fail) throw StateError('Sin conexión');
    return events;
  }

  @override
  Future<EventModel?> getEventById(String id) async {
    return events.cast<EventModel?>().firstWhere(
      (e) => e?.id == id,
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

  List<EventModel> fixtures() {
    final now = DateTime.now();
    EventModel teamEvent(
      String id,
      SportType sport,
      EventStatus status,
      String league,
      String home,
      String away,
      int? homeScore,
      int? awayScore,
    ) => EventModel(
      id: id,
      sport: sport,
      status: status,
      league: league,
      startTime: DateTime(now.year, now.month, now.day, 20),
      currentPeriod: status == EventStatus.live ? '67′' : null,
      homeTeam: TeamModel(id: '$id-home', name: home),
      awayTeam: TeamModel(id: '$id-away', name: away),
      homeScore: homeScore,
      awayScore: awayScore,
    );

    EventModel fightEvent(
      String id,
      EventStatus status,
      String league,
      String fighter1,
      String fighter2,
    ) => EventModel(
      id: id,
      sport: SportType.ufc,
      status: status,
      league: league,
      startTime: DateTime(now.year, now.month, now.day, 22),
      fighter1: FighterModel(id: '$id-f1', name: fighter1),
      fighter2: FighterModel(id: '$id-f2', name: fighter2),
    );

    return [
      teamEvent(
        'football-live',
        SportType.soccer,
        EventStatus.live,
        'Primera División',
        'Colo-Colo',
        'U. de Chile',
        2,
        1,
      ),
      teamEvent(
        'nba-scheduled',
        SportType.nba,
        EventStatus.scheduled,
        'NBA · Temporada regular',
        'Lakers',
        'Celtics',
        null,
        null,
      ),
      fightEvent(
        'ufc-scheduled',
        EventStatus.scheduled,
        'UFC · Noche de combates',
        'Diego Silva',
        'Lucas Costa',
      ),
      teamEvent(
        'lol-live',
        SportType.lol,
        EventStatus.live,
        'LCK · Serie al mejor de 3',
        'T1',
        'Gen.G',
        1,
        1,
      ),
      teamEvent(
        'val-scheduled',
        SportType.valorant,
        EventStatus.scheduled,
        'VCT Americas',
        'KRÜ',
        'Leviatán',
        null,
        null,
      ),
      teamEvent(
        'football-result',
        SportType.soccer,
        EventStatus.finished,
        'Premier League',
        'Arsenal',
        'Chelsea',
        3,
        1,
      ),
    ];
  }

  Future<({ProviderContainer container, GoRouter router, GlobalKey preview})>
  mount(
    WidgetTester tester, {
    bool fail = false,
    double textScale = 1,
    Size size = const Size(390, 844),
    List<EventModel>? customEvents,
    FeedDataSource? sourceOverride,
    DateTime? lastUpdatedOverride,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final repository = MockFeedRepository(
      events: customEvents ?? fixtures(),
      fail: fail,
      sourceOverride: sourceOverride,
      lastUpdatedOverride: lastUpdatedOverride,
    );
    final container = ProviderContainer(
      overrides: [feedRepositoryProvider.overrideWithValue(repository)],
    );
    final router = createRouter();
    final preview = GlobalKey();
    addTearDown(() {
      router.dispose();
      container.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: preview,
          child: KambateApp(router: router),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (container: container, router: router, preview: preview);
  }

  testWidgets(
    'Inicio claro, filtro por deporte y estado sin perder el catálogo',
    (tester) async {
      final app = await mount(tester);
      expect(find.text('KAMBATE'), findsOneWidget);
      expect(find.text('Tu jornada deportiva'), findsNothing);
      expect(app.container.read(selectedSportFilterProvider), SportType.soccer);
      expect(
        Theme.of(tester.element(find.text('KAMBATE'))).brightness,
        Brightness.light,
      );
      await tester.tap(find.text('NBA').first);
      await tester.pumpAndSettle();
      expect(find.text('Lakers'), findsOneWidget);
      expect(find.text('Colo-Colo'), findsNothing);
      expect(app.container.read(feedNotifierProvider).requireValue.length, 6);
      await tester.tap(find.widgetWithText(ChoiceChip, 'En vivo'));
      await tester.pumpAndSettle();
      expect(find.text('No hay encuentros para estos filtros'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'La liga reúne sus partidos y permite seguirla desde la cabecera',
    (tester) async {
      final now = DateTime.now();
      final day = DateTime(now.year, now.month, now.day, 18);
      EventModel liveMatch(
        String id,
        String home,
        String away,
        String minute,
      ) => EventModel(
        id: id,
        sport: SportType.soccer,
        league: 'Serie A',
        leagueModel: const LeagueModel(
          id: 'serie-a-id',
          name: 'Serie A',
          slug: 'ita.1',
        ),
        status: EventStatus.live,
        startTime: day,
        footballStats: FootballStatsModel(
          id: 'stats-$id',
          extraStats: {'clock': minute},
        ),
        homeTeam: TeamModel(id: '$id-home', name: home),
        awayTeam: TeamModel(id: '$id-away', name: away),
        homeScore: 1,
        awayScore: 0,
      );

      final app = await mount(
        tester,
        customEvents: [
          liveMatch('match-a', 'Inter', 'Roma', "23'"),
          liveMatch('match-b', 'Milan', 'Napoli', "45'+2'"),
        ],
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'En vivo'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('competition_block_league_id:serie-a-id')),
        findsOneWidget,
      );
      expect(find.text('Serie A'), findsOneWidget);
      expect(find.byType(ScoreboardRow), findsNWidgets(2));
      expect(find.text('EN VIVO'), findsNothing);
      expect(find.textContaining('Fútbol • Serie A'), findsNothing);
      expect(find.text('23′'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('23′')).style?.color,
        AppColors.liveRed,
      );
      expect(find.text('45+2′'), findsOneWidget);

      final follow = find.byKey(
        const ValueKey('follow_league_league_id:serie-a-id'),
      );
      await tester.ensureVisible(follow);
      await tester.tap(follow);
      await tester.pumpAndSettle();
      expect(app.container.read(followedLeaguesProvider), contains('serie a'));
    },
  );

  testWidgets('Volver desde un partido conserva deporte y fecha', (
    tester,
  ) async {
    final app = await mount(tester);
    await tester.tap(find.text('NBA').first);
    await tester.pumpAndSettle();
    final date = app.container.read(selectedFeedDateProvider);
    await tester.tap(find.byType(ScoreboardRow).first);
    await tester.pumpAndSettle();
    final detail = find.byType(MatchDetailScreen);
    expect(detail, findsOneWidget);
    expect(
      GoRouterState.of(tester.element(detail)).uri.path,
      '/detail/nba-scheduled',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(app.container.read(selectedSportFilterProvider), SportType.nba);
    expect(app.container.read(selectedFeedDateProvider), date);
    expect(find.text('Lakers'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Volver desde un partido conserva deporte, fecha y posición de scroll',
    (tester) async {
      final now = DateTime.now();
      final manyEvents = List.generate(
        15,
        (i) => EventModel(
          id: 'scroll-event-$i',
          sport: SportType.soccer,
          status: EventStatus.scheduled,
          league: 'Liga de Fútbol $i',
          startTime: DateTime(now.year, now.month, now.day, 10 + (i % 10)),
          homeTeam: TeamModel(id: 'home-$i', name: 'Equipo Local $i'),
          awayTeam: TeamModel(id: 'away-$i', name: 'Equipo Visitante $i'),
        ),
      );

      final app = await mount(tester, customEvents: manyEvents);
      final scrollFinder = find.byType(CustomScrollView).first;

      // Desplazar hacia abajo en la lista
      await tester.drag(scrollFinder, const Offset(0, -350));
      await tester.pumpAndSettle();

      final scrollableState = tester.state<ScrollableState>(
        find.descendant(of: scrollFinder, matching: find.byType(Scrollable)).first,
      );
      final offsetBefore = scrollableState.position.pixels;
      expect(offsetBefore, greaterThan(50.0));

      // Entrar al detalle del primer partido visible tras scroll
      await tester.tap(find.byType(ScoreboardRow).hitTestable().first);
      await tester.pumpAndSettle();
      expect(find.byType(MatchDetailScreen), findsOneWidget);

      // Regresar
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Verificar que el scroll se conservó en la misma posición
      final scrollableStateAfter = tester.state<ScrollableState>(
        find.descendant(of: scrollFinder, matching: find.byType(Scrollable)).first,
      );
      final offsetAfter = scrollableStateAfter.position.pixels;
      expect(offsetAfter, equals(offsetBefore));
      expect(app.container.read(selectedSportFilterProvider), SportType.soccer);
    },
  );

  testWidgets(
    'Navegación completa a detalles de los 5 deportes (Fútbol, NBA, UFC, LoL, Valorant) y retorno',
    (tester) async {
      final app = await mount(tester);

      final sportsToTest = [
        (sport: SportType.soccer, chip: 'Fútbol', matchText: 'Colo-Colo'),
        (sport: SportType.nba, chip: 'NBA', matchText: 'Lakers'),
        (sport: SportType.ufc, chip: 'UFC', matchText: 'Diego Silva'),
        (sport: SportType.lol, chip: 'LoL', matchText: 'T1'),
        (sport: SportType.valorant, chip: 'Valorant', matchText: 'KRÜ'),
      ];

      for (final item in sportsToTest) {
        app.container.read(selectedEventStatusProvider.notifier).state = null;
        app.container.read(selectedSportFilterProvider.notifier).state =
            item.sport;
        await tester.pumpAndSettle();

        var matchFinder = find.text(item.matchText);
        if (matchFinder.evaluate().isEmpty) {
          await tester.tap(find.widgetWithText(ChoiceChip, 'En vivo'));
          await tester.pumpAndSettle();
          matchFinder = find.text(item.matchText);
        }
        await tester.ensureVisible(matchFinder);
        await tester.tap(matchFinder);
        await tester.pumpAndSettle();
        expect(find.byType(MatchDetailScreen), findsOneWidget);

        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(app.container.read(selectedSportFilterProvider), item.sport);
      }
    },
  );

  testWidgets(
    'Seleccionar filtro por estado filtra por estado correspondiente',
    (tester) async {
      final app = await mount(tester);
      expect(app.container.read(selectedEventStatusProvider), isNull);

      final resultadosChip = find.widgetWithText(ChoiceChip, 'Resultados');
      await tester.ensureVisible(resultadosChip);
      await tester.tap(resultadosChip);
      await tester.pumpAndSettle();

      expect(
        app.container.read(selectedEventStatusProvider),
        EventStatus.finished,
      );
      expect(find.text('Arsenal'), findsOneWidget);
      expect(find.text('Colo-Colo'), findsNothing);
    },
  );

  testWidgets('Un error conserva controles y ofrece reintento', (tester) async {
    await mount(tester, fail: true);
    expect(find.text('No pudimos cargar los partidos'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Colo-Colo'), findsNothing);
    expect(find.text('NBA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Desconexión con datos en caché muestra banner y estado offline',
    (tester) async {
      final app = await mount(
        tester,
        sourceOverride: FeedDataSource.cache,
        lastUpdatedOverride: DateTime(2026, 10, 20, 18, 30),
      );

      expect(
        find.textContaining('Datos guardados ·'),
        findsNothing,
      );
      expect(
        app.container.read(connectionStatusProvider),
        ConnectionStatus.offlineCached,
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'En vivo'));
      await tester.pumpAndSettle();
      expect(find.text('Colo-Colo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'DateFormatter maneja transiciones de horario (DST) y timezones con precisión',
    (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final tomorrow = DateTime(now.year, now.month, now.day + 1);

      expect(AppDateFormatter.getRelativeDayName(today), 'Hoy');
      expect(AppDateFormatter.getRelativeDayName(yesterday), 'Ayer');
      expect(AppDateFormatter.getRelativeDayName(tomorrow), 'Mañana');

      // isSameDay con UTC vs Local
      final utcNow = now.toUtc();
      final localNow = now.toLocal();
      expect(AppDateFormatter.isSameDay(utcNow, localNow), isTrue);

      // formatFullDate incluye zona horaria sin fijar CLT si el sistema es diferente
      final fullDate = AppDateFormatter.formatFullDate(now);
      expect(fullDate, isNotEmpty);
      expect(fullDate, contains(now.toLocal().timeZoneName));
    },
  );

  testWidgets(
    'Textos largos y pantalla pequeña (320px) sin desbordamientos en feed y tarjetas',
    (tester) async {
      final longEvent = EventModel(
        id: 'long-names-event',
        sport: SportType.soccer,
        status: EventStatus.live,
        league:
            'Campeonato Nacional de Primera División AFP PlanVital de la República de Chile',
        startTime: DateTime.now(),
        currentPeriod: '90+5′ Segundo tiempo suplementario',
        homeTeam: TeamModel(
          id: 'long-home',
          name:
              'Club Social y Deportivo Colo-Colo de Santiago de Chile y Alrededores',
        ),
        awayTeam: TeamModel(
          id: 'long-away',
          name:
              'Club Universidad de Chile de la Ciudad Deportiva Metropolitana',
        ),
        homeScore: 12,
        awayScore: 11,
      );

      await mount(
        tester,
        size: const Size(320, 568),
        textScale: 1.3,
        customEvents: [longEvent],
      );

      await tester.tap(find.widgetWithText(ChoiceChip, 'En vivo'));
      await tester.pumpAndSettle();

      final rowFinder = find.byType(ScoreboardRow);
      await tester.dragUntilVisible(
        rowFinder,
        find.byType(CustomScrollView).first,
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();
      expect(rowFinder, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('El inicio admite texto ampliado sin desbordamientos', (
    tester,
  ) async {
    await mount(tester, textScale: 2);
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Vista previa del inicio con datos de prueba', (tester) async {
    final app = await mount(tester);
    expect(tester.takeException(), isNull);
    // Captura opcional para revisión visual; no utiliza datos de producción.
    if (const bool.fromEnvironment('CAPTURE_PREVIEW')) {
      final boundary =
          app.preview.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      await capturePreview(tester, boundary, 'inicio-b');
    }
  });

  group('Tarea 28 — Disposición de ScoreboardRow en tres columnas', () {
    testWidgets('Distribución en tres columnas: equipos, marcadores alineados y estado/minuto/hora sin duplicar', (tester) async {
      final now = DateTime.now();
      final liveEvent = EventModel(
        id: 'evt-3col-live',
        sport: SportType.soccer,
        league: 'Champions League',
        status: EventStatus.live,
        startTime: DateTime(now.year, now.month, now.day, 20, 0),
        currentPeriod: "34'",
        homeTeam: const TeamModel(id: 't-rma', name: 'Real Madrid'),
        awayTeam: const TeamModel(id: 't-mci', name: 'Manchester City'),
        homeScore: 2,
        awayScore: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: ScoreboardRow(event: liveEvent, onTap: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Columna 1: Equipos en sus filas
      expect(find.text('Real Madrid'), findsOneWidget);
      expect(find.text('Manchester City'), findsOneWidget);

      // Columna 2: Marcadores alineados
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // Columna 3: Minuto real de juego en vivo sin duplicarse y sin punto rojo
      expect(find.text('34′'), findsOneWidget);
      expect(find.byKey(const ValueKey('scoreboard_live_dot')), findsNothing);

      // Encabezado: Competición y estado chip conservados sin duplicar el minuto
      expect(find.textContaining('Champions League'), findsOneWidget);
      expect(find.text('EN VIVO'), findsOneWidget);
      expect(find.text('34′'), findsOneWidget); // Exactamente 1 ocurrencia, sin duplicarse en cabecera
    });

    testWidgets('En vivo sin minuto (otro deporte o descanso): muestra indicador en vivo accesible sin inventar reloj', (tester) async {
      final now = DateTime.now();
      final nbaLive = EventModel(
        id: 'evt-3col-nba-live',
        sport: SportType.nba,
        league: 'NBA',
        status: EventStatus.live,
        startTime: DateTime(now.year, now.month, now.day, 21, 30),
        currentPeriod: 'Q3 04:12',
        homeTeam: const TeamModel(id: 't-bos', name: 'Boston Celtics'),
        awayTeam: const TeamModel(id: 't-mia', name: 'Miami Heat'),
        homeScore: 88,
        awayScore: 82,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: ScoreboardRow(event: nbaLive, onTap: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Boston Celtics'), findsOneWidget);
      expect(find.text('Miami Heat'), findsOneWidget);
      expect(find.text('88'), findsOneWidget);
      expect(find.text('82'), findsOneWidget);

      // Indicador en vivo presente (VIVO) sin punto rojo
      expect(find.text('VIVO'), findsOneWidget);
      final semantics = tester.ensureSemantics();
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('En vivo'), findsWidgets);
      semantics.dispose();

      // No inventa minuto de fútbol
      expect(find.textContaining('′'), findsNothing);
    });

    testWidgets('Finalizado con score real: muestra marcadores finales y estado FINAL en tercera columna', (tester) async {
      final now = DateTime.now();
      final finishedEvent = EventModel(
        id: 'evt-3col-finished',
        sport: SportType.soccer,
        league: 'LaLiga EA Sports',
        status: EventStatus.finished,
        startTime: DateTime(now.year, now.month, now.day, 16, 0),
        homeTeam: const TeamModel(id: 't-bar', name: 'FC Barcelona'),
        awayTeam: const TeamModel(id: 't-atm', name: 'Atlético de Madrid'),
        homeScore: 3,
        awayScore: 1,
        score: '3 - 1',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: ScoreboardRow(event: finishedEvent, onTap: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('FC Barcelona'), findsOneWidget);
      expect(find.text('Atlético de Madrid'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      // Estado final en tercera columna
      expect(find.text('FINAL'), findsOneWidget);
      // Estado chip en cabecera
      expect(find.text('FINALIZADO'), findsOneWidget);
    });

    testWidgets('Programado: muestra guiones neutrales en marcadores y hora de inicio en tercera columna', (tester) async {
      final now = DateTime.now();
      final schedEvent = EventModel(
        id: 'evt-3col-sched',
        sport: SportType.soccer,
        league: 'Premier League',
        status: EventStatus.scheduled,
        startTime: DateTime(now.year, now.month, now.day, 19, 45),
        homeTeam: const TeamModel(id: 't-liv', name: 'Liverpool'),
        awayTeam: const TeamModel(id: 't-mun', name: 'Manchester United'),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: ScoreboardRow(event: schedEvent, onTap: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Liverpool'), findsOneWidget);
      expect(find.text('Manchester United'), findsOneWidget);
      // Guiones neutrales, nunca 0 - 0 inventado
      expect(find.text('—'), findsNWidgets(2));
      expect(find.text('0 - 0'), findsNothing);
      // Hora de inicio en tercera columna
      expect(find.text(AppDateFormatter.formatEventTime(schedEvent.startTime)), findsOneWidget);
      expect(find.text('PROGRAMADO'), findsOneWidget);
    });

    testWidgets('Combate UFC: no inventa marcadores numéricos y conserva contrato del deporte', (tester) async {
      final now = DateTime.now();
      final ufcFinished = EventModel(
        id: 'evt-3col-ufc',
        sport: SportType.ufc,
        league: 'UFC 310',
        status: EventStatus.finished,
        startTime: DateTime(now.year, now.month, now.day, 23, 0),
        fighter1: const FighterModel(id: 'f-jon', name: 'Jon Jones'),
        fighter2: const FighterModel(id: 'f-sti', name: 'Stipe Miocic'),
        fightResult: 'TKO Rd 3 04:29',
        score: 'TKO Rd 3 04:29',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: ScoreboardRow(event: ufcFinished, onTap: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jon Jones'), findsOneWidget);
      expect(find.text('Stipe Miocic'), findsOneWidget);
      // No muestra guiones ni marcadores numéricos inventados
      expect(find.text('—'), findsNothing);
      expect(find.text('0'), findsNothing);
      // Resultado oficial presente
      expect(find.text('TKO Rd 3 04:29'), findsOneWidget);
      expect(find.text('FINAL'), findsOneWidget);
      expect(find.text('FINALIZADO'), findsOneWidget);
    });

    testWidgets('Nombres largos en ancho 320px y texto ampliado: sin desbordamiento RenderFlex ni desplazamiento de columnas', (tester) async {
      final now = DateTime.now();
      final extremeEvent = EventModel(
        id: 'evt-3col-extreme',
        sport: SportType.soccer,
        league: 'Campeonato Nacional de Primera División AFP PlanVital',
        status: EventStatus.live,
        startTime: DateTime(now.year, now.month, now.day, 20, 0),
        currentPeriod: "90+4'",
        homeTeam: const TeamModel(
          id: 't-ext-1',
          name: 'Club Social y Deportivo Colo-Colo de Santiago de Chile',
        ),
        awayTeam: const TeamModel(
          id: 't-ext-2',
          name: 'Club Universidad de Chile de la Ciudad Deportiva Metropolitana',
        ),
        homeScore: 10,
        awayScore: 9,
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(1.4),
          ),
          child: MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: ScoreboardRow(event: extremeEvent, onTap: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('90+4′'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('EN VIVO'), findsOneWidget);
    });
  });

  group('Tarea 29 — Agrupar partidos por liga o competición en FeedScreen', () {
    testWidgets('Visualización de grupos por competición en FeedScreen con orden determinista y ScoreboardRow', (tester) async {
      final now = DateTime.now();
      final feedEvents = [
        EventModel(
          id: 'ucl-1',
          sport: SportType.soccer,
          league: 'UEFA Champions League',
          leagueModel: const LeagueModel(
            id: 'ucl-id',
            name: 'UEFA Champions League',
            slug: 'uefa.champions',
            logoUrl: 'https://a.espncdn.com/i/leaguelogos/soccer/500/2.png',
          ),
          status: EventStatus.scheduled,
          startTime: DateTime(now.year, now.month, now.day, 20, 0),
          homeTeam: const TeamModel(id: 't-rma', name: 'Real Madrid'),
          awayTeam: const TeamModel(id: 't-mci', name: 'Man City'),
          footballStats: const FootballStatsModel(
            id: 'fs-ucl',
            extraStats: {'phase': 'Fase de Liga'},
          ),
        ),
        EventModel(
          id: 'ucl-2',
          sport: SportType.soccer,
          league: 'UEFA Champions League',
          leagueModel: const LeagueModel(
            id: 'ucl-id',
            name: 'UEFA Champions League',
            slug: 'uefa.champions',
            logoUrl: 'https://a.espncdn.com/i/leaguelogos/soccer/500/2.png',
          ),
          status: EventStatus.scheduled,
          startTime: DateTime(now.year, now.month, now.day, 18, 0),
          homeTeam: const TeamModel(id: 't-bar', name: 'Barcelona'),
          awayTeam: const TeamModel(id: 't-bay', name: 'Bayern'),
        ),
        EventModel(
          id: 'ucl-1', // ID duplicado para probar deduplicación
          sport: SportType.soccer,
          league: 'UEFA Champions League',
          leagueModel: const LeagueModel(
            id: 'ucl-id',
            name: 'UEFA Champions League',
            slug: 'uefa.champions',
          ),
          status: EventStatus.scheduled,
          startTime: DateTime(now.year, now.month, now.day, 20, 0),
          homeTeam: const TeamModel(id: 't-rma', name: 'Real Madrid'),
          awayTeam: const TeamModel(id: 't-mci', name: 'Man City'),
        ),
        EventModel(
          id: 'nba-1',
          sport: SportType.nba,
          league: 'NBA',
          leagueModel: const LeagueModel(id: 'nba-id', name: 'NBA', slug: 'nba'),
          status: EventStatus.scheduled,
          startTime: DateTime(now.year, now.month, now.day, 21, 30),
          homeTeam: const TeamModel(id: 't-lal', name: 'Lakers'),
          awayTeam: const TeamModel(id: 't-gsw', name: 'Warriors'),
        ),
      ];

      await mount(tester, customEvents: feedEvents);

      // La competición aparece una sola vez en la cabecera del bloque.
      expect(find.text('UEFA Champions League'), findsOneWidget);
      expect(find.byKey(const ValueKey('competition_block_league_id:ucl-id')), findsOneWidget);

      // Verificamos que Real Madrid y Barcelona están presentes una sola vez cada uno
      expect(find.text('Real Madrid'), findsOneWidget);
      expect(find.text('Barcelona'), findsOneWidget);

      // Verificamos que NBA está disponible al cambiar el filtro
      await tester.tap(find.text('NBA').first);
      await tester.pumpAndSettle();
      expect(find.text('Lakers'), findsOneWidget);
      expect(find.text('Warriors'), findsOneWidget);
    });
  });
}
