import 'package:flutter/material.dart';
import '../models/anime.dart';

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

  @override
  void initState() {
    super.initState();
    _isSaved = widget.isSaved;
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
          widget.anime.displayTitle,
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
            if (widget.anime.imageUrl.isNotEmpty)
              SizedBox(
                height: 300,
                width: double.infinity,
                child: Image.network(
                  widget.anime.imageUrl,
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
                    widget.anime.displayTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.anime.titleEnglish != null &&
                      widget.anime.titleEnglish != widget.anime.title) ...[
                    const SizedBox(height: 4),
                    Text(
                    widget.anime.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Quick Stats Row
                  Row(
                    children: [
                      if (widget.anime.score != null) ...[
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
                                widget.anime.score!.toStringAsFixed(1),
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
                      if (widget.anime.type != null) ...[
                        Chip(
                          label: Text(widget.anime.type!),
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (widget.anime.episodes != null)
                        Chip(
                          label: Text('${widget.anime.episodes} Ep'),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Genres
                  if (widget.anime.genres.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: widget.anime.genres
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
                    widget.anime.synopsis ?? 'No synopsis available.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
