import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kambate_mobile/core/theme/app_theme.dart';
import 'package:kambate_mobile/features/feed/data/feed_repository.dart';
import 'package:kambate_mobile/features/feed/providers/feed_provider.dart';
import 'package:kambate_mobile/features/match_detail/presentation/screens/match_detail_screen.dart';
import 'package:kambate_mobile/features/match_detail/presentation/widgets/valorant_detail_view.dart';
import 'package:kambate_mobile/features/match_detail/presentation/widgets/valorant_match_header.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'package:kambate_mobile/models/stats_models.dart';
import 'package:kambate_mobile/models/valorant_detail_model.dart';
import 'support/preview.dart';

Map<String, dynamic> sampleValorantDetail() => {
  'version': 1,
  'homeParticipantId': 'kru',
  'awayParticipantId': 'lev',
  'format': 'Bo3',
  'activeMapNumber': 3,
  'maps': [
    {
      'mapNumber': 1,
      'mapName': 'Bind',
      'status': 'finished',
      'duration': '42:10',
      'winnerParticipantId': 'kru',
      'homeScore': 13,
      'awayScore': 9,
    },
    {
      'mapNumber': 2,
      'mapName': 'Haven',
      'status': 'finished',
      'duration': '38:45',
      'winnerParticipantId': 'lev',
      'homeScore': 8,
      'awayScore': 13,
    },
    {
      'mapNumber': 3,
      'mapName': 'Ascent',
      'status': 'live',
      'currentRound': 19,
      'homeScore': 10,
      'awayScore': 8,
      'homeSide': 'Defensa',
      'awaySide': 'Ataque',
      'rounds': [
        {'roundNumber': 13, 'winnerParticipantId': 'kru'},
        {'roundNumber': 14, 'winnerParticipantId': 'lev'},
        {'roundNumber': 15, 'winnerParticipantId': 'kru'},
        {'roundNumber': 16, 'winnerParticipantId': 'kru'},
        {'roundNumber': 17, 'winnerParticipantId': 'lev'},
        {'roundNumber': 18, 'winnerParticipantId': 'kru'},
      ],
      'stats': {
        'homeFirstBloods': 10,
        'awayFirstBloods': 8,
        'homePlants': 5,
        'awayPlants': 4,
        'homeDefuses': 2,
        'awayDefuses': 1,
      },
      'homePlayers': [
        {
          'name': 'keznit',
          'agent': 'Jett',
          'role': 'Duelista',
          'combatScore': 245,
          'kills': 18,
          'deaths': 11,
          'assists': 4,
        },
        {
          'name': 'Klaus',
          'agent': 'Killjoy',
          'role': 'Centinela',
          'combatScore': 190,
          'kills': 14,
          'deaths': 12,
          'assists': 6,
        },
      ],
      'awayPlayers': [
        {
          'name': 'aspas',
          'agent': 'Jett',
          'role': 'Duelista',
          'combatScore': 230,
          'kills': 16,
          'deaths': 13,
          'assists': 3,
        },
        {
          'name': 'kiNgg',
          'agent': 'Viper',
          'role': 'Controlador',
          'combatScore': 195,
          'kills': 14,
          'deaths': 12,
          'assists': 5,
        },
      ],
    },
  ],
};

EventModel buildValorantSample({
  String? format = 'Bo3',
  bool withDetail = true,
}) {
  return EventModel.fromJson({
    'id': 'val-sample-1',
    'sport': 'valorant',
    'status': 'LIVE',
    'league': 'VCT Americas',
    'startDate': '2026-10-20T12:00:00Z',
    'currentPeriod': 'Ascent · Ronda 19',
    'participants': [
      {'id': 'lev', 'name': 'Leviatán', 'shortName': 'LEV'},
      {'id': 'kru', 'name': 'KRÜ', 'shortName': 'KRÜ'},
    ],
    'esportsStats': {
      'format': format,
      'homeScore': 1,
      'awayScore': 1,
      'map': 'Ascent',
      if (withDetail) 'extraStats': {'detail': sampleValorantDetail()},
    },
  });
}

class MutableValorantRepository extends FeedRepository {
  MutableValorantRepository(this.event) : super(subscribeToRealtime: false);
  EventModel event;
  @override
  Future<List<EventModel>> fetchRemoteEvents() async => [event];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPreviewFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Contrato ValorantDetailModel', () {
    test('Parsea versión 1 y rechaza versiones desconocidas', () {
      final valid = ValorantDetailModel.parse(sampleValorantDetail());
      expect(valid, isNotNull);
      expect(valid!.version, 1);
      expect(valid.homeParticipantId, 'kru');
      expect(valid.awayParticipantId, 'lev');

      final invalidVersion = sampleValorantDetail()..['version'] = 2;
      expect(ValorantDetailModel.parse(invalidVersion), isNull);

      final sameParticipants = sampleValorantDetail()..['awayParticipantId'] = 'kru';
      expect(ValorantDetailModel.parse(sameParticipants), isNull);
    });

    test('Parsea formatos conocidos y maneja formato nulo o desconocido', () {
      final bo3 = ValorantDetailModel.parse(sampleValorantDetail())!;
      expect(bo3.formatDisplayName, 'Al mejor de 3');

      final bo5 = ValorantDetailModel.parse(sampleValorantDetail()..['format'] = 'Bo5')!;
      expect(bo5.formatDisplayName, 'Al mejor de 5');

      final bo1 = ValorantDetailModel.parse(sampleValorantDetail()..['format'] = 'Bo1')!;
      expect(bo1.formatDisplayName, 'Partida única');

      final unknown = ValorantDetailModel.parse(sampleValorantDetail()..remove('format'))!;
      expect(unknown.formatDisplayName, isNull);

      final custom = ValorantDetailModel.parse(sampleValorantDetail()..['format'] = 'Final')!;
      expect(custom.formatDisplayName, 'Final');
    });

    test('activeMap retorna mapa explícito o live o último finished', () {
      final detail = ValorantDetailModel.parse(sampleValorantDetail())!;
      expect(detail.activeMap?.mapNumber, 3);
      expect(detail.activeMap?.mapName, 'Ascent');
    });

    test('recentRounds toma como máximo las últimas 6 rondas disputadas', () {
      final json = sampleValorantDetail();
      final map3 = (json['maps'] as List)[2] as Map<String, dynamic>;
      map3['rounds'] = [
        for (var i = 1; i <= 10; i++)
          {'roundNumber': i, 'winnerParticipantId': 'kru'},
      ];

      final detail = ValorantDetailModel.parse(json)!;
      final ascent = detail.maps[2];
      expect(ascent.recentRounds.length, 6);
      expect(ascent.recentRounds.first.roundNumber, 5);
      expect(ascent.recentRounds.last.roundNumber, 10);
    });

    test('Parsea métricas comparativas del mapa', () {
      final stats = ValorantMapStats.fromJson({
        'homeFirstBloods': 10,
        'awayFirstBloods': 8,
        'homePlants': 5,
        'awayPlants': 4,
        'homeDefuses': 2,
        'awayDefuses': 1,
      })!;

      expect(stats.hasFirstBloods, isTrue);
      expect(stats.hasPlants, isTrue);
      expect(stats.hasDefuses, isTrue);
      expect(stats.hasAnyMetric, isTrue);
      expect(stats.homeFirstBloods, 10);
      expect(stats.awayFirstBloods, 8);
    });

    test('Parsea jugadores con agente, ACS y KDA', () {
      final player = ValorantPlayerStats.fromJson({
        'name': 'keznit',
        'agent': 'Jett',
        'role': 'Duelista',
        'combatScore': 245,
        'kills': 18,
        'deaths': 11,
        'assists': 4,
      })!;

      expect(player.name, 'keznit');
      expect(player.agent, 'Jett');
      expect(player.role, 'Duelista');
      expect(player.combatScore, 245);
      expect(player.acsDisplay, '245 ACS');
      expect(player.kdaString, '18 / 11 / 4');
      expect(player.kdaRatio, closeTo(2.0, 0.01));
    });

    test('Deduce status de mapa si no viene explícito', () {
      final mapFinished = ValorantMapDetail.fromJson({
        'mapNumber': 1,
        'mapName': 'Bind',
        'winnerParticipantId': 'kru',
      })!;
      expect(mapFinished.status, ValorantMapStatus.finished);

      final mapLive = ValorantMapDetail.fromJson({
        'mapNumber': 2,
        'mapName': 'Haven',
        'currentRound': 10,
      })!;
      expect(mapLive.status, ValorantMapStatus.live);

      final mapScheduled = ValorantMapDetail.fromJson({
        'mapNumber': 3,
        'mapName': 'Ascent',
      })!;
      expect(mapScheduled.status, ValorantMapStatus.scheduled);
    });

    test('Los participantes resuelven local y visitante aunque lleguen invertidos en participants', () {
      final event = buildValorantSample();
      expect(event.homeTeam?.id, 'kru');
      expect(event.homeTeam?.name, 'KRÜ');
      expect(event.awayTeam?.id, 'lev');
      expect(event.awayTeam?.name, 'Leviatán');
    });

    test('Un detalle con participantes distintos se ignora de forma segura', () {
      final json = sampleValorantDetail();
      json['homeParticipantId'] = 'unknown_1';
      json['awayParticipantId'] = 'unknown_2';

      final event = EventModel.fromJson({
        'id': 'val-mismatch',
        'sport': 'valorant',
        'status': 'LIVE',
        'participants': [
          {'id': 'kru', 'name': 'KRÜ'},
          {'id': 'lev', 'name': 'Leviatán'},
        ],
        'esportsStats': {
          'extraStats': {'detail': json},
        },
      });

      // Conserva fallback
      expect(event.homeTeam?.id, 'kru');
      expect(event.awayTeam?.id, 'lev');
    });
  });

  group('Interfaz y widgets de Valorant', () {
    testWidgets('Header muestra disciplina VALORANT, marcador de serie, MAPAS GANADOS y EN VIVO', (tester) async {
      final event = buildValorantSample();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: ValorantMatchHeader(event: event)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('VALORANT'), findsOneWidget);
      expect(find.text('1 — 1'), findsOneWidget);
      expect(find.text('MAPAS GANADOS'), findsOneWidget);
      expect(find.text('EN VIVO'), findsOneWidget);
      expect(find.text('KRÜ'), findsOneWidget);
      expect(find.text('Leviatán'), findsOneWidget);
    });

    testWidgets('Rondas de mapa seleccionado se diferencian claramente de la serie', (tester) async {
      final event = buildValorantSample();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(child: ValorantDetailView(event: event)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // En el Resumen, el mapa Ascent activo debe mostrar 10 — 8 y RONDAS GANADAS
      expect(find.text('10  —  8'), findsOneWidget);
      expect(find.text('RONDAS GANADAS'), findsOneWidget);
      expect(find.text('Ascent'), findsWidgets);
      expect(find.text('Ronda 19'), findsOneWidget);
      expect(find.text('Defensa'), findsOneWidget);
      expect(find.text('Ataque'), findsOneWidget);
    });

    testWidgets('Muestra carrusel de Últimas 6 rondas con números de ronda y logos/etiquetas', (tester) async {
      final event = buildValorantSample();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(child: ValorantDetailView(event: event)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Últimas 6 rondas'), findsOneWidget);
      expect(find.text('13'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('16'), findsOneWidget);
      expect(find.text('17'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
    });

    testWidgets('Muestra comparativa del mapa con Primeras bajas, Plantadas y Desactivaciones', (tester) async {
      final event = buildValorantSample();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(child: ValorantDetailView(event: event)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Comparativa del mapa'), findsOneWidget);
      expect(find.text('Primeras bajas'), findsOneWidget);
      expect(find.text('Plantadas'), findsOneWidget);
      expect(find.text('Desactivaciones'), findsOneWidget);
      expect(find.text('10'), findsWidgets);
      expect(find.text('8'), findsWidgets);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('4'), findsWidgets);
    });

    testWidgets('Botón Ver estadísticas de jugadores conmuta a pestaña Jugadores', (tester) async {
      final event = buildValorantSample();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(child: ValorantDetailView(event: event)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final action = find.byKey(const ValueKey('valorant-view-players-action'));
      expect(action, findsOneWidget);

      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();

      // Debe estar en pestaña Jugadores
      expect(find.text('keznit'), findsOneWidget);
      expect(find.text('Jett'), findsOneWidget);
      expect(find.text('245 ACS'), findsOneWidget);
      expect(find.text('18 / 11 / 4'), findsOneWidget);
    });

    testWidgets('Conmutación entre pestañas Resumen, Mapas y Jugadores', (tester) async {
      final event = buildValorantSample();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(child: ValorantDetailView(event: event)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Pestaña inicial: Resumen
      expect(find.text('Comparativa del mapa'), findsOneWidget);

      // 2. Pestaña Mapas
      await tester.tap(find.text('Mapas'));
      await tester.pumpAndSettle();
      expect(find.text('Ganador: KRÜ'), findsOneWidget);
      expect(find.text('Ganador: Leviatán'), findsOneWidget);
      expect(find.text('13 — 9'), findsWidgets);
      expect(find.text('8 — 13'), findsWidgets);

      // 3. Pestaña Jugadores
      await tester.tap(find.text('Jugadores'));
      await tester.pumpAndSettle();
      expect(find.text('keznit'), findsOneWidget);

      // Alternar a equipo rival en Jugadores
      await tester.tap(find.text('Leviatán').last);
      await tester.pumpAndSettle();
      expect(find.text('aspas'), findsOneWidget);
      expect(find.text('230 ACS'), findsOneWidget);
    });

    testWidgets('Permite consultar mapas finalizados sin perder selección en actualizaciones en vivo', (tester) async {
      final event = buildValorantSample();
      final repo = MutableValorantRepository(event);

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

      // Inicialmente en Ascent (mapa 3 activo)
      expect(find.text('Ascent'), findsWidgets);
      expect(find.text('10  —  8'), findsOneWidget);

      // Usuario selecciona Mapa 1 (Bind, finalizado)
      await tester.tap(find.byKey(const ValueKey('valorant-map-card-1')));
      await tester.pumpAndSettle();

      // Muestra Bind (13 — 9)
      expect(find.text('13  —  9'), findsOneWidget);
      expect(find.text('Finalizado · 42:10'), findsOneWidget);

      // Simular actualización del evento en vivo (ej. ronda 20 disputada en Ascent)
      final updatedJson = sampleValorantDetail();
      final map3 = (updatedJson['maps'] as List)[2] as Map<String, dynamic>;
      map3['homeScore'] = 11;
      map3['currentRound'] = 20;

      final updatedEvent = event.copyWith(
        esportsStats: EsportsStatsModel(
          id: 'es-val-1',
          format: 'Bo3',
          homeScore: 1,
          awayScore: 1,
          extraStats: {'detail': updatedJson},
        ),
      );

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

      // LA SELECCIÓN DEBE SEGUIR EN MAPA 1 (BIND)
      expect(find.text('13  —  9'), findsOneWidget);
      expect(find.text('Finalizado · 42:10'), findsOneWidget);
    });

    testWidgets('Maneja formato de serie desconocido en AppBar sin supuestos ficticios', (tester) async {
      final eventWithoutFormat = buildValorantSample(format: null);
      final json = sampleValorantDetail()..remove('format');
      final event = eventWithoutFormat.copyWith(
        esportsStats: EsportsStatsModel(
          id: 'es-val-unknown',
          format: null,
          homeScore: 1,
          awayScore: 1,
          extraStats: {'detail': json},
        ),
      );

      final repo = MutableValorantRepository(event);

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

      expect(find.text('VCT Americas'), findsOneWidget);
      expect(find.textContaining('Al mejor de'), findsNothing);
      expect(find.textContaining('Bo3'), findsNothing);
    });

    testWidgets('Estado programado no simula rondas ni mapas ficticios', (tester) async {
      final scheduledEvent = EventModel.fromJson({
        'id': 'val-sched',
        'sport': 'valorant',
        'status': 'SCHEDULED',
        'league': 'VCT Pacific',
        'startDate': '2026-10-20T14:00:00Z',
        'participants': [
          {'id': 'prx', 'name': 'Paper Rex'},
          {'id': 'drx', 'name': 'DRX'},
        ],
        'esportsStats': {
          'format': 'Bo3',
          'homeScore': 0,
          'awayScore': 0,
        },
      });

      final repo = MutableValorantRepository(scheduledEvent);

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
      expect(find.text('Serie programada'), findsOneWidget);
      expect(find.textContaining('RONDAS GANADAS'), findsNothing);
    });

    testWidgets('Admite escala de texto x2 y ancho estrecho sin desbordamientos', (tester) async {
      final event = buildValorantSample();
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
              body: SingleChildScrollView(child: ValorantDetailView(event: event)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Botón de favorito conmuta en Valorant', (tester) async {
      final event = buildValorantSample();
      final repo = MutableValorantRepository(event);

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
  });
}
