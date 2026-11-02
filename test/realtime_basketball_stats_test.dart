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

  test('NbaStats reconoce eventId en camelCase y snake_case', () {
    final camel = RealtimeEventUpdate.nbaStats({'eventId': 'nba-event-1'});
    final snake = RealtimeEventUpdate.nbaStats({'event_id': 'nba-event-2'});

    expect(camel?.eventId, 'nba-event-1');
    expect(camel?.requiresRefresh, isTrue);
    expect(snake?.eventId, 'nba-event-2');
    expect(RealtimeEventUpdate.nbaStats({}), isNull);
  });

  test(
    'una actualización de NbaStats actualiza el feed sin consulta adicional',
    () async {
      final initial = EventModel(
        id: 'nba-event-1',
        sport: SportType.nba,
        league: 'NBA',
        status: EventStatus.live,
        startTime: DateTime.utc(2026, 10, 18),
        homeScore: 81,
        awayScore: 77,
        isFavorite: true,
      );
      final refreshed = EventModel(
        id: 'nba-event-1',
        sport: SportType.nba,
        league: 'NBA',
        status: EventStatus.live,
        startTime: DateTime.utc(2026, 10, 18),
        homeScore: 84,
        awayScore: 79,
        nbaStats: const NbaStatsModel(
          id: 'nba-stats-1',
          eventId: 'nba-event-1',
          homePoints: 84,
          awayPoints: 79,
          quarter: '3',
          extraStats: {
            'clock': '02:34',
            'detail': {
              'version': 1,
              'homeParticipantId': 'lal',
              'awayParticipantId': 'bos',
              'periods': [
                {'period': '1', 'home': 28, 'away': 24},
                {'period': '2', 'home': 27, 'away': 26},
                {'period': '3', 'home': 29, 'away': 29},
              ],
            },
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

      await notifier.applyRealtimeUpdate(RealtimeEventUpdate.nbaStats({
        'eventId': 'nba-event-1', 'id': 'nba-stats-1',
        'homePoints': 84, 'awayPoints': 79, 'quarter': '3',
        'extraStats': {'clock': '02:34'},
      })!);

      final event = container.read(feedNotifierProvider).requireValue.single;
      expect(event.homeScore, 84);
      expect(event.awayScore, 79);
      expect(event.nbaStats?.homePoints, 84);
      expect(event.nbaStats?.extraStats?['clock'], '02:34');
      expect(event.isFavorite, isTrue);
      expect(repository.detailRequests, 0);
    },
  );
}
