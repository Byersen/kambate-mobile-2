import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/sport_type.dart';
import '../../models/searchable_team_item.dart';
import '../../providers/favorites_provider.dart';
import '../widgets/favorites_sport_chips.dart';
import '../widgets/team_search_card.dart';

const _kWesternTeams = [
  'Denver Nuggets', 'Minnesota Timberwolves', 'Oklahoma City Thunder', 'Portland Trail Blazers', 'Utah Jazz',
  'Golden State Warriors', 'LA Clippers', 'Los Angeles Lakers', 'Phoenix Suns', 'Sacramento Kings',
  'Dallas Mavericks', 'Houston Rockets', 'Memphis Grizzlies', 'New Orleans Pelicans', 'San Antonio Spurs'
];

const _kEasternTeams = [
  'Boston Celtics', 'Brooklyn Nets', 'New York Knicks', 'Philadelphia 76ers', 'Toronto Raptors',
  'Chicago Bulls', 'Cleveland Cavaliers', 'Detroit Pistons', 'Indiana Pacers', 'Milwaukee Bucks',
  'Atlanta Hawks', 'Charlotte Hornets', 'Miami Heat', 'Orlando Magic', 'Washington Wizards'
];

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
    final allTeams = ref.watch(filteredTeamsProvider);
    final isSearching = query.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
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
          _buildExploreTab(allTeams, favoriteTeamIds, isSearching, query),
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
                onPressed: () => _tabController.animateTo(1),
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


  Widget _buildExploreTab(
    List<SearchableTeamItem> teams,
    Set<String> favoriteTeamIds,
    bool isSearching,
    String query,
  ) {
    return Column(
      children: [
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
                        icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textSecondary),
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

        const FavoritesSportChips(),
        const SizedBox(height: 4),

        Expanded(
          child: teams.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          query.isEmpty ? 'Cargando equipos...' : 'Sin resultados',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          query.isEmpty
                              ? 'Los equipos aparecen aquí una vez que se carguen los partidos.'
                              : 'Prueba con otro término o selecciona un deporte diferente.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildGroupedTeamList(teams, favoriteTeamIds, query),
        ),
      ],
    );
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
    if (['MÉXICO', 'ESTADOS UNIDOS'].contains(country)) return 'NORTEAMÉRICA';
    if (['CONMEBOL', 'ARGENTINA', 'BRASIL', 'CHILE'].contains(country)) return 'SUDAMÉRICA';
    if (['UEFA', 'ESPAÑA', 'INGLATERRA', 'ITALIA', 'ALEMANIA', 'FRANCIA', 'PAÍSES BAJOS', 'PORTUGAL'].contains(country)) return 'EUROPA';
    if (['MUNDIAL', 'COPA AMÉRICA', 'EUROCOPA'].contains(country)) return 'INTERNACIONAL';
    
    return 'RESTO DEL MUNDO';
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
    if (l.contains('eurocopa') || (l.contains('uefa') && l.contains('euro'))) return 'Eurocopa';

    return league.toUpperCase();
  }

  Widget _buildGroupedTeamList(
    List<SearchableTeamItem> teams,
    Set<String> favoriteTeamIds,
    String query,
  ) {
    if (query.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GridView.builder(
          padding: const EdgeInsets.only(bottom: 24, top: 4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.2,
          ),
          itemCount: teams.length,
          itemBuilder: (context, index) {
            final team = teams[index];
            return _buildSimpleCard(team, favoriteTeamIds.contains(team.id));
          },
        ),
      );
    }

    final soccerByRegion = <String, Map<String, Map<String, List<SearchableTeamItem>>>>{};
    final otherBySportLeague = <SportType, Map<String, List<SearchableTeamItem>>>{
      SportType.ufc: {},
      SportType.lol: {},
      SportType.valorant: {},
    };
    List<SearchableTeamItem> nbaTeams = [];

    for (final team in teams) {
      if (team.sport == SportType.nba) {
        nbaTeams.add(team);
      } else if (team.sport == SportType.soccer) {
        final region = _getRegionForLeague(team.league);
        if (region == 'RESTO DEL MUNDO') continue;
        
        final country = _getCountryOrConfederation(team.league);
        final prettyLeague = _getPrettyLeagueName(team.league);
        soccerByRegion.putIfAbsent(region, () => {});
        soccerByRegion[region]!.putIfAbsent(country, () => {});
        soccerByRegion[region]![country]!.putIfAbsent(prettyLeague, () => []).add(team);
      } else {
        otherBySportLeague.putIfAbsent(team.sport, () => {});
        otherBySportLeague[team.sport]!.putIfAbsent(team.league, () => []).add(team);
      }
    }

    final children = <Widget>[];

    if (nbaTeams.isNotEmpty) {
      children.add(
        _CollapsibleSection(
          headerBuilder: (isExpanded) => _buildTopLevelHeader('NBA', isExpanded, SportType.nba),
          initiallyExpanded: false,
          contentBuilder: (context) => _buildNbaGrid(nbaTeams, favoriteTeamIds),
        ),
      );
    }

    int getRegionOrder(String r) {
      if (r == 'SUDAMÉRICA') return 1;
      if (r == 'EUROPA') return 2;
      if (r == 'NORTEAMÉRICA') return 3;
      if (r == 'INTERNACIONAL') return 4;
      return 5;
    }

    final sortedRegions = soccerByRegion.keys.toList()
      ..sort((a, b) => getRegionOrder(a).compareTo(getRegionOrder(b)));

    for (final region in sortedRegions) {
      final countriesMap = soccerByRegion[region]!;
      final regionContent = <Widget>[];

      // Define standard country ordering
      int getCountryOrder(String c) {
        if (c == 'CONMEBOL' || c == 'UEFA') return 1;
        if (c == 'Chile' || c == 'España' || c == 'México' || c == 'Copa América') return 2;
        if (c == 'Argentina' || c == 'Inglaterra' || c == 'Estados Unidos' || c == 'Eurocopa') return 3;
        if (c == 'Brasil' || c == 'Italia' || c == 'Mundial') return 4;
        if (c == 'Alemania') return 5;
        if (c == 'Francia') return 6;
        if (c == 'Países Bajos') return 7;
        if (c == 'Portugal') return 8;
        return 9;
      }

      final sortedCountries = countriesMap.keys.toList()..sort((a, b) => getCountryOrder(a).compareTo(getCountryOrder(b)));
      
      for (final country in sortedCountries) {
        final leaguesMap = countriesMap[country]!;
        final countryContent = <Widget>[];

        final sortedLeagues = leaguesMap.keys.toList()..sort();
        for (final league in sortedLeagues) {
          countryContent.add(
                _buildLeagueHeader(league, country, false, SportType.soccer),
          );
        }

        regionContent.add(
          _CollapsibleSection(
            headerBuilder: (isExpanded) => _buildCountryHeader(country, isExpanded, SportType.soccer, leaguesMap.length),
            initiallyExpanded: false,
            contentBuilder: (context) => Column(children: countryContent),
          ),
        );
      }

      children.add(
        _CollapsibleSection(
          headerBuilder: (isExpanded) => _buildTopLevelHeader(region, isExpanded, SportType.soccer),
          initiallyExpanded: false,
          contentBuilder: (context) => Column(children: regionContent),
        ),
      );
    }

    final sortedSports = otherBySportLeague.keys.toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
      
    for (final sport in sortedSports) {
      final leaguesMap = otherBySportLeague[sport]!;
      final sportContent = <Widget>[];

      final sortedLeagues = leaguesMap.keys.toList()..sort();
      for (final league in sortedLeagues) {
        
        if (sport == SportType.ufc) {
          sportContent.add(
            _buildLeagueHeader(league, sport.displayName, false, sport),
          );
        } else {
          sportContent.add(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLeagueHeader(league, sport.displayName, false, sport),
              ],
            ),
          );
        }
      }

      if (sportContent.isEmpty) {
        sportContent.add(
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'No hay equipos disponibles por ahora.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
          ),
        );
      }

      children.add(
        _CollapsibleSection(
          headerBuilder: (isExpanded) => _buildTopLevelHeader(sport.displayName, isExpanded, sport),
          initiallyExpanded: false,
          contentBuilder: (context) => Column(children: sportContent),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 32, top: 4),
      children: children,
    );
  }

  Widget _buildNbaGrid(List<SearchableTeamItem> nbaTeams, Set<String> favoriteTeamIds) {
    final west = nbaTeams.where((t) => _kWesternTeams.any((wt) => t.name.contains(wt) || wt.contains(t.name))).toList();
    final east = nbaTeams.where((t) => _kEasternTeams.any((et) => t.name.contains(et) || et.contains(t.name))).toList();
    
    final matchedIds = [...west.map((e) => e.id), ...east.map((e) => e.id)];
    final others = nbaTeams.where((t) => !matchedIds.contains(t.id)).toList();
    if (others.isNotEmpty) {
      west.addAll(others.take(others.length ~/ 2));
      east.addAll(others.skip(others.length ~/ 2));
    }

    west.sort((a, b) => a.name.compareTo(b.name));
    east.sort((a, b) => a.name.compareTo(b.name));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8, left: 4),
                  child: Text('OESTE', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                ),
                ...west.map((t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _buildSimpleCard(t, favoriteTeamIds.contains(t.id)))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8, left: 4),
                  child: Text('ESTE', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                ),
                ...east.map((t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _buildSimpleCard(t, favoriteTeamIds.contains(t.id)))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleCard(SearchableTeamItem team, bool isFavorite) {
    final initials = team.name.isNotEmpty
        ? team.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : '?';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFavorite ? AppColors.warning.withValues(alpha: 0.5) : AppColors.cardBorderDark,
        ),
      ),
      child: InkWell(
        onTap: () => ref.read(favoriteTeamIdsProvider.notifier).toggleFavorite(team.id),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardBorderDark),
                ),
                alignment: Alignment.center,
                clipBehavior: Clip.antiAlias,
                child: (team.logoUrl != null || team.photoUrl != null)
                    ? Image.network(
                        (team.logoUrl ?? team.photoUrl)!,
                        width: 18,
                        height: 18,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Text(
                          initials,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      )
                    : Text(
                        initials,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  team.name.replaceAll('Los Angeles ', 'LA '),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color: isFavorite ? AppColors.warning : AppColors.textMuted,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopLevelHeader(String label, bool isExpanded, SportType sport) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: sport.color.withValues(alpha: 0.8), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: sport.color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
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

  Widget _buildCountryHeader(String label, bool isExpanded, SportType sport, [int leagueCount = 0]) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
      child: Row(
        children: [
          Text(_getCountryFlag(label), style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          if (leagueCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$leagueCount',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          const Spacer(),
          Icon(
            isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueHeader(String label, String subtitle, bool isExpanded, SportType sport) {
    return InkWell(
      onTap: () => context.push('/league/${Uri.encodeComponent(label)}', extra: sport),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.cardBorderDark),
              ),
              child: Icon(sport.icon, size: 20, color: sport.color.withValues(alpha: 0.5)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
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

class _CollapsibleSection extends StatefulWidget {
  final Widget Function(bool isExpanded) headerBuilder;
  final WidgetBuilder contentBuilder;
  final bool initiallyExpanded;

  const _CollapsibleSection({
    required this.headerBuilder,
    required this.contentBuilder,
    this.initiallyExpanded = false,
  });

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  late bool _isExpanded;
  bool _hasBeenExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    if (_isExpanded) _hasBeenExpanded = true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isExpanded) _hasBeenExpanded = true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: widget.headerBuilder(_isExpanded),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: _hasBeenExpanded 
              ? widget.contentBuilder(context) 
              : const SizedBox(width: double.infinity, height: 0),
          crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
