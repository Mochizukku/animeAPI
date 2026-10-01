import 'package:flutter/material.dart';

import '../models/anime.dart';

class AnimeCollectionScreen extends StatelessWidget {
  final String emptyMessage;
  final List<Anime> anime;
  final ValueChanged<Anime> onAnimeSelected;

  const AnimeCollectionScreen({
    super.key,
    required this.emptyMessage,
    required this.anime,
    required this.onAnimeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (anime.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(emptyMessage, style: theme.textTheme.bodyLarge),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: anime.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = anime[index];
        return ListTile(
          contentPadding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: theme.colorScheme.surfaceContainerLow,
          leading: _AnimeImage(anime: item),
          title: Text(item.displayTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(item.genres.take(3).join(', ')),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => onAnimeSelected(item),
        );
      },
    );
  }
}

class _AnimeImage extends StatelessWidget {
  final Anime anime;

  const _AnimeImage({required this.anime});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 64,
      child: anime.imageUrl.isEmpty
          ? const Icon(Icons.movie_rounded)
          : Image.network(
              anime.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(Icons.broken_image_rounded),
            ),
    );
  }
}
