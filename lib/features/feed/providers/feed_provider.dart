import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/event_model.dart';
import '../../../models/event_status.dart';
import '../../../models/sport_type.dart';
import '../../../services/cache_service.dart';
import '../../../services/realtime_service.dart';
import '../data/feed_repository.dart';
import 'connection_provider.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository();
});

/// Sport discipline filter (defaults to soccer; soccer, nba, ufc, lol, valorant)
final selectedSportFilterProvider = StateProvider<SportType>((ref) {
  return SportType.soccer;
});

final selectedEventStatusProvider = StateProvider<EventStatus?>((ref) => null);
final feedDataSourceProvider = StateProvider<FeedDataSource>(
  (ref) => FeedDataSource.remote,
);
final feedLastUpdatedProvider = StateProvider<DateTime?>((ref) => null);

/// League Tier filter (null = Todas las ligas, 1 = Tier 1 Élite, 2 = Tier 2 Secundarias)
final selectedLeagueTierProvider = StateProvider<int?>((ref) {
  return null;
});

/// Selected date filter for the main feed carousel (defaults to today)
final selectedFeedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

class FeedNotifier extends StateNotifier<AsyncValue<List<EventModel>>> {
  final FeedRepository _repository;
  final Ref _ref;
  StreamSubscription<RealtimeEventUpdate>? _realtimeSubscription;
  DateTime? _lastRefreshTime;
  bool _isLoading = false;

  FeedNotifier(this._repository, this._ref)
    : super(const AsyncValue.loading()) {
    loadEvents(forceRefresh: true);
    _listenToRealtimeUpdates();
  }

  DateTime? get lastRefreshTime => _lastRefreshTime;
  bool get isLoading => _isLoading;

  /// Listen to Supabase Realtime PostgreSQL updates
  void _listenToRealtimeUpdates() {
    _realtimeSubscription = RealtimeService().onEventUpdate.listen(
      applyRealtimeUpdate,
    );
  }

  /// Maneja el regreso a la app desde segundo plano.
  /// Evita solicitudes duplicadas o en ráfaga con un enfriamiento de 15 segundos.
  Future<void> onAppResumed() async {
    if (_isLoading) return;
    if (_lastRefreshTime != null &&
        DateTime.now().difference(_lastRefreshTime!) <
            const Duration(seconds: 15)) {
      return;
    }
    await RealtimeService().reconnectIfNeeded();
    await loadEvents(forceRefresh: true);
  }

  /// Pausa temporizadores pendientes cuando la app pasa a segundo plano o inactiva.
  void onAppPaused() {
    RealtimeService().pause();
  }

  @visibleForTesting
  Future<void> applyRealtimeUpdate(RealtimeEventUpdate update) async {
    if (update.requiresRefresh) {
      final refreshed = await _repository.getEventById(update.eventId);
      if (!mounted || refreshed == null) return;
      final events = state.asData?.value;
      if (events == null) return;
      final index = events.indexWhere(
        (event) =>
            event.id == update.eventId || event.externalId == update.eventId,
      );
      if (index == -1) {
        final updatedList = List<EventModel>.from(events)..add(refreshed);
        state = AsyncValue.data(updatedList);
        await CacheService.saveEvents(updatedList);
        return;
      }

      final updatedList = List<EventModel>.from(events);
      updatedList[index] = refreshed.copyWith(
        isFavorite: events[index].isFavorite,
      );
      state = AsyncValue.data(updatedList);
      await CacheService.saveEvents(updatedList);
      debugPrint('FeedNotifier: refreshed stats for ${update.eventId}');
      return;
    }

    final events = state.asData?.value;
    if (events == null) return;
    final record = update.record;
    final index = events.indexWhere(
      (event) =>
          event.id == update.eventId || event.externalId == update.eventId,
    );
    if (index == -1) {
      final newEvent = await _repository.getEventById(update.eventId);
      if (newEvent != null && mounted) {
        final currentEvents = state.asData?.value ?? [];
        final updatedList = List<EventModel>.from(currentEvents)..add(newEvent);
        state = AsyncValue.data(updatedList);
        await CacheService.saveEvents(updatedList);
      }
      return;
    }
    final oldEvent = events[index];

    EventStatus? newStatus;
    if (record['status'] != null) {
      newStatus = EventStatus.fromString(record['status'].toString());
    }

    int? newHomeScore;
    int? newAwayScore;
    final scoreMatch = RegExp(
      r'(\d+)\s*[-–:]\s*(\d+)',
    ).firstMatch(record['score']?.toString() ?? '');
    if (scoreMatch != null) {
      newHomeScore = int.parse(scoreMatch.group(1)!);
      newAwayScore = int.parse(scoreMatch.group(2)!);
    }
    if (record['home_score'] != null) {
      newHomeScore = int.tryParse(record['home_score'].toString());
    }
    if (record['away_score'] != null) {
      newAwayScore = int.tryParse(record['away_score'].toString());
    }

    DateTime? newStartTime;
    final rawDate =
        record['startDate'] ?? record['start_time'] ?? record['startTime'];
    if (rawDate != null) {
      try {
        String dateStr = rawDate.toString();
        if (!RegExp(
          r'(Z|[+-]\d{2}:?\d{2})$',
          caseSensitive: false,
        ).hasMatch(dateStr)) {
          dateStr += 'Z';
        }
        newStartTime = DateTime.parse(dateStr).toLocal();
      } catch (_) {}
    }

    final effectiveStatus = newStatus ?? oldEvent.status;
    final isScheduled = effectiveStatus == EventStatus.scheduled;

    final effectiveHomeScore =
        isScheduled ? null : (newHomeScore ?? oldEvent.homeScore);
    final effectiveAwayScore =
        isScheduled ? null : (newAwayScore ?? oldEvent.awayScore);

    String? effectiveScore =
        isScheduled ? null : (record['score']?.toString() ?? oldEvent.score);
    if (!isScheduled) {
      if (effectiveScore == 'vs') {
        effectiveScore = null;
      } else if ((effectiveScore == null || effectiveScore.isEmpty) &&
          effectiveHomeScore != null &&
          effectiveAwayScore != null) {
        effectiveScore = '$effectiveHomeScore - $effectiveAwayScore';
      }
    }

    final updatedEvent = oldEvent.copyWith(
      homeScore: effectiveHomeScore,
      awayScore: effectiveAwayScore,
      score: effectiveScore,
      startTime: newStartTime ?? oldEvent.startTime,
      currentPeriod:
          record['current_period']?.toString() ??
          record['currentPeriod']?.toString() ??
          oldEvent.currentPeriod,
      status: effectiveStatus,
    );

    final updatedList = List<EventModel>.from(events);
    updatedList[index] = updatedEvent;
    state = AsyncValue.data(updatedList);
    await CacheService.saveEvents(updatedList);
    debugPrint(
      'FeedNotifier: Realtime updated event ${update.eventId} in state',
    );
  }

  Future<void>? _currentLoadFuture;

  Future<void> loadEvents({bool forceRefresh = false}) {
    if (_isLoading && _currentLoadFuture != null) {
      return _currentLoadFuture!;
    }
    _isLoading = true;
    _currentLoadFuture = _performLoad(forceRefresh: forceRefresh);
    return _currentLoadFuture!;
  }

  Future<void> _performLoad({bool forceRefresh = false}) async {
    if (!state.hasValue) {
      state = const AsyncValue.loading();
    }
    try {
      final favoriteIds = await CacheService.getFavoriteIds();

      final rawEvents = await _repository.getEvents(forceRefresh: forceRefresh);

      final events =
          rawEvents.map((e) {
            if (favoriteIds.contains(e.id)) {
              return e.copyWith(isFavorite: true);
            }
            return e;
          }).toList();

      if (!mounted) return;
      _lastRefreshTime = DateTime.now();
      _ref.read(feedDataSourceProvider.notifier).state = _repository.source;
      _ref.read(feedLastUpdatedProvider.notifier).state =
          _repository.lastUpdated;
      if (_repository.source == FeedDataSource.cache) {
        _ref.read(connectionStatusProvider.notifier).setOffline();
      } else {
        _ref.read(connectionStatusProvider.notifier).setConnected();
      }
      state = AsyncValue.data(events);
    } catch (e, st) {
      if (mounted) {
        _ref.read(connectionStatusProvider.notifier).setOffline();
        state = AsyncValue.error(e, st);
      }
    } finally {
      _isLoading = false;
      _currentLoadFuture = null;
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

      return notifier;
    });

final favoriteEventsProvider = Provider<List<EventModel>>((ref) {
  final feedState = ref.watch(feedNotifierProvider);
  return feedState.maybeWhen(
    data: (events) => events.where((e) => e.isFavorite).toList(),
    orElse: () => [],
  );
});
