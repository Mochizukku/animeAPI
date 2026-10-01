import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animeapi/models/anime.dart';
import 'package:animeapi/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('round-trips Anime toJson and fromJson', () {
      const anime = Anime(
        malId: 52991,
        title: 'Sousou no Frieren',
        titleEnglish: "Frieren: Beyond Journey's End",
        imageUrl: 'https://example.com/frieren.jpg',
        score: 9.32,
        episodes: 28,
        synopsis: 'Elven mage Frieren journeys...',
        type: 'TV',
        genres: ['Adventure', 'Drama'],
      );

      final json = anime.toJson();
      final restored = Anime.fromJson(json);

      expect(restored.malId, anime.malId);
      expect(restored.title, anime.title);
      expect(restored.titleEnglish, anime.titleEnglish);
      expect(restored.imageUrl, anime.imageUrl);
      expect(restored.score, anime.score);
      expect(restored.episodes, anime.episodes);
      expect(restored.synopsis, anime.synopsis);
      expect(restored.type, anime.type);
      expect(restored.genres, anime.genres);
    });

    test('saves and loads watch history', () async {
      const storage = StorageService();
      const anime = Anime(
        malId: 101,
        title: 'Watched Anime',
        imageUrl: 'https://example.com/img.jpg',
      );

      await storage.saveWatchHistory([anime]);
      final loaded = await storage.loadWatchHistory();

      expect(loaded.length, 1);
      expect(loaded.first.malId, 101);
      expect(loaded.first.title, 'Watched Anime');
    });

    test('saves and loads saved anime (My List)', () async {
      const storage = StorageService();
      const anime = Anime(
        malId: 202,
        title: 'Saved Anime',
        imageUrl: 'https://example.com/img2.jpg',
      );

      await storage.saveSavedAnime([anime]);
      final loaded = await storage.loadSavedAnime();

      expect(loaded.length, 1);
      expect(loaded.first.malId, 202);
      expect(loaded.first.title, 'Saved Anime');
    });

    test('clears all data', () async {
      const storage = StorageService();
      const anime = Anime(
        malId: 303,
        title: 'Temporary Anime',
        imageUrl: 'https://example.com/303.jpg',
      );

      await storage.saveWatchHistory([anime]);
      await storage.saveSavedAnime([anime]);

      expect((await storage.loadWatchHistory()).length, 1);
      expect((await storage.loadSavedAnime()).length, 1);

      await storage.clearAll();

      expect((await storage.loadWatchHistory()).isEmpty, isTrue);
      expect((await storage.loadSavedAnime()).isEmpty, isTrue);
    });
  });
}
