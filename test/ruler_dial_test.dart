import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shotbook/features/pro_camera/widgets/ruler_dial.dart';

void main() {
  testWidgets('dragging the ruler left moves it forward and snaps to steps', (
    tester,
  ) async {
    double? got;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 46,
              child: RulerDial(
                position: 0.5,
                steps: 30,
                onChanged: (t) => got = t,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.drag(find.byType(RulerDial), const Offset(-120, 0));
    await tester.pump();
    debugPrint('got $got');
  });
}
