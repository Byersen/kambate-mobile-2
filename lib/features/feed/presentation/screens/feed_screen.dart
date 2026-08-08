import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/event_status.dart';
import '../../../../models/sport_type.dart';
import '../../providers/feed_provider.dart';
import '../widgets/league_tier_selector.dart';
import '../widgets/match_card.dart';
import '../widgets/sport_filter_bar.dart';
import '../widgets/sync_status_badge.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSport = ref.watch(selectedSportFilterProvider);
    final selectedTier = ref.watch(selectedLeagueTierProvider);
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
      body: Column(
        children: [
          // 1. Sport Discipline Filter Bar (Todos, Fútbol, NBA, UFC, LoL, Valorant)
          SportFilterBar(
            selectedSport: selectedSport,
            onSportSelected: (sport) {
              ref.read(selectedSportFilterProvider.notifier).state = sport;
            },
          ),

          // 2. League Tier Selector (Todas, Tier 1 Élite, Tier 2 Secundarias)
          const LeagueTierSelector(),

          const SizedBox(height: 4),

          // 3. Events Feed List
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
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(selectedSport.icon, size: 52, color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          Text(
                            'No hay eventos de ${selectedSport.displayName} ${selectedTier != null ? (selectedTier == 1 ? "Tier 1" : "Tier 2") : ""}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Prueba seleccionando "Todas las Ligas" u otra disciplina deportiva.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () {
                              ref.read(selectedSportFilterProvider.notifier).state = SportType.all;
                              ref.read(selectedLeagueTierProvider.notifier).state = null;
                            },
                            child: const Text('Restablecer Filtros'),
                          ),
                        ],
                      ),
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
                    await ref.read(feedNotifierProvider.notifier).loadEvents(forceRefresh: true);
                  },
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      // Section 1: LIVE NOW
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

                      // Section 2: UPCOMING MATCHES
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

                      // Section 3: FINISHED MATCHES
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
              border: Border.all(color: AppColors.cardBorderDark, width: 0.8),
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
