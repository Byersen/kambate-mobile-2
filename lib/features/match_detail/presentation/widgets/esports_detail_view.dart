import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/event_model.dart';
import '../../../../models/sport_type.dart';
import 'lol_detail_view.dart';
import 'stat_comparison_bar.dart';

class EsportsDetailView extends StatelessWidget {
  final EventModel event;

  const EsportsDetailView({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    if (event.sport == SportType.lol) {
      return LolDetailView(event: event);
    }

    final format = event.esportsStats?.format?.trim();
    final formatSubtitle = format != null && format.isNotEmpty ? ' • SERIE $format' : '';
    final accentColor = event.sport.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('DESGLOSE DE MAPAS$formatSubtitle'),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildMapItem(
                  mapName: 'Mapa 1 (Bind)',
                  winner: event.homeTeam?.name ?? 'Sentinels',
                  score: '13 - 9 (42:10 min)',
                  mvp: 'zekken (Jett)',
                  isFinished: true,
                  accentColor: accentColor,
                ),
                const Divider(color: AppColors.cardBorderDark, height: 20),
                _buildMapItem(
                  mapName: 'Mapa 2 (Haven)',
                  winner: event.awayTeam?.name ?? 'KRÜ',
                  score: '11 - 13 (48:30 min)',
                  mvp: 'keznit (Raze)',
                  isFinished: true,
                  accentColor: accentColor,
                ),
                const Divider(color: AppColors.cardBorderDark, height: 20),
                _buildMapItem(
                  mapName: 'Mapa 3 (Ascent)',
                  winner: 'En Juego (1-1)',
                  score: '6 - 6 (Cambio de Lado)',
                  mvp: 'En curso...',
                  isFinished: false,
                  accentColor: accentColor,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        _buildSectionTitle('ESTADÍSTICAS DE ENCUENTRO'),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                StatComparisonBar(
                  label: 'Rondas Totales Ganadas',
                  homeValueText: '13',
                  awayValueText: '9',
                  homeRatio: 13 / 22,
                  accentColor: accentColor,
                ),
                StatComparisonBar(
                  label: 'Primeras Sangres (First Blood)',
                  homeValueText: '14',
                  awayValueText: '8',
                  homeRatio: 14 / 22,
                  accentColor: accentColor,
                ),
                StatComparisonBar(
                  label: 'Spikes Plantadas',
                  homeValueText: '10',
                  awayValueText: '7',
                  homeRatio: 10 / 17,
                  accentColor: accentColor,
                ),
                StatComparisonBar(
                  label: 'Spikes Desactivadas',
                  homeValueText: '3',
                  awayValueText: '2',
                  homeRatio: 3 / 5,
                  accentColor: accentColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildMapItem({
    required String mapName,
    required String winner,
    required String score,
    required String mvp,
    required bool isFinished,
    required Color accentColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isFinished ? AppColors.surfaceDark : accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isFinished ? Icons.check_circle_outline : Icons.play_circle_outline,
            size: 20,
            color: isFinished ? AppColors.textMuted : accentColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    mapName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    winner,
                    style: TextStyle(
                      color: isFinished ? AppColors.primary : accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    score,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  Text(
                    'MVP: $mvp',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
