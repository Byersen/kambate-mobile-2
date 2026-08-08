import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kambate_mobile/core/router/app_router.dart';
import 'package:kambate_mobile/main.dart';

void main() {
  testWidgets('KambateApp renders feed and header', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: KambateApp(router: appRouter),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('KAMBATE'), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Fútbol'), findsOneWidget);
  });
}
