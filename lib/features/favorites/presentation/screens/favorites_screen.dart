import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        title: const Text('Siguiendo'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          tabs: [
            Tab(
              text: followedTeams.isEmpty
                  ? 'Mis equipos'
                  : 'Mis equipos (${followedTeams.length})',
            ),
            const Tab(text: 'Explorar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFollowingTab(followedTeams, favoriteTeamIds),
          _buildExploreTab(allTeams, favoriteTeamIds, isSearching, query),
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

  String _getRegionForLeague(String league) {
    final l = league.toLowerCase();
    
    if (['mex', 'usa', 'mls', 'mx', 'concacaf', 'major league'].any((x) => l.contains(x))) return 'NORTEAMÉRICA';
    
    if (['conmebol', 'arg', 'bra', 'chi', 'col', 'libertadores', 'sudamericana', 'argentina', 'brasil', 'chile', 'colombia', 'brasileirão', 'argentine', 'brazilian', 'chilean', 'colombian'].any((x) => l.contains(x))) return 'SUDAMÉRICA';
    
    if (['fifa', 'mundial', 'world cup', 'selecciones', 'copa américa', 'eurocopa', 'internacional', 'friendlies', 'amistosos'].any((x) => l.contains(x))) return 'SELECCIONES';
    
    if (['esp', 'eng', 'ita', 'ger', 'fra', 'ned', 'por', 'tur', 'uefa', 'champions', 'europa', 'premier', 'laliga', 'bundesliga', 'serie a', 'ligue 1', 'eredivisie', 'primeira', 'españa', 'inglaterra', 'spanish', 'english', 'italian', 'german', 'french', 'dutch', 'portuguese', 'turkish', 'süper lig', 'super lig'].any((x) => l.contains(x))) return 'EUROPA';
    
    if (l.contains('liga')) return 'EUROPA';

    return 'RESTO DEL MUNDO';
  }

  String _getPrettyLeagueName(String league) {
    final l = league.toLowerCase();
    
    if (l.contains('mex') || l.contains('mx')) return 'MEX - LIGA MX';
    if (l.contains('usa') || l.contains('mls') || l.contains('major league')) return 'USA - MLS';
    
    if (l.contains('arg') || l.contains('argentin')) return 'ARG - LIGA PROF. DE FÚTBOL';
    if (l.contains('bra') || l.contains('brazilian') || l.contains('brasileir')) return 'BRA - BRASILEIRÃO';
    if (l.contains('chi') || l.contains('chile')) return 'CHI - PRIMERA DIVISIÓN';
    if (l.contains('col') || l.contains('colombia')) return 'COL - PRIMERA A';
    if (l.contains('libertadores')) return 'CONMEBOL LIBERTADORES';
    if (l.contains('sudamericana')) return 'CONMEBOL SUDAMERICANA';
    
    if (l.contains('esp') || l.contains('spanish') || l.contains('laliga')) return 'ESP - LALIGA';
    if (l.contains('eng') || l.contains('english') || l.contains('premier')) return 'ENG - PREMIER LEAGUE';
    if (l.contains('ita') || l.contains('italian') || l.contains('serie a')) return 'ITA - SERIE A';
    if (l.contains('ger') || l.contains('german') || l.contains('bundesliga')) return 'GER - BUNDESLIGA';
    if (l.contains('fra') || l.contains('french') || l.contains('ligue 1')) return 'FRA - LIGUE 1';
    if (l.contains('ned') || l.contains('dutch') || l.contains('eredivisie')) return 'NED - EREDIVISIE';
    if (l.contains('por') || l.contains('portuguese') || l.contains('primeira')) return 'POR - PRIMEIRA LIGA';
    if (l.contains('tur') || l.contains('turkish') || l.contains('süper') || l.contains('super')) return 'TUR - SÜPER LIG';
    
    if (l.contains('fifa') || l.contains('world cup') || l.contains('mundial')) return 'COPA MUNDIAL DE LA FIFA';
    if (l.contains('copa américa')) return 'COPA AMÉRICA';
    if (l.contains('eurocopa') || (l.contains('uefa') && l.contains('euro'))) return 'EUROCOPA';

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

    final soccerByRegion = <String, Map<String, List<SearchableTeamItem>>>{};
    final otherBySportLeague = <String, List<SearchableTeamItem>>{};
    List<SearchableTeamItem> nbaTeams = [];

    for (final team in teams) {
      if (team.sport == SportType.nba) {
        nbaTeams.add(team);
      } else if (team.sport == SportType.soccer) {
        final region = _getRegionForLeague(team.league);
        final prettyLeague = _getPrettyLeagueName(team.league);
        soccerByRegion.putIfAbsent(region, () => {});
        soccerByRegion[region]!.putIfAbsent(prettyLeague, () => []).add(team);
      } else {
        final key = '${team.sport.displayName} · ${team.league}';
        otherBySportLeague.putIfAbsent(key, () => []).add(team);
      }
    }

    final children = <Widget>[];

    if (nbaTeams.isNotEmpty) {
      children.add(
        _CollapsibleSection(
          headerBuilder: (isExpanded) => _buildLeagueHeader('BALONCESTO · NBA', isExpanded),
          initiallyExpanded: false,
          content: _buildNbaGrid(nbaTeams, favoriteTeamIds),
        ),
      );
    }

    int getRegionOrder(String r) {
      if (r == 'EUROPA') return 1;
      if (r == 'NORTEAMÉRICA') return 2;
      if (r == 'SUDAMÉRICA') return 3;
      if (r == 'SELECCIONES') return 4;
      return 5;
    }

    final sortedRegions = soccerByRegion.keys.toList()
      ..sort((a, b) => getRegionOrder(a).compareTo(getRegionOrder(b)));

    for (final region in sortedRegions) {
      final leaguesMap = soccerByRegion[region]!;
      final regionContent = <Widget>[];

      final sortedLeagues = leaguesMap.keys.toList()..sort();
      for (final league in sortedLeagues) {
        final leagueTeams = leaguesMap[league]!..sort((a, b) => a.name.compareTo(b.name));
        regionContent.add(
          _CollapsibleSection(
            headerBuilder: (isExpanded) => _buildLeagueHeader(league, isExpanded),
            initiallyExpanded: false,
            content: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 3.2,
                ),
                itemCount: leagueTeams.length,
                itemBuilder: (context, index) => _buildSimpleCard(
                  leagueTeams[index],
                  favoriteTeamIds.contains(leagueTeams[index].id),
                ),
              ),
            ),
          ),
        );
      }

      children.add(
        _CollapsibleSection(
          headerBuilder: (isExpanded) => _buildRegionHeader(region, isExpanded),
          initiallyExpanded: false,
          content: Column(children: regionContent),
        ),
      );
    }

    final sortedOther = otherBySportLeague.keys.toList()..sort();
    for (final key in sortedOther) {
      final leagueTeams = otherBySportLeague[key]!..sort((a, b) => a.name.compareTo(b.name));
      children.add(
        _CollapsibleSection(
          headerBuilder: (isExpanded) => _buildLeagueHeader(key, isExpanded),
          initiallyExpanded: false,
          content: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 3.2,
              ),
              itemCount: leagueTeams.length,
              itemBuilder: (context, index) => _buildSimpleCard(
                leagueTeams[index],
                favoriteTeamIds.contains(leagueTeams[index].id),
              ),
            ),
          ),
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
                child: Text(
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

  Widget _buildRegionHeader(String label, bool isExpanded) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.cardBorderDark),
            ),
            child: Row(
              children: [
                Icon(
                  label == 'EUROPA'
                      ? Icons.public
                      : label == 'NORTEAMÉRICA'
                          ? Icons.map
                          : label == 'SUDAMÉRICA'
                              ? Icons.south_america
                              : Icons.language,
                  size: 14,
                  color: AppColors.soccer,
                ),
                const SizedBox(width: 6),
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(height: 1, color: AppColors.cardBorderDark),
          ),
          const SizedBox(width: 8),
          Icon(
            isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueHeader(String label, bool isExpanded) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.cardBorderDark),
            ),
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(height: 1, color: AppColors.cardBorderDark),
          ),
          const SizedBox(width: 8),
          Icon(
            isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
        ],
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
              color: sport.color.withValues(alpha: 0.15),
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
              color: AppColors.cardBorderDark,
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
  final Widget content;
  final bool initiallyExpanded;

  const _CollapsibleSection({
    required this.headerBuilder,
    required this.content,
    this.initiallyExpanded = false,
  });

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
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
          secondChild: widget.content,
          crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
