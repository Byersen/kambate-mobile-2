import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kambate_mobile/core/theme/app_theme.dart';
import 'package:kambate_mobile/features/feed/data/feed_repository.dart';
import 'package:kambate_mobile/features/feed/providers/feed_provider.dart';
import 'package:kambate_mobile/features/match_detail/presentation/screens/match_detail_screen.dart';
import 'package:kambate_mobile/models/basketball_detail_model.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'support/preview.dart';

Map<String, dynamic> sampleBasketballDetail() => {
  'version': 1,
  'homeParticipantId': 'lal',
  'awayParticipantId': 'bos',
  'periods': [
    {'period': '1', 'home': 28, 'away': 24},
    {'period': '2', 'home': 27, 'away': 26},
    {'period': '3', 'home': 29, 'away': 29},
    {'period': '4', 'home': null, 'away': 0}, // Q4 pendiente para local, 0 puntos para visitante
  ],
  'statistics': [
    {'key': 'fieldGoalPct', 'home': 48, 'away': 45},
    {'key': 'rebounds', 'home': 32, 'away': 29},
    {'key': 'assists', 'home': 20, 'away': 18},
    {'key': 'turnovers', 'home': 8, 'away': 10},
  ],
  'leaders': {
    'points': {
      'home': {'name': 'Jugador 23', 'number': '23', 'value': '26 PTS'},
      'away': {'name': 'Jugador 0', 'number': '0', 'value': '24 PTS'},
    },
  },
  'homePlayers': [
    {
      'name': 'Jugador 23',
      'number': '23',
      'position': 'F',
      'isStarter': true,
      'points': 26,
      'rebounds': 8,
      'assists': 7,
      'minutes': '28',
    },
    {
      'name': 'Jugador 5',
      'number': '5',
      'position': 'G',
      'isStarter': false,
      'points': 4,
      'rebounds': 2,
      'assists': 1,
      'minutes': '12',
    },
  ],
  'awayPlayers': [
    {
      'name': 'Jugador 0',
      'number': '0',
      'position': 'F',
      'isStarter': true,
      'points': 24,
      'rebounds': 7,
      'assists': 5,
      'minutes': '27',
    },
  ],
  'plays': [
    {
      'id': 'p1',
      'clock': '02:34',
      'period': '3.er cuarto',
      'text': 'Triple anotado por Jugador 23',
      'homeScore': 84,
      'awayScore': 79,
      'scoringPlay': true,
      'scoreValue': 3,
      'side': 'home',
    },
  ],
};

EventModel buildBasketballSample({
  String status = 'LIVE',
  bool withDetail = true,
  String score = '84 - 79',
}) {
  return EventModel.fromJson({
    'id': 'basketball',
    'sport': 'nba',
    'status': status,
    'score': score,
    'league': 'NBA · Temporada regular',
    'startDate': '2026-10-18T19:30:00Z',
    'participants': [
      {'id': 'bos', 'name': 'Celtics', 'shortName': 'BOS'},
      {'id': 'lal', 'name': 'Lakers', 'shortName': 'LAL'},
    ],
    'nbaStats': {
      'homePoints': 84,
      'awayPoints': 79,
      'quarter': '3',
      'extraStats': {
        'clock': '02:34',
        'quarter': '3',
        'venue': 'Crypto.com Arena',
        if (withDetail) 'detail': sampleBasketballDetail(),
      },
    },
  });
}

class MutableBasketballRepository extends FeedRepository {
  MutableBasketballRepository(this.event) : super(subscribeToRealtime: false);
  EventModel event;
  @override
  Future<List<EventModel>> fetchRemoteEvents() async => [event];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPreviewFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Contrato BasketballDetailModel', () {
    test('Parsea versión 1 y rechaza versiones desconocidas', () {
      final valid = BasketballDetailModel.parse(sampleBasketballDetail());
      expect(valid, isNotNull);
      expect(valid!.version, 1);
      expect(valid.homeParticipantId, 'lal');
      expect(valid.awayParticipantId, 'bos');

      final invalidVersion = sampleBasketballDetail()..['version'] = 2;
      expect(BasketballDetailModel.parse(invalidVersion), isNull);

      final sameParticipants = sampleBasketballDetail()
        ..['awayParticipantId'] = 'lal';
      expect(BasketballDetailModel.parse(sameParticipants), isNull);
    });

    test(
      'Distingue periodo pendiente (null -> —) de periodo con cero puntos (0 -> 0)',
      () {
        final detail = BasketballDetailModel.parse(sampleBasketballDetail())!;
        final q4 = detail.periods.firstWhere((p) => p.period == '4');
        expect(q4.homeScore, isNull); // Pendiente
        expect(q4.awayScore, 0); // Disputado con 0 puntos

        // Verificamos visualización
        expect(q4.homeScore == null ? '—' : '${q4.homeScore}', '—');
        expect(q4.awayScore == null ? '—' : '${q4.awayScore}', '0');
      },
    );

    test('Soporta prórrogas (OT, OT2) y suma coherente', () {
      final json = sampleBasketballDetail();
      json['periods'] = [
        {'period': '1', 'home': 25, 'away': 25},
        {'period': '2', 'home': 25, 'away': 25},
        {'period': '3', 'home': 25, 'away': 25},
        {'period': '4', 'home': 25, 'away': 25},
        {'period': 'OT', 'home': 10, 'away': 8},
      ];
      final detail = BasketballDetailModel.parse(json)!;
      expect(detail.periods.length, 5);
      expect(detail.periods.last.period, 'OT');
      expect(detail.periods.last.homeScore, 10);
      expect(detail.periods.last.awayScore, 8);
    });

    test(
      'Los identificadores resuelven local y visitante aunque lleguen invertidos en participants',
      () {
        final event = buildBasketballSample();
        expect(event.homeTeam?.id, 'lal');
        expect(event.homeTeam?.name, 'Lakers');
        expect(event.awayTeam?.id, 'bos');
        expect(event.awayTeam?.name, 'Celtics');
      },
    );

    test(
      'Un detalle con equipos que no coinciden con el evento es ignorado',
      () {
        final json = sampleBasketballDetail();
        json['homeParticipantId'] = 'other_1';
        json['awayParticipantId'] = 'other_2';

        final event = EventModel.fromJson({
          'id': 'basketball',
          'sport': 'nba',
          'status': 'LIVE',
          'participants': [
            {'id': 'lal', 'name': 'Lakers'},
            {'id': 'bos', 'name': 'Celtics'},
          ],
          'nbaStats': {
            'extraStats': {'detail': json},
          },
        });

        // Al no coincidir, no se altera la asignación base ni se atribuye erróneamente
        expect(event.homeTeam?.id, 'lal');
        expect(event.awayTeam?.id, 'bos');
      },
    );
  });

  group('Interfaz y widgets de básquetbol', () {
    testWidgets('Header muestra marcador, reloj, badges y nombres de equipos', (
      tester,
    ) async {
      final event = buildBasketballSample();
      final repository = MutableBasketballRepository(event);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: MatchDetailScreen(event: event),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Nombres de equipos y shortNames
      expect(find.text('Lakers'), findsWidgets);
      expect(find.text('LAL'), findsWidgets);
      expect(find.text('Celtics'), findsWidgets);
      expect(find.text('BOS'), findsWidgets);

      // Marcador y badge
      expect(find.byKey(const ValueKey('basketball-score')), findsOneWidget);
      expect(find.text('84 - 79'), findsWidgets);
      expect(find.text('EN VIVO'), findsOneWidget);
      expect(find.text('3.er cuarto · 02:34'), findsOneWidget);

      // Subtítulo en AppBar
      expect(find.text('BÁSQUETBOL'), findsOneWidget);
    });

    testWidgets(
      'Pestaña Resumen renderiza tabla de cuartos con guion en pendientes y 0 en ceros reales',
      (tester) async {
        final event = buildBasketballSample();
        final repository = MutableBasketballRepository(event);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [feedRepositoryProvider.overrideWithValue(repository)],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: MatchDetailScreen(event: event),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Título de sección
        expect(find.text('Puntos por cuarto'), findsOneWidget);

        // Cabeceras de cuartos
        expect(find.text('Equipo'), findsOneWidget);
        expect(find.text('1'), findsWidgets);
        expect(find.text('2'), findsWidgets);
        expect(find.text('3'), findsWidgets);
        expect(find.text('4'), findsWidgets);
        expect(find.text('Total'), findsOneWidget);

        // Guion en periodo 4 pendiente
        expect(find.text('—'), findsWidgets);

        // Cero real en periodo 4 de Celtics
        expect(find.text('0'), findsWidgets);

        // Estadísticas por equipo sin título de sección
        expect(find.text('Comparativa de equipos'), findsNothing);
        expect(find.text('Tiros de campo'), findsOneWidget);
        expect(find.text('Rebotes'), findsOneWidget);
        expect(find.text('Asistencias'), findsOneWidget);
        expect(find.text('Pérdidas'), findsOneWidget);

        // Líderes en puntos
        expect(find.text('Líderes en puntos'), findsOneWidget);
        expect(find.text('Jugador 23'), findsWidgets);
        expect(find.text('26 PTS'), findsOneWidget);
        expect(find.text('Jugador 0'), findsWidgets);
        expect(find.text('24 PTS'), findsOneWidget);
      },
    );

    testWidgets(
      'Botón "Ver estadísticas de jugadores" alterna a la pestaña de Jugadores',
      (tester) async {
        final event = buildBasketballSample();
        final repository = MutableBasketballRepository(event);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [feedRepositoryProvider.overrideWithValue(repository)],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: MatchDetailScreen(event: event),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final viewPlayersBtn = find.byKey(
          const ValueKey('basketball-view-players-btn'),
        );
        expect(viewPlayersBtn, findsOneWidget);

        await tester.ensureVisible(viewPlayersBtn);
        await tester.pumpAndSettle();
        await tester.tap(viewPlayersBtn);
        await tester.pumpAndSettle();

        // Ahora está en la pestaña Jugadores
        expect(find.text('TITULARES'), findsOneWidget);
        expect(find.text('SUPLENTES'), findsOneWidget);
        expect(find.text('#23'), findsOneWidget);
        expect(find.text('Jugador 23'), findsOneWidget);
      },
    );

    testWidgets(
      'Pestaña Jugadas eliminada: solo muestra Resumen y Jugadores',
      (tester) async {
        final event = buildBasketballSample();
        final repository = MutableBasketballRepository(event);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [feedRepositoryProvider.overrideWithValue(repository)],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: MatchDetailScreen(event: event),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('basketball-tab-0')), findsOneWidget);
        expect(find.byKey(const ValueKey('basketball-tab-1')), findsOneWidget);
        expect(find.byKey(const ValueKey('basketball-tab-2')), findsNothing);
        expect(find.text('Jugadas'), findsNothing);
      },
    );

    testWidgets(
      'Sin datos de detalle no muestra cuartos ficticios ni cálculos inventados',
      (tester) async {
        final eventWithoutDetail = buildBasketballSample(withDetail: false);
        final repository = MutableBasketballRepository(eventWithoutDetail);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [feedRepositoryProvider.overrideWithValue(repository)],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: MatchDetailScreen(event: eventWithoutDetail),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // NO debe calcular parciales ficticios restando como antes
        expect(find.text('Desglose por cuartos no disponible para este encuentro.'), findsOneWidget);
        expect(find.text('Estadísticas de equipo no disponibles para este encuentro.'), findsOneWidget);
        expect(find.text('Líderes en puntos'), findsNothing);

        // No se inventa jugadores ni estrellas no recibidas
        expect(find.text('L. James (32 pts)'), findsNothing);
        expect(find.text('S. Curry (29 pts)'), findsNothing);
      },
    );

    testWidgets(
      'Partido programado (SCHEDULED) muestra PROGRAMADO, hora y mensajes claros de disponibilidad',
      (tester) async {
        final scheduledEvent = buildBasketballSample(
          status: 'SCHEDULED',
          withDetail: false,
          score: '0 - 0',
        );
        final repository = MutableBasketballRepository(scheduledEvent);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [feedRepositoryProvider.overrideWithValue(repository)],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: MatchDetailScreen(event: scheduledEvent),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('PROGRAMADO'), findsOneWidget);
        expect(find.text('VS'), findsOneWidget);
        expect(
          find.text(
            'El partido aún no comienza. Los parciales por cuarto aparecerán cuando esté en juego.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('Botón de favorito conmuta en básquetbol', (tester) async {
      final event = buildBasketballSample();
      final repository = MutableBasketballRepository(event);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: MatchDetailScreen(event: event),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final starBtn = find.byTooltip('Añadir a favoritos');
      expect(starBtn, findsOneWidget);
      await tester.tap(starBtn);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Quitar de favoritos'), findsOneWidget);
    });

    testWidgets('Admite escala de texto x2 sin desbordamientos', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360 * 2, 800 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final event = buildBasketballSample();
      final repository = MutableBasketballRepository(event);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: MatchDetailScreen(event: event),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Payload parcial (solo cuartos y estadísticas, sin jugadores ni jugadas) muestra estados vacíos informativos',
      (tester) async {
        final partialDetail = {
          'version': 1,
          'homeParticipantId': 'lal',
          'awayParticipantId': 'bos',
          'periods': [
            {'period': '1', 'home': 28, 'away': 24},
            {'period': '2', 'home': 26, 'away': 26},
          ],
          'statistics': [
            {'key': 'rebounds', 'home': 22, 'away': 20},
          ],
          'leaders': null,
          'homePlayers': null,
          'awayPlayers': null,
          'plays': null,
        };

        final event = EventModel.fromJson({
          'id': 'bball-partial',
          'sport': 'nba',
          'status': 'LIVE',
          'score': '54 - 50',
          'startDate': '2026-10-21T20:00:00Z',
          'participants': [
            {'id': 'lal', 'name': 'Lakers', 'shortName': 'LAL'},
            {'id': 'bos', 'name': 'Celtics', 'shortName': 'BOS'},
          ],
          'nbaStats': {
            'homePoints': 54,
            'awayPoints': 50,
            'quarter': '2',
            'extraStats': {'detail': partialDetail},
          },
        });

        final repository = MutableBasketballRepository(event);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [feedRepositoryProvider.overrideWithValue(repository)],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: MatchDetailScreen(event: event),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Resumen muestra cuartos reales disponibles
        expect(find.text('Puntos por cuarto'), findsOneWidget);
        expect(find.text('1'), findsWidgets);
        expect(find.text('2'), findsWidgets);
        expect(find.text('Líderes en puntos'), findsNothing);

        // Pestaña Jugadores muestra estado no disponible sin crashear
        final playersTab = find.byKey(const ValueKey('basketball-tab-1'));
        await tester.tap(playersTab);
        await tester.pumpAndSettle();
        expect(
          find.text('Estadísticas de jugadores no disponibles'),
          findsOneWidget,
        );

        // Pestaña Jugadas ya no existe
        expect(find.byKey(const ValueKey('basketball-tab-2')), findsNothing);
      },
    );

    testWidgets(
      'Fixture programado real con score null no fabrica 0 - 0 y mantiene estado limpio',
      (tester) async {
        final scheduledEvent = EventModel.fromJson({
          'id': 'bball-scheduled-null',
          'sport': 'nba',
          'status': 'SCHEDULED',
          'score': null,
          'startDate': '2026-10-25T19:00:00Z',
          'participants': [
            {'id': 'lal', 'name': 'Lakers', 'shortName': 'LAL'},
            {'id': 'uta', 'name': 'Jazz', 'shortName': 'UTA'},
          ],
          'nbaStats': {
            'homePoints': null,
            'awayPoints': null,
            'quarter': null,
            'extraStats': {
              'detail': {
                'version': 1,
                'homeParticipantId': 'lal',
                'awayParticipantId': 'uta',
                'periods': [],
                'statistics': [],
                'leaders': null,
                'homePlayers': null,
                'awayPlayers': null,
                'plays': null,
              },
            },
          },
        });

        expect(scheduledEvent.homeScore, isNull);
        expect(scheduledEvent.awayScore, isNull);
        expect(scheduledEvent.score, isNull);

        final repository = MutableBasketballRepository(scheduledEvent);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [feedRepositoryProvider.overrideWithValue(repository)],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: MatchDetailScreen(event: scheduledEvent),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('PROGRAMADO'), findsOneWidget);
        expect(find.text('VS'), findsOneWidget);
        expect(find.text('0 - 0'), findsNothing);
        expect(
          find.text(
            'El partido aún no comienza. Los parciales por cuarto aparecerán cuando esté en juego.',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
