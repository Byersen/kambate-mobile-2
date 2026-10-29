import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/match_minute_formatter.dart';
import '../../../../models/event_model.dart';
import '../../../../models/event_status.dart';
import '../../../feed/presentation/widgets/live_badge.dart';

class MatchHeaderHero extends StatelessWidget {
  final EventModel event;

  const MatchHeaderHero({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final sportColor = event.sport.color;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: sportColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            sportColor.withValues(alpha: 0.18),
            AppColors.surfaceDark,
          ],
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: sportColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(event.sport.icon, size: 12, color: sportColor),
                    const SizedBox(width: 4),
                    Text(
                      event.sport.displayName.toUpperCase(),
                      style: TextStyle(
                        color: sportColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  event.league,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (event.leagueModel != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: event.leagueModel!.isTier1
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : AppColors.cardDark,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: event.leagueModel!.isTier1
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.cardBorderDark,
                    ),
                  ),
                  child: Text(
                    event.leagueModel!.isTier1 ? 'TIER 1' : 'TIER 2',
                    style: TextStyle(
                      color: event.leagueModel!.isTier1 ? AppColors.primary : AppColors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          if (event.isCombat)
            _buildCombatScoreboard(sportColor)
          else
            _buildTeamScoreboard(sportColor),

          const SizedBox(height: 14),

          if (event.isLive)
            LiveBadge(
              text: MatchMinuteFormatter.format(event) ??
                  event.currentPeriod ??
                  'EN VIVO',
            )
          else if (event.status == EventStatus.finished)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorderDark),
              ),
              child: const Text(
                'FINALIZADO',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            )
          else
            Text(
              AppDateFormatter.formatFullDate(event.startTime),
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),

          if (event.venue != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  event.venue!,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamScoreboard(Color sportColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            children: [
              _buildAvatar(event.homeTeam?.name ?? 'Local', sportColor, isLarge: true),
              const SizedBox(height: 8),
              Text(
                event.homeTeam?.name ?? 'Local',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: event.homeScore != null && event.awayScore != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sportColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${event.homeScore} - ${event.awayScore}',
                    style: TextStyle(
                      color: event.isLive ? AppColors.primary : AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'VS',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
        ),

        Expanded(
          child: Column(
            children: [
              _buildAvatar(event.awayTeam?.name ?? 'Visitante', sportColor, isLarge: true),
              const SizedBox(height: 8),
              Text(
                event.awayTeam?.name ?? 'Visitante',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCombatScoreboard(Color sportColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: Column(
            children: [
              _buildAvatar(event.fighter1?.name ?? 'Peleador 1', sportColor, isLarge: true),
              const SizedBox(height: 6),
              Text(
                event.fighter1?.name ?? 'Peleador 1',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (event.fighter1?.nickname != null)
                Text(
                  '"${event.fighter1!.nickname}"',
                  style: TextStyle(
                    color: sportColor,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              if (event.fighter1?.record != null)
                Text(
                  event.fighter1!.record!,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sportColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            event.fightResult ?? 'VS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: event.fightResult != null ? AppColors.primary : AppColors.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),

        Expanded(
          child: Column(
            children: [
              _buildAvatar(event.fighter2?.name ?? 'Peleador 2', sportColor, isLarge: true),
              const SizedBox(height: 6),
              Text(
                event.fighter2?.name ?? 'Peleador 2',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (event.fighter2?.nickname != null)
                Text(
                  '"${event.fighter2!.nickname}"',
                  style: TextStyle(
                    color: sportColor,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              if (event.fighter2?.record != null)
                Text(
                  event.fighter2!.record!,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(String name, Color sportColor, {bool isLarge = false}) {
    final size = isLarge ? 50.0 : 34.0;
    final initials = name.isNotEmpty
        ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        shape: BoxShape.circle,
        border: Border.all(color: sportColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: sportColor.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: sportColor,
          fontSize: isLarge ? 16 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
