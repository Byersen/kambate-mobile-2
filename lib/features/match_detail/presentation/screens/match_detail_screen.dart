import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/event_model.dart';
import '../../../../models/lol_detail_model.dart';
import '../../../../models/sport_type.dart';
import '../../../../models/valorant_detail_model.dart';
import '../../../feed/providers/feed_provider.dart';
import '../widgets/basketball_match_header.dart';
import '../widgets/football_detail_view.dart';
import '../widgets/football_match_header.dart';
import '../widgets/lol_detail_view.dart';
import '../widgets/lol_match_header.dart';
import '../widgets/match_header_hero.dart';
import '../widgets/nba_detail_view.dart';
import '../widgets/ufc_detail_view.dart';
import '../widgets/valorant_detail_view.dart';
import '../widgets/valorant_match_header.dart';

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
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentEvent.sport == SportType.lol &&
                      LolDetailModel.parse(
                            currentEvent.esportsStats?.extraStats?['detail'],
                          )?.formatDisplayName !=
                          null
                  ? '${currentEvent.league} · ${LolDetailModel.parse(currentEvent.esportsStats?.extraStats?['detail'])!.formatDisplayName}'
                  : currentEvent.league,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              currentEvent.sport == SportType.valorant &&
                      ValorantDetailModel.parse(
                            currentEvent.esportsStats?.extraStats?['detail'],
                          )?.formatDisplayName !=
                          null
                  ? ValorantDetailModel.parse(
                      currentEvent.esportsStats?.extraStats?['detail'],
                    )!.formatDisplayName!
                  : currentEvent.sport == SportType.nba
                      ? 'BÁSQUETBOL'
                      : currentEvent.sport == SportType.ufc
                          ? 'MMA · UFC'
                          : currentEvent.sport.displayName.toUpperCase(),
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              currentEvent.isFavorite
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              color: currentEvent.isFavorite
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            tooltip: currentEvent.isFavorite
                ? 'Quitar de favoritos'
                : 'Añadir a favoritos',
            onPressed: () {
              ref
                  .read(feedNotifierProvider.notifier)
                  .toggleFavorite(currentEvent.id);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(feedNotifierProvider.notifier)
              .loadEvents(forceRefresh: true);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            if (feedAsync.hasError) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Mostrando datos locales de caché',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () {
                        ref
                            .read(feedNotifierProvider.notifier)
                            .loadEvents(forceRefresh: true);
                      },
                      child: const Text(
                        'Reintentar',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (currentEvent.sport == SportType.soccer)
              FootballMatchHeader(event: currentEvent)
            else if (currentEvent.sport == SportType.nba)
              BasketballMatchHeader(event: currentEvent)
            else if (currentEvent.sport == SportType.lol)
              LolMatchHeader(event: currentEvent)
            else if (currentEvent.sport == SportType.valorant)
              ValorantMatchHeader(event: currentEvent)
            else if (currentEvent.sport == SportType.ufc)
              const SizedBox.shrink()
            else
              MatchHeaderHero(event: currentEvent),

            if (currentEvent.sport != SportType.ufc)
              const SizedBox(height: 18),

            _buildSpecializedContent(currentEvent),

            if (currentEvent.sport != SportType.soccer &&
                currentEvent.sport != SportType.nba &&
                currentEvent.sport != SportType.lol &&
                currentEvent.sport != SportType.valorant &&
                currentEvent.sport != SportType.ufc) ...[
              const SizedBox(height: 18),
              _buildMatchInfoCard(currentEvent),
            ],

            if (currentEvent.id == 'football' ||
                currentEvent.id == 'basketball' ||
                currentEvent.id == 'lol' ||
                currentEvent.id == 'lol-1' ||
                currentEvent.id == 'val-1' ||
                currentEvent.id.startsWith('mock_')) ...[
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Datos de ejemplo',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
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
        return LolDetailView(event: event);
      case SportType.valorant:
        return ValorantDetailView(event: event);
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
