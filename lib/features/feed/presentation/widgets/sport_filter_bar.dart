import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/sport_type.dart';

class SportFilterBar extends StatelessWidget {
  const SportFilterBar({
    super.key,
    required this.selectedSport,
    required this.onSportSelected,
  });
  final SportType selectedSport;
  final ValueChanged<SportType> onSportSelected;

  static const List<SportType> supportedSports = [
    SportType.soccer,
    SportType.nba,
    SportType.ufc,
    SportType.lol,
    SportType.valorant,
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: supportedSports.map((sport) {
          final selected = sport == selectedSport;
          final label = switch (sport) {
            SportType.ufc => 'UFC',
            SportType.lol => 'LoL',
            _ => sport.displayName,
          };
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Semantics(
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
            ),
          );
        }).toList(),
      ),
    );
  }
}
