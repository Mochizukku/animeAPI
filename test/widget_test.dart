import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:animeapi/main.dart';
import 'package:animeapi/models/anime.dart';
import 'package:animeapi/screens/browse_screen.dart';

void main() {
  testWidgets('Dashboard loads directly and displays components', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AnimeApiApp());
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Dashboard title and category chips are displayed
    expect(find.text('Anime Dashboard'), findsOneWidget);
    expect(find.text('Top Anime'), findsWidgets);
    expect(find.text('This Season'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
  });

  testWidgets('Dashboard shows Browse, My List, and History destinations', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AnimeApiApp());
    await tester.pump(const Duration(milliseconds: 500));

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
