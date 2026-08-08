import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/event_model.dart';
import 'stat_comparison_bar.dart';

class UfcDetailView extends StatelessWidget {
  final EventModel event;

  const UfcDetailView({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final f1 = event.fighter1;
    final f2 = event.fighter2;
    final ufcStats = event.ufcStats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Official Result & Finish Details (if finished)
        if (event.fightResult != null || ufcStats?.method != null) ...[
          _buildSectionTitle('RESULTADO OFICIAL DEL COMBATE'),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.ufc.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.ufc.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emoji_events, color: AppColors.ufc, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ufcStats?.winnerName ?? f1?.name ?? 'Ganador del Combate',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Método: ${ufcStats?.method ?? event.fightResult ?? "KO / TKO"} • R${ufcStats?.round ?? 2} (${ufcStats?.time ?? "0:13"})',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 2. Tale of the Tape (Cara a Cara Físico y Récord)
        _buildSectionTitle('TALE OF THE TAPE • CARA A CARA'),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTapeRow('División', f1?.weightClass ?? '145 lbs (Pluma)', f2?.weightClass ?? '145 lbs (Pluma)'),
                const Divider(color: AppColors.cardBorderDark),
                _buildTapeRow('Récord MMA', f1?.record ?? '15-0-0', f2?.record ?? '26-7-0'),
                const Divider(color: AppColors.cardBorderDark),
                _buildTapeRow('Estatura', '1.70 m (5\'7")', '1.80 m (5\'11")'),
                const Divider(color: AppColors.cardBorderDark),
                _buildTapeRow('Alcance', '175 cm (69")', '175 cm (69")'),
                const Divider(color: AppColors.cardBorderDark),
                _buildTapeRow('Guardia', 'Ortodoxa', 'Ortodoxa / Switch'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 3. Significant Strikes & Grappling Stats
        _buildSectionTitle('ESTADÍSTICAS DEL COMBATE'),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                StatComparisonBar(
                  label: 'Golpes Significativos',
                  homeValueText: '62 / 104',
                  awayValueText: '48 / 95',
                  homeRatio: 62 / 110,
                  accentColor: AppColors.ufc,
                ),
                StatComparisonBar(
                  label: 'Efectividad de Golpeo',
                  homeValueText: '59%',
                  awayValueText: '50%',
                  homeRatio: 0.59,
                  accentColor: AppColors.ufc,
                ),
                StatComparisonBar(
                  label: 'Derribos Completados',
                  homeValueText: '2 / 3',
                  awayValueText: '0 / 1',
                  homeRatio: 2 / 2,
                  accentColor: AppColors.ufc,
                ),
                StatComparisonBar(
                  label: 'Intentos de Sumisión',
                  homeValueText: '1',
                  awayValueText: '0',
                  homeRatio: 1.0,
                  accentColor: AppColors.ufc,
                ),
                StatComparisonBar(
                  label: 'Tiempo de Control',
                  homeValueText: '3:24 min',
                  awayValueText: '0:45 min',
                  homeRatio: 0.8,
                  accentColor: AppColors.ufc,
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

  Widget _buildTapeRow(String attribute, String f1Value, String f2Value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              f1Value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              attribute,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              f2Value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
