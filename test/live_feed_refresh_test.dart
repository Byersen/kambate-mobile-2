import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kambate_mobile/core/utils/match_minute_formatter.dart';
import 'package:kambate_mobile/features/feed/data/feed_repository.dart';
import 'package:kambate_mobile/features/feed/providers/feed_provider.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'package:kambate_mobile/models/event_status.dart';
import 'package:kambate_mobile/models/sport_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClockRepository extends FeedRepository {
  ClockRepository(this.event) : super(subscribeToRealtime: false);

  EventModel event;
  final refreshes = <bool>[];
  List<String>? lastTrackedLiveIds;

  @override
  Future<List<EventModel>> getEvents({
    SportType? sport,
    int? leagueTier,
    bool forceRefresh = false,
  }) async {
    refreshes.add(forceRefresh);
    return [event];
  }

  @override
  Future<List<EventModel>> fetchLiveAndDueEvents(
    List<String> trackedLiveIds,
  ) async {
    lastTrackedLiveIds = trackedLiveIds;
    refreshes.add(true);
    return [event];
  }
}

void main() {
  testWidgets('refresca el minuto sin realtime y se pausa en segundo plano', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    EventModel payload(String clock) => EventModel.fromJson({
      'id': 'live-match',
      'sport': {'slug': 'football'},
      'status': 'LIVE',
      'startDate': '2026-10-24T20:00:00Z',
      'footballStats': [
        {
          'id': 'stats',
          'extraStats': {'clock': clock},
        },
      ],
    });
    final repository = ClockRepository(payload("23'"));
    final container = ProviderContainer(
      overrides: [feedRepositoryProvider.overrideWithValue(repository)],
    );
    final notifier = container.read(feedNotifierProvider.notifier);
    await notifier.loadEvents(forceRefresh: true);
    notifier.startLiveRefresh();
    expect(repository.refreshes, [true]);

    repository.event = payload("24'");
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(repository.refreshes, [true, true]);
    expect(repository.lastTrackedLiveIds, ['live-match']);
    expect(
      MatchMinuteFormatter.format(
        container.read(feedNotifierProvider).requireValue.single,
      ),
      '24′',
    );

    notifier.onAppPaused();
    await tester.pump(const Duration(minutes: 1));
    expect(repository.refreshes, [true, true]);

    await notifier.onAppResumed();
    final resumedCount = repository.refreshes.length;
    repository.event = payload("45'+2'");
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(repository.refreshes.length, resumedCount + 1);
    expect(
      MatchMinuteFormatter.format(
        container.read(feedNotifierProvider).requireValue.single,
      ),
      '45+2′',
    );

    repository.event = repository.event.copyWith(status: EventStatus.finished);
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    final finishedCount = repository.refreshes.length;
    await tester.pump(const Duration(seconds: 30));
    expect(repository.refreshes.length, finishedCount);
    container.dispose();
  });

  testWidgets(
    'refreshLivePulse hace merge de partido SCHEDULED próximo a iniciar sin estado loading',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final dueStart = DateTime.now().add(const Duration(minutes: 2)).toUtc();
      final scheduledDue = EventModel(
        id: 'due-match',
        sport: SportType.soccer,
        league: 'Primera División',
        status: EventStatus.scheduled,
        startTime: dueStart,
      );

      final repository = ClockRepository(scheduledDue);
      final container = ProviderContainer(
        overrides: [feedRepositoryProvider.overrideWithValue(repository)],
      );
      final notifier = container.read(feedNotifierProvider.notifier);
      await notifier.loadEvents(forceRefresh: true);
      notifier.startLiveRefresh();

      final states = <AsyncValue<List<EventModel>>>[];
      container.listen(
        feedNotifierProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      repository.event = scheduledDue.copyWith(
        status: EventStatus.live,
        homeScore: 1,
        awayScore: 0,
        score: '1 - 0',
      );

      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();

      expect(states.any((s) => s.isLoading), isFalse);
      final updated = container.read(feedNotifierProvider).requireValue.single;
      expect(updated.status, EventStatus.live);
      expect(updated.homeScore, 1);
      container.dispose();
    },
  );
}
