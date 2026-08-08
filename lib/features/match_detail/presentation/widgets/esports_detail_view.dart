import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/event_model.dart';
import '../../../../models/sport_type.dart';
import 'stat_comparison_bar.dart';

class EsportsDetailView extends StatelessWidget {
  final EventModel event;

  const EsportsDetailView({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final isLol = event.sport == SportType.lol;
    final format = event.esportsStats?.format ?? 'Bo5';
    final accentColor = event.sport.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Series Map Breakdown
        _buildSectionTitle('DESGLOSE DE MAPAS • SERIE $format'),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildMapItem(
                  mapName: isLol ? 'Mapa 1 (Grieta del Invocador)' : 'Mapa 1 (Bind)',
                  winner: event.homeTeam?.name ?? 'T1',
                  score: isLol ? '18 - 8 (31:24 min)' : '13 - 9 (42:10 min)',
                  mvp: isLol ? 'Faker (Orianna)' : 'zekken (Jett)',
                  isFinished: true,
                  accentColor: accentColor,
                ),
                const Divider(color: AppColors.cardBorderDark, height: 20),
                _buildMapItem(
                  mapName: isLol ? 'Mapa 2 (Grieta del Invocador)' : 'Mapa 2 (Haven)',
                  winner: event.awayTeam?.name ?? 'Gen.G',
                  score: isLol ? '12 - 21 (36:50 min)' : '11 - 13 (48:30 min)',
                  mvp: isLol ? 'Chovy (Yone)' : 'keznit (Raze)',
                  isFinished: true,
                  accentColor: accentColor,
                ),
                const Divider(color: AppColors.cardBorderDark, height: 20),
                _buildMapItem(
                  mapName: isLol ? 'Mapa 3 (Grieta del Invocador)' : 'Mapa 3 (Ascent)',
                  winner: 'En Juego (1-1)',
                  score: isLol ? '14 - 12 (24:15 min)' : '6 - 6 (Cambio de Lado)',
                  mvp: 'En curso...',
                  isFinished: false,
                  accentColor: accentColor,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 2. Esports In-Game Comparative Stats
        _buildSectionTitle(isLol ? 'ESTADÍSTICAS GLOBALES DE PARTIDA' : 'ESTADÍSTICAS DE ENCUENTRO'),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (isLol) ...[
                  StatComparisonBar(
                    label: 'Oro Acumulado Total',
                    homeValueText: '68.4k',
                    awayValueText: '62.1k',
                    homeRatio: 68.4 / (68.4 + 62.1),
                    accentColor: accentColor,
                  ),
                  StatComparisonBar(
                    label: 'Asesinatos (Kills)',
                    homeValueText: '16',
                    awayValueText: '11',
                    homeRatio: 16 / 27,
                    accentColor: accentColor,
                  ),
                  StatComparisonBar(
                    label: 'Torres Destruidas',
                    homeValueText: '7',
                    awayValueText: '3',
                    homeRatio: 7 / 10,
                    accentColor: accentColor,
                  ),
                  StatComparisonBar(
                    label: 'Dragones Elementales',
                    homeValueText: '3',
                    awayValueText: '1',
                    homeRatio: 3 / 4,
                    accentColor: accentColor,
                  ),
                  StatComparisonBar(
                    label: 'Barones de Nashor',
                    homeValueText: '1',
                    awayValueText: '0',
                    homeRatio: 1.0,
                    accentColor: accentColor,
                  ),
                ] else ...[
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
