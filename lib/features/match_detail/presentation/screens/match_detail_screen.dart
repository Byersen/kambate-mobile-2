import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/event_model.dart';
import '../../../../models/sport_type.dart';
import '../../../feed/providers/feed_provider.dart';
import '../widgets/esports_detail_view.dart';
import '../widgets/football_detail_view.dart';
import '../widgets/football_match_header.dart';
import '../widgets/match_header_hero.dart';
import '../widgets/nba_detail_view.dart';
import '../widgets/ufc_detail_view.dart';

class MatchDetailScreen extends ConsumerWidget {
  final EventModel event;

  const MatchDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedNotifierProvider);
    final currentEvent = feedAsync.maybeWhen(
      data: (events) =>
          events.firstWhere((e) => e.id == event.id, orElse: () => event),
      orElse: () => event,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentEvent.sport == SportType.soccer
              ? 'Detalle del partido'
              : currentEvent.league,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          if (currentEvent.sport == SportType.soccer)
            FootballMatchHeader(event: currentEvent)
          else
            MatchHeaderHero(event: currentEvent),

          const SizedBox(height: 18),

          _buildSpecializedContent(currentEvent),

          const SizedBox(height: 18),

          if (currentEvent.sport != SportType.soccer)
            _buildMatchInfoCard(currentEvent),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSpecializedContent(EventModel event) {
    switch (event.sport) {
      case SportType.soccer:
        return FootballDetailView(event: event);
      case SportType.nba:
        return NbaDetailView(event: event);
      case SportType.ufc:
        return UfcDetailView(event: event);
      case SportType.lol:
      case SportType.valorant:
        return EsportsDetailView(event: event);
      case SportType.all:
        return FootballDetailView(event: event);
    }
  }

  Widget _buildMatchInfoCard(EventModel event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'INFORMACIÓN DEL EVENTO',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('Disciplina', event.sport.displayName),
                const Divider(color: AppColors.cardBorderDark),
                _buildInfoRow('Liga / Torneo', event.league),
                if (event.leagueModel != null) ...[
                  const Divider(color: AppColors.cardBorderDark),
                  _buildInfoRow(
                    'Nivel de Liga',
                    event.leagueModel!.isTier1
                        ? 'Tier 1 (Élite Internacional)'
                        : 'Tier 2 (Desarrollo / Regional)',
                  ),
                ],
                if (event.seasonModel != null) ...[
                  const Divider(color: AppColors.cardBorderDark),
                  _buildInfoRow('Temporada', event.seasonModel!.name),
                ],
                const Divider(color: AppColors.cardBorderDark),
                _buildInfoRow('Estado', event.status.displayName),
                if (event.venue != null) ...[
                  const Divider(color: AppColors.cardBorderDark),
                  _buildInfoRow('Sede / Estadio', event.venue!),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
