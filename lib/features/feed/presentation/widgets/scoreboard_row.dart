import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/match_minute_formatter.dart';
import '../../../../core/widgets/event_status_chip.dart';
import '../../../../models/event_model.dart';
import '../../../../models/event_status.dart';
import '../../../../models/sport_type.dart';

class ScoreboardRow extends StatelessWidget {
  const ScoreboardRow({
    super.key,
    required this.event,
    required this.onTap,
    this.followed = false,
    this.showHeader = true,
  });

  final EventModel event;
  final VoidCallback onTap;
  final bool followed;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final showScore =
        !event.isCombat &&
        (event.status == EventStatus.live ||
            event.status == EventStatus.finished);

    final homeScoreText = showScore ? event.homeScore?.toString() ?? '—' : '—';
    final awayScoreText = showScore ? event.awayScore?.toString() ?? '—' : '—';

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
              if (showHeader) ...[
                _buildHeader(context),
                const SizedBox(height: 7),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Columna 1: Local y visitante, cada uno en su fila con logo y nombre
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _participantRow(
                          event.participant1Name,
                          event.isCombat
                              ? (event.fighter1?.photoUrl ??
                                  event.homeTeam?.logoUrl)
                              : event.homeTeam?.logoUrl,
                        ),
                        const SizedBox(height: 5.5),
                        _participantRow(
                          event.participant2Name,
                          event.isCombat
                              ? (event.fighter2?.photoUrl ??
                                  event.awayTeam?.logoUrl)
                              : event.awayTeam?.logoUrl,
                        ),
                      ],
                    ),
                  ),

                  // Columna 2: Marcador local y visitante, alineado con sus equipos y solo cuando el estado/datos permitan mostrarlo
                  if (!event.isCombat) ...[
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _scoreBox(homeScoreText),
                        const SizedBox(height: 5.5),
                        _scoreBox(awayScoreText),
                      ],
                    ),
                  ],

                  // Columna 3: Minuto real si está en vivo, estado final si terminó u hora de inicio si está programado
                  const SizedBox(width: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 44),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _buildTimeOrStatus(context),
                    ),
                  ),
                ],
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
    var rawLeague = event.league;
    if (event.sport == SportType.soccer) {
      final regex = RegExp(
        r'\b(english|spanish|german|french|dutch)\b',
        caseSensitive: false,
      );
      rawLeague = rawLeague
          .replaceAll(regex, '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(RegExp(r'^[\s\-–—:]+|[\s\-–—:]+$'), '')
          .trim();
      if (rawLeague.isEmpty) rawLeague = event.league;
    }
    final leagueText = rawLeague.toLowerCase().contains(
              event.sport.displayName.toLowerCase(),
            )
        ? rawLeague
        : '${event.sport.displayName} • $rawLeague';

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScaler = MediaQuery.textScalerOf(context);
        final isLargeScale = textScaler.scale(1.0) > 1.25;
        final isNarrow = constraints.maxWidth < 310;

        if (isLargeScale || (isNarrow && leagueText.length > 24)) {
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
              EventStatusChip(status: event.status),
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
            EventStatusChip(status: event.status),
          ],
        );
      },
    );
  }

  Widget _participantRow(String name, String? logo) {
    final fallback = Icon(
      event.sport.icon,
      size: 16,
      color: AppColors.textMuted,
    );
    return SizedBox(
      height: 22,
      child: Row(
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
        ],
      ),
    );
  }

  Widget _scoreBox(String score) {
    return SizedBox(
      height: 22,
      child: Center(
        child: Text(
          score,
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: event.isLive ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeOrStatus(BuildContext context) {
    if (event.isLive) {
      final liveMinute = MatchMinuteFormatter.format(event);
      if (liveMinute != null) {
        return Text(
          liveMinute,
          style: const TextStyle(
            color: AppColors.liveRed,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        );
      }
      return const Text(
        'VIVO',
        style: TextStyle(
          color: AppColors.liveRed,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    if (event.status == EventStatus.finished) {
      return const Text(
        'FINAL',
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    if (event.status == EventStatus.postponed) {
      return Text(
        AppDateFormatter.formatEventTime(event.startTime),
        style: const TextStyle(
          color: AppColors.warning,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    if (event.status == EventStatus.canceled) {
      return const Text(
        'CANC',
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Text(
      AppDateFormatter.formatEventTime(event.startTime),
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
