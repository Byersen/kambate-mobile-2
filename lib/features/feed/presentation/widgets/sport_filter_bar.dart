import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/sport_type.dart';

class SportFilterBar extends StatelessWidget {
  final SportType selectedSport;
  final ValueChanged<SportType> onSportSelected;

  const SportFilterBar({
    super.key,
    required this.selectedSport,
    required this.onSportSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: SportType.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final sport = SportType.values[index];
          final isSelected = selectedSport == sport;

          return InkWell(
            onTap: () => onSportSelected(sport),
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? sport.color.withValues(alpha: 0.18)
                    : AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? sport.color
                      : AppColors.cardBorderDark.withValues(alpha: 0.6),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    sport.icon,
                    size: 16,
                    color: isSelected ? sport.color : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    sport.displayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
