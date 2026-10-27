import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/search_league_item.dart';
import '../../providers/favorites_provider.dart';

class LeagueSearchCard extends ConsumerWidget {
  final SearchLeagueItem league;
  final VoidCallback? onTap;

  const LeagueSearchCard({
    super.key,
    required this.league,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followedLeagues = ref.watch(followedLeaguesProvider);
    final isFavorite = followedLeagues.contains(league.name.toLowerCase());
    final effectiveColor = league.color ?? league.sport.color;
    final effectiveIcon = league.icon ?? league.sport.icon;
    final hasLogo = league.logoUrl != null && league.logoUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderDark),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap ??
              () {
                final queryParams = <String, String>{};
                if (league.slug != null && league.slug!.isNotEmpty) {
                  queryParams['slug'] = league.slug!;
                }
                final queryStr = queryParams.isNotEmpty
                    ? '?${Uri(queryParameters: queryParams).query}'
                    : '';
                context.push(
                  '/league/${Uri.encodeComponent(league.name)}$queryStr',
                  extra: league.sport,
                );
              },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: hasLogo ? Colors.white : effectiveColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: hasLogo
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      padding: hasLogo ? const EdgeInsets.all(4) : EdgeInsets.zero,
                      alignment: Alignment.center,
                      child: hasLogo
                          ? Image.network(
                              league.logoUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                effectiveIcon,
                                size: 20,
                                color: effectiveColor,
                              ),
                            )
                          : Icon(
                              effectiveIcon,
                              size: 20,
                              color: effectiveColor,
                            ),
                    ),
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: isFavorite ? AppColors.warning : AppColors.textMuted,
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 18,
                      onPressed: () {
                        ref.read(followedLeaguesProvider.notifier).toggle(league.name);
                      },
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      league.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (league.isCompetition) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'TORNEO',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        Expanded(
                          child: Text(
                            league.subtitle,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
