import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/event_model.dart';
import '../../../models/event_status.dart';
import '../../../models/sport_type.dart';
import '../../../models/stats_models.dart';
import '../../../services/cache_service.dart';
import '../../../services/realtime_service.dart';
import '../data/feed_repository.dart';
import 'connection_provider.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository();
});

const List<SportType> kDefaultSelectedSports = [
  SportType.soccer,
  SportType.nba,
  SportType.ufc,
  SportType.lol,
  SportType.valorant,
];

class SelectedSportsNotifier extends StateNotifier<Set<SportType>> {
  final Ref _ref;

  SelectedSportsNotifier(this._ref, [Set<SportType>? initialSports])
      : super(
          initialSports != null
              ? normalizeSports(initialSports)
              : kDefaultSelectedSports.toSet(),
        ) {
    if (initialSports == null) {
      _loadFromCache();
    }
  }

  static Set<SportType> normalizeSports(Iterable<SportType> sports) {
    final ordered = <SportType>{};
    for (final canonical in kDefaultSelectedSports) {
      if (sports.contains(canonical)) {
        ordered.add(canonical);
      }
    }
    return ordered.isEmpty ? {SportType.soccer} : ordered;
  }

  Future<void> _loadFromCache() async {
    final saved = await CacheService.getSelectedSportTypes();
    if (!mounted || saved.isEmpty) return;
    final normalized = normalizeSports(saved);
    state = normalized;
    final currentFilter = _ref.read(selectedSportFilterProvider);
    if (!normalized.contains(currentFilter)) {
      _ref.read(selectedSportFilterProvider.notifier).state = normalized.first;
    }
  }

  Future<void> setSelectedSports(Iterable<SportType> sports) async {
    final normalized = normalizeSports(sports);
    final addedNewSport = normalized.any((s) => !state.contains(s));
    state = normalized;

    await CacheService.saveSelectedSports(
      normalized.map((s) => s.id).toList(),
    );

    final currentFilter = _ref.read(selectedSportFilterProvider);
    if (!normalized.contains(currentFilter)) {
      _ref.read(selectedSportFilterProvider.notifier).state = normalized.first;
    }

    await _ref
        .read(feedNotifierProvider.notifier)
        .applySelectedSports(normalized, reloadRemote: addedNewSport);
  }
}

/// User's selected sports in onboarding/settings (defaults to all 5 sports)
final selectedSportsProvider =
    StateNotifierProvider<SelectedSportsNotifier, Set<SportType>>((ref) {
      return SelectedSportsNotifier(ref);
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
/// Notifica si los partidos de una fecha seleccionada se están cargando bajo demanda
final isDateLoadingProvider = StateProvider<bool>((ref) => false);

final selectedFeedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

class FeedNotifier extends StateNotifier<AsyncValue<List<EventModel>>> {
  final FeedRepository _repository;
  final Ref _ref;
  StreamSubscription<RealtimeEventUpdate>? _realtimeSubscription;
  Timer? _liveRefreshTimer;
  bool _liveRefreshEnabled = false;
  DateTime? _lastRefreshTime;
  bool _isLoading = false;
  bool _isPulsing = false;

  FeedNotifier(this._repository, this._ref)
    : super(const AsyncValue.loading()) {
    loadEvents(forceRefresh: true);
    _listenToRealtimeUpdates();
  }

  DateTime? get lastRefreshTime => _lastRefreshTime;
  bool get isLoading => _isLoading;

  void startLiveRefresh() {
    _liveRefreshEnabled = true;
    _startLiveRefresh();
  }

  void stopLiveRefresh() {
    _liveRefreshEnabled = false;
    _liveRefreshTimer?.cancel();
  }

  bool _shouldRunLivePulse(List<EventModel> events) {
    final nowLocal = DateTime.now();
    final pulseHorizonUtc = nowLocal.toUtc().add(const Duration(minutes: 5));

    for (final event in events) {
      if (event.isLive) return true;
      if (event.status == EventStatus.scheduled) {
        final localStart = event.startTime.toLocal();
        final isToday =
            localStart.year == nowLocal.year &&
            localStart.month == nowLocal.month &&
            localStart.day == nowLocal.day;
        if (isToday && !event.startTime.toUtc().isAfter(pulseHorizonUtc)) {
          return true;
        }
      }
    }
    return false;
  }

  void _startLiveRefresh() {
    _liveRefreshTimer?.cancel();
    _liveRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final events = state.asData?.value;
      if (mounted &&
          !_isLoading &&
          !_isPulsing &&
          events != null &&
          _shouldRunLivePulse(events)) {
        unawaited(refreshLivePulse());
      }
    });
  }

  /// Pulso ligero de sincronización reactiva sin spinner de carga completa ni bloqueo de UI.
  Future<void> refreshLivePulse() async {
    if (_isLoading || _isPulsing) return;
    final currentEvents = state.asData?.value;
    if (currentEvents == null || !_shouldRunLivePulse(currentEvents)) return;

    _isPulsing = true;
    try {
      final cachedSports = await CacheService.getSelectedSportTypes();
      final selectedSports = cachedSports.isNotEmpty
          ? SelectedSportsNotifier.normalizeSports(cachedSports)
          : _ref.read(selectedSportsProvider);
      final trackedLiveIds = currentEvents
          .where((e) => e.isLive && selectedSports.contains(e.sport))
          .map((e) => e.id)
          .toList();

      final updatedBatch = await _repository.fetchLiveAndDueEvents(
        trackedLiveIds,
      );
      if (!mounted || updatedBatch.isEmpty) return;

      final favoriteIds = await CacheService.getFavoriteIds();
      if (!mounted) return;

      final latestEvents = List<EventModel>.from(
        state.asData?.value ?? currentEvents,
      );
      final indexById = <String, int>{
        for (var i = 0; i < latestEvents.length; i++) latestEvents[i].id: i,
      };

      for (final incoming in updatedBatch) {
        if (selectedSports.isNotEmpty &&
            !selectedSports.contains(incoming.sport)) {
          continue;
        }
        final existingIndex =
            indexById[incoming.id] ??
            latestEvents.indexWhere(
              (e) =>
                  e.externalId != null && e.externalId == incoming.externalId,
            );
        if (existingIndex != -1) {
          final prev = latestEvents[existingIndex];
          latestEvents[existingIndex] = incoming.copyWith(
            isFavorite: prev.isFavorite || favoriteIds.contains(incoming.id),
          );
        } else {
          latestEvents.add(
            incoming.copyWith(isFavorite: favoriteIds.contains(incoming.id)),
          );
          indexById[incoming.id] = latestEvents.length - 1;
        }
      }

      final now = DateTime.now();
      _lastRefreshTime = now;
      _ref.read(feedLastUpdatedProvider.notifier).state = now;
      _ref.read(connectionStatusProvider.notifier).setConnected();
      state = AsyncValue.data(latestEvents);
      await CacheService.saveEvents(latestEvents);
    } catch (e) {
      debugPrint('FeedNotifier.refreshLivePulse error: $e');
    } finally {
      _isPulsing = false;
    }
  }

  /// Aplica el subconjunto de deportes seleccionados descartando eventos no seleccionados
  /// de la memoria y recargando si se habilitó una disciplina adicional.
  Future<void> applySelectedSports(
    Set<SportType> allowedSports, {
    bool reloadRemote = false,
  }) async {
    final currentEvents = state.asData?.value;
    if (currentEvents != null && allowedSports.isNotEmpty) {
      final pruned = currentEvents
          .where((e) => allowedSports.contains(e.sport))
          .toList();
      if (pruned.length != currentEvents.length) {
        state = AsyncValue.data(pruned);
      }
      await CacheService.saveEvents(pruned);
    }
    if (reloadRemote) {
      await loadEvents(forceRefresh: true);
    }
  }

  /// Listen to Supabase Realtime PostgreSQL updates
  void _listenToRealtimeUpdates() {
    _realtimeSubscription = RealtimeService().onEventUpdate.listen(
      applyRealtimeUpdate,
    );
  }

  /// Maneja el regreso a la app desde segundo plano.
  /// Evita solicitudes duplicadas o en ráfaga con un enfriamiento de 15 segundos.
  Future<void> onAppResumed() async {
    if (_liveRefreshEnabled) _startLiveRefresh();
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
    _liveRefreshTimer?.cancel();
    RealtimeService().pause();
  }

  @visibleForTesting
  Future<void> applyRealtimeUpdate(RealtimeEventUpdate update) async {
    final cachedSports = await CacheService.getSelectedSportTypes();
    final selectedSports = cachedSports.isNotEmpty
        ? SelectedSportsNotifier.normalizeSports(cachedSports)
        : _ref.read(selectedSportsProvider);
    final currentEvents = state.asData?.value;
    final currentIndex = currentEvents?.indexWhere(
      (event) => event.id == update.eventId || event.externalId == update.eventId,
    ) ?? -1;
    if (currentEvents != null && currentIndex >= 0 &&
        (update.statsKind == RealtimeStatsKind.football ||
         update.statsKind == RealtimeStatsKind.nba)) {
      final previous = currentEvents[currentIndex];
      final record = update.record;
      final extra = record['extraStats'] ?? record['extra_stats'];
      final payloadExtra = extra is Map ? Map<String, dynamic>.from(extra) : <String, dynamic>{};
      final incomingExtra = <String, dynamic>{
        for (final key in [
          'clock',
          'period',
          'statusDetail',
          'leagueLogo',
          'venue',
          'round',
          'homeTeamId',
          'awayTeamId',
        ])
          if (payloadExtra.containsKey(key)) key: payloadExtra[key],
      };
      EventModel updated;
      if (update.statsKind == RealtimeStatsKind.football && previous.sport == SportType.soccer) {
        final incoming = FootballStatsModel.fromJson(record);
        final old = previous.footballStats;
        final stats = FootballStatsModel(
          id: incoming.id.isEmpty ? (old?.id ?? '') : incoming.id,
          eventId: incoming.eventId ?? old?.eventId,
          homeGoals: incoming.homeGoals ?? old?.homeGoals,
          awayGoals: incoming.awayGoals ?? old?.awayGoals,
          homeCards: incoming.homeCards ?? old?.homeCards,
          awayCards: incoming.awayCards ?? old?.awayCards,
          extraStats: {...?old?.extraStats, ...incomingExtra},
        );
        updated = previous.copyWith(
          footballStats: stats,
          homeScore: stats.homeGoals,
          awayScore: stats.awayGoals,
          score: stats.homeGoals != null && stats.awayGoals != null
              ? '${stats.homeGoals} - ${stats.awayGoals}' : previous.score,
        );
      } else if (update.statsKind == RealtimeStatsKind.nba && previous.sport == SportType.nba) {
        final incoming = NbaStatsModel.fromJson(record);
        final old = previous.nbaStats;
        final stats = NbaStatsModel(
          id: incoming.id.isEmpty ? (old?.id ?? '') : incoming.id,
          eventId: incoming.eventId ?? old?.eventId,
          homePoints: incoming.homePoints ?? old?.homePoints,
          awayPoints: incoming.awayPoints ?? old?.awayPoints,
          quarter: incoming.quarter ?? old?.quarter,
          extraStats: {...?old?.extraStats, ...incomingExtra},
        );
        updated = previous.copyWith(
          nbaStats: stats,
          homeScore: stats.homePoints,
          awayScore: stats.awayPoints,
          score: stats.homePoints != null && stats.awayPoints != null
              ? '${stats.homePoints} - ${stats.awayPoints}' : previous.score,
        );
      } else {
        return;
      }
      final updatedList = List<EventModel>.from(currentEvents)..[currentIndex] = updated;
      state = AsyncValue.data(updatedList);
      await CacheService.saveEvents(updatedList);
      return;
    }
    if (update.requiresRefresh) {
      final refreshed = await _repository.getEventById(update.eventId);
      if (!mounted || refreshed == null) return;
      if (selectedSports.isNotEmpty &&
          !selectedSports.contains(refreshed.sport)) {
        return;
      }
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
      if (newEvent != null &&
          mounted &&
          (selectedSports.isEmpty || selectedSports.contains(newEvent.sport))) {
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
      final cachedSports = await CacheService.getSelectedSportTypes();
      final selectedSports = cachedSports.isNotEmpty
          ? SelectedSportsNotifier.normalizeSports(cachedSports)
          : _ref.read(selectedSportsProvider);

      final rawEvents = await _repository.getEvents(forceRefresh: forceRefresh);
      final filteredEvents = selectedSports.isEmpty
          ? rawEvents
          : rawEvents.where((e) => selectedSports.contains(e.sport)).toList();

      final events =
          filteredEvents.map((e) {
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
      _preloadUpcomingDays();
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


  void _preloadUpcomingDays() {
    unawaited(Future.microtask(() async {
      try {
        final nowLocal = DateTime.now();
        final yesterdayStart = DateTime(
          nowLocal.year,
          nowLocal.month,
          nowLocal.day - 1,
          0,
          0,
          0,
        );
        final yesterdayEnd = DateTime(
          nowLocal.year,
          nowLocal.month,
          nowLocal.day - 1,
          23,
          59,
          59,
          999,
        );
        final upcomingStart = DateTime(
          nowLocal.year,
          nowLocal.month,
          nowLocal.day + 1,
          0,
          0,
          0,
        );
        final upcomingEnd = DateTime(
          nowLocal.year,
          nowLocal.month,
          nowLocal.day + 6,
          23,
          59,
          59,
          999,
        );

        final results = await Future.wait([
          _repository.fetchEventsForDateRange(yesterdayStart, yesterdayEnd),
          _repository.fetchEventsForDateRange(upcomingStart, upcomingEnd),
        ]);
        final backgroundEvents = <EventModel>[...results[0], ...results[1]];
        if (!mounted || backgroundEvents.isEmpty) return;

        final favoriteIds = await CacheService.getFavoriteIds();
        final current = state.asData?.value ?? [];
        final merged = _mergeEvents(current, backgroundEvents, favoriteIds);
        state = AsyncValue.data(merged);
        await CacheService.saveEvents(merged);
      } catch (e) {
        debugPrint('FeedNotifier: Preload upcoming days silent error: $e');
      }
    }));
  }

  final Set<String> _loadingDates = {};

  /// Carga bajo demanda los partidos y resultados de un día seleccionado
  Future<void> loadEventsForDate(DateTime date, {bool forceRefresh = false}) async {
    final dateKey = '${date.year}-${date.month}-${date.day}';
    if (_loadingDates.contains(dateKey)) return;
    _loadingDates.add(dateKey);

    final currentEvents = state.asData?.value ?? <EventModel>[];
    final hasEventsForDate = currentEvents.any(
      (e) => AppDateFormatter.isSameDay(e.startTime, date),
    );

    if (!hasEventsForDate) {
      _ref.read(isDateLoadingProvider.notifier).state = true;
    }

    try {
      final startLocal = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endLocal = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
      final incoming = await _repository.fetchEventsForDateRange(startLocal, endLocal);

      final favoriteIds = await CacheService.getFavoriteIds();
      final latestEvents = List<EventModel>.from(state.asData?.value ?? currentEvents);
      final merged = _mergeEvents(latestEvents, incoming, favoriteIds);

      state = AsyncValue.data(merged);
      await CacheService.saveEvents(merged);
      _ref.read(connectionStatusProvider.notifier).setConnected();
    } catch (e) {
      debugPrint('FeedNotifier.loadEventsForDate error for $dateKey: $e');
    } finally {
      _loadingDates.remove(dateKey);
      if (mounted) {
        _ref.read(isDateLoadingProvider.notifier).state = false;
      }
    }
  }

  static List<EventModel> _mergeEvents(
    List<EventModel> current,
    List<EventModel> incoming,
    Set<String> favoriteIds,
  ) {
    final result = List<EventModel>.from(current);
    final indexById = <String, int>{
      for (var i = 0; i < result.length; i++) result[i].id: i,
    };

    for (final inc in incoming) {
      final idx = indexById[inc.id] ??
          result.indexWhere((e) => e.externalId != null && e.externalId == inc.externalId);
      final isFav = favoriteIds.contains(inc.id) || (idx != -1 && result[idx].isFavorite);
      final item = inc.copyWith(isFavorite: isFav);

      if (idx != -1) {
        result[idx] = item;
      } else {
        result.add(item);
        indexById[item.id] = result.length - 1;
      }
    }
    return result;
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
    _liveRefreshTimer?.cancel();
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
