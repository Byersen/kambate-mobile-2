import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/event_status_chip.dart';
import '../../../../models/event_model.dart';
import '../../../../models/event_status.dart';

class ScoreboardRow extends StatelessWidget {
  const ScoreboardRow({
    super.key,
    required this.event,
    required this.onTap,
    this.followed = false,
  });

  final EventModel event;
  final VoidCallback onTap;
  final bool followed;

  @override
  Widget build(BuildContext context) {
    final showScore =
        !event.isCombat &&
        (event.status == EventStatus.live ||
            event.status == EventStatus.finished);
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    event.sport.icon,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.league.toLowerCase().contains(
                                event.sport.displayName.toLowerCase(),
                              )
                          ? event.league
                          : '${event.sport.displayName} • ${event.league}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (followed) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  EventStatusChip(status: event.status),
                  Text(
                    event.isLive && event.currentPeriod != null
                        ? event.currentPeriod!
                        : AppDateFormatter.formatEventTime(event.startTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: event.isLive
                          ? AppColors.liveRed
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _participant(
                event.participant1Name,
                event.isCombat
                    ? event.fighter1?.photoUrl
                    : event.homeTeam?.logoUrl,
                showScore ? event.homeScore?.toString() ?? '—' : '—',
              ),
              const SizedBox(height: 10),
              _participant(
                event.participant2Name,
                event.isCombat
                    ? event.fighter2?.photoUrl
                    : event.awayTeam?.logoUrl,
                showScore ? event.awayScore?.toString() ?? '—' : '—',
              ),
              if (event.isCombat &&
                  event.status == EventStatus.finished &&
                  event.score != null) ...[
                const SizedBox(height: 10),
                Text(
                  event.score!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _participant(String name, String? logo, String score) {
    final fallback = Icon(
      event.sport.icon,
      size: 21,
      color: AppColors.textMuted,
    );
    return Row(
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: logo == null || logo.isEmpty
              ? fallback
              : Image.network(
                  logo,
                  fit: BoxFit.contain,
                  errorBuilder: (_, error, stack) => fallback,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          score,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
