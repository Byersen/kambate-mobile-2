import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/event_model.dart';
import '../../../models/event_status.dart';
import '../../../models/sport_type.dart';
import '../../../services/cache_service.dart';
import '../../../services/realtime_service.dart';
import '../data/feed_repository.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository();
});

/// Sport discipline filter (all, soccer, nba, ufc, lol, valorant)
final selectedSportFilterProvider = StateProvider<SportType>((ref) {
  return SportType.all;
});

/// League Tier filter (null = Todas las ligas, 1 = Tier 1 Élite, 2 = Tier 2 Secundarias)
final selectedLeagueTierProvider = StateProvider<int?>((ref) {
  return null;
});

class FeedNotifier extends StateNotifier<AsyncValue<List<EventModel>>> {
  final FeedRepository _repository;
  final Ref _ref;
  StreamSubscription<Map<String, dynamic>>? _realtimeSubscription;

  FeedNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadEvents();
    _listenToRealtimeUpdates();
  }

  /// Listen to Supabase Realtime PostgreSQL updates
  void _listenToRealtimeUpdates() {
    _realtimeSubscription = RealtimeService().onEventUpdate.listen((record) {
      final updatedId = record['id']?.toString();
      if (updatedId == null) return;

      state.whenData((events) {
        final index = events.indexWhere((e) => e.id == updatedId || e.externalId == updatedId);
        if (index != -1) {
          final oldEvent = events[index];

          // Parse updated fields from record
          int? newHomeScore;
          int? newAwayScore;
          if (record['home_score'] != null) {
            newHomeScore = int.tryParse(record['home_score'].toString());
          }
          if (record['away_score'] != null) {
            newAwayScore = int.tryParse(record['away_score'].toString());
          }

          EventStatus? newStatus;
          if (record['status'] != null) {
            newStatus = EventStatus.fromString(record['status'].toString());
          }

          final updatedEvent = oldEvent.copyWith(
            homeScore: newHomeScore ?? oldEvent.homeScore,
            awayScore: newAwayScore ?? oldEvent.awayScore,
            score: record['score']?.toString() ?? oldEvent.score,
            currentPeriod: record['current_period']?.toString() ??
                record['currentPeriod']?.toString() ??
                oldEvent.currentPeriod,
            status: newStatus ?? oldEvent.status,
          );

          final updatedList = List<EventModel>.from(events);
          updatedList[index] = updatedEvent;
          state = AsyncValue.data(updatedList);

          // Update local cache with updated event
          CacheService.saveEvents(updatedList);
          debugPrint('FeedNotifier: Realtime updated event $updatedId in state');
        }
      });
    });
  }

  Future<void> loadEvents({bool forceRefresh = false}) async {
    // If not forcing refresh and state already has data, don't show full loading spinner (stale-while-revalidate)
    if (!state.hasValue) {
      state = const AsyncValue.loading();
    }
    try {
      final selectedSport = _ref.read(selectedSportFilterProvider);
      final selectedTier = _ref.read(selectedLeagueTierProvider);
      final favoriteIds = await CacheService.getFavoriteIds();

      final rawEvents = await _repository.getEvents(
        sport: selectedSport,
        leagueTier: selectedTier,
        forceRefresh: forceRefresh,
      );

      // Restore saved favorite state
      final events = rawEvents.map((e) {
        if (favoriteIds.contains(e.id)) {
          return e.copyWith(isFavorite: true);
        }
        return e;
      }).toList();

      state = AsyncValue.data(events);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void toggleFavorite(String eventId) async {
    state.whenData((events) async {
      final updatedEvents = events.map((event) {
        if (event.id == eventId) {
          return event.copyWith(isFavorite: !event.isFavorite);
        }
        return event;
      }).toList();

      state = AsyncValue.data(updatedEvents);

      // Persist favorite IDs to local cache
      final favIds = updatedEvents
          .where((e) => e.isFavorite)
          .map((e) => e.id)
          .toSet();
      await CacheService.saveFavoriteIds(favIds);
    });
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
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

  // Re-fetch when league tier filter changes
  ref.listen<int?>(selectedLeagueTierProvider, (_, _) {
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
