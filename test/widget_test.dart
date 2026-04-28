import 'package:project/features/home/screen/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HomeScreen displays the correct text',
      (WidgetTester tester) async {
    // Build the HomeScreen widget inside a MaterialApp
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );

    // Verify that the "Home Screen" text is shown
    expect(find.text('Home Screen'), findsOneWidget);

    // Verify that there are no other unexpected widgets
    expect(find.byType(Text), findsOneWidget);
    expect(find.byType(Center), findsOneWidget);
  });
}
