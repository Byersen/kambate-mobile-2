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

  @override
  Future<List<EventModel>> getEvents({
    SportType? sport,
    int? leagueTier,
    bool forceRefresh = false,
  }) async {
    refreshes.add(forceRefresh);
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
}
