import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/music_provider.dart';
import '../../services/player_provider.dart';
import '../../services/favorites_provider.dart';
import '../../models/music_track.dart';
import '../widgets/track_options_bottom_sheet.dart';
import '../theme.dart';

class OnlinePlaylistScreen extends StatelessWidget {
  final String playlistId;
  final String playlistName;
  final String? imageUrl;

  const OnlinePlaylistScreen({
    super.key,
    required this.playlistId,
    required this.playlistName,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);

    return Scaffold(
      body: FutureBuilder<List<MusicTrack>>(
        future: musicProvider.getPlaylistTracks(playlistId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: SpotifyColors.green));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }

          var tracks = snapshot.data ?? [];

          // Ensure all tracks have an image and correct artist name
          tracks = tracks.map((t) {
            var updatedTrack = t;
            
            // Fix Artist if unknown
            if ((updatedTrack.artist == 'Unknown' || updatedTrack.artist.isEmpty)) {
               // We don't have a clear "Playlist Artist", but we can keep it as is or try to resolve
            }

            // Sync Images (use playlist cover as fallback)
            if (imageUrl != null && imageUrl!.isNotEmpty) {
              if (updatedTrack.albumArtUrl == null || 
                  updatedTrack.albumArtUrl!.isEmpty || 
                  updatedTrack.albumArtUrl!.contains('on__music_logo_mono')) {
                
                final thumbs = Map<String, String>.from(updatedTrack.thumbnails ?? {});
                thumbs['large'] = imageUrl!;
                thumbs['medium'] = imageUrl!;
                thumbs['small'] = imageUrl!;
                
                updatedTrack = updatedTrack.copyWith(
                  albumArtUrl: imageUrl,
                  thumbnails: thumbs,
                );
              }
            }
            return updatedTrack;
          }).toList();

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                actions: [
                  Consumer<FavoritesProvider>(
                    builder: (context, favorites, _) {
                      final isSaved = favorites.isSaved(playlistId);
                      return IconButton(
                        icon: Icon(isSaved ? Icons.favorite : Icons.favorite_border),
                        color: isSaved ? SpotifyColors.green : Colors.white,
                        onPressed: () async {
                          await favorites.toggleSave(
                            MusicTrack(
                              id: playlistId,
                              title: playlistName,
                              artist: 'Playlist',
                              album: 'Online Playlist',
                              albumArtUrl: imageUrl ?? '',
                              source: MusicSource.youtube,
                            ),
                            'playlist',
                          );
                        },
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    playlistName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                    ),
                    maxLines: 1,
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'playlist_$playlistId',
                        child: imageUrl != null && imageUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: imageUrl!, 
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: Colors.black26),
                                errorWidget: (context, url, error) => const Icon(Icons.error),
                              )
                            : Container(color: Colors.grey[900], child: const Icon(Icons.queue_music, size: 100, color: Colors.white)),
                      ),
                      // Gradient Overlay for visibility
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black87,
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black54,
                            ],
                            stops: [0.0, 0.3, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Playlist', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: SpotifyColors.green, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('${tracks.length} songs', style: const TextStyle(color: Colors.white54)),
                      const SizedBox(height: 16),
                      // Play All Button
                      if (tracks.isNotEmpty)
                        ElevatedButton(
                          onPressed: () {
                             Provider.of<PlayerProvider>(context, listen: false).play(context, tracks.first, initialQueue: tracks);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SpotifyColors.green,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: const Text('PLAY ALL', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final track = tracks[index];
                    return ListTile(
                      leading: Text('${index + 1}', style: const TextStyle(color: Colors.white54)),
                      title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: SpotifyColors.grey)),
                      onLongPress: () => TrackOptionsBottomSheet.show(context, track),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white54),
                        onPressed: () => TrackOptionsBottomSheet.show(context, track),
                      ),
                      onTap: () => Provider.of<PlayerProvider>(context, listen: false).play(context, track, initialQueue: tracks),
                    );
                  },
                  childCount: tracks.length,
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
      ),
    );
  }
}
