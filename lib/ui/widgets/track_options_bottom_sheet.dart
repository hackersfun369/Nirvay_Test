import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/music_track.dart';
import '../../models/local_playlist.dart';
import '../../services/player_provider.dart';
import '../../services/favorites_provider.dart';
import '../../services/playlist_provider.dart';
import '../theme.dart';
import 'add_to_playlist_dialog.dart';

class TrackOptionsBottomSheet extends StatelessWidget {
  final MusicTrack track;
  final LocalPlaylist? playlist;

  const TrackOptionsBottomSheet({super.key, required this.track, this.playlist});

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final isLiked = favoritesProvider.isLiked(track.id);

    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          // Like/Unlike Option
          ListTile(
            leading: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? SpotifyColors.green : Colors.white,
            ),
            title: Text(isLiked ? 'Remove from Liked Songs' : 'Add to Liked Songs', style: const TextStyle(color: Colors.white)),
            onTap: () async {
              await favoritesProvider.toggleLike(track);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isLiked ? 'Removed from Liked Songs' : 'Added to Liked Songs')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.queue_music, color: Colors.white),
            title: const Text('Add to Queue', style: TextStyle(color: Colors.white)),
            onTap: () {
              Provider.of<PlayerProvider>(context, listen: false).addToQueue(track);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added ${track.title} to queue')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add, color: Colors.white),
            title: const Text('Add to Playlist', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => AddToPlaylistDialog(track: track),
              );
            },
          ),
          // Remove from Playlist Option (Conditional)
          if (playlist != null)
            ListTile(
              leading: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
              title: const Text('Remove from this playlist', style: TextStyle(color: Colors.white)),
              onTap: () async {
                await Provider.of<PlaylistProvider>(context, listen: false).removeFromPlaylist(playlist!, track.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Removed ${track.title} from ${playlist!.name}')),
                  );
                }
              },
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static void show(BuildContext context, MusicTrack track, {LocalPlaylist? playlist}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SpotifyColors.darkGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TrackOptionsBottomSheet(track: track, playlist: playlist),
    );
  }
}
