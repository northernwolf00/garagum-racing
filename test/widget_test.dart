import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:garagum_racing/main.dart';

void main() {
  testWidgets('App builds without throwing', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const GaragumRacingApp());
    await tester.pump(const Duration(milliseconds: 500));
  });
}
