import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/anime.dart';

class _CachedResponse {
  final String body;
  final DateTime timestamp;

  _CachedResponse(this.body) : timestamp = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(timestamp) > const Duration(minutes: 5);
}

class ApiService {
  static const String _baseUrl = 'https://api.jikan.moe/v4';

  http.Client client;
  DateTime _lastRequestTime = DateTime.fromMillisecondsSinceEpoch(0);
  final Map<String, _CachedResponse> _responseCache = {};

  static final ApiService _instance = ApiService._internal();
  factory ApiService({http.Client? client}) {
    if (client != null) {
      _instance.client = client;
      _instance._responseCache.clear();
      _instance._lastRequestTime = DateTime.fromMillisecondsSinceEpoch(0);
    }
    return _instance;
  }
  ApiService._internal() : client = http.Client();

  Future<http.Response> _queuedGet(Uri url) async {
    final cacheKey = url.toString();
    final cached = _responseCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return http.Response(cached.body, 200);
    }

    final now = DateTime.now();
    final elapsed = now.difference(_lastRequestTime);
    const minDelay = Duration(milliseconds: 360);
    if (elapsed < minDelay && _lastRequestTime.millisecondsSinceEpoch != 0) {
      await Future<void>.delayed(minDelay - elapsed);
    }
    _lastRequestTime = DateTime.now();

    final response = await _getWithRetry(url);
    if (response.statusCode == 200) {
      _responseCache[cacheKey] = _CachedResponse(response.body);
    }
    return response;
  }

  Future<List<Anime>> _fetchAnimeList(Uri url) async {
    try {
      final response = await _queuedGet(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['data'] as List<dynamic>?;
        if (list != null) {
          return list
              .whereType<Map<String, dynamic>>()
              .map(Anime.fromJson)
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  Future<List<Anime>> fetchTopAnime({int limit = 25}) async {
    final url = Uri.parse('$_baseUrl/top/anime?limit=$limit');
    final result = await _fetchAnimeList(url);
    if (result.isNotEmpty) {
      return result;
    }
    try {
      return await _fetchAniListTop(limit: limit);
    } catch (_) {
      return _fallbackAnimeList;
    }
  }

  Future<List<Anime>> fetchCurrentSeasonAnime({int limit = 25}) async {
    final url = Uri.parse('$_baseUrl/seasons/now?limit=$limit');
    final result = await _fetchAnimeList(url);
    if (result.isNotEmpty) {
      return result;
    }
    try {
      return await _fetchAniListReleasing(limit: limit);
    } catch (_) {
      return _fallbackAnimeList;
    }
  }

  Future<List<Anime>> fetchUpcomingAnime({int limit = 25}) async {
    final url = Uri.parse('$_baseUrl/seasons/upcoming?limit=$limit');
    final result = await _fetchAnimeList(url);
    if (result.isNotEmpty) {
      return result;
    }
    try {
      return await _fetchAniListUpcoming(limit: limit);
    } catch (_) {
      return _fallbackUpcomingAnimeList;
    }
  }

  Future<List<Anime>> fetchSchedules({String? filter, int limit = 25}) async {
    final queryParams = <String, String>{'limit': limit.toString()};
    if (filter != null && filter.isNotEmpty) {
      queryParams['filter'] = filter;
    }
    final url = Uri.https('api.jikan.moe', '/v4/schedules', queryParams);
    final result = await _fetchAnimeList(url);
    if (result.isNotEmpty) {
      return result;
    }
    try {
      return await _fetchAniListReleasing(limit: limit);
    } catch (_) {
      return _fallbackAnimeList;
    }
  }

  Future<Anime?> fetchRandomAnime() async {
    try {
      final response = await _queuedGet(Uri.parse('$_baseUrl/random/anime'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final animeData = data['data'] as Map<String, dynamic>?;
        if (animeData != null) {
          return Anime.fromJson(animeData);
        }
      }
    } catch (_) {}

    // Fallback to random pick from local fallback list if Jikan times out (504)
    if (_fallbackAnimeList.isNotEmpty) {
      final index =
          DateTime.now().millisecondsSinceEpoch % _fallbackAnimeList.length;
      return _fallbackAnimeList[index];
    }
    return null;
  }

  Future<Anime?> fetchAnimeFullDetails(int malId) async {
    try {
      final response =
          await _queuedGet(Uri.parse('$_baseUrl/anime/$malId/full'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final animeData = data['data'] as Map<String, dynamic>?;
        if (animeData != null) {
          return Anime.fromJson(animeData);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<List<AnimeRecommendation>> fetchAnimeRecommendations(int malId) async {
    try {
      final response = await _queuedGet(
        Uri.parse('$_baseUrl/anime/$malId/recommendations'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['data'] as List<dynamic>?;
        if (list != null) {
          return list
              .whereType<Map<String, dynamic>>()
              .map(AnimeRecommendation.fromJson)
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  Future<List<AnimeCharacter>> fetchAnimeCharacters(int malId) async {
    try {
      final response =
          await _queuedGet(Uri.parse('$_baseUrl/anime/$malId/characters'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['data'] as List<dynamic>?;
        if (list != null) {
          return list
              .whereType<Map<String, dynamic>>()
              .map(AnimeCharacter.fromJson)
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  Future<List<AnimeVideo>> fetchAnimeVideos(int malId) async {
    try {
      final response =
          await _queuedGet(Uri.parse('$_baseUrl/anime/$malId/videos'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final promoList =
            (data['data'] as Map<String, dynamic>?)?['promo'] as List<dynamic>?;
        if (promoList != null) {
          return promoList
              .whereType<Map<String, dynamic>>()
              .map(AnimeVideo.fromJson)
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  Future<List<AnimeGenre>> fetchGenres() async {
    try {
      final response =
          await _queuedGet(Uri.parse('$_baseUrl/genres/anime'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['data'] as List<dynamic>?;
        if (list != null) {
          return list
              .whereType<Map<String, dynamic>>()
              .map(AnimeGenre.fromJson)
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  Future<Anime?> fetchAnimeDetails(int malId) async {
    try {
      final response = await _queuedGet(Uri.parse('$_baseUrl/anime/$malId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final animeData = data['data'] as Map<String, dynamic>?;
        if (animeData != null) {
          return Anime.fromJson(animeData);
        }
      }
    } catch (_) {}

    return _fetchAniListByIdMal(malId);
  }

  Future<Anime?> _fetchAniListByIdMal(int malId) async {
    const query = r'''
      query ($idMal: Int) {
        Media(idMal: $idMal, type: ANIME) {
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
    ''';
    try {
      final response = await client
          .post(
            Uri.parse('https://graphql.anilist.co'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'query': query,
              'variables': {'idMal': malId},
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;
        final media = data?['Media'] as Map<String, dynamic>?;
        if (media != null) {
          return Anime.fromAniListJson(media);
        }
      }
    } catch (_) {}

    return null;
  }

  Future<List<Anime>> searchAnimeAdvanced({
    String? query,
    int? genreId,
    String? genreName,
    String? type,
    String? status,
    String? orderBy,
    String? sort,
    int limit = 10,
  }) async {
    final queryParams = <String, String>{'limit': limit.toString()};
    if (query != null && query.trim().isNotEmpty) {
      queryParams['q'] = query.trim();
    }
    if (genreId != null) {
      queryParams['genres'] = genreId.toString();
    }
    if (type != null && type.isNotEmpty) {
      queryParams['type'] = type;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (orderBy != null && orderBy.isNotEmpty) {
      queryParams['order_by'] = orderBy;
    }
    if (sort != null && sort.isNotEmpty) {
      queryParams['sort'] = sort;
    }

    final url = Uri.https('api.jikan.moe', '/v4/anime', queryParams);
    final results = await _fetchAnimeList(url);
    if (results.isNotEmpty) {
      return results;
    }

    // Fall back to AniList if Jikan is failing with 504 Gateway Timeout or unavailable
    try {
      return await _searchAniList(query: query, genre: genreName);
    } catch (_) {
      return [];
    }
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
      final response = await _queuedGet(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['data'] as List<dynamic>? ?? [];
        if (list.isNotEmpty) {
          return list
              .whereType<Map<String, dynamic>>()
              .map(Anime.fromJson)
              .toList();
        }
      }
    } catch (_) {
      // Fall back to AniList when Jikan is temporarily unavailable.
    }

    return _searchAniList(query: trimmedQuery);
  }

  Future<http.Response> _getWithRetry(Uri url) async {
    const maxAttempts = 2;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final response = await client
            .get(
              url,
              headers: {
                'Accept': 'application/json',
                'User-Agent': 'FlutterAnimeApp/1.0',
              },
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200 || attempt == maxAttempts - 1) {
          return response;
        }

        // Only retry for 429 rate limiting with backoff
        if (response.statusCode == 429) {
          await Future<void>.delayed(const Duration(milliseconds: 1500));
        } else {
          // For 504 Gateway Timeout or 5xx server errors, do not retry
          return response;
        }
      } on TimeoutException {
        rethrow;
      }
    }

    throw StateError('Search request could not be completed.');
  }

  Future<List<Anime>> _searchAniList({String? query, String? genre}) async {
    const searchQuery = r'''
      query ($search: String, $genre: String) {
        Page(perPage: 10) {
          media(search: $search, genre: $genre, type: ANIME, isAdult: false) {
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
    final variables = <String, dynamic>{};
    if (query != null && query.trim().isNotEmpty) {
      variables['search'] = query.trim();
    }
    if (genre != null && genre.trim().isNotEmpty) {
      variables['genre'] = genre.trim();
    }

    final response = await client
        .post(
          Uri.parse('https://graphql.anilist.co'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'query': searchQuery,
            'variables': variables,
          }),
        )
        .timeout(const Duration(seconds: 5));

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

  Future<List<Anime>> _fetchAniListUpcoming({int limit = 25}) async {
    const query = r'''
      query ($limit: Int) {
        Page(perPage: $limit) {
          media(status: NOT_YET_RELEASED, sort: POPULARITY_DESC, type: ANIME, isAdult: false) {
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

    final response = await client
        .post(
          Uri.parse('https://graphql.anilist.co'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'query': query,
            'variables': {'limit': limit},
          }),
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw Exception('Unable to fetch upcoming anime from AniList.');
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

  Future<List<Anime>> _fetchAniListReleasing({int limit = 25}) async {
    const query = r'''
      query ($limit: Int) {
        Page(perPage: $limit) {
          media(status: RELEASING, sort: POPULARITY_DESC, type: ANIME, isAdult: false) {
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

    final response = await client
        .post(
          Uri.parse('https://graphql.anilist.co'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'query': query,
            'variables': {'limit': limit},
          }),
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw Exception('Unable to fetch releasing anime from AniList.');
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

  Future<List<Anime>> _fetchAniListTop({int limit = 25}) async {
    const query = r'''
      query ($limit: Int) {
        Page(perPage: $limit) {
          media(sort: SCORE_DESC, type: ANIME, isAdult: false) {
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

    final response = await client
        .post(
          Uri.parse('https://graphql.anilist.co'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'query': query,
            'variables': {'limit': limit},
          }),
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw Exception('Unable to fetch top anime from AniList.');
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

  static final List<Anime> _fallbackUpcomingAnimeList = [
    const Anime(
      malId: 54857,
      title: 'Chainsaw Man Movie: Reze-hen',
      titleEnglish: 'Chainsaw Man - The Movie: Reze Arc',
      imageUrl: 'https://cdn.myanimelist.net/images/anime/1169/140683l.jpg',
      score: null,
      type: 'Movie',
      synopsis:
          'Upcoming anime film adapting the Reze Arc / Bomb Girl Arc of Chainsaw Man.',
      genres: ['Action', 'Supernatural'],
      status: 'Not yet aired',
    ),
    const Anime(
      malId: 58514,
      title: 'One Punch Man 3',
      titleEnglish: 'One Punch Man Season 3',
      imageUrl: 'https://cdn.myanimelist.net/images/anime/1041/141753l.jpg',
      score: null,
      type: 'TV',
      synopsis:
          'Third season of One Punch Man covering the Monster Association arc.',
      genres: ['Action', 'Comedy'],
      status: 'Not yet aired',
    ),
    const Anime(
      malId: 59438,
      title: 'Jujutsu Kaisen: Shimetsu Kaiyuu',
      titleEnglish: 'Jujutsu Kaisen: Culling Game Arc',
      imageUrl: 'https://cdn.myanimelist.net/images/anime/1171/109222l.jpg',
      score: null,
      type: 'TV',
      synopsis:
          'Sequel to Jujutsu Kaisen Season 2 depicting the Culling Game arc.',
      genres: ['Action', 'Supernatural'],
      status: 'Not yet aired',
    ),
  ];

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
