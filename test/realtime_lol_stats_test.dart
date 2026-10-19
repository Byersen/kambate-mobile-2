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

class RealtimeTestLolRepository extends FeedRepository {
  RealtimeTestLolRepository({required this.initial, required this.refreshed})
    : super(subscribeToRealtime: false);

  final EventModel initial;
  final EventModel refreshed;

  @override
  Future<List<EventModel>> fetchRemoteEvents() async => [initial];

  @override
  Future<EventModel?> getEventById(String id) async {
    return id == refreshed.id ? refreshed : null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('EsportsStats reconoce eventId en camelCase y snake_case', () {
    final camel = RealtimeEventUpdate.esportsStats({'eventId': 'lol-event-1'});
    final snake = RealtimeEventUpdate.esportsStats({'event_id': 'lol-event-2'});

    expect(camel?.eventId, 'lol-event-1');
    expect(camel?.requiresRefresh, isTrue);
    expect(snake?.eventId, 'lol-event-2');
    expect(RealtimeEventUpdate.esportsStats({}), isNull);
  });

  test(
    'una actualización de EsportsStats recarga el detalle completo de LoL conservando favoritos',
    () async {
      final initial = EventModel(
        id: 'lol-event-1',
        sport: SportType.lol,
        league: 'LCK',
        status: EventStatus.live,
        startTime: DateTime.utc(2026, 10, 19),
        homeScore: 1,
        awayScore: 0,
        isFavorite: true,
      );
      final refreshed = EventModel(
        id: 'lol-event-1',
        sport: SportType.lol,
        league: 'LCK',
        status: EventStatus.live,
        startTime: DateTime.utc(2026, 10, 19),
        homeScore: 1,
        awayScore: 1,
        esportsStats: const EsportsStatsModel(
          id: 'esports-stats-1',
          eventId: 'lol-event-1',
          homeScore: 1,
          awayScore: 1,
          format: 'Bo3',
          map: 'Grieta del Invocador',
          extraStats: {
            'detail': {
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
                },
                {
                  'gameNumber': 2,
                  'status': 'finished',
                  'duration': '34:08',
                  'winnerParticipantId': 'geng',
                  'homeKills': 12,
                  'awayKills': 21,
                },
                {
                  'gameNumber': 3,
                  'status': 'live',
                  'duration': '24:15',
                  'homeKills': 14,
                  'awayKills': 12,
                },
              ],
            },
          },
        ),
      );
      final repository = RealtimeTestLolRepository(
        initial: initial,
        refreshed: refreshed,
      );
      final container = ProviderContainer(
        overrides: [feedRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(feedNotifierProvider.notifier);
      await notifier.loadEvents(forceRefresh: true);

      await notifier.applyRealtimeUpdate(
        const RealtimeEventUpdate(
          eventId: 'lol-event-1',
          record: {'eventId': 'lol-event-1'},
          requiresRefresh: true,
        ),
      );

      final state = container.read(feedNotifierProvider).asData?.value;
      final event = state?.firstWhere((e) => e.id == 'lol-event-1');
      expect(event?.isFavorite, isTrue);
      expect(event?.homeScore, 1);
      expect(event?.awayScore, 1);
      expect(event?.esportsStats?.format, 'Bo3');
    },
  );
}
