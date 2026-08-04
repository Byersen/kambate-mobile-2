import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../feed/presentation/widgets/match_card.dart';
import '../../../feed/providers/feed_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Favoritos'),
      ),
      body: favorites.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_border_rounded, size: 56, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text(
                    'No tienes eventos favoritos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Toca la estrella en cualquier partido para seguirlo aquí.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final event = favorites[index];
                return MatchCard(
                  event: event,
                  onTap: () => context.push('/detail/${event.id}', extra: event),
                  onFavoriteToggle: () => ref.read(feedNotifierProvider.notifier).toggleFavorite(event.id),
                );
              },
            ),
    );
  }
}
