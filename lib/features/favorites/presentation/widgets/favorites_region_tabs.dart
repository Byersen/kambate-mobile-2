import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/favorites_provider.dart';

const List<String> kSearchRegions = [
  'Todos',
  'Europa',
  'Sudamérica',
  'Norteamérica',
  'Internacional',
];

class FavoritesRegionTabs extends ConsumerWidget {
  const FavoritesRegionTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRegion = ref.watch(favoritesRegionFilterProvider);

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: kSearchRegions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final region = kSearchRegions[index];
          final isSelected = selectedRegion == region;

          return InkWell(
            onTap: () {
              ref.read(favoritesRegionFilterProvider.notifier).state = region;
            },
            borderRadius: BorderRadius.circular(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  region,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 2.5,
                  width: isSelected ? 24 : 0,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
