import 'package:flutter_test/flutter_test.dart';

import 'package:garagum_racing/main.dart';

void main() {
  testWidgets('App builds without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const GaragumRacingApp());
    await tester.pump();
  });
}
