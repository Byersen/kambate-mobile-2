import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/event_status_chip.dart';
import '../../../../models/basketball_detail_model.dart';
import '../../../../models/event_model.dart';
import '../../../../models/event_status.dart';
import '../../../../models/team_model.dart';

class BasketballMatchHeader extends StatelessWidget {
  final EventModel event;
  const BasketballMatchHeader({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final showScore =
        event.status == EventStatus.live ||
        event.status == EventStatus.finished;
    final score = showScore
        ? '${event.homeScore ?? '—'} - ${event.awayScore ?? '—'}'
        : 'VS';

    final detail = BasketballDetailModel.parse(
      event.nbaStats?.extraStats?['detail'],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: _teamColumn(event.homeTeam, 'Local'),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: _centerStatusAndScore(score, detail),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: _teamColumn(event.awayTeam, 'Visitante'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _teamColumn(TeamModel? team, String fallback) {
    const placeholder = Icon(
      Icons.sports_basketball_outlined,
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
        if (team?.shortName != null && team!.shortName!.isNotEmpty) ...[
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

  Widget _centerStatusAndScore(String score, BasketballDetailModel? detail) {
    final periodAndClock = _resolvePeriodAndClock(detail);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: _buildStatusBadge(),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            score,
            key: const ValueKey('basketball-score'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        if (periodAndClock != null) ...[
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              periodAndClock,
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

  Widget _buildStatusBadge() {
    if (event.isLive) {
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
            const Text(
              'EN VIVO',
              style: TextStyle(
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

  String? _resolvePeriodAndClock(BasketballDetailModel? detail) {
    if (event.isLive) {
      final rawPeriod = event.nbaStats?.extraStats?['period']?.toString() ??
          event.nbaStats?.extraStats?['quarter']?.toString() ??
          event.nbaStats?.quarter ??
          event.currentPeriod;

      final clock = event.nbaStats?.extraStats?['clock']?.toString() ??
          _extractClockFromPeriod(event.currentPeriod);

      final periodText = _formatQuarter(rawPeriod);
      if (periodText != null && clock != null && clock.isNotEmpty) {
        return '$periodText · $clock';
      }
      if (periodText != null) return periodText;
      if (clock != null && clock.isNotEmpty) return clock;
      return null;
    }

    if (event.status == EventStatus.scheduled) {
      return AppDateFormatter.formatEventTime(event.startTime);
    }

    if (event.status == EventStatus.finished) {
      final hasOt = detail?.periods.any((p) {
        final lower = p.period.toLowerCase();
        return lower.contains('ot') || lower.contains('prórroga');
      }) ?? false;
      return hasOt ? 'Finalizado (Prórroga)' : null;
    }

    return null;
  }

  String? _formatQuarter(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final clean = raw.trim();
    final lower = clean.toLowerCase();

    if (lower.contains('1st') || lower == '1' || lower == 'q1') {
      return '1.er cuarto';
    }
    if (lower.contains('2nd') || lower == '2' || lower == 'q2') {
      return '2.° cuarto';
    }
    if (lower.contains('3rd') || lower == '3' || lower == 'q3') {
      return '3.er cuarto';
    }
    if (lower.contains('4th') || lower == '4' || lower == 'q4') {
      return '4.° cuarto';
    }
    if (lower.contains('ot2') || lower.contains('2ot')) {
      return '2.ª prórroga';
    }
    if (lower.contains('ot') || lower.contains('overtime')) {
      return 'Prórroga';
    }
    if (lower.contains('halftime') || lower == 'ht') {
      return 'Entretiempo';
    }

    final match = RegExp(r'[Qq](\d)').firstMatch(clean);
    if (match != null) {
      final qNum = match.group(1);
      return '$qNum.° cuarto';
    }

    if (clean.length <= 15 && !clean.contains(':')) {
      return clean;
    }
    return null;
  }

  String? _extractClockFromPeriod(String? raw) {
    if (raw == null) return null;
    final match = RegExp(r'(\d{1,2}:\d{2})').firstMatch(raw);
    return match?.group(1);
  }
}
