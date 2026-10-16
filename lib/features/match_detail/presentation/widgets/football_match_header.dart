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
        ? '${event.homeScore ?? '—'} - ${event.awayScore ?? '—'}'
        : 'VS';

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
              child: _centerStatusAndScore(score),
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
      ],
    );
  }

  Widget _centerStatusAndScore(String score) {
    final clock = _resolveClock();
    final periodText = _resolvePeriod();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: _buildStatusBadge(clock),
        ),
        if (periodText != null) ...[
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              periodText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            score,
            key: const ValueKey('football-score'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String? clock) {
    if (event.isLive) {
      final clockPart = clock != null && clock.isNotEmpty ? ' • $clock' : '';
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
              'EN VIVO$clockPart',
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

  String? _resolveClock() {
    final raw = event.currentPeriod ??
        event.footballStats?.extraStats?['clock']?.toString();
    if (raw == null || raw.isEmpty) return null;
    return raw.replaceAll('′', "'");
  }

  String? _resolvePeriod() {
    if (event.isLive) {
      final raw = event.footballStats?.extraStats?['statusDescription']?.toString() ??
          event.footballStats?.extraStats?['statusDetail']?.toString();
      if (raw != null && raw.isNotEmpty) {
        final lower = raw.toLowerCase();
        if (lower.contains('1st half') || lower.contains('first half')) {
          return 'Primer tiempo';
        }
        if (lower.contains('2nd half') || lower.contains('second half')) {
          return 'Segundo tiempo';
        }
        if (lower.contains('halftime') || lower.contains('ht') || lower == 'entretiempo') {
          return 'Entretiempo';
        }
        if (lower.contains('extra time') || lower.contains('prórroga')) {
          return 'Prórroga';
        }
        if (lower.contains('penalties') || lower.contains('penales')) {
          return 'Penales';
        }
        if (!raw.endsWith("'") && !raw.endsWith('′')) {
          return raw;
        }
      }
      return null;
    }

    if (event.status == EventStatus.scheduled) {
      return AppDateFormatter.formatEventTime(event.startTime);
    }

    return null;
  }
}
