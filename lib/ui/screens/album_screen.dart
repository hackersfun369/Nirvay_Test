import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/music_provider.dart';
import '../../services/player_provider.dart';
import '../../services/favorites_provider.dart';
import '../../models/music_track.dart';
import '../widgets/track_options_bottom_sheet.dart';
import '../theme.dart';

class AlbumScreen extends StatefulWidget {
  final String albumId;
  final String albumName;
  final String artistName;
  final String? albumArtUrl;

  const AlbumScreen({
    super.key,
    required this.albumId,
    required this.albumName,
    required this.artistName,
    this.albumArtUrl,
  });

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  late Future<List<MusicTrack>> _tracksFuture;

  @override
  void initState() {
    super.initState();
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    _tracksFuture = _fetchAndProcessTracks(musicProvider);
  }

  Future<List<MusicTrack>> _fetchAndProcessTracks(MusicProvider musicProvider) async {
    final rawTracks = await musicProvider.getAlbumTracks(widget.albumId, widget.albumName, widget.artistName);
    
    // Process tracks once after fetching
    return rawTracks.map((t) {
      var updatedTrack = t;
      
      // Fix Artist if unknown
      if ((updatedTrack.artist == 'Unknown' || updatedTrack.artist.isEmpty) && widget.artistName != 'Unknown') {
        updatedTrack = updatedTrack.copyWith(artist: widget.artistName);
      }

      // Sync Images (Force album art for consistency if track art is missing/low quality)
      if (widget.albumArtUrl != null && widget.albumArtUrl!.isNotEmpty) {
        if (updatedTrack.albumArtUrl == null || 
            updatedTrack.albumArtUrl!.isEmpty || 
            updatedTrack.albumArtUrl!.contains('on__music_logo_mono')) {
          
          final thumbs = Map<String, String>.from(updatedTrack.thumbnails ?? {});
          thumbs['large'] = widget.albumArtUrl!;
          thumbs['medium'] = widget.albumArtUrl!;
          thumbs['small'] = widget.albumArtUrl!;
          
          updatedTrack = updatedTrack.copyWith(
            albumArtUrl: widget.albumArtUrl,
            thumbnails: thumbs,
          );
        }
      }
      return updatedTrack;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<MusicTrack>>(
        future: _tracksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final tracks = snapshot.data ?? [];
          
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                centerTitle: false,
                title: Text(
                  widget.albumName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  Consumer<FavoritesProvider>(
                    builder: (context, favorites, _) {
                      final isSaved = favorites.isSaved(widget.albumId);
                      return IconButton(
                        icon: Icon(isSaved ? Icons.favorite : Icons.favorite_border),
                        color: isSaved ? SpotifyColors.green : Colors.white,
                        onPressed: () async {
                          await favorites.toggleSave(
                            MusicTrack(
                              id: widget.albumId,
                              title: widget.albumName,
                              artist: widget.artistName,
                              album: widget.albumName,
                              albumArtUrl: widget.albumArtUrl ?? '',
                              source: MusicSource.youtube,
                            ),
                            'album',
                          );
                        },
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'album_${widget.albumId}',
                        child: widget.albumArtUrl != null
                            ? CachedNetworkImage(
                                imageUrl: widget.albumArtUrl!, 
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: Colors.black12),
                                errorWidget: (context, url, error) => const Icon(Icons.error),
                              )
                            : Container(color: Colors.grey[900], child: const Icon(Icons.album, size: 100)),
                      ),
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
              if (tracks.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text('No tracks found', style: TextStyle(color: Colors.white)),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.artistName, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text('${tracks.length} songs', style: const TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
                ),
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
                            placeholder: (context, url) => Container(color: Colors.white10),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey,
                              width: 48,
                              height: 48,
                              child: const Icon(Icons.music_note, color: Colors.white54),
                            ),
                          ),
                        ),
                        title: Text(
                          track.title,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          track.artist,
                          style: const TextStyle(color: Colors.white70),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
            ],
          );
        },
      ),
    );
  }
}
