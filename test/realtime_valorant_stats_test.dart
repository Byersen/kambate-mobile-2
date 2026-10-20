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

class RealtimeTestValorantRepository extends FeedRepository {
  RealtimeTestValorantRepository({required this.initial, required this.refreshed})
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

  test('EsportsStats reconoce eventId en camelCase y snake_case para Valorant', () {
    final camel = RealtimeEventUpdate.esportsStats({'eventId': 'val-event-1'});
    final snake = RealtimeEventUpdate.esportsStats({'event_id': 'val-event-2'});

    expect(camel?.eventId, 'val-event-1');
    expect(camel?.requiresRefresh, isTrue);
    expect(snake?.eventId, 'val-event-2');
    expect(RealtimeEventUpdate.esportsStats({}), isNull);
  });

  test(
    'una actualización de EsportsStats recarga el detalle completo de Valorant conservando favoritos',
    () async {
      final initial = EventModel(
        id: 'val-event-1',
        sport: SportType.valorant,
        league: 'VCT Americas',
        status: EventStatus.live,
        startTime: DateTime.utc(2026, 10, 20),
        homeScore: 1,
        awayScore: 0,
        isFavorite: true,
      );
      final refreshed = EventModel(
        id: 'val-event-1',
        sport: SportType.valorant,
        league: 'VCT Americas',
        status: EventStatus.live,
        startTime: DateTime.utc(2026, 10, 20),
        homeScore: 1,
        awayScore: 1,
        esportsStats: const EsportsStatsModel(
          id: 'es-val-event-1',
          format: 'Bo3',
          homeScore: 1,
          awayScore: 1,
          map: 'Ascent',
          extraStats: {
            'detail': {
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
                  'winnerParticipantId': 'kru',
                  'homeScore': 13,
                  'awayScore': 9,
                },
                {
                  'mapNumber': 2,
                  'mapName': 'Haven',
                  'status': 'finished',
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
                },
              ],
            },
          },
        ),
      );

      final repo = RealtimeTestValorantRepository(
        initial: initial,
        refreshed: refreshed,
      );
      final container = ProviderContainer(
        overrides: [feedRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(feedNotifierProvider.notifier);
      await notifier.loadEvents(forceRefresh: true);

      final initialFeed = container.read(feedNotifierProvider).asData?.value;
      expect(initialFeed?.first.esportsStats?.extraStats?['detail'], isNull);
      expect(initialFeed?.first.isFavorite, isTrue);

      final update = RealtimeEventUpdate.esportsStats({
        'eventId': 'val-event-1',
        'home_score': 1,
        'away_score': 1,
      });

      expect(update, isNotNull);
      await notifier.applyRealtimeUpdate(update!);

      final updatedEvents = container.read(feedNotifierProvider).asData?.value;
      expect(updatedEvents, isNotNull);
      final updatedEvent = updatedEvents!.firstWhere((e) => e.id == 'val-event-1');
      expect(updatedEvent.isFavorite, isTrue);
      expect(updatedEvent.esportsStats?.homeScore, 1);
      expect(updatedEvent.esportsStats?.awayScore, 1);
      expect(
        updatedEvent.esportsStats?.extraStats?['detail'],
        isA<Map<String, dynamic>>(),
      );
      expect(updatedEvent.valorantDetail, isNotNull);
      expect(updatedEvent.valorantDetail?.maps.length, 3);
      expect(updatedEvent.valorantDetail?.activeMap?.mapName, 'Ascent');
    },
  );
}
