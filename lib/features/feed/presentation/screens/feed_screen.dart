import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/event_status.dart';
import '../../providers/feed_provider.dart';
import '../widgets/match_card.dart';
import '../widgets/sport_filter_bar.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSport = ref.watch(selectedSportFilterProvider);
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
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: () => ref.read(feedNotifierProvider.notifier).loadEvents(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar by Discipline
          SportFilterBar(
            selectedSport: selectedSport,
            onSportSelected: (sport) {
              ref.read(selectedSportFilterProvider.notifier).state = sport;
            },
          ),

          const SizedBox(height: 4),

          // Events Feed List
          Expanded(
            child: feedAsync.when(
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
              data: (events) {
                if (events.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(selectedSport.icon, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No hay eventos de ${selectedSport.displayName} por ahora',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }

                final liveEvents = events.where((e) => e.status == EventStatus.live).toList();
                final upcomingEvents = events.where((e) => e.status == EventStatus.scheduled).toList();
                final finishedEvents = events.where((e) => e.status == EventStatus.finished).toList();

                return RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surfaceDark,
                  onRefresh: () async {
                    await ref.read(feedNotifierProvider.notifier).loadEvents();
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
                              onTap: () => context.push('/detail/${e.id}', extra: e),
                              onFavoriteToggle: () => ref.read(feedNotifierProvider.notifier).toggleFavorite(e.id),
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
                              onTap: () => context.push('/detail/${e.id}', extra: e),
                              onFavoriteToggle: () => ref.read(feedNotifierProvider.notifier).toggleFavorite(e.id),
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
                              onTap: () => context.push('/detail/${e.id}', extra: e),
                              onFavoriteToggle: () => ref.read(feedNotifierProvider.notifier).toggleFavorite(e.id),
                            )),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: AppColors.textMuted,
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
