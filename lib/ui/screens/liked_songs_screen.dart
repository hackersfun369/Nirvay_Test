import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/favorites_provider.dart';
import '../../services/player_provider.dart';
import '../../models/music_track.dart';
import '../widgets/track_options_bottom_sheet.dart';
import '../widgets/spotify_widgets.dart';
import '../theme.dart';

class LikedSongsScreen extends StatelessWidget {
  const LikedSongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    // Convert LikedSongs to MusicTracks for playback
    final tracks = favoritesProvider.likedSongs.map((song) => MusicTrack(
      id: song.trackId,
      title: song.title,
      artist: song.artist,
      album: 'Liked Songs',
      albumArtUrl: song.albumArtUrl,
      source: song.source == 'MusicSource.youtube' ? MusicSource.youtube : MusicSource.saavn,
    )).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF450AF5),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Liked Songs'),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF450AF5), Color(0xFF121212)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite, size: 64, color: Colors.white),
                      const SizedBox(height: 16),
                      Text('${tracks.length} songs', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (tracks.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('No liked songs yet', style: TextStyle(color: Colors.white)),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = tracks[index];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: track.albumArtUrl ?? '',
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(width: 48, height: 48, color: Colors.white10),
                        errorWidget: (context, url, error) => Container(color: Colors.grey, width: 48, height: 48, child: const Icon(Icons.music_note)),
                      ),
                    ),
                    title: Text(track.title, style: const TextStyle(color: Colors.white), maxLines: 1),
                    subtitle: Text(track.artist, style: const TextStyle(color: Colors.white70), maxLines: 1),
                    onLongPress: () => TrackOptionsBottomSheet.show(context, track),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white54),
                      onPressed: () => TrackOptionsBottomSheet.show(context, track),
                    ),
                    onTap: () {
                      playerProvider.play(context, track, initialQueue: tracks);
                    },
                  );
                },
                childCount: tracks.length,
              ),
            ),
             const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }
}
