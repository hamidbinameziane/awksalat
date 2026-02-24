import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awksalat/main.dart';

void main() {
  testWidgets('PrayerScreen builds and shows loading or data', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SalatApp());

    // Initially it might show a loading indicator.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Since we can't easily mock rootBundle in a simple widget test without more setup,
    // we just verify it starts correctly.
  });
}
