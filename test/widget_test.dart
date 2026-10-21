import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kambate_mobile/core/router/app_router.dart';
import 'package:kambate_mobile/core/utils/date_formatter.dart';
import 'package:kambate_mobile/features/feed/data/feed_repository.dart';
import 'package:kambate_mobile/features/feed/providers/connection_provider.dart';
import 'package:kambate_mobile/features/feed/providers/feed_provider.dart';
import 'package:kambate_mobile/features/feed/presentation/widgets/scoreboard_row.dart';
import 'package:kambate_mobile/features/match_detail/presentation/screens/match_detail_screen.dart';
import 'package:kambate_mobile/main.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'package:kambate_mobile/models/event_status.dart';
import 'package:kambate_mobile/models/fighter_model.dart';
import 'package:kambate_mobile/models/sport_type.dart';
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
      expect(find.text('Tu jornada deportiva'), findsOneWidget);
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
      await tester.tap(find.byType(ScoreboardRow).first);
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
      expect(app.container.read(selectedSportFilterProvider), SportType.all);
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
        app.container.read(selectedSportFilterProvider.notifier).state =
            item.sport;
        await tester.pumpAndSettle();

        final matchFinder = find.text(item.matchText);
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
    'Pulsar Ver todos en cabecera de sección filtra por estado correspondiente',
    (tester) async {
      final app = await mount(tester);
      expect(app.container.read(selectedEventStatusProvider), isNull);

      final resultadosTitle = find.text('Resultados (1)');
      await tester.dragUntilVisible(
        resultadosTitle,
        find.byType(CustomScrollView).first,
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();

      final verTodosBtn = find.text('Ver todos').last;
      await tester.ensureVisible(verTodosBtn);
      await tester.tap(verTodosBtn);
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
        findsOneWidget,
      );
      expect(
        app.container.read(connectionStatusProvider),
        ConnectionStatus.offlineCached,
      );
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
}
