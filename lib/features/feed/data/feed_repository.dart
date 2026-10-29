import 'package:flutter/foundation.dart';
import '../../../models/event_model.dart';
import '../../../models/sport_type.dart';
import '../../../services/cache_service.dart';
import '../../../services/realtime_service.dart';
import '../../../services/supabase_service.dart';

enum FeedDataSource { remote, cache }

const _eventSelect = '''
  id, externalId, startDate, status, score,
  sport:Sport(id, name, slug),
  league:League(id, name, slug, country, logoUrl, isActive),
  season:Season(id, name, slug, isCurrent),
  participants:Participant(id, name, externalId, logoUrl),
  footballStats:FootballStats(*), nbaStats:NbaStats(*),
  ufcStats:UfcStats(*), esportsStats:EsportsStats(*)
''';

class FeedRepository {
  FeedRepository({bool subscribeToRealtime = true}) {
    if (subscribeToRealtime) RealtimeService().subscribeToEvents();
  }

  FeedDataSource source = FeedDataSource.remote;
  DateTime? lastUpdated;

  /// Solo se almacena información obtenida de Supabase, nunca datos de ejemplo.
  Future<List<EventModel>> getEvents({
    SportType? sport,
    int? leagueTier,
    bool forceRefresh = false,
  }) async {
    final cached = await CacheService.getCachedEvents();
    final lastSync = await CacheService.getLastSyncTime();
    final isCacheFresh = lastSync != null &&
        DateTime.now().difference(lastSync) < const Duration(minutes: 5);

    // Solo usar cache si fue actualizada hace menos de 5 minutos
    if (!forceRefresh && cached != null && isCacheFresh) {
      source = FeedDataSource.remote;
      lastUpdated = lastSync;
      return _filter(cached, sport, leagueTier);
    }

    try {
      final events = await fetchRemoteEvents();
      await CacheService.saveEvents(events);
      source = FeedDataSource.remote;
      lastUpdated = DateTime.now();
      return _filter(events, sport, leagueTier);
    } catch (error) {
      debugPrint('No se pudieron actualizar los partidos remotamente: $error');
      final fallbackCached = cached ?? await CacheService.getCachedEvents();
      if (fallbackCached == null) rethrow;
      source = FeedDataSource.cache;
      lastUpdated = lastSync ?? await CacheService.getLastSyncTime();
      return _filter(fallbackCached, sport, leagueTier);
    }
  }

  /// Consulta por defecto únicamente la ventana [ayer 00:00, mañana 23:59:59] en UTC.
  @visibleForTesting
  Future<List<EventModel>> fetchRemoteEvents() async {
    return _fetchRemoteEventsInWindow();
  }

  Future<List<EventModel>> _fetchRemoteEventsInWindow({
    DateTime? start,
    DateTime? end,
  }) async {
    final client = SupabaseService.client;
    if (client == null) throw StateError('Conexión de datos no disponible');

    final nowLocal = DateTime.now();
    final rangeStart = (start ??
            DateTime(nowLocal.year, nowLocal.month, nowLocal.day - 1, 0, 0, 0))
        .toUtc();
    final rangeEnd = (end ??
            DateTime(
              nowLocal.year,
              nowLocal.month,
              nowLocal.day + 1,
              23,
              59,
              59,
              999,
            ))
        .toUtc();

    final events = <EventModel>[];
    const pageSize = 1000;
    for (var offset = 0; ; offset += pageSize) {
      final data = await client
          .from('Event')
          .select(_eventSelect)
          .gte('startDate', rangeStart.toIso8601String())
          .lte('startDate', rangeEnd.toIso8601String())
          .order('startDate')
          .order('id')
          .range(offset, offset + pageSize - 1);
      events.addAll(data.map(EventModel.fromJson));
      if (data.length < pageSize) break;
    }
    return events;
  }

  /// Pulso ligero de alta prioridad:
  /// a) Eventos con status = 'LIVE'
  /// b) Eventos cuyos IDs estén en [trackedLiveIds] (transición LIVE -> FINISHED)
  /// c) Eventos de hoy con status = 'SCHEDULED' y startDate <= DateTime.now().toUtc() (transición SCHEDULED -> LIVE)
  Future<List<EventModel>> fetchLiveAndDueEvents(
    List<String> trackedLiveIds,
  ) async {
    final client = SupabaseService.client;
    if (client == null) {
      return getEvents(forceRefresh: true);
    }

    final nowLocal = DateTime.now();
    final nowUtcIso = nowLocal.toUtc().toIso8601String();
    final todayStartIso = DateTime(
      nowLocal.year,
      nowLocal.month,
      nowLocal.day,
      0,
      0,
      0,
    ).toUtc().toIso8601String();

    final cleanTrackedIds = trackedLiveIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final orFilters = <String>[
      'status.eq.LIVE',
      'and(status.eq.SCHEDULED,startDate.gte.$todayStartIso,startDate.lte.$nowUtcIso)',
      if (cleanTrackedIds.isNotEmpty)
        'id.in.(${cleanTrackedIds.map((id) => '"$id"').join(',')})',
    ];

    final data = await client
        .from('Event')
        .select(_eventSelect)
        .or(orFilters.join(','))
        .order('startDate')
        .order('id');

    final seenIds = <String>{};
    final result = <EventModel>[];
    for (final row in data) {
      final event = EventModel.fromJson(row);
      if (seenIds.add(event.id)) {
        result.add(event);
      }
    }
    return result;
  }

  /// Carga bajo demanda para un rango de fechas (carrusel o calendario).
  Future<List<EventModel>> fetchEventsForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final normalizedStart = start.isUtc
        ? start
        : DateTime(
            start.year,
            start.month,
            start.day,
            start.hour,
            start.minute,
            start.second,
            start.millisecond,
          ).toUtc();

    final isEndMidnight =
        end.hour == 0 &&
        end.minute == 0 &&
        end.second == 0 &&
        end.millisecond == 0;
    final normalizedEnd = isEndMidnight
        ? (end.isUtc
            ? DateTime.utc(end.year, end.month, end.day, 23, 59, 59, 999)
            : DateTime(end.year, end.month, end.day, 23, 59, 59, 999).toUtc())
        : end.toUtc();

    if (SupabaseService.client == null) {
      final all = await fetchRemoteEvents();
      return all.where((event) {
        final t = event.startTime.toUtc();
        return !t.isBefore(normalizedStart) && !t.isAfter(normalizedEnd);
      }).toList();
    }

    return _fetchRemoteEventsInWindow(
      start: normalizedStart,
      end: normalizedEnd,
    );
  }

  List<EventModel> _filter(
    List<EventModel> events,
    SportType? sport,
    int? tier,
  ) {
    return events
        .where(
          (event) =>
              (sport == null ||
                  sport == SportType.all ||
                  event.sport == sport) &&
              (tier == null ||
                  event.leagueModel == null ||
                  event.leagueModel!.tier == tier),
        )
        .toList();
  }

  Future<EventModel?> getEventById(String id) async {
    try {
      final client = SupabaseService.client;
      if (client != null) {
        var response = await client
            .from('Event')
            .select(_eventSelect)
            .eq('id', id)
            .maybeSingle();
        response ??= await client
            .from('Event')
            .select(_eventSelect)
            .eq('externalId', id)
            .maybeSingle();
        if (response != null) return EventModel.fromJson(response);
      }
    } catch (error) {
      debugPrint('No se pudo actualizar el encuentro: $error');
    }
    final cached = await CacheService.getCachedEvents();
    for (final event in cached ?? <EventModel>[]) {
      if (event.id == id || event.externalId == id) return event;
    }
    return null;
  }
}
