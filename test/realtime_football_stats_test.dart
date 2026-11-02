import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kambate_mobile/features/feed/data/feed_repository.dart';
import 'package:kambate_mobile/features/feed/providers/feed_provider.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'package:kambate_mobile/models/event_status.dart';
import 'package:kambate_mobile/models/sport_type.dart';
import 'package:kambate_mobile/models/stats_models.dart';
import 'package:kambate_mobile/services/realtime_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RealtimeTestRepository extends FeedRepository {
  RealtimeTestRepository({required this.initial, required this.refreshed})
    : super(subscribeToRealtime: false);

  final EventModel initial;
  final EventModel refreshed;
  int detailRequests = 0;

  @override
  Future<List<EventModel>> fetchRemoteEvents() async => [initial];

  @override
  Future<EventModel?> getEventById(String id) async {
    detailRequests++;
    return id == refreshed.id ? refreshed : null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('FootballStats reconoce eventId en camelCase y snake_case', () {
    final camel = RealtimeEventUpdate.footballStats({'eventId': 'event-1'});
    final snake = RealtimeEventUpdate.footballStats({'event_id': 'event-2'});

    expect(camel?.eventId, 'event-1');
    expect(camel?.requiresRefresh, isTrue);
    expect(snake?.eventId, 'event-2');
    expect(RealtimeEventUpdate.footballStats({}), isNull);
  });

  test(
    'una actualización de FootballStats actualiza el feed sin consultar el detalle',
    () async {
      final initial = EventModel(
        id: 'event-1',
        sport: SportType.soccer,
        league: 'Premier League',
        status: EventStatus.live,
        startTime: DateTime.utc(2026, 10, 17),
        homeScore: 1,
        awayScore: 0,
        isFavorite: true,
      );
      final refreshed = EventModel(
        id: 'event-1',
        sport: SportType.soccer,
        league: 'Premier League',
        status: EventStatus.live,
        startTime: DateTime.utc(2026, 10, 17),
        homeScore: 2,
        awayScore: 0,
        footballStats: const FootballStatsModel(
          id: 'stats-1',
          eventId: 'event-1',
          homeGoals: 2,
          awayGoals: 0,
          extraStats: {
            'detail': {'version': 1},
          },
        ),
      );
      final repository = RealtimeTestRepository(
        initial: initial,
        refreshed: refreshed,
      );
      final container = ProviderContainer(
        overrides: [feedRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(feedNotifierProvider.notifier);
      await notifier.loadEvents(forceRefresh: true);

      await notifier.applyRealtimeUpdate(RealtimeEventUpdate.footballStats({
        'eventId': 'event-1', 'id': 'stats-1',
        'homeGoals': 2, 'awayGoals': 0,
      })!);

      final event = container.read(feedNotifierProvider).requireValue.single;
      expect(event.homeScore, 2);
      expect(event.footballStats?.homeGoals, 2);
      expect(event.isFavorite, isTrue);
      expect(repository.detailRequests, 0);
    },
  );
}
