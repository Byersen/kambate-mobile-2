import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/match_round_formatter.dart';
import '../../../../models/event_model.dart';
import '../../../../models/event_status.dart';
import '../../../../models/league_detail_model.dart';
import '../../../../models/sport_type.dart';
import '../../../feed/presentation/widgets/match_card.dart';
import '../../../feed/providers/feed_provider.dart';
import '../../data/league_detail_repository.dart';
import '../../providers/league_detail_provider.dart';
import '../../providers/lol_worlds_provider.dart';
import '../../providers/ufc_rankings_provider.dart';
import '../widgets/lol_worlds_swiss_view.dart';
import '../widgets/ufc_rankings_view.dart';
import '../widgets/ufc_upcoming_cards_view.dart';
import '../../../favorites/models/search_league_item.dart';
import '../../../favorites/providers/favorites_provider.dart';

final upcomingUfcCardsProvider = FutureProvider<List<EventModel>>((ref) =>
    ref.read(feedRepositoryProvider).fetchUpcomingUfcCards());

class LeagueDetailScreen extends ConsumerStatefulWidget {
  final String leagueName;
  final SportType sport;
  final String? leagueSlug;
  final String? leagueId;
  final String? seasonId;
  final int? initialTabIndex;

  const LeagueDetailScreen({
    super.key,
    required this.leagueName,
    this.sport = SportType.soccer,
    this.leagueSlug,
    this.leagueId,
    this.seasonId,
    this.initialTabIndex,
  });

  @override
  ConsumerState<LeagueDetailScreen> createState() => _LeagueDetailScreenState();
}

class _ParticipatingTeamInfo {
  final String id;
  final String name;
  final String? logoUrl;
  final int? position;
  final int? points;
  final int? playedGames;

  const _ParticipatingTeamInfo({
    required this.id,
    required this.name,
    this.logoUrl,
    this.position,
    this.points,
    this.playedGames,
  });
}

class _LeagueDetailScreenState extends ConsumerState<LeagueDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _selectedMatchdayNumber;

  bool get _isSoccer => widget.sport == SportType.soccer;

  bool get _isUcl {
    final lower = widget.leagueName.toLowerCase();
    final slug = (widget.leagueSlug ?? '').toLowerCase();
    return widget.sport == SportType.soccer &&
        (lower.contains('champions') ||
            slug.contains('champions') ||
            slug == 'ucl' ||
            slug == 'uefa.champions');
  }

  int? _extractMatchdayNumber(String? round) {
    if (round == null) return null;
    final match = RegExp(r'(\d+)').firstMatch(round);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  String _resolveActiveRoundDisplay(List<EventModel> events) {
    final active = _resolveActiveRound(events);
    if (active != null && active.trim().isNotEmpty) {
      final formatted = MatchRoundFormatter.format(active);
      if (formatted != null && formatted.isNotEmpty) return formatted;
      return active.trim();
    }
    if (_isUcl) {
      return 'Fecha 5';
    }
    return '';
  }

  List<LeagueStandingEntryModel> _sortGroupEntries(
      List<LeagueStandingEntryModel> entries) {
    final sorted = List<LeagueStandingEntryModel>.from(entries);
    sorted.sort((a, b) {
      if (a.position != b.position && a.position > 0 && b.position > 0) {
        return a.position.compareTo(b.position);
      }
      if (a.points != b.points) {
        return b.points.compareTo(a.points);
      }
      final gdA = a.goalDifference ?? 0;
      final gdB = b.goalDifference ?? 0;
      if (gdA != gdB) {
        return gdB.compareTo(gdA);
      }
      final gfA = a.goalsFor ?? 0;
      final gfB = b.goalsFor ?? 0;
      return gfB.compareTo(gfA);
    });
    return sorted;
  }

  String _resolveFormattedDateForEvents(
    List<EventModel> events, [
    DateTime? fallbackDate,
  ]) {
    if (events.isEmpty) {
      if (fallbackDate != null) {
        final rel = AppDateFormatter.getRelativeDayName(fallbackDate);
        final formatted = AppDateFormatter.formatDate(fallbackDate);
        if (rel == 'Hoy' || rel == 'Mañana' || rel == 'Ayer') {
          return '$rel · $formatted';
        }
        return formatted;
      }
      return '';
    }

    final dates = <DateTime>{};
    for (final e in events) {
      final local = e.startTime.toLocal();
      dates.add(DateTime(local.year, local.month, local.day));
    }
    final sortedDates = dates.toList()..sort();

    if (sortedDates.length == 1) {
      final d = sortedDates.first;
      final rel = AppDateFormatter.getRelativeDayName(d);
      final formatted = AppDateFormatter.formatDate(d);
      if (rel == 'Hoy' || rel == 'Mañana' || rel == 'Ayer') {
        return '$rel · $formatted';
      }
      return formatted;
    } else if (sortedDates.length > 1) {
      final first = sortedDates.first;
      final last = sortedDates.last;
      return '${AppDateFormatter.formatShortDayMonth(first)} – ${AppDateFormatter.formatShortDayMonth(last)}';
    }
    return '';
  }

  String get _displayLeagueTitle {
    final name = widget.leagueName.trim();
    final lower = name.toLowerCase();
    if (lower == 'champions league' ||
        lower == 'uefa champions league' ||
        lower == 'uefa.champions' ||
        lower == 'ucl') {
      return 'UEFA Champions League';
    }
    return name;
  }

  String get _displayLeagueSubtitle {
    final lower = widget.leagueName.toLowerCase();
    final slug = (widget.leagueSlug ?? '').toLowerCase();
    if (lower.contains('champions') || slug.contains('champions')) {
      return 'Internacional Clubes';
    }
    if (lower.contains('libertadores') || lower.contains('sudamericana')) {
      return 'Internacional Clubes';
    }
    if (lower.contains('europa league') || lower.contains('conference')) {
      return 'Internacional Clubes';
    }
    if (widget.sport == SportType.soccer) {
      for (final cl in kCanonicalLeagues) {
        if (cl.slug != null && cl.slug!.toLowerCase() == slug) {
          return cl.region;
        }
        if (cl.name.toLowerCase() == lower) {
          return cl.region;
        }
      }
      return 'Fútbol';
    }
    return widget.sport.displayName;
  }

  @override
  void initState() {
    super.initState();
    final tabCount = _isSoccer ? 4 : 3;
    final initial = widget.initialTabIndex ?? 0;
    _tabController = TabController(
      length: tabCount,
      vsync: this,
      initialIndex: (initial >= 0 && initial < tabCount) ? initial : 0,
    );
  }

  @override
  void didUpdateWidget(LeagueDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sport != widget.sport) {
      final tabCount = _isSoccer ? 4 : 3;
      final oldIndex = _tabController.index;
      _tabController.dispose();
      _tabController = TabController(
        length: tabCount,
        vsync: this,
        initialIndex: oldIndex < tabCount ? oldIndex : 0,
      );
    }
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

    final lowerName = widget.leagueName.toLowerCase();
    final isUcl = (lowerName == 'champions league' ||
            lowerName == 'uefa champions league' ||
            lowerName == 'ucl' ||
            lowerName == 'uefa.champions' ||
            (lowerName.contains('champions') &&
                !lowerName.contains('valorant') &&
                !lowerName.contains('vct') &&
                !lowerName.contains('lol') &&
                !lowerName.contains('worlds') &&
                !lowerName.contains('championship'))) &&
        widget.sport == SportType.soccer;

    if (isUcl) {
      resolvedSlug = 'uefa.champions';
    }

    if (resolvedSlug == null || resolvedLeagueId == null || resolvedSeasonId == null) {
      final matching = events.where((e) {
        if (widget.sport != SportType.all && e.sport != widget.sport) {
          return false;
        }
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

  String? _resolveLeagueLogo(
    LeagueDetailParams params,
    List<EventModel> events,
  ) {
    final targetSlug = (params.leagueSlug ?? '').toLowerCase();
    final targetName = widget.leagueName.toLowerCase();

    for (final cl in kCanonicalLeagues) {
      if (cl.slug != null && cl.slug!.toLowerCase() == targetSlug) {
        return cl.logoUrl;
      }
      final cName = cl.name.toLowerCase();
      if (cName == targetName ||
          targetName.contains(cName) ||
          cName.contains(targetName)) {
        return cl.logoUrl;
      }
    }

    for (final e in events) {
      if (_matchesLeagueAndSeason(e, params)) {
        if (e.leagueModel?.logoUrl != null &&
            e.leagueModel!.logoUrl!.isNotEmpty) {
          return e.leagueModel!.logoUrl;
        }
      }
    }

    return null;
  }

  List<_ParticipatingTeamInfo> _resolveParticipatingTeams({
    required LeagueDetailParams params,
    required List<EventModel> leagueEvents,
    LeagueDetailModel? detail,
  }) {
    final Map<String, _ParticipatingTeamInfo> teams = {};

    if (detail != null && detail.groups.isNotEmpty) {
      for (final group in detail.groups) {
        for (final entry in group.entries) {
          final normName = entry.teamName.trim().toLowerCase();
          if (normName.isEmpty) continue;
          teams[normName] = _ParticipatingTeamInfo(
            id: entry.teamId ?? entry.participantId ?? normName,
            name: entry.teamName.trim(),
            logoUrl: entry.teamLogo,
            position: entry.position,
            points: entry.points,
            playedGames: entry.playedGames,
          );
        }
      }
    }

    for (final event in leagueEvents) {
      void addParticipant(String? name, String? logo, String? id) {
        if (name == null || name.trim().isEmpty) return;
        final norm = name.trim().toLowerCase();
        if (teams.containsKey(norm)) {
          final existing = teams[norm]!;
          if ((existing.logoUrl == null || existing.logoUrl!.isEmpty) &&
              logo != null &&
              logo.isNotEmpty) {
            teams[norm] = _ParticipatingTeamInfo(
              id: existing.id,
              name: existing.name,
              logoUrl: logo,
              position: existing.position,
              points: existing.points,
              playedGames: existing.playedGames,
            );
          }
        } else {
          teams[norm] = _ParticipatingTeamInfo(
            id: id ?? norm,
            name: name.trim(),
            logoUrl: logo,
          );
        }
      }

      addParticipant(
        event.homeTeam?.name,
        event.homeTeam?.logoUrl,
        event.homeTeam?.id,
      );
      addParticipant(
        event.awayTeam?.name,
        event.awayTeam?.logoUrl,
        event.awayTeam?.id,
      );
      for (final p in event.participants) {
        addParticipant(p.name, p.logoUrl, p.id);
      }
    }

    final list = teams.values.toList();
    list.sort((a, b) {
      if (a.position != null && b.position != null) {
        return a.position!.compareTo(b.position!);
      }
      if (a.position != null) return -1;
      if (b.position != null) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  void _showParticipatingTeamsModal(
    BuildContext context,
    List<_ParticipatingTeamInfo> teams,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorderDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Equipos participantes',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${teams.length} equipos confirmados • ${widget.leagueName}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.cardBorderDark),
                Expanded(
                  child: teams.isEmpty
                      ? const Center(
                          child: Text(
                            'No se registran equipos participantes aún.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : GridView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.2,
                          ),
                          itemCount: teams.length,
                          itemBuilder: (context, idx) {
                            final team = teams[idx];
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundDark,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.cardBorderDark),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: team.logoUrl != null && team.logoUrl!.isNotEmpty
                                        ? Image.network(
                                            team.logoUrl!,
                                            width: 26,
                                            height: 26,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) => Icon(
                                              widget.sport.icon,
                                              size: 18,
                                              color: widget.sport.color,
                                            ),
                                          )
                                        : Icon(
                                            widget.sport.icon,
                                            size: 18,
                                            color: widget.sport.color,
                                          ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          team.name,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          team.position != null
                                              ? 'Puesto ${team.position} • ${team.points ?? 0} pts'
                                              : (team.points != null
                                                  ? '${team.points} pts'
                                                  : (team.playedGames != null
                                                      ? '${team.playedGames} PJ'
                                                      : widget.sport.displayName)),
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 10,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
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
    final detailAsync = ref.watch(leagueDetailProvider(params));
    final leagueEvents = events
        .where((e) => _matchesLeagueAndSeason(e, params))
        .toList();
    final activeRoundDisplay = _resolveActiveRoundDisplay(leagueEvents);
    final officialLogo = _resolveLeagueLogo(params, events);
    final participatingTeams = _resolveParticipatingTeams(
      params: params,
      leagueEvents: leagueEvents,
      detail: detailAsync.value,
    );

    final isWorlds = widget.sport == SportType.lol &&
        (params.leagueSlug?.contains('worlds') == true ||
            widget.leagueName.toLowerCase().contains('worlds'));

    if (isWorlds) {
      final seasonSlug = RegExp(r'^[0-9a-fA-F]{8}-').hasMatch(params.seasonId ?? '')
          ? null : params.seasonId;
      final worldsAsync = ref.watch(lolWorldsStageProvider(seasonSlug));
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
          title: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.all(2),
                child: Image.network(
                  'https://cdn-api.pandascore.co/images/league/image/297/worlds-png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.sports_esports,
                    size: 18,
                    color: AppColors.lol,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  widget.leagueName.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppColors.textSecondary,
              ),
              onPressed: () =>
                  ref.refresh(lolWorldsStageProvider(seasonSlug)),
            ),
          ],
        ),
        body: worldsAsync.when(
          data: (stageData) => LolWorldsSwissView(
            stageData: stageData,
            onRefresh: () =>
                ref.refresh(lolWorldsStageProvider(seasonSlug)),
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

    final isUfc = widget.sport == SportType.ufc ||
        params.leagueSlug == 'ufc' ||
        widget.leagueName.toLowerCase().contains('ufc');

    if (isUfc) {
      final rankingsAsync = ref.watch(ufcRankingsProvider);
      final cardsAsync = ref.watch(upcomingUfcCardsProvider);
      return DefaultTabController(
        length: 2,
        child: Scaffold(
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
            title: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white24, width: 0.5),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Image.network(
                    'https://a.espncdn.com/i/teamlogos/leagues/500/ufc.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.sports_mma,
                      size: 18,
                      color: AppColors.ufcRed,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.leagueName.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  ref.invalidate(feedNotifierProvider);
                  ref.invalidate(upcomingUfcCardsProvider);
                  ref.invalidate(ufcRankingsProvider);
                },
              ),
            ],
            bottom: const TabBar(
              indicatorColor: AppColors.ufcRed,
              labelColor: AppColors.ufcRed,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: 'Próximas carteleras'),
                Tab(text: 'Rankings'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              cardsAsync.when(
                data: (cards) => UfcUpcomingCardsView(
                  allEvents: cards,
                  onRefresh: () => ref.invalidate(upcomingUfcCardsProvider),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => events.any((e) => e.sport == SportType.ufc)
                  ? UfcUpcomingCardsView(allEvents: events,
                      onRefresh: () => ref.invalidate(upcomingUfcCardsProvider))
                  : Center(child: Text(
                      'No se pudieron cargar las carteleras: $error',
                      style: const TextStyle(color: AppColors.textSecondary),
                    )),
              ),
              rankingsAsync.when(
                data: (rankings) => UfcRankingsView(
                  rankings: rankings,
                  allEvents: events,
                  onRefresh: () async => ref.invalidate(ufcRankingsProvider),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: _buildNoCoverageState(
                    icon: Icons.error_outline_rounded,
                    title: 'Error al conectar con la fuente',
                    subtitle:
                        'No se pudieron recuperar los rankings oficiales de UFC ($e).',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                onPressed: () => context.pop(),
              ),
              title: innerBoxIsScrolled
                  ? Text(
                      _displayLeagueTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
              actions: [
                if (participatingTeams.isNotEmpty)
                  IconButton(
                    icon: const Icon(
                      Icons.shield_outlined,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                    tooltip: 'Equipos participantes (${participatingTeams.length})',
                    onPressed: () => _showParticipatingTeamsModal(
                      context,
                      participatingTeams,
                    ),
                  ),
                Consumer(
                  builder: (context, ref, _) {
                    final followed = ref.watch(followedLeaguesProvider);
                    final isFav = followed.contains(widget.leagueName.toLowerCase()) ||
                        (params.leagueSlug != null && followed.contains(params.leagueSlug!.toLowerCase())) ||
                        followed.contains('uefa.champions') ||
                        followed.contains('champions league');

                    return IconButton(
                      icon: Icon(
                        isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: isFav ? const Color(0xFFFFB800) : AppColors.textPrimary,
                        size: 24,
                      ),
                      tooltip: isFav ? 'Siguiendo competición' : 'Seguir competición',
                      onPressed: () {
                        ref.read(followedLeaguesProvider.notifier).toggle(
                              params.leagueSlug ?? widget.leagueName,
                            );
                      },
                    );
                  },
                ),
                const SizedBox(width: 4),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 48, bottom: 48),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: AppColors.border, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            padding: const EdgeInsets.all(4),
                            child: (officialLogo != null && officialLogo.isNotEmpty)
                                ? Image.network(
                                    officialLogo,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Icon(
                                      widget.sport.icon,
                                      color: AppColors.primary,
                                      size: 26,
                                    ),
                                  )
                                : Icon(
                                    widget.sport.icon,
                                    color: AppColors.primary,
                                    size: 26,
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _displayLeagueTitle,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Text(
                                      _displayLeagueSubtitle,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (activeRoundDisplay.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.25),
                                          ),
                                        ),
                                        child: Text(
                                          activeRoundDisplay,
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(46),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 2.5,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    tabs: _isSoccer
                        ? const [
                            Tab(text: 'Resumen'),
                            Tab(text: 'Partidos'),
                            Tab(text: 'Tabla'),
                            Tab(text: 'Estadísticas'),
                          ]
                        : const [
                            Tab(text: 'Partidos'),
                            Tab(text: 'Tabla'),
                            Tab(text: 'Estadísticas'),
                          ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: _isSoccer
              ? [
                  _buildSummaryTab(params, participatingTeams),
                  _buildMatchesTab(params),
                  _buildStandingsTab(params),
                  _buildStatsTab(params),
                ]
              : [
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

    // League of Legends
    if (l.contains('worlds') || l.contains('world championship')) {
      return 'Worlds';
    }
    if (l.contains('lck')) return 'LCK';
    if (l.contains('lec')) return 'LEC';
    if (l.contains('lcs')) return 'LCS';
    if (l.contains('lpl')) return 'LPL';
    if (l.contains('msi')) return 'MSI';
    if (l.contains('lol') || l.contains('legends')) return 'LoL';

    // Valorant
    if (l.contains('valorant champions') || (l.contains('champions') && (l.contains('val') || l.contains('vct')))) {
      return 'Valorant Champions';
    }
    if (l.contains('valorant masters') || l.contains('vct masters') || (l.contains('masters') && (l.contains('val') || l.contains('vct')))) {
      return 'Valorant Masters';
    }
    if (l.contains('ascension') && (l.contains('americas') || l.contains('val') || l.contains('vct'))) {
      return 'VCT Ascension Americas';
    }
    if (l.contains('vct americas') || (l.contains('americas') && (l.contains('vct') || l.contains('val')))) {
      return 'VCT Americas';
    }
    if (l.contains('vct emea') || (l.contains('emea') && (l.contains('vct') || l.contains('val')))) {
      return 'VCT EMEA';
    }

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

    if (l.contains('copa chile') || l.contains('copa_chi')) return 'Copa Chile';
    if (l.contains('chi') || l.contains('chile') || l.contains('campeonato itaú')) {
      return 'Primera División';
    }

    if (l.contains('col') || l.contains('colombia')) return 'Primera A';

    if (l.contains('libertadores')) return 'Copa Libertadores';
    if (l.contains('sudamericana')) return 'Copa Sudamericana';
    if (l.contains('recopa')) return 'Recopa Sudamericana';

    if (l == 'uefa champions league' ||
        l == 'champions league' ||
        l == 'uefa.champions' ||
        l == 'ucl' ||
        (l.contains('champions') && !l.contains('championship'))) {
      return 'Champions League';
    }
    if (l.contains('europa league') || (l.contains('europa') && !l.contains('eurocopa'))) {
      return 'Europa League';
    }
    if (l.contains('conference')) return 'Conference League';
    if (l.contains('supercopa de europa') || l.contains('uefa.super_cup') || l.contains('uefa super cup')) {
      return 'Supercopa de Europa';
    }

    if (l.contains('carabao') || l.contains('league_cup') || l.contains('league cup') || l.contains('efl cup')) {
      return 'Carabao Cup';
    }
    if (l.contains('community shield') || l.contains('charity')) {
      return 'Community Shield';
    }
    if (l.contains('fa cup') || l == 'eng.fa') {
      return 'FA Cup';
    }
    if (l.contains('copa del rey') || l.contains('copa_del_rey')) {
      return 'Copa del Rey';
    }

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
    // 0. Aislamiento absoluto por deporte: Si la pantalla tiene un deporte específico,
    // NUNCA aceptar eventos de otro deporte (evita LoL/Valorant/NBA en Champions League).
    if (widget.sport != SportType.all && e.sport != widget.sport) {
      return false;
    }

    // Regla especial para UEFA Champions League (Fútbol)
    final isUcl = (params.leagueSlug?.toLowerCase() == 'uefa.champions' ||
            params.leagueSlug?.toLowerCase() == 'ucl' ||
            widget.leagueName.toLowerCase().contains('champions')) &&
        widget.sport == SportType.soccer;

    if (isUcl) {
      if (e.sport != SportType.soccer) return false;
      final eSlug = e.leagueModel?.slug.toLowerCase() ?? '';
      final eName = e.league.toLowerCase();
      final isUclEvent = eSlug == 'ucl' ||
          eSlug == 'uefa.champions' ||
          eName.contains('champions league') ||
          eName.contains('uefa champions');
      if (!isUclEvent) return false;
      return true;
    }

    // Si la pantalla es de Valorant o el evento es de Valorant, aplicar aislamiento estricto
    if (widget.sport == SportType.valorant || e.sport == SportType.valorant) {
      if (e.sport != widget.sport) return false;

      final targetSlug = params.leagueSlug?.toLowerCase() ?? '';
      final targetName = widget.leagueName.toLowerCase();
      final eventSlug = e.leagueModel?.slug.toLowerCase() ?? '';
      final eventLeague = _getPrettyLeagueName(e.league).toLowerCase();

      if (targetSlug == 'valorant-champions' || targetName.contains('champions')) {
        return eventSlug == 'valorant-champions' || eventLeague == 'valorant champions';
      }
      if (targetSlug == 'valorant-masters' || targetName.contains('masters')) {
        return eventSlug == 'valorant-masters' || eventLeague == 'valorant masters';
      }
      if (targetSlug == 'vct-ascension-americas' || targetName.contains('ascension')) {
        return eventSlug == 'vct-ascension-americas' || eventLeague == 'vct ascension americas';
      }
      if (targetSlug == 'vct-americas' || (targetName.contains('americas') && !targetName.contains('ascension'))) {
        return eventSlug == 'vct-americas' || (eventLeague == 'vct americas' && !eventLeague.contains('ascension'));
      }
      if (targetSlug == 'vct-emea' || targetName.contains('emea')) {
        return eventSlug == 'vct-emea' || eventLeague == 'vct emea';
      }
      return false;
    }

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

  String? _resolveActiveRound(List<EventModel> events) {
    if (events.isEmpty) return null;

    // 1. Si hay partido en vivo con round/fase, usar esa ronda
    for (final e in events) {
      if (e.isLive && e.roundOrPhase != null && e.roundOrPhase!.trim().isNotEmpty) {
        return e.roundOrPhase!.trim();
      }
    }

    // 2. Si hay partidos programados con round/fase
    for (final e in events) {
      if (e.status == EventStatus.scheduled &&
          e.roundOrPhase != null &&
          e.roundOrPhase!.trim().isNotEmpty) {
        return e.roundOrPhase!.trim();
      }
    }

    // 3. Si hay partidos finalizados con round/fase (el más reciente)
    final finished = events
        .where(
          (e) =>
              e.status == EventStatus.finished &&
              e.roundOrPhase != null &&
              e.roundOrPhase!.trim().isNotEmpty,
        )
        .toList();
    if (finished.isNotEmpty) {
      return finished.last.roundOrPhase!.trim();
    }

    // 4. Si cualquier partido tiene roundOrPhase
    for (final e in events) {
      if (e.roundOrPhase != null && e.roundOrPhase!.trim().isNotEmpty) {
        return e.roundOrPhase!.trim();
      }
    }

    return null;
  }

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildFechaHeaderCard({
    required String fechaTitle,
    String? phaseSubtitle,
    required String dateSubtitle,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: widget.sport.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                size: 15,
                color: widget.sport.color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        fechaTitle.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                      if (phaseSubtitle != null && phaseSubtitle.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          '· $phaseSubtitle',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (dateSubtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      dateSubtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildViewFullTableButton() {
    return InkWell(
      key: const ValueKey('btn_ver_tabla_completa'),
      onTap: () {
        // En fútbol, la pestaña Tabla completa es el índice 2
        _tabController.animateTo(2);
      },
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.cardBorderDark),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Ver tabla completa',
              style: TextStyle(
                color: widget.sport.color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: widget.sport.color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTab(
    LeagueDetailParams params,
    List<_ParticipatingTeamInfo> participatingTeams,
  ) {
    final feedAsync = ref.watch(feedNotifierProvider);
    final detailAsync = ref.watch(leagueDetailProvider(params));
    final selectedFeedDate = ref.watch(selectedFeedDateProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(feedNotifierProvider);
        ref.invalidate(leagueDetailProvider(params));
      },
      color: widget.sport.color,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // 1. PARTIDOS DE LA JORNADA / FECHA INDICADA POR LA FUENTE
          ...feedAsync.when(
            data: (events) {
              final leagueEvents = events
                  .where((e) => _matchesLeagueAndSeason(e, params))
                  .toList();

              if (leagueEvents.isEmpty) {
                return [
                  _buildSectionHeader('PARTIDOS'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorderDark),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.event_busy_rounded,
                            color: AppColors.textMuted,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Sin partidos disponibles',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ];
              }

              final activeRound = _resolveActiveRound(leagueEvents);
              List<EventModel> roundMatches;
              final String fechaTitle;

              if (activeRound != null) {
                final filtered = leagueEvents
                    .where((e) => e.roundOrPhase == activeRound)
                    .toList();
                roundMatches = filtered.isNotEmpty ? filtered : leagueEvents;
                fechaTitle =
                    MatchRoundFormatter.format(activeRound) ?? activeRound;
              } else if (_isUcl) {
                roundMatches = leagueEvents;
                fechaTitle = 'Fecha 5';
              } else {
                roundMatches = leagueEvents;
                fechaTitle = 'Partidos';
              }

              if (widget.sport == SportType.soccer ||
                  widget.sport == SportType.lol ||
                  widget.sport == SportType.nba) {
                roundMatches = List<EventModel>.from(roundMatches)
                  ..sort((a, b) {
                    int statusOrder(EventModel e) {
                      if (e.status == EventStatus.live) return 0;
                      if (e.status == EventStatus.finished) return 1;
                      return 2;
                    }
                    final orderA = statusOrder(a);
                    final orderB = statusOrder(b);
                    if (orderA != orderB) return orderA.compareTo(orderB);
                    final cmp = a.startTime.compareTo(b.startTime);
                    if (cmp != 0) return cmp;
                    return a.id.compareTo(b.id);
                  });
              }

              final dateSubtitle = _resolveFormattedDateForEvents(
                roundMatches,
                selectedFeedDate,
              );
              final phaseSubtitle = _isUcl ? 'Fase de Liga' : null;

              final trailingWidget = leagueEvents.length > roundMatches.length
                  ? GestureDetector(
                      onTap: () => _tabController.animateTo(1),
                      child: Text(
                        'VER TODOS (${leagueEvents.length})',
                        style: TextStyle(
                          color: widget.sport.color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null;

              final headerWidget = _isUcl
                  ? _buildFechaHeaderCard(
                      fechaTitle: fechaTitle,
                      phaseSubtitle: phaseSubtitle,
                      dateSubtitle: dateSubtitle,
                      trailing: trailingWidget,
                    )
                  : _buildSectionHeader(
                      activeRound != null
                          ? activeRound.toUpperCase()
                          : 'PARTIDOS',
                      trailing: trailingWidget,
                    );

              return [
                headerWidget,
                ...roundMatches.map(
                  (match) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4.0),
                    child: MatchCard(
                      event: match,
                      isCompact: true,
                      onTap: () => context.push('/detail/${match.id}', extra: match),
                    ),
                  ),
                ),
              ];
            },
            loading: () => [
              _buildSectionHeader('PARTIDOS'),
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (e, _) => [
              _buildSectionHeader('PARTIDOS'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorderDark),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.textMuted,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Error al cargar partidos de la jornada',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 2. PRIMEROS CINCO PUESTOS DE LA TABLA Y 3. BOTÓN VER TABLA COMPLETA
          ...detailAsync.when(
            data: (detail) {
              if (!detail.hasStandingsCoverage ||
                  detail.groups.isEmpty ||
                  !detail.groups.any((g) => g.entries.isNotEmpty)) {
                return [
                  _buildSectionHeader('TABLA DE POSICIONES'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorderDark),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.table_chart_outlined,
                            color: AppColors.textMuted,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Posiciones no disponibles',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ];
              }

              final widgets = <Widget>[
                _buildSectionHeader('TABLA DE POSICIONES'),
              ];

              for (final group in detail.groups) {
                if (detail.groups.length > 1 || group.name != 'General') {
                  widgets.add(
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                  );
                }

                final sortedEntries = _sortGroupEntries(group.entries);
                final topEntries = sortedEntries.take(5).toList();

                widgets.add(
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorderDark),
                    ),
                    child: Column(
                      children: [
                        _buildStandingsHeader(),
                        ...topEntries.map((entry) => _buildStandingsRow(entry)),
                        _buildViewFullTableButton(),
                      ],
                    ),
                  ),
                );
              }

              return widgets;
            },
            loading: () => [
              _buildSectionHeader('TABLA DE POSICIONES'),
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (e, _) => [
              _buildSectionHeader('TABLA DE POSICIONES'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorderDark),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.textMuted,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Error al consultar posiciones',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 4. PRIMEROS CINCO GOLEADORES DEL TORNEO
          ...detailAsync.when(
            data: (detail) {
              if (!detail.hasLeadersCoverage || detail.topScorers.isEmpty) {
                return [
                  _buildSectionHeader('GOLEADORES'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorderDark),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.leaderboard_outlined,
                            color: AppColors.textMuted,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Goleadores no disponibles',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ];
              }

              final topFiveScorers = detail.topScorers.take(5).toList();

              return [
                _buildSectionHeader(
                  'GOLEADORES',
                  trailing: detail.topScorers.length > 5
                      ? GestureDetector(
                          onTap: () => _tabController.animateTo(3),
                          child: Text(
                            'VER TODOS (${detail.topScorers.length})',
                            style: TextStyle(
                              color: widget.sport.color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorderDark),
                  ),
                  child: Column(
                    children: topFiveScorers
                        .map((scorer) => _buildScorerRow(scorer))
                        .toList(),
                  ),
                ),
              ];
            },
            loading: () => [
              _buildSectionHeader('GOLEADORES'),
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (e, _) => [
              _buildSectionHeader('GOLEADORES'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorderDark),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.textMuted,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Error al consultar goleadores',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSoccerMatchesView(
    List<EventModel> leagueEvents,
    DateTime selectedFeedDate,
  ) {
    // 1. Gather all available matchday numbers in the events
    final availableMatchdays = <int>{};
    for (final e in leagueEvents) {
      final num = _extractMatchdayNumber(e.roundOrPhase);
      if (num != null) availableMatchdays.add(num);
    }

    final int totalFechas = _isUcl
        ? 8
        : (availableMatchdays.isNotEmpty
            ? availableMatchdays.reduce((a, b) => a > b ? a : b)
            : 1);

    final defaultMatchday =
        _extractMatchdayNumber(_resolveActiveRound(leagueEvents)) ??
            (_isUcl
                ? 5
                : (availableMatchdays.isNotEmpty
                    ? availableMatchdays.first
                    : 1));

    final currentFecha = _selectedMatchdayNumber ?? defaultMatchday;

    // Filter matches for currentFecha
    final matchesForFecha = leagueEvents.where((e) {
      final num = _extractMatchdayNumber(e.roundOrPhase);
      return num == currentFecha;
    }).toList();

    // Compute date label for currentFecha
    final dateRangeText =
        _resolveFormattedDateForEvents(matchesForFecha, selectedFeedDate);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Navigation bar for Fecha
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    color: currentFecha > 1
                        ? AppColors.primary
                        : AppColors.textMuted.withValues(alpha: 0.3),
                    onPressed: currentFecha > 1
                        ? () => setState(
                            () => _selectedMatchdayNumber = currentFecha - 1)
                        : null,
                  ),
                  Column(
                    children: [
                      Text(
                        _isUcl
                            ? 'FECHA $currentFecha DE $totalFechas'
                            : 'FECHA $currentFecha',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateRangeText.isNotEmpty
                            ? dateRangeText
                            : (_isUcl ? 'Fase de Liga' : 'Temporada regular'),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    color: currentFecha < totalFechas
                        ? AppColors.primary
                        : AppColors.textMuted.withValues(alpha: 0.3),
                    onPressed: currentFecha < totalFechas
                        ? () => setState(
                            () => _selectedMatchdayNumber = currentFecha + 1)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Horizontal pills for selecting Fecha 1..totalFechas
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: List.generate(totalFechas, (index) {
                    final fNum = index + 1;
                    final isSelected = fNum == currentFecha;
                    final hasMatches = availableMatchdays.contains(fNum);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        onTap: () =>
                            setState(() => _selectedMatchdayNumber = fNum),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Fecha $fNum',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (hasMatches
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted),
                              fontSize: 11,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),

        // Matches content
        if (matchesForFecha.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_note_rounded,
                    size: 44,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sin partidos para la Fecha $currentFecha',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Los cruces y horarios de esta jornada se confirmarán próximamente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          ...() {
            final sorted = List<EventModel>.from(matchesForFecha)
              ..sort((a, b) {
                int statusOrder(EventModel e) {
                  if (e.status == EventStatus.live) return 0;
                  if (e.status == EventStatus.finished) return 1;
                  return 2;
                }
                final orderA = statusOrder(a);
                final orderB = statusOrder(b);
                if (orderA != orderB) return orderA.compareTo(orderB);
                return a.startTime.compareTo(b.startTime);
              });

            final Map<String, List<EventModel>> grouped = {};
            for (final m in sorted) {
              final dateKey = AppDateFormatter.formatDate(m.startTime);
              final rel = AppDateFormatter.getRelativeDayName(m.startTime);
              final header = (rel == 'Hoy' || rel == 'Mañana' || rel == 'Ayer')
                  ? '${rel.toUpperCase()} · ${dateKey.toUpperCase()}'
                  : dateKey.toUpperCase();
              grouped.putIfAbsent(header, () => []).add(m);
            }

            final widgets = <Widget>[];
            for (final entry in grouped.entries) {
              widgets.add(
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.key,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );

              for (final match in entry.value) {
                widgets.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: MatchCard(
                      event: match,
                      isCompact: true,
                      onTap: () =>
                          context.push('/detail/${match.id}', extra: match),
                    ),
                  ),
                );
              }
            }
            return widgets;
          }(),
        ],
      ],
    );
  }

  Widget _buildMatchesTab(LeagueDetailParams params) {
    final feedAsync = ref.watch(feedNotifierProvider);
    final selectedFeedDate = ref.watch(selectedFeedDateProvider);
    return feedAsync.when(
      data: (events) {
        final leagueEvents = events
            .where((e) => _matchesLeagueAndSeason(e, params))
            .toList();

        if (leagueEvents.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy_rounded,
                    size: 48,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sin cobertura disponible',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No se registran partidos o ediciones de ${widget.leagueName} en la fuente oficial.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        if (_isUcl) {
          return _buildSoccerMatchesView(leagueEvents, selectedFeedDate);
        }

        final hasEditions = leagueEvents.any(
          (e) => e.seasonModel?.name != null && e.seasonModel!.name.isNotEmpty,
        );

        if (widget.sport == SportType.soccer ||
            widget.sport == SportType.lol ||
            widget.sport == SportType.nba) {
          leagueEvents.sort((a, b) {
            if (hasEditions) {
              final edA = a.seasonModel?.name ?? '';
              final edB = b.seasonModel?.name ?? '';
              final edCmp = edB.compareTo(edA);
              if (edCmp != 0) return edCmp;
            }
            int statusOrder(EventModel e) {
              if (e.status == EventStatus.finished) return 0;
              if (e.status == EventStatus.live) return 1;
              return 2;
            }
            final orderA = statusOrder(a);
            final orderB = statusOrder(b);
            if (orderA != orderB) return orderA.compareTo(orderB);
            final cmp = a.startTime.compareTo(b.startTime);
            if (cmp != 0) return cmp;
            return a.id.compareTo(b.id);
          });
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: leagueEvents.length,
          itemBuilder: (context, index) {
            final event = leagueEvents[index];
            final prevEvent = index > 0 ? leagueEvents[index - 1] : null;
            final editionName = event.seasonModel?.name;
            final showEditionHeader = hasEditions &&
                editionName != null &&
                editionName.isNotEmpty &&
                (prevEvent == null || prevEvent.seasonModel?.name != editionName);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showEditionHeader) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 6.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: widget.sport.color.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        editionName.toUpperCase(),
                        style: TextStyle(
                          color: widget.sport.color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: MatchCard(
                    event: event,
                    isCompact: true,
                    onTap: () => context.push('/detail/${event.id}', extra: event),
                  ),
                ),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Error al cargar partidos')),
    );
  }

  Widget _buildStandingsTab(LeagueDetailParams params) {
    if (widget.sport == SportType.valorant) {
      return _buildNoCoverageState(
        icon: Icons.account_tree_outlined,
        title: 'Formato de series y llaves',
        subtitle:
            'Los torneos de Valorant se estructuran en fases de grupos y llaves de eliminación directa. Consulta el fixture y resultados en la pestaña "Partidos".',
      );
    }

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
                  if (_isUcl || detail.groups.length > 1 || group.name != 'General') ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isUcl ? 'FASE DE LIGA' : group.name.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (_isUcl)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Fecha 5 de 8',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildStandingsHeader(),
                        ..._sortGroupEntries(group.entries)
                            .map((entry) => _buildStandingsRow(entry, params)),
                      ],
                    ),
                  ),
                  _buildStandingsLegend(params),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '#',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'CLUB',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              'PJ',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              'DIF',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              'PTS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandingsRow(LeagueStandingEntryModel entry, [LeagueDetailParams? params]) {
    final lowerName = widget.leagueName.toLowerCase();
    final slug = (params?.leagueSlug ?? widget.leagueSlug ?? '').toLowerCase();
    final isChampions = slug == 'uefa.champions' ||
        slug == 'ucl' ||
        lowerName.contains('champions');

    Color positionColor = AppColors.textSecondary;
    Color? positionBg;
    String? zoneLabel;

    if (isChampions) {
      if (entry.position >= 1 && entry.position <= 8) {
        positionColor = AppColors.success;
        positionBg = AppColors.success.withValues(alpha: 0.12);
        zoneLabel = 'Octavos de final';
      } else if (entry.position >= 9 && entry.position <= 24) {
        positionColor = AppColors.primary;
        positionBg = AppColors.primary.withValues(alpha: 0.12);
        zoneLabel = '16vos de final';
      } else {
        positionColor = AppColors.textMuted;
        positionBg = AppColors.surfaceMuted;
        zoneLabel = 'Eliminado';
      }
    } else {
      final note = entry.note?.toLowerCase() ?? '';
      if (note.contains('round of 16') || entry.position <= 4) {
        positionColor = AppColors.success;
        positionBg = AppColors.success.withValues(alpha: 0.12);
      } else if (note.contains('playoff') || entry.isPromotion) {
        positionColor = AppColors.primary;
        positionBg = AppColors.primary.withValues(alpha: 0.12);
      } else if (note.contains('relegat') || note.contains('eliminated')) {
        positionColor = AppColors.error;
        positionBg = AppColors.error.withValues(alpha: 0.10);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: positionBg ?? Colors.transparent,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              '${entry.position}',
              style: TextStyle(
                color: positionColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (entry.teamLogo != null && entry.teamLogo!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                entry.teamLogo!,
                width: 22,
                height: 22,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox(width: 22),
              ),
            ),
            const SizedBox(width: 10),
          ] else ...[
            const SizedBox(width: 32),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                if (zoneLabel != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    zoneLabel,
                    style: TextStyle(
                      color: positionColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else if (entry.note != null && entry.note!.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    entry.note!,
                    style: TextStyle(
                      color: positionColor,
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

  Widget _buildStandingsLegend(LeagueDetailParams params) {
    final lowerName = widget.leagueName.toLowerCase();
    final slug = (params.leagueSlug ?? '').toLowerCase();
    final isChampions = slug == 'uefa.champions' ||
        slug == 'ucl' ||
        lowerName.contains('champions');

    if (!isChampions) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FASES DE CLASIFICACIÓN',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          _legendItem(
            color: AppColors.success,
            label: 'Puestos 1 – 8',
            desc: 'Clasificación directa a Octavos de Final',
          ),
          const SizedBox(height: 8),
          _legendItem(
            color: AppColors.primary,
            label: 'Puestos 9 – 24',
            desc: 'Fase de Play-offs (16vos de Final)',
          ),
          const SizedBox(height: 8),
          _legendItem(
            color: AppColors.textMuted,
            label: 'Puestos 25 – 36',
            desc: 'Eliminación del torneo',
          ),
        ],
      ),
    );
  }

  Widget _legendItem({
    required Color color,
    required String label,
    required String desc,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            desc,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsTab(LeagueDetailParams params) {
    if (widget.sport == SportType.valorant || widget.sport == SportType.lol) {
      return _buildNoCoverageState(
        icon: Icons.sports_esports_outlined,
        title: 'Estadísticas por partida',
        subtitle: widget.sport == SportType.lol
            ? 'Las estadísticas de jugadores, campeones, KDA y recursos se registran dentro de cada partida de la serie.'
            : 'Las estadísticas de jugadores, agentes, K/D y ACS se registran dentro de cada enfrentamiento y mapa individual.',
      );
    }

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
