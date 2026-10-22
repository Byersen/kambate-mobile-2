import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kambate_mobile/core/theme/app_theme.dart';
import 'package:kambate_mobile/features/feed/presentation/widgets/match_card.dart';
import 'package:kambate_mobile/features/feed/presentation/widgets/scoreboard_row.dart';
import 'package:kambate_mobile/features/feed/providers/feed_provider.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'package:kambate_mobile/models/event_status.dart';
import 'package:kambate_mobile/models/sport_type.dart';
import 'package:kambate_mobile/services/realtime_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tarea 25 - Integridad de Estados y Resultados Reales (EventModel & Fixtures)', () {
    test('1. Fixture PROGRAMADO: status scheduled fuerza scores nulos aunque el payload traiga marcadores ficticios', () {
      final json = {
        'id': 'evt-prog-1',
        'externalId': 'football-espn-1001',
        'sport': {'slug': 'football', 'name': 'Futbol'},
        'league': {'name': 'UEFA Champions League', 'slug': 'uefa.champions'},
        'status': 'SCHEDULED',
        'score': '0 - 0', // Intento de proveedor de asociar 0-0 a partido futuro
        'home_score': 0,
        'away_score': 0,
        'startDate': '2026-10-30T19:00:00Z',
        'participants': [
          {'id': 'p1', 'name': 'Real Madrid', 'externalId': 'team-rm'},
          {'id': 'p2', 'name': 'Bayern Munich', 'externalId': 'team-bay'},
        ],
      };

      final event = EventModel.fromJson(json);

      expect(event.status, EventStatus.scheduled);
      expect(event.homeScore, isNull);
      expect(event.awayScore, isNull);
      expect(event.score, isNull);
    });

    test('2. Fixture EN VIVO: status live persiste marcador parcial y periodo en curso', () {
      final json = {
        'id': 'evt-live-1',
        'externalId': 'football-espn-1002',
        'sport': {'slug': 'football', 'name': 'Futbol'},
        'league': {'name': 'LaLiga', 'slug': 'esp.1'},
        'status': 'LIVE',
        'score': '1 - 0',
        'home_score': 1,
        'away_score': 0,
        'current_period': "35'",
        'startDate': '2026-10-22T15:00:00Z',
        'participants': [
          {'id': 'p1', 'name': 'Barcelona', 'externalId': 'team-fcb'},
          {'id': 'p2', 'name': 'Sevilla', 'externalId': 'team-sev'},
        ],
      };

      final event = EventModel.fromJson(json);

      expect(event.status, EventStatus.live);
      expect(event.isLive, isTrue);
      expect(event.homeScore, 1);
      expect(event.awayScore, 0);
      expect(event.score, '1 - 0');
      expect(event.currentPeriod, "35'");
    });

    test('3. Fixture FINALIZADO CON SCORE: status finished persiste y preserva marcador real confirmado', () {
      final json = {
        'id': 'evt-fin-score-1',
        'externalId': 'football-espn-1003',
        'sport': {'slug': 'football', 'name': 'Futbol'},
        'league': {'name': 'Premier League', 'slug': 'eng.1'},
        'status': 'FINISHED',
        'score': '3 - 1',
        'home_score': 3,
        'away_score': 1,
        'startDate': '2026-10-22T13:00:00Z',
        'participants': [
          {'id': 'p1', 'name': 'Arsenal', 'externalId': 'team-ars'},
          {'id': 'p2', 'name': 'Chelsea', 'externalId': 'team-che'},
        ],
      };

      final event = EventModel.fromJson(json);

      expect(event.status, EventStatus.finished);
      expect(event.homeScore, 3);
      expect(event.awayScore, 1);
      expect(event.score, '3 - 1');
    });

    test('4. Fixture FINALIZADO SIN SCORE: status finished conserva score nulo sin fabricar 0-0 ni inferir resultado por hora transcurrida', () {
      final json = {
        'id': 'evt-fin-noscore-1',
        'externalId': 'football-espn-1004',
        'sport': {'slug': 'football', 'name': 'Futbol'},
        'league': {'name': 'Serie A', 'slug': 'ita.1'},
        'status': 'FINISHED',
        'score': null, // Proveedor no entregó goles
        'home_score': null,
        'away_score': null,
        'startDate': '2026-10-21T18:00:00Z', // Hora ya pasó hace más de 24h
        'participants': [
          {'id': 'p1', 'name': 'Milan', 'externalId': 'team-acm'},
          {'id': 'p2', 'name': 'Inter', 'externalId': 'team-int'},
        ],
      };

      final event = EventModel.fromJson(json);

      expect(event.status, EventStatus.finished);
      expect(event.homeScore, isNull);
      expect(event.awayScore, isNull);
      expect(event.score, isNull);
    });

    test('5. Fixture ESTADO DESCONOCIDO: ante estado inválido o no reconocido recurre a scheduled con scores nulos', () {
      final json = {
        'id': 'evt-unknown-1',
        'externalId': 'nba-espn-9999',
        'sport': {'slug': 'nba', 'name': 'NBA'},
        'league': {'name': 'NBA', 'slug': 'nba'},
        'status': 'UNKNOWN_STATE_FROM_API',
        'score': '110 - 105',
        'home_score': 110,
        'away_score': 105,
        'startDate': '2026-10-22T23:00:00Z',
        'participants': [
          {'id': 'p1', 'name': 'Celtics', 'externalId': 'team-bos'},
          {'id': 'p2', 'name': 'Warriors', 'externalId': 'team-gsw'},
        ],
      };

      final event = EventModel.fromJson(json);

      expect(event.status, EventStatus.scheduled);
      expect(event.homeScore, isNull);
      expect(event.awayScore, isNull);
      expect(event.score, isNull);
    });
  });

  group('Tarea 25 - Presentación en Widgets (ScoreboardRow & MatchCard)', () {
    testWidgets('ScoreboardRow muestra PROGRAMADO y oculta marcadores en fixture programado', (tester) async {
      final event = EventModel(
        id: 'evt-test-sched',
        sport: SportType.soccer,
        league: 'Champions League',
        status: EventStatus.scheduled,
        startTime: DateTime.utc(2026, 10, 25, 20, 0),
        homeScore: null,
        awayScore: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ScoreboardRow(event: event, onTap: () {}),
          ),
        ),
      );

      expect(find.text('PROGRAMADO'), findsOneWidget);
      // Los marcadores muestran el guion neutral
      expect(find.text('—'), findsNWidgets(2));
    });

    testWidgets('ScoreboardRow muestra EN VIVO y marcadores reales en fixture en vivo', (tester) async {
      final event = EventModel(
        id: 'evt-test-live',
        sport: SportType.soccer,
        league: 'LaLiga',
        status: EventStatus.live,
        startTime: DateTime.utc(2026, 10, 22, 17, 0),
        currentPeriod: "42'",
        homeScore: 2,
        awayScore: 1,
        score: '2 - 1',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ScoreboardRow(event: event, onTap: () {}),
          ),
        ),
      );

      expect(find.text('EN VIVO'), findsOneWidget);
      expect(find.text("42'"), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('ScoreboardRow muestra FINALIZADO y marcadores reales en fixture finalizado con score', (tester) async {
      final event = EventModel(
        id: 'evt-test-fin',
        sport: SportType.soccer,
        league: 'Premier League',
        status: EventStatus.finished,
        startTime: DateTime.utc(2026, 10, 22, 14, 0),
        homeScore: 4,
        awayScore: 0,
        score: '4 - 0',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ScoreboardRow(event: event, onTap: () {}),
          ),
        ),
      );

      expect(find.text('FINALIZADO'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('ScoreboardRow muestra FINALIZADO y guiones sin inventar datos en fixture finalizado sin score', (tester) async {
      final event = EventModel(
        id: 'evt-test-fin-null',
        sport: SportType.soccer,
        league: 'Serie A',
        status: EventStatus.finished,
        startTime: DateTime.utc(2026, 10, 21, 16, 0),
        homeScore: null,
        awayScore: null,
        score: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ScoreboardRow(event: event, onTap: () {}),
          ),
        ),
      );

      expect(find.text('FINALIZADO'), findsOneWidget);
      expect(find.text('—'), findsNWidgets(2));
      expect(find.text('0 - 0'), findsNothing);
    });

    testWidgets('MatchCard renderiza etiqueta FINAL para partido finalizado', (tester) async {
      final event = EventModel(
        id: 'evt-mc-fin',
        sport: SportType.soccer,
        league: 'Bundesliga',
        status: EventStatus.finished,
        startTime: DateTime.utc(2026, 10, 22, 13, 30),
        homeScore: 3,
        awayScore: 2,
        score: '3 - 2',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MatchCard(event: event, onTap: () {}),
          ),
        ),
      );

      expect(find.text('FINAL'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });
  });

  group('Tarea 25 - Actualización Realtime de Estados y Marcadores (FeedNotifier)', () {
    test('applyRealtimeUpdate transiciona evento de SCHEDULED a FINISHED con su marcador real', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(feedNotifierProvider.notifier);

      final initialEvent = EventModel(
        id: 'evt-rt-1',
        sport: SportType.soccer,
        league: 'Europa League',
        status: EventStatus.scheduled,
        startTime: DateTime.utc(2026, 10, 22, 16, 45),
        homeScore: null,
        awayScore: null,
      );

      notifier.state = AsyncValue.data([initialEvent]);

      final update = RealtimeEventUpdate(
        eventId: 'evt-rt-1',
        requiresRefresh: false,
        record: {
          'id': 'evt-rt-1',
          'status': 'FINISHED',
          'score': '4 - 0',
          'home_score': 4,
          'away_score': 0,
        },
      );

      await notifier.applyRealtimeUpdate(update);

      final updatedEvents = container.read(feedNotifierProvider).value!;
      final updated = updatedEvents.firstWhere((e) => e.id == 'evt-rt-1');

      expect(updated.status, EventStatus.finished);
      expect(updated.homeScore, 4);
      expect(updated.awayScore, 0);
      expect(updated.score, '4 - 0');
    });

    test('applyRealtimeUpdate transiciona evento a FINISHED conservando marcador nulo si no se provee', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(feedNotifierProvider.notifier);

      final initialEvent = EventModel(
        id: 'evt-rt-2',
        sport: SportType.soccer,
        league: 'Europa League',
        status: EventStatus.scheduled,
        startTime: DateTime.utc(2026, 10, 22, 16, 45),
        homeScore: null,
        awayScore: null,
      );

      notifier.state = AsyncValue.data([initialEvent]);

      final update = RealtimeEventUpdate(
        eventId: 'evt-rt-2',
        requiresRefresh: false,
        record: {
          'id': 'evt-rt-2',
          'status': 'FINISHED',
          'score': null,
          'home_score': null,
          'away_score': null,
        },
      );

      await notifier.applyRealtimeUpdate(update);

      final updatedEvents = container.read(feedNotifierProvider).value!;
      final updated = updatedEvents.firstWhere((e) => e.id == 'evt-rt-2');

      expect(updated.status, EventStatus.finished);
      expect(updated.homeScore, isNull);
      expect(updated.awayScore, isNull);
      expect(updated.score, isNull);
    });
  });
}
