import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_cctv/main.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // Mock SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CCTVApp());

    // Verify that the app builds successfully (MaterialApp is in the widget tree)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
