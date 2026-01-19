import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/player_provider.dart';
import '../screens/player_screen.dart';
import '../theme.dart';
import '../../main.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final track = playerProvider.currentTrack;

    if (track == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        navigatorKey.currentState!.push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const PlayerScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              var begin = const Offset(0.0, 1.0);
              var end = Offset.zero;
              var curve = Curves.ease;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
          ),
        );
      },
      child: Container(
        height: 64,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: SpotifyColors.lightGrey,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: track.albumArtUrl != null
                          ? CachedNetworkImage(
                              imageUrl: track.albumArtUrl!, 
                              width: 40, 
                              height: 40, 
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: SpotifyColors.darkGrey),
                              errorWidget: (context, url, error) => const Icon(Icons.error),
                            )
                          : Container(
                              width: 40,
                              height: 40,
                              color: SpotifyColors.darkGrey,
                              child: const Icon(Icons.music_note, color: Colors.white, size: 20),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: SpotifyColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.devices_outlined, size: 24, color: SpotifyColors.grey),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(
                        playerProvider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                      onPressed: () => playerProvider.togglePlay(),
                    ),
                  ],
                ),
              ),
            ),
            // Tiny progress bar at bottom
            LinearProgressIndicator(
              value: playerProvider.position.inSeconds.toDouble() / 
                     playerProvider.duration.inSeconds.toDouble().clamp(1.0, double.infinity),
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 2,
            ),
          ],
        ),
      ),
    );
  }
}
