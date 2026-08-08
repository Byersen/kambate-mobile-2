import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/sport_type.dart';
import '../../../feed/presentation/widgets/match_card.dart';
import '../../../feed/providers/feed_provider.dart';
import '../../models/searchable_team_item.dart';
import '../../providers/favorites_provider.dart';
import '../widgets/favorites_sport_chips.dart';
import '../widgets/team_search_card.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(favoritesSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(favoritesSearchQueryProvider);
    final selectedSport = ref.watch(favoritesSportFilterProvider);
    final favoriteTeamIds = ref.watch(favoriteTeamIdsProvider);
    final followedTeams = ref.watch(followedTeamsListProvider);
    final matchingTeams = ref.watch(filteredTeamsProvider);
    final favoriteEvents = ref.watch(filteredFavoritesEventsProvider);

    final isSearching = query.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Siguiendo & Equipos'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                  hintText: 'Buscar equipos, atletas (ej. T1, Madrid, Topuria)...',
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

          // 2. Sport / Category Filter Chips (LoL, Valorant, Fútbol, NBA, UFC, Todos)
          const FavoritesSportChips(),
          const SizedBox(height: 10),

          // 3. Dynamic Body: Search Results OR Favorites Feed
          Expanded(
            child: isSearching
                ? _buildSearchResults(matchingTeams, favoriteEvents, favoriteTeamIds)
                : _buildFavoritesFeed(followedTeams, favoriteEvents, selectedSport),
          ),
        ],
      ),
    );
  }

  /// View when searching by team / athlete name or category
  Widget _buildSearchResults(
    List<SearchableTeamItem> teams,
    List<dynamic> events,
    Set<String> favoriteTeamIds,
  ) {
    if (teams.isEmpty && events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.search_off_rounded, size: 52, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text(
                'No se encontraron coincidencias',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Prueba con otra etiqueta de deporte o término de búsqueda.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (teams.isNotEmpty) ...[
          _buildSectionHeader('EQUIPOS Y ATLETAS', teams.length),
          ...teams.map(
            (team) => TeamSearchCard(
              team: team,
              isFavorite: favoriteTeamIds.contains(team.id),
              onToggleFavorite: () {
                ref.read(favoriteTeamIdsProvider.notifier).toggleFavorite(team.id);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (events.isNotEmpty) ...[
          _buildSectionHeader('PARTIDOS RELACIONADOS', events.length),
          ...events.map(
            (event) => MatchCard(
              event: event,
              onTap: () => context.push('/detail/${event.id}', extra: event),
              onFavoriteToggle: () =>
                  ref.read(feedNotifierProvider.notifier).toggleFavorite(event.id),
            ),
          ),
        ],
      ],
    );
  }

  /// View when not searching (Browsing followed teams and favorite matches)
  Widget _buildFavoritesFeed(
    List<SearchableTeamItem> followedTeams,
    List<dynamic> favoriteEvents,
    SportType selectedSport,
  ) {
    if (followedTeams.isEmpty && favoriteEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardBorderDark),
                ),
                child: const Icon(Icons.star_outline_rounded, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'Aún no sigues equipos ni partidos',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Usa el buscador arriba o las etiquetas de deportes (LoL, Valorant, Fútbol, etc.) para encontrar tus clubes y marcadores favoritos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Horizontal Followed Teams Strip
        if (followedTeams.isNotEmpty) ...[
          _buildSectionHeader('EQUIPOS QUE SIGUES', followedTeams.length),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: followedTeams.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final team = followedTeams[index];
                return _FollowedTeamChip(
                  team: team,
                  onRemove: () {
                    ref.read(favoriteTeamIdsProvider.notifier).toggleFavorite(team.id);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Favorite Matches List
        _buildSectionHeader(
          selectedSport == SportType.all
              ? 'TODOS LOS PARTIDOS FAVORITOS'
              : 'PARTIDOS FAVORITOS • ${selectedSport.displayName.toUpperCase()}',
          favoriteEvents.length,
        ),
        if (favoriteEvents.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorderDark),
              ),
              child: const Text(
                'No hay partidos programados para tus favoritos en esta disciplina.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          )
        else
          ...favoriteEvents.map(
            (event) => MatchCard(
              event: event,
              onTap: () => context.push('/detail/${event.id}', extra: event),
              onFavoriteToggle: () =>
                  ref.read(feedNotifierProvider.notifier).toggleFavorite(event.id),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorderDark),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowedTeamChip extends StatelessWidget {
  final SearchableTeamItem team;
  final VoidCallback onRemove;

  const _FollowedTeamChip({
    required this.team,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final sportColor = team.sport.color;
    final initials = team.name.isNotEmpty
        ? team.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : '?';

    return Container(
      width: 88,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sportColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: sportColor, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: TextStyle(
                    color: sportColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                right: -6,
                top: -6,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceDark,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cancel,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            team.shortName ?? team.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
