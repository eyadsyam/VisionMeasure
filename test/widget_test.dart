import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vision_measure/features/manual_entry/widgets/stepper_field.dart';

void main() {
  testWidgets('StepperField increments and decrements', (tester) async {
    double value = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => StepperField(
              label: 'Sphere',
              value: value,
              min: -5,
              max: 5,
              step: 0.25,
              suffix: ' D',
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      ),
    );

    expect(find.text('0.00 D'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    expect(find.text('0.25 D'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.remove_rounded));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.remove_rounded));
    await tester.pump();
    expect(find.text('-0.25 D'), findsOneWidget);
  });
}
