import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/event_status_chip.dart';
import '../../../../models/event_model.dart';
import '../../../../models/event_status.dart';
import '../../../../models/lol_detail_model.dart';
import '../../../../models/team_model.dart';

class LolMatchHeader extends StatelessWidget {
  final EventModel event;
  const LolMatchHeader({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final detail = LolDetailModel.parse(
      event.esportsStats?.extraStats?['detail'],
    );

    final showScore =
        event.status == EventStatus.live ||
        event.status == EventStatus.finished;

    final homeScore = event.homeScore ?? event.esportsStats?.homeScore;
    final awayScore = event.awayScore ?? event.esportsStats?.awayScore;

    final score = showScore
        ? '${homeScore ?? 0} — ${awayScore ?? 0}'
        : 'VS';

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: _teamColumn(event.homeTeam, 'Equipo 1'),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: _centerStatusAndScore(score, detail),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: _teamColumn(event.awayTeam, 'Equipo 2'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _teamColumn(TeamModel? team, String fallback) {
    const placeholder = Icon(
      Icons.sports_esports_outlined,
      size: 38,
      color: AppColors.textMuted,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 52,
          height: 52,
          child: team?.logoUrl == null || team!.logoUrl!.isEmpty
              ? placeholder
              : Image.network(
                  team.logoUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, error, stack) => placeholder,
                ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            team?.name ?? fallback,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (team?.shortName != null &&
            team!.shortName!.isNotEmpty &&
            team.shortName!.trim().toUpperCase() != team.name.trim().toUpperCase()) ...[
          const SizedBox(height: 2),
          Text(
            team.shortName!.toUpperCase(),
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _centerStatusAndScore(String score, LolDetailModel? detail) {
    final subInfo = _resolveSubInfo(detail);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: _buildStatusBadge(detail),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            score,
            key: const ValueKey('lol-series-score'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'PARTIDAS GANADAS',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        if (subInfo != null) ...[
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              subInfo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: event.isLive
                    ? AppColors.liveRed
                    : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: event.isLive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(LolDetailModel? detail) {
    if (event.isLive) {
      final activeGameNum = detail?.activeGame?.gameNumber ??
          detail?.activeGameNumber;
      final label = activeGameNum != null
          ? 'EN VIVO · Partida $activeGameNum'
          : 'EN VIVO';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
        decoration: BoxDecoration(
          color: AppColors.liveRed.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.liveRed,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.liveRed,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    if (event.status == EventStatus.finished) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'FINALIZADO',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    if (event.status == EventStatus.scheduled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'PROGRAMADO',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    return EventStatusChip(status: event.status);
  }

  String? _resolveSubInfo(LolDetailModel? detail) {
    if (event.status == EventStatus.scheduled) {
      return AppDateFormatter.formatEventTime(event.startTime);
    }
    return null;
  }
}
