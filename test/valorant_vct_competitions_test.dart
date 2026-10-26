import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kambate_mobile/features/favorites/models/search_league_item.dart';
import 'package:kambate_mobile/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:kambate_mobile/features/favorites/providers/favorites_provider.dart';
import 'package:kambate_mobile/features/feed/data/feed_repository.dart';
import 'package:kambate_mobile/features/feed/presentation/screens/feed_screen.dart';
import 'package:kambate_mobile/features/feed/providers/feed_provider.dart';
import 'package:kambate_mobile/features/league_detail/data/league_detail_repository.dart';
import 'package:kambate_mobile/features/league_detail/presentation/screens/league_detail_screen.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'package:kambate_mobile/models/event_status.dart';
import 'package:kambate_mobile/models/league_model.dart';
import 'package:kambate_mobile/models/season_model.dart';
import 'package:kambate_mobile/models/sport_type.dart';
import 'package:kambate_mobile/models/team_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeFeedRepository extends FeedRepository {
  final List<EventModel> eventsList;
  _FakeFeedRepository(this.eventsList) : super(subscribeToRealtime: false);

  @override
  Future<List<EventModel>> fetchRemoteEvents() async => eventsList;

  @override
  Future<EventModel?> getEventById(String id) async {
    return eventsList.cast<EventModel?>().firstWhere(
      (e) => e?.id == id || e?.externalId == id,
      orElse: () => null,
    );
  }
}

EventModel _buildTestValorantEvent({
  required String id,
  required String leagueName,
  required String leagueSlug,
  required String homeTeam,
  required String awayTeam,
  String? seasonName,
  DateTime? startTime,
  EventStatus status = EventStatus.scheduled,
  int? homeScore,
  int? awayScore,
  String? phase,
}) {
  final now = startTime ?? DateTime.now();
  return EventModel(
    id: id,
    sport: SportType.valorant,
    league: leagueName,
    currentPeriod: phase ?? 'Regular Season',
    startTime: now,
    status: status,
    leagueModel: LeagueModel(
      id: 'league-$leagueSlug',
      name: leagueName,
      slug: leagueSlug,
      country: 'Internacional',
    ),
    seasonModel: SeasonModel(
      id: 'season-$leagueSlug-2026',
      name: seasonName ?? '2026 Season',
      slug: '$leagueSlug-2026',
    ),
    homeTeam: TeamModel(id: 't-$homeTeam', name: homeTeam),
    awayTeam: TeamModel(id: 't-$awayTeam', name: awayTeam),
    homeScore: homeScore,
    awayScore: awayScore,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Tarea 32 — Valorant VCT, Ascension, Masters y Champions', () {
    test('resolveLeagueSlug mapea con exactitud torneos y competiciones de Valorant', () {
      expect(LeagueDetailRepository.resolveLeagueSlug('Valorant Champions'), equals('valorant-champions'));
      expect(LeagueDetailRepository.resolveLeagueSlug('VCT Champions 2026'), equals('valorant-champions'));
      expect(LeagueDetailRepository.resolveLeagueSlug('Valorant Masters'), equals('valorant-masters'));
      expect(LeagueDetailRepository.resolveLeagueSlug('VCT Masters Tokyo'), equals('valorant-masters'));
      expect(LeagueDetailRepository.resolveLeagueSlug('VCT Ascension Americas'), equals('vct-ascension-americas'));
      expect(LeagueDetailRepository.resolveLeagueSlug('VCT Americas'), equals('vct-americas'));
      expect(LeagueDetailRepository.resolveLeagueSlug('VCT EMEA'), equals('vct-emea'));

      // Verificar que Champions League de fútbol no colisiona
      expect(LeagueDetailRepository.resolveLeagueSlug('Champions League'), equals('uefa.champions'));
    });

    test('kCanonicalLeagues separa Ligas de Competiciones para Valorant', () {
      final championsItem = kCanonicalLeagues.firstWhere((l) => l.name == 'Valorant Champions');
      final mastersItem = kCanonicalLeagues.firstWhere((l) => l.name == 'Valorant Masters');
      final americasItem = kCanonicalLeagues.firstWhere((l) => l.name == 'VCT Americas');
      final emeaItem = kCanonicalLeagues.firstWhere((l) => l.name == 'VCT EMEA');
      final ascensionItem = kCanonicalLeagues.firstWhere((l) => l.name == 'VCT Ascension Americas');

      expect(championsItem.isCompetition, isTrue);
      expect(mastersItem.isCompetition, isTrue);
      expect(americasItem.isCompetition, isFalse);
      expect(emeaItem.isCompetition, isFalse);
      expect(ascensionItem.isCompetition, isFalse);
    });

    testWidgets('FeedScreen al elegir Valorant sólo muestra VCT Americas, EMEA y Ascension Americas', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final now = DateTime.now();
      final testEvents = [
        _buildTestValorantEvent(
          id: 'val-1',
          leagueName: 'VCT Americas',
          leagueSlug: 'vct-americas',
          homeTeam: 'Sentinels',
          awayTeam: 'Leviatán',
          startTime: now,
        ),
        _buildTestValorantEvent(
          id: 'val-2',
          leagueName: 'VCT EMEA',
          leagueSlug: 'vct-emea',
          homeTeam: 'Fnatic',
          awayTeam: 'Team Heretics',
          startTime: now,
        ),
        _buildTestValorantEvent(
          id: 'val-3',
          leagueName: 'VCT Ascension Americas',
          leagueSlug: 'vct-ascension-americas',
          homeTeam: '2Game Esports',
          awayTeam: 'M80',
          startTime: now,
        ),
        _buildTestValorantEvent(
          id: 'val-4',
          leagueName: 'Valorant Champions',
          leagueSlug: 'valorant-champions',
          homeTeam: 'EDward Gaming',
          awayTeam: 'Team Heretics',
          startTime: now,
        ),
        _buildTestValorantEvent(
          id: 'val-5',
          leagueName: 'Valorant Masters',
          leagueSlug: 'valorant-masters',
          homeTeam: 'Gen.G',
          awayTeam: 'Team Heretics',
          startTime: now,
        ),
        _buildTestValorantEvent(
          id: 'val-6',
          leagueName: 'Game Changers Championship',
          leagueSlug: 'valorant-game-changers',
          homeTeam: 'Shopify Rebellion',
          awayTeam: 'MIBR GC',
          startTime: now,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          feedRepositoryProvider.overrideWithValue(_FakeFeedRepository(testEvents)),
          selectedSportFilterProvider.overrideWith((ref) => SportType.valorant),
          selectedFeedDateProvider.overrideWith((ref) => now),
        ],
      );
      addTearDown(container.dispose);
      await container.read(feedNotifierProvider.notifier).loadEvents(forceRefresh: true);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: FeedScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Deben aparecer los partidos de VCT Americas, VCT EMEA y VCT Ascension Americas
      expect(find.text('Sentinels'), findsOneWidget);
      expect(find.text('Leviatán'), findsOneWidget);
      expect(find.text('Fnatic'), findsOneWidget);
      expect(find.text('2Game Esports'), findsOneWidget);

      // NO deben aparecer Champions, Masters ni Game Changers en el feed regional de partidos
      expect(find.text('EDward Gaming'), findsNothing);
      expect(find.text('Gen.G'), findsNothing);
      expect(find.text('Shopify Rebellion'), findsNothing);
    });

    testWidgets('FavoritesScreen separa Competiciones (Champions, Masters) y Ligas para Valorant', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer(
        overrides: [
          favoritesSportFilterProvider.overrideWith((ref) => SportType.valorant),
          favoritesRegionFilterProvider.overrideWith((ref) => 'Todos'),
          feedRepositoryProvider.overrideWithValue(_FakeFeedRepository([])),
        ],
      );
      addTearDown(container.dispose);
      await container.read(feedNotifierProvider.notifier).loadEvents(forceRefresh: true);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: FavoritesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar que existen los encabezados de secciones diferenciadas
      expect(find.text('COMPETICIONES'), findsOneWidget);
      expect(find.text('LIGAS'), findsOneWidget);

      // Verificar que están las tarjetas de Champions y Masters en Competiciones
      expect(find.text('Valorant Champions'), findsOneWidget);
      expect(find.text('Valorant Masters'), findsOneWidget);

      // Verificar que están las tarjetas de las ligas regionales
      expect(find.text('VCT Americas'), findsOneWidget);
      expect(find.text('VCT EMEA'), findsOneWidget);
      expect(find.text('VCT Ascension Americas'), findsOneWidget);
    });

    testWidgets('LeagueDetailScreen para Valorant Champions sólo muestra partidos de Champions sin mezclar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final now = DateTime.now();
      final allEvents = [
        _buildTestValorantEvent(
          id: 'champ-1',
          leagueName: 'Valorant Champions',
          leagueSlug: 'valorant-champions',
          homeTeam: 'EDward Gaming',
          awayTeam: 'Team Heretics',
          seasonName: 'Champions 2026 Seoul',
          startTime: now,
          status: EventStatus.finished,
          homeScore: 3,
          awayScore: 2,
        ),
        _buildTestValorantEvent(
          id: 'vct-1',
          leagueName: 'VCT Americas',
          leagueSlug: 'vct-americas',
          homeTeam: 'Sentinels',
          awayTeam: 'Leviatán',
          seasonName: 'Stage 1',
          startTime: now,
        ),
        _buildTestValorantEvent(
          id: 'mast-1',
          leagueName: 'Valorant Masters',
          leagueSlug: 'valorant-masters',
          homeTeam: 'Gen.G',
          awayTeam: 'Paper Rex',
          seasonName: 'Masters Shanghai',
          startTime: now,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          feedRepositoryProvider.overrideWithValue(_FakeFeedRepository(allEvents)),
        ],
      );
      addTearDown(container.dispose);
      await container.read(feedNotifierProvider.notifier).loadEvents(forceRefresh: true);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LeagueDetailScreen(
              leagueName: 'Valorant Champions',
              sport: SportType.valorant,
              leagueSlug: 'valorant-champions',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Debe aparecer el partido de Champions
      expect(find.text('EDward Gaming'), findsOneWidget);
      expect(find.text('Team Heretics'), findsOneWidget);

      // NO deben aparecer partidos de VCT Americas ni de Masters
      expect(find.text('Sentinels'), findsNothing);
      expect(find.text('Leviatán'), findsNothing);
      expect(find.text('Paper Rex'), findsNothing);
    });

    testWidgets('LeagueDetailScreen muestra estado claro Sin cobertura disponible cuando no hay partidos', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer(
        overrides: [
          feedRepositoryProvider.overrideWithValue(_FakeFeedRepository([])),
        ],
      );
      addTearDown(container.dispose);
      await container.read(feedNotifierProvider.notifier).loadEvents(forceRefresh: true);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LeagueDetailScreen(
              leagueName: 'Valorant Masters',
              sport: SportType.valorant,
              leagueSlug: 'valorant-masters',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sin cobertura disponible'), findsOneWidget);
      expect(find.text('No se registran partidos o ediciones de Valorant Masters en la fuente oficial.'), findsOneWidget);
    });
  });
}
