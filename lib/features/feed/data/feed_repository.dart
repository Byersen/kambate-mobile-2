import 'package:flutter/foundation.dart';
import '../../../models/event_model.dart';
import '../../../models/sport_type.dart';
import '../../../services/cache_service.dart';
import '../../../services/realtime_service.dart';
import '../../../services/supabase_service.dart';
import 'mock_events.dart';

/// The select fragment shared by all queries.
const _kEventSelect = '''
  id,
  externalId,
  startDate,
  status,
  score,
  sport:Sport(id, name, slug),
  league:League(id, name, slug, country, tier, isActive),
  season:Season(id, name, slug, isCurrent),
  participants:Participant(id, name, externalId, logoUrl),
  footballStats:FootballStats(*),
  nbaStats:NbaStats(*),
  ufcStats:UfcStats(*),
  esportsStats:EsportsStats(*)
''';

class FeedRepository {
  FeedRepository() {
    RealtimeService().subscribeToEvents();
  }

  /// Get ALL events from the current season.
  /// The database only stores current-season data, so no date filtering is needed.
  /// Sport / tier filters are applied in-memory to avoid PostgREST inner-join issues.
  Future<List<EventModel>> getEvents({
    SportType? sport,
    int? leagueTier,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await CacheService.getCachedEvents();
      if (cached != null && cached.isNotEmpty) {
        debugPrint('FeedRepository: Loaded ${cached.length} events from local cache');
        final filtered = _applyFilters(cached, sport, leagueTier);
        if (filtered.isNotEmpty) {
          _syncFromSupabaseBackground();
          return filtered;
        }
      }
    }

    try {
      final client = SupabaseService.client;
      if (client != null) {
        final List<EventModel> allEvents = [];
        int offset = 0;
        const int pageSize = 1000;
        
        while (true) {
          final response = await client
              .from('Event')
              .select(_kEventSelect)
              .order('startDate', ascending: true)
              .range(offset, offset + pageSize - 1);

          final List<dynamic> data = response as List<dynamic>;
          if (data.isEmpty) break;
          
          allEvents.addAll(data.map((item) => EventModel.fromJson(item as Map<String, dynamic>)));
          
          if (data.length < pageSize) break;
          offset += pageSize;
        }

        if (allEvents.isNotEmpty) {
          await CacheService.saveEvents(allEvents);
          debugPrint('FeedRepository: Synced ${allEvents.length} events from Supabase via pagination');

          return _applyFilters(allEvents, sport, leagueTier);
        }
      }
    } catch (e) {
      debugPrint('FeedRepository Supabase query error: $e — using cache/mock fallback');
    }

    final cachedFallback = await CacheService.getCachedEvents();
    final List<EventModel> fallback = cachedFallback != null && cachedFallback.isNotEmpty
        ? cachedFallback
        : List<EventModel>.from(kMockEvents);

    if (cachedFallback == null || cachedFallback.isEmpty) {
      await CacheService.saveEvents(kMockEvents);
    }

    return _applyFilters(fallback, sport, leagueTier);
  }

  /// Apply sport and league-tier filters in-memory.
  List<EventModel> _applyFilters(
      List<EventModel> events, SportType? sport, int? leagueTier) {
    var result = events;
    if (sport != null && sport != SportType.all) {
      result = result.where((e) => e.sport == sport).toList();
    }
    if (leagueTier != null) {
      result = result
          .where((e) => e.leagueModel == null || e.leagueModel!.tier == leagueTier)
          .toList();
    }
    return result;
  }

  /// Background sync — updates the local cache without blocking the UI.
  void _syncFromSupabaseBackground() async {
    try {
      final client = SupabaseService.client;
      if (client != null) {
        final List<EventModel> allEvents = [];
        int offset = 0;
        const int pageSize = 1000;
        
        while (true) {
          final response = await client
              .from('Event')
              .select(_kEventSelect)
              .order('startDate', ascending: true)
              .range(offset, offset + pageSize - 1);

          final List<dynamic> data = response as List<dynamic>;
          if (data.isEmpty) break;
          
          allEvents.addAll(data.map((item) => EventModel.fromJson(item as Map<String, dynamic>)));
          
          if (data.length < pageSize) break;
          offset += pageSize;
        }

        if (allEvents.isNotEmpty) {
          await CacheService.saveEvents(allEvents);
          debugPrint('FeedRepository: Background sync completed — ${allEvents.length} events cached');
        }
      }
    } catch (_) {}
  }

  Future<EventModel?> getEventById(String id) async {
    try {
      final client = SupabaseService.client;
      if (client != null) {
        final response = await client
            .from('Event')
            .select(_kEventSelect)
            .eq('id', id)
            .maybeSingle();

        if (response != null) {
          return EventModel.fromJson(response);
        }
      }
    } catch (e) {
      debugPrint('FeedRepository getEventById error: $e');
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


