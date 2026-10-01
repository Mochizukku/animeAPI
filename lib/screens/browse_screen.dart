import 'dart:async';

import 'package:flutter/material.dart';

import '../models/anime.dart';
import '../services/api_service.dart';
import 'anime_collection_screen.dart';

class BrowseScreen extends StatefulWidget {
  final ValueChanged<Anime> onAnimeSelected;
  final Future<List<Anime>> Function(String query)? searchAnime;

  const BrowseScreen({
    super.key,
    required this.onAnimeSelected,
    this.searchAnime,
  });

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final _searchController = TextEditingController();
  final _apiService = ApiService();
  late final Future<List<AnimeGenre>> _genresFuture;
  AnimeGenre? _selectedGenre;
  Future<List<Anime>>? _searchResults;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _genresFuture = _apiService.fetchGenres();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _selectGenre(AnimeGenre genre) {
    setState(() {
      _selectedGenre = (_selectedGenre?.malId == genre.malId) ? null : genre;
    });
    _search();
  }

  void _search([String? value]) {
    final query = (value ?? _searchController.text).trim();
    if (query.isEmpty && _selectedGenre == null) {
      setState(() => _searchResults = null);
      return;
    }
    setState(() {
      if (widget.searchAnime != null) {
        _searchResults = widget.searchAnime!(query);
      } else if (_selectedGenre != null) {
        _searchResults = _apiService.searchAnimeAdvanced(
          query: query.isEmpty ? null : query,
          genreId: _selectedGenre!.malId,
          genreName: _selectedGenre!.name,
        );
      } else {
        _searchResults = _apiService.searchAnime(query);
      }
    });
  }

  void _onQueryChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        _search(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: _onQueryChanged,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: 'Search anime',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded),
                tooltip: 'Search',
                onPressed: _search,
              ),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: FutureBuilder<List<AnimeGenre>>(
            future: _genresFuture,
            builder: (context, snapshot) {
              final genres = snapshot.data ?? [];
              if (genres.isEmpty) return const SizedBox.shrink();
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: genres.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final genre = genres[index];
                  final isSelected = _selectedGenre?.malId == genre.malId;
                  return FilterChip(
                    label: Text(genre.name),
                    selected: isSelected,
                    onSelected: (_) => _selectGenre(genre),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildResults()),
      ],
    );
  }

  Widget _buildResults() {
    if (_searchResults == null) {
      return const Center(child: Text('Search for an anime to get started.'));
    }

    return FutureBuilder<List<Anime>>(
      future: _searchResults,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Anime search is temporarily unavailable.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _search,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }
        return AnimeCollectionScreen(
          emptyMessage: 'No anime matched your search.',
          anime: snapshot.data ?? [],
          onAnimeSelected: widget.onAnimeSelected,
        );
      },
    );
  }
}
