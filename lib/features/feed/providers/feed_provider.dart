import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/event_model.dart';
import '../../../models/sport_type.dart';
import '../data/feed_repository.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository();
});

final selectedSportFilterProvider = StateProvider<SportType>((ref) {
  return SportType.all;
});

class FeedNotifier extends StateNotifier<AsyncValue<List<EventModel>>> {
  final FeedRepository _repository;
  final Ref _ref;

  FeedNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadEvents();
  }

  Future<void> loadEvents() async {
    state = const AsyncValue.loading();
    try {
      final selectedSport = _ref.read(selectedSportFilterProvider);
      final events = await _repository.getEvents(sport: selectedSport);
      state = AsyncValue.data(events);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void toggleFavorite(String eventId) {
    state.whenData((events) {
      final updatedEvents = events.map((event) {
        if (event.id == eventId) {
          return event.copyWith(isFavorite: !event.isFavorite);
        }
        return event;
      }).toList();
      state = AsyncValue.data(updatedEvents);
    });
  }
}

final feedNotifierProvider =
    StateNotifierProvider<FeedNotifier, AsyncValue<List<EventModel>>>((ref) {
  final repository = ref.watch(feedRepositoryProvider);
  final notifier = FeedNotifier(repository, ref);

  // Re-fetch when the selected sport filter changes
  ref.listen<SportType>(selectedSportFilterProvider, (_, _) {
    notifier.loadEvents();
  });

  return notifier;
});

final favoriteEventsProvider = Provider<List<EventModel>>((ref) {
  final feedState = ref.watch(feedNotifierProvider);
  return feedState.maybeWhen(
    data: (events) => events.where((e) => e.isFavorite).toList(),
    orElse: () => [],
  );
});
