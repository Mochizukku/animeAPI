import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:animeapi/main.dart';
import 'package:animeapi/models/anime.dart';
import 'package:animeapi/screens/browse_screen.dart';

void main() {
  testWidgets('Login screen loads and displays login components', (
    WidgetTester tester,
  ) async {
    // Build AnimeApiApp and trigger a frame.
    await tester.pumpWidget(const AnimeApiApp());

    // Verify AnimeAPI header and login button are displayed
    expect(find.text('AnimeAPI'), findsOneWidget);
    expect(find.text('Log In to Dashboard'), findsOneWidget);
  });

  testWidgets(
    'Login passes username to Dashboard and displays Welcome message',
    (WidgetTester tester) async {
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
    },
  );

  testWidgets('Dashboard shows Browse, My List, and History destinations', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AnimeApiApp());

    await tester.enterText(find.byType(TextFormField).first, 'JohnDoe');
    await tester.tap(find.text('Log In to Dashboard'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    expect(find.text('Search for an anime to get started.'), findsOneWidget);

    await tester.tap(find.text('My List'));
    await tester.pumpAndSettle();
    expect(find.text('Your saved anime will appear here.'), findsOneWidget);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Anime you open will appear here.'), findsOneWidget);
  });

  testWidgets('Browse displays anime that matches entered search text', (
    WidgetTester tester,
  ) async {
    const naruto = Anime(malId: 20, title: 'Naruto', imageUrl: '');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BrowseScreen(
            onAnimeSelected: (_) {},
            searchAnime: (query) async => query == 'Naruto' ? [naruto] : [],
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Naruto');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsOneWidget);
  });
}
