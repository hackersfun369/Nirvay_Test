import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/music_provider.dart';
import '../../services/player_provider.dart';
import '../../services/favorites_provider.dart';
import '../../models/music_track.dart';
import '../widgets/track_options_bottom_sheet.dart';
import '../theme.dart';

class ArtistScreen extends StatefulWidget {
  final String artistId;
  final String artistName;
  final String? artistImageUrl;
  final MusicSource? source;

  const ArtistScreen({
    super.key,
    required this.artistId,
    required this.artistName,
    this.artistImageUrl,
    this.source,
  });

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  late Future<List<MusicTrack>> _tracksFuture;

  @override
  void initState() {
    super.initState();
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    _tracksFuture = _fetchAndProcessTracks(musicProvider);
  }

  Future<List<MusicTrack>> _fetchAndProcessTracks(MusicProvider musicProvider) async {
    final rawTracks = await musicProvider.getArtistTracks(
      widget.artistId, 
      widget.artistName,
      source: widget.source,
    );
    
    // Process tracks once after fetching
    return rawTracks.map((t) {
      var updatedTrack = t;
      
      // Fix Artist if unknown (use current artist name as fallback)
      if ((updatedTrack.artist == 'Unknown' || updatedTrack.artist.isEmpty)) {
        updatedTrack = updatedTrack.copyWith(artist: widget.artistName);
      }

      // Sync Images (use artist photo as fallback)
      if (widget.artistImageUrl != null && widget.artistImageUrl!.isNotEmpty) {
        if (updatedTrack.albumArtUrl == null || 
            updatedTrack.albumArtUrl!.isEmpty || 
            updatedTrack.albumArtUrl!.contains('on__music_logo_mono')) {
          
          final thumbs = Map<String, String>.from(updatedTrack.thumbnails ?? {});
          thumbs['large'] = widget.artistImageUrl!;
          thumbs['medium'] = widget.artistImageUrl!;
          thumbs['small'] = widget.artistImageUrl!;
          
          updatedTrack = updatedTrack.copyWith(
            albumArtUrl: widget.artistImageUrl,
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
                expandedHeight: 250,
                pinned: true,
                centerTitle: false,
                title: Text(
                  widget.artistName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                  ),
                ),
                actions: [
                  Consumer<FavoritesProvider>(
                    builder: (context, favorites, _) {
                      final isSaved = favorites.isSaved(widget.artistId);
                      return IconButton(
                        icon: Icon(isSaved ? Icons.favorite : Icons.favorite_border),
                        color: isSaved ? SpotifyColors.green : Colors.white,
                        onPressed: () async {
                          await favorites.toggleSave(
                            MusicTrack(
                              id: widget.artistId,
                              title: widget.artistName,
                              artist: 'Artist',
                              album: 'Artist',
                              albumArtUrl: widget.artistImageUrl ?? '',
                              source: widget.source ?? MusicSource.youtube,
                            ),
                            'artist',
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
                      widget.artistImageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: widget.artistImageUrl!, 
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: Colors.black12),
                              errorWidget: (context, url, error) => const Icon(Icons.error),
                            )
                          : Container(color: Colors.grey[900], child: const Icon(Icons.person, size: 100)),
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
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Text(
                          '${tracks.length} songs',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
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
                    child: Text('Top Songs', style: Theme.of(context).textTheme.titleLarge),
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
