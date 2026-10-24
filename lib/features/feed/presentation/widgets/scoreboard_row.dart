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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 7),
              _participant(
                event.participant1Name,
                event.isCombat
                    ? (event.fighter1?.photoUrl ?? event.homeTeam?.logoUrl)
                    : event.homeTeam?.logoUrl,
                showScore ? event.homeScore?.toString() ?? '—' : '—',
              ),
              const SizedBox(height: 5.5),
              _participant(
                event.participant2Name,
                event.isCombat
                    ? (event.fighter2?.photoUrl ?? event.awayTeam?.logoUrl)
                    : event.awayTeam?.logoUrl,
                showScore ? event.awayScore?.toString() ?? '—' : '—',
              ),
              if (event.status == EventStatus.finished &&
                  event.score != null &&
                  event.score != 'vs' &&
                  event.score!.trim().isNotEmpty &&
                  (event.isCombat ||
                      (event.homeScore == null && event.awayScore == null))) ...[
                const SizedBox(height: 5),
                Text(
                  event.isCombat
                      ? event.score!
                      : 'Resultado: ${event.score!}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

  Widget _buildHeader(BuildContext context) {
    final timeOrPeriod = event.isLive && event.currentPeriod != null
        ? event.currentPeriod!
        : AppDateFormatter.formatEventTime(event.startTime);

    final leagueText = event.league.toLowerCase().contains(
              event.sport.displayName.toLowerCase(),
            )
        ? event.league
        : '${event.sport.displayName} • ${event.league}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScaler = MediaQuery.textScalerOf(context);
        final isLargeScale = textScaler.scale(1.0) > 1.25;
        final isNarrow = constraints.maxWidth < 310;

        final statusAndTime = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            EventStatusChip(status: event.status),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                timeOrPeriod,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: event.isLive ? FontWeight.bold : FontWeight.w500,
                  color: event.isLive
                      ? AppColors.liveRed
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        );

        if (isLargeScale ||
            (isNarrow &&
                (leagueText.length > 24 || timeOrPeriod.length > 18))) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    event.sport.icon,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      leagueText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  if (followed) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.star_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              statusAndTime,
            ],
          );
        }

        return Row(
          children: [
            Icon(
              event.sport.icon,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      leagueText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  if (followed) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.star_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            statusAndTime,
          ],
        );
      },
    );
  }

  Widget _participant(String name, String? logo, String score) {
    final fallback = Icon(
      event.sport.icon,
      size: 16,
      color: AppColors.textMuted,
    );
    return Row(
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: logo == null || logo.trim().isEmpty
              ? fallback
              : Image.network(
                  logo.trim(),
                  fit: BoxFit.contain,
                  errorBuilder: (_, error, stack) => fallback,
                ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          score,
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: event.isLive ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
