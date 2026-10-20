import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/event_model.dart';
import '../../../../models/sport_type.dart';
import 'lol_detail_view.dart';
import 'valorant_detail_view.dart';

class EsportsDetailView extends StatelessWidget {
  final EventModel event;

  const EsportsDetailView({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    if (event.sport == SportType.lol) {
      return LolDetailView(event: event);
    }
    if (event.sport == SportType.valorant) {
      return ValorantDetailView(event: event);
    }

    final stats = event.esportsStats;
    final mapName = stats?.map;
    final format = stats?.format;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'INFORMACIÓN DE ESPORTS',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            if (mapName != null && mapName.isNotEmpty) ...[
              Text(
                'Mapa: $mapName',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
            ],
            if (format != null && format.isNotEmpty) ...[
              Text(
                'Formato: $format',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              'Marcador general: ${event.homeScore ?? 0} — ${event.awayScore ?? 0}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
