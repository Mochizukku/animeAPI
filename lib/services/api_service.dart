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
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'FlutterAnimeApp/1.0',
        },
      ).timeout(const Duration(seconds: 10));

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
