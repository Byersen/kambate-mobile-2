import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/event_model.dart';
import 'stat_comparison_bar.dart';

class NbaDetailView extends StatelessWidget {
  final EventModel event;

  const NbaDetailView({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final homeTotal = event.homeScore ?? 104;
    final awayTotal = event.awayScore ?? 101;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('PUNTUACIÓN POR CUARTOS'),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2.5),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1),
                    4: FlexColumnWidth(1),
                    5: FlexColumnWidth(1.2),
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.cardBorderDark)),
                      ),
                      children: [
                        _buildTableHeader('EQUIPO', alignLeft: true),
                        _buildTableHeader('Q1'),
                        _buildTableHeader('Q2'),
                        _buildTableHeader('Q3'),
                        _buildTableHeader('Q4'),
                        _buildTableHeader('TOTAL', isHighlight: true),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableCell(event.homeTeam?.shortName ?? 'LAL', isBold: true, alignLeft: true),
                        _buildTableCell('28'),
                        _buildTableCell('25'),
                        _buildTableCell('29'),
                        _buildTableCell('${homeTotal - (28 + 25 + 29)}'),
                        _buildTableCell('$homeTotal', isBold: true, isHighlight: true),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableCell(event.awayTeam?.shortName ?? 'GSW', isBold: true, alignLeft: true),
                        _buildTableCell('24'),
                        _buildTableCell('28'),
                        _buildTableCell('26'),
                        _buildTableCell('${awayTotal - (24 + 28 + 26)}'),
                        _buildTableCell('$awayTotal', isBold: true, isHighlight: true),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        _buildSectionTitle('ESTADÍSTICAS DEL PARTIDO'),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                StatComparisonBar(
                  label: 'Tiros de Campo (FG%)',
                  homeValueText: '48.2%',
                  awayValueText: '45.1%',
                  homeRatio: 0.52,
                  accentColor: AppColors.nba,
                ),
                StatComparisonBar(
                  label: 'Triples (3PT%)',
                  homeValueText: '38.5%',
                  awayValueText: '41.2%',
                  homeRatio: 0.47,
                  accentColor: AppColors.nba,
                ),
                StatComparisonBar(
                  label: 'Tiros Libres (FT%)',
                  homeValueText: '84.6%',
                  awayValueText: '78.9%',
                  homeRatio: 0.54,
                  accentColor: AppColors.nba,
                ),
                StatComparisonBar(
                  label: 'Rebotes Totales',
                  homeValueText: '46',
                  awayValueText: '41',
                  homeRatio: 46 / 87,
                  accentColor: AppColors.nba,
                ),
                StatComparisonBar(
                  label: 'Asistencias',
                  homeValueText: '28',
                  awayValueText: '26',
                  homeRatio: 28 / 54,
                  accentColor: AppColors.nba,
                ),
                StatComparisonBar(
                  label: 'Puntos en Pintura',
                  homeValueText: '52',
                  awayValueText: '44',
                  homeRatio: 52 / 96,
                  accentColor: AppColors.nba,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        _buildSectionTitle('LÍDERES INDIVIDUALES'),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildLeaderRow(
                  category: 'Máximo Anotador',
                  homeLeader: 'L. James (32 pts)',
                  awayLeader: 'S. Curry (29 pts)',
                ),
                const Divider(color: AppColors.cardBorderDark),
                _buildLeaderRow(
                  category: 'Rebotes',
                  homeLeader: 'A. Davis (14 reb)',
                  awayLeader: 'D. Green (9 reb)',
                ),
                const Divider(color: AppColors.cardBorderDark),
                _buildLeaderRow(
                  category: 'Asistencias',
                  homeLeader: 'D. Russell (8 ast)',
                  awayLeader: 'C. Paul (11 ast)',
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

  Widget _buildTableHeader(String text, {bool alignLeft = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        style: TextStyle(
          color: isHighlight ? AppColors.primary : AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isBold = false, bool alignLeft = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        style: TextStyle(
          color: isHighlight ? AppColors.primary : AppColors.textPrimary,
          fontSize: 13,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildLeaderRow({
    required String category,
    required String homeLeader,
    required String awayLeader,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            homeLeader,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            category,
            style: const TextStyle(
              color: AppColors.nba,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            awayLeader,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
