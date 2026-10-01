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
        '';

    final genresList =
        (json['genres'] as List<dynamic>?)
            ?.map(
              (g) =>
                  g is Map<String, dynamic> ? (g['name'] as String? ?? '') : '',
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
    );
  }

  factory Anime.fromAniListJson(Map<String, dynamic> json) {
    final title = json['title'] as Map<String, dynamic>?;
    final coverImage = json['coverImage'] as Map<String, dynamic>?;
    final genres = (json['genres'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();

    return Anime(
      malId: json['idMal'] as int? ?? json['id'] as int? ?? 0,
      title: title?['romaji'] as String? ?? 'Untitled',
      titleEnglish: title?['english'] as String?,
      imageUrl:
          coverImage?['large'] as String? ??
          coverImage?['medium'] as String? ??
          '',
      score: (json['averageScore'] as num?)?.toDouble(),
      episodes: json['episodes'] as int?,
      synopsis: json['description'] as String?,
      type: json['format'] as String?,
      genres: genres,
    );
  }
}
