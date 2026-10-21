import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/cache_service.dart';
import 'services/supabase_service.dart';

import 'features/feed/providers/feed_provider.dart';

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

class KambateApp extends ConsumerStatefulWidget {
  final dynamic router;

  const KambateApp({super.key, required this.router});

  @override
  ConsumerState<KambateApp> createState() => _KambateAppState();
}

class _KambateAppState extends ConsumerState<KambateApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(feedNotifierProvider.notifier).onAppResumed();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      ref.read(feedNotifierProvider.notifier).onAppPaused();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Kambate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: widget.router,
    );
  }
}
