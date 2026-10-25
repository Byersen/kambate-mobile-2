import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/football_competition_priority.dart';
import '../../../../models/event_model.dart';
import '../../../../models/event_status.dart';
import '../../../../models/sport_type.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../../data/feed_repository.dart';
import '../../providers/connection_provider.dart';
import '../../providers/feed_provider.dart';
import '../widgets/scoreboard_row.dart';
import '../widgets/live_feed_refresh_scope.dart';
import '../widgets/sport_filter_bar.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  bool _followed(EventModel event, Set<String> teams, Set<String> leagues) {
    final leagueCleaned = event.sport == SportType.soccer
        ? cleanFootballLeagueName(event.league).toLowerCase()
        : event.league.toLowerCase();
    final modelName = event.leagueModel?.name.trim().toLowerCase();
    final modelNameCleaned = event.leagueModel != null && event.sport == SportType.soccer
        ? cleanFootballLeagueName(event.leagueModel!.name).toLowerCase()
        : null;

    return event.isFavorite ||
        leagues.contains(event.league.toLowerCase()) ||
        leagues.contains(leagueCleaned) ||
        (modelName != null && leagues.contains(modelName)) ||
        (modelNameCleaned != null && leagues.contains(modelNameCleaned)) ||
        teams.contains(event.homeTeam?.id) ||
        teams.contains(event.awayTeam?.id) ||
        teams.contains(event.fighter1?.id) ||
        teams.contains(event.fighter2?.id) ||
        event.participants.any((participant) => teams.contains(participant.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedFeedDateProvider);
    final sport = ref.watch(selectedSportFilterProvider);
    final status = ref.watch(selectedEventStatusProvider);
    final feed = ref.watch(feedNotifierProvider);
    final source = ref.watch(feedDataSourceProvider);
    final updated = ref.watch(feedLastUpdatedProvider);
    final teams = ref.watch(favoriteTeamIdsProvider);
    final leagues = ref.watch(followedLeaguesProvider);
    final filtered =
        (feed.asData?.value ?? <EventModel>[])
            .where(
              (event) =>
                  AppDateFormatter.isSameDay(event.startTime, date) &&
                  (sport == SportType.all || event.sport == sport) &&
                  (status == null || event.status == status) &&
                  event.status != EventStatus.archived,
            )
            .toList();
    final uniqueFiltered = <EventModel>[];
    final seenFilteredIds = <String>{};
    for (final event in filtered) {
      if (seenFilteredIds.add(event.id)) {
        uniqueFiltered.add(event);
      }
    }
    final events = FootballCompetitionPriority.sortEvents(
      uniqueFiltered,
      isFollowed: (event) => _followed(event, teams, leagues),
    );
    Future<void> refresh() =>
        ref.read(feedNotifierProvider.notifier).loadEvents(forceRefresh: true);


    final scaffold = Scaffold(
      appBar: AppBar(
        title: const Text(
          'KAMBATE',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Ajustes y preferencias',
            onPressed: () => context.push('/onboarding'),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: CustomScrollView(
          key: const PageStorageKey('feed-results'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SportFilterBar(
                selectedSport: sport,
                onSportSelected: (value) =>
                    ref.read(selectedSportFilterProvider.notifier).state =
                        value,
              ),
            ),
            SliverToBoxAdapter(
              child: _DateSelector(
                date: date,
                onChanged: (value) =>
                    ref.read(selectedFeedDateProvider.notifier).state = value,
              ),
            ),
            if (!AppDateFormatter.isSameDay(date, DateTime.now()))
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          final now = DateTime.now();
                          ref.read(selectedFeedDateProvider.notifier).state =
                              DateTime(now.year, now.month, now.day);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.today_rounded,
                                size: 13,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Ir a hoy',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    for (final filter in <(String, EventStatus?)>[
                      ('Todos', null),
                      ('En vivo', EventStatus.live),
                      ('Próximos', EventStatus.scheduled),
                      ('Resultados', EventStatus.finished),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter.$1),
                          selected: status == filter.$2,
                          showCheckmark: false,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceMuted,
                          side: BorderSide.none,
                          labelStyle: TextStyle(
                            color: status == filter.$2
                                ? AppColors.onPrimary
                                : AppColors.textPrimary,
                          ),
                          onSelected: (_) =>
                              ref
                                  .read(selectedEventStatusProvider.notifier)
                                  .state = filter
                                  .$2,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            if (feed.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (feed.hasError)
              SliverToBoxAdapter(
                child: _FeedMessage(
                  icon: Icons.cloud_off_rounded,
                  title: 'No pudimos cargar los partidos',
                  message: 'Revisa tu conexión e inténtalo de nuevo.',
                  action: 'Reintentar',
                  onPressed: refresh,
                ),
              )
            else if (events.isEmpty)
              SliverToBoxAdapter(
                child: _FeedMessage(
                  icon: Icons.event_available_outlined,
                  title: 'No hay encuentros para estos filtros',
                  message: status == EventStatus.scheduled &&
                          date.isBefore(
                            DateTime(
                              DateTime.now().year,
                              DateTime.now().month,
                              DateTime.now().day,
                            ),
                          )
                      ? 'No hay partidos programados en fechas pasadas. Consulta los resultados o restablece los filtros.'
                      : 'Prueba otro día o consulta todos los deportes.',
                  action: status != null
                      ? 'Ver todos los estados'
                      : (!AppDateFormatter.isSameDay(date, DateTime.now())
                          ? 'Ir a hoy'
                          : 'Restablecer filtros'),
                  onPressed: () {
                    if (status != null) {
                      ref.read(selectedEventStatusProvider.notifier).state =
                          null;
                    } else if (!AppDateFormatter.isSameDay(
                      date,
                      DateTime.now(),
                    )) {
                      final now = DateTime.now();
                      ref.read(selectedFeedDateProvider.notifier).state =
                          DateTime(now.year, now.month, now.day);
                    } else {
                      ref.read(selectedSportFilterProvider.notifier).state =
                          SportType.soccer;
                      ref.read(selectedEventStatusProvider.notifier).state =
                          null;
                    }
                  },
                ),
              )
            else ...[
              _eventList(
                context,
                events,
                teams,
                leagues,
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
    return LiveFeedRefreshScope(child: scaffold);
  }

  Widget _eventList(
    BuildContext context,
    List<EventModel> events,
    Set<String> teams,
    Set<String> leagues,
  ) {
    final competitionGroups = groupEventsByCompetition(events);
    return SliverList.separated(
      itemCount: competitionGroups.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final group = competitionGroups[index];
        return Container(
          key: ValueKey('competition_block_${group.key}'),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CompetitionHeader(
                  key: ValueKey('competition_header_${group.key}'),
                  group: group,
                ),
                for (
                  var eventIndex = 0;
                  eventIndex < group.events.length;
                  eventIndex++
                ) ...[
                  if (eventIndex > 0)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                  ScoreboardRow(
                    key: ValueKey(group.events[eventIndex].id),
                    event: group.events[eventIndex],
                    followed: _followed(
                      group.events[eventIndex],
                      teams,
                      leagues,
                    ),
                    showHeader: false,
                    onTap: () {
                      final event = group.events[eventIndex];
                      context.push('/detail/${event.id}', extra: event);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static List<CompetitionGroup> groupEventsByCompetition(
    List<EventModel> events,
  ) {
    final seenEventIds = <String>{};
    final uniqueEvents = <EventModel>[];
    for (final event in events) {
      if (seenEventIds.add(event.id)) {
        uniqueEvents.add(event);
      }
    }

    final groupMap = <String, CompetitionGroup>{};
    final orderedKeys = <String>[];

    for (final event in uniqueEvents) {
      final String groupKey;
      String groupName;
      final String? logoUrl;
      final String? country;

      if (event.leagueModel != null &&
          event.leagueModel!.id.trim().isNotEmpty) {
        groupKey = 'league_id:${event.leagueModel!.id.trim()}';
        groupName = event.leagueModel!.name.trim().isNotEmpty
            ? event.leagueModel!.name.trim()
            : event.league;
        logoUrl = event.leagueLogoUrl;
        country = event.leagueModel!.country;
      } else {
        final rawLeague = event.league.trim();
        final cleanedRawLeague = event.sport == SportType.soccer
            ? cleanFootballLeagueName(rawLeague)
            : rawLeague;
        final normalizedLeague = cleanedRawLeague.trim().toLowerCase();
        groupKey = 'no_league_id:${event.sport.name}:$normalizedLeague';
        groupName = cleanedRawLeague.trim().isNotEmpty
            ? cleanedRawLeague.trim()
            : 'Competición';
        logoUrl = event.leagueLogoUrl;
        country = null;
      }

      if (event.sport == SportType.soccer) {
        groupName = cleanFootballLeagueName(groupName);
      }

      if (!groupMap.containsKey(groupKey)) {
        groupMap[groupKey] = CompetitionGroup(
          key: groupKey,
          name: groupName,
          logoUrl: logoUrl,
          country: country,
          roundOrPhase: event.roundOrPhase,
          sport: event.sport,
          events: [event],
        );
        orderedKeys.add(groupKey);
      } else {
        final existingGroup = groupMap[groupKey]!;
        existingGroup.events.add(event);
        if ((existingGroup.logoUrl == null ||
                existingGroup.logoUrl!.isEmpty) &&
            logoUrl != null &&
            logoUrl.isNotEmpty) {
          groupMap[groupKey] = CompetitionGroup(
            key: existingGroup.key,
            name: existingGroup.name,
            logoUrl: logoUrl,
            country: existingGroup.country ?? country,
            roundOrPhase: existingGroup.roundOrPhase ?? event.roundOrPhase,
            sport: existingGroup.sport,
            events: existingGroup.events,
          );
        } else if (existingGroup.roundOrPhase == null &&
            event.roundOrPhase != null) {
          groupMap[groupKey] = CompetitionGroup(
            key: existingGroup.key,
            name: existingGroup.name,
            logoUrl: existingGroup.logoUrl,
            country: existingGroup.country ?? country,
            roundOrPhase: event.roundOrPhase,
            sport: existingGroup.sport,
            events: existingGroup.events,
          );
        }
      }
    }

    final result = <CompetitionGroup>[];
    for (final key in orderedKeys) {
      final group = groupMap[key]!;
      if (group.events.isEmpty) continue;

      group.events.sort((a, b) {
        if (group.sport == SportType.soccer) {
          int statusOrder(EventModel e) {
            if (e.status == EventStatus.finished) return 0;
            if (e.status == EventStatus.live) return 1;
            return 2;
          }
          final orderA = statusOrder(a);
          final orderB = statusOrder(b);
          if (orderA != orderB) return orderA.compareTo(orderB);
        } else {
          final aLive = a.status == EventStatus.live ? 0 : 1;
          final bLive = b.status == EventStatus.live ? 0 : 1;
          if (aLive != bLive) return aLive.compareTo(bLive);
        }
        final cmp = a.startTime.compareTo(b.startTime);
        if (cmp != 0) return cmp;
        return a.id.compareTo(b.id);
      });

      result.add(group);
    }

    // Priorizar la competición Worlds al mostrar League of Legends
    if (result.any((g) => g.sport == SportType.lol)) {
      result.sort((a, b) {
        if (a.sport == SportType.lol && b.sport == SportType.lol) {
          final aIsWorlds = a.name.toLowerCase().contains('worlds') ||
              a.key.toLowerCase().contains('worlds');
          final bIsWorlds = b.name.toLowerCase().contains('worlds') ||
              b.key.toLowerCase().contains('worlds');
          if (aIsWorlds && !bIsWorlds) return -1;
          if (!aIsWorlds && bIsWorlds) return 1;
        }
        return 0;
      });
    }

    return result;
  }

  static String cleanFootballLeagueName(String name) {
    var cleaned = name;
    final regex = RegExp(
      r'\b(english|spanish|german|french|dutch)\b',
      caseSensitive: false,
    );
    cleaned = cleaned.replaceAll(regex, '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    cleaned = cleaned.replaceAll(RegExp(r'^[\s\-–—:]+|[\s\-–—:]+$'), '').trim();
    return cleaned.isNotEmpty ? cleaned : name;
  }
}

class CompetitionGroup {
  final String key;
  final String name;
  final String? logoUrl;
  final String? country;
  final String? roundOrPhase;
  final SportType sport;
  final List<EventModel> events;

  CompetitionGroup({
    required this.key,
    required this.name,
    this.logoUrl,
    this.country,
    this.roundOrPhase,
    required this.sport,
    required this.events,
  });
}

class _CompetitionHeader extends ConsumerWidget {
  const _CompetitionHeader({super.key, required this.group});

  final CompetitionGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasLogo = group.logoUrl != null && group.logoUrl!.trim().isNotEmpty;
    final league = group.events.first.leagueModel;
    final following = ref
        .watch(followedLeaguesProvider)
        .contains(group.name.toLowerCase());
    final query = <String, String>{
      if (league != null && league.id.isNotEmpty) 'leagueId': league.id,
      if (league != null && league.slug.isNotEmpty) 'slug': league.slug,
    };
    final leaguePath = '/league/${Uri.encodeComponent(group.name)}';
    final destination = query.isEmpty
        ? leaguePath
        : '$leaguePath?${Uri(queryParameters: query).query}';

    return ColoredBox(
      color: AppColors.surfaceMuted,
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push(destination, extra: group.sport),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                  child: Row(
                    children: [
                      if (hasLogo)
                        Image.network(
                          group.logoUrl!.trim(),
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Icon(
                            group.sport.icon,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        )
                      else
                        Icon(
                          group.sport.icon,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          group.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            key: ValueKey('follow_league_${group.key}'),
            tooltip: following
                ? 'Dejar de seguir ${group.name}'
                : 'Seguir ${group.name}',
            onPressed: () =>
                ref.read(followedLeaguesProvider.notifier).toggle(group.name),
            icon: Icon(
              following ? Icons.star_rounded : Icons.star_border_rounded,
              color: following ? AppColors.warning : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({required this.date, required this.onChanged});
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 36),
            tooltip: 'Día anterior',
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: () =>
                onChanged(DateTime(date.year, date.month, date.day - 1)),
          ),
          for (final offset in [-1, 0, 1])
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _day(DateTime(date.year, date.month, date.day + offset)),
              ),
            ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 36),
            tooltip: 'Día siguiente',
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: () =>
                onChanged(DateTime(date.year, date.month, date.day + 1)),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 36),
            tooltip: 'Elegir fecha',
            icon: const Icon(Icons.calendar_month_outlined, size: 18),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2024, 1, 1),
                lastDate: DateTime(2030, 12, 31),
                helpText: 'SELECCIONAR FECHA',
                cancelText: 'CANCELAR',
                confirmText: 'SELECCIONAR',
              );
              if (picked != null) {
                onChanged(DateTime(picked.year, picked.month, picked.day));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _day(DateTime value) {
    final selected = AppDateFormatter.isSameDay(date, value);
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        visualDensity: VisualDensity.compact,
        foregroundColor: selected ? AppColors.onPrimary : AppColors.textPrimary,
        backgroundColor: selected ? AppColors.primary : AppColors.surfaceMuted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () => onChanged(value),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppDateFormatter.getRelativeDayName(value),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppDateFormatter.formatShortDayMonth(value),
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.icon,
    required this.count,
    this.live = false,
    this.onSeeAll,
  });
  final String label;
  final IconData icon;
  final int count;
  final bool live;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: live ? AppColors.liveRed : AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label ($count)',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          if (onSeeAll != null)
            InkWell(
              onTap: onSeeAll,
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver todos',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
    required this.onPressed,
  });
  final IconData icon;
  final String title;
  final String message;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onPressed, child: Text(action)),
        ],
      ),
    );
  }
}
