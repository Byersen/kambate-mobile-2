import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kambate_mobile/core/theme/app_colors.dart';
import 'package:kambate_mobile/core/utils/date_formatter.dart';
import 'package:kambate_mobile/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:kambate_mobile/features/favorites/providers/favorites_provider.dart';
import 'package:kambate_mobile/features/feed/data/feed_repository.dart';
import 'package:kambate_mobile/features/feed/presentation/screens/feed_screen.dart';
import 'package:kambate_mobile/features/feed/providers/feed_provider.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'package:kambate_mobile/models/event_status.dart';
import 'package:kambate_mobile/models/fighter_model.dart';
import 'package:kambate_mobile/models/participant_model.dart';
import 'package:kambate_mobile/models/sport_type.dart';
import 'package:kambate_mobile/models/team_model.dart';
import 'package:kambate_mobile/services/realtime_service.dart';
import 'support/preview.dart';

class MockCalendarRepository extends FeedRepository {
  MockCalendarRepository({
    this.events = const [],
    this.fail = false,
    this.sourceOverride,
    this.lastUpdatedOverride,
  }) : super(subscribeToRealtime: false);

  List<EventModel> events;
  bool fail;
  FeedDataSource? sourceOverride;
  DateTime? lastUpdatedOverride;
  int fetchCount = 0;

  @override
  FeedDataSource get source => sourceOverride ?? super.source;

  @override
  DateTime? get lastUpdated => lastUpdatedOverride ?? super.lastUpdated;

  @override
  Future<List<EventModel>> fetchRemoteEvents() async {
    fetchCount++;
    if (fail) throw StateError('Sin conexión de red');
    return events;
  }

  @override
  Future<EventModel?> getEventById(String id) async {
    return events.cast<EventModel?>().firstWhere(
      (e) => e?.id == id || e?.externalId == id,
      orElse: () => null,
    );
  }
}

class MockFavoriteTeamsNotifier extends FavoriteTeamsNotifier {
  MockFavoriteTeamsNotifier(Set<String> initial) {
    state = initial;
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

  group('Contrato de Tarea 11 y ausencia de marcadores fabricados', () {
    test('Partidos programados (SCHEDULED) no inventan marcadores 0 - 0', () {
      final scheduledJson = {
        'id': 'match-scheduled-1',
        'sport': 'football',
        'league': 'Primera División',
        'status': 'SCHEDULED',
        'startDate': '2026-10-22T20:00:00Z',
        'score': '0 - 0', // Placeholder que no debe fabricar resultados
        'participants': [
          {'id': 'team-1', 'name': 'Colo-Colo'},
          {'id': 'team-2', 'name': 'U. de Chile'},
        ],
      };

      final event = EventModel.fromJson(scheduledJson);
      expect(event.status, EventStatus.scheduled);
      expect(event.score, isNull, reason: 'Partidos futuros no deben tener score');
      expect(event.homeScore, isNull);
      expect(event.awayScore, isNull);
    });

    test('Partidos finalizados y en vivo preservan marcadores reales', () {
      final finishedJson = {
        'id': 'match-finished-1',
        'sport': 'football',
        'league': 'Primera División',
        'status': 'FINISHED',
        'startDate': '2026-10-21T18:00:00Z',
        'score': '2 - 1',
        'participants': [
          {'id': 'team-1', 'name': 'Colo-Colo'},
          {'id': 'team-2', 'name': 'U. de Chile'},
        ],
      };

      final event = EventModel.fromJson(finishedJson);
      expect(event.status, EventStatus.finished);
      expect(event.score, '2 - 1');
      expect(event.homeScore, 2);
      expect(event.awayScore, 1);
    });

    test('Marcadores con sufijos de estado (e.g. 2 - 1 (Final)) extraen goles numéricos', () {
      final finishedJson = {
        'id': 'match-finished-annotated',
        'sport': 'football',
        'league': 'Primera División',
        'status': 'FINISHED',
        'startDate': '2026-10-20T18:00:00Z',
        'score': '2 - 1 (Final)',
        'participants': [
          {'id': 'team-1', 'name': 'Colo-Colo'},
          {'id': 'team-2', 'name': 'U. de Chile'},
        ],
      };

      final event = EventModel.fromJson(finishedJson);
      expect(event.status, EventStatus.finished);
      expect(event.score, '2 - 1 (Final)');
      expect(event.homeScore, 2);
      expect(event.awayScore, 1);
    });

    test('Marcadores no numéricos de origen (L - W (Final)) no fabrican 0 - 0', () {
      final esportsJson = {
        'id': 'match-esports-lw',
        'sport': 'lol',
        'league': 'LCK',
        'status': 'FINISHED',
        'startDate': '2026-10-20T12:00:00Z',
        'score': 'L - W (Final)',
        'participants': [
          {'id': 'team-t1', 'name': 'T1'},
          {'id': 'team-geng', 'name': 'Gen.G'},
        ],
      };

      final event = EventModel.fromJson(esportsJson);
      expect(event.status, EventStatus.finished);
      expect(event.score, 'L - W (Final)');
      expect(event.homeScore, isNull);
      expect(event.awayScore, isNull);
    });

    test('Mapeo de estados de proveedor: STATUS_ABANDONED y STATUS_SUSPENDED', () {
      expect(EventStatus.fromString('STATUS_ABANDONED'), EventStatus.canceled);
      expect(EventStatus.fromString('STATUS_CANCELED'), EventStatus.canceled);
      expect(EventStatus.fromString('STATUS_SUSPENDED'), EventStatus.postponed);
      expect(EventStatus.fromString('STATUS_POSTPONED'), EventStatus.postponed);
      expect(EventStatus.fromString('STATUS_IN_PROGRESS'), EventStatus.live);
      expect(EventStatus.fromString('STATUS_FINAL'), EventStatus.finished);
    });

    test('Participantes no inventados: retorna Por definir cuando no hay datos', () {
      final noTeamsEvent = EventModel(
        id: 'no-teams-match',
        sport: SportType.soccer,
        league: 'Copa Chile',
        status: EventStatus.scheduled,
        startTime: DateTime.now(),
        participants: const [],
      );

      expect(noTeamsEvent.participant1Name, 'Por definir');
      expect(noTeamsEvent.participant2Name, 'Por definir');
    });
  });

  group('Fechas y zona horaria de Chile en cartelera y calendario', () {
    test('Conversión de fechas UTC a hora local y agrupación en calendario', () {
      // Evento a las 23:30 UTC del 21 de octubre.
      // En Chile (UTC-3), corresponde a las 20:30 del 21 de octubre.
      final utcDate = DateTime.utc(2026, 10, 21, 23, 30);
      final event = EventModel(
        id: 'tz-event',
        sport: SportType.soccer,
        league: 'Primera División',
        status: EventStatus.scheduled,
        startTime: utcDate,
      );

      final local = event.startTime.toLocal();
      expect(AppDateFormatter.isSameDay(utcDate, local), isTrue);
      expect(local.isUtc, isFalse);
    });
  });

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('Interfaz y filtros en Calendario (CalendarScreen)', () {
    testWidgets('Muestra encuentros, badges de estado y permite pull-to-refresh', (tester) async {
      configureViewport(tester);

      final now = DateTime.now();
      final todayEvent = EventModel(
        id: 'cal-ev-1',
        sport: SportType.soccer,
        league: 'Primera División',
        status: EventStatus.scheduled,
        startTime: DateTime(now.year, now.month, now.day, 16, 30),
        homeTeam: const TeamModel(id: 't-1', name: 'Colo-Colo'),
        awayTeam: const TeamModel(id: 't-2', name: 'U. de Chile'),
      );

      final repository = MockCalendarRepository(events: [todayEvent]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            home: CalendarScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Calendario'), findsOneWidget);
      expect(find.text('Colo-Colo vs U. de Chile'), findsOneWidget);
      expect(find.text('16:30'), findsOneWidget);

      // Probar Pull-to-Refresh
      expect(find.byType(RefreshIndicator), findsOneWidget);
      final refreshIndicator =
          tester.widget<RefreshIndicator>(find.byType(RefreshIndicator));
      await refreshIndicator.onRefresh();
      await tester.pumpAndSettle();
      expect(repository.fetchCount, greaterThanOrEqualTo(2));
    });

    testWidgets('Muestra estado CANC en partidos cancelados y APLAZ en aplazados', (tester) async {
      configureViewport(tester);

      final now = DateTime.now();
      final canceledEvent = EventModel(
        id: 'cal-ev-canceled',
        sport: SportType.soccer,
        league: 'LaLiga',
        status: EventStatus.canceled,
        startTime: DateTime(now.year, now.month, now.day, 18, 0),
        homeTeam: const TeamModel(id: 't-1', name: 'Rayo Vallecano'),
        awayTeam: const TeamModel(id: 't-2', name: 'Athletic Club'),
      );
      final postponedEvent = EventModel(
        id: 'cal-ev-postponed',
        sport: SportType.nba,
        league: 'NBA',
        status: EventStatus.postponed,
        startTime: DateTime(now.year, now.month, now.day, 21, 0),
        homeTeam: const TeamModel(id: 't-3', name: 'Warriors'),
        awayTeam: const TeamModel(id: 't-4', name: 'Lakers'),
      );

      final repository = MockCalendarRepository(events: [canceledEvent, postponedEvent]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            home: CalendarScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CANC'), findsOneWidget);
      expect(find.text('APLAZ'), findsOneWidget);
      expect(find.text('Rayo Vallecano vs Athletic Club'), findsOneWidget);
    });

    testWidgets('Banner offline en Calendario cuando los datos provienen de caché', (tester) async {
      configureViewport(tester);

      final now = DateTime.now();
      final repository = MockCalendarRepository(
        events: [
          EventModel(
            id: 'cached-ev',
            sport: SportType.soccer,
            league: 'Premier League',
            status: EventStatus.scheduled,
            startTime: DateTime(now.year, now.month, now.day, 12, 0),
            homeTeam: const TeamModel(id: 't-1', name: 'Arsenal'),
            awayTeam: const TeamModel(id: 't-2', name: 'Chelsea'),
          ),
        ],
        sourceOverride: FeedDataSource.cache,
        lastUpdatedOverride: DateTime(2026, 10, 21, 15, 0),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            home: CalendarScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Datos guardados ·'), findsOneWidget);
      expect(find.text('Arsenal vs Chelsea'), findsOneWidget);
    });

    testWidgets('Error de red muestra vista con reintento en Calendario', (tester) async {
      configureViewport(tester);

      final repository = MockCalendarRepository(fail: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            home: CalendarScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No pudimos cargar el calendario'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);

      // Simular que la red vuelve
      repository.fail = false;
      repository.events = [
        EventModel(
          id: 'ev-recovered',
          sport: SportType.soccer,
          league: 'Champions League',
          status: EventStatus.scheduled,
          startTime: DateTime.now(),
          homeTeam: const TeamModel(id: 't-1', name: 'Real Madrid'),
          awayTeam: const TeamModel(id: 't-2', name: 'Milan'),
        ),
      ];

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Real Madrid vs Milan'), findsOneWidget);
    });

    testWidgets('Filtro por equipos seguidos (Siguiendo) y restablecimiento', (tester) async {
      configureViewport(tester);

      final now = DateTime.now();
      final followedEvent = EventModel(
        id: 'followed-ev',
        sport: SportType.soccer,
        league: 'Primera División',
        status: EventStatus.scheduled,
        startTime: DateTime(now.year, now.month, now.day, 17, 0),
        participants: [
          const ParticipantModel(id: 'team-fav', name: 'Colo-Colo'),
          const ParticipantModel(id: 'team-other', name: 'Cobresal'),
        ],
        homeTeam: const TeamModel(id: 'team-fav', name: 'Colo-Colo'),
        awayTeam: const TeamModel(id: 'team-other', name: 'Cobresal'),
      );
      final otherEvent = EventModel(
        id: 'other-ev',
        sport: SportType.nba,
        league: 'NBA',
        status: EventStatus.scheduled,
        startTime: DateTime(now.year, now.month, now.day, 19, 0),
        homeTeam: const TeamModel(id: 't-nba-1', name: 'Bulls'),
        awayTeam: const TeamModel(id: 't-nba-2', name: 'Knicks'),
      );

      final repository = MockCalendarRepository(events: [followedEvent, otherEvent]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedRepositoryProvider.overrideWithValue(repository),
            favoriteTeamIdsProvider
                .overrideWith((ref) => MockFavoriteTeamsNotifier({'team-fav'})),
          ],
          child: const MaterialApp(
            home: CalendarScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Colo-Colo vs Cobresal'), findsOneWidget);
      expect(find.text('Bulls vs Knicks'), findsOneWidget);

      // Activar filtro Siguiendo
      await tester.tap(find.text('Siguiendo'));
      await tester.pumpAndSettle();

      expect(find.text('Colo-Colo vs Cobresal'), findsOneWidget);
      expect(find.text('Bulls vs Knicks'), findsNothing);
    });
  });

  group('Filtros en Feed (FeedScreen)', () {
    testWidgets('Chips de filtro por Aplazados y Cancelados en FeedScreen', (tester) async {
      configureViewport(tester);

      final now = DateTime.now();
      final postponedEvent = EventModel(
        id: 'feed-ev-postponed',
        sport: SportType.soccer,
        league: 'Primera División',
        status: EventStatus.postponed,
        startTime: DateTime(now.year, now.month, now.day, 15, 0),
        homeTeam: const TeamModel(id: 't-1', name: 'Everton'),
        awayTeam: const TeamModel(id: 't-2', name: 'Palestino'),
      );
      final canceledEvent = EventModel(
        id: 'feed-ev-canceled',
        sport: SportType.soccer,
        league: 'Primera División',
        status: EventStatus.canceled,
        startTime: DateTime(now.year, now.month, now.day, 18, 0),
        homeTeam: const TeamModel(id: 't-3', name: 'Cobreloa'),
        awayTeam: const TeamModel(id: 't-4', name: 'Iquique'),
      );

      final repository = MockCalendarRepository(events: [postponedEvent, canceledEvent]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            home: FeedScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verificar que los chips existen
      expect(find.widgetWithText(ChoiceChip, 'Aplazados'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Cancelados'), findsOneWidget);

      // Filtrar por Aplazados
      await tester.tap(find.widgetWithText(ChoiceChip, 'Aplazados'));
      await tester.pumpAndSettle();
      expect(find.text('Everton'), findsOneWidget);
      expect(find.text('Cobreloa'), findsNothing);

      // Filtrar por Cancelados
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Cancelados'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Cancelados'));
      await tester.pumpAndSettle();
      expect(find.text('Cobreloa'), findsOneWidget);
      expect(find.text('Everton'), findsNothing);
    });

    testWidgets('Navegación a día anterior muestra partidos pasados y botón Ir a hoy regresa a hoy', (tester) async {
      configureViewport(tester);

      final now = DateTime.now();
      final todayEvent = EventModel(
        id: 'today-ev',
        sport: SportType.soccer,
        league: 'Primera División',
        status: EventStatus.scheduled,
        startTime: DateTime(now.year, now.month, now.day, 19, 0),
        homeTeam: const TeamModel(id: 't-1', name: 'Colo-Colo'),
        awayTeam: const TeamModel(id: 't-2', name: 'U. Católica'),
      );

      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final yesterdayEvent = EventModel(
        id: 'yesterday-ev',
        sport: SportType.soccer,
        league: 'Primera División',
        status: EventStatus.finished,
        startTime: DateTime(yesterday.year, yesterday.month, yesterday.day, 18, 0),
        homeTeam: const TeamModel(id: 't-3', name: 'Cobresal'),
        awayTeam: const TeamModel(id: 't-4', name: 'Cobreloa'),
        homeScore: 3,
        awayScore: 1,
      );

      final repository = MockCalendarRepository(events: [todayEvent, yesterdayEvent]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            home: FeedScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Hoy está activo inicialmente
      expect(find.text('Colo-Colo'), findsOneWidget);
      expect(find.text('Cobresal'), findsNothing);

      // Navegar al día anterior con el botón chevron izquierdo
      await tester.tap(find.byTooltip('Día anterior'));
      await tester.pumpAndSettle();

      // Debe mostrar el partido de ayer con su marcador real
      expect(find.text('Cobresal'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Colo-Colo'), findsNothing);

      // Debe aparecer el botón Ir a hoy
      expect(find.text('Ir a hoy'), findsOneWidget);

      // Tocar Ir a hoy para regresar
      await tester.tap(find.text('Ir a hoy'));
      await tester.pumpAndSettle();

      // Vuelve a hoy
      expect(find.text('Colo-Colo'), findsOneWidget);
      expect(find.text('Cobresal'), findsNothing);
    });

    testWidgets('Partido finalizado con resultado textual muestra etiqueta de resultado y no guión vacío', (tester) async {
      configureViewport(tester);

      final now = DateTime.now();
      final finishedTextScoreEvent = EventModel(
        id: 'finished-text-score',
        sport: SportType.lol,
        league: 'LCK',
        status: EventStatus.finished,
        startTime: DateTime(now.year, now.month, now.day, 10, 0),
        homeTeam: const TeamModel(id: 't-1', name: 'T1'),
        awayTeam: const TeamModel(id: 't-2', name: 'Gen.G'),
        score: 'L - W (Final)',
      );

      final repository = MockCalendarRepository(events: [finishedTextScoreEvent]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedRepositoryProvider.overrideWithValue(repository),
            selectedSportFilterProvider.overrideWith((ref) => SportType.lol),
          ],
          child: const MaterialApp(
            home: FeedScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('T1'), findsOneWidget);
      expect(find.text('Resultado: L - W (Final)'), findsOneWidget);
    });

    testWidgets('Empty state en fechas pasadas con filtro Próximos ofrece Ver todos los estados', (tester) async {
      configureViewport(tester);

      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final yesterdayFinished = EventModel(
        id: 'y-fin',
        sport: SportType.soccer,
        league: 'LaLiga',
        status: EventStatus.finished,
        startTime: DateTime(yesterday.year, yesterday.month, yesterday.day, 16, 0),
        homeTeam: const TeamModel(id: 't-1', name: 'Barcelona'),
        awayTeam: const TeamModel(id: 't-2', name: 'Sevilla'),
        homeScore: 2,
        awayScore: 0,
      );

      final repository = MockCalendarRepository(events: [yesterdayFinished]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            home: FeedScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ir a ayer
      await tester.tap(find.byTooltip('Día anterior'));
      await tester.pumpAndSettle();
      expect(find.text('Barcelona'), findsOneWidget);

      // Activar filtro Próximos
      await tester.tap(find.widgetWithText(ChoiceChip, 'Próximos'));
      await tester.pumpAndSettle();

      // Barcelona no debe aparecer porque está finalizado
      expect(find.text('Barcelona'), findsNothing);
      expect(find.text('No hay encuentros para estos filtros'), findsOneWidget);
      expect(find.text('Ver todos los estados'), findsOneWidget);

      // Tocar Ver todos los estados
      await tester.tap(find.text('Ver todos los estados'));
      await tester.pumpAndSettle();

      // Vuelve a aparecer Barcelona
      expect(find.text('Barcelona'), findsOneWidget);
    });
  });

  group('Actualización en tiempo real y retorno a la app (Lifecycle)', () {
    testWidgets('applyRealtimeUpdate actualiza marcador en vivo y fecha', (tester) async {
      final now = DateTime.now();
      final initialEvent = EventModel(
        id: 'rt-event-1',
        sport: SportType.soccer,
        league: 'Copa Libertadores',
        status: EventStatus.scheduled,
        startTime: DateTime(now.year, now.month, now.day, 20, 0),
        homeTeam: const TeamModel(id: 't-1', name: 'Colo-Colo'),
        awayTeam: const TeamModel(id: 't-2', name: 'Boca Juniors'),
      );

      final repository = MockCalendarRepository(events: [initialEvent]);
      final container = ProviderContainer(
        overrides: [feedRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(feedNotifierProvider.notifier);
      await notifier.loadEvents(forceRefresh: true);

      // Evento pasa a EN VIVO con marcador 1 - 0
      await notifier.applyRealtimeUpdate(
        RealtimeEventUpdate(
          eventId: 'rt-event-1',
          record: {
            'id': 'rt-event-1',
            'status': 'LIVE',
            'score': '1 - 0',
            'current_period': "12'",
          },
          requiresRefresh: false,
        ),
      );

      final updatedEvents = container.read(feedNotifierProvider).requireValue;
      final updatedEvent = updatedEvents.singleWhere((e) => e.id == 'rt-event-1');
      expect(updatedEvent.status, EventStatus.live);
      expect(updatedEvent.score, '1 - 0');
      expect(updatedEvent.homeScore, 1);
      expect(updatedEvent.awayScore, 0);
      expect(updatedEvent.currentPeriod, "12'");
    });

    testWidgets('onAppResumed revalida encuentros con cooldown contra solicitudes repetidas', (tester) async {
      final repository = MockCalendarRepository(events: []);
      final container = ProviderContainer(
        overrides: [feedRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(feedNotifierProvider.notifier);
      await notifier.loadEvents(forceRefresh: true);
      final initialCount = repository.fetchCount;
      expect(initialCount, greaterThan(0));

      // Llamada inmediata de onAppResumed (dentro de cooldown de 15 segundos)
      await notifier.onAppResumed();
      expect(repository.fetchCount, initialCount, reason: 'No debe spamear peticiones en ráfaga');
    });
  });

  group('Tarea 24: Ordenar calendario multideporte y ocultar partidos finalizados', () {
    testWidgets('Orden entre deportes: muestra encuentros multideporte en una sola lista ordenada por hora local ascendente', (tester) async {
      configureViewport(tester);

      final now = DateTime.now();
      final lolEvent = EventModel(
        id: 'ev-lol-1000',
        sport: SportType.lol,
        league: 'LCK',
        status: EventStatus.scheduled,
        startTime: DateTime(now.year, now.month, now.day, 10, 0),
        homeTeam: const TeamModel(id: 't-lol-1', name: 'T1'),
        awayTeam: const TeamModel(id: 't-lol-2', name: 'Gen.G'),
      );
      final valorantEvent = EventModel(
        id: 'ev-val-1230',
        sport: SportType.valorant,
        league: 'VCT Americas',
        status: EventStatus.scheduled,
        startTime: DateTime(now.year, now.month, now.day, 12, 30),
        homeTeam: const TeamModel(id: 't-val-1', name: 'Sentinels'),
        awayTeam: const TeamModel(id: 't-val-2', name: 'Fnatic'),
      );
      final nbaEvent = EventModel(
        id: 'ev-nba-1545',
        sport: SportType.nba,
        league: 'NBA',
        status: EventStatus.scheduled,
        startTime: DateTime(now.year, now.month, now.day, 15, 45),
        homeTeam: const TeamModel(id: 't-nba-1', name: 'Lakers'),
        awayTeam: const TeamModel(id: 't-nba-2', name: 'Warriors'),
      );
      final soccerEvent = EventModel(
        id: 'ev-soc-1800',
        sport: SportType.soccer,
        league: 'Primera División',
        status: EventStatus.scheduled,
        startTime: DateTime(now.year, now.month, now.day, 18, 0),
        homeTeam: const TeamModel(id: 't-soc-1', name: 'Colo-Colo'),
        awayTeam: const TeamModel(id: 't-soc-2', name: 'U. de Chile'),
      );
      final ufcEvent = EventModel(
        id: 'ev-ufc-2215',
        sport: SportType.ufc,
        league: 'UFC 308',
        status: EventStatus.scheduled,
        startTime: DateTime(now.year, now.month, now.day, 22, 15),
        fighter1: const FighterModel(id: 'f-1', name: 'Ilia Topuria'),
        fighter2: const FighterModel(id: 'f-2', name: 'Max Holloway'),
      );

      // Repositorio con orden desordenado para comprobar que CalendarScreen ordena por hora local
      final repository = MockCalendarRepository(
        events: [ufcEvent, soccerEvent, nbaEvent, valorantEvent, lolEvent],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: CalendarScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // No requiere seleccionar deporte: incluye los partidos de todos los deportes por defecto
      expect(find.text('T1 vs Gen.G'), findsOneWidget);
      expect(find.text('Sentinels vs Fnatic'), findsOneWidget);
      expect(find.text('Lakers vs Warriors'), findsOneWidget);
      expect(find.text('Colo-Colo vs U. de Chile'), findsOneWidget);
      expect(find.text('Ilia Topuria vs Max Holloway'), findsOneWidget);
      expect(find.text('5 encuentros'), findsOneWidget);

      // Verificar orden ascendente estricto por hora local mezclando deportes
      final yLol = tester.getTopLeft(find.text('T1 vs Gen.G')).dy;
      final yVal = tester.getTopLeft(find.text('Sentinels vs Fnatic')).dy;
      final yNba = tester.getTopLeft(find.text('Lakers vs Warriors')).dy;
      final ySoc = tester.getTopLeft(find.text('Colo-Colo vs U. de Chile')).dy;
      final yUfc = tester.getTopLeft(find.text('Ilia Topuria vs Max Holloway')).dy;

      expect(yLol, lessThan(yVal));
      expect(yVal, lessThan(yNba));
      expect(yNba, lessThan(ySoc));
      expect(ySoc, lessThan(yUfc));
    });

    testWidgets('Exclusión de finalizados: no muestra eventos finalizados ni archivados en calendario y mantiene marcadores coherentes', (tester) async {
      configureViewport(tester);

      final now = DateTime.now();
      final scheduledSoccer = EventModel(
        id: 'ev-sched-soc',
        sport: SportType.soccer,
        league: 'Primera División',
        status: EventStatus.scheduled,
        startTime: DateTime(now.year, now.month, now.day, 16, 0),
        homeTeam: const TeamModel(id: 't-1', name: 'Cobresal'),
        awayTeam: const TeamModel(id: 't-2', name: 'Cobreloa'),
      );
      final liveNba = EventModel(
        id: 'ev-live-nba',
        sport: SportType.nba,
        league: 'NBA',
        status: EventStatus.live,
        startTime: DateTime(now.year, now.month, now.day, 19, 0),
        homeTeam: const TeamModel(id: 't-3', name: 'Celtics'),
        awayTeam: const TeamModel(id: 't-4', name: 'Heat'),
        homeScore: 82,
        awayScore: 78,
      );
      final finishedSoccer = EventModel(
        id: 'ev-fin-soc',
        sport: SportType.soccer,
        league: 'Primera División',
        status: EventStatus.finished,
        startTime: DateTime(now.year, now.month, now.day, 12, 0),
        homeTeam: const TeamModel(id: 't-5', name: 'Huachipato'),
        awayTeam: const TeamModel(id: 't-6', name: 'Audax Italiano'),
        homeScore: 2,
        awayScore: 1,
      );
      final archivedEsports = EventModel(
        id: 'ev-arch-lol',
        sport: SportType.lol,
        league: 'LCK',
        status: EventStatus.archived,
        startTime: DateTime(now.year, now.month, now.day, 9, 0),
        homeTeam: const TeamModel(id: 't-7', name: 'KT Rolster'),
        awayTeam: const TeamModel(id: 't-8', name: 'DRX'),
        homeScore: 2,
        awayScore: 0,
      );

      final repository = MockCalendarRepository(
        events: [scheduledSoccer, liveNba, finishedSoccer, archivedEsports],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: CalendarScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Los partidos programados y en vivo sí deben aparecer
      expect(find.text('Cobresal vs Cobreloa'), findsOneWidget);
      expect(find.text('Celtics 82 - 78 Heat'), findsOneWidget);

      // Los partidos finalizados y archivados NO deben aparecer en el calendario
      expect(find.text('Huachipato vs Audax Italiano'), findsNothing);
      expect(find.text('Huachipato 2 - 1 Audax Italiano'), findsNothing);
      expect(find.text('KT Rolster vs DRX'), findsNothing);

      // El contador de encuentros del día es coherente y cuenta sólo los visibles (2)
      expect(find.text('2 encuentros'), findsOneWidget);
    });

    testWidgets('Inclusión de programados y en vivo: muestra hora para programados y estado correspondiente para aplazados y cancelados', (tester) async {
      configureViewport(tester);

      final now = DateTime.now();
      final scheduledEv = EventModel(
        id: 'ev-prog',
        sport: SportType.soccer,
        league: 'Premier League',
        status: EventStatus.scheduled,
        startTime: DateTime(now.year, now.month, now.day, 14, 15),
        homeTeam: const TeamModel(id: 't-1', name: 'Liverpool'),
        awayTeam: const TeamModel(id: 't-2', name: 'Arsenal'),
      );
      final postponedEv = EventModel(
        id: 'ev-aplaz',
        sport: SportType.nba,
        league: 'NBA',
        status: EventStatus.postponed,
        startTime: DateTime(now.year, now.month, now.day, 17, 0),
        homeTeam: const TeamModel(id: 't-3', name: 'Bulls'),
        awayTeam: const TeamModel(id: 't-4', name: 'Bucks'),
      );
      final canceledEv = EventModel(
        id: 'ev-canc',
        sport: SportType.valorant,
        league: 'VCT',
        status: EventStatus.canceled,
        startTime: DateTime(now.year, now.month, now.day, 20, 0),
        homeTeam: const TeamModel(id: 't-5', name: 'LOUD'),
        awayTeam: const TeamModel(id: 't-6', name: 'KRÜ'),
      );

      final repository = MockCalendarRepository(
        events: [scheduledEv, postponedEv, canceledEv],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: CalendarScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('14:15'), findsOneWidget);
      expect(find.text('Liverpool vs Arsenal'), findsOneWidget);
      expect(find.text('APLAZ'), findsOneWidget);
      expect(find.text('Bulls vs Bucks'), findsOneWidget);
      expect(find.text('CANC'), findsOneWidget);
      expect(find.text('LOUD vs KRÜ'), findsOneWidget);
    });

    testWidgets('Indicador rojo: marca cada evento en vivo con punto rojo visible y accesible además del texto EN VIVO', (tester) async {
      configureViewport(tester);

      final now = DateTime.now();
      final liveSoccer = EventModel(
        id: 'ev-live-red',
        sport: SportType.soccer,
        league: 'Champions League',
        status: EventStatus.live,
        startTime: DateTime(now.year, now.month, now.day, 16, 0),
        homeTeam: const TeamModel(id: 't-1', name: 'Real Madrid'),
        awayTeam: const TeamModel(id: 't-2', name: 'Manchester City'),
        homeScore: 1,
        awayScore: 0,
      );

      final repository = MockCalendarRepository(events: [liveSoccer]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: CalendarScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Texto de evento en vivo y solo punto rojo (sin texto EN VIVO)
      expect(find.text('Real Madrid 1 - 0 Manchester City'), findsOneWidget);
      expect(find.text('EN VIVO'), findsNothing);

      // Punto rojo visible con key específica
      final dotFinder = find.byKey(const ValueKey('live_indicator_dot'));
      expect(dotFinder, findsOneWidget);

      final container = tester.widget<Container>(dotFinder);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.liveRed);
      expect(decoration.shape, BoxShape.circle);

      // Accesibilidad: semántica 'En vivo' presente en el árbol accesible
      final semantics = tester.ensureSemantics();
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('En vivo'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'En vivo'),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('Cambio de día y zona horaria: trata zona horaria de Chile y ofrece navegación a Partidos para fechas pasadas sin ocultar históricos', (tester) async {
      configureViewport(tester);

      // Evento a la 01:30 UTC del día 23 de octubre.
      // En hora local de Chile (UTC-3), corresponde a las 22:30 del 22 de octubre.
      final utcMatchTime = DateTime.utc(2026, 10, 23, 1, 30);
      final localChileTime = utcMatchTime.toLocal();

      final tzEvent = EventModel(
        id: 'ev-tz-chile',
        sport: SportType.soccer,
        league: 'Copa Libertadores',
        status: EventStatus.scheduled,
        startTime: utcMatchTime,
        homeTeam: const TeamModel(id: 't-1', name: 'Flamengo'),
        awayTeam: const TeamModel(id: 't-2', name: 'River Plate'),
      );

      final repository = MockCalendarRepository(events: [tzEvent]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: CalendarScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final hourStr = localChileTime.hour.toString().padLeft(2, '0');
      final minStr = localChileTime.minute.toString().padLeft(2, '0');
      final expectedTime = '$hourStr:$minStr';

      if (AppDateFormatter.isSameDay(DateTime.now(), localChileTime)) {
        expect(find.text('Flamengo vs River Plate'), findsOneWidget);
        expect(find.text(expectedTime), findsOneWidget);
      }

      // Navegación: tocar botón 'Hoy' en AppBar
      await tester.tap(find.text('Hoy'));
      await tester.pumpAndSettle();
      expect(find.text('Calendario'), findsOneWidget);
    });
  });
}
