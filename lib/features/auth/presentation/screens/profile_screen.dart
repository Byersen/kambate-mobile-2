import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/supabase_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isSupabaseConnected = SupabaseService.isInitialized;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Cuenta'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.surfaceDark,
                    child: Icon(Icons.person, size: 30, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Usuario Kambate',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Invitado',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Autenticación disponible en la Fase 4')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Ingresar'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'CONFIGURACIÓN & SISTEMA',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.schedule, color: AppColors.secondary),
                  title: const Text('Zona Horaria'),
                  subtitle: const Text(AppConstants.timeZone),
                ),
                const Divider(height: 1, color: AppColors.cardBorderDark),
                ListTile(
                  leading: Icon(
                    isSupabaseConnected ? Icons.cloud_done : Icons.cloud_queue,
                    color: isSupabaseConnected ? AppColors.success : AppColors.warning,
                  ),
                  title: const Text('Estado de Backend (Supabase)'),
                  subtitle: Text(
                    isSupabaseConnected ? 'Conectado a la nube' : 'Modo local (Mock Data)',
                  ),
                ),
                const Divider(height: 1, color: AppColors.cardBorderDark),
                const ListTile(
                  leading: Icon(Icons.info_outline, color: AppColors.textMuted),
                  title: Text('Versión de la App'),
                  subtitle: Text('1.0.0 (Fase 2: Feed Principal)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
