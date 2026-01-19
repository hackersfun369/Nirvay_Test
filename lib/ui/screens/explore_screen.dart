import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/music_provider.dart';
import '../../services/player_provider.dart';
import '../../models/music_track.dart';
import '../widgets/add_to_playlist_dialog.dart';
import '../widgets/track_options_bottom_sheet.dart';
import '../theme.dart';
import 'album_screen.dart';
import 'online_playlist_screen.dart';
import '../widgets/spotify_widgets.dart'; // Re-added this as it was implicitly removed by the provided import list but is needed.

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<MusicProvider>(context, listen: false);
      provider.fetchExploreData();
      provider.loadSearchHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: SpotifyColors.black),
                      hintText: 'What do you want to listen to?',
                      hintStyle: const TextStyle(color: SpotifyColors.black, fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.black),
                            onPressed: () {
                               _searchController.clear();
                               musicProvider.fetchSuggestions('');
                               // Explicitly rebuild to show history
                               setState(() {});
                            },
                          ) 
                        : null,
                    ),
                    onChanged: (value) {
                       _debounce?.cancel();
                       _debounce = Timer(const Duration(milliseconds: 400), () {
                          musicProvider.fetchSuggestions(value);
                       });
                       setState(() {}); // Rebuild to toggle between history/suggestions
                    },
                    onSubmitted: (value) {
                      musicProvider.search(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSourceToggle(musicProvider),
                ],
              ),
            ),
            Expanded(
              child: _buildContent(musicProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceToggle(MusicProvider provider) {
    return Row(
      children: [
        _SourceChip(
          label: 'YouTube Music',
          isSelected: provider.currentSource == MusicSource.youtube,
          onTap: () => provider.setSource(MusicSource.youtube),
        ),
        const SizedBox(width: 8),
        _SourceChip(
          label: 'JioSaavn',
          isSelected: provider.currentSource == MusicSource.saavn,
          onTap: () => provider.setSource(MusicSource.saavn),
        ),
      ],
    );
  }

  Widget _buildSearchResults(MusicProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: SpotifyColors.green));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (provider.songs.isNotEmpty) ...[
          _buildResultSection('Songs', provider.songs),
        ],
        // IMPORTANT: We intentionally exclude Albums, Artists, and Playlists here
        // as per the requirement to show "Only Songs" in Explore.
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildResultSection(String title, List<MusicTrack> items, {bool isHorizontal = false, bool isCircle = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        isHorizontal
            ? SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return SpotifyCard(
                      title: item.title,
                      subtitle: item.artist,
                      imageUrl: item.albumArtUrl ?? '',
                      onTap: () => _handleItemTap(context, item, type: title),
                    );
                  },
                ),
              )
            : Column(
                children: items.map((item) => ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CachedNetworkImage(
                      imageUrl: item.albumArtUrl ?? '', 
                      width: 50, 
                      height: 50, 
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: SpotifyColors.lightGrey),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(item.artist, style: const TextStyle(color: SpotifyColors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                  onLongPress: () => TrackOptionsBottomSheet.show(context, item),
                  trailing: title == 'Songs' || title == 'Search Results' ? IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white54),
                    onPressed: () => TrackOptionsBottomSheet.show(context, item),
                  ) : null,
                  onTap: () => _handleItemTap(context, item, type: title),
                )).toList(),
              ),
      ],
    );
  }

  void _handleItemTap(BuildContext context, MusicTrack item, {String type = 'Song'}) {
    if (type == 'Albums') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AlbumScreen(
            albumId: item.id,
            albumName: item.title,
            artistName: item.artist,
            albumArtUrl: item.albumArtUrl,
            source: item.source,
          ),
        ),
      );
    } else if (type == 'Playlists') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OnlinePlaylistScreen(
            playlistId: item.id,
            playlistName: item.title,
            imageUrl: item.albumArtUrl,
          ),
        ),
      );
    } else {
      // Songs or others -> Play
      Provider.of<PlayerProvider>(context, listen: false).play(context, item);
    }
  }

  Widget _buildContent(MusicProvider provider) {
    if (_searchController.text.isEmpty) {
      return _buildSearchHistory(provider);
    } else if (provider.songs.isEmpty && provider.albums.isEmpty && !provider.isLoading) {
      return _buildSuggestions(provider);
    } else {
      return _buildSearchResults(provider);
    }
  }

  Widget _buildSearchHistory(MusicProvider provider) {
    if (provider.searchHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: SpotifyColors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Search History',
              style: TextStyle(color: SpotifyColors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Searches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => provider.clearSearchHistory(),
              child: const Text('Clear', style: TextStyle(color: SpotifyColors.grey)),
            ),
          ],
        ),
        ...provider.searchHistory.map((history) => ListTile(
          leading: const Icon(Icons.history, color: SpotifyColors.grey),
          title: Text(history.query, style: const TextStyle(color: Colors.white)),
          trailing: const Icon(Icons.north_west, size: 16, color: SpotifyColors.grey),
          onTap: () {
            _searchController.text = history.query;
            provider.search(history.query);
          },
        )),
      ],
    );
  }

  Widget _buildSuggestions(MusicProvider provider) {
    if (provider.suggestions.isEmpty) {
       return const SizedBox.shrink(); 
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: provider.suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = provider.suggestions[index];
        return ListTile(
          leading: const Icon(Icons.search, color: SpotifyColors.grey),
          title: Text(suggestion, style: const TextStyle(color: Colors.white)),
          onTap: () {
            _searchController.text = suggestion;
            provider.search(suggestion);
          },
        );
      },
    );
  }
}

class _SourceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SourceChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? SpotifyColors.green : SpotifyColors.lightGrey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

