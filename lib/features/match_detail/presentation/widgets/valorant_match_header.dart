import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/event_status_chip.dart';
import '../../../../models/event_model.dart';
import '../../../../models/event_status.dart';
import '../../../../models/sport_type.dart';
import '../../../../models/team_model.dart';
import '../../../../models/valorant_detail_model.dart';

class ValorantMatchHeader extends StatelessWidget {
  final EventModel event;
  const ValorantMatchHeader({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final detail = ValorantDetailModel.parse(
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                SportType.valorant.icon,
                size: 16,
                color: AppColors.valorant,
              ),
              const SizedBox(width: 6),
              const Text(
                'VALORANT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Card(
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
        ),
      ],
    );
  }

  Widget _teamColumn(TeamModel? team, String fallback) {
    const placeholder = Icon(
      Icons.shield_outlined,
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

  Widget _centerStatusAndScore(String score, ValorantDetailModel? detail) {
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
            key: const ValueKey('valorant-series-score'),
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
          'MAPAS GANADOS',
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
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(ValorantDetailModel? detail) {
    if (event.status == EventStatus.live) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            const Text(
              'EN VIVO',
              style: TextStyle(
                color: AppColors.liveRed,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      );
    }

    if (event.status == EventStatus.finished) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'FINALIZADO',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 0.4,
          ),
        ),
      );
    }

    return EventStatusChip(status: event.status);
  }

  String? _resolveSubInfo(ValorantDetailModel? detail) {
    if (event.status == EventStatus.scheduled) {
      return AppDateFormatter.formatFullDate(event.startTime);
    }

    final active = detail?.activeMap;
    if (active != null) {
      if (active.isLive) {
        if (active.currentRound != null) {
          return '${active.mapName} · Ronda ${active.currentRound}';
        }
        return '${active.mapName} · En juego';
      }
      if (active.isFinished) {
        return '${active.mapName} · Finalizado';
      }
      return '${active.mapName} · Por jugar';
    }

    if (event.currentPeriod != null && event.currentPeriod!.isNotEmpty) {
      return event.currentPeriod;
    }

    if (event.status == EventStatus.finished) {
      return 'Serie concluida';
    }

    return null;
  }
}
