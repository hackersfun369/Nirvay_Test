import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/playlist_provider.dart';
import '../../services/player_provider.dart';
import '../../models/local_playlist.dart';
import '../widgets/track_options_bottom_sheet.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final int playlistId;
  final String playlistName;

  const PlaylistDetailScreen({super.key, required this.playlistId, required this.playlistName});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, playlistProvider, child) {
        // Find the live playlist object
        final playlist = playlistProvider.playlists.firstWhere(
           (p) => p.id == playlistId, 
           orElse: () => LocalPlaylist()..name = playlistName // Fallback
        );
        
        // Handle deletion case (popping if not found would be better but this prevents crash)
        if (playlist.id == -9223372036854775808) { // Default ID checks
           return Scaffold(appBar: AppBar(title: Text(playlistName)), body: const Center(child: Text('Playlist not found')));
        }

        final tracks = playlistProvider.getPlaylistTracks(playlist);

        return Scaffold(
          appBar: AppBar(
            title: Text(playlist.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () {
                  if (tracks.isNotEmpty) {
                    Provider.of<PlayerProvider>(context, listen: false).play(context, tracks.first, initialQueue: tracks);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_forever),
                onPressed: () {
                   showDialog(
                     context: context,
                     builder: (ctx) => AlertDialog(
                       title: const Text('Delete Playlist'),
                       content: const Text('Are you sure you want to delete this playlist?'),
                       actions: [
                         TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                         TextButton(onPressed: () {
                           playlistProvider.deletePlaylist(playlistId);
                           Navigator.pop(ctx); // Close dialog
                           Navigator.pop(context); // Close screen
                         }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
                       ],
                     ),
                   );
                },
              ),
            ],
          ),
          body: tracks.isEmpty
              ? const Center(child: Text('This playlist is empty.'))
              : ListView.builder(
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return ListTile(
                      leading: track.albumArtUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: CachedNetworkImage(
                                imageUrl: track.albumArtUrl!, 
                                width: 50, 
                                height: 50, 
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(width: 50, height: 50, color: Colors.white10),
                                errorWidget: (context, url, error) => const Icon(Icons.error),
                              ),
                            )
                          : const Icon(Icons.music_note),
                      title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${track.artist}'),
                      onLongPress: () => TrackOptionsBottomSheet.show(context, track, playlist: playlist),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => TrackOptionsBottomSheet.show(context, track, playlist: playlist),
                      ),
                      onTap: () {
                        Provider.of<PlayerProvider>(context, listen: false).play(
                          context, 
                          track, 
                          initialQueue: tracks,
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}
