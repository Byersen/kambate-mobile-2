import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kambate_mobile/core/theme/app_theme.dart';
import 'package:kambate_mobile/features/feed/data/feed_repository.dart';
import 'package:kambate_mobile/features/feed/providers/feed_provider.dart';
import 'package:kambate_mobile/features/match_detail/presentation/screens/match_detail_screen.dart';
import 'package:kambate_mobile/features/match_detail/presentation/widgets/lol_match_header.dart';
import 'package:kambate_mobile/features/match_detail/presentation/widgets/lol_detail_view.dart';
import 'package:kambate_mobile/models/lol_detail_model.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'package:kambate_mobile/models/sport_type.dart';
import 'package:kambate_mobile/models/stats_models.dart';
import 'support/preview.dart';

Map<String, dynamic> sampleLolDetail() => {
  'version': 1,
  'homeParticipantId': 't1',
  'awayParticipantId': 'geng',
  'format': 'Bo3',
  'activeGameNumber': 3,
  'games': [
    {
      'gameNumber': 1,
      'status': 'finished',
      'duration': '31:24',
      'winnerParticipantId': 't1',
      'homeKills': 18,
      'awayKills': 8,
      'objectives': {
        'homeGold': 62.4,
        'awayGold': 51.8,
        'homeTowers': 9,
        'awayTowers': 2,
        'homeDragons': 3,
        'awayDragons': 1,
        'homeBarons': 1,
        'awayBarons': 0,
      },
      'homePlayers': [
        {
          'name': 'Faker',
          'champion': 'Orianna',
          'role': 'MID',
          'kills': 7,
          'deaths': 1,
          'assists': 9,
          'cs': 280,
        },
      ],
    },
    {
      'gameNumber': 2,
      'status': 'finished',
      'duration': '34:08',
      'winnerParticipantId': 'geng',
      'homeKills': 12,
      'awayKills': 21,
      'objectives': {
        'homeGold': 54.1,
        'awayGold': 67.5,
        'homeTowers': 3,
        'awayTowers': 8,
        'homeDragons': 1,
        'awayDragons': 4,
        'homeBarons': 0,
        'awayBarons': 1,
      },
    },
    {
      'gameNumber': 3,
      'status': 'live',
      'duration': '24:15',
      'mapName': 'Grieta del Invocador',
      'homeKills': 14,
      'awayKills': 12,
      'objectives': {
        'homeGold': 45.2,
        'awayGold': 43.8,
        'homeGoldFormatted': '45,2 mil',
        'awayGoldFormatted': '43,8 mil',
        'homeTowers': 4,
        'awayTowers': 3,
        'homeDragons': 2,
        'awayDragons': 1,
        'homeBarons': 0,
        'awayBarons': 0,
      },
      'homePlayers': [
        {
          'name': 'Zeus',
          'champion': 'Jayce',
          'role': 'TOP',
          'kills': 4,
          'deaths': 1,
          'assists': 6,
          'cs': 210,
        },
        {
          'name': 'Oner',
          'champion': 'Vi',
          'role': 'JGL',
          'kills': 3,
          'deaths': 2,
          'assists': 8,
          'cs': 142,
        },
        {
          'name': 'Faker',
          'champion': 'Orianna',
          'role': 'MID',
          'kills': 5,
          'deaths': 1,
          'assists': 7,
          'cs': 235,
        },
        {
          'name': 'Gumayusi',
          'champion': 'Varus',
          'role': 'ADC',
          'kills': 2,
          'deaths': 1,
          'assists': 5,
          'cs': 240,
        },
        {
          'name': 'Keria',
          'champion': 'Nautilus',
          'role': 'SUP',
          'kills': 0,
          'deaths': 1,
          'assists': 9,
          'cs': 35,
        },
      ],
      'awayPlayers': [
        {
          'name': 'Kiin',
          'champion': "K'Sante",
          'role': 'TOP',
          'kills': 2,
          'deaths': 3,
          'assists': 4,
          'cs': 195,
        },
        {
          'name': 'Canyon',
          'champion': 'Sejuani',
          'role': 'JGL',
          'kills': 2,
          'deaths': 4,
          'assists': 6,
          'cs': 130,
        },
        {
          'name': 'Chovy',
          'champion': 'Yone',
          'role': 'MID',
          'kills': 6,
          'deaths': 2,
          'assists': 3,
          'cs': 252,
        },
        {
          'name': 'Peyz',
          'champion': 'Kalista',
          'role': 'ADC',
          'kills': 2,
          'deaths': 3,
          'assists': 4,
          'cs': 228,
        },
        {
          'name': 'Lehends',
          'champion': 'Rakan',
          'role': 'SUP',
          'kills': 0,
          'deaths': 2,
          'assists': 8,
          'cs': 30,
        },
      ],
    },
  ],
};

EventModel buildLolSample({
  String status = 'LIVE',
  bool withDetail = true,
  String score = '1 - 1',
  String? format = 'Bo3',
}) {
  return EventModel.fromJson({
    'id': 'lol-sample-1',
    'sport': 'lol',
    'status': status,
    'score': score,
    'league': 'LCK',
    'startDate': '2026-10-19T10:00:00Z',
    'participants': [
      {'id': 'geng', 'name': 'Gen.G', 'shortName': 'GEN'},
      {'id': 't1', 'name': 'T1', 'shortName': 'T1'},
    ],
    'esportsStats': {
      'format': format,
      'homeScore': 1,
      'awayScore': 1,
      'map': 'Grieta del Invocador',
      if (withDetail) 'extraStats': {'detail': sampleLolDetail()},
    },
  });
}

class MutableLolRepository extends FeedRepository {
  MutableLolRepository(this.event) : super(subscribeToRealtime: false);
  EventModel event;
  @override
  Future<List<EventModel>> fetchRemoteEvents() async => [event];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPreviewFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Contrato LolDetailModel', () {
    test('Parsea versión 1 y rechaza versiones desconocidas', () {
      final valid = LolDetailModel.parse(sampleLolDetail());
      expect(valid, isNotNull);
      expect(valid!.version, 1);
      expect(valid.homeParticipantId, 't1');
      expect(valid.awayParticipantId, 'geng');

      final invalidVersion = sampleLolDetail()..['version'] = 2;
      expect(LolDetailModel.parse(invalidVersion), isNull);

      final sameParticipants = sampleLolDetail()..['awayParticipantId'] = 't1';
      expect(LolDetailModel.parse(sameParticipants), isNull);
    });

    test('Parsea formatos conocidos y maneja formato nulo o desconocido', () {
      final bo3 = LolDetailModel.parse(sampleLolDetail())!;
      expect(bo3.formatDisplayName, 'Serie al mejor de 3');

      final bo5 = LolDetailModel.parse(sampleLolDetail()..['format'] = 'Bo5')!;
      expect(bo5.formatDisplayName, 'Serie al mejor de 5');

      final bo1 = LolDetailModel.parse(sampleLolDetail()..['format'] = 'Bo1')!;
      expect(bo1.formatDisplayName, 'Partida única');

      final unknown = LolDetailModel.parse(sampleLolDetail()..remove('format'))!;
      expect(unknown.formatDisplayName, isNull);

      final custom = LolDetailModel.parse(sampleLolDetail()..['format'] = 'Final')!;
      expect(custom.formatDisplayName, 'Final');
    });

    test('Ordena partidas de manera ascendente por gameNumber', () {
      final json = sampleLolDetail();
      final games = json['games'] as List;
      // Invertir orden
      json['games'] = [games[2], games[0], games[1]];

      final detail = LolDetailModel.parse(json)!;
      expect(detail.games[0].gameNumber, 1);
      expect(detail.games[1].gameNumber, 2);
      expect(detail.games[2].gameNumber, 3);
    });

    test('Deduce status de partida si no viene explícito', () {
      final gameFinished = LolGameDetail.parse({
        'gameNumber': 1,
        'winnerParticipantId': 't1',
      })!;
      expect(gameFinished.status, LolGameStatus.finished);

      final gameLive = LolGameDetail.parse({
        'gameNumber': 2,
        'homeKills': 10,
        'awayKills': 5,
      })!;
      expect(gameLive.status, LolGameStatus.live);

      final gameScheduled = LolGameDetail.parse({
        'gameNumber': 3,
      })!;
      expect(gameScheduled.status, LolGameStatus.scheduled);
    });

    test('Los identificadores resuelven local y visitante aunque lleguen invertidos en participants', () {
      final event = buildLolSample();
      expect(event.homeTeam?.id, 't1');
      expect(event.homeTeam?.name, 'T1');
      expect(event.awayTeam?.id, 'geng');
      expect(event.awayTeam?.name, 'Gen.G');
    });

    test('Un detalle con equipos que no coinciden con el evento es ignorado', () {
      final json = sampleLolDetail();
      json['homeParticipantId'] = 'other_1';
      json['awayParticipantId'] = 'other_2';

      final event = EventModel.fromJson({
        'id': 'lol-mismatch',
        'sport': 'lol',
        'status': 'LIVE',
        'participants': [
          {'id': 't1', 'name': 'T1'},
          {'id': 'geng', 'name': 'Gen.G'},
        ],
        'esportsStats': {
          'extraStats': {'detail': json},
        },
      });

      // homeTeam y awayTeam deben conservar el fallback de participants
      expect(event.homeTeam?.id, 't1');
      expect(event.awayTeam?.id, 'geng');
    });

    test('Parsea objetivos y verifica hasAny / formatos de oro', () {
      final obj = LolGameObjectives.parse({
        'homeGold': 45.2,
        'awayGold': 43.8,
        'homeTowers': 4,
        'awayTowers': 3,
        'homeDragons': 2,
        'awayDragons': 1,
        'homeBarons': 0,
        'awayBarons': 0,
      })!;

      expect(obj.hasGold, isTrue);
      expect(obj.hasTowers, isTrue);
      expect(obj.hasDragons, isTrue);
      expect(obj.hasBarons, isTrue);
      expect(obj.hasAny, isTrue);
      expect(obj.displayHomeGold(), '45,2 mil');
      expect(obj.displayAwayGold(), '43,8 mil');
    });

    test('Maneja datos parciales de objetivos sin inventar números', () {
      final partial = LolGameObjectives.parse({
        'homeTowers': 2,
        'awayTowers': 1,
      })!;

      expect(partial.hasTowers, isTrue);
      expect(partial.hasGold, isFalse);
      expect(partial.hasDragons, isFalse);
      expect(partial.hasBarons, isFalse);
    });

    test('Parsea estadísticas de jugadores y KDA ratio', () {
      final player = LolPlayerStats.parse({
        'name': 'Faker',
        'champion': 'Orianna',
        'role': 'MID',
        'kills': 5,
        'deaths': 1,
        'assists': 7,
        'cs': 235,
      })!;

      expect(player.name, 'Faker');
      expect(player.champion, 'Orianna');
      expect(player.role, 'MID');
      expect(player.kdaString, '5 / 1 / 7');
      expect(player.kdaRatio, '12.0'); // (5 + 7) / 1
    });
  });

  group('Interfaz y widgets de LoL', () {
    testWidgets('Header muestra marcador de serie, PARTIDAS GANADAS y badge EN VIVO', (tester) async {
      final event = buildLolSample();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: LolMatchHeader(event: event)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 — 1'), findsOneWidget);
      expect(find.text('PARTIDAS GANADAS'), findsOneWidget);
      expect(find.text('EN VIVO · Partida 3'), findsOneWidget);
      expect(find.text('T1'), findsOneWidget);
      expect(find.text('Gen.G'), findsOneWidget);
    });

    testWidgets('Kills de partida seleccionada se diferencian claramente de la serie', (tester) async {
      final event = buildLolSample();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(child: LolDetailView(event: event)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // En el Resumen, la partida 3 activa debe mostrar 14 — 12 con ASESINATOS
      expect(find.text('14 — 12'), findsOneWidget);
      expect(find.text('ASESINATOS'), findsOneWidget);
      expect(find.text('Partida 3 · 24:15'), findsOneWidget);
      expect(find.text('Grieta del Invocador'), findsWidgets);
    });

    testWidgets('Muestra objetivos y recursos solo cuando existen datos', (tester) async {
      final event = buildLolSample();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(child: LolDetailView(event: event)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Objetivos y recursos'), findsOneWidget);
      expect(find.text('Oro'), findsOneWidget);
      expect(find.text('45,2 mil'), findsOneWidget);
      expect(find.text('43,8 mil'), findsOneWidget);
      expect(find.text('Torres'), findsOneWidget);
      expect(find.text('Dragones'), findsOneWidget);
      expect(find.text('Barones'), findsOneWidget);
    });

    testWidgets('Resumen de la serie lista partidas anteriores y activa', (tester) async {
      final event = buildLolSample();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(child: LolDetailView(event: event)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Resumen de la serie'), findsOneWidget);
      expect(find.text('T1 ganó'), findsOneWidget);
      expect(find.text('Gen.G ganó'), findsOneWidget);
      expect(find.text('En juego'), findsOneWidget);
      expect(find.text('FINALIZADA'), findsNWidgets(2));
      expect(find.text('EN VIVO'), findsWidgets);
    });

    testWidgets('Conmutación entre pestañas Resumen, Partidas y Jugadores', (tester) async {
      final event = buildLolSample();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(child: LolDetailView(event: event)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Pestaña inicial: Resumen
      expect(find.text('Resumen de la serie'), findsOneWidget);

      // 2. Ir a pestaña Partidas
      await tester.tap(find.text('Partidas'));
      await tester.pumpAndSettle();
      expect(find.text('Ganador: T1'), findsOneWidget);
      expect(find.text('Ganador: Gen.G'), findsOneWidget);

      // 3. Ir a pestaña Jugadores
      await tester.tap(find.text('Jugadores'));
      await tester.pumpAndSettle();
      expect(find.text('Faker'), findsOneWidget);
      expect(find.text('Orianna'), findsOneWidget);
      expect(find.text('5 / 1 / 7'), findsOneWidget);

      // Alternar a equipo rival en Jugadores
      await tester.tap(find.text('Gen.G').last);
      await tester.pumpAndSettle();
      expect(find.text('Chovy'), findsOneWidget);
      expect(find.text('Yone'), findsOneWidget);
    });

    testWidgets('Permite consultar partidas finalizadas sin perder selección en actualizaciones', (tester) async {
      final event = buildLolSample();
      final repo = MutableLolRepository(event);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: MatchDetailScreen(event: event),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Inicialmente en Partida 3 (activa)
      expect(find.text('Partida 3 · 24:15'), findsOneWidget);
      expect(find.text('14 — 12'), findsOneWidget);

      // El usuario selecciona Partida 1 (finalizada)
      await tester.tap(find.byKey(const ValueKey('lol-game-pill-1')));
      await tester.pumpAndSettle();

      // Debe mostrar Partida 1 (18 — 8)
      expect(find.text('Partida 1 · 31:24'), findsOneWidget);
      expect(find.text('18 — 8'), findsOneWidget);

      // Simular actualización del evento (ej. aumenta un kill en la partida 3 en vivo)
      final updatedJson = sampleLolDetail();
      (updatedJson['games'] as List)[2]['homeKills'] = 15;
      final updatedEvent = event.copyWith(
        esportsStats: EsportsStatsModel(
          id: 'es-1',
          format: 'Bo3',
          homeScore: 1,
          awayScore: 1,
          extraStats: {'detail': updatedJson},
        ),
      );

      // Re-render con nuevo evento
      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: MatchDetailScreen(event: updatedEvent),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // LA SELECCIÓN DEBE PERMANECER EN PARTIDA 1 (NO VOLVER A PARTIDA 3)
      expect(find.text('Partida 1 · 31:24'), findsOneWidget);
      expect(find.text('18 — 8'), findsOneWidget);
    });

    testWidgets('Maneja formato de serie desconocido en AppBar sin supuestos ficticios', (tester) async {
      final eventWithoutFormat = buildLolSample(format: null);
      // Eliminar formato del detail también
      final json = sampleLolDetail()..remove('format');
      final event = eventWithoutFormat.copyWith(
        esportsStats: EsportsStatsModel(
          id: 'es-unknown',
          format: null,
          homeScore: 1,
          awayScore: 1,
          extraStats: {'detail': json},
        ),
      );

      final repo = MutableLolRepository(event);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: MatchDetailScreen(event: event),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe mostrar solo LCK en el título sin añadir Bo3/Bo5 ficticio
      expect(find.text('LCK'), findsOneWidget);
      expect(find.textContaining('Serie al mejor de'), findsNothing);
      expect(find.textContaining('Bo3'), findsNothing);
    });

    testWidgets('Estado programado no simula asesinatos ni resultados inventados', (tester) async {
      final scheduledEvent = EventModel.fromJson({
        'id': 'lol-sched',
        'sport': 'lol',
        'status': 'SCHEDULED',
        'league': 'LEC Europa',
        'startDate': '2026-10-20T12:00:00Z',
        'participants': [
          {'id': 'fnc', 'name': 'Fnatic'},
          {'id': 'g2', 'name': 'G2 Esports'},
        ],
        'esportsStats': {
          'format': 'Bo3',
          'homeScore': 0,
          'awayScore': 0,
        },
      });

      final repo = MutableLolRepository(scheduledEvent);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: MatchDetailScreen(event: scheduledEvent),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PROGRAMADO'), findsOneWidget);
      expect(find.text('VS'), findsOneWidget);
      expect(find.text('Encuentro programado'), findsOneWidget);
      expect(find.textContaining('asesinatos'), findsNothing);
    });

    testWidgets('Admite escala de texto x2 y ancho estrecho sin desbordamientos', (tester) async {
      final event = buildLolSample();
      tester.view.physicalSize = const Size(320 * 2.0, 800 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(child: LolDetailView(event: event)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Botón de favorito conmuta en LoL', (tester) async {
      final event = buildLolSample();
      final repo = MutableLolRepository(event);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: MatchDetailScreen(event: event),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final favButton = find.byTooltip('Añadir a favoritos');
      expect(favButton, findsOneWidget);

      await tester.tap(favButton);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Quitar de favoritos'), findsOneWidget);
    });

    testWidgets('LolMatchHeader muestra categoría LEAGUE OF LEGENDS e ícono de esports', (tester) async {
      final event = buildLolSample();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: LolMatchHeader(event: event)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LEAGUE OF LEGENDS'), findsOneWidget);
      expect(find.byIcon(Icons.sports_esports), findsOneWidget);
    });

    testWidgets('Partido en vivo sin marcador no fabrica 0 — 0 y muestra — — —', (tester) async {
      final liveNoScoreEvent = EventModel.fromJson({
        'id': 'lol-live-noscore',
        'sport': 'lol',
        'status': 'LIVE',
        'league': 'LCK Korea',
        'startDate': '2026-10-20T12:00:00Z',
        'participants': [
          {'id': 'team-t1', 'name': 'T1'},
          {'id': 'team-geng', 'name': 'Gen.G'},
        ],
        'esportsStats': {
          'id': 'es-noscore',
        },
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: LolMatchHeader(event: liveNoScoreEvent)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('— — —'), findsOneWidget);
      expect(find.text('0 — 0'), findsNothing);
    });

    testWidgets('Ausencia de detalle con formato y mapa parciales muestra tarjeta de serie y advertencia explícita', (tester) async {
      final partialEvent = EventModel.fromJson({
        'id': 'lol-partial-info',
        'sport': 'lol',
        'status': 'LIVE',
        'league': 'LEC Season Finals',
        'startDate': '2026-10-20T12:00:00Z',
        'participants': [
          {'id': 'team-fnc', 'name': 'Fnatic'},
          {'id': 'team-g2', 'name': 'G2 Esports'},
        ],
        'score': '1 - 0',
        'esportsStats': {
          'id': 'es-partial',
          'format': 'Bo5',
          'map': 'Grieta del Invocador',
          'homeScore': 1,
          'awayScore': 0,
        },
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(child: LolDetailView(event: partialEvent)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('INFORMACIÓN DE LA SERIE'), findsOneWidget);
      expect(find.text('Formato: Bo5'), findsOneWidget);
      expect(find.text('Mapa / Fase: Grieta del Invocador'), findsOneWidget);
      expect(find.text('Competición: LEC Season Finals'), findsOneWidget);
      expect(find.text('Serie en vivo'), findsOneWidget);
      expect(
        find.text('Sin proveedor de estadísticas en tiempo real ni desglose de partidas activo para esta competición.'),
        findsOneWidget,
      );
      expect(find.textContaining('asesinatos'), findsNothing);
    });

    testWidgets('Ausencia total de detalle en finalizado muestra estado explícito sin datos simulados', (tester) async {
      final finishedEmptyEvent = EventModel.fromJson({
        'id': 'lol-fin-empty',
        'sport': 'lol',
        'status': 'FINISHED',
        'league': 'Worlds 2026',
        'startDate': '2026-10-19T10:00:00Z',
        'participants': [
          {'id': 'team-t1', 'name': 'T1'},
          {'id': 'team-wbg', 'name': 'Weibo Gaming'},
        ],
        'score': '3 - 0',
        'home_score': 3,
        'away_score': 0,
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(child: LolDetailView(event: finishedEmptyEvent)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Encuentro finalizado'), findsOneWidget);
      expect(find.text('La información desglosada por partida no se encuentra disponible para esta serie.'), findsOneWidget);
      expect(
        find.text('Sin proveedor de estadísticas en tiempo real ni desglose de partidas activo para esta competición.'),
        findsOneWidget,
      );
      expect(find.byType(Card), findsOneWidget);
    });
  });

  group('Resolución de Persistencia Supabase para Esports (Tarea 19)', () {
    test('Evento persistido con sport "esports" y league "lol" se clasifica como SportType.lol', () {
      final json = {
        'id': 'ev-esports-lol',
        'sport': {'id': 'sp-1', 'name': 'Esports (LoL/Valorant)', 'slug': 'esports'},
        'league': {'id': 'lg-1', 'name': 'League of Legends Champions Korea', 'slug': 'lol'},
        'status': 'SCHEDULED',
        'startDate': '2026-10-25T10:00:00Z',
        'participants': [
          {'id': 'team-1', 'name': 'Dplus KIA'},
          {'id': 'team-2', 'name': 'KT Rolster'},
        ],
      };

      final event = EventModel.fromJson(json);
      expect(event.sport, SportType.lol);
    });

    test('Evento persistido con sport "esports" y liga regional "lck" se clasifica como SportType.lol', () {
      final json = {
        'id': 'ev-esports-lck',
        'sport': {'id': 'sp-1', 'name': 'Esports (LoL/Valorant)', 'slug': 'esports'},
        'league': {'id': 'lg-2', 'name': 'LCK', 'slug': 'lck'},
        'status': 'FINISHED',
        'startDate': '2026-10-20T10:00:00Z',
        'participants': [
          {'id': 'team-1', 'name': 'T1'},
          {'id': 'team-2', 'name': 'Gen.G'},
        ],
      };

      final event = EventModel.fromJson(json);
      expect(event.sport, SportType.lol);
    });

    test('Evento persistido con sport "esports" y league "valorant" se clasifica como SportType.valorant', () {
      final json = {
        'id': 'ev-esports-val',
        'sport': {'id': 'sp-1', 'name': 'Esports (LoL/Valorant)', 'slug': 'esports'},
        'league': {'id': 'lg-3', 'name': 'Valorant Champions Tour', 'slug': 'valorant'},
        'status': 'LIVE',
        'startDate': '2026-10-20T10:00:00Z',
        'participants': [
          {'id': 'team-v1', 'name': 'Sentinels'},
          {'id': 'team-v2', 'name': 'Fnatic'},
        ],
      };

      final event = EventModel.fromJson(json);
      expect(event.sport, SportType.valorant);
    });
  });
}
