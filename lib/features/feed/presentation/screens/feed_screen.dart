import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../models/event_model.dart';
import '../../../../models/event_status.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../../providers/feed_provider.dart';
import '../widgets/date_filter_carousel.dart';

import '../widgets/match_card.dart';
import '../widgets/sync_status_badge.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  bool _isEventFollowed(EventModel event, Set<String> followedTeamIds) {
    if (followedTeamIds.isEmpty) return false;
    if (event.homeTeam != null && followedTeamIds.contains(event.homeTeam!.id)) return true;
    if (event.awayTeam != null && followedTeamIds.contains(event.awayTeam!.id)) return true;
    if (event.fighter1 != null && followedTeamIds.contains(event.fighter1!.id)) return true;
    if (event.fighter2 != null && followedTeamIds.contains(event.fighter2!.id)) return true;
    for (final p in event.participants) {
      if (followedTeamIds.contains(p.id)) return true;
    }
    return false;
  }

  List<EventModel> _sortByFollowed(List<EventModel> list, Set<String> followedIds) {
    final copy = [...list];
    copy.sort((a, b) {
      final aFollowed = _isEventFollowed(a, followedIds);
      final bFollowed = _isEventFollowed(b, followedIds);
      if (aFollowed && !bFollowed) return -1;
      if (!aFollowed && bFollowed) return 1;
      return a.startTime.compareTo(b.startTime);
    });
    return copy;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedFeedDateProvider);
    final followedTeamIds = ref.watch(favoriteTeamIdsProvider);
    final feedAsync = ref.watch(feedNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'KAMBATE',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'LIVE',
              style: TextStyle(
                color: AppColors.liveRed,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          const SyncStatusBadge(),
          const SizedBox(width: 2),
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 20),
            tooltip: 'Mis Deportes',
            onPressed: () => context.push('/onboarding'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Actualizar',
            onPressed: () => ref.read(feedNotifierProvider.notifier).loadEvents(forceRefresh: true),
          ),
        ],
      ),
      body: feedAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Error al cargar eventos: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(feedNotifierProvider.notifier).loadEvents(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (allEvents) {
          final Set<String> daysWithEvents = {};
          for (final e in allEvents) {
            final key =
                '${e.startTime.year}-${e.startTime.month.toString().padLeft(2, '0')}-${e.startTime.day.toString().padLeft(2, '0')}';
            daysWithEvents.add(key);
          }

          final dayEvents = allEvents
              .where((e) => AppDateFormatter.isSameDay(e.startTime, selectedDate))
              .toList();

          final liveEvents = _sortByFollowed(
            dayEvents.where((e) => e.status == EventStatus.live).toList(),
            followedTeamIds,
          );
          final upcomingEvents = _sortByFollowed(
            dayEvents.where((e) => e.status == EventStatus.scheduled).toList(),
            followedTeamIds,
          );
          final finishedEvents = _sortByFollowed(
            dayEvents.where((e) => e.status == EventStatus.finished).toList(),
            followedTeamIds,
          );

          final followedInDayCount = dayEvents
              .where((e) => _isEventFollowed(e, followedTeamIds))
              .length;

          final isToday = AppDateFormatter.getRelativeDayName(selectedDate) == 'Hoy';

          return Column(
            children: [
              DateFilterCarousel(
                selectedDate: selectedDate,
                daysWithEvents: daysWithEvents,
                onDateSelected: (date) {
                  ref.read(selectedFeedDateProvider.notifier).state = date;
                },
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'PARTIDOS • ${AppDateFormatter.formatDate(selectedDate).toUpperCase()}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        if (followedInDayCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$followedInDayCount de tus equipos',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorderDark, width: 0.8),
                      ),
                      child: Text(
                        '${dayEvents.length} encuentros',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 2),

              Expanded(
                child: dayEvents.isEmpty
                    ? Center(
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
                                child: const Icon(
                                  Icons.event_busy_rounded,
                                  size: 40,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'No hay partidos programados para el ${AppDateFormatter.formatCarouselLabel(selectedDate)}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Explora otros días en el carrusel superior o vuelve al día de hoy.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                              if (!isToday) ...[
                                const SizedBox(height: 14),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    final now = DateTime.now();
                                    ref.read(selectedFeedDateProvider.notifier).state =
                                        DateTime(now.year, now.month, now.day);
                                  },
                                  icon: const Icon(Icons.today_rounded, size: 15),
                                  label: const Text('Ir a Hoy'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        backgroundColor: AppColors.surfaceDark,
                        onRefresh: () async {
                          await ref
                              .read(feedNotifierProvider.notifier)
                              .loadEvents(forceRefresh: true);
                        },
                        child: ListView(
                          padding: const EdgeInsets.only(bottom: 24),
                          children: [
                            if (liveEvents.isNotEmpty) ...[
                              _buildSectionHeader(
                                context,
                                title: 'EN VIVO AHORA',
                                icon: Icons.fiber_manual_record,
                                iconColor: AppColors.liveRed,
                                count: liveEvents.length,
                              ),
                              ...liveEvents.map((e) => MatchCard(
                                    event: e,
                                    isFollowed: _isEventFollowed(e, followedTeamIds),
                                    onTap: () => context.push('/detail/${e.id}', extra: e),
                                  )),
                            ],

                            if (upcomingEvents.isNotEmpty) ...[
                              _buildSectionHeader(
                                context,
                                title: 'PRÓXIMOS ENCUENTROS',
                                icon: Icons.calendar_today_rounded,
                                iconColor: AppColors.secondary,
                                count: upcomingEvents.length,
                              ),
                              ...upcomingEvents.map((e) => MatchCard(
                                    event: e,
                                    isFollowed: _isEventFollowed(e, followedTeamIds),
                                    onTap: () => context.push('/detail/${e.id}', extra: e),
                                  )),
                            ],

                            if (finishedEvents.isNotEmpty) ...[
                              _buildSectionHeader(
                                context,
                                title: 'FINALIZADOS',
                                icon: Icons.check_circle_outline_rounded,
                                iconColor: AppColors.textMuted,
                                count: finishedEvents.length,
                              ),
                              ...finishedEvents.map((e) => MatchCard(
                                    event: e,
                                    isFollowed: _isEventFollowed(e, followedTeamIds),
                                    onTap: () => context.push('/detail/${e.id}', extra: e),
                                  )),
                            ],
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required int count,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 5),
      child: Row(
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorderDark, width: 0.8),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
