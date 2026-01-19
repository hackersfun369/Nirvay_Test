import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/download_provider.dart';
import '../../services/player_provider.dart';
import '../../services/playlist_provider.dart';
import '../../services/favorites_provider.dart';
import '../../models/local_playlist.dart';
import '../../models/music_track.dart';
import '../widgets/add_to_playlist_dialog.dart';
import 'playlist_detail_screen.dart';
import '../theme.dart';
import 'liked_songs_screen.dart';
import '../../services/music_provider.dart';
import '../../services/saavn_service.dart';
import 'artist_screen.dart';
import 'album_screen.dart';
import 'online_playlist_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _selectedFilter = 'Playlists';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Your Library',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.add), onPressed: () => _showCreatePlaylistDialog(context)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: SpotifyColors.lightGrey,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search within ${_selectedFilter.toLowerCase()}...',
                    hintStyle: const TextStyle(color: SpotifyColors.grey, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: SpotifyColors.grey, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: SpotifyColors.grey, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            if (_selectedFilter == 'Artists' || _selectedFilter == 'Albums') {
                              Provider.of<MusicProvider>(context, listen: false).search('', bothSources: true);
                            }
                          },
                        )
                      : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    
                    _searchDebounce?.cancel();
                    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                      if (_selectedFilter == 'Artists' || _selectedFilter == 'Albums') {
                        if (value.length >= 2 || value.isEmpty) {
                          Provider.of<MusicProvider>(context, listen: false).search(value, bothSources: true, saveToHistory: false);
                        }
                      }
                    });
                  },
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Playlists',
                    isSelected: _selectedFilter == 'Playlists',
                    onTap: () => setState(() => _selectedFilter = 'Playlists'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Artists',
                    isSelected: _selectedFilter == 'Artists',
                    onTap: () {
                       setState(() => _selectedFilter = 'Artists');
                       if (_searchQuery.isNotEmpty) {
                         Provider.of<MusicProvider>(context, listen: false).search(_searchQuery, bothSources: true, saveToHistory: false);
                       }
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Albums',
                    isSelected: _selectedFilter == 'Albums',
                    onTap: () {
                       setState(() => _selectedFilter = 'Albums');
                       if (_searchQuery.isNotEmpty) {
                         Provider.of<MusicProvider>(context, listen: false).search(_searchQuery, bothSources: true, saveToHistory: false);
                       }
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Downloads',
                    isSelected: _selectedFilter == 'Downloads',
                    onTap: () => setState(() => _selectedFilter = 'Downloads'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_selectedFilter == 'Downloads') return _DownloadsTab(searchQuery: _searchQuery);
    if (_selectedFilter == 'Artists') return _ArtistsTab(searchQuery: _searchQuery);
    if (_selectedFilter == 'Albums') return _AlbumsTab(searchQuery: _searchQuery);
    return _PlaylistsTab(searchQuery: _searchQuery);
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SpotifyColors.lightGrey,
        title: const Text('New Playlist', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: SpotifyColors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: SpotifyColors.green)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Provider.of<PlaylistProvider>(context, listen: false).createPlaylist(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create', style: TextStyle(color: SpotifyColors.green)),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

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
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _DownloadsTab extends StatelessWidget {
  final String searchQuery;
  const _DownloadsTab({this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    final downloadProvider = Provider.of<DownloadProvider>(context);
    final tracks = downloadProvider.downloadedTracks.where((t) {
       return t.title.toLowerCase().contains(searchQuery.toLowerCase()) || 
              t.artist.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    if (tracks.isEmpty) {
      return Center(child: Text(
        searchQuery.isEmpty ? 'No offline tracks yet.' : 'No results found.', 
        style: const TextStyle(color: SpotifyColors.grey)
      ));
    }

    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: track.albumArtUrl != null
                ? CachedNetworkImage(
                    imageUrl: track.albumArtUrl!, 
                    width: 48, 
                    height: 48, 
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: SpotifyColors.lightGrey),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  )
                : Container(width: 48, height: 48, color: SpotifyColors.lightGrey, child: const Icon(Icons.music_note)),
          ),
          title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
          subtitle: Text('Track • ${track.artist}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: SpotifyColors.grey, fontSize: 12)),
          onTap: () => Provider.of<PlayerProvider>(context, listen: false).play(
            context, 
            track,
            initialQueue: tracks,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: SpotifyColors.grey),
            onPressed: () async {
               await downloadProvider.delete(track.id);
               if (context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from downloads')));
               }
            },
          ),
        );
      },
    );
  }
}

class _PlaylistsTab extends StatelessWidget {
  final String searchQuery;
  const _PlaylistsTab({this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    final playlistProvider = Provider.of<PlaylistProvider>(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);

    // Filter Logic
    final query = searchQuery.toLowerCase();
    
    final showLikedSongs = 'liked songs'.contains(query);
    final filteredPlaylists = playlistProvider.playlists.where((p) => p.name.toLowerCase().contains(query)).toList();


    // Add a virtual "Liked Songs" playlist at the top like Spotify
    final likedSongs = [
      if (showLikedSongs || query.isEmpty)
      ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF450AF5), Color(0xFFC4EFD9)],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.favorite, color: Colors.white, size: 24),
        ),
        title: const Text('Liked Songs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text('Playlist • ${favoritesProvider.likedSongs.length} songs', style: const TextStyle(color: SpotifyColors.grey, fontSize: 12)),
        onTap: () {
             Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LikedSongsScreen()),
            );
        },
      )
    ];


    // Add saved items (only playlists, not albums or artists)
    final savedEntries = favoritesProvider.savedItems
        .where((item) => item.type == 'playlist' && item.name.toLowerCase().contains(query))
        .map((item) {
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: item.imageUrl!, 
                    width: 48, 
                    height: 48, 
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: SpotifyColors.lightGrey),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  )
                : Container(width: 48, height: 48, color: SpotifyColors.lightGrey, child: const Icon(Icons.queue_music, color: SpotifyColors.grey)),
          ),
          title: Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text('Playlist • ${item.artistName ?? 'Spotify'}', style: const TextStyle(color: SpotifyColors.grey, fontSize: 12)),
          onTap: () {
            // Navigate to online playlist screen
            Navigator.push(context, MaterialPageRoute(builder: (context) => OnlinePlaylistScreen(playlistId: item.itemId, playlistName: item.name, imageUrl: item.imageUrl)));
          },
        );
    }).toList();

    if (filteredPlaylists.isEmpty && likedSongs.isEmpty && savedEntries.isEmpty) {
      return const Center(child: Text('No results found.', style: TextStyle(color: SpotifyColors.grey)));
    }

    return ListView(
      children: [
        ...likedSongs,
        ...savedEntries,
        ...filteredPlaylists.map((playlist) => ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: SpotifyColors.lightGrey,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.playlist_play, color: SpotifyColors.grey),
          ),
          title: Text(playlist.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text('Playlist • ${playlist.trackCount} songs', style: TextStyle(color: SpotifyColors.grey, fontSize: 12)),
          onTap: () {
             Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PlaylistDetailScreen(playlistId: playlist.id, playlistName: playlist.name)),
            );
          },
        )),
      ],
    );
  }
}

class _ArtistsTab extends StatelessWidget {
  final String searchQuery;
  const _ArtistsTab({this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context);
    
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final likedArtists = favoritesProvider.savedItems.where((i) => i.type == 'artist').toList();
    
    if (searchQuery.isEmpty) {
      if (likedArtists.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_search, size: 64, color: SpotifyColors.grey),
              const SizedBox(height: 16),
              const Text('Search for artists...', style: TextStyle(color: SpotifyColors.grey, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Find your favorite artists to see their top songs', style: TextStyle(color: Colors.white24, fontSize: 12)),
            ],
          ),
        );
      }
      
      return ListView.builder(
        itemCount: likedArtists.length,
        itemBuilder: (context, index) {
          final artist = likedArtists[index];
          return ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: SpotifyColors.lightGrey,
              backgroundImage: artist.imageUrl != null && artist.imageUrl!.isNotEmpty ? CachedNetworkImageProvider(artist.imageUrl!) : null,
              child: (artist.imageUrl == null || artist.imageUrl!.isEmpty) ? const Icon(Icons.person) : null,
            ),
            title: Text(artist.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('Artist', style: TextStyle(color: SpotifyColors.grey, fontSize: 12)),
            onTap: () {
              final source = artist.source == 'MusicSource.saavn' ? MusicSource.saavn : MusicSource.youtube;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ArtistScreen(
                  artistId: artist.itemId, 
                  artistName: artist.name,
                  artistImageUrl: artist.imageUrl,
                  source: source,
                )),
              );
            },
          );
        },
      );
    }

    if (musicProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (musicProvider.artists.isEmpty) {
      return const Center(child: Text('No artists found.', style: TextStyle(color: SpotifyColors.grey)));
    }

    return ListView.builder(
      itemCount: musicProvider.artists.length,
      itemBuilder: (context, index) {
        final artist = musicProvider.artists[index];
        return ListTile(
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: SpotifyColors.lightGrey,
            backgroundImage: artist.albumArtUrl != null && artist.albumArtUrl!.isNotEmpty ? CachedNetworkImageProvider(artist.albumArtUrl!) : null,
            child: (artist.albumArtUrl == null || artist.albumArtUrl!.isEmpty) ? const Icon(Icons.person) : null,
          ),
          title: Text(artist.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text(artist.source == MusicSource.youtube ? 'YouTube Music' : 'JioSaavn', style: const TextStyle(color: SpotifyColors.grey, fontSize: 12)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ArtistScreen(
                artistId: artist.id, 
                artistName: artist.title,
                artistImageUrl: artist.albumArtUrl,
                source: artist.source,
              )),
            );
          },
        );
      },
    );
  }
}

class _AlbumsTab extends StatelessWidget {
  final String searchQuery;
  const _AlbumsTab({this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context);

    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final likedAlbums = favoritesProvider.savedItems.where((i) => i.type == 'album').toList();

    if (searchQuery.isEmpty) {
      if (likedAlbums.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.album, size: 64, color: SpotifyColors.grey),
              const SizedBox(height: 16),
              const Text('Search for albums...', style: TextStyle(color: SpotifyColors.grey, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Discover albums from YouTube and JioSaavn', style: TextStyle(color: Colors.white24, fontSize: 12)),
            ],
          ),
        );
      }
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: likedAlbums.length,
        itemBuilder: (context, index) {
          final album = likedAlbums[index];
          return GestureDetector(
            onTap: () {
              final source = album.source == 'MusicSource.saavn' ? MusicSource.saavn : MusicSource.youtube;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AlbumScreen(
                  albumId: album.itemId, 
                  albumName: album.name, 
                  artistName: album.artistName ?? 'Unknown',
                  albumArtUrl: album.imageUrl,
                  source: source,
                )),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: album.imageUrl != null && album.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: album.imageUrl!, 
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: SpotifyColors.lightGrey),
                              errorWidget: (context, url, error) => const Icon(Icons.error),
                            )
                          : Container(color: SpotifyColors.lightGrey, child: const Icon(Icons.album, size: 48)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(album.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(album.artistName ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: SpotifyColors.grey, fontSize: 12)),
              ],
            ),
          );
        },
      );
    }

    if (musicProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (musicProvider.albums.isEmpty) {
      return const Center(child: Text('No albums found.', style: TextStyle(color: SpotifyColors.grey)));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: musicProvider.albums.length,
      itemBuilder: (context, index) {
        final album = musicProvider.albums[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AlbumScreen(
                albumId: album.id, 
                albumName: album.title, 
                artistName: album.artist,
                albumArtUrl: album.albumArtUrl,
                source: album.source,
              )),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: album.albumArtUrl != null && album.albumArtUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: album.albumArtUrl!, 
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: SpotifyColors.lightGrey),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          )
                        : Container(color: SpotifyColors.lightGrey, child: const Icon(Icons.album, size: 48)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(album.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(album.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: SpotifyColors.grey, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }
}
