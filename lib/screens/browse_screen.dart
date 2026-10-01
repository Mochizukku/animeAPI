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
  Future<List<Anime>>? _searchResults;
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _search([String? value]) {
    final query = (value ?? _searchController.text).trim();
    if (query.isEmpty) {
      setState(() => _searchResults = null);
      return;
    }
    setState(() {
      _searchResults = (widget.searchAnime ?? _apiService.searchAnime)(query);
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
          padding: const EdgeInsets.all(16),
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
