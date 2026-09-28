import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:animeapi/main.dart';

void main() {
  testWidgets('Login screen loads and displays login components', (WidgetTester tester) async {
    // Build AnimeApiApp and trigger a frame.
    await tester.pumpWidget(const AnimeApiApp());

    // Verify AnimeAPI header and login button are displayed
    expect(find.text('AnimeAPI'), findsOneWidget);
    expect(find.text('Log In to Dashboard'), findsOneWidget);
  });

  testWidgets('Login passes username to Dashboard and displays Welcome message', (WidgetTester tester) async {
    await tester.pumpWidget(const AnimeApiApp());

    // Enter username
    await tester.enterText(find.byType(TextFormField).first, 'JohnDoe');
    await tester.tap(find.text('Log In to Dashboard'));
    await tester.pumpAndSettle();

    // Verify Welcome message in Dashboard
    expect(find.text('Welcome, JohnDoe!'), findsOneWidget);

    // Switch to Profile tab
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // Verify passed username on Profile tab
    expect(find.text('Welcome, JohnDoe'), findsOneWidget);
    expect(find.text('JohnDoe'), findsOneWidget);
  });
}
