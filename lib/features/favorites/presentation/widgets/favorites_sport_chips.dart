import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/sport_type.dart';
import '../../providers/favorites_provider.dart';

class FavoritesSportChips extends ConsumerWidget {
  const FavoritesSportChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSport = ref.watch(favoritesSportFilterProvider);

    final sports = SportType.values;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sports.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final sport = sports[index];
          final isSelected = selectedSport == sport;

          return _SportTagChip(
            sport: sport,
            isSelected: isSelected,
            onTap: () {
              final notifier = ref.read(favoritesSportFilterProvider.notifier);
              if (notifier.state == sport && sport != SportType.all) {
                notifier.state = SportType.all;
              } else {
                notifier.state = sport;
              }
            },
          );
        },
      ),
    );
  }
}

class _SportTagChip extends StatelessWidget {
  final SportType sport;
  final bool isSelected;
  final VoidCallback onTap;

  const _SportTagChip({
    required this.sport,
    required this.isSelected,
    required this.onTap,
  });

  String _getLabel() {
    switch (sport) {
      case SportType.all:
        return 'Todos';
      case SportType.soccer:
        return 'Fútbol';
      case SportType.nba:
        return 'NBA';
      case SportType.ufc:
        return 'UFC';
      case SportType.lol:
        return 'LoL';
      case SportType.valorant:
        return 'Valorant';
    }
  }

  IconData _getIcon() {
    if (sport == SportType.all) return Icons.public;
    return sport.icon;
  }

  @override
  Widget build(BuildContext context) {
    final chipColor = sport.color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? chipColor.withValues(alpha: 0.12)
                : AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? chipColor : AppColors.cardBorderDark,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIcon(),
                size: 15,
                color: isSelected ? chipColor : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                _getLabel(),
                style: TextStyle(
                  color: isSelected ? chipColor : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
