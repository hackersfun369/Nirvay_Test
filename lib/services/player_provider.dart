import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import '../models/music_track.dart';
import '../services/youtube_service.dart';
import '../services/saavn_service.dart';
import 'download_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/lyrics_service.dart';
import '../models/lyric_line.dart';
import '../models/watch_history.dart';
import 'database_service.dart';
import 'dart:io';
import '../../main.dart';
import 'music_provider.dart';

class PlayerProvider with ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final YouTubeService _youtubeService = YouTubeService();
  final JioSaavnService _saavnService = JioSaavnService();
  final LyricsService _lyricsService = LyricsService();
  final Connectivity _connectivity = Connectivity();

  // State Variables
  MusicTrack? _currentTrack;
  List<MusicTrack> _queue = []; // Context Queue (Album/Playlist)
  List<MusicTrack> _userQueue = []; // Manual Priority Queue
  List<MusicTrack> _relatedTracks = []; // Autoplay/Recommendations
  
  int _currentIndex = -1;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  List<LyricLine> _currentLyrics = [];
  int _currentLyricIndex = -1;
  
  // Caches
  final Map<String, String> _resolvedUrls = {}; 
  final Map<String, List<LyricLine>> _resolvedLyrics = {}; 
  final Map<String, Future<String?>> _pendingUrlRequests = {}; 
  DateTime? _lastNotifyTime; 

  // Getters
  MusicTrack? get currentTrack => _currentTrack;
  int get currentIndex => _currentIndex;
  List<MusicTrack> get queue => _queue;
  List<MusicTrack> get userQueue => _userQueue;
  List<MusicTrack> get relatedTracks => _relatedTracks;
  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;
  List<LyricLine> get currentLyrics => _currentLyrics;
  int get currentLyricIndex => _currentLyricIndex;
  AudioPlayer get player => _player;

  bool _isWifi = true; 

  PlayerProvider() {
    _connectivity.onConnectivityChanged.listen((result) {
      _isWifi = result == ConnectivityResult.wifi;
    });
    // Initial check
    _connectivity.checkConnectivity().then((result) {
      _isWifi = result == ConnectivityResult.wifi;
    });

    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        _playNext();
      }
      notifyListeners();
    });

    _player.durationStream.listen((d) {
      _duration = d ?? Duration.zero;
      notifyListeners();
    });

    _player.positionStream.listen((p) {
      _position = p;
      _updateLyricIndex(p);
      
      // Throttle UI updates to once every 500ms to prevent ANRs
      final now = DateTime.now();
      if (_lastNotifyTime == null || now.difference(_lastNotifyTime!) > const Duration(milliseconds: 500)) {
        _lastNotifyTime = now;
        notifyListeners();
      }
    });
  }

  Future<void> addToQueue(MusicTrack track) async {
    _userQueue.add(track);
    notifyListeners();
  }

  Future<void> play(BuildContext context, MusicTrack track, {List<MusicTrack>? initialQueue, bool autoFetch = true}) async {
    try {
      _userQueue.clear(); 
      _relatedTracks.clear();

      if (initialQueue != null) {
        _queue = initialQueue;
        _currentIndex = _queue.indexWhere((t) => t.id == track.id);
      } else {
        _queue = [track];
        _currentIndex = 0;
      }
      
      _currentTrack = track;
      _currentLyrics = []; 
      _currentLyricIndex = -1;
      notifyListeners();

      await _loadAndPlay(context, track);

      _fetchUpNext(track);

    } catch (e) {
      print('Playback Error: $e');
    }
  }

  String? _lastFetchedTrackId;
  Future<void> fetchLyrics() async {
    if (_currentTrack == null || _currentTrack!.id == _lastFetchedTrackId) return;
    
    if (_resolvedLyrics.containsKey(_currentTrack!.id)) {
      _currentLyrics = _resolvedLyrics[_currentTrack!.id]!;
      _currentLyricIndex = 0;
      _lastFetchedTrackId = _currentTrack!.id;
      notifyListeners();
      return;
    }

    try {
      final lyrics = await _lyricsService.getLyrics(_currentTrack!.id, _currentTrack!.title, _currentTrack!.artist);
      _currentLyrics = lyrics;
      _resolvedLyrics[_currentTrack!.id] = lyrics;
      _currentLyricIndex = 0;
      _lastFetchedTrackId = _currentTrack!.id;
      notifyListeners();
    } catch (e) {
      print('Lyrics Fetch Error: $e');
    }
  }

  bool _isFetchingRelated = false;
  Future<void> _fetchUpNext(MusicTrack track) async {
    if (_isFetchingRelated) return;
    _isFetchingRelated = true;
    try {
      print('Fetching Related for ${track.source}: ${track.id}');
      List<MusicTrack> related = [];
      if (track.source == MusicSource.youtube) {
        related = await _youtubeService.getRelatedTracks(track.id);
      } else {
        related = await _saavnService.getRelatedTracks(track.id);
      }
      
      if (related.isNotEmpty) {
        final existingIds = _queue.map((t) => t.id).toSet();
        existingIds.addAll(_userQueue.map((t)=>t.id));

        _relatedTracks = related.where((t) => !existingIds.contains(t.id)).toList();
        notifyListeners();
        
        _preFetchContent();
      }
    } catch (e) {
      print('Error fetching Up Next: $e');
    } finally {
      _isFetchingRelated = false;
    }
  }

  Future<void> _preFetchContent() async {
    // Basic prefetch implementation
    for (int i = 0; i < 2 && i < _userQueue.length; i++) {
        final track = _userQueue[i];
         if (!_resolvedUrls.containsKey(track.id)) {
            _resolveUrl(track).then((url) { if(url != null) _resolvedUrls[track.id] = url; });
         }
    }
  }

  Future<String?> _resolveUrl(MusicTrack track) async {
    if (track.isDownloaded && track.localPath != null) return track.localPath;
    
    if (_pendingUrlRequests.containsKey(track.id)) {
      return _pendingUrlRequests[track.id];
    }

    final future = _performUrlResolution(track);
    _pendingUrlRequests[track.id] = future;
    
    try {
      final url = await future;
      _pendingUrlRequests.remove(track.id);
      return url;
    } catch (e) {
      _pendingUrlRequests.remove(track.id);
      rethrow;
    }
  }

  Future<String?> _performUrlResolution(MusicTrack track) async {
    final isWifi = _isWifi;

    if (track.source == MusicSource.youtube) {
      return await _youtubeService.getAudioStreamUrl(track.id);
    } else {
      return await _saavnService.getAudioStreamUrl(
        track.id,
        highQuality: isWifi,
        encryptedUrl: track.encryptedMediaUrl,
      );
    }
  }

  bool _isSkipping = false;

  Future<void> _playNext({bool force = false}) async {
    if (_isSkipping && !force) return;
    _isSkipping = true;

    try {
      MusicTrack? nextTrack;

      // 1. Check User Queue (Priority)
      if (_userQueue.isNotEmpty) {
        nextTrack = _userQueue.removeAt(0);
        _queue.add(nextTrack); 
        _currentIndex = _queue.length - 1; 
      } 
      // 2. Check Context Queue (Album/Playlist)
      else if (_currentIndex + 1 < _queue.length) {
        _currentIndex++;
        nextTrack = _queue[_currentIndex];
      }
      // 3. Autoplay (Use Related Tracks)
      else if (_relatedTracks.isNotEmpty) {
        nextTrack = _relatedTracks.first;
        _queue.add(nextTrack);
        _currentIndex = _queue.length - 1;
      } else {
         _isSkipping = false;
         return;
      }

      _currentTrack = nextTrack;
      _currentLyrics = [];
      _currentLyricIndex = -1;
      notifyListeners();

      await _loadAndPlay(null, nextTrack!);
      _fetchUpNext(nextTrack);

    } catch(e) {
      print("Error in playNext: $e");
    } finally {
      _isSkipping = false;
    }
  }

  Future<void> skipTo(int index) async {
    if (index >= 0 && index < _queue.length) {
      _currentIndex = index;
      final track = _queue[_currentIndex];
      _currentTrack = track;
       _currentLyrics = [];
      _currentLyricIndex = -1;
      notifyListeners();
      await _loadAndPlay(null, track);
    }
  }

  Future<void> _loadAndPlay(BuildContext? context, MusicTrack track) async {
    MusicTrack? finalTrack = track;
    
    if (context != null) {
      final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
      if (downloadProvider.isDownloaded(track.id)) {
        finalTrack = downloadProvider.downloadedTracks.firstWhere((t) => t.id == track.id);
      }
    }

    String? url = _resolvedUrls[finalTrack.id];
    if (url == null) {
      url = await _resolveUrl(finalTrack);
      if (url != null) _resolvedUrls[finalTrack.id] = url;
    }

    if (url != null) {
      print('Playing URL: $url (Downloaded: ${finalTrack.isDownloaded})');
      final artUrl = finalTrack.thumbnails?['large'] ?? finalTrack.albumArtUrl;
      
      final tag = MediaItem(
          id: finalTrack.id,
          album: finalTrack.album,
          title: finalTrack.title,
          artist: finalTrack.artist,
          artUri: artUrl != null ? Uri.parse(artUrl) : null,
      );

      // Add to History (Realtime)
      if (navigatorKey.currentContext != null) {
        Provider.of<MusicProvider>(navigatorKey.currentContext!, listen: false).addToHistory(finalTrack);
      }

      if (finalTrack.isDownloaded) {
        final file = File(url);
        if (await file.exists()) {
          print('Playing local file: $url');
          try {
             final source = AudioSource.file(url, tag: tag);
             await _player.setAudioSource(source);
             _player.play();
             await _forcePlayLoop(); // Force play for local file
             return; 
          } catch (e) {
             print('Error playing local file: $e. Falling back to stream.');
          }
        } else {
             print('Local file missing at: $url. Falling back to stream.');
        }
        
        final streamUrl = await _performUrlResolution(finalTrack); 
        if (streamUrl != null) {
           print('Fallback Stream URL: $streamUrl');
           final source = AudioSource.uri(Uri.parse(streamUrl), tag: tag);
           await _player.setAudioSource(source);
           _player.play();
        }
      } else {
          try {
            final source = AudioSource.uri(Uri.parse(url), tag: tag);
            await _player.setAudioSource(source);
            _player.play();
          } catch (e) {
            print('Error setting stream source: $e. Retrying with fresh URL...');
            // Invalidate cache and retry
            _resolvedUrls.remove(finalTrack.id);
            final newUrl = await _resolveUrl(finalTrack);
            if (newUrl != null) {
               _resolvedUrls[finalTrack.id] = newUrl;
               try {
                 print('Retrying with new URL: $newUrl');
                 final newSource = AudioSource.uri(Uri.parse(newUrl), tag: tag);
                 await _player.setAudioSource(newSource);
                 _player.play();
               } catch (retryError) {
                 print('Retry failed: $retryError');
               }
            }
          }
      }
      
      await _forcePlayLoop(); // Force play for stream
    } else {
      print('Failed to resolve URL for track: ${finalTrack.title}');
    }
  }
  
  Future<void> _forcePlayLoop() async {
      for (int i = 0; i < 5; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (!_player.playing) {
          print('State is paused. Forcing play... (Check ${i + 1}/5)');
          _player.play();
        }
      }
  }

  void skipToNext() => _playNext(force: true);

  void skipToPrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
      final prevTrack = _queue[_currentIndex];
      _currentTrack = prevTrack;
      _currentLyrics = [];
      _currentLyricIndex = -1;
      notifyListeners();
      _loadAndPlay(null, prevTrack);
    }
  }

  void togglePlay() {
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void _updateLyricIndex(Duration position) {
  if (_currentLyrics.isEmpty) return;
  
  // Optimization: Don't search if we are still on the current line or next line
  // (Most common case during playback)
  if (_currentLyricIndex >= 0 && _currentLyricIndex < _currentLyrics.length) {
    final current = _currentLyrics[_currentLyricIndex];
    final next = (_currentLyricIndex + 1 < _currentLyrics.length) ? _currentLyrics[_currentLyricIndex + 1] : null;
    
    if (position >= current.startTime && (next == null || position < next.startTime)) {
      return; // Still on same line
    }
  }

  int index = -1;
  // Use binary search for better performance on long lyrics
  int low = 0;
  int high = _currentLyrics.length - 1;
  while (low <= high) {
    int mid = (low + high) ~/ 2;
    if (position >= _currentLyrics[mid].startTime) {
      index = mid;
      low = mid + 1;
    } else {
      high = mid - 1;
    }
  }
  
  if (index != _currentLyricIndex) {
    _currentLyricIndex = index;
    notifyListeners();
  }
}

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
