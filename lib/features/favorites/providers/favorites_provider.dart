import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/event_model.dart';
import '../../../models/sport_type.dart';
import '../../feed/providers/feed_provider.dart';
import '../models/searchable_team_item.dart';

/// Search query provider for favorites screen
final favoritesSearchQueryProvider = StateProvider<String>((ref) => '');

/// Tag / Sport filter for favorites screen
final favoritesSportFilterProvider = StateProvider<SportType>((ref) => SportType.all);

/// State notifier for followed teams / fighters / clubs IDs
class FavoriteTeamsNotifier extends StateNotifier<Set<String>> {
  FavoriteTeamsNotifier()
      : super({
          'rm', // Real Madrid
          't1', // T1 Telecom
          'f1', // Ilia Topuria
          'lal', // Los Angeles Lakers
        });

  void toggleFavorite(String teamId) {
    if (state.contains(teamId)) {
      state = {...state}..remove(teamId);
    } else {
      state = {...state, teamId};
    }
  }

  bool isFavorite(String teamId) => state.contains(teamId);
}

final favoriteTeamIdsProvider =
    StateNotifierProvider<FavoriteTeamsNotifier, Set<String>>((ref) {
  return FavoriteTeamsNotifier();
});

/// Master catalog of teams, fighters and esports squads
final allAvailableTeamsProvider = Provider<List<SearchableTeamItem>>((ref) {
  final feedState = ref.watch(feedNotifierProvider);
  final List<EventModel> events = feedState.maybeWhen(
    data: (data) => data,
    orElse: () => [],
  );

  final Map<String, SearchableTeamItem> itemsMap = {};

  // 1. Predefined standard teams by sport for comprehensive search
  final predefinedTeams = <SearchableTeamItem>[
    // Fútbol
    const SearchableTeamItem(
      id: 'rm',
      name: 'Real Madrid',
      shortName: 'RMA',
      sport: SportType.soccer,
      league: 'UEFA Champions League / LaLiga',
      country: 'España',
    ),
    const SearchableTeamItem(
      id: 'mc',
      name: 'Manchester City',
      shortName: 'MCI',
      sport: SportType.soccer,
      league: 'Premier League',
      country: 'Inglaterra',
    ),
    const SearchableTeamItem(
      id: 'fcb',
      name: 'FC Barcelona',
      shortName: 'BAR',
      sport: SportType.soccer,
      league: 'LaLiga EA Sports',
      country: 'España',
    ),
    const SearchableTeamItem(
      id: 'cc',
      name: 'Colo-Colo',
      shortName: 'CC',
      sport: SportType.soccer,
      league: 'Primera División de Chile',
      country: 'Chile',
    ),
    const SearchableTeamItem(
      id: 'uch',
      name: 'Universidad de Chile',
      shortName: 'UCH',
      sport: SportType.soccer,
      league: 'Primera División de Chile',
      country: 'Chile',
    ),
    const SearchableTeamItem(
      id: 'bay',
      name: 'Bayern Munich',
      shortName: 'BAY',
      sport: SportType.soccer,
      league: 'Bundesliga',
      country: 'Alemania',
    ),
    const SearchableTeamItem(
      id: 'ars',
      name: 'Arsenal FC',
      shortName: 'ARS',
      sport: SportType.soccer,
      league: 'Premier League',
      country: 'Inglaterra',
    ),

    // LoL (League of Legends)
    const SearchableTeamItem(
      id: 't1',
      name: 'T1 Telecom',
      shortName: 'T1',
      sport: SportType.lol,
      league: 'LCK / Worlds 2026',
      country: 'Corea del Sur',
    ),
    const SearchableTeamItem(
      id: 'geng',
      name: 'Gen.G Esports',
      shortName: 'GEN',
      sport: SportType.lol,
      league: 'LCK / Worlds 2026',
      country: 'Corea del Sur',
    ),
    const SearchableTeamItem(
      id: 'fnc_lol',
      name: 'Fnatic LoL',
      shortName: 'FNC',
      sport: SportType.lol,
      league: 'LEC Europa',
      country: 'Europa',
    ),
    const SearchableTeamItem(
      id: 'g2_lol',
      name: 'G2 Esports',
      shortName: 'G2',
      sport: SportType.lol,
      league: 'LEC Europa',
      country: 'Europa',
    ),
    const SearchableTeamItem(
      id: 'blg',
      name: 'Bilibili Gaming',
      shortName: 'BLG',
      sport: SportType.lol,
      league: 'LPL China',
      country: 'China',
    ),

    // Valorant
    const SearchableTeamItem(
      id: 'sen',
      name: 'Sentinels',
      shortName: 'SEN',
      sport: SportType.valorant,
      league: 'VCT Americas',
      country: 'Estados Unidos',
    ),
    const SearchableTeamItem(
      id: 'kru',
      name: 'KRÜ Esports',
      shortName: 'KRÜ',
      sport: SportType.valorant,
      league: 'VCT Americas',
      country: 'Chile / Argentina',
    ),
    const SearchableTeamItem(
      id: 'lev',
      name: 'Leviatán',
      shortName: 'LEV',
      sport: SportType.valorant,
      league: 'VCT Americas',
      country: 'Chile / Argentina',
    ),
    const SearchableTeamItem(
      id: 'fnc_val',
      name: 'Fnatic Valorant',
      shortName: 'FNC',
      sport: SportType.valorant,
      league: 'VCT EMEA',
      country: 'Europa',
    ),
    const SearchableTeamItem(
      id: 'prx',
      name: 'Paper Rex',
      shortName: 'PRX',
      sport: SportType.valorant,
      league: 'VCT Pacific',
      country: 'Singapur',
    ),

    // NBA
    const SearchableTeamItem(
      id: 'lal',
      name: 'Los Angeles Lakers',
      shortName: 'LAL',
      sport: SportType.nba,
      league: 'NBA Western Conference',
      country: 'Estados Unidos',
    ),
    const SearchableTeamItem(
      id: 'gsw',
      name: 'Golden State Warriors',
      shortName: 'GSW',
      sport: SportType.nba,
      league: 'NBA Western Conference',
      country: 'Estados Unidos',
    ),
    const SearchableTeamItem(
      id: 'bos',
      name: 'Boston Celtics',
      shortName: 'BOS',
      sport: SportType.nba,
      league: 'NBA Eastern Conference',
      country: 'Estados Unidos',
    ),
    const SearchableTeamItem(
      id: 'den',
      name: 'Denver Nuggets',
      shortName: 'DEN',
      sport: SportType.nba,
      league: 'NBA Western Conference',
      country: 'Estados Unidos',
    ),

    // UFC / MMA Fighters
    const SearchableTeamItem(
      id: 'f1',
      name: 'Ilia Topuria',
      shortName: 'El Matador',
      sport: SportType.ufc,
      league: 'UFC Featherweight Champion',
      record: '15-0-0',
      isCombat: true,
      country: 'España / Georgia',
    ),
    const SearchableTeamItem(
      id: 'f2',
      name: 'Max Holloway',
      shortName: 'Blessed',
      sport: SportType.ufc,
      league: 'UFC BMF / Featherweight',
      record: '26-7-0',
      isCombat: true,
      country: 'Estados Unidos',
    ),
    const SearchableTeamItem(
      id: 'f3',
      name: 'Islam Makhachev',
      shortName: 'Islam',
      sport: SportType.ufc,
      league: 'UFC Lightweight Champion',
      record: '26-1-0',
      isCombat: true,
      country: 'Rusia',
    ),
    const SearchableTeamItem(
      id: 'f4',
      name: 'Alex Pereira',
      shortName: 'Poatan',
      sport: SportType.ufc,
      league: 'UFC Light Heavyweight Champion',
      record: '12-2-0',
      isCombat: true,
      country: 'Brasil',
    ),
  ];

  for (final item in predefinedTeams) {
    itemsMap[item.id] = item;
  }

  // 2. Extract dynamically from events
  for (final event in events) {
    if (event.isCombat) {
      if (event.fighter1 != null) {
        itemsMap[event.fighter1!.id] = SearchableTeamItem(
          id: event.fighter1!.id,
          name: event.fighter1!.name,
          shortName: event.fighter1!.nickname,
          photoUrl: event.fighter1!.photoUrl,
          sport: SportType.ufc,
          league: event.league,
          record: event.fighter1!.record,
          isCombat: true,
        );
      }
      if (event.fighter2 != null) {
        itemsMap[event.fighter2!.id] = SearchableTeamItem(
          id: event.fighter2!.id,
          name: event.fighter2!.name,
          shortName: event.fighter2!.nickname,
          photoUrl: event.fighter2!.photoUrl,
          sport: SportType.ufc,
          league: event.league,
          record: event.fighter2!.record,
          isCombat: true,
        );
      }
    } else {
      if (event.homeTeam != null) {
        itemsMap[event.homeTeam!.id] = SearchableTeamItem(
          id: event.homeTeam!.id,
          name: event.homeTeam!.name,
          shortName: event.homeTeam!.shortName,
          logoUrl: event.homeTeam!.logoUrl,
          sport: event.sport,
          league: event.league,
        );
      }
      if (event.awayTeam != null) {
        itemsMap[event.awayTeam!.id] = SearchableTeamItem(
          id: event.awayTeam!.id,
          name: event.awayTeam!.name,
          shortName: event.awayTeam!.shortName,
          logoUrl: event.awayTeam!.logoUrl,
          sport: event.sport,
          league: event.league,
        );
      }
    }

    for (final p in event.participants) {
      if (!itemsMap.containsKey(p.id)) {
        itemsMap[p.id] = SearchableTeamItem(
          id: p.id,
          name: p.name,
          shortName: p.shortName,
          logoUrl: p.logoUrl,
          photoUrl: p.photoUrl,
          sport: event.sport,
          league: event.league,
          country: p.country,
          record: p.record,
          isCombat: event.isCombat,
        );
      }
    }
  }

  return itemsMap.values.toList();
});

/// Filtered teams according to search query and selected sport tag
final filteredTeamsProvider = Provider<List<SearchableTeamItem>>((ref) {
  final allTeams = ref.watch(allAvailableTeamsProvider);
  final query = ref.watch(favoritesSearchQueryProvider).trim().toLowerCase();
  final sportFilter = ref.watch(favoritesSportFilterProvider);

  return allTeams.where((team) {
    // 1. Sport filter
    if (sportFilter != SportType.all && team.sport != sportFilter) {
      return false;
    }

    // 2. Query filter
    if (query.isEmpty) return true;

    final nameMatch = team.name.toLowerCase().contains(query);
    final shortNameMatch = team.shortName?.toLowerCase().contains(query) ?? false;
    final leagueMatch = team.league.toLowerCase().contains(query);
    final countryMatch = team.country?.toLowerCase().contains(query) ?? false;

    return nameMatch || shortNameMatch || leagueMatch || countryMatch;
  }).toList();
});

/// List of followed favorite teams (matching sport filter)
final followedTeamsListProvider = Provider<List<SearchableTeamItem>>((ref) {
  final allTeams = ref.watch(allAvailableTeamsProvider);
  final favoriteIds = ref.watch(favoriteTeamIdsProvider);
  final sportFilter = ref.watch(favoritesSportFilterProvider);

  return allTeams.where((team) {
    if (!favoriteIds.contains(team.id)) return false;
    if (sportFilter != SportType.all && team.sport != sportFilter) return false;
    return true;
  }).toList();
});

/// Filtered events that are either favorite or have a favorite team participating
final filteredFavoritesEventsProvider = Provider<List<EventModel>>((ref) {
  final feedState = ref.watch(feedNotifierProvider);
  final favoriteTeamIds = ref.watch(favoriteTeamIdsProvider);
  final sportFilter = ref.watch(favoritesSportFilterProvider);
  final query = ref.watch(favoritesSearchQueryProvider).trim().toLowerCase();

  final List<EventModel> allEvents = feedState.maybeWhen(
    data: (data) => data,
    orElse: () => [],
  );

  return allEvents.where((event) {
    // 1. Must be favorite event OR include a followed team
    final hasFollowedTeam = (event.homeTeam != null && favoriteTeamIds.contains(event.homeTeam!.id)) ||
        (event.awayTeam != null && favoriteTeamIds.contains(event.awayTeam!.id)) ||
        (event.fighter1 != null && favoriteTeamIds.contains(event.fighter1!.id)) ||
        (event.fighter2 != null && favoriteTeamIds.contains(event.fighter2!.id));

    final isMarkedFavorite = event.isFavorite;

    if (!isMarkedFavorite && !hasFollowedTeam) {
      return false;
    }

    // 2. Sport tag filter
    if (sportFilter != SportType.all && event.sport != sportFilter) {
      return false;
    }

    // 3. Search query filter
    if (query.isNotEmpty) {
      final p1 = event.participant1Name.toLowerCase();
      final p2 = event.participant2Name.toLowerCase();
      final league = event.league.toLowerCase();
      if (!p1.contains(query) && !p2.contains(query) && !league.contains(query)) {
        return false;
      }
    }

    return true;
  }).toList();
});
