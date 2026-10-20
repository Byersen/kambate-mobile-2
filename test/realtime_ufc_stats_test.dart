import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kambate_mobile/features/feed/data/feed_repository.dart';
import 'package:kambate_mobile/features/feed/providers/feed_provider.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'package:kambate_mobile/models/event_status.dart';
import 'package:kambate_mobile/models/fighter_model.dart';
import 'package:kambate_mobile/models/sport_type.dart';
import 'package:kambate_mobile/models/stats_models.dart';
import 'package:kambate_mobile/services/realtime_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RealtimeTestUfcRepository extends FeedRepository {
  RealtimeTestUfcRepository({required this.initial, required this.refreshed})
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

  test('UfcStats reconoce eventId en camelCase y snake_case para UFC', () {
    final camel = RealtimeEventUpdate.ufcStats({'eventId': 'ufc-event-1'});
    final snake = RealtimeEventUpdate.ufcStats({'event_id': 'ufc-event-2'});

    expect(camel?.eventId, 'ufc-event-1');
    expect(camel?.requiresRefresh, isTrue);
    expect(snake?.eventId, 'ufc-event-2');
    expect(RealtimeEventUpdate.ufcStats({}), isNull);
  });

  test(
    'una actualización de UfcStats recarga el detalle completo de UFC conservando favoritos',
    () async {
      final initial = EventModel(
        id: 'ufc-event-1',
        sport: SportType.ufc,
        league: 'UFC • Noche de combates',
        status: EventStatus.scheduled,
        startTime: DateTime.utc(2026, 10, 20, 20, 0),
        fighter1: const FighterModel(id: 'f1', name: 'Diego Silva'),
        fighter2: const FighterModel(id: 'f2', name: 'Lucas Costa'),
        isFavorite: true,
      );
      final refreshed = EventModel(
        id: 'ufc-event-1',
        sport: SportType.ufc,
        league: 'UFC • Noche de combates',
        status: EventStatus.live,
        startTime: DateTime.utc(2026, 10, 20, 20, 0),
        fighter1: const FighterModel(id: 'f1', name: 'Diego Silva'),
        fighter2: const FighterModel(id: 'f2', name: 'Lucas Costa'),
        ufcStats: const UfcStatsModel(
          id: 'us-1',
          round: 2,
          time: '03:12',
          extraStats: {
            'card': {
              'version': 1,
              'cardId': 'ufc-card-santiago',
              'name': 'Santiago',
              'status': 'live',
              'fights': [],
            },
          },
        ),
      );

      final repository = RealtimeTestUfcRepository(
        initial: initial,
        refreshed: refreshed,
      );
      final container = ProviderContainer(
        overrides: [feedRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container.read(feedNotifierProvider.notifier).loadEvents();
      final before = container.read(feedNotifierProvider).asData?.value.first;
      expect(before?.status, EventStatus.scheduled);
      expect(before?.isFavorite, isTrue);

      final update = RealtimeEventUpdate.ufcStats({
        'eventId': 'ufc-event-1',
        'round': 2,
      })!;
      await container
          .read(feedNotifierProvider.notifier)
          .applyRealtimeUpdate(update);

      final after = container.read(feedNotifierProvider).asData?.value.first;
      expect(after?.status, EventStatus.live);
      expect(after?.ufcCard?.name, equals('Santiago'));
      expect(after?.isFavorite, isTrue);
    },
  );
}
