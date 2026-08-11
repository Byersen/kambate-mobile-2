import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class StatComparisonBar extends StatelessWidget {
  final String label;
  final String homeValueText;
  final String awayValueText;
  final double homeRatio;
  final Color? accentColor;

  const StatComparisonBar({
    super.key,
    required this.label,
    required this.homeValueText,
    required this.awayValueText,
    required this.homeRatio,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    final clampedRatio = homeRatio.clamp(0.05, 0.95);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                homeValueText,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                awayValueText,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Expanded(
                    flex: (clampedRatio * 100).toInt(),
                    child: Container(
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: ((1 - clampedRatio) * 100).toInt(),
                    child: Container(
                      color: AppColors.cardBorderDark.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
