import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:animeapi/services/api_service.dart';

void main() {
  group('ApiService endpoints', () {
    test('fetchCurrentSeasonAnime parses list correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v4/seasons/now');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'mal_id': 101,
                'title': 'Test Season Anime',
                'images': {
                  'jpg': {'image_url': 'https://example.com/img.jpg'}
                },
                'score': 8.7,
              }
            ]
          }),
          200,
        );
      });

      final apiService = ApiService(client: mockClient);
      final list = await apiService.fetchCurrentSeasonAnime();
      expect(list.length, 1);
      expect(list.first.malId, 101);
      expect(list.first.title, 'Test Season Anime');
    });

    test('fetchUpcomingAnime parses list correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v4/seasons/upcoming');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'mal_id': 102,
                'title': 'Test Upcoming Anime',
                'images': {'jpg': {}},
              }
            ]
          }),
          200,
        );
      });

      final apiService = ApiService(client: mockClient);
      final list = await apiService.fetchUpcomingAnime();
      expect(list.length, 1);
      expect(list.first.malId, 102);
    });

    test('fetchSchedules parses list correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v4/schedules');
        expect(request.url.queryParameters['filter'], 'monday');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'mal_id': 103,
                'title': 'Monday Anime',
                'images': {'jpg': {}},
              }
            ]
          }),
          200,
        );
      });

      final apiService = ApiService(client: mockClient);
      final list = await apiService.fetchSchedules(filter: 'monday');
      expect(list.length, 1);
      expect(list.first.malId, 103);
    });

    test('fetchRandomAnime parses single anime correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v4/random/anime');
        return http.Response(
          jsonEncode({
            'data': {
              'mal_id': 104,
              'title': 'Random Anime',
              'images': {'jpg': {}},
            }
          }),
          200,
        );
      });

      final apiService = ApiService(client: mockClient);
      final anime = await apiService.fetchRandomAnime();
      expect(anime, isNotNull);
      expect(anime!.malId, 104);
      expect(anime.title, 'Random Anime');
    });

    test('fetchAnimeFullDetails parses extended fields correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v4/anime/105/full');
        return http.Response(
          jsonEncode({
            'data': {
              'mal_id': 105,
              'title': 'Full Anime',
              'images': {'jpg': {}},
              'status': 'Finished Airing',
              'rating': 'PG-13',
              'studios': [
                {'name': 'Madhouse'}
              ],
            }
          }),
          200,
        );
      });

      final apiService = ApiService(client: mockClient);
      final anime = await apiService.fetchAnimeFullDetails(105);
      expect(anime, isNotNull);
      expect(anime!.status, 'Finished Airing');
      expect(anime.rating, 'PG-13');
      expect(anime.studios, contains('Madhouse'));
    });

    test('fetchAnimeRecommendations parses recommendations correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v4/anime/106/recommendations');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'entry': {
                  'mal_id': 200,
                  'title': 'Recommended Anime',
                  'images': {
                    'jpg': {'image_url': 'https://example.com/rec.jpg'}
                  }
                },
                'votes': 42,
              }
            ]
          }),
          200,
        );
      });

      final apiService = ApiService(client: mockClient);
      final recs = await apiService.fetchAnimeRecommendations(106);
      expect(recs.length, 1);
      expect(recs.first.malId, 200);
      expect(recs.first.title, 'Recommended Anime');
      expect(recs.first.votes, 42);
    });

    test('fetchAnimeCharacters parses characters & cast correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v4/anime/107/characters');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'character': {
                  'mal_id': 301,
                  'name': 'Hero',
                  'images': {
                    'jpg': {'image_url': 'https://example.com/hero.jpg'}
                  }
                },
                'role': 'Main',
                'voice_actors': [
                  {
                    'person': {'mal_id': 401, 'name': 'Actor A'},
                    'language': 'Japanese'
                  }
                ]
              }
            ]
          }),
          200,
        );
      });

      final apiService = ApiService(client: mockClient);
      final characters = await apiService.fetchAnimeCharacters(107);
      expect(characters.length, 1);
      expect(characters.first.name, 'Hero');
      expect(characters.first.role, 'Main');
      expect(characters.first.voiceActorName, 'Actor A');
    });

    test('fetchAnimeVideos parses promotional trailers correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v4/anime/108/videos');
        return http.Response(
          jsonEncode({
            'data': {
              'promo': [
                {
                  'title': 'Main Trailer',
                  'trailer': {
                    'youtube_id': 'abc123xyz',
                    'url': 'https://youtube.com/watch?v=abc123xyz',
                  }
                }
              ]
            }
          }),
          200,
        );
      });

      final apiService = ApiService(client: mockClient);
      final videos = await apiService.fetchAnimeVideos(108);
      expect(videos.length, 1);
      expect(videos.first.title, 'Main Trailer');
      expect(videos.first.youtubeId, 'abc123xyz');
    });

    test('fetchGenres parses anime genres correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v4/genres/anime');
        return http.Response(
          jsonEncode({
            'data': [
              {'mal_id': 1, 'name': 'Action', 'count': 500},
              {'mal_id': 2, 'name': 'Adventure', 'count': 300},
            ]
          }),
          200,
        );
      });

      final apiService = ApiService(client: mockClient);
      final genres = await apiService.fetchGenres();
      expect(genres.length, 2);
      expect(genres.first.name, 'Action');
      expect(genres.last.name, 'Adventure');
    });

    test('searchAnimeAdvanced builds query parameters correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v4/anime');
        expect(request.url.queryParameters['q'], 'test');
        expect(request.url.queryParameters['genres'], '1');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'mal_id': 501,
                'title': 'Advanced Search Result',
                'images': {'jpg': {}},
              }
            ]
          }),
          200,
        );
      });

      final apiService = ApiService(client: mockClient);
      final results = await apiService.searchAnimeAdvanced(
        query: 'test',
        genreId: 1,
      );
      expect(results.length, 1);
      expect(results.first.title, 'Advanced Search Result');
    });

    test('fetchAnimeDetails parses details and falls back to AniList if Jikan fails', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'api.jikan.moe') {
          return http.Response('{"status":504}', 504);
        }
        expect(request.url.host, 'graphql.anilist.co');
        return http.Response(
          jsonEncode({
            'data': {
              'Media': {
                'id': 1001,
                'idMal': 52991,
                'title': {'english': 'Frieren'},
                'description': 'A magical journey.',
                'coverImage': {'large': 'https://example.com/frieren.jpg'},
              }
            }
          }),
          200,
        );
      });

      final apiService = ApiService(client: mockClient);
      final anime = await apiService.fetchAnimeDetails(52991);
      expect(anime, isNotNull);
      expect(anime!.titleEnglish, 'Frieren');
      expect(anime.synopsis, 'A magical journey.');
    });

    test('searchAnimeAdvanced falls back to AniList when Jikan returns 504', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'api.jikan.moe') {
          return http.Response('{"status":504}', 504);
        }
        expect(request.url.host, 'graphql.anilist.co');
        return http.Response(
          jsonEncode({
            'data': {
              'Page': {
                'media': [
                  {
                    'id': 2001,
                    'title': {'english': 'Action Hero'},
                    'coverImage': {'large': ''},
                  }
                ]
              }
            }
          }),
          200,
        );
      });

      final apiService = ApiService(client: mockClient);
      final results = await apiService.searchAnimeAdvanced(
        genreName: 'Action',
      );
      expect(results.length, 1);
      expect(results.first.titleEnglish, 'Action Hero');
    });

    test('fetchUpcomingAnime falls back to AniList when Jikan returns 504', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'api.jikan.moe') {
          return http.Response('{"status":504}', 504);
        }
        expect(request.url.host, 'graphql.anilist.co');
        return http.Response(
          jsonEncode({
            'data': {
              'Page': {
                'media': [
                  {
                    'id': 3001,
                    'title': {'english': 'Upcoming Hit'},
                    'coverImage': {'large': ''},
                  }
                ]
              }
            }
          }),
          200,
        );
      });

      final apiService = ApiService(client: mockClient);
      final results = await apiService.fetchUpcomingAnime();
      expect(results.length, 1);
      expect(results.first.titleEnglish, 'Upcoming Hit');
    });

    test('fetchSchedules falls back to AniList when Jikan returns 504', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'api.jikan.moe') {
          return http.Response('{"status":504}', 504);
        }
        expect(request.url.host, 'graphql.anilist.co');
        return http.Response(
          jsonEncode({
            'data': {
              'Page': {
                'media': [
                  {
                    'id': 4001,
                    'title': {'english': 'Scheduled Hit'},
                    'coverImage': {'large': ''},
                  }
                ]
              }
            }
          }),
          200,
        );
      });

      final apiService = ApiService(client: mockClient);
      final results = await apiService.fetchSchedules();
      expect(results.length, 1);
      expect(results.first.titleEnglish, 'Scheduled Hit');
    });
  });
}
