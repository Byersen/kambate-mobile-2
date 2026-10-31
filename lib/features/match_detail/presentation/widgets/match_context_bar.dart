import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/match_round_formatter.dart';
import '../../../../models/event_model.dart';

/// Franja superior del detalle de partido con el contexto del encuentro:
/// ronda o fase (ej. "Fecha 12", "Cuartos de final") y la fecha y hora en
/// que se juega (ej. "Sábado 01 Noviembre · 20:00").
class MatchContextBar extends StatelessWidget {
  final EventModel event;

  const MatchContextBar({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final round = MatchRoundFormatter.format(event.roundOrPhase);
    final local = event.startTime.toLocal();
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    final dateText = '${AppDateFormatter.formatDate(local)} · $time';

    return Padding(
      key: const ValueKey('match-context-bar'),
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          if (round != null)
            Container(
              key: const ValueKey('match-round-chip'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                round,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.event_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  dateText,
                  key: const ValueKey('match-date-text'),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

