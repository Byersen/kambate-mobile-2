import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/feed_provider.dart';

class LeagueTierSelector extends ConsumerWidget {
  const LeagueTierSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTier = ref.watch(selectedLeagueTierProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorderDark, width: 0.8),
      ),
      child: Row(
        children: [
          _TierButton(
            title: 'Todas las Ligas',
            isSelected: selectedTier == null,
            onTap: () => ref.read(selectedLeagueTierProvider.notifier).state = null,
          ),
          _TierButton(
            title: 'Tier 1 (Élite)',
            isSelected: selectedTier == 1,
            onTap: () => ref.read(selectedLeagueTierProvider.notifier).state = 1,
          ),
          _TierButton(
            title: 'Tier 2 (Secundarias)',
            isSelected: selectedTier == 2,
            onTap: () => ref.read(selectedLeagueTierProvider.notifier).state = 2,
          ),
        ],
      ),
    );
  }
}

class _TierButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _TierButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.cardDark : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1)
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
