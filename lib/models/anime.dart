class Anime {
  final int malId;
  final String title;
  final String? titleEnglish;
  final String imageUrl;
  final double? score;
  final int? episodes;
  final String? synopsis;
  final String? type;
  final List<String> genres;
  final String? status;
  final String? rating;
  final int? year;
  final String? season;
  final List<String> studios;

  const Anime({
    required this.malId,
    required this.title,
    this.titleEnglish,
    required this.imageUrl,
    this.score,
    this.episodes,
    this.synopsis,
    this.type,
    this.genres = const [],
    this.status,
    this.rating,
    this.year,
    this.season,
    this.studios = const [],
  });

  String get displayTitle =>
      (titleEnglish != null && titleEnglish!.trim().isNotEmpty)
      ? titleEnglish!
      : title;

  factory Anime.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as Map<String, dynamic>?;
    final jpg = images?['jpg'] as Map<String, dynamic>?;
    final webp = images?['webp'] as Map<String, dynamic>?;

    final imgUrl =
        jpg?['large_image_url'] as String? ??
        jpg?['image_url'] as String? ??
        webp?['image_url'] as String? ??
        json['image_url'] as String? ??
        json['imageUrl'] as String? ??
        '';

    final genresList =
        (json['genres'] as List<dynamic>?)
            ?.map(
              (g) => g is Map<String, dynamic>
                  ? (g['name'] as String? ?? '')
                  : (g is String ? g : ''),
            )
            .where((name) => name.isNotEmpty)
            .toList() ??
        const [];

    final studiosList =
        (json['studios'] as List<dynamic>?)
            ?.map(
              (s) => s is Map<String, dynamic>
                  ? (s['name'] as String? ?? '')
                  : (s is String ? s : ''),
            )
            .where((name) => name.isNotEmpty)
            .toList() ??
        const [];

    double? parsedScore;
    if (json['score'] is num) {
      parsedScore = (json['score'] as num).toDouble();
    }

    return Anime(
      malId: json['mal_id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Untitled',
      titleEnglish: json['title_english'] as String?,
      imageUrl: imgUrl,
      score: parsedScore,
      episodes: json['episodes'] as int?,
      synopsis: json['synopsis'] as String?,
      type: json['type'] as String?,
      genres: genresList,
      status: json['status'] as String?,
      rating: json['rating'] as String?,
      year: json['year'] as int?,
      season: json['season'] as String?,
      studios: studiosList,
    );
  }

  Map<String, dynamic> toJson() => {
    'mal_id': malId,
    'title': title,
    'title_english': titleEnglish,
    'imageUrl': imageUrl,
    'score': score,
    'episodes': episodes,
    'synopsis': synopsis,
    'type': type,
    'genres': genres,
    'status': status,
    'rating': rating,
    'year': year,
    'season': season,
    'studios': studios,
  };

  factory Anime.fromAniListJson(Map<String, dynamic> json) {
    final title = json['title'] as Map<String, dynamic>?;
    final coverImage = json['coverImage'] as Map<String, dynamic>?;
    final genres = (json['genres'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();

    final rawDescription = json['description'] as String?;
    final cleanedDescription = rawDescription
        ?.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();

    double? parsedScore;
    if (json['averageScore'] is num) {
      final val = (json['averageScore'] as num).toDouble();
      parsedScore =
          val > 10 ? double.parse((val / 10).toStringAsFixed(1)) : val;
    }

    return Anime(
      malId: json['idMal'] as int? ?? json['id'] as int? ?? 0,
      title: title?['romaji'] as String? ?? 'Untitled',
      titleEnglish: title?['english'] as String?,
      imageUrl:
          coverImage?['large'] as String? ??
          coverImage?['medium'] as String? ??
          '',
      score: parsedScore,
      episodes: json['episodes'] as int?,
      synopsis: cleanedDescription,
      type: json['format'] as String?,
      genres: genres,
    );
  }
}

class AnimeCharacter {
  final int malId;
  final String name;
  final String imageUrl;
  final String role;
  final String? voiceActorName;
  final String? voiceActorLanguage;

  const AnimeCharacter({
    required this.malId,
    required this.name,
    required this.imageUrl,
    required this.role,
    this.voiceActorName,
    this.voiceActorLanguage,
  });

  factory AnimeCharacter.fromJson(Map<String, dynamic> json) {
    final character = json['character'] as Map<String, dynamic>? ?? {};
    final images = character['images'] as Map<String, dynamic>?;
    final jpg = images?['jpg'] as Map<String, dynamic>?;
    final webp = images?['webp'] as Map<String, dynamic>?;
    final imgUrl =
        jpg?['image_url'] as String? ?? webp?['image_url'] as String? ?? '';

    final voiceActors = json['voice_actors'] as List<dynamic>? ?? [];
    String? vaName;
    String? vaLang;
    if (voiceActors.isNotEmpty) {
      final firstVa = voiceActors.first as Map<String, dynamic>?;
      final person = firstVa?['person'] as Map<String, dynamic>?;
      vaName = person?['name'] as String?;
      vaLang = firstVa?['language'] as String?;
    }

    return AnimeCharacter(
      malId: character['mal_id'] as int? ?? 0,
      name: character['name'] as String? ?? 'Unknown',
      imageUrl: imgUrl,
      role: json['role'] as String? ?? 'Supporting',
      voiceActorName: vaName,
      voiceActorLanguage: vaLang,
    );
  }
}

class AnimeVideo {
  final String title;
  final String? youtubeId;
  final String? url;
  final String? imageUrl;

  const AnimeVideo({
    required this.title,
    this.youtubeId,
    this.url,
    this.imageUrl,
  });

  factory AnimeVideo.fromJson(Map<String, dynamic> json) {
    final trailer = json['trailer'] as Map<String, dynamic>?;
    final images = trailer?['images'] as Map<String, dynamic>?;
    return AnimeVideo(
      title: json['title'] as String? ?? 'Promo Video',
      youtubeId: trailer?['youtube_id'] as String?,
      url: trailer?['url'] as String?,
      imageUrl:
          images?['medium_image_url'] as String? ??
          images?['image_url'] as String?,
    );
  }
}

class AnimeGenre {
  final int malId;
  final String name;
  final int count;

  const AnimeGenre({
    required this.malId,
    required this.name,
    this.count = 0,
  });

  factory AnimeGenre.fromJson(Map<String, dynamic> json) {
    return AnimeGenre(
      malId: json['mal_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }
}

class AnimeRecommendation {
  final int malId;
  final String title;
  final String imageUrl;
  final int votes;

  const AnimeRecommendation({
    required this.malId,
    required this.title,
    required this.imageUrl,
    this.votes = 0,
  });

  factory AnimeRecommendation.fromJson(Map<String, dynamic> json) {
    final entry = json['entry'] as Map<String, dynamic>? ?? {};
    final images = entry['images'] as Map<String, dynamic>?;
    final jpg = images?['jpg'] as Map<String, dynamic>?;
    final webp = images?['webp'] as Map<String, dynamic>?;
    final imgUrl =
        jpg?['large_image_url'] as String? ??
        jpg?['image_url'] as String? ??
        webp?['image_url'] as String? ??
        '';

    return AnimeRecommendation(
      malId: entry['mal_id'] as int? ?? 0,
      title: entry['title'] as String? ?? 'Untitled',
      imageUrl: imgUrl,
      votes: json['votes'] as int? ?? 0,
    );
  }
}
