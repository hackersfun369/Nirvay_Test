import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'services/database_service.dart';
import 'services/music_provider.dart';
import 'services/player_provider.dart';
import 'services/download_provider.dart';
import 'services/playlist_provider.dart';
import 'services/favorites_provider.dart';
import 'ui/screens/home_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Audio background (NO await = faster startup)
  JustAudioBackground.init(
    androidNotificationChannelId: 'com.nirvay.music.playback',
    androidNotificationChannelName: 'Nirvay Playback',
    androidNotificationOngoing: true,
  );

  runApp(const NirvayApp());
}

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
        theme: SpotifyTheme.theme,
        debugShowCheckedModeBanner: false,
        home: const SplashLoader(),
      ),
    );
  }
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
