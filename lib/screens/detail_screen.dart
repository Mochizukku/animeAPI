import 'package:flutter/material.dart';
import '../models/anime.dart';
import '../services/api_service.dart';

class DetailScreen extends StatefulWidget {
  final Anime anime;
  final bool isSaved;
  final VoidCallback onToggleSaved;

  const DetailScreen({
    super.key,
    required this.anime,
    required this.isSaved,
    required this.onToggleSaved,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late bool _isSaved;
  late Anime _currentAnime;
  final ApiService _apiService = ApiService();
  late final Future<List<AnimeCharacter>> _charactersFuture;
  late final Future<List<AnimeRecommendation>> _recommendationsFuture;
  late final Future<List<AnimeVideo>> _videosFuture;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.isSaved;
    _currentAnime = widget.anime;
    _charactersFuture = _apiService.fetchAnimeCharacters(widget.anime.malId);
    _recommendationsFuture =
        _apiService.fetchAnimeRecommendations(widget.anime.malId);
    _videosFuture = _apiService.fetchAnimeVideos(widget.anime.malId);

    if (_currentAnime.synopsis == null || _currentAnime.synopsis!.isEmpty) {
      _apiService.fetchAnimeDetails(widget.anime.malId).then((details) {
        if (mounted && details != null) {
          setState(() {
            _currentAnime = details;
          });
        }
      });
    }
  }

  void _toggleSaved() {
    widget.onToggleSaved();
    setState(() => _isSaved = !_isSaved);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentAnime.displayTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            ),
            tooltip: _isSaved ? 'Remove from My List' : 'Add to My List',
            onPressed: _toggleSaved,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Anime Header Image
            if (_currentAnime.imageUrl.isNotEmpty)
              SizedBox(
                height: 300,
                width: double.infinity,
                child: Image.network(
                  _currentAnime.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: Icon(Icons.movie, size: 64, color: Colors.grey),
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    _currentAnime.displayTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_currentAnime.titleEnglish != null &&
                      _currentAnime.titleEnglish != _currentAnime.title) ...[
                    const SizedBox(height: 4),
                    Text(
                      _currentAnime.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Quick Stats Row
                  Row(
                    children: [
                      if (_currentAnime.score != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _currentAnime.score!.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (_currentAnime.type != null) ...[
                        Chip(
                          label: Text(_currentAnime.type!),
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (_currentAnime.episodes != null)
                        Chip(
                          label: Text('${_currentAnime.episodes} Ep'),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Genres
                  if (_currentAnime.genres.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _currentAnime.genres
                          .map((genre) => ActionChip(
                                label: Text(genre),
                                onPressed: () {},
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Synopsis
                  Text(
                    'Synopsis',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentAnime.synopsis ??
                        (widget.anime.synopsis ?? 'Loading synopsis...'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Extra Information (Status, Rating, Studios)
                  if (_currentAnime.status != null ||
                      _currentAnime.rating != null ||
                      _currentAnime.studios.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (_currentAnime.status != null)
                          Chip(
                            label: Text(_currentAnime.status!),
                            visualDensity: VisualDensity.compact,
                          ),
                        if (_currentAnime.rating != null)
                          Chip(
                            label: Text(_currentAnime.rating!),
                            visualDensity: VisualDensity.compact,
                          ),
                        if (_currentAnime.studios.isNotEmpty)
                          Chip(
                            label: Text(_currentAnime.studios.join(', ')),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Characters & Cast
                  FutureBuilder<List<AnimeCharacter>>(
                    future: _charactersFuture,
                    builder: (context, snapshot) {
                      final characters = snapshot.data ?? [];
                      if (characters.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Characters & Voice Actors',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 120,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: characters.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final char = characters[index];
                                return SizedBox(
                                  width: 80,
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundImage: char.imageUrl.isNotEmpty
                                            ? NetworkImage(char.imageUrl)
                                            : null,
                                        child: char.imageUrl.isEmpty
                                            ? const Icon(Icons.person)
                                            : null,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        char.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (char.voiceActorName != null)
                                        Text(
                                          char.voiceActorName!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),

                  // Trailers & Promo Videos
                  FutureBuilder<List<AnimeVideo>>(
                    future: _videosFuture,
                    builder: (context, snapshot) {
                      final videos = snapshot.data ?? [];
                      if (videos.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trailers & Videos',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 100,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: videos.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final video = videos[index];
                                return Card(
                                  clipBehavior: Clip.antiAlias,
                                  child: SizedBox(
                                    width: 160,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        if (video.imageUrl != null &&
                                            video.imageUrl!.isNotEmpty)
                                          Positioned.fill(
                                            child: Image.network(
                                              video.imageUrl!,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        Container(
                                          color: Colors.black
                                              .withValues(alpha: 0.4),
                                        ),
                                        const Icon(
                                          Icons.play_circle_fill_rounded,
                                          size: 36,
                                          color: Colors.white,
                                        ),
                                        Positioned(
                                          bottom: 6,
                                          left: 8,
                                          right: 8,
                                          child: Text(
                                            video.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),

                  // Recommendations ("More Like This")
                  FutureBuilder<List<AnimeRecommendation>>(
                    future: _recommendationsFuture,
                    builder: (context, snapshot) {
                      final recs = snapshot.data ?? [];
                      if (recs.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'More Like This',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 140,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: recs.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final rec = recs[index];
                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailScreen(
                                          anime: Anime(
                                            malId: rec.malId,
                                            title: rec.title,
                                            imageUrl: rec.imageUrl,
                                          ),
                                          isSaved: false,
                                          onToggleSaved: () {},
                                        ),
                                      ),
                                    );
                                  },
                                  child: SizedBox(
                                    width: 90,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: SizedBox(
                                            width: 90,
                                            height: 100,
                                            child: rec.imageUrl.isNotEmpty
                                                ? Image.network(
                                                    rec.imageUrl,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Container(
                                                    color: colorScheme
                                                        .surfaceContainerHighest,
                                                    child: const Icon(
                                                      Icons.movie,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          rec.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
