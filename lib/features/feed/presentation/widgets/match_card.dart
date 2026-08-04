import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/event_model.dart';
import '../../../../models/event_status.dart';
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
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('dd MMM');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
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
              // Header: Sport badge, League, and Status/Time
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
                  Expanded(
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
                      '${dateFormat.format(event.startTime)} • ${timeFormat.format(event.startTime)}',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(width: 4),
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

              // Match Body (Team vs Team or Fighter vs Fighter)
              if (event.isCombat)
                _buildCombatBody(context)
              else
                _buildTeamBody(context),

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

        // VS or Status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cardBorderDark.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            event.fightResult ?? 'VS',
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 12,
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
          color: AppColors.cardBorderDark,
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
