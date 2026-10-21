import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/cache_service.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('SupabaseService.initialize error: $e');
  }

  bool onboardingCompleted = false;
  try {
    onboardingCompleted = await CacheService.isOnboardingCompleted();
  } catch (e) {
    debugPrint('CacheService.isOnboardingCompleted error: $e');
  }

  final String initialLocation = onboardingCompleted ? '/feed' : '/onboarding';
  final router = createRouter(initialLocation: initialLocation);

  runApp(ProviderScope(child: KambateApp(router: router)));
}

class KambateApp extends StatelessWidget {
  final dynamic router;

  const KambateApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Kambate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
