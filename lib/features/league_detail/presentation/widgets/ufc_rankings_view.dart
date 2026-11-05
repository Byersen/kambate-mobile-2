import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/event_model.dart';
import '../../../../models/sport_type.dart';
import '../../../../models/ufc_card_model.dart';
import '../../../../models/ufc_rankings_model.dart';
import '../../../match_detail/presentation/screens/ufc_fight_detail_screen.dart';

class UfcRankingsView extends StatefulWidget {
  final UfcRankingsModel rankings;
  final List<EventModel> allEvents;
  final VoidCallback? onRefresh;

  const UfcRankingsView({
    super.key,
    required this.rankings,
    this.allEvents = const [],
    this.onRefresh,
  });

  @override
  State<UfcRankingsView> createState() => _UfcRankingsViewState();
}

class _UfcRankingsViewState extends State<UfcRankingsView> {
  final Set<String> _expandedCategoryIds = {};

  void _navigateToFighterFight(UfcRankingFighterModel fighter) {
    final fighterName = fighter.name.toLowerCase();

    for (final event in widget.allEvents) {
      if (event.sport != SportType.ufc) continue;

      final card =
          event.ufcCard ?? UfcCardModel.fromEvent(event, allEvents: widget.allEvents);
      for (final fight in card.fights) {
        final f1Name = fight.fighter1.name.toLowerCase();
        final f2Name = fight.fighter2.name.toLowerCase();

        if (f1Name.contains(fighterName) ||
            fighterName.contains(f1Name) ||
            f2Name.contains(fighterName) ||
            fighterName.contains(f2Name) ||
            (fighter.participantId != null &&
                (fight.fighter1.id == fighter.participantId ||
                    fight.fighter2.id == fighter.participantId))) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => UfcFightDetailScreen(
                card: card,
                fight: fight,
                event: event,
              ),
            ),
          );
          return;
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${fighter.name} no tiene combate programado en las próximas carteleras.',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.surfaceDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.rankings.hasCoverage || widget.rankings.categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.format_list_numbered_rounded,
                  size: 48,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cobertura no disponible',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No se pudieron cargar los rankings oficiales de UFC desde la fuente oficial.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              if (widget.onRefresh != null) ...[
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: widget.onRefresh,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Reintentar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ufcRed,
                    side: const BorderSide(color: AppColors.ufcRed),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      itemCount: widget.rankings.categories.length,
      itemBuilder: (context, index) {
        final category = widget.rankings.categories[index];
        final expanded = _expandedCategoryIds.contains(category.id);
        return _buildCategoryCard(category, expanded);
      },
    );
  }

  Widget _buildCategoryCard(UfcRankingCategoryModel category, bool expanded) {
    final champion = category.champion;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey('ufc-division-${category.id}'),
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                setState(() {
                  if (expanded) {
                    _expandedCategoryIds.remove(category.id);
                  } else {
                    _expandedCategoryIds.add(category.id);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.translatedName.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                              color: AppColors.ufcRed,
                            ),
                          ),
                          if (champion != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              champion.name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                                height: 1.1,
                                color: Color(0xFF111111),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'CHAMPION',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1, color: AppColors.borderDark),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                children: [
                  for (final fighter in category.ranks) _buildFighterRow(fighter),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFighterRow(UfcRankingFighterModel fighter) {
    final pos = fighter.position ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToFighterFight(fighter),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '$pos',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111111),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  fighter.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildSimpleTrend(fighter.trend),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleTrend(String? trend) {
    if (trend == null) return const SizedBox.shrink();
    final clean = trend.trim();
    if (clean.isEmpty || clean == '-' || clean == '=') {
      return const SizedBox.shrink();
    }

    if (clean.startsWith('+')) {
      final delta = clean.substring(1).trim();
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.arrow_drop_up_rounded,
            size: 20,
            color: Color(0xFF65A30D),
          ),
          if (delta.isNotEmpty)
            Text(
              delta,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Color(0xFF111111),
              ),
            ),
        ],
      );
    }

    if (clean.startsWith('-')) {
      final delta = clean.substring(1).trim();
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.arrow_drop_down_rounded,
            size: 20,
            color: Color(0xFFDC2626),
          ),
          if (delta.isNotEmpty)
            Text(
              delta,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Color(0xFF111111),
              ),
            ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
