import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/music_provider.dart';
import '../../services/player_provider.dart';
import '../../services/download_provider.dart';
import '../../models/music_track.dart';
import '../widgets/mini_player.dart';
import '../widgets/spotify_widgets.dart';
import '../theme.dart';
import 'library_screen.dart';
import 'explore_screen.dart';
import 'settings_screen.dart';
import 'album_screen.dart';
import 'online_playlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _HomeView(),
    const ExploreScreen(),
    const LibraryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MusicProvider>(context, listen: false).fetchHomeContent();
    });
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context);

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (musicProvider.tracks.isNotEmpty || musicProvider.trendingTracks.isNotEmpty)
            const MiniPlayer(),
          BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_filled),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                activeIcon: Icon(Icons.search),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music_outlined),
                activeIcon: Icon(Icons.library_music),
                label: 'Your Library',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context);
    final playerProvider = Provider.of<PlayerProvider>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF303030),
              SpotifyColors.black,
            ],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getGreeting(),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Row(
                          children: [
                            //IconButton(
                            //  icon: const Icon(Icons.notifications_none),
                            //  onPressed: () {},
                            //),
                            //IconButton(
                            // icon: const Icon(Icons.history),
                            //  onPressed: () {},
                            //),
                            IconButton(
                              icon: const Icon(Icons.settings_outlined),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SettingsScreen()),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Welcome Grid
                    // Welcome Grid (Prioritize Personal History -> Quick Picks -> Trending)
                    if (musicProvider.recentlyPlayed.isNotEmpty || musicProvider.quickPicks.isNotEmpty || musicProvider.trendingTracks.isNotEmpty)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 3,
                        ),
                        itemCount: (musicProvider.recentlyPlayed.isNotEmpty 
                            ? musicProvider.recentlyPlayed.length 
                            : (musicProvider.quickPicks.isNotEmpty 
                                ? musicProvider.quickPicks.length 
                                : musicProvider.trendingTracks.length)).clamp(0, 6),
                        itemBuilder: (context, index) {
                          final list = musicProvider.recentlyPlayed.isNotEmpty 
                              ? musicProvider.recentlyPlayed 
                              : (musicProvider.quickPicks.isNotEmpty 
                                  ? musicProvider.quickPicks 
                                  : musicProvider.trendingTracks);
                          final track = list[index];
                          return SpotifyWelcomeCard(
                            title: track.title,
                            imageUrl: track.albumArtUrl ?? '',
                            onTap: () => playerProvider.play(context, track),
                          );
                        },
                      ),
                  ]),
                ),
              ),

                    // Quick Picks (Top Priority)
                    if (musicProvider.quickPicks.isNotEmpty) ...[
                       const SliverToBoxAdapter(child: SizedBox(height: 24)), // Spacing
                       SliverToBoxAdapter(child: _SectionHeader(title: 'Quick Picks for You', padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8))),
                       SliverToBoxAdapter(
                        child: SizedBox(
                          height: 220,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(left: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: musicProvider.quickPicks.length,
                            itemBuilder: (context, index) {
                              final track = musicProvider.quickPicks[index];
                              return SpotifyCard(
                                title: track.title,
                                subtitle: track.artist,
                                imageUrl: track.albumArtUrl ?? '',
                                onTap: () => playerProvider.play(context, track),
                              );
                            },
                          ),
                        ),
                      ),
                    ],

                    // Recently Played (Horizontal List)
                    if (musicProvider.recentlyPlayed.isNotEmpty) ...[
                      SliverToBoxAdapter(child: _SectionHeader(title: 'Jump Back In', padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16))),
                       SliverToBoxAdapter(
                        child: SizedBox(
                          height: 220,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(left: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: (musicProvider.recentlyPlayed.length), // No deduplication needed here if Provider handles it
                            itemBuilder: (context, index) {
                              final track = musicProvider.recentlyPlayed[index];
                              return SpotifyCard(
                                title: track.title,
                                subtitle: track.artist,
                                imageUrl: track.albumArtUrl ?? '',
                                onTap: () => playerProvider.play(context, track),
                              );
                            },
                          ),
                        ),
                      ),
                    ],

                    // Top Charts
                    if (musicProvider.charts.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: _SectionHeader(title: 'Top Charts', padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8))
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 240,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(left: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: musicProvider.charts.length,
                            itemBuilder: (context, index) {
                              final chart = musicProvider.charts[index];
                              return SpotifyCard(
                                title: chart.title,
                                subtitle: 'Chart',
                                imageUrl: chart.albumArtUrl ?? '',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OnlinePlaylistScreen(
                                      playlistId: chart.id,
                                      playlistName: chart.title,
                                      imageUrl: chart.albumArtUrl,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],

                    // New Releases
                    if (musicProvider.newReleases.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: _SectionHeader(title: 'New Releases', padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8))
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 240,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(left: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: musicProvider.newReleases.length,
                            itemBuilder: (context, index) {
                              final album = musicProvider.newReleases[index];
                              return SpotifyCard(
                                title: album.title,
                                subtitle: album.artist,
                                imageUrl: album.albumArtUrl ?? '',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AlbumScreen(
                                      albumId: album.id,
                                      albumName: album.title,
                                      artistName: album.artist,
                                      albumArtUrl: album.albumArtUrl,
                                      source: album.source,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],

                // Related Albums (Albums You Might Like)
                if (musicProvider.relatedAlbums.isNotEmpty) ...[
                   SliverToBoxAdapter(child: _SectionHeader(title: 'Albums You Might Like', padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16))),
                   SliverToBoxAdapter(
                    child: SizedBox(
                      height: 220,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(left: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: musicProvider.relatedAlbums.length,
                        itemBuilder: (context, index) {
                          final album = musicProvider.relatedAlbums[index];
                          return SpotifyCard(
                            title: album.title,
                            subtitle: album.artist,
                            imageUrl: album.albumArtUrl ?? '',
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AlbumScreen(
                                    albumId: album.id,
                                    albumName: album.title,
                                    artistName: album.artist,
                                    albumArtUrl: album.albumArtUrl,
                                    source: album.source,
                                  ),
                                ),
                              ),
                          );
                        },
                      ),
                    ),
                  ),
                ],

                // Related Artists
                if (musicProvider.relatedArtists.isNotEmpty) ...[
                   SliverToBoxAdapter(child: _SectionHeader(title: 'Similar Artists', padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16))),
                   SliverToBoxAdapter(
                    child: SizedBox(
                      height: 220,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(left: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: musicProvider.relatedArtists.length,
                        itemBuilder: (context, index) {
                          final artist = musicProvider.relatedArtists[index];
                          return SpotifyCard(
                            title: artist.title,
                            subtitle: 'Artist',
                            imageUrl: artist.albumArtUrl ?? '',
                            onTap: () => playerProvider.play(context, artist),
                          );
                        },
                      ),
                    ),
                  ),
                ],

              // Empty state when no listening history
              if (musicProvider.recentlyPlayed.isEmpty) ...[
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.music_note, size: 64, color: Colors.white24),
                        SizedBox(height: 16),
                        Text(
                          'Start listening to music',
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your personalized recommendations will appear here',
                          style: TextStyle(color: Colors.white38, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry padding;

  const _SectionHeader({
    required this.title, 
    this.padding = EdgeInsets.zero
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
