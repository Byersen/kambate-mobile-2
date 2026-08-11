import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kambate_mobile/core/router/app_router.dart';
import 'package:kambate_mobile/main.dart';
import 'package:kambate_mobile/services/cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'kambate_onboarding_completed_v1': true});
    await CacheService.setOnboardingCompleted(true);
  });

  testWidgets('KambateApp renders feed and header', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: KambateApp(router: appRouter),
      ),
    );

    // Pump a finite duration to allow frame build without waiting for infinite pulse animations
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('KAMBATE'), findsOneWidget);
    expect(find.text('HOY'), findsWidgets);
  });
}
