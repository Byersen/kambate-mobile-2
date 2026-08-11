import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/event_model.dart';
import 'stat_comparison_bar.dart';

class FootballDetailView extends StatelessWidget {
  final EventModel event;

  const FootballDetailView({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final stats = event.footballStats;
    final homeGoals = stats?.homeGoals ?? event.homeScore ?? 0;
    final homeCards = stats?.homeCards ?? 1;
    final awayCards = stats?.awayCards ?? 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('LÍNEA DE TIEMPO DEL PARTIDO'),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTimelineItem(
                  minute: "34'",
                  isHome: true,
                  icon: Icons.sports_soccer,
                  iconColor: AppColors.primary,
                  title: '¡Gol de Real Madrid!',
                  subtitle: 'Vinícius Jr (Asistencia de Bellingham)',
                ),
                const Divider(color: AppColors.cardBorderDark, height: 20),
                _buildTimelineItem(
                  minute: "45+2'",
                  isHome: false,
                  icon: Icons.sports_soccer,
                  iconColor: AppColors.secondary,
                  title: '¡Gol de Manchester City!',
                  subtitle: 'Erling Haaland (Cabezazo)',
                ),
                const Divider(color: AppColors.cardBorderDark, height: 20),
                _buildTimelineItem(
                  minute: "58'",
                  isHome: false,
                  icon: Icons.square,
                  iconColor: Colors.amber,
                  title: 'Tarjeta Amarilla',
                  subtitle: 'Rodri (Falta táctica)',
                ),
                if (homeGoals >= 2 || event.isLive) ...[
                  const Divider(color: AppColors.cardBorderDark, height: 20),
                  _buildTimelineItem(
                    minute: "68'",
                    isHome: true,
                    icon: Icons.sports_soccer,
                    iconColor: AppColors.primary,
                    title: '¡Gol de Real Madrid!',
                    subtitle: 'Rodrygo (Remate al ángulo)',
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        _buildSectionTitle('ESTADÍSTICAS DEL ENCUENTRO'),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                StatComparisonBar(
                  label: 'Posesión de Balón',
                  homeValueText: '54%',
                  awayValueText: '46%',
                  homeRatio: 0.54,
                  accentColor: AppColors.soccer,
                ),
                StatComparisonBar(
                  label: 'Tiros Totales',
                  homeValueText: '14',
                  awayValueText: '10',
                  homeRatio: 14 / 24,
                  accentColor: AppColors.soccer,
                ),
                StatComparisonBar(
                  label: 'Tiros a Puerta',
                  homeValueText: '6',
                  awayValueText: '4',
                  homeRatio: 6 / 10,
                  accentColor: AppColors.soccer,
                ),
                StatComparisonBar(
                  label: 'Córners',
                  homeValueText: '7',
                  awayValueText: '3',
                  homeRatio: 7 / 10,
                  accentColor: AppColors.soccer,
                ),
                StatComparisonBar(
                  label: 'Faltas Cometidas',
                  homeValueText: '11',
                  awayValueText: '13',
                  homeRatio: 11 / 24,
                  accentColor: AppColors.soccer,
                ),
                StatComparisonBar(
                  label: 'Tarjetas Amarillas',
                  homeValueText: '$homeCards',
                  awayValueText: '$awayCards',
                  homeRatio: (homeCards + awayCards > 0) ? homeCards / (homeCards + awayCards) : 0.5,
                  accentColor: Colors.amber,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        _buildSectionTitle('ALINEACIONES Y TÁCTICA'),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTacticalBadge(event.homeTeam?.name ?? 'Local', '4-3-3', AppColors.soccer),
                Container(
                  width: 1,
                  height: 48,
                  color: AppColors.cardBorderDark,
                ),
                _buildTacticalBadge(event.awayTeam?.name ?? 'Visitante', '4-2-3-1', AppColors.secondary),
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

  Widget _buildTimelineItem({
    required String minute,
    required bool isHome,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          padding: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            minute,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTacticalBadge(String teamName, String formation, Color color) {
    return Column(
      children: [
        Text(
          teamName,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            formation,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
