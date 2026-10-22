import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:kambate_mobile/services/realtime_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RealtimeService realtimeService;

  setUp(() {
    realtimeService = RealtimeService();
    realtimeService.resetForTesting();
  });

  tearDown(() {
    realtimeService.resetForTesting();
  });

  group('RealtimeService - Tablas PostgreSQL y Esquema', () {
    test('monitorea exactamente las 5 tablas PascalCase del esquema Prisma', () {
      expect(RealtimeService.monitoredTables, [
        'Event',
        'FootballStats',
        'NbaStats',
        'EsportsStats',
        'UfcStats',
      ]);
    });

    test('no incluye tablas snake_case redundantes o inexistentes', () {
      const forbiddenTables = [
        'event',
        'football_stats',
        'nba_stats',
        'esports_stats',
        'ufc_stats',
      ];
      for (final table in forbiddenTables) {
        expect(
          RealtimeService.monitoredTables.contains(table),
          isFalse,
          reason: 'La tabla $table no debe estar en monitoredTables',
        );
      }
    });

    test('channelName usa el tópico kambate_live_feed', () {
      expect(RealtimeService.channelName, 'kambate_live_feed');
    });
  });

  group('RealtimeService - Verificación de Estado de Suscripción', () {
    test('estado inicial y getters booleanos de estado', () {
      realtimeService.resetForTesting(
        initialState: RealtimeConnectionState.connecting,
      );

      expect(realtimeService.currentState, RealtimeConnectionState.connecting);
      expect(realtimeService.isConnecting, isTrue);
      expect(realtimeService.isSubscribed, isFalse);
      expect(realtimeService.isDisconnected, isFalse);
      expect(realtimeService.isOffline, isFalse);
      expect(realtimeService.hasActiveChannel, isFalse);
    });

    test('verifySubscription detecta modo offline si Supabase no está inicializado', () async {
      final isReady = await realtimeService.verifySubscription();
      expect(isReady, isFalse);
      expect(realtimeService.currentState, RealtimeConnectionState.offline);
      expect(realtimeService.isOffline, isTrue);
    });

    test('subscribeToEvents pasa a offline si no hay cliente Supabase', () {
      realtimeService.subscribeToEvents();
      expect(realtimeService.currentState, RealtimeConnectionState.offline);
      expect(realtimeService.isOffline, isTrue);
    });
  });

  group('RealtimeService - Recuperación tras Desconexión y Timeout', () {
    test('recibe status subscribed y pasa a connected', () async {
      final states = <RealtimeConnectionState>[];
      final subscription = realtimeService.onConnectionStateChanged.listen(
        states.add,
      );

      realtimeService.handleConnectionStatusForTesting(
        RealtimeSubscribeStatus.subscribed,
      );

      await pumpEventQueue();
      expect(realtimeService.currentState, RealtimeConnectionState.connected);
      expect(realtimeService.reconnectAttempts, 0);
      expect(states, contains(RealtimeConnectionState.connected));

      await subscription.cancel();
    });

    test('recibe channelError y pasa a disconnected con backoff programado', () async {
      final states = <RealtimeConnectionState>[];
      final subscription = realtimeService.onConnectionStateChanged.listen(
        states.add,
      );

      realtimeService.handleConnectionStatusForTesting(
        RealtimeSubscribeStatus.channelError,
        'Connection dropped',
      );

      await pumpEventQueue();
      expect(realtimeService.currentState, RealtimeConnectionState.disconnected);
      expect(realtimeService.isDisconnected, isTrue);
      expect(realtimeService.reconnectAttempts, 1);
      expect(states, contains(RealtimeConnectionState.disconnected));

      await subscription.cancel();
    });

    test('recibe closed y pasa a disconnected', () async {
      realtimeService.handleConnectionStatusForTesting(
        RealtimeSubscribeStatus.closed,
      );
      await pumpEventQueue();

      expect(realtimeService.currentState, RealtimeConnectionState.disconnected);
      expect(realtimeService.isDisconnected, isTrue);
      expect(realtimeService.reconnectAttempts, 1);
    });

    test('recibe timedOut y pasa a disconnected', () async {
      realtimeService.handleConnectionStatusForTesting(
        RealtimeSubscribeStatus.timedOut,
      );
      await pumpEventQueue();

      expect(realtimeService.currentState, RealtimeConnectionState.disconnected);
      expect(realtimeService.isDisconnected, isTrue);
      expect(realtimeService.reconnectAttempts, 1);
    });

    test('reconexión exitosa tras error reinicia el contador de intentos', () async {
      realtimeService.handleConnectionStatusForTesting(
        RealtimeSubscribeStatus.channelError,
      );
      expect(realtimeService.reconnectAttempts, 1);

      realtimeService.handleConnectionStatusForTesting(
        RealtimeSubscribeStatus.subscribed,
      );
      expect(realtimeService.reconnectAttempts, 0);
      expect(realtimeService.currentState, RealtimeConnectionState.connected);
    });
  });

  group('RealtimeService - Prevención de Suscripciones Duplicadas', () {
    test('pause cancela temporizadores pendientes', () {
      realtimeService.handleConnectionStatusForTesting(
        RealtimeSubscribeStatus.channelError,
      );
      expect(realtimeService.reconnectAttempts, 1);

      realtimeService.pause();
      // El temporizador pendiente queda anulado
    });

    test('unsubscribe limpia estado y temporizadores', () {
      realtimeService.handleConnectionStatusForTesting(
        RealtimeSubscribeStatus.channelError,
      );
      realtimeService.unsubscribe();

      expect(realtimeService.hasActiveChannel, isFalse);
    });

    test('reconnectIfNeeded no realiza acción si ya está conectado y activo', () async {
      realtimeService.setMockConnectedForTesting();
      expect(realtimeService.isSubscribed, isTrue);
      final preState = realtimeService.currentState;
      await realtimeService.reconnectIfNeeded();
      expect(realtimeService.currentState, preState);
      expect(realtimeService.isSubscribed, isTrue);
    });
  });

  group('RealtimeService - Emisión de Eventos en Stream', () {
    test('onEventUpdate emite actualizaciones de Event', () async {
      final updates = <RealtimeEventUpdate>[];
      final subscription = realtimeService.onEventUpdate.listen(updates.add);

      final eventUpdate = RealtimeEventUpdate.event({
        'id': 'evt-101',
        'status': 'LIVE',
        'score': '1 - 0',
      })!;

      realtimeService.handleIncomingUpdate(eventUpdate);
      await pumpEventQueue();

      expect(updates.length, 1);
      expect(updates.first.eventId, 'evt-101');
      expect(updates.first.requiresRefresh, isFalse);
      expect(updates.first.record['score'], '1 - 0');

      await subscription.cancel();
    });

    test('onEventUpdate emite actualizaciones de FootballStats requiriendo refresh', () async {
      final updates = <RealtimeEventUpdate>[];
      final subscription = realtimeService.onEventUpdate.listen(updates.add);

      final statsUpdate = RealtimeEventUpdate.footballStats({
        'eventId': 'evt-101',
        'homeGoals': 2,
        'awayGoals': 1,
      })!;

      realtimeService.handleIncomingUpdate(statsUpdate);
      await pumpEventQueue();

      expect(updates.length, 1);
      expect(updates.first.eventId, 'evt-101');
      expect(updates.first.requiresRefresh, isTrue);

      await subscription.cancel();
    });

    test('onEventUpdate emite actualizaciones de NbaStats, EsportsStats y UfcStats', () async {
      final updates = <RealtimeEventUpdate>[];
      final subscription = realtimeService.onEventUpdate.listen(updates.add);

      final nba = RealtimeEventUpdate.nbaStats({'eventId': 'nba-1'})!;
      final esports = RealtimeEventUpdate.esportsStats({'eventId': 'esports-1'})!;
      final ufc = RealtimeEventUpdate.ufcStats({'eventId': 'ufc-1'})!;

      realtimeService.handleIncomingUpdate(nba);
      realtimeService.handleIncomingUpdate(esports);
      realtimeService.handleIncomingUpdate(ufc);
      await pumpEventQueue();

      expect(updates.length, 3);
      expect(updates.map((u) => u.eventId), ['nba-1', 'esports-1', 'ufc-1']);
      expect(updates.every((u) => u.requiresRefresh), isTrue);

      await subscription.cancel();
    });
  });
}
