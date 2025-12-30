import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:liquid_bottle/liquid_bottle.dart';

void main() {
  test('adds one to input values', () {
    // Basic unit test for BottleType
    const bottle = BottleType(
      id: "test",
      name: "Test",
      volumeMl: 100,
      imperialVol: "3oz",
      aspectRatio: 1.0,
    );
    expect(bottle.volumeMl, 100);
  });

  testWidgets('LiquidBottleSlider renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 100,
            height: 200,
            child: LiquidBottleSlider(
              bottleType: BottleType.standards.first,
              value: 0.5,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(LiquidBottleSlider), findsOneWidget);
  });
}
