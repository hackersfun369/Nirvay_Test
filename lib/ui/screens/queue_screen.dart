import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/player_provider.dart';
import '../../models/music_track.dart';
import '../theme.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // DO NOT listen to the entire provider here
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Related', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.black,
      body: Selector<PlayerProvider, (MusicTrack?, List<MusicTrack>, List<MusicTrack>)>(
        selector: (_, p) => (p.currentTrack, p.userQueue, p.relatedTracks),
        builder: (context, data, _) {
          final currentTrack = data.$1;
          final userQueue = data.$2;
          final relatedTracks = data.$3;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: 2 + (userQueue.length) + (relatedTracks.length),
            itemBuilder: (context, index) {
              // Now Playing Section
              if (index == 0) {
                if (currentTrack == null) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Now Playing', style: TextStyle(color: SpotifyColors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    _buildTrackTile(context, currentTrack, playerProvider, isCurrent: true),
                    const SizedBox(height: 24),
                  ],
                );
              }

              // User Queue Title
              if (index == 1) {
                if (userQueue.isEmpty) return const SizedBox.shrink();
                return const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text('Next in Queue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                );
              }

              // User Queue Items
              final userQueueIndex = index - 2;
              if (userQueueIndex < userQueue.length) {
                return _buildTrackTile(context, userQueue[userQueueIndex], playerProvider);
              }

              // Related Title / Items
              final relatedBaseIndex = 2 + userQueue.length;
              final relatedIndex = index - relatedBaseIndex;

              if (relatedIndex == 0) {
                if (relatedTracks.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
                  child: Text('Related to ${currentTrack?.title ?? "current song"}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                );
              }

              final actualRelatedIndex = relatedIndex - 1;
              if (actualRelatedIndex < relatedTracks.length) {
                return _buildTrackTile(context, relatedTracks[actualRelatedIndex], playerProvider, isRelated: true);
              }

              return const SizedBox(height: 48);
            },
          );
        },
      ),
    );
  }

  Widget _buildTrackTile(BuildContext context, MusicTrack track, PlayerProvider provider, {bool isCurrent = false, bool isRelated = false}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          imageUrl: track.thumbnails?['small'] ?? track.thumbnails?['medium'] ?? track.albumArtUrl ?? '',
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(width: 48, height: 48, color: SpotifyColors.darkGrey),
          errorWidget: (context, url, error) => Container(
            width: 48,
            height: 48,
            color: SpotifyColors.darkGrey,
            child: const Icon(Icons.music_note, color: Colors.white),
          ),
        ),
      ),
      title: Text(
        track.title,
        style: TextStyle(color: isCurrent ? SpotifyColors.green : Colors.white, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        track.artist,
        style: const TextStyle(color: SpotifyColors.grey, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isRelated 
         ? IconButton(
             icon: const Icon(Icons.add_circle_outline, color: Colors.white),
             onPressed: () {
               provider.addToQueue(track);
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Queue')));
             },
           )
         : null,
      onTap: () {
        if (isRelated) {
           // Play related immediately effectively "skips" to it
           provider.play(context, track); 
        } else if (!isCurrent) {
           // Skip to this track. 
           // Since we don't have a unified index anymore, we just play it.
           provider.play(context, track);
        }
      },
    );
  }
}
