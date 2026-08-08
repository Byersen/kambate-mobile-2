import 'package:flutter/foundation.dart';
import '../../../models/event_model.dart';
import '../../../models/sport_type.dart';
import '../../../services/cache_service.dart';
import '../../../services/realtime_service.dart';
import '../../../services/supabase_service.dart';
import 'mock_events.dart';

class FeedRepository {
  FeedRepository() {
    // Initiate Realtime listener automatically
    RealtimeService().subscribeToEvents();
  }

  /// Get events with offline cache-first strategy and Supabase sync
  Future<List<EventModel>> getEvents({
    SportType? sport,
    int? leagueTier,
    bool forceRefresh = false,
  }) async {
    // 1. If not forcing refresh, try to load from local cache first
    if (!forceRefresh) {
      final cached = await CacheService.getCachedEvents();
      if (cached != null && cached.isNotEmpty) {
        debugPrint('FeedRepository: Loaded ${cached.length} events from local offline cache');
        var filtered = cached;
        if (sport != null && sport != SportType.all) {
          filtered = filtered.where((e) => e.sport == sport).toList();
        }
        if (leagueTier != null) {
          filtered = filtered
              .where((e) => e.leagueModel == null || e.leagueModel!.tier == leagueTier)
              .toList();
        }
        if (filtered.isNotEmpty) {
          // Trigger asynchronous background refresh without blocking
          _syncFromSupabaseBackground(sport: sport, leagueTier: leagueTier);
          return filtered;
        }
      }
    }

    // 2. Fetch fresh data from Supabase
    try {
      final client = SupabaseService.client;
      if (client != null) {
        var query = client.from('Event').select('''
          id,
          externalId,
          startDate,
          status,
          score,
          currentPeriod,
          venue,
          sport:Sport(id, name, slug),
          league:League(id, name, slug, country, tier, isActive),
          season:Season(id, name, slug, isCurrent),
          participants:Participant(id, name, slug, shortName, logoUrl, photoUrl, country, record),
          footballStats:FootballStats(*),
          nbaStats:NbaStats(*),
          ufcStats:UfcStats(*),
          esportsStats:EsportsStats(*)
        ''');

        if (sport != null && sport != SportType.all) {
          query = query.eq('sport.slug', sport.id);
        }

        final response = await query.order('startDate', ascending: true);
        final List<dynamic> data = response as List<dynamic>;

        if (data.isNotEmpty) {
          final events = data
              .map((item) => EventModel.fromJson(item as Map<String, dynamic>))
              .toList();

          // Persist full list to local offline cache
          await CacheService.saveEvents(events);
          debugPrint('FeedRepository: Successfully synced ${events.length} events from Supabase');

          if (leagueTier != null) {
            return events
                .where((e) => e.leagueModel?.tier == leagueTier)
                .toList();
          }
          return events;
        }
      }
    } catch (e) {
      debugPrint('FeedRepository Supabase query error ($e). Falling back to cached/mock data.');
    }

    // 3. Fallback to cached events or enriched local mock events
    final cachedFallback = await CacheService.getCachedEvents();
    List<EventModel> results = cachedFallback != null && cachedFallback.isNotEmpty
        ? cachedFallback
        : List<EventModel>.from(kMockEvents);

    // Save initial mock data to cache for first-time offline availability
    if (cachedFallback == null || cachedFallback.isEmpty) {
      await CacheService.saveEvents(kMockEvents);
    }

    if (sport != null && sport != SportType.all) {
      results = results.where((e) => e.sport == sport).toList();
    }

    if (leagueTier != null) {
      results = results
          .where((e) => e.leagueModel == null || e.leagueModel!.tier == leagueTier)
          .toList();
    }

    return results;
  }

  void _syncFromSupabaseBackground({SportType? sport, int? leagueTier}) async {
    try {
      final client = SupabaseService.client;
      if (client != null) {
        final response = await client.from('Event').select('''
          id,
          externalId,
          startDate,
          status,
          score,
          currentPeriod,
          venue,
          sport:Sport(id, name, slug),
          league:League(id, name, slug, country, tier, isActive),
          season:Season(id, name, slug, isCurrent),
          participants:Participant(id, name, slug, shortName, logoUrl, photoUrl, country, record),
          footballStats:FootballStats(*),
          nbaStats:NbaStats(*),
          ufcStats:UfcStats(*),
          esportsStats:EsportsStats(*)
        ''').order('startDate', ascending: true);

        final List<dynamic> data = response as List<dynamic>;
        if (data.isNotEmpty) {
          final events = data
              .map((item) => EventModel.fromJson(item as Map<String, dynamic>))
              .toList();
          await CacheService.saveEvents(events);
          debugPrint('FeedRepository: Background cache sync completed (${events.length} events)');
        }
      }
    } catch (_) {}
  }

  Future<EventModel?> getEventById(String id) async {
    try {
      final client = SupabaseService.client;
      if (client != null) {
        final response = await client.from('Event').select('''
          id,
          externalId,
          startDate,
          status,
          score,
          currentPeriod,
          venue,
          sport:Sport(id, name, slug),
          league:League(id, name, slug, country, tier, isActive),
          season:Season(id, name, slug, isCurrent),
          participants:Participant(id, name, slug, shortName, logoUrl, photoUrl, country, record),
          footballStats:FootballStats(*),
          nbaStats:NbaStats(*),
          ufcStats:UfcStats(*),
          esportsStats:EsportsStats(*)
        ''').eq('id', id).maybeSingle();

        if (response != null) {
          return EventModel.fromJson(response);
        }
      }
    } catch (e) {
      debugPrint('FeedRepository getEventById Supabase error: $e');
    }

    final cached = await CacheService.getCachedEvents();
    if (cached != null) {
      try {
        return cached.firstWhere((e) => e.id == id);
      } catch (_) {}
    }

    try {
      return kMockEvents.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
