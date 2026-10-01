import 'package:flutter/material.dart';
import '../models/anime.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'anime_collection_screen.dart';
import 'browse_screen.dart';
import 'detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String username;
  final StorageService? storageService;

  const DashboardScreen({
    super.key,
    this.username = 'Anime Fan',
    this.storageService,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentTabIndex = 0;
  final ApiService _apiService = ApiService();
  StorageService get _storageService =>
      widget.storageService ?? const StorageService();
  final List<Anime> _savedAnime = [];
  final List<Anime> _watchHistory = [];

  late Future<List<Anime>> _animeFuture;
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAnime();
    _loadPersistedData();
  }

  Future<void> _loadPersistedData() async {
    final history = await _storageService.loadWatchHistory();
    final saved = await _storageService.loadSavedAnime();
    if (!mounted) return;
    setState(() {
      _watchHistory.clear();
      _watchHistory.addAll(history);
      _savedAnime.clear();
      _savedAnime.addAll(saved);
    });
  }

  void _loadAnime() {
    setState(() {
      switch (_selectedCategoryIndex) {
        case 1:
          _animeFuture = _apiService.fetchCurrentSeasonAnime();
          break;
        case 2:
          _animeFuture = _apiService.fetchUpcomingAnime();
          break;
        case 3:
          _animeFuture = _apiService.fetchSchedules();
          break;
        default:
          _animeFuture = _apiService.fetchTopAnime();
          break;
      }
    });
  }

  Future<void> _openRandomAnime() async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Finding a random anime...'),
        duration: Duration(seconds: 1),
      ),
    );
    final randomAnime = await _apiService.fetchRandomAnime();
    if (!mounted) return;
    if (randomAnime != null) {
      _openDetail(randomAnime);
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not fetch random anime. Try again.')),
      );
    }
  }

  Future<void> _clearAllData() async {
    await _storageService.clearAll();
    if (!mounted) return;
    setState(() {
      _watchHistory.clear();
      _savedAnime.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Watch History and My List have been cleared.'),
      ),
    );
  }

  void _openDetail(Anime anime) {
    _recordHistory(anime);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(
          anime: anime,
          isSaved: _isSaved(anime),
          onToggleSaved: () => _toggleSaved(anime),
        ),
      ),
    );
  }

  bool _isSaved(Anime anime) =>
      _savedAnime.any((savedAnime) => savedAnime.malId == anime.malId);

  void _toggleSaved(Anime anime) {
    setState(() {
      if (_isSaved(anime)) {
        _savedAnime.removeWhere(
          (savedAnime) => savedAnime.malId == anime.malId,
        );
      } else {
        _savedAnime.add(anime);
      }
    });
    _storageService.saveSavedAnime(_savedAnime);
  }

  void _recordHistory(Anime anime) {
    setState(() {
      _watchHistory.removeWhere(
        (viewedAnime) => viewedAnime.malId == anime.malId,
      );
      _watchHistory.insert(0, anime);
    });
    _storageService.saveWatchHistory(_watchHistory);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final List<Widget> tabs = [
      _buildAnimeTab(theme, colorScheme),
      BrowseScreen(onAnimeSelected: _openDetail),
      AnimeCollectionScreen(
        emptyMessage: 'Your saved anime will appear here.',
        anime: _savedAnime,
        onAnimeSelected: _openDetail,
      ),
      AnimeCollectionScreen(
        emptyMessage: 'Anime you open will appear here.',
        anime: _watchHistory,
        onAnimeSelected: _openDetail,
      ),
      _buildProfileTab(theme, colorScheme),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          [
            'Anime Dashboard',
            'Browse Anime',
            'My List',
            'Watch History',
            'My Profile',
          ][_currentTabIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_currentTabIndex == 0)
            IconButton(
              icon: const Icon(Icons.casino_outlined),
              tooltip: 'Surprise Me',
              onPressed: _openRandomAnime,
            ),
        ],
      ),
      drawer: _buildDrawer(theme, colorScheme),
      body: IndexedStack(index: _currentTabIndex, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.movie_outlined),
            selectedIcon: Icon(Icons.movie_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Browse',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border_rounded),
            selectedIcon: Icon(Icons.bookmark_rounded),
            label: 'My List',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildAnimeTab(ThemeData theme, ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadAnime();
        await _animeFuture;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Banner with passed data
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.secondaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.waving_hand_rounded,
                      size: 24,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Welcome, ${widget.username}!',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),

          // Category selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Top Anime'),
                  selected: _selectedCategoryIndex == 0,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategoryIndex = 0);
                      _loadAnime();
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('This Season'),
                  selected: _selectedCategoryIndex == 1,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategoryIndex = 1);
                      _loadAnime();
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Upcoming'),
                  selected: _selectedCategoryIndex == 2,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategoryIndex = 2);
                      _loadAnime();
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Schedule'),
                  selected: _selectedCategoryIndex == 3,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategoryIndex = 3);
                      _loadAnime();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Anime List Title
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Text(
              const [
                'Top Anime',
                'This Season',
                'Upcoming Anime',
                'Schedule',
              ][_selectedCategoryIndex],
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Anime List View
          Expanded(
            child: FutureBuilder<List<Anime>>(
              future: _animeFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        const Text('Failed to load anime list.'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadAnime,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  );
                }

                final animeList = snapshot.data ?? [];
                if (animeList.isEmpty) {
                  return const Center(child: Text('No anime found.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: animeList.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final anime = animeList[index];
                    return Card(
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => _openDetail(anime),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Poster Thumbnail
                            ClipRRect(
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(12),
                              ),
                              child: SizedBox(
                                width: 85,
                                height: 115,
                                child: anime.imageUrl.isNotEmpty
                                    ? Image.network(
                                        anime.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  color: colorScheme
                                                      .surfaceContainerHighest,
                                                  child: const Icon(
                                                    Icons.broken_image,
                                                  ),
                                                ),
                                      )
                                    : Container(
                                        color:
                                            colorScheme.surfaceContainerHighest,
                                        child: const Icon(Icons.movie),
                                      ),
                              ),
                            ),

                            // Anime Info
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      anime.displayTitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        if (anime.score != null) ...[
                                          const Icon(
                                            Icons.star_rounded,
                                            size: 16,
                                            color: Colors.amber,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            anime.score!.toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                        ],
                                        if (anime.type != null) ...[
                                          Text(
                                            anime.type!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                        ],
                                        if (anime.episodes != null)
                                          Text(
                                            '${anime.episodes} eps',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                      ],
                                    ),
                                    if (anime.genres.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        anime.genres.take(3).join(', '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.6),
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 40, right: 8),
                              child: Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // User Avatar Circle
          CircleAvatar(
            radius: 48,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              widget.username.isNotEmpty
                  ? widget.username[0].toUpperCase()
                  : 'U',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Welcome text with passed data
          Text(
            'Welcome, ${widget.username}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),

          const SizedBox(height: 28),

          // Passed User Details Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.account_circle_outlined),
                    title: const Text('Username'),
                    subtitle: Text(
                      widget.username,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.verified_user_outlined),
                    title: Text('Account Status'),
                    subtitle: Text(
                      'Active Guest Session',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.api_rounded),
                    title: Text('Data Provider'),
                    subtitle: Text('Jikan REST API v4 with AniList fallback'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Clear Data Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _clearAllData,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Clear History & My List'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(ThemeData theme, ColorScheme colorScheme) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colorScheme.primary,
                    child: Text(
                      widget.username.isNotEmpty
                          ? widget.username[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.username,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'AnimeAPI',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                _currentTabIndex == 0
                    ? Icons.movie_rounded
                    : Icons.movie_outlined,
              ),
              title: const Text('Home'),
              selected: _currentTabIndex == 0,
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentTabIndex = 0);
              },
            ),
            ListTile(
              leading: Icon(
                _currentTabIndex == 1
                    ? Icons.search_rounded
                    : Icons.search_outlined,
              ),
              title: const Text('Browse'),
              selected: _currentTabIndex == 1,
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentTabIndex = 1);
              },
            ),
            ListTile(
              leading: Icon(
                _currentTabIndex == 2
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
              ),
              title: const Text('My List'),
              selected: _currentTabIndex == 2,
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentTabIndex = 2);
              },
            ),
            ListTile(
              leading: Icon(
                _currentTabIndex == 3
                    ? Icons.history_rounded
                    : Icons.history_outlined,
              ),
              title: const Text('History'),
              selected: _currentTabIndex == 3,
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentTabIndex = 3);
              },
            ),
            ListTile(
              leading: Icon(
                _currentTabIndex == 4
                    ? Icons.person_rounded
                    : Icons.person_outline_rounded,
              ),
              title: const Text('Profile'),
              selected: _currentTabIndex == 4,
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentTabIndex = 4);
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading:
                  const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
              title: const Text(
                'Clear Saved Data',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _clearAllData();
              },
            ),
          ],
        ),
      ),
    );
  }
}
