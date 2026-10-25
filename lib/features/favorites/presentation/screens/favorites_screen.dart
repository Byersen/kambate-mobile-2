import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/event_model.dart';
import '../../../../models/sport_type.dart';
import '../../../feed/providers/feed_provider.dart';
import '../../models/search_league_item.dart';
import '../../models/searchable_team_item.dart';
import '../../providers/favorites_provider.dart';
import '../widgets/favorites_region_tabs.dart';
import '../widgets/favorites_sport_chips.dart';
import '../widgets/league_search_card.dart';
import '../widgets/team_search_card.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(favoritesSearchQueryProvider),
    );
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(favoritesSearchQueryProvider);
    final favoriteTeamIds = ref.watch(favoriteTeamIdsProvider);
    final followedTeams = ref.watch(followedTeamsListProvider);
    final isSearching = query.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'Buscar',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          tabs: [
            const Tab(text: 'Explorar'),
            Tab(
              text: followedTeams.isEmpty
                  ? 'Mis equipos'
                  : 'Mis equipos (${followedTeams.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExploreTab(isSearching, query),
          _buildFollowingTab(followedTeams, favoriteTeamIds),
        ],
      ),
    );
  }

  Widget _buildFollowingTab(
    List<SearchableTeamItem> followedTeams,
    Set<String> favoriteTeamIds,
  ) {
    if (followedTeams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardBorderDark),
                ),
                child: const Icon(
                  Icons.sports_rounded,
                  size: 52,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Aún no sigues ningún equipo',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ve a la pestaña Explorar para encontrar equipos y ligas que te interesen.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => _tabController.animateTo(0),
                icon: const Icon(Icons.explore_rounded, size: 16),
                label: const Text('Explorar equipos'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final grouped = <SportType, List<SearchableTeamItem>>{};
    for (final team in followedTeams) {
      grouped.putIfAbsent(team.sport, () => []).add(team);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24, top: 8),
      children: [
        for (final sport in grouped.keys) ...[
          _buildSportGroupHeader(sport, grouped[sport]!.length),
          ...grouped[sport]!.map(
            (team) => TeamSearchCard(
              team: team,
              isFavorite: true,
              onToggleFavorite: () {
                ref.read(favoriteTeamIdsProvider.notifier).toggleFavorite(team.id);
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildExploreTab(bool isSearching, String query) {
    final feedState = ref.watch(feedNotifierProvider);
    final selectedSport = ref.watch(favoritesSportFilterProvider);
    final selectedRegion = ref.watch(favoritesRegionFilterProvider);
    final allTeams = ref.watch(filteredTeamsProvider);

    return Column(
      children: [
        // Campo de búsqueda según vista-buscar.png
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSearching ? AppColors.primary : AppColors.cardBorderDark,
                width: isSearching ? 1.5 : 1.0,
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar equipos, atletas, ligas...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isSearching ? AppColors.primary : AppColors.textMuted,
                  size: 20,
                ),
                suffixIcon: isSearching
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(favoritesSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onChanged: (val) {
                ref.read(favoritesSearchQueryProvider.notifier).state = val;
              },
            ),
          ),
        ),

        // Filtros por deporte (pills horizontales) según vista-buscar.png
        const FavoritesSportChips(),
        const SizedBox(height: 8),

        // Selector de región (Todos, Europa, Sudamérica, Norteamérica, Internacional) según vista-buscar.png
        const FavoritesRegionTabs(),
        const SizedBox(height: 6),

        // Área de contenido según estado: Cargando, Error, Vacío o Vista Completa
        Expanded(
          child: _buildExploreContent(
            feedState: feedState,
            selectedSport: selectedSport,
            selectedRegion: selectedRegion,
            query: query.trim(),
            allTeams: allTeams,
          ),
        ),
      ],
    );
  }

  Widget _buildExploreContent({
    required AsyncValue<List<EventModel>> feedState,
    required SportType selectedSport,
    required String selectedRegion,
    required String query,
    required List<SearchableTeamItem> allTeams,
  }) {
    // 1. Estado Cargando
    if (feedState.isLoading && !feedState.hasValue) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Cargando ligas y competiciones...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // 2. Estado Error
    if (feedState.hasError && (!feedState.hasValue || feedState.value!.isEmpty)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 16),
              const Text(
                'No pudimos cargar la información',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Revisa tu conexión e inténtalo de nuevo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => ref
                    .read(feedNotifierProvider.notifier)
                    .loadEvents(forceRefresh: true),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reintentar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Extraer y combinar ligas canónicas con las disponibles en eventos
    final events = feedState.value ?? [];
    final allLeagues = _getAllLeagues(events);

    // Filtrar ligas según deporte, región y consulta
    final filteredLeagues = allLeagues.where((league) {
      // Filtro de deporte
      if (selectedSport != SportType.all && league.sport != selectedSport) {
        return false;
      }
      // Filtro de región
      if (selectedRegion != 'Todos' &&
          league.region.toLowerCase() != selectedRegion.toLowerCase()) {
        return false;
      }
      // Filtro de búsqueda textual
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        final matchesName = league.name.toLowerCase().contains(q);
        final matchesSub = league.subtitle.toLowerCase().contains(q);
        final matchesSport = league.sport.displayName.toLowerCase().contains(q);
        if (!matchesName && !matchesSub && !matchesSport) return false;
      }
      return true;
    }).toList();

    // Priorizar Worlds al filtrar por LoL
    if (selectedSport == SportType.lol) {
      filteredLeagues.sort((a, b) {
        final aIsWorlds = a.name.toLowerCase().contains('worlds');
        final bIsWorlds = b.name.toLowerCase().contains('worlds');
        if (aIsWorlds && !bIsWorlds) return -1;
        if (!aIsWorlds && bIsWorlds) return 1;
        return a.name.compareTo(b.name);
      });
    }

    // Si se está buscando texto y no hay ligas, pero hay equipos que coinciden
    final matchingTeams = query.isNotEmpty
        ? allTeams.where((team) {
            final q = query.toLowerCase();
            return team.name.toLowerCase().contains(q) ||
                (team.shortName?.toLowerCase().contains(q) ?? false) ||
                team.league.toLowerCase().contains(q);
          }).toList()
        : <SearchableTeamItem>[];

    // 3. Estado Vacío
    if (filteredLeagues.isEmpty && matchingTeams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 16),
              const Text(
                'Sin resultados',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                query.isNotEmpty
                    ? 'No encontramos coincidencias para "$query".'
                    : 'No hay ligas disponibles con los filtros actuales.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              if (query.isNotEmpty ||
                  selectedSport != SportType.all ||
                  selectedRegion != 'Todos') ...[
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    ref.read(favoritesSearchQueryProvider.notifier).state = '';
                    ref.read(favoritesSportFilterProvider.notifier).state = SportType.all;
                    ref.read(favoritesRegionFilterProvider.notifier).state = 'Todos';
                  },
                  icon: const Icon(Icons.clear_all_rounded, size: 16),
                  label: const Text('Restablecer filtros'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // 4. Vista Completa: Tarjetas de ligas en dos columnas según vista-buscar.png
    return GridView.builder(
      key: const PageStorageKey('explore-leagues-grid'),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.18,
      ),
      itemCount: filteredLeagues.length,
      itemBuilder: (context, index) {
        final league = filteredLeagues[index];
        return LeagueSearchCard(
          key: ValueKey('league_card_${league.name}'),
          league: league,
        );
      },
    );
  }

  List<SearchLeagueItem> _getAllLeagues(List<EventModel> events) {
    final Map<String, SearchLeagueItem> map = {};
    for (final cl in kCanonicalLeagues) {
      map[cl.name.toLowerCase()] = cl;
    }

    for (final event in events) {
      final prettyName = _getPrettyLeagueName(event.league);
      final key = prettyName.toLowerCase();
      if (!map.containsKey(key)) {
        final region = _getRegionForLeague(event.league);
        final country = event.leagueModel?.country ?? _getCountryOrConfederation(event.league);
        final flag = _getCountryFlag(country);
        map[key] = SearchLeagueItem(
          name: prettyName,
          subtitle: '$flag $country',
          sport: event.sport,
          region: region,
          icon: event.sport.icon,
          color: event.sport.color,
        );
      }
    }
    return map.values.toList();
  }

  String _getCountryOrConfederation(String league) {
    final l = league.toLowerCase();
    if (['mex', 'mx'].any((x) => l.contains(x))) return 'México';
    if (['usa', 'mls', 'major league'].any((x) => l.contains(x))) return 'Estados Unidos';
    if (['libertadores', 'sudamericana', 'recopa', 'conmebol'].any((x) => l.contains(x))) return 'CONMEBOL';
    if (['arg', 'argentin', 'liga prof', 'copa de la liga', 'copa argentina'].any((x) => l.contains(x))) return 'Argentina';
    if (['bra', 'brasileir', 'copa do brasil', 'paulista', 'carioca'].any((x) => l.contains(x))) return 'Brasil';
    if (['chi', 'chile', 'campeonato itaú', 'copa chile'].any((x) => l.contains(x))) return 'Chile';
    if (['esp', 'españa', 'spanish', 'laliga'].any((x) => l.contains(x))) return 'España';
    if (['eng', 'inglaterra', 'english', 'premier'].any((x) => l.contains(x))) return 'Inglaterra';
    if (['ita', 'italian', 'serie a'].any((x) => l.contains(x))) return 'Italia';
    if (['ger', 'german', 'bundesliga'].any((x) => l.contains(x))) return 'Alemania';
    if (['fra', 'french', 'ligue 1'].any((x) => l.contains(x))) return 'Francia';
    if (['ned', 'dutch', 'eredivisie', 'paises bajos', 'países bajos'].any((x) => l.contains(x))) return 'Países Bajos';
    if (['por', 'portuguese', 'primeira', 'portugal'].any((x) => l.contains(x))) return 'Portugal';
    if (['champions', 'europa league', 'conference', 'supercopa de europa', 'uefa'].any((x) => l.contains(x))) return 'UEFA';
    if (['mundial', 'world cup'].any((x) => l.contains(x))) return 'Mundial';
    if (['copa américa'].any((x) => l.contains(x))) return 'Copa América';
    if (['eurocopa'].any((x) => l.contains(x))) return 'Eurocopa';
    return 'Otros';
  }

  String _getRegionForLeague(String league) {
    final country = _getCountryOrConfederation(league).toUpperCase();
    if (['MÉXICO', 'ESTADOS UNIDOS'].contains(country)) return 'Norteamérica';
    if (['CONMEBOL', 'ARGENTINA', 'BRASIL', 'CHILE'].contains(country)) return 'Sudamérica';
    if (['UEFA', 'ESPAÑA', 'INGLATERRA', 'ITALIA', 'ALEMANIA', 'FRANCIA', 'PAÍSES BAJOS', 'PORTUGAL'].contains(country)) return 'Europa';
    if (['MUNDIAL', 'COPA AMÉRICA', 'EUROCOPA'].contains(country)) return 'Internacional';
    return 'Internacional';
  }

  String _getPrettyLeagueName(String league) {
    final l = league.toLowerCase();
    if (l.contains('mex') || l.contains('mx')) return 'Liga MX';
    if (l.contains('usa') || l.contains('mls') || l.contains('major league')) return 'MLS';
    if (l.contains('copa argentina')) return 'Copa Argentina';
    if (l.contains('copa de la liga')) return 'Copa de la Liga';
    if (l.contains('arg') || l.contains('argentin') || l.contains('liga prof')) return 'Liga Profesional';
    if (l.contains('copa do brasil')) return 'Copa do Brasil';
    if (l.contains('bra') || l.contains('brazilian') || l.contains('brasileir')) return 'Brasileirão';
    if (l.contains('copa chile')) return 'Copa Chile';
    if (l.contains('chi') || l.contains('chile') || l.contains('campeonato itaú')) return 'Primera División';
    if (l.contains('col') || l.contains('colombia')) return 'Primera A';
    if (l.contains('libertadores')) return 'Copa Libertadores';
    if (l.contains('sudamericana')) return 'Copa Sudamericana';
    if (l.contains('recopa')) return 'Recopa Sudamericana';
    if (l.contains('champions')) return 'Champions League';
    if (l.contains('europa league') || (l.contains('europa') && !l.contains('eurocopa'))) return 'Europa League';
    if (l.contains('conference')) return 'Conference League';
    if (l.contains('supercopa de europa')) return 'Supercopa de Europa';
    if (l.contains('esp') || l.contains('spanish') || l.contains('laliga')) return 'LaLiga';
    if (l.contains('eng') || l.contains('english') || l.contains('premier')) return 'Premier League';
    if (l.contains('ita') || l.contains('italian') || l.contains('serie a')) return 'Serie A';
    if (l.contains('ger') || l.contains('german') || l.contains('bundesliga')) return 'Bundesliga';
    if (l.contains('fra') || l.contains('french') || l.contains('ligue 1')) return 'Ligue 1';
    if (l.contains('ned') || l.contains('dutch') || l.contains('eredivisie')) return 'Eredivisie';
    if (l.contains('por') || l.contains('portuguese') || l.contains('primeira')) return 'Primeira Liga';
    if (l.contains('tur') || l.contains('turkish') || l.contains('süper') || l.contains('super')) return 'Süper Lig';
    if (l.contains('fifa') || l.contains('world cup') || l.contains('mundial')) return 'Copa Mundial';
    if (l.contains('copa américa')) return 'Copa América';
    if (l.contains('worlds') || l.contains('world championship')) return 'Worlds';
    if (l.contains('eurocopa') || (l.contains('uefa') && l.contains('euro'))) return 'Eurocopa';
    return league.toUpperCase();
  }

  String _getCountryFlag(String country) {
    switch (country.toUpperCase()) {
      case 'CHILE': return '🇨🇱';
      case 'ARGENTINA': return '🇦🇷';
      case 'BRASIL': return '🇧🇷';
      case 'MÉXICO': return '🇲🇽';
      case 'ESTADOS UNIDOS': return '🇺🇸';
      case 'ESPAÑA': return '🇪🇸';
      case 'INGLATERRA': return '🏴󠁧󠁢󠁥󠁮󠁧󠁿';
      case 'ITALIA': return '🇮🇹';
      case 'ALEMANIA': return '🇩🇪';
      case 'FRANCIA': return '🇫🇷';
      case 'PAÍSES BAJOS': return '🇳🇱';
      case 'PORTUGAL': return '🇵🇹';
      case 'CONMEBOL': return '🌎';
      case 'UEFA': return '🇪🇺';
      case 'INTERNACIONAL': return '🌐';
      case 'MUNDIAL': return '🏆';
      default: return '🏳️';
    }
  }

  Widget _buildSportGroupHeader(SportType sport, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: sport.color.withValues(alpha: 0.4)),
            ),
            child: Text(
              sport.displayName.toUpperCase(),
              style: TextStyle(
                color: sport.color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: sport.color.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count equipo${count != 1 ? 's' : ''}',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
