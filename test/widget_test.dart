import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kambate_mobile/core/router/app_router.dart';
import 'package:kambate_mobile/features/feed/providers/feed_provider.dart';
import 'package:kambate_mobile/features/feed/presentation/widgets/scoreboard_row.dart';
import 'package:kambate_mobile/features/match_detail/presentation/screens/match_detail_screen.dart';
import 'package:kambate_mobile/main.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'package:kambate_mobile/models/event_status.dart';
import 'package:kambate_mobile/models/sport_type.dart';
import 'package:kambate_mobile/models/team_model.dart';
import 'feed_repository_test.dart' show TestRepository;
import 'support/preview.dart';

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
    EventModel event(
      String id,
      SportType sport,
      EventStatus status,
      String home,
      String away,
      int? homeScore,
      int? awayScore,
    ) => EventModel(
      id: id,
      sport: sport,
      status: status,
      league: sport == SportType.nba
          ? 'NBA · Temporada regular'
          : 'Primera División',
      startTime: DateTime(now.year, now.month, now.day, 21),
      currentPeriod: status == EventStatus.live ? '67′' : null,
      homeTeam: TeamModel(id: '$id-home', name: home),
      awayTeam: TeamModel(id: '$id-away', name: away),
      homeScore: homeScore,
      awayScore: awayScore,
    );
    return [
      event(
        'football',
        SportType.soccer,
        EventStatus.live,
        'Colo-Colo',
        'U. de Chile',
        2,
        1,
      ),
      event(
        'nba',
        SportType.nba,
        EventStatus.scheduled,
        'Lakers',
        'Celtics',
        null,
        null,
      ),
      event(
        'result',
        SportType.soccer,
        EventStatus.finished,
        'Arsenal',
        'Chelsea',
        3,
        1,
      ),
    ];
  }

  Future<({ProviderContainer container, GoRouter router, GlobalKey preview})>
  mount(WidgetTester tester, {bool fail = false, double textScale = 1}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final repository = TestRepository(events: fixtures(), fail: fail);
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
      expect(app.container.read(feedNotifierProvider).requireValue.length, 3);
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
    expect(GoRouterState.of(tester.element(detail)).uri.path, '/detail/nba');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(app.container.read(selectedSportFilterProvider), SportType.nba);
    expect(app.container.read(selectedFeedDateProvider), date);
    expect(find.text('Lakers'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Un error conserva controles y ofrece reintento', (tester) async {
    await mount(tester, fail: true);
    expect(find.text('No pudimos cargar los partidos'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Colo-Colo'), findsNothing);
    expect(find.text('NBA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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
