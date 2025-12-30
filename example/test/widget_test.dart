import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';

void main() {
  testWidgets('Verify platform version', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LiquidBottleExampleApp());

    // Verify that platform version is retrieved.
    expect(find.text('LIQUID INVENTORY'), findsOneWidget);
  });
}
