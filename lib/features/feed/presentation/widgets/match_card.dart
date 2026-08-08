import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../models/event_model.dart';
import '../../../../models/event_status.dart';
import '../../../../models/sport_type.dart';
import 'live_badge.dart';

class MatchCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  const MatchCard({
    super.key,
    required this.event,
    this.onTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isEsports = event.sport == SportType.lol || event.sport == SportType.valorant;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      elevation: event.isLive ? 2.5 : 1.0,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: event.sport.color,
                width: 3.5,
              ),
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header: Sport badge, League Name with Tier, and Status/Time
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: event.sport.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(event.sport.icon, size: 12, color: event.sport.color),
                        const SizedBox(width: 4),
                        Text(
                          event.sport.displayName.toUpperCase(),
                          style: TextStyle(
                            color: event.sport.color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // League Name & Tier Badge
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            event.league,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (event.leagueModel != null) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: event.leagueModel!.isTier1
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : AppColors.surfaceDark,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: event.leagueModel!.isTier1
                                    ? AppColors.primary.withValues(alpha: 0.4)
                                    : AppColors.cardBorderDark,
                                width: 0.7,
                              ),
                            ),
                            child: Text(
                              event.leagueModel!.isTier1 ? 'T1' : 'T2',
                              style: TextStyle(
                                color: event.leagueModel!.isTier1
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Status Indicator or Time
                  if (event.isLive)
                    LiveBadge(text: event.currentPeriod ?? 'EN VIVO')
                  else if (event.status == EventStatus.finished)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.cardBorderDark,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'FINAL',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Text(
                      AppDateFormatter.formatEventTime(event.startTime),
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                  const SizedBox(width: 4),

                  // Star / Bookmark Toggle
                  IconButton(
                    icon: Icon(
                      event.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: event.isFavorite ? AppColors.warning : AppColors.textMuted,
                      size: 20,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onFavoriteToggle,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 2. Match Body (Adaptive by Sport Type)
              if (event.isCombat)
                _buildCombatBody(context)
              else if (isEsports)
                _buildEsportsBody(context)
              else
                _buildTeamBody(context),

              // 3. Footer (Venue or Esports Format)
              if (event.venue != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
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
        ),
      ),
    );
  }

  Widget _buildTeamBody(BuildContext context) {
    return Column(
      children: [
        // Home Team
        Row(
          children: [
            _buildAvatar(event.homeTeam?.name ?? 'Local', event.homeTeam?.logoUrl),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                event.homeTeam?.name ?? 'Local',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (event.homeScore != null)
              Text(
                '${event.homeScore}',
                style: TextStyle(
                  color: event.isLive ? AppColors.primary : AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Away Team
        Row(
          children: [
            _buildAvatar(event.awayTeam?.name ?? 'Visitante', event.awayTeam?.logoUrl),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                event.awayTeam?.name ?? 'Visitante',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (event.awayScore != null)
              Text(
                '${event.awayScore}',
                style: TextStyle(
                  color: event.isLive ? AppColors.primary : AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildEsportsBody(BuildContext context) {
    final format = event.esportsStats?.format ?? 'Bo3';

    return Column(
      children: [
        // Format & Current Map Bar
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SERIE $format',
                style: TextStyle(
                  color: event.sport.color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              if (event.esportsStats?.currentMap != null)
                Text(
                  event.esportsStats!.currentMap!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),

        // Team 1
        Row(
          children: [
            _buildAvatar(event.homeTeam?.name ?? 'Equipo 1', event.homeTeam?.logoUrl),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                event.homeTeam?.name ?? 'Equipo 1',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (event.homeScore != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: event.isLive ? event.sport.color.withValues(alpha: 0.2) : AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${event.homeScore}',
                  style: TextStyle(
                    color: event.isLive ? event.sport.color : AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Team 2
        Row(
          children: [
            _buildAvatar(event.awayTeam?.name ?? 'Equipo 2', event.awayTeam?.logoUrl),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                event.awayTeam?.name ?? 'Equipo 2',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (event.awayScore != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: event.isLive ? event.sport.color.withValues(alpha: 0.2) : AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${event.awayScore}',
                  style: TextStyle(
                    color: event.isLive ? event.sport.color : AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCombatBody(BuildContext context) {
    return Row(
      children: [
        // Fighter 1
        Expanded(
          child: Column(
            children: [
              _buildAvatar(event.fighter1?.name ?? 'Peleador 1', event.fighter1?.photoUrl, isLarge: true),
              const SizedBox(height: 6),
              Text(
                event.fighter1?.name ?? 'Peleador 1',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (event.fighter1?.record != null)
                Text(
                  event.fighter1!.record!,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
            ],
          ),
        ),

        // VS or Result
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cardBorderDark.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            event.fightResult ?? 'VS',
            style: TextStyle(
              color: event.fightResult != null ? AppColors.primary : AppColors.secondary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),

        // Fighter 2
        Expanded(
          child: Column(
            children: [
              _buildAvatar(event.fighter2?.name ?? 'Peleador 2', event.fighter2?.photoUrl, isLarge: true),
              const SizedBox(height: 6),
              Text(
                event.fighter2?.name ?? 'Peleador 2',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

  Widget _buildAvatar(String name, String? imageUrl, {bool isLarge = false}) {
    final size = isLarge ? 38.0 : 24.0;
    final initials = name.isNotEmpty
        ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        shape: BoxShape.circle,
        border: Border.all(
          color: event.sport.color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: event.sport.color,
          fontSize: isLarge ? 12 : 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
