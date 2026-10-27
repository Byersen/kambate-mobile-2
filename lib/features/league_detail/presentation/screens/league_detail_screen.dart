import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
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

class _LeaguePeriodInfo {
  final String periodText;
  final String statusText;
  final Color statusColor;

  const _LeaguePeriodInfo({
    required this.periodText,
    required this.statusText,
    required this.statusColor,
  });
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

  bool get _isSoccer => widget.sport == SportType.soccer;

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

  static String _monthName(int month) {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  _LeaguePeriodInfo _resolvePeriodInfo(
    LeagueDetailParams params,
    List<EventModel> leagueEvents,
  ) {
    DateTime? startDate;
    DateTime? endDate;

    for (final e in leagueEvents) {
      if (e.seasonModel?.startDate != null) {
        if (startDate == null || e.seasonModel!.startDate!.isBefore(startDate)) {
          startDate = e.seasonModel!.startDate;
        }
      }
      if (e.seasonModel?.endDate != null) {
        if (endDate == null || e.seasonModel!.endDate!.isAfter(endDate)) {
          endDate = e.seasonModel!.endDate;
        }
      }
    }

    if (startDate == null && leagueEvents.isNotEmpty) {
      final sortedMatches = List<EventModel>.from(leagueEvents)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      startDate = sortedMatches.first.startTime;
      endDate = sortedMatches.last.startTime;
    }

    final now = DateTime.now();

    if (startDate != null && endDate != null) {
      final periodText = (startDate.year == endDate.year && startDate.month == endDate.month)
          ? '${startDate.day} – ${endDate.day} ${_monthName(endDate.month)} ${endDate.year}'
          : '${_monthName(startDate.month)} ${startDate.year} – ${_monthName(endDate.month)} ${endDate.year}';

      final String statusText;
      final Color statusColor;
      if (now.isBefore(startDate)) {
        statusText = 'Próximamente';
        statusColor = AppColors.warning;
      } else if (now.isAfter(endDate.add(const Duration(days: 15)))) {
        statusText = 'Finalizada';
        statusColor = AppColors.textMuted;
      } else {
        statusText = 'En curso';
        statusColor = AppColors.success;
      }

      return _LeaguePeriodInfo(
        periodText: periodText,
        statusText: statusText,
        statusColor: statusColor,
      );
    }

    final slug = (params.leagueSlug ?? '').toLowerCase();
    final name = widget.leagueName.toLowerCase();
    final currentYear = now.year;
    final nextYear = currentYear + 1;

    if (slug.contains('nba') || name.contains('nba')) {
      final isFinals = now.month >= 6 && now.month <= 9;
      return _LeaguePeriodInfo(
        periodText: 'Octubre $currentYear – Junio $nextYear',
        statusText: isFinals ? 'Finales / Pretemporada' : 'En curso',
        statusColor: isFinals ? AppColors.warning : AppColors.success,
      );
    }

    if (slug.contains('ufc') || name.contains('ufc')) {
      return _LeaguePeriodInfo(
        periodText: 'Temporada continua $currentYear',
        statusText: 'Activa',
        statusColor: AppColors.success,
      );
    }

    if (slug.contains('worlds') || name.contains('worlds')) {
      final isWorldsMonth = now.month >= 9 && now.month <= 11;
      return _LeaguePeriodInfo(
        periodText: 'Octubre – Noviembre $currentYear',
        statusText: isWorldsMonth ? 'En curso' : 'Próximamente',
        statusColor: isWorldsMonth ? AppColors.success : AppColors.warning,
      );
    }

    if (slug.contains('msi') || name.contains('msi')) {
      return _LeaguePeriodInfo(
        periodText: 'Mayo $currentYear',
        statusText: now.month == 5 ? 'En curso' : 'Temporada anual',
        statusColor: now.month == 5 ? AppColors.success : AppColors.primary,
      );
    }

    if (slug.contains('champions') ||
        slug.contains('masters') ||
        slug.contains('ascension') ||
        slug.contains('vct') ||
        widget.sport == SportType.valorant) {
      if (slug.contains('champions')) {
        return _LeaguePeriodInfo(
          periodText: 'Agosto – Septiembre $currentYear',
          statusText: (now.month >= 8 && now.month <= 9) ? 'En curso' : 'Fase clasificatoria',
          statusColor: (now.month >= 8 && now.month <= 9) ? AppColors.success : AppColors.primary,
        );
      }
      return _LeaguePeriodInfo(
        periodText: 'Febrero – Agosto $currentYear',
        statusText: (now.month >= 2 && now.month <= 8) ? 'En curso' : 'Pretemporada',
        statusColor: (now.month >= 2 && now.month <= 8) ? AppColors.success : AppColors.primary,
      );
    }

    if (slug.contains('libertadores') ||
        slug.contains('sudamericana') ||
        slug.contains('bra.') ||
        slug.contains('arg.') ||
        slug.contains('chi.') ||
        name.contains('libertadores') ||
        name.contains('sudamericana') ||
        name.contains('brasileir') ||
        name.contains('primera división')) {
      return _LeaguePeriodInfo(
        periodText: 'Febrero – Diciembre $currentYear',
        statusText: (now.month >= 2 && now.month <= 12) ? 'En curso' : 'Receso',
        statusColor: (now.month >= 2 && now.month <= 12) ? AppColors.success : AppColors.textMuted,
      );
    }

    if (slug.contains('mex.') || name.contains('liga mx')) {
      final isClausura = now.month >= 1 && now.month <= 5;
      return _LeaguePeriodInfo(
        periodText: isClausura ? 'Clausura: Ene – May $currentYear' : 'Apertura: Jul – Dic $currentYear',
        statusText: 'En curso',
        statusColor: AppColors.success,
      );
    }

    if (slug.contains('usa.') || name.contains('mls')) {
      return _LeaguePeriodInfo(
        periodText: 'Febrero – Diciembre $currentYear',
        statusText: (now.month >= 2 && now.month <= 12) ? 'En curso' : 'Pretemporada',
        statusColor: (now.month >= 2 && now.month <= 12) ? AppColors.success : AppColors.primary,
      );
    }

    final isEuropeanSeason = (now.month >= 8 || now.month <= 5);
    final seasonYears = now.month >= 7 ? '$currentYear–$nextYear' : '${currentYear - 1}–$currentYear';
    return _LeaguePeriodInfo(
      periodText: 'Agosto – Mayo ($seasonYears)',
      statusText: isEuropeanSeason ? 'En curso' : 'Receso de verano',
      statusColor: isEuropeanSeason ? AppColors.success : AppColors.warning,
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

  Widget _buildParticipatingTeamsSection(List<_ParticipatingTeamInfo> teams) {
    if (teams.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('EQUIPOS PARTICIPANTES (${teams.length})'),
        SizedBox(
          height: 104,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            scrollDirection: Axis.horizontal,
            itemCount: teams.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final team = teams[index];
              return Container(
                width: 96,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorderDark),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: team.logoUrl != null && team.logoUrl!.isNotEmpty
                          ? Image.network(
                              team.logoUrl!,
                              width: 30,
                              height: 30,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                widget.sport.icon,
                                size: 20,
                                color: widget.sport.color,
                              ),
                            )
                          : Icon(
                              widget.sport.icon,
                              size: 20,
                              color: widget.sport.color,
                            ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      team.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      team.position != null
                          ? '#${team.position} • ${team.points ?? 0} pts'
                          : (team.points != null
                              ? '${team.points} pts'
                              : (team.playedGames != null
                                  ? '${team.playedGames} PJ'
                                  : widget.sport.displayName)),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
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
    final officialLogo = _resolveLeagueLogo(params, events);
    final periodInfo = _resolvePeriodInfo(params, leagueEvents);
    final participatingTeams = _resolveParticipatingTeams(
      params: params,
      leagueEvents: leagueEvents,
      detail: detailAsync.value,
    );

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

    final isUfc = widget.sport == SportType.ufc ||
        params.leagueSlug == 'ufc' ||
        widget.leagueName.toLowerCase().contains('ufc');

    if (isUfc) {
      final rankingsAsync = ref.watch(ufcRankingsProvider);
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
              UfcUpcomingCardsView(
                allEvents: events,
                onRefresh: () async => ref.invalidate(feedNotifierProvider),
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
      backgroundColor: AppColors.backgroundDark,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppColors.surfaceDark,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => context.pop(),
              ),
              actions: [
                if (participatingTeams.isNotEmpty)
                  IconButton(
                    icon: const Icon(
                      Icons.shield_outlined,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                    tooltip: 'Ver equipos participantes',
                    onPressed: () => _showParticipatingTeamsModal(
                      context,
                      participatingTeams,
                    ),
                  ),
              ],
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
                            widget.sport.color.withValues(alpha: 0.35),
                            AppColors.surfaceDark,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: -20,
                      top: 20,
                      child: Icon(
                        widget.sport.icon,
                        size: 150,
                        color: widget.sport.color.withValues(alpha: 0.08),
                      ),
                    ),
                    Positioned(
                      top: 46,
                      left: 48,
                      right: 16,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: (officialLogo != null && officialLogo.isNotEmpty)
                                  ? Colors.white
                                  : widget.sport.color.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: (officialLogo != null && officialLogo.isNotEmpty)
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            padding: (officialLogo != null && officialLogo.isNotEmpty)
                                ? const EdgeInsets.all(3)
                                : EdgeInsets.zero,
                            alignment: Alignment.center,
                            child: (officialLogo != null && officialLogo.isNotEmpty)
                                ? Image.network(
                                    officialLogo,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Icon(
                                      widget.sport.icon,
                                      size: 24,
                                      color: widget.sport.color,
                                    ),
                                  )
                                : Icon(
                                    widget.sport.icon,
                                    size: 24,
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: periodInfo.statusColor.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: periodInfo.statusColor.withValues(alpha: 0.4),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 5,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              color: periodInfo.statusColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            periodInfo.statusText.toUpperCase(),
                                            style: TextStyle(
                                              color: periodInfo.statusColor,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (participatingTeams.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () => _showParticipatingTeamsModal(
                                          context,
                                          participatingTeams,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.25),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '${participatingTeams.length} equipos',
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 3),
                                              const Icon(
                                                Icons.chevron_right_rounded,
                                                size: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        periodInfo.periodText,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
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
              final String headerTitle;

              if (activeRound != null) {
                final filtered = leagueEvents
                    .where((e) => e.roundOrPhase == activeRound)
                    .toList();
                roundMatches = filtered.isNotEmpty ? filtered : leagueEvents;
                headerTitle = activeRound.toUpperCase();
              } else {
                // Si el proveedor no entrega número/nombre de jornada, omitir esa etiqueta
                // y mostrar los partidos con una agrupación neutral
                roundMatches = leagueEvents;
                headerTitle = 'PARTIDOS';
              }

              if (widget.sport == SportType.soccer || widget.sport == SportType.lol) {
                roundMatches = List<EventModel>.from(roundMatches)
                  ..sort((a, b) {
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

              return [
                _buildSectionHeader(
                  headerTitle,
                  trailing: leagueEvents.length > roundMatches.length
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
                      : null,
                ),
                ...roundMatches.map(
                  (match) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: MatchCard(event: match),
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

                final topEntries = group.entries.take(5).toList();

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

  Widget _buildMatchesTab(LeagueDetailParams params) {
    final feedAsync = ref.watch(feedNotifierProvider);
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

        final hasEditions = leagueEvents.any(
          (e) => e.seasonModel?.name != null && e.seasonModel!.name.isNotEmpty,
        );

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
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: MatchCard(event: event),
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
