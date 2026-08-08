import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/connection_provider.dart';

class SyncStatusBadge extends ConsumerWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectionStatusProvider);

    Color dotColor;
    String label;
    IconData icon;

    switch (status) {
      case ConnectionStatus.liveConnected:
        dotColor = AppColors.primary;
        label = 'En Vivo • Realtime';
        icon = Icons.wifi_rounded;
        break;
      case ConnectionStatus.syncing:
        dotColor = AppColors.secondary;
        label = 'Sincronizando...';
        icon = Icons.sync_rounded;
        break;
      case ConnectionStatus.offlineCached:
        dotColor = AppColors.warning;
        label = 'Modo Offline (Caché)';
        icon = Icons.cloud_off_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dotColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: dotColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: dotColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
