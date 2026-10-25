import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/event_model.dart';
import '../../../../models/league_detail_model.dart';
import '../../../../models/sport_type.dart';
import '../../../feed/presentation/widgets/match_card.dart';
import '../../../feed/providers/feed_provider.dart';
import '../../data/league_detail_repository.dart';
import '../../providers/league_detail_provider.dart';
import '../../providers/lol_worlds_provider.dart';
import '../widgets/lol_worlds_swiss_view.dart';

class LeagueDetailScreen extends ConsumerStatefulWidget {
  final String leagueName;
  final SportType sport;
  final String? leagueSlug;
  final String? leagueId;
  final String? seasonId;

  const LeagueDetailScreen({
    super.key,
    required this.leagueName,
    this.sport = SportType.soccer,
    this.leagueSlug,
    this.leagueId,
    this.seasonId,
  });

  @override
  ConsumerState<LeagueDetailScreen> createState() => _LeagueDetailScreenState();
}

class _LeagueDetailScreenState extends ConsumerState<LeagueDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  LeagueDetailParams _resolveParams(List<EventModel> events) {
    String? resolvedSlug = widget.leagueSlug;
    String? resolvedLeagueId = widget.leagueId;
    String? resolvedSeasonId = widget.seasonId;

    if (resolvedSlug == null || resolvedLeagueId == null || resolvedSeasonId == null) {
      final matching = events.where((e) {
        final eventLeague = _getPrettyLeagueName(e.league).toLowerCase();
        final target = widget.leagueName.toLowerCase();
        return eventLeague == target ||
            eventLeague.contains(target) ||
            target.contains(eventLeague);
      });

      if (matching.isNotEmpty) {
        final first = matching.first;
        resolvedSlug ??= first.leagueModel?.slug;
        resolvedLeagueId ??= first.leagueModel?.id;
        resolvedSeasonId ??= first.seasonModel?.id;
      }
    }

    resolvedSlug ??= LeagueDetailRepository.resolveLeagueSlug(widget.leagueName);

    return LeagueDetailParams(
      leagueName: widget.leagueName,
      leagueSlug: resolvedSlug,
      leagueId: resolvedLeagueId,
      seasonId: resolvedSeasonId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedNotifierProvider);
    final events = feedAsync.maybeWhen(
      data: (list) => list,
      orElse: () => const <EventModel>[],
    );
    final params = _resolveParams(events);

    final isWorlds = widget.sport == SportType.lol &&
        (params.leagueSlug?.contains('worlds') == true ||
            widget.leagueName.toLowerCase().contains('worlds'));

    if (isWorlds) {
      final worldsAsync = ref.watch(lolWorldsStageProvider(params.seasonId));
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceDark,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            widget.leagueName.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppColors.textSecondary,
              ),
              onPressed: () =>
                  ref.refresh(lolWorldsStageProvider(params.seasonId)),
            ),
          ],
        ),
        body: worldsAsync.when(
          data: (stageData) => LolWorldsSwissView(
            stageData: stageData,
            onRefresh: () =>
                ref.refresh(lolWorldsStageProvider(params.seasonId)),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: _buildNoCoverageState(
              icon: Icons.error_outline_rounded,
              title: 'Error al conectar con la fuente',
              subtitle: 'No se pudo recuperar la información de Worlds ($e).',
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: AppColors.surfaceDark,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => context.pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding:
                    const EdgeInsets.only(left: 48, bottom: 16, right: 16),
                title: Text(
                  widget.leagueName.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            widget.sport.color.withValues(alpha: 0.3),
                            AppColors.surfaceDark,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: -20,
                      top: 40,
                      child: Icon(
                        widget.sport.icon,
                        size: 150,
                        color: widget.sport.color.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: widget.sport.color,
                labelColor: widget.sport.color,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Partidos'),
                  Tab(text: 'Tabla'),
                  Tab(text: 'Estadísticas'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMatchesTab(params),
            _buildStandingsTab(params),
            _buildStatsTab(params),
          ],
        ),
      ),
    );
  }

  String _getPrettyLeagueName(String league) {
    final l = league.toLowerCase();

    if (l.contains('mex') || l.contains('mx')) return 'Liga MX';
    if (l.contains('usa') || l.contains('mls') || l.contains('major league')) {
      return 'MLS';
    }

    if (l.contains('copa argentina')) return 'Copa Argentina';
    if (l.contains('copa de la liga')) return 'Copa de la Liga';
    if (l.contains('arg') || l.contains('argentin') || l.contains('liga prof')) {
      return 'Liga Profesional';
    }

    if (l.contains('copa do brasil')) return 'Copa do Brasil';
    if (l.contains('bra') || l.contains('brazilian') || l.contains('brasileir')) {
      return 'Brasileirão';
    }

    if (l.contains('copa chile')) return 'Copa Chile';
    if (l.contains('chi') || l.contains('chile') || l.contains('campeonato itaú')) {
      return 'Primera División';
    }

    if (l.contains('col') || l.contains('colombia')) return 'Primera A';

    if (l.contains('libertadores')) return 'Copa Libertadores';
    if (l.contains('sudamericana')) return 'Copa Sudamericana';
    if (l.contains('recopa')) return 'Recopa Sudamericana';

    if (l.contains('champions')) return 'Champions League';
    if (l.contains('europa league') || (l.contains('europa') && !l.contains('eurocopa'))) {
      return 'Europa League';
    }
    if (l.contains('conference')) return 'Conference League';
    if (l.contains('supercopa de europa')) return 'Supercopa de Europa';

    if (l.contains('esp') || l.contains('spanish') || l.contains('laliga')) {
      return 'LaLiga';
    }
    if (l.contains('eng') || l.contains('english') || l.contains('premier')) {
      return 'Premier League';
    }
    if (l.contains('ita') || l.contains('italian') || l.contains('serie a')) {
      return 'Serie A';
    }
    if (l.contains('ger') || l.contains('german') || l.contains('bundesliga')) {
      return 'Bundesliga';
    }
    if (l.contains('fra') || l.contains('french') || l.contains('ligue 1')) {
      return 'Ligue 1';
    }
    if (l.contains('ned') || l.contains('dutch') || l.contains('eredivisie')) {
      return 'Eredivisie';
    }
    if (l.contains('por') || l.contains('portuguese') || l.contains('primeira')) {
      return 'Primeira Liga';
    }
    if (l.contains('tur') || l.contains('turkish') || l.contains('süper') || l.contains('super')) {
      return 'Süper Lig';
    }

    if (l.contains('nba')) return 'NBA';
    if (l.contains('ufc')) return 'UFC';
    if (l.contains('worlds') || l.contains('world championship')) {
      return 'Worlds';
    }
    if (l.contains('fifa') || l.contains('world cup') || l.contains('mundial')) {
      return 'Copa Mundial';
    }
    if (l.contains('copa américa')) return 'Copa América';
    if (l.contains('eurocopa') || (l.contains('uefa') && l.contains('euro'))) {
      return 'Eurocopa';
    }

    return league.toUpperCase();
  }

  bool _matchesLeagueAndSeason(
    EventModel e,
    LeagueDetailParams params,
  ) {
    // 1. Filtro por temporada si está especificada
    if (params.seasonId != null && params.seasonId!.isNotEmpty) {
      if (e.seasonModel != null &&
          e.seasonModel!.id != params.seasonId &&
          e.seasonModel!.slug != params.seasonId) {
        return false;
      }
    }

    // 2. Filtro por ID de liga
    if (params.leagueId != null &&
        params.leagueId!.isNotEmpty &&
        e.leagueModel?.id == params.leagueId) {
      return true;
    }

    // 3. Filtro por slug de liga
    if (params.leagueSlug != null &&
        params.leagueSlug!.isNotEmpty &&
        e.leagueModel?.slug.toLowerCase() == params.leagueSlug!.toLowerCase()) {
      return true;
    }

    // 4. Filtro por coincidencia de nombre
    final eventLeague = _getPrettyLeagueName(e.league).toLowerCase();
    final targetLeague = widget.leagueName.toLowerCase();
    return eventLeague == targetLeague ||
        eventLeague.contains(targetLeague) ||
        targetLeague.contains(eventLeague);
  }

  Widget _buildMatchesTab(LeagueDetailParams params) {
    final feedAsync = ref.watch(feedNotifierProvider);
    return feedAsync.when(
      data: (events) {
        final leagueEvents = events
            .where((e) => _matchesLeagueAndSeason(e, params))
            .toList();

        if (leagueEvents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 48,
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No hay partidos programados',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: leagueEvents.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: MatchCard(event: leagueEvents[index]),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Error al cargar partidos')),
    );
  }

  Widget _buildStandingsTab(LeagueDetailParams params) {
    final detailAsync = ref.watch(leagueDetailProvider(params));

    return detailAsync.when(
      data: (detail) {
        if (!detail.hasStandingsCoverage ||
            detail.groups.isEmpty ||
            !detail.groups.any((g) => g.entries.isNotEmpty)) {
          return _buildNoCoverageState(
            icon: Icons.table_chart_outlined,
            title: 'Posiciones no disponibles',
            subtitle:
                'El proveedor actual no entrega tabla de posiciones para esta competición o fase.',
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(leagueDetailProvider(params).future),
          color: widget.sport.color,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: detail.groups.length,
            itemBuilder: (context, groupIndex) {
              final group = detail.groups[groupIndex];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (detail.groups.length > 1 || group.name != 'General') ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
                      child: Text(
                        group.name.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorderDark),
                    ),
                    child: Column(
                      children: [
                        _buildStandingsHeader(),
                        ...group.entries.map((entry) => _buildStandingsRow(entry)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: _buildNoCoverageState(
          icon: Icons.error_outline_rounded,
          title: 'Error al consultar posiciones',
          subtitle: 'No se pudieron recuperar las posiciones del proveedor.',
        ),
      ),
    );
  }

  Widget _buildStandingsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorderDark)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '#',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          SizedBox(width: 24),
          Expanded(
            child: Text(
              'EQUIPO',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              'PJ',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              'DIF',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              'PTS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandingsRow(LeagueStandingEntryModel entry) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorderDark)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${entry.position}',
              style: TextStyle(
                color: entry.isPromotion
                    ? widget.sport.color
                    : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          if (entry.teamLogo != null && entry.teamLogo!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                entry.teamLogo!,
                width: 20,
                height: 20,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox(width: 20),
              ),
            ),
            const SizedBox(width: 8),
          ] else ...[
            const SizedBox(width: 28),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.teamName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.note != null && entry.note!.isNotEmpty) ...[
                  Text(
                    entry.note!,
                    style: TextStyle(
                      color: widget.sport.color.withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              '${entry.playedGames}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              entry.goalDifference != null
                  ? (entry.goalDifference! > 0
                      ? '+${entry.goalDifference}'
                      : '${entry.goalDifference}')
                  : '—',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '${entry.points}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab(LeagueDetailParams params) {
    final detailAsync = ref.watch(leagueDetailProvider(params));

    return detailAsync.when(
      data: (detail) {
        if (!detail.hasLeadersCoverage || detail.topScorers.isEmpty) {
          return _buildNoCoverageState(
            icon: Icons.leaderboard_outlined,
            title: 'Goleadores no disponibles',
            subtitle:
                'El proveedor actual no entrega estadísticas individuales de goleadores para esta competición.',
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(leagueDetailProvider(params).future),
          color: widget.sport.color,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'GOLEADORES',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'TOTAL: ${detail.topScorers.length}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorderDark),
                ),
                child: Column(
                  children: detail.topScorers
                      .map((scorer) => _buildScorerRow(scorer))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: _buildNoCoverageState(
          icon: Icons.error_outline_rounded,
          title: 'Error al consultar goleadores',
          subtitle: 'No se pudieron recuperar los goleadores del proveedor.',
        ),
      ),
    );
  }

  Widget _buildScorerRow(LeagueScorerModel scorer) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorderDark)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${scorer.rank}',
              style: TextStyle(
                color: scorer.rank <= 3
                    ? widget.sport.color
                    : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          if (scorer.playerPhoto != null && scorer.playerPhoto!.isNotEmpty) ...[
            ClipOval(
              child: Image.network(
                scorer.playerPhoto!,
                width: 28,
                height: 28,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.surfaceMuted,
                  child: Icon(
                    Icons.person,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ] else ...[
            const CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.surfaceMuted,
              child: Icon(
                Icons.person,
                size: 16,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scorer.playerName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    if (scorer.teamLogo != null &&
                        scorer.teamLogo!.isNotEmpty) ...[
                      Image.network(
                        scorer.teamLogo!,
                        width: 12,
                        height: 12,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox(),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        scorer.teamName,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (scorer.playedGames != null) ...[
                      Text(
                        '${scorer.playedGames} PJ',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: widget.sport.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${scorer.goals} G',
              style: TextStyle(
                color: widget.sport.color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCoverageState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: widget.sport.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 42,
                color: widget.sport.color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
