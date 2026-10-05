import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kambate_mobile/core/theme/app_theme.dart';
import 'package:kambate_mobile/core/router/app_router.dart';
import 'package:kambate_mobile/main.dart';
import 'package:kambate_mobile/models/sport_type.dart';
import 'package:kambate_mobile/models/team_model.dart';
import 'package:kambate_mobile/features/feed/presentation/widgets/scoreboard_row.dart';
import 'package:kambate_mobile/features/feed/data/feed_repository.dart';
import 'package:kambate_mobile/features/feed/providers/feed_provider.dart';
import 'package:kambate_mobile/features/match_detail/presentation/screens/match_detail_screen.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'package:kambate_mobile/models/football_detail_model.dart';
import 'package:kambate_mobile/models/stats_models.dart';
import 'support/preview.dart';

// Datos sintéticos exclusivamente para comprobar el contrato del cliente.
Map<String, dynamic> details() => {
  'version': 1,
  'homeParticipantId': 'home',
  'awayParticipantId': 'away',
  'statistics': [
    {'key': 'possession', 'home': 60, 'away': 40},
    {'key': 'shots', 'home': 0, 'away': null},
  ],
  'timeline': [
    {
      'kind': 'goal',
      'side': 'home',
      'minute': '12′',
      'player': 'Jugador de prueba',
    },
    {
      'kind': 'yellowCard',
      'side': 'away',
      'minute': '25′',
      'player': 'Defensa de prueba',
    },
    {
      'kind': 'substitution',
      'side': 'home',
      'minute': '61′',
      'player': 'Entra de prueba',
      'secondaryPlayer': 'Sale de prueba',
    },
  ],
  'homeLineup': {
    'formation': '4-3-3',
    'starters': [
      {'name': 'Titular de prueba', 'number': 10, 'position': 'Delantero'},
    ],
    'substitutes': null,
  },
  'awayLineup': null,
};

EventModel sample({
  String status = 'LIVE',
  bool withDetail = true,
  String score = '2 - 1',
}) {
  return EventModel.fromJson({
    'id': 'football',
    'sport': 'football',
    'status': status,
    'score': score,
    'league': 'Competición de prueba',
    'startDate': '2026-10-05T21:00:00Z',
    'participants': [
      {'id': 'away', 'name': 'Visitante de prueba'},
      {'id': 'home', 'name': 'Local de prueba'},
    ],
    'footballStats': {
      'extraStats': {'clock': '67′', if (withDetail) 'detail': details()},
    },
  });
}

class MutableRepository extends FeedRepository {
  MutableRepository(this.event) : super(subscribeToRealtime: false);
  EventModel event;
  @override
  Future<List<EventModel>> fetchRemoteEvents() async => [event];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPreviewFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Los datos ausentes siguen siendo null tras serializar', () {
    final stats = FootballStatsModel.fromJson({
      'homeGoals': 0,
      'awayGoals': null,
      'homeCards': 'bad',
    });
    final roundTrip = FootballStatsModel.fromJson(stats.toJson());
    expect(roundTrip.homeGoals, 0);
    expect(roundTrip.awayGoals, isNull);
    expect(roundTrip.homeCards, isNull);
    expect(roundTrip.awayCards, isNull);
    expect(
      EventModel.fromJson({'sport': 'football', 'footballStats': {}}).homeScore,
      isNull,
    );
  });

  test(
    'Los identificadores resuelven local y visitante aunque lleguen invertidos',
    () {
      final event = sample();
      expect(event.homeTeam!.id, 'home');
      expect(event.awayTeam!.id, 'away');
      final cached = EventModel.fromJson(event.toJson());
      expect(cached.homeTeam!.id, 'home');
      expect(cached.footballStats!.extraStats!['detail'], details());
    },
  );

  test(
    'El contrato rechaza versiones y valores inválidos sin inventar datos',
    () {
      expect(FootballDetailModel.parse({...details(), 'version': 2}), isNull);
      expect(
        FootballDetailModel.parse({...details(), 'awayParticipantId': 'home'}),
        isNull,
      );
      final parsed = FootballDetailModel.parse({
        ...details(),
        'statistics': [
          {'key': 'possession', 'home': 101, 'away': 'NaN'},
          {'key': 'shots', 'home': -1, 'away': 0},
          false,
        ],
        'timeline': [
          false,
          {'kind': 'goal', 'side': 'unknown'},
        ],
      })!;
      expect(parsed.statistics.first.home, isNull);
      expect(parsed.statistics.first.away, isNull);
      expect(parsed.statistics.last.home, isNull);
      expect(parsed.statistics.last.away, 0);
      expect(parsed.timeline, isEmpty);
    },
  );

  Future<
    ({
      ProviderContainer container,
      MutableRepository repository,
      GlobalKey preview,
    })
  >
  mount(
    WidgetTester tester,
    EventModel event, {
    double scale = 1,
    double width = 390,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final repository = MutableRepository(event);
    final container = ProviderContainer(
      overrides: [feedRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final preview = GlobalKey();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: preview,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: MatchDetailScreen(event: event),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (container: container, repository: repository, preview: preview);
  }

  Future<void> tab(WidgetTester tester, String label) async {
    final chip = find.widgetWithText(ChoiceChip, label);
    final vertical = find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;
    tester.state<ScrollableState>(vertical).position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(chip, 150, scrollable: vertical);
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(chip).selected, isTrue);
  }

  for (final status in ['SCHEDULED', 'LIVE', 'FINISHED', 'CANCELED']) {
    testWidgets(
      '$status muestra disponibilidad sin ejemplos ni marcadores programados',
      (tester) async {
        await mount(tester, sample(status: status, withDetail: false));
        expect(
          find.text(
            status == 'SCHEDULED' || status == 'CANCELED' ? 'VS' : '2 : 1',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Real Madrid'), findsNothing);
        expect(find.textContaining('Rodri'), findsNothing);
        await tab(tester, 'Estadísticas');
        expect(find.text('Estadísticas no disponibles'), findsOneWidget);
        expect(find.text('54%'), findsNothing);
        await tab(tester, 'Alineaciones');
        expect(find.text('Alineación no disponible'), findsNWidgets(2));
        expect(find.textContaining('4-3-3'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Presenta cronología, ceros reales, datos parciales y alineaciones',
    (tester) async {
      final app = await mount(tester, sample());
      expect(find.text('Jugador de prueba'), findsOneWidget);
      expect(find.text('Tarjeta amarilla'), findsOneWidget);
      expect(find.text('Entra: Entra de prueba'), findsOneWidget);
      await capturePreview(
        tester,
        app.preview.currentContext!.findRenderObject() as RenderRepaintBoundary,
        'futbol-resumen',
      );
      await tab(tester, 'Estadísticas');
      expect(find.text('60%'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      await capturePreview(
        tester,
        app.preview.currentContext!.findRenderObject() as RenderRepaintBoundary,
        'futbol-estadisticas',
      );
      await tab(tester, 'Alineaciones');
      expect(find.text('Formación 4-3-3'), findsOneWidget);
      expect(find.text('Titular de prueba'), findsOneWidget);
      expect(find.text('Alineación no disponible'), findsOneWidget);
      await capturePreview(
        tester,
        app.preview.currentContext!.findRenderObject() as RenderRepaintBoundary,
        'futbol-alineaciones',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Actualiza marcador y estado desde el feed sin perder pestaña', (
    tester,
  ) async {
    final app = await mount(tester, sample());
    await tab(tester, 'Estadísticas');
    app.repository.event = sample(status: 'FINISHED', score: '3 - 1');
    await app.container
        .read(feedNotifierProvider.notifier)
        .loadEvents(forceRefresh: true);
    await tester.pumpAndSettle();
    expect(find.text('3 : 1'), findsOneWidget);
    expect(find.text('FINALIZADO'), findsOneWidget);
    expect(find.text('Comparativa de equipos'), findsOneWidget);
    expect(find.text('67′'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    '320 px y texto doble conservan todas las secciones sin overflow',
    (tester) async {
      await mount(tester, sample(), width: 320, scale: 2);
      for (final label in ['Resumen', 'Estadísticas', 'Alineaciones']) {
        await tab(tester, label);
        await tester.drag(find.byType(ListView), const Offset(0, -350));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('Un detalle de otros equipos no se atribuye al partido', (
    tester,
  ) async {
    await mount(
      tester,
      sample().copyWith(
        homeTeam: const TeamModel(id: 'different', name: 'Otro equipo'),
      ),
    );
    expect(find.text('Jugador de prueba'), findsNothing);
    await tab(tester, 'Estadísticas');
    expect(find.text('Estadísticas no disponibles'), findsOneWidget);
    await tab(tester, 'Alineaciones');
    expect(find.text('Titular de prueba'), findsNothing);
  });

  testWidgets('Abre fútbol desde Inicio y vuelve conservando los filtros', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime.now();
    final event = sample().copyWith(startTime: now);
    final container = ProviderContainer(
      overrides: [
        feedRepositoryProvider.overrideWithValue(MutableRepository(event)),
      ],
    );
    container.read(selectedSportFilterProvider.notifier).state =
        SportType.soccer;
    final selectedDate = container.read(selectedFeedDateProvider);
    final router = createRouter();
    addTearDown(() {
      router.dispose();
      container.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: KambateApp(router: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(ScoreboardRow));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ScoreboardRow));
    await tester.pumpAndSettle();
    expect(find.byType(MatchDetailScreen), findsOneWidget);
    expect(find.text('2 : 1'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(MatchDetailScreen), findsNothing);
    expect(container.read(selectedSportFilterProvider), SportType.soccer);
    expect(container.read(selectedFeedDateProvider), selectedDate);
    expect(tester.takeException(), isNull);
  });
}
