import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/anime.dart';

class ApiService {
  static const String _baseUrl = 'https://api.jikan.moe/v4';

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<List<Anime>> fetchTopAnime() async {
    try {
      final url = Uri.parse('$_baseUrl/top/anime?limit=25');
      final response = await http
          .get(
            url,
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'FlutterAnimeApp/1.0',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['data'] as List<dynamic>?;
        if (list != null) {
          return list
              .whereType<Map<String, dynamic>>()
              .map((item) => Anime.fromJson(item))
              .toList();
        }
      }
    } catch (_) {
      // Return fallback items if network request fails or times out
    }

    return _fallbackAnimeList;
  }

  Future<List<Anime>> searchAnime(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return [];
    }

    final url = Uri.https('api.jikan.moe', '/v4/anime', {
      'q': trimmedQuery,
      'limit': '10',
    });
    try {
      final response = await _getWithRetry(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['data'] as List<dynamic>? ?? [];
        return list
            .whereType<Map<String, dynamic>>()
            .map(Anime.fromJson)
            .toList();
      }
    } on TimeoutException {
      // Fall back to AniList when Jikan is temporarily unavailable.
    }

    return _searchAniList(trimmedQuery);
  }

  Future<http.Response> _getWithRetry(Uri url) async {
    const retryableStatusCodes = {429, 500, 502, 503, 504};
    const maxAttempts = 3;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final response = await http
            .get(
              url,
              headers: {
                'Accept': 'application/json',
                'User-Agent': 'FlutterAnimeApp/1.0',
              },
            )
            .timeout(const Duration(seconds: 10));

        if (!retryableStatusCodes.contains(response.statusCode) ||
            attempt == maxAttempts - 1) {
          return response;
        }
      } on TimeoutException {
        if (attempt == maxAttempts - 1) {
          rethrow;
        }
      }

      await Future<void>.delayed(Duration(seconds: attempt + 1));
    }

    throw StateError('Search request could not be completed.');
  }

  Future<List<Anime>> _searchAniList(String query) async {
    const searchQuery = r'''
      query ($search: String!) {
        Page(perPage: 10) {
          media(search: $search, type: ANIME, isAdult: false) {
            id
            idMal
            title { romaji english }
            coverImage { large medium }
            averageScore
            episodes
            description
            format
            genres
          }
        }
      }
    ''';
    final response = await http
        .post(
          Uri.parse('https://graphql.anilist.co'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'query': searchQuery,
            'variables': {'search': query},
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Unable to search anime.');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    final page = data?['Page'] as Map<String, dynamic>?;
    final media = page?['media'] as List<dynamic>? ?? [];
    return media
        .whereType<Map<String, dynamic>>()
        .map(Anime.fromAniListJson)
        .toList();
  }

  static final List<Anime> _fallbackAnimeList = [
    const Anime(
      malId: 52991,
      title: 'Sousou no Frieren',
      titleEnglish: "Frieren: Beyond Journey's End",
      imageUrl: 'https://cdn.myanimelist.net/images/anime/1015/138006l.jpg',
      score: 9.32,
      episodes: 28,
      type: 'TV',
      synopsis:
          "During their decade-long quest to defeat the Demon King, the members of the hero's party forge deep bonds. After victory, elven mage Frieren witnesses her companions pass away, leading her on a new journey to understand humanity.",
      genres: ['Adventure', 'Drama', 'Fantasy'],
    ),
    const Anime(
      malId: 50265,
      title: 'Spy x Family',
      titleEnglish: 'SPY x FAMILY',
      imageUrl: 'https://cdn.myanimelist.net/images/anime/1441/122795l.jpg',
      score: 8.50,
      episodes: 25,
      type: 'TV',
      synopsis:
          'Master spy Twilight creates a fabricated family to infiltrate an elite school: an assassin wife and a telepathic daughter.',
      genres: ['Action', 'Comedy'],
    ),
    const Anime(
      malId: 5114,
      title: 'Fullmetal Alchemist: Brotherhood',
      titleEnglish: 'Fullmetal Alchemist: Brotherhood',
      imageUrl: 'https://cdn.myanimelist.net/images/anime/1208/94745l.jpg',
      score: 9.09,
      episodes: 64,
      type: 'TV',
      synopsis:
          'Two brothers embark on a search for the Philosopher\'s Stone to restore their bodies after a disastrous attempt at human transmutation.',
      genres: ['Action', 'Adventure', 'Drama', 'Fantasy'],
    ),
    const Anime(
      malId: 40748,
      title: 'Jujutsu Kaisen',
      titleEnglish: 'Jujutsu Kaisen',
      imageUrl: 'https://cdn.myanimelist.net/images/anime/1171/109222l.jpg',
      score: 8.58,
      episodes: 24,
      type: 'TV',
      synopsis:
          'High school student Yuji Itadori swallows a cursed talisman and becomes host to the King of Curses, entering the supernatural world of jujutsu sorcery.',
      genres: ['Action', 'Fantasy'],
    ),
  ];
}
