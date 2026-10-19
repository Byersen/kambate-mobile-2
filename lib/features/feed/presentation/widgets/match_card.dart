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
  final bool isFollowed;

  const MatchCard({
    super.key,
    required this.event,
    this.onTap,
    this.isFollowed = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEsports = event.sport == SportType.lol || event.sport == SportType.valorant;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      clipBehavior: Clip.antiAlias,
      elevation: event.isLive ? 2.5 : 1.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isFollowed
            ? BorderSide(
                color: AppColors.primary.withValues(alpha: 0.6),
                width: 1.2,
              )
            : BorderSide.none,
      ),
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
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: event.sport.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(event.sport.icon, size: 11, color: event.sport.color),
                        const SizedBox(width: 4),
                        Text(
                          event.sport.displayName.toUpperCase(),
                          style: TextStyle(
                            color: event.sport.color,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),

                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            event.league,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
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
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (isFollowed) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bookmark_rounded, size: 10, color: AppColors.primary),
                          SizedBox(width: 2),
                          Text(
                            'SIGUIENDO',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (event.isLive)
                    LiveBadge(text: event.currentPeriod ?? 'EN VIVO')
                  else if (event.status == EventStatus.finished)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.cardBorderDark,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        'FINAL',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9.5,
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
                ],
              ),

              const SizedBox(height: 11),

              if (event.isCombat)
                _buildCombatBody(context)
              else if (isEsports)
                _buildEsportsBody(context)
              else
                _buildTeamBody(context),

              // 3. Footer (Venue or Esports Format)
              if (event.venue != null) ...[
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      event.venue!,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10.5,
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
        Row(
          children: [
            _buildAvatar(event.homeTeam?.name ?? 'Local', event.homeTeam?.logoUrl),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                event.homeTeam?.name ?? 'Local',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
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
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            _buildAvatar(event.awayTeam?.name ?? 'Visitante', event.awayTeam?.logoUrl),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                event.awayTeam?.name ?? 'Visitante',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
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
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildEsportsBody(BuildContext context) {
    final format = event.esportsStats?.format?.trim();
    final formatLabel = format != null && format.isNotEmpty ? 'SERIE $format' : 'SERIE';

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 7),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatLabel,
                style: TextStyle(
                  color: event.sport.color,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
              if (event.esportsStats?.currentMap != null)
                Text(
                  event.esportsStats!.currentMap!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9.5,
                  ),
                ),
            ],
          ),
        ),

        Row(
          children: [
            _buildAvatar(event.homeTeam?.name ?? 'Equipo 1', event.homeTeam?.logoUrl),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                event.homeTeam?.name ?? 'Equipo 1',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (event.homeScore != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: event.isLive
                      ? event.sport.color.withValues(alpha: 0.2)
                      : AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${event.homeScore}',
                  style: TextStyle(
                    color: event.isLive ? event.sport.color : AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 7),

        Row(
          children: [
            _buildAvatar(event.awayTeam?.name ?? 'Equipo 2', event.awayTeam?.logoUrl),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                event.awayTeam?.name ?? 'Equipo 2',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (event.awayScore != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: event.isLive
                      ? event.sport.color.withValues(alpha: 0.2)
                      : AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${event.awayScore}',
                  style: TextStyle(
                    color: event.isLive ? event.sport.color : AppColors.textPrimary,
                    fontSize: 15,
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
        Expanded(
          child: Column(
            children: [
              _buildAvatar(
                  event.fighter1?.name ?? 'Peleador 1', event.fighter1?.photoUrl,
                  isLarge: true),
              const SizedBox(height: 5),
              Text(
                event.fighter1?.name ?? 'Peleador 1',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (event.fighter1?.record != null)
                Text(
                  event.fighter1!.record!,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5),
                ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
          decoration: BoxDecoration(
            color: AppColors.cardBorderDark.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            event.fightResult ?? 'VS',
            style: TextStyle(
              color: event.fightResult != null ? AppColors.primary : AppColors.secondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),

        Expanded(
          child: Column(
            children: [
              _buildAvatar(
                  event.fighter2?.name ?? 'Peleador 2', event.fighter2?.photoUrl,
                  isLarge: true),
              const SizedBox(height: 5),
              Text(
                event.fighter2?.name ?? 'Peleador 2',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (event.fighter2?.record != null)
                Text(
                  event.fighter2!.record!,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(String name, String? imageUrl, {bool isLarge = false}) {
    final size = isLarge ? 36.0 : 22.0;
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
          fontSize: isLarge ? 11.5 : 9.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
