import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/event_model.dart';
import '../../../models/sport_type.dart';
import '../../feed/providers/feed_provider.dart';
import '../models/searchable_team_item.dart';
import '../../../services/cache_service.dart';

/// Search query provider for favorites screen
final favoritesSearchQueryProvider = StateProvider<String>((ref) => '');

/// Tag / Sport filter for favorites screen
final favoritesSportFilterProvider = StateProvider<SportType>((ref) => SportType.all);

/// Region filter for explore / search screen (Todos, Europa, Sudamérica, Norteamérica, Internacional)
final favoritesRegionFilterProvider = StateProvider<String>((ref) => 'Todos');

/// State notifier for followed teams / fighters / clubs IDs
class FavoriteTeamsNotifier extends StateNotifier<Set<String>> {
  FavoriteTeamsNotifier() : super({}) {
    _loadFromCache();
  }

  Future<void> _loadFromCache() async {
    final cached = await CacheService.getFollowedTeams();
    if (cached.isNotEmpty) {
      state = cached;
    }
  }

  void toggleFavorite(String teamId) {
    if (state.contains(teamId)) {
      state = {...state}..remove(teamId);
    } else {
      state = {...state, teamId};
    }
    CacheService.saveFollowedTeams(state);
  }

  bool isFavorite(String teamId) => state.contains(teamId);
}

final favoriteTeamIdsProvider =
    StateNotifierProvider<FavoriteTeamsNotifier, Set<String>>((ref) {
  return FavoriteTeamsNotifier();
});

/// Master catalog built 100% from live events loaded from Supabase.
/// Uses real Participant UUIDs so following a team correctly highlights their matches in the feed.
final allAvailableTeamsProvider = Provider<List<SearchableTeamItem>>((ref) {
  final feedState = ref.watch(feedNotifierProvider);
  final selectedSports = ref.watch(selectedSportsProvider);
  final List<EventModel> events = feedState.maybeWhen(
    data: (data) => data
        .where((e) => selectedSports.isEmpty || selectedSports.contains(e.sport))
        .toList(),
    orElse: () => [],
  );

  final Map<String, SearchableTeamItem> itemsMap = {};

  int getLeaguePriority(String league) {
    final l = league.toLowerCase();
    if (['arg', 'argentin', 'liga prof', 'copa de la liga', 'copa argentina',
         'bra', 'brasileir', 'copa do brasil', 'paulista', 'carioca',
         'chi', 'chile', 'campeonato itaú', 'copa chile',
         'col', 'colombia', 'liga betplay',
         'mex', 'mx', 'usa', 'mls', 'major league',
         'esp', 'eng', 'ita', 'ger', 'fra', 'ned', 'por', 'tur', 
         'premier', 'laliga', 'bundesliga', 'serie a', 'ligue 1', 'eredivisie', 'primeira', 'süper lig', 'super lig'].any((x) => l.contains(x))) {
      return 1;
    }
    if (['libertadores', 'sudamericana', 'recopa', 'conmebol', 
         'champions', 'europa league', 'conference', 'uefa'].any((x) => l.contains(x))) {
      return 2;
    }
    return 3;
  }

  void updateTeamLeagueIfNeeded(String teamId, SearchableTeamItem newTeam) {
    if (!itemsMap.containsKey(teamId)) {
      itemsMap[teamId] = newTeam;
    } else {
      final existingTeam = itemsMap[teamId]!;
      final existingPriority = getLeaguePriority(existingTeam.league);
      final newPriority = getLeaguePriority(newTeam.league);
      
      if (newPriority < existingPriority) {
        itemsMap[teamId] = existingTeam.copyWith(league: newTeam.league);
      }
    }
  }

  for (final event in events) {
    final leagueName = event.league;
    final sport = event.sport;
    final isCombat = event.isCombat;

    if (isCombat) {
      if (event.fighter1 != null && event.fighter1!.id.isNotEmpty) {
        updateTeamLeagueIfNeeded(
          event.fighter1!.id,
          SearchableTeamItem(
            id: event.fighter1!.id,
            name: event.fighter1!.name,
            shortName: event.fighter1!.nickname,
            photoUrl: event.fighter1!.photoUrl,
            sport: sport,
            league: leagueName,
            country: event.leagueModel?.country,
            record: event.fighter1!.record,
            isCombat: true,
          ),
        );
      }
      if (event.fighter2 != null && event.fighter2!.id.isNotEmpty) {
        updateTeamLeagueIfNeeded(
          event.fighter2!.id,
          SearchableTeamItem(
            id: event.fighter2!.id,
            name: event.fighter2!.name,
            shortName: event.fighter2!.nickname,
            photoUrl: event.fighter2!.photoUrl,
            sport: sport,
            league: leagueName,
            country: event.leagueModel?.country,
            record: event.fighter2!.record,
            isCombat: true,
          ),
        );
      }
    } else {
      if (event.homeTeam != null && event.homeTeam!.id.isNotEmpty) {
        updateTeamLeagueIfNeeded(
          event.homeTeam!.id,
          SearchableTeamItem(
            id: event.homeTeam!.id,
            name: event.homeTeam!.name,
            shortName: event.homeTeam!.shortName,
            logoUrl: event.homeTeam!.logoUrl,
            sport: sport,
            league: leagueName,
            country: event.leagueModel?.country,
          ),
        );
      }
      if (event.awayTeam != null && event.awayTeam!.id.isNotEmpty) {
        updateTeamLeagueIfNeeded(
          event.awayTeam!.id,
          SearchableTeamItem(
            id: event.awayTeam!.id,
            name: event.awayTeam!.name,
            shortName: event.awayTeam!.shortName,
            logoUrl: event.awayTeam!.logoUrl,
            sport: sport,
            league: leagueName,
            country: event.leagueModel?.country,
          ),
        );
      }
    }

    for (final p in event.participants) {
      if (p.id.isEmpty) continue;
      updateTeamLeagueIfNeeded(
        p.id,
        SearchableTeamItem(
          id: p.id,
          name: p.name,
          shortName: p.shortName,
          logoUrl: p.logoUrl,
          photoUrl: p.photoUrl,
          sport: sport,
          league: leagueName,
          country: p.country ?? event.leagueModel?.country,
          record: p.record,
          isCombat: isCombat,
        ),
      );
    }
  }

  final sorted = itemsMap.values.toList()
    ..sort((a, b) {
      final sportCmp = a.sport.displayName.compareTo(b.sport.displayName);
      if (sportCmp != 0) return sportCmp;
      final leagueCmp = a.league.compareTo(b.league);
      if (leagueCmp != 0) return leagueCmp;
      return a.name.compareTo(b.name);
    });

  return sorted;
});

/// Filtered teams according to search query and selected sport tag
final filteredTeamsProvider = Provider<List<SearchableTeamItem>>((ref) {
  final allTeams = ref.watch(allAvailableTeamsProvider);
  final query = ref.watch(favoritesSearchQueryProvider).trim().toLowerCase();
  final sportFilter = ref.watch(favoritesSportFilterProvider);

  return allTeams.where((team) {
    if (sportFilter != SportType.all && team.sport != sportFilter) return false;
    if (query.isEmpty) return true;

    final nameMatch = team.name.toLowerCase().contains(query);
    final shortNameMatch = team.shortName?.toLowerCase().contains(query) ?? false;
    final leagueMatch = team.league.toLowerCase().contains(query);
    final countryMatch = team.country?.toLowerCase().contains(query) ?? false;

    return nameMatch || shortNameMatch || leagueMatch || countryMatch;
  }).toList();
});

/// All followed teams regardless of sport filter (used in "Mis equipos" tab)
final followedTeamsListProvider = Provider<List<SearchableTeamItem>>((ref) {
  final allTeams = ref.watch(allAvailableTeamsProvider);
  final favoriteIds = ref.watch(favoriteTeamIdsProvider);

  return allTeams.where((team) => favoriteIds.contains(team.id)).toList();
});

// ─── Ligas seguidas ────────────────────────────────────────────────────────────
/// Notifier que guarda los nombres (lowercase) de ligas que el usuario sigue
class FavoriteLeaguesNotifier extends StateNotifier<Set<String>> {
  FavoriteLeaguesNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final cached = await CacheService.getFollowedLeagues();
    if (cached.isNotEmpty) {
      state = cached;
    }
  }

  void toggle(String leagueName) {
    final lower = leagueName.toLowerCase();
    if (state.contains(lower)) {
      state = {...state}..remove(lower);
    } else {
      state = {...state, lower};
    }
    CacheService.saveFollowedLeagues(state);
  }

  bool isFollowing(String leagueName) => state.contains(leagueName.toLowerCase());
}

final followedLeaguesProvider =
    StateNotifierProvider<FavoriteLeaguesNotifier, Set<String>>((ref) {
  return FavoriteLeaguesNotifier();
});
