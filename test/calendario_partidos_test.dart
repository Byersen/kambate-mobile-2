import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kambate_mobile/core/utils/date_formatter.dart';
import 'package:kambate_mobile/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:kambate_mobile/features/favorites/providers/favorites_provider.dart';
import 'package:kambate_mobile/features/feed/data/feed_repository.dart';
import 'package:kambate_mobile/features/feed/presentation/screens/feed_screen.dart';
import 'package:kambate_mobile/features/feed/providers/feed_provider.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'package:kambate_mobile/models/event_status.dart';
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
            status: EventStatus.finished,
            startTime: DateTime(now.year, now.month, now.day, 12, 0),
            homeTeam: const TeamModel(id: 't-1', name: 'Arsenal'),
            awayTeam: const TeamModel(id: 't-2', name: 'Chelsea'),
            homeScore: 3,
            awayScore: 1,
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
      expect(find.text('Arsenal 3 - 1 Chelsea'), findsOneWidget);
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
}
