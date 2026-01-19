import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../services/youtube_service.dart';


import 'package:just_audio_background/just_audio_background.dart';

import 'services/music_provider.dart';
import 'services/player_provider.dart';
import 'services/download_provider.dart';
import 'services/playlist_provider.dart';
import 'services/favorites_provider.dart';
import 'services/database_service.dart';
import 'ui/screens/home_screen.dart';
import 'ui/widgets/mini_player.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = GlobalHttpOverrides();

  // ✅ Initialize Audio Background in parallel
  JustAudioBackground.init(
    androidNotificationChannelId: 'com.nirvay.music.playback',
    androidNotificationChannelName: 'Nirvay Playback',
    androidNotificationOngoing: true,
  ).catchError((e) => debugPrint('⚠️ JustAudioBackground failed: $e'));

  runApp(const NirvayApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NirvayApp extends StatelessWidget {
  const NirvayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MusicProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: MaterialApp(
        title: 'Nirvay',
        navigatorKey: navigatorKey,
        theme: SpotifyTheme.theme,
        debugShowCheckedModeBanner: false,
        home: const SplashLoader(),
      ),
    );
  }
}

// Add this at the bottom of main.dart, after the NirvayApp class
class TestPlayer extends StatefulWidget {
  final String videoId;

  const TestPlayer({Key? key, required this.videoId}) : super(key: key);

  @override
  State<TestPlayer> createState() => _TestPlayerState();
}

class _TestPlayerState extends State<TestPlayer> {
  final player = AudioPlayer();
  String log = 'Tap Play';

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> playFromYouTube() async {
    setState(() => log = 'Extracting audio...');

    try {
      final url = await YouTubeService().getAudioStreamUrl(widget.videoId);
      setState(() => log = '✅ SUCCESS\nStream URL: $url\n\nPlaying...');
      
      await player.setUrl(url);
      await player.play();
    } catch (e) {
      setState(() => log = '❌ Error: $e');
      debugPrint('Playback error: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Test YouTube Player')),
    body: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: playFromYouTube,
            child: Text('Play YouTube Audio'),
          ),
          SizedBox(height: 20),
          Expanded(child: SingleChildScrollView(child: Text(log))),
          IconButton(
            icon: Icon(Icons.play_arrow),
            onPressed: () => player.play(),
          ),
          IconButton(
            icon: Icon(Icons.pause),
            onPressed: () => player.pause(),
          ),
        ],
      ),
    ),
  );
}


class SplashLoader extends StatefulWidget {
  const SplashLoader({super.key});

  @override
  State<SplashLoader> createState() => _SplashLoaderState();
}

class _SplashLoaderState extends State<SplashLoader> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await DatabaseService.init();
      await context.read<DownloadProvider>().init();
      await context.read<PlaylistProvider>().loadPlaylists();
      await context.read<FavoritesProvider>().loadFavorites();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e, st) {
      debugPrint('❌ Init failed: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Global HTTP overrides to set a desktop-like User-Agent
/// This prevents 403 (Forbidden) responses from YouTube when streaming directly
class GlobalHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36';
  }
}
