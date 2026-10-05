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
  league:League(id, name, slug, country, isActive),
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
    if (!forceRefresh) {
      final cached = await CacheService.getCachedEvents();
      if (cached != null) {
        source = FeedDataSource.cache;
        lastUpdated = await CacheService.getLastSyncTime();
        return _filter(cached, sport, leagueTier);
      }
    }
    try {
      final events = await fetchRemoteEvents();
      await CacheService.saveEvents(events);
      source = FeedDataSource.remote;
      lastUpdated = await CacheService.getLastSyncTime();
      // Un resultado vacío también es válido y sustituye la caché anterior.
      return _filter(events, sport, leagueTier);
    } catch (error) {
      debugPrint('No se pudieron actualizar los partidos: $error');
      final cached = await CacheService.getCachedEvents();
      if (cached == null) rethrow;
      source = FeedDataSource.cache;
      lastUpdated = await CacheService.getLastSyncTime();
      return _filter(cached, sport, leagueTier);
    }
  }

  @visibleForTesting
  Future<List<EventModel>> fetchRemoteEvents() async {
    final client = SupabaseService.client;
    if (client == null) throw StateError('Conexión de datos no disponible');
    final events = <EventModel>[];
    const pageSize = 1000;
    for (var offset = 0; ; offset += pageSize) {
      final data = await client
          .from('Event')
          .select(_eventSelect)
          .order('startDate')
          .order('id')
          .range(offset, offset + pageSize - 1);
      events.addAll(data.map(EventModel.fromJson));
      if (data.length < pageSize) break;
    }
    return events;
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
        final response = await client
            .from('Event')
            .select(_eventSelect)
            .eq('id', id)
            .maybeSingle();
        if (response != null) return EventModel.fromJson(response);
      }
    } catch (error) {
      debugPrint('No se pudo actualizar el encuentro: $error');
    }
    final cached = await CacheService.getCachedEvents();
    for (final event in cached ?? <EventModel>[]) {
      if (event.id == id) return event;
    }
    return null;
  }
}
