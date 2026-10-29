import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_model.dart';
import '../models/sport_type.dart';

class CacheService {
  // v1 podía contener partidos de demostración guardados como datos reales.
  static const String _kEventsKey = 'kambate_cached_events_v2';
  static const String _kLastSyncKey = 'kambate_last_sync_timestamp';
  static const String _kCacheDateKey = 'kambate_cached_events_date';
  static const String _kFavoritesKey = 'kambate_favorites_set';
  static const String _kOnboardingKey = 'kambate_onboarding_completed_v1';
  static const String _kSelectedSportsKey = 'kambate_selected_sports_v1';
  static const String _kFollowedTeamsKey = 'kambate_followed_teams_set';
  static const String _kFollowedLeaguesKey = 'kambate_followed_leagues_set';

  static String _formatLocalDate(DateTime date) {
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static bool _isInActiveWindow(DateTime startTime, DateTime nowLocal) {
    final local = startTime.toLocal();
    final eventDay = DateTime(local.year, local.month, local.day);
    final yesterday = DateTime(nowLocal.year, nowLocal.month, nowLocal.day - 1);
    final tomorrow = DateTime(nowLocal.year, nowLocal.month, nowLocal.day + 1);
    return !eventDay.isBefore(yesterday) && !eventDay.isAfter(tomorrow);
  }

  /// Clear expired daily events cache keys (`_kEventsKey`, `_kLastSyncKey`, `_kCacheDateKey`)
  static Future<void> clearExpiredDailyCache([SharedPreferences? prefs]) async {
    try {
      final store = prefs ?? await SharedPreferences.getInstance();
      await store.remove(_kEventsKey);
      await store.remove(_kLastSyncKey);
      await store.remove(_kCacheDateKey);
    } catch (e) {
      debugPrint('CacheService.clearExpiredDailyCache error: $e');
    }
  }

  static Set<SportType> parseSelectedSportTypes(Iterable<String> slugs) {
    final parsed = <SportType>{};
    for (final slug in slugs) {
      final sport = SportType.fromString(slug);
      if (sport != SportType.all) {
        parsed.add(sport);
      }
    }
    return parsed;
  }

  /// Save events list to offline cache (only active window: [yesterday, today, tomorrow] and selected sports)
  static Future<void> saveEvents(List<EventModel> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayStr = _formatLocalDate(now);
      final selectedSlugs = prefs.getStringList(_kSelectedSportsKey) ?? [];
      final allowedSports = parseSelectedSportTypes(selectedSlugs);
      final activeEvents = events
          .where(
            (e) =>
                _isInActiveWindow(e.startTime, now) &&
                (allowedSports.isEmpty || allowedSports.contains(e.sport)),
          )
          .toList();
      final jsonList = activeEvents.map((e) => e.toJson()).toList();
      final encoded = jsonEncode(jsonList);
      await prefs.setString(_kEventsKey, encoded);
      await prefs.setString(_kLastSyncKey, now.toIso8601String());
      await prefs.setString(_kCacheDateKey, todayStr);
    } catch (e) {
      debugPrint('CacheService.saveEvents error: $e');
    }
  }

  /// Retrieve cached events list if available and valid for the current local day
  static Future<List<EventModel>?> getCachedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = _formatLocalDate(DateTime.now());
      final cachedDate = prefs.getString(_kCacheDateKey);
      if (cachedDate != todayStr) {
        await clearExpiredDailyCache(prefs);
        return null;
      }

      final selectedSlugs = prefs.getStringList(_kSelectedSportsKey) ?? [];
      final allowedSports = parseSelectedSportTypes(selectedSlugs);

      final raw = prefs.getString(_kEventsKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .map((item) => EventModel.fromJson(item as Map<String, dynamic>))
            .where(
              (event) =>
                  allowedSports.isEmpty || allowedSports.contains(event.sport),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('CacheService.getCachedEvents error: $e');
    }
    return null;
  }

  /// Get the timestamp of the last successful cache sync
  static Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kLastSyncKey);
      if (raw != null && raw.isNotEmpty) {
        return DateTime.tryParse(raw);
      }
    } catch (_) {}
    return null;
  }

  /// Save favorites IDs set locally
  static Future<void> saveFavoriteIds(Set<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kFavoritesKey, ids.toList());
    } catch (e) {
      debugPrint('CacheService.saveFavoriteIds error: $e');
    }
  }

  /// Retrieve favorites IDs set
  static Future<Set<String>> getFavoriteIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kFavoritesKey);
      if (list != null) {
        return list.toSet();
      }
    } catch (_) {}
    return {};
  }

  /// Check if the user has completed initial onboarding
  static Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kOnboardingKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Mark initial onboarding as completed
  static Future<void> setOnboardingCompleted(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kOnboardingKey, value);
    } catch (e) {
      debugPrint('CacheService.setOnboardingCompleted error: $e');
    }
  }

  /// Save user's preferred sports slugs (e.g. ['soccer', 'nba', 'lol'])
  /// and prune cached events of unselected sports to save local storage.
  static Future<void> saveSelectedSports(List<String> sports) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final previousSlugs = prefs.getStringList(_kSelectedSportsKey) ?? [];
      final previousSports = parseSelectedSportTypes(previousSlugs);
      final nextSports = parseSelectedSportTypes(sports);

      await prefs.setStringList(
        _kSelectedSportsKey,
        nextSports.map((s) => s.id).toList(),
      );

      final addedNewSport =
          previousSports.isNotEmpty &&
          nextSports.any((s) => !previousSports.contains(s));
      if (addedNewSport) {
        await prefs.remove(_kLastSyncKey);
      }

      final rawEvents = prefs.getString(_kEventsKey);
      if (rawEvents != null && rawEvents.isNotEmpty && nextSports.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(rawEvents) as List<dynamic>;
        final filteredJson = decoded
            .map((item) => EventModel.fromJson(item as Map<String, dynamic>))
            .where((event) => nextSports.contains(event.sport))
            .map((event) => event.toJson())
            .toList();
        await prefs.setString(_kEventsKey, jsonEncode(filteredJson));
      }
    } catch (e) {
      debugPrint('CacheService.saveSelectedSports error: $e');
    }
  }

  /// Get user's preferred sports slugs
  static Future<List<String>> getSelectedSports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_kSelectedSportsKey) ?? [];
    } catch (_) {
      return [];
    }
  }

  /// Get user's preferred sports as a typed `Set<SportType>`
  static Future<Set<SportType>> getSelectedSportTypes() async {
    final slugs = await getSelectedSports();
    return parseSelectedSportTypes(slugs);
  }

  /// Save followed teams/athletes IDs
  static Future<void> saveFollowedTeams(Set<String> teamIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kFollowedTeamsKey, teamIds.toList());
    } catch (e) {
      debugPrint('CacheService.saveFollowedTeams error: $e');
    }
  }

  /// Get followed teams/athletes IDs
  static Future<Set<String>> getFollowedTeams() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kFollowedTeamsKey);
      if (list != null) {
        return list.toSet();
      }
    } catch (_) {}
    return {};
  }

  /// Save followed leagues (lowercase names)
  static Future<void> saveFollowedLeagues(Set<String> leagues) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kFollowedLeaguesKey, leagues.toList());
    } catch (e) {
      debugPrint('CacheService.saveFollowedLeagues error: $e');
    }
  }

  /// Get followed leagues (lowercase names)
  static Future<Set<String>> getFollowedLeagues() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kFollowedLeaguesKey);
      if (list != null) return list.toSet();
    } catch (_) {}
    return {};
  }

  /// Clear all cached data
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kEventsKey);
      await prefs.remove(_kLastSyncKey);
      await prefs.remove(_kCacheDateKey);
      await prefs.remove(_kFavoritesKey);
      await prefs.remove(_kOnboardingKey);
      await prefs.remove(_kSelectedSportsKey);
      await prefs.remove(_kFollowedTeamsKey);
      await prefs.remove(_kFollowedLeaguesKey);
    } catch (_) {}
  }
}
