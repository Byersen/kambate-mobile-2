import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
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
    final events =
        (feed.asData?.value ?? <EventModel>[])
            .where(
              (event) =>
                  AppDateFormatter.isSameDay(event.startTime, date) &&
                  (sport == SportType.all || event.sport == sport) &&
                  (status == null || event.status == status) &&
                  event.status != EventStatus.archived,
            )
            .toList()
          ..sort((a, b) {
            final priority = (_followed(b, teams, leagues) ? 1 : 0).compareTo(
              _followed(a, teams, leagues) ? 1 : 0,
            );
            return priority != 0
                ? priority
                : a.startTime.compareTo(b.startTime);
          });
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppDateFormatter.getRelativeDayName(date),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        const Text(
                          'Tu jornada deportiva',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          AppDateFormatter.formatDate(date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
                  message: 'Prueba otro día o consulta todos los deportes.',
                  action: 'Restablecer filtros',
                  onPressed: () {
                    ref.read(selectedSportFilterProvider.notifier).state =
                        SportType.all;
                    ref.read(selectedEventStatusProvider.notifier).state = null;
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
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
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
    return SliverList.separated(
      itemCount: events.length,
      separatorBuilder: (_, index) =>
          const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final event = events[index];
        return ScoreboardRow(
          key: ValueKey(event.id),
          event: event,
          followed: _followed(event, teams, leagues),
          onTap: () => context.push('/detail/${event.id}', extra: event),
        );
      },
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({required this.date, required this.onChanged});
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Día anterior',
            icon: const Icon(Icons.chevron_left),
            onPressed: () =>
                onChanged(DateTime(date.year, date.month, date.day - 1)),
          ),
          for (final offset in [-1, 0, 1])
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _day(DateTime(now.year, now.month, now.day + offset)),
              ),
            ),
          IconButton(
            tooltip: 'Día siguiente',
            icon: const Icon(Icons.chevron_right),
            onPressed: () =>
                onChanged(DateTime(date.year, date.month, date.day + 1)),
          ),
        ],
      ),
    );
  }

  Widget _day(DateTime value) {
    final selected = AppDateFormatter.isSameDay(date, value);
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 12),
        foregroundColor: selected ? AppColors.onPrimary : AppColors.textPrimary,
        backgroundColor: selected ? AppColors.primary : AppColors.surfaceMuted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () => onChanged(value),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppDateFormatter.getRelativeDayName(value),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 3),
          Text(
            AppDateFormatter.formatShortDayMonth(value),
            style: const TextStyle(fontSize: 10),
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
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: live ? AppColors.liveRed : AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label ($count)',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
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
