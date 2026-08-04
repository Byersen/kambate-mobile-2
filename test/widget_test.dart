import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kambate_mobile/main.dart';

void main() {
  testWidgets('KambateApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: KambateApp(),
      ),
    );

    expect(find.text('Kambate Mobile'), findsOneWidget);
  });
}
