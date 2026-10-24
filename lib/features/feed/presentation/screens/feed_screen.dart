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
import '../widgets/sport_filter_bar.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  bool _followed(EventModel event, Set<String> teams, Set<String> leagues) {
    return event.isFavorite ||
        leagues.contains(event.league.toLowerCase()) ||
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
    final groups = [
      (label: 'En vivo', icon: Icons.sensors_rounded, state: EventStatus.live),
      (
        label: 'Próximos',
        icon: Icons.calendar_today_outlined,
        state: EventStatus.scheduled,
      ),
      (
        label: 'Resultados',
        icon: Icons.flag_outlined,
        state: EventStatus.finished,
      ),
      (
        label: 'Aplazados',
        icon: Icons.pause_circle_outline,
        state: EventStatus.postponed,
      ),
      (
        label: 'Cancelados',
        icon: Icons.cancel_outlined,
        state: EventStatus.canceled,
      ),
    ];

    return Scaffold(
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
                      ('Aplazados', EventStatus.postponed),
                      ('Cancelados', EventStatus.canceled),
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
            if ((source == FeedDataSource.cache ||
                    ref.watch(connectionStatusProvider) ==
                        ConnectionStatus.offlineCached) &&
                !feed.isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_off_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            updated == null
                                ? 'Mostrando datos guardados. Desliza para actualizar.'
                                : 'Datos guardados · ${AppDateFormatter.formatEventTime(updated)}. Desliza para actualizar.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
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
            else
              for (final group in groups)
                if (events.any((event) => event.status == group.state)) ...[
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      label: group.label,
                      icon: group.icon,
                      count: events
                          .where((event) => event.status == group.state)
                          .length,
                      live: group.state == EventStatus.live,
                      onSeeAll: () {
                        ref.read(selectedEventStatusProvider.notifier).state =
                            group.state;
                      },
                    ),
                  ),
                  _eventList(
                    context,
                    events
                        .where((event) => event.status == group.state)
                        .toList(),
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
  }

  Widget _eventList(
    BuildContext context,
    List<EventModel> events,
    Set<String> teams,
    Set<String> leagues,
  ) {
    final competitionGroups = groupEventsByCompetition(events);
    final items = <_FeedListItem>[];
    for (final compGroup in competitionGroups) {
      items.add(_CompetitionHeaderItem(compGroup));
      for (final event in compGroup.events) {
        items.add(_EventItem(event));
      }
    }

    return SliverList.separated(
      itemCount: items.length,
      separatorBuilder: (_, index) {
        final current = items[index];
        final next = index + 1 < items.length ? items[index + 1] : null;

        if (next is _CompetitionHeaderItem) {
          return const SizedBox(height: 8);
        }
        if (current is _EventItem && next is _EventItem) {
          return const Divider(height: 1, indent: 16, endIndent: 16);
        }
        return const SizedBox.shrink();
      },
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is _CompetitionHeaderItem) {
          return _CompetitionHeader(
            key: ValueKey('competition_header_${item.group.key}'),
            group: item.group,
          );
        } else if (item is _EventItem) {
          final event = item.event;
          return ScoreboardRow(
            key: ValueKey(event.id),
            event: event,
            followed: _followed(event, teams, leagues),
            onTap: () => context.push('/detail/${event.id}', extra: event),
          );
        }
        return const SizedBox.shrink();
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
      final String groupName;
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
        final normalizedLeague = event.league.trim().toLowerCase();
        groupKey = 'no_league_id:${event.sport.name}:$normalizedLeague';
        groupName = event.league.trim().isNotEmpty
            ? event.league.trim()
            : 'Competición';
        logoUrl = event.leagueLogoUrl;
        country = null;
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
        final cmp = a.startTime.compareTo(b.startTime);
        if (cmp != 0) return cmp;
        return a.id.compareTo(b.id);
      });

      result.add(group);
    }

    return result;
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

sealed class _FeedListItem {}

class _CompetitionHeaderItem extends _FeedListItem {
  final CompetitionGroup group;
  _CompetitionHeaderItem(this.group);
}

class _EventItem extends _FeedListItem {
  final EventModel event;
  _EventItem(this.event);
}

class _CompetitionHeader extends StatelessWidget {
  const _CompetitionHeader({super.key, required this.group});

  final CompetitionGroup group;

  @override
  Widget build(BuildContext context) {
    final hasLogo =
        group.logoUrl != null && group.logoUrl!.trim().isNotEmpty;
    final hasRoundOrPhase =
        group.roundOrPhase != null && group.roundOrPhase!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          if (hasLogo) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                group.logoUrl!.trim(),
                width: 18,
                height: 18,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  group.sport.icon,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ] else ...[
            Icon(
              group.sport.icon,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    group.name,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (group.country != null &&
                    group.country!.trim().isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    '• ${group.country!.trim()}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hasRoundOrPhase) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.7),
                  width: 0.8,
                ),
              ),
              child: Text(
                group.roundOrPhase!.trim(),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
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
