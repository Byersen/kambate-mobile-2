import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/searchable_team_item.dart';

class TeamSearchCard extends StatelessWidget {
  final SearchableTeamItem team;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onTap;

  const TeamSearchCard({
    super.key,
    required this.team,
    required this.isFavorite,
    required this.onToggleFavorite,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sportColor = team.sport.color;
    final initials = team.name.isNotEmpty
        ? team.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : '?';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFavorite
              ? sportColor.withValues(alpha: 0.4)
              : AppColors.cardBorderDark,
          width: isFavorite ? 1.2 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: sportColor.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: sportColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              team.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: sportColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              team.sport.displayName.toUpperCase(),
                              style: TextStyle(
                                color: sportColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              team.league,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (team.record != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              team.record!,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                      key: ValueKey<bool>(isFavorite),
                      color: isFavorite ? AppColors.warning : AppColors.textMuted,
                      size: 24,
                    ),
                  ),
                  tooltip: isFavorite ? 'Dejar de seguir' : 'Seguir equipo',
                  onPressed: onToggleFavorite,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
