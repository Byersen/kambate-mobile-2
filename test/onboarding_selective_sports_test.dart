import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kambate_mobile/core/router/app_router.dart';
import 'package:kambate_mobile/core/theme/app_colors.dart';
import 'package:kambate_mobile/core/theme/app_theme.dart';
import 'package:kambate_mobile/features/favorites/presentation/widgets/favorites_sport_chips.dart';
import 'package:kambate_mobile/features/feed/data/feed_repository.dart';
import 'package:kambate_mobile/features/feed/presentation/screens/feed_screen.dart';
import 'package:kambate_mobile/features/feed/presentation/widgets/sport_filter_bar.dart';
import 'package:kambate_mobile/features/feed/providers/feed_provider.dart';
import 'package:kambate_mobile/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'package:kambate_mobile/models/event_status.dart';
import 'package:kambate_mobile/models/fighter_model.dart';
import 'package:kambate_mobile/models/sport_type.dart';
import 'package:kambate_mobile/models/team_model.dart';
import 'package:kambate_mobile/services/cache_service.dart';
import 'package:kambate_mobile/services/realtime_service.dart';
import 'support/preview.dart';

class _SelectiveTestFeedRepository extends FeedRepository {
  _SelectiveTestFeedRepository(this.remoteEvents)
      : super(subscribeToRealtime: false);

  final List<EventModel> remoteEvents;
  int fetchCalls = 0;

  @override
  Future<List<EventModel>> fetchRemoteEvents() async {
    fetchCalls++;
    return remoteEvents;
  }

  @override
  Future<EventModel?> getEventById(String id) async {
    for (final e in remoteEvents) {
      if (e.id == id || e.externalId == id) return e;
    }
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPreviewFonts);

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  List<EventModel> sampleAllSportsEvents() {
    final now = DateTime.now();
    final todayNoon = DateTime(now.year, now.month, now.day, 15, 0);
    return [
      EventModel(
        id: 'ev-soccer',
        sport: SportType.soccer,
        league: 'Champions League',
        status: EventStatus.scheduled,
        startTime: todayNoon,
        homeTeam: const TeamModel(id: 't-rm', name: 'Real Madrid'),
        awayTeam: const TeamModel(id: 't-bay', name: 'Bayern Munich'),
      ),
      EventModel(
        id: 'ev-nba',
        sport: SportType.nba,
        league: 'NBA',
        status: EventStatus.scheduled,
        startTime: todayNoon,
        homeTeam: const TeamModel(id: 't-lal', name: 'Lakers'),
        awayTeam: const TeamModel(id: 't-bos', name: 'Celtics'),
      ),
      EventModel(
        id: 'ev-ufc',
        sport: SportType.ufc,
        league: 'UFC 315',
        status: EventStatus.scheduled,
        startTime: todayNoon,
        fighter1: const FighterModel(id: 'f-1', name: 'Ilia Topuria'),
        fighter2: const FighterModel(id: 'f-2', name: 'Max Holloway'),
      ),
      EventModel(
        id: 'ev-lol',
        sport: SportType.lol,
        league: 'LCK',
        status: EventStatus.scheduled,
        startTime: todayNoon,
        homeTeam: const TeamModel(id: 't-t1', name: 'T1'),
        awayTeam: const TeamModel(id: 't-geng', name: 'Gen.G'),
      ),
      EventModel(
        id: 'ev-val',
        sport: SportType.valorant,
        league: 'VCT Americas',
        status: EventStatus.scheduled,
        startTime: todayNoon,
        homeTeam: const TeamModel(id: 't-kru', name: 'KRÜ'),
        awayTeam: const TeamModel(id: 't-lev', name: 'Leviatán'),
      ),
    ];
  }

  group('OnboardingScreen — Paleta de colores actual y selección de deportes', () {
    testWidgets(
      'Usa la paleta clara institucional (AppColors.background, primary, surface) y actualiza selección',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repo = _SelectiveTestFeedRepository(sampleAllSportsEvents());
        final router = createRouter(initialLocation: '/onboarding');
        addTearDown(router.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [feedRepositoryProvider.overrideWithValue(repo)],
            child: MaterialApp.router(
              theme: AppTheme.lightTheme,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
        expect(scaffold.backgroundColor, equals(AppColors.background));
        expect(find.text('Selecciona tus deportes favoritos'), findsOneWidget);
        expect(find.textContaining('Solo cargamos partidos de tus deportes elegidos'), findsNothing);
        expect(find.text('5 de 5 seleccionados'), findsOneWidget);

        // Deseleccionar UFC, Valorant y LoL dejando solo Fútbol y NBA
        await tester.tap(find.byKey(const ValueKey('onboarding_sport_card_ufc')));
        await tester.tap(
          find.byKey(const ValueKey('onboarding_sport_card_valorant')),
        );
        await tester.tap(find.byKey(const ValueKey('onboarding_sport_card_lol')));
        await tester.pumpAndSettle();

        expect(find.text('2 de 5 seleccionados'), findsOneWidget);

        // Continuar a Partidos
        await tester.tap(find.text('Continuar a Partidos'));
        await tester.pumpAndSettle();

        expect(find.byType(FeedScreen), findsOneWidget);
        final savedSports = await CacheService.getSelectedSportTypes();
        expect(savedSports, equals({SportType.soccer, SportType.nba}));

        // En SportFilterBar solo deben aparecer Fútbol y NBA
        final barFinder = find.byType(SportFilterBar);
        expect(
          find.descendant(of: barFinder, matching: find.text('Fútbol')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: barFinder, matching: find.text('NBA')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: barFinder, matching: find.text('UFC')),
          findsNothing,
        );
        expect(
          find.descendant(of: barFinder, matching: find.text('LoL')),
          findsNothing,
        );
        expect(
          find.descendant(of: barFinder, matching: find.text('Valorant')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'Al reabrir OnboardingScreen desde ajustes carga la selección guardada previamente',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'kambate_onboarding_completed_v1': true,
          'kambate_selected_sports_v1': ['soccer', 'lol'],
        });

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: OnboardingScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('2 de 5 seleccionados'), findsOneWidget);
      },
    );
  });

  group('Optimización de carga y ahorro de espacio por deportes seleccionados', () {
    test(
      'FeedRepository.buildEventSelect omite tablas de estadísticas de deportes no seleccionados',
      () {
        final onlySoccerAndNba = {SportType.soccer, SportType.nba};
        final select = FeedRepository.buildEventSelect(onlySoccerAndNba);

        expect(select, contains('sport:Sport!inner(id, name, slug)'));
        expect(select, contains('footballStats:FootballStats(*)'));
        expect(select, contains('nbaStats:NbaStats(*)'));
        expect(select, isNot(contains('ufcStats:UfcStats(*)')));
        expect(select, isNot(contains('esportsStats:EsportsStats(*)')));

        final slugs = FeedRepository.backendSportSlugs(onlySoccerAndNba);
        expect(slugs, containsAll(['football', 'soccer', 'nba', 'basketball']));
        expect(slugs, isNot(contains('ufc')));
        expect(slugs, isNot(contains('esports')));
      },
    );

    test(
      'CacheService depura eventos de deportes no seleccionados y ahorra espacio en almacenamiento local',
      () async {
        final allEvents = sampleAllSportsEvents();
        await CacheService.saveEvents(allEvents);

        final initialCached = await CacheService.getCachedEvents();
        expect(initialCached!.length, 5);

        // El usuario selecciona únicamente Fútbol y NBA
        await CacheService.saveSelectedSports(['soccer', 'nba']);

        final prunedCached = await CacheService.getCachedEvents();
        expect(prunedCached, isNotNull);
        expect(
          prunedCached!.map((e) => e.sport).toSet(),
          equals({SportType.soccer, SportType.nba}),
        );
        expect(prunedCached.length, 2);
      },
    );

    test(
      'FeedNotifier descarta de memoria y Realtime los eventos de deportes no seleccionados',
      () async {
        SharedPreferences.setMockInitialValues({
          'kambate_onboarding_completed_v1': true,
          'kambate_selected_sports_v1': ['soccer'],
        });

        final allEvents = sampleAllSportsEvents();
        final repo = _SelectiveTestFeedRepository(allEvents);
        final container = ProviderContainer(
          overrides: [feedRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);

        await container.read(feedNotifierProvider.notifier).loadEvents(
          forceRefresh: true,
        );

        final loaded = container.read(feedNotifierProvider).requireValue;
        expect(loaded.map((e) => e.id).toList(), equals(['ev-soccer']));

        // Simular una actualización Realtime de UFC (deporte NO seleccionado)
        final ufcUpdate = RealtimeEventUpdate.ufcStats({'eventId': 'ev-ufc'})!;
        await container
            .read(feedNotifierProvider.notifier)
            .applyRealtimeUpdate(ufcUpdate);

        final afterRealtime = container.read(feedNotifierProvider).requireValue;
        expect(
          afterRealtime.map((e) => e.id).toList(),
          equals(['ev-soccer']),
          reason: 'Eventos de deportes no seleccionados no deben cargarse en memoria por Realtime',
        );
      },
    );

    testWidgets(
      'SportFilterBar y FavoritesSportChips muestran únicamente los deportes seleccionados',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'kambate_onboarding_completed_v1': true,
          'kambate_selected_sports_v1': ['soccer', 'ufc'],
        });
        final selectedOnly = {SportType.soccer, SportType.ufc};

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              selectedSportsProvider.overrideWith(
                (ref) => SelectedSportsNotifier(ref, selectedOnly),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: Column(
                  children: [
                    SportFilterBar(
                      selectedSport: SportType.soccer,
                      availableSports: selectedOnly,
                      onSportSelected: (_) {},
                    ),
                    const FavoritesSportChips(),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Fútbol'), findsNWidgets(2));
        expect(find.text('UFC'), findsNWidgets(2));
        expect(find.text('NBA'), findsNothing);
        expect(find.text('LoL'), findsNothing);
        expect(find.text('League of Legends'), findsNothing);
        expect(find.text('Valorant'), findsNothing);
      },
    );
  });
}


