import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shotbook/features/pro_camera/widgets/ruler_dial.dart';

void main() {
  testWidgets('the ruler follows the finger and settles on a mark', (
    tester,
  ) async {
    final values = <double>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 40,
              child: RulerDial(
                value: 0.5,
                divisions: 30,
                onChanged: values.add,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.drag(find.byType(RulerDial), const Offset(-120, 0));
    await tester.pumpAndSettle();
    expect(values, isNotEmpty);
    expect(values.last, greaterThan(0.5));
    // Every reported value sits on a mark.
    for (final v in values) {
      expect((v * 30 - (v * 30).round()).abs(), lessThan(1e-9));
    }
  });

  testWidgets('a value set from outside glides without reporting back', (
    tester,
  ) async {
    final values = <double>[];
    Widget dial(double v) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 40,
          child: RulerDial(value: v, divisions: 10, onChanged: values.add),
        ),
      ),
    );
    await tester.pumpWidget(dial(0.2));
    await tester.pumpWidget(dial(0.8));
    await tester.pumpAndSettle();
    expect(values, isEmpty);
  });
}
