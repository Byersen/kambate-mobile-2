import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_model.dart';

class CacheService {
  // v1 podía contener partidos de demostración guardados como datos reales.
  static const String _kEventsKey = 'kambate_cached_events_v2';
  static const String _kLastSyncKey = 'kambate_last_sync_timestamp';
  static const String _kFavoritesKey = 'kambate_favorites_set';
  static const String _kOnboardingKey = 'kambate_onboarding_completed_v1';
  static const String _kSelectedSportsKey = 'kambate_selected_sports_v1';
  static const String _kFollowedTeamsKey = 'kambate_followed_teams_set';
  static const String _kFollowedLeaguesKey = 'kambate_followed_leagues_set';

  /// Save events list to offline cache
  static Future<void> saveEvents(List<EventModel> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = events.map((e) => e.toJson()).toList();
      final encoded = jsonEncode(jsonList);
      await prefs.setString(_kEventsKey, encoded);
      await prefs.setString(_kLastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('CacheService.saveEvents error: $e');
    }
  }

  /// Retrieve cached events list if available
  static Future<List<EventModel>?> getCachedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kEventsKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .map((item) => EventModel.fromJson(item as Map<String, dynamic>))
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
  static Future<void> saveSelectedSports(List<String> sports) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kSelectedSportsKey, sports);
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
      await prefs.remove(_kFavoritesKey);
      await prefs.remove(_kOnboardingKey);
      await prefs.remove(_kSelectedSportsKey);
      await prefs.remove(_kFollowedTeamsKey);
      await prefs.remove(_kFollowedLeaguesKey);
    } catch (_) {}
  }
}
