import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/sport_type.dart';

class SportFilterBar extends StatelessWidget {
  const SportFilterBar({
    super.key,
    required this.selectedSport,
    required this.onSportSelected,
    this.availableSports,
  });
  final SportType selectedSport;
  final ValueChanged<SportType> onSportSelected;
  final Iterable<SportType>? availableSports;

  static const List<SportType> supportedSports = [
    SportType.soccer,
    SportType.nba,
    SportType.ufc,
    SportType.lol,
    SportType.valorant,
  ];

  @override
  Widget build(BuildContext context) {
    final allowedSet = availableSports
        ?.where((s) => s != SportType.all)
        .toSet();
    final sportsToShow = (allowedSet != null && allowedSet.isNotEmpty)
        ? supportedSports.where(allowedSet.contains).toList()
        : supportedSports;

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < sportsToShow.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Builder(
                builder: (context) {
                  final sport = sportsToShow[i];
                  final selected = sport == selectedSport;
                  final label = switch (sport) {
                    SportType.ufc => 'UFC',
                    SportType.lol => 'LoL',
                    _ => sport.displayName,
                  };
                  return Semantics(
                    selected: selected,
                    button: true,
                    child: InkWell(
                      onTap: () => onSportSelected(sport),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 62,
                          minHeight: 76,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.09)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              sport.icon,
                              size: 25,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
