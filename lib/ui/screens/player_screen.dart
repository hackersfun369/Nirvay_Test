import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../services/music_provider.dart';
import '../../services/player_provider.dart';
import '../../services/download_provider.dart';
import '../../services/favorites_provider.dart';
import '../../models/music_track.dart';
import '../../services/share_service.dart';
import '../../models/lyric_line.dart';
import '../theme.dart';
import 'queue_screen.dart';
import '../widgets/add_to_playlist_dialog.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final ScrollController _scrollController = ScrollController();
  Color _dominantColor = SpotifyColors.darkGrey;
  bool _showLyrics = false;

  @override
  void initState() {
    super.initState();
  }

  String? _lastTrackId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // We'll move the palette update to a more controlled check in build or via a listener
  }

  void _checkAndUpdatePalette(MusicTrack? track) {
    if (track != null && track.id != _lastTrackId) {
      _lastTrackId = track.id;
      final imageUrl = track.thumbnails?['large'] ?? track.albumArtUrl;
      if (imageUrl != null) _updatePalette(imageUrl);
    }
  }

  void _updatePalette(String imageUrl) async {
    if (imageUrl.isEmpty) return;
    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(imageUrl),
        maximumColorCount: 8, // Reduced from 20 to save CPU
      );
      if (mounted) {
        setState(() {
          _dominantColor = paletteGenerator.dominantColor?.color ?? SpotifyColors.darkGrey;
        });
      }
    } catch (e) {
      debugPrint('Palette Error: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // DO NOT listen to the entire provider here. 
    // Use Selectors below for specific parts to prevent frequent rebuilds.
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    
    return Selector<PlayerProvider, MusicTrack?>(
      selector: (_, p) => p.currentTrack,
      builder: (context, currentTrack, _) {
        if (currentTrack == null) return const Scaffold(body: Center(child: Text('No song playing')));

        return Scaffold(
          body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _dominantColor.withOpacity(0.8),
              SpotifyColors.black,
            ],
            stops: const [0.0, 0.7],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Column(
                        children: [
                          const Text(
                            'PLAYING FROM ALBUM',
                            style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: SpotifyColors.grey),
                          ),
                          Text(
                            currentTrack.album,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          _showMoreOptions(context, currentTrack);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Artwork
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                      child: (currentTrack.thumbnails?['large'] != null && currentTrack.thumbnails!['large']!.isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: currentTrack.thumbnails!['large']!, 
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: SpotifyColors.lightGrey),
                                errorWidget: (context, url, error) => const Icon(Icons.error),
                              )
                            : (currentTrack.albumArtUrl != null && currentTrack.albumArtUrl!.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: currentTrack.albumArtUrl!, 
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(color: SpotifyColors.lightGrey),
                                    errorWidget: (context, url, error) => const Icon(Icons.error),
                                  )
                                : Container(
                                    color: SpotifyColors.lightGrey,
                                    child: const Icon(Icons.music_note, size: 100, color: Colors.white),
                                  ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                // Track Title & Artist (Directly using currentTrack from above)
                Builder(
                  builder: (context) {
                    // Trigger palette update when track changes
                    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndUpdatePalette(currentTrack));
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentTrack.title,
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontSize: 22,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  currentTrack.artist,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontSize: 16,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Consumer<FavoritesProvider>(
                            builder: (context, favorites, _) {
                              final isLiked = favorites.isLiked(currentTrack.id);
                              return IconButton(
                                icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border),
                                color: isLiked ? SpotifyColors.green : Colors.white,
                                iconSize: 28,
                                onPressed: () {
                                  favorites.toggleLike(currentTrack);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Progress Bar (Isolate high-frequency rebuilds here)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Selector<PlayerProvider, (Duration, Duration)>(
                        selector: (_, p) => (p.position, p.duration),
                        builder: (context, data, _) {
                          final position = data.$1;
                          final duration = data.$2;
                          return Column(
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor: Colors.white.withOpacity(0.2),
                                  thumbColor: Colors.white,
                                ),
                                child: Slider(
                                  value: position.inSeconds.toDouble(),
                                  max: duration.inSeconds.toDouble().clamp(1.0, double.infinity),
                                  onChanged: (value) {
                                    Provider.of<PlayerProvider>(context, listen: false).player.seek(Duration(seconds: value.toInt()));
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_formatDuration(position), style: const TextStyle(fontSize: 12, color: SpotifyColors.grey)),
                                    Text(_formatDuration(duration), style: const TextStyle(fontSize: 12, color: SpotifyColors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Controls (Trigger rebuild only for playing state)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.shuffle, size: 28, color: SpotifyColors.grey), onPressed: () {}),
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, size: 44), 
                        onPressed: () => Provider.of<PlayerProvider>(context, listen: false).skipToPrevious()
                      ),
                      Selector<PlayerProvider, bool>(
                        selector: (_, p) => p.isPlaying,
                        builder: (context, isPlaying, _) {
                          return IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                              size: 80,
                              color: Colors.white,
                            ),
                            onPressed: () => Provider.of<PlayerProvider>(context, listen: false).togglePlay(),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, size: 44), 
                        onPressed: () => Provider.of<PlayerProvider>(context, listen: false).skipToNext()
                      ),
                      IconButton(icon: const Icon(Icons.repeat_rounded, size: 28, color: SpotifyColors.grey), onPressed: () {}),
                    ],
                  ),
                ),
                
                 const SizedBox(height: 16),
                 // Queue Button
                 TextButton.icon(
                   onPressed: () {
                     Navigator.push(
                       context,
                       MaterialPageRoute(builder: (context) => const QueueScreen()),
                     );
                   },
                   icon: const Icon(Icons.queue_music, color: Colors.white),
                   label: const Text('Related', style: TextStyle(color: Colors.white)),
                 ),
                 
                 const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
   },
  );
 }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showMoreOptions(BuildContext context, MusicTrack track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF191414), // Spotify dark background
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Track Header in Menu
            ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: track.thumbnails?['small'] ?? track.albumArtUrl ?? '',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(width: 48, height: 48, color: Colors.white10),
                  errorWidget: (context, url, error) => Container(color: Colors.grey, width: 48, height: 48, child: const Icon(Icons.error)),
                ),
              ),
              title: Text(track.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(track.artist, style: const TextStyle(color: SpotifyColors.grey)),
              trailing: IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white),
                onPressed: () {}, // Info action
              ),
            ),
            const Divider(color: Colors.white24),
            
            // Play Next
            ListTile(
              leading: const Icon(Icons.play_arrow_outlined, color: Colors.white),
              title: const Text('Play Next', style: TextStyle(color: Colors.white)),
              onTap: () {
                // Determine logic to insert next
                // PlayerProvider queue manipulation needed
                 Navigator.pop(context);
              },
            ),
            
            // Add to Queue
              ListTile(
                leading: const Icon(Icons.queue_music, color: Colors.white),
                title: const Text('Add to Queue', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Provider.of<PlayerProvider>(context, listen: false).addToQueue(track);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to queue')));
                },
              ),

            // Add to Favorites
             Consumer<FavoritesProvider>(
               builder: (context, favorites, _) {
                 final isLiked = favorites.isLiked(track.id);
                 return ListTile(
                    leading: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? SpotifyColors.green : Colors.white),
                    title: Text(isLiked ? 'Remove from Favorites' : 'Add to Favorites', style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      favorites.toggleLike(track);
                      Navigator.pop(context);
                    },
                 );
               },
             ),

            // Add to Playlist
            ListTile(
              leading: const Icon(Icons.playlist_add, color: Colors.white),
              title: const Text('Add to Playlist', style: TextStyle(color: Colors.white)),
              onTap: () {
                 Navigator.pop(context); // Close menu
                 showDialog(
                   context: context,
                   builder: (context) => AddToPlaylistDialog(track: track),
                 );
              },
            ),

            // Share
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text('Share', style: TextStyle(color: Colors.white)),
              onTap: () {
                ShareService.shareTrack(track);
                Navigator.pop(context);
              },
            ),

            // Download (Moved Here)
            Consumer<DownloadProvider>(
              builder: (context, downloads, _) {
                 final isDownloaded = downloads.isDownloaded(track.id);
                 final isDownloading = downloads.downloadProgress.containsKey(track.id);
                 final progress = downloads.downloadProgress[track.id];

                 return ListTile(
                   leading: isDownloading 
                     ? SizedBox(
                         width: 24, 
                         height: 24, 
                         child: CircularProgressIndicator(
                           value: progress, // Show determinate progress
                           strokeWidth: 2, 
                           color: Colors.white,
                           backgroundColor: Colors.white24,
                         )
                       )
                     : Icon(isDownloaded ? Icons.download_done : Icons.download, color: isDownloaded ? SpotifyColors.green : Colors.white),
                   title: Text(
                     isDownloading 
                       ? 'Downloading... ${(progress != null ? (progress * 100).toInt() : 0)}%' 
                       : (isDownloaded ? 'Remove Download' : 'Download'), 
                     style: const TextStyle(color: Colors.white)
                   ),
                   onTap: () async {
                     if (isDownloading) return; // Prevent action while downloading
                     
                     if (isDownloaded) {
                       await downloads.delete(track.id);
                       if (context.mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from downloads')));
                       }
                     } else {
                       Navigator.pop(context); // Close menu immediately so user can see progress
                       final success = await downloads.download(track);
                       if (context.mounted && success) {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download Complete!')));
                       }
                     }
                   },
                 );
              },
            ),

             // Open Link
            ListTile(
              leading: const Icon(Icons.open_in_new, color: Colors.white),
              title: const Text('Open original link', style: TextStyle(color: Colors.white)),
              onTap: () {
                 // Launch URL logic
                 Navigator.pop(context);
              },
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildUpNextList(PlayerProvider provider) {
    final nextSongs = [];
    if (provider.queue.isNotEmpty && provider.currentIndex < provider.queue.length - 1) {
      for (int i = provider.currentIndex + 1; i < provider.queue.length; i++) {
        nextSongs.add(provider.queue[i]);
      }
    }

    if (nextSongs.isEmpty) {
      return const Text('End of queue', style: TextStyle(color: SpotifyColors.grey));
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: nextSongs.length,
      itemBuilder: (context, index) {
        final track = nextSongs[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              track.thumbnails?['small'] ?? track.thumbnails?['medium'] ?? track.albumArtUrl ?? '',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 48,
                height: 48,
                color: SpotifyColors.darkGrey,
                child: const Icon(Icons.music_note, color: Colors.white),
              ),
            ),
          ),
          title: Text(
            track.title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            track.artist,
            style: const TextStyle(color: SpotifyColors.grey, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
             provider.play(context, track, initialQueue: provider.queue);
          },
        );
      },
    );
  }
}
