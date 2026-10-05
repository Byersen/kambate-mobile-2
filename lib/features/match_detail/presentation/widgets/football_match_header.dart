import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/event_status_chip.dart';
import '../../../../models/event_model.dart';
import '../../../../models/event_status.dart';
import '../../../../models/team_model.dart';

class FootballMatchHeader extends StatelessWidget {
  final EventModel event;
  const FootballMatchHeader({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final showScore =
        event.status == EventStatus.live ||
        event.status == EventStatus.finished;
    final score = showScore
        ? '${event.homeScore ?? '—'} : ${event.awayScore ?? '—'}'
        : 'VS';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              event.league,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _team(event.homeTeam, 'Local')),
                const SizedBox(width: 12),
                Expanded(child: _team(event.awayTeam, 'Visitante')),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              score,
              key: const ValueKey('football-score'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                EventStatusChip(status: event.status),
                if (event.isLive && event.currentPeriod != null)
                  Text(
                    event.currentPeriod!,
                    style: const TextStyle(
                      color: AppColors.liveRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              AppDateFormatter.formatFullDate(event.startTime),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            if (event.venue != null) ...[
              const SizedBox(height: 8),
              Text(
                event.venue!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _team(TeamModel? team, String fallback) {
    const placeholder = Icon(
      Icons.shield_outlined,
      size: 34,
      color: AppColors.textMuted,
    );
    return Column(
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: team?.logoUrl == null || team!.logoUrl!.isEmpty
              ? placeholder
              : Image.network(
                  team.logoUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, error, stack) => placeholder,
                ),
        ),
        const SizedBox(height: 10),
        Text(
          team?.name ?? fallback,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
