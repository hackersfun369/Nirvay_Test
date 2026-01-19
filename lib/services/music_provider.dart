import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/music_track.dart';
import '../models/search_history.dart';
import 'package:isar/isar.dart';
import '../services/youtube_service.dart';
import '../services/saavn_service.dart';
import '../models/watch_history.dart';
import 'database_service.dart';
import '../services/database_service.dart';
import 'package:isar/isar.dart';

class MusicProvider with ChangeNotifier {
  final YouTubeService _youtubeService = YouTubeService();
  final JioSaavnService _saavnService = JioSaavnService();

  List<MusicTrack> _songs = [];
  List<MusicTrack> _albums = [];
  List<MusicTrack> _artists = [];
  List<MusicTrack> _playlists = [];
  List<MusicTrack> _trendingTracks = [];
  List<MusicTrack> _quickPicks = [];
  List<MusicTrack> _recentlyPlayed = [];
  List<MusicTrack> _relatedAlbums = [];
  List<MusicTrack> _relatedArtists = [];
  List<MusicTrack> _charts = [];
  List<MusicTrack> _newReleases = [];
  List<SearchHistory> _searchHistory = [];
  List<String> _suggestions = [];
  bool _isLoading = false;
  String? _activeSearchQuery; 
  String? _activeSuggestionQuery;
  MusicSource _currentSource = MusicSource.youtube;

  List<MusicTrack> get songs => _songs;
  List<MusicTrack> get albums => _albums;
  List<MusicTrack> get artists => _artists;
  List<MusicTrack> get playlists => _playlists;
  List<MusicTrack> get tracks => _songs; // Alias for compatibility
  List<MusicTrack> get trendingTracks => _trendingTracks;
  List<MusicTrack> get quickPicks => _quickPicks;
  List<MusicTrack> get recentlyPlayed => _recentlyPlayed;
  List<MusicTrack> get relatedAlbums => _relatedAlbums;
  List<MusicTrack> get relatedArtists => _relatedArtists;
  List<MusicTrack> get charts => _charts;
  List<MusicTrack> get newReleases => _newReleases;
  bool get isLoading => _isLoading;
  MusicSource get currentSource => _currentSource;
  List<SearchHistory> get searchHistory => _searchHistory;
  List<String> get suggestions => _suggestions;
  
  void setSource(MusicSource source) {
    if (_currentSource == source) return;
    _currentSource = source;
    _songs = [];
    _albums = [];
    _artists = [];
    _playlists = [];
    notifyListeners();
  }

  Future<void> fetchHomeContent() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch Recently Played from DB
      final history = await DatabaseService.isar.watchHistorys.where().sortByTimestampDesc().limit(20).findAll();
      _recentlyPlayed = history.take(10).map((h) => MusicTrack(
        id: h.trackId,
        title: h.title,
        artist: h.artist,
        album: 'Unknown Album',
        albumArtUrl: h.albumArtUrl ?? '',
        source: h.source == 'MusicSource.youtube' ? MusicSource.youtube : MusicSource.saavn,
      )).toList();

      // 2, 3, 4. Generate Personalized Content in parallel
      List<String> uniqueArtists = [];
      if (history.isNotEmpty) {
        uniqueArtists = history
            .where((h) => h.artist.isNotEmpty && h.artist != 'Unknown')
            .map((h) => h.artist)
            .toSet()
            .take(5)
            .toList();

        await Future.wait([
          _generateQuickPicks(uniqueArtists),
          _generateRelatedAlbums(uniqueArtists),
          _generateRelatedArtists(history.take(3).map((h) => h.artist).toList()),
        ]);
      } else {
        _quickPicks = [];
        // Fallback for new users: Show generic popular albums
        await _generateRelatedAlbums(['Taylor Swift', 'The Weeknd', 'Arijit Singh', 'BTS']); 
        _relatedArtists = [];
      }
      
      // 5. Fetch Global Content (Trending, Charts, New Releases)
      await Future.wait([
        fetchTrending(),
        fetchExploreData(seedArtists: uniqueArtists),
      ]);

      // 6. Global Deduplication
      _deduplicateHomeSections();

    } catch (e) {
      print('Error fetching home content: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void _deduplicateHomeSections() {
    final seenIds = <String>{};

    // 1. Recently Played (Priority 1)
    _recentlyPlayed = _uniqueList(_recentlyPlayed, seenIds);

    // 2. Quick Picks (Priority 2)
    _quickPicks = _uniqueList(_quickPicks, seenIds);

    // 3. Trending (Priority 3)
    _trendingTracks = _uniqueList(_trendingTracks, seenIds);
    
    // Note: Albums and Charts are distinct types, so we just internal-dedup them
    _newReleases = _uniqueList(_newReleases, <String>{}); // Local dedup only
    _relatedAlbums = _uniqueList(_relatedAlbums, <String>{});
    _charts = _uniqueList(_charts, <String>{});
  }

  List<MusicTrack> _uniqueList(List<MusicTrack> list, Set<String> seenIds) {
    final unique = <MusicTrack>[];
    for (var item in list) {
      if (item.id.isNotEmpty && !seenIds.contains(item.id)) {
        seenIds.add(item.id);
        unique.add(item);
      }
    }
    return unique;
  }

  Future<void> _generateQuickPicks(List<String> artists) async {
    final quickPicksList = <MusicTrack>[];
    await Future.wait(artists.map((artist) async {
      try {
        final artistTracks = await _youtubeService.search('$artist top songs');
        quickPicksList.addAll(artistTracks.take(3));
      } catch (e) {}
    }));
    // Interleave results to keep variety but prioritize top artists
    // (Instead of valid shuffle which is random)
    _quickPicks = quickPicksList.take(20).toList();
    _quickPicks.shuffle(); // Shuffle ensuring top 20 are mixed
  }

  Future<void> _generateRelatedAlbums(List<String> artists) async {
    final albumsList = <MusicTrack>[];
    await Future.wait(artists.map((artist) async {
      try {
        final albums = await _youtubeService.searchAlbums('$artist albums');
        albumsList.addAll(albums.take(2));
      } catch (e) {}
    }));
    _relatedAlbums = albumsList.take(10).toList();
  }

  Future<void> _generateRelatedArtists(List<String> artists) async {
    final relatedArtistsList = <MusicTrack>[];
    await Future.wait(artists.map((artist) async {
      try {
        final similarArtists = await _youtubeService.searchArtists('$artist similar artists');
        relatedArtistsList.addAll(similarArtists.take(3));
      } catch (e) {}
    }));
    _relatedArtists = relatedArtistsList.take(10).toList();
  }


  Future<void> fetchTrending() async {
    _isLoading = true;
    notifyListeners();
    try {
      if (_currentSource == MusicSource.youtube) {
        _trendingTracks = await _youtubeService.search('Trending Music');
      } else {
        _trendingTracks = await _saavnService.search('Trending');
      }
    } catch (e) {
      print('Trending Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchExploreData({List<String>? seedArtists}) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (_currentSource == MusicSource.youtube) {
        _charts = await _youtubeService.getCharts();
        
        // Personalize New Releases if seeds are available
        if (seedArtists != null && seedArtists.isNotEmpty) {
           final seed = seedArtists.first; // Use the most relevant artist
           _newReleases = await _youtubeService.searchAlbums('New albums similar to $seed');
        } else {
           _newReleases = await _youtubeService.getNewReleases();
        }

      } else {
        _charts = await _saavnService.getCharts();
        // Saavn personalization (basic fallback for now, as SaavnService.getNewReleases is rigid)
         if (seedArtists != null && seedArtists.isNotEmpty) {
           final seed = seedArtists.first;
           _newReleases = await _saavnService.searchAlbums('New albums $seed');
         } else {
           _newReleases = await _saavnService.getNewReleases();
         }
      }
    } catch (e) {
      print('Explore Data Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSearchHistory() async {
    _searchHistory = await DatabaseService.isar.searchHistorys.where().sortByTimestampDesc().findAll();
    notifyListeners();
  }

  Future<void> _addToSearchHistory(String query) async {
    if (query.trim().isEmpty) return;
    final history = SearchHistory()
      ..query = query.trim()
      ..timestamp = DateTime.now();
    await DatabaseService.isar.writeTxn(() async {
      await DatabaseService.isar.searchHistorys.put(history);
    });
    await loadSearchHistory();
  }

  Future<void> clearSearchHistory() async {
    await DatabaseService.isar.writeTxn(() async {
      await DatabaseService.isar.searchHistorys.clear();
    });
    await loadSearchHistory();
  }

  Future<void> addToHistory(MusicTrack track) async {
    if (track.id.isEmpty) return;

    // 1. Update In-Memory List Immediately (Realtime UI)
    _recentlyPlayed.removeWhere((t) => t.id == track.id);
    _recentlyPlayed.insert(0, track);
    if (_recentlyPlayed.length > 20) {
      _recentlyPlayed = _recentlyPlayed.take(20).toList();
    }
    notifyListeners();

    // 2. Persist to DB
    try {
      final history = WatchHistory(
        trackId: track.id,
        title: track.title,
        artist: track.artist,
        albumArtUrl: track.albumArtUrl,
        timestamp: DateTime.now(),
        source: track.source.toString(),
      );

      await DatabaseService.isar.writeTxn(() async {
        await DatabaseService.isar.watchHistorys.put(history);
      });
    } catch (e) {
      print('Error saving history: $e');
    }
  }

  Future<void> fetchSuggestions(String query) async {
    _activeSuggestionQuery = query;
    if (query.isEmpty) {
      _suggestions = [];
      if (_activeSuggestionQuery == query) notifyListeners();
      return;
    }
    
    try {
      if (_currentSource == MusicSource.youtube) {
        final url = Uri.parse('https://suggestqueries.google.com/complete/search?client=youtube&ds=yt&q=${Uri.encodeComponent(query)}');
        final response = await http.get(url);
        if (_activeSuggestionQuery != query) return;
        
        final body = response.body;
        final start = body.indexOf('[');
        final end = body.lastIndexOf(']');
        if (start != -1 && end != -1) {
          final json = jsonDecode(body.substring(start, end + 1));
          _suggestions = (json[1] as List).map((e) => e[0].toString()).toList();
        }
      } else {
        final results = await _saavnService.search(query);
        if (_activeSuggestionQuery != query) return;
        _suggestions = results.map((e) => e.title).take(5).toList();
      }
      if (_activeSuggestionQuery == query) notifyListeners();
    } catch (e) {
      print('Suggestion Error: $e');
    }
  }

  Future<List<MusicTrack>> getArtistTracks(String id, String name, {MusicSource? source}) async {
    final targetSource = source ?? _currentSource;
    if (targetSource == MusicSource.youtube) {
      return _youtubeService.getArtistTracks(name);
    } else {
      return _saavnService.getArtistTracks(id);
    }
  }

  Future<List<MusicTrack>> getAlbumTracks(String id, String name, String artist, {MusicSource? source}) async {
    final targetSource = source ?? _currentSource;
    if (targetSource == MusicSource.youtube) {
      return _youtubeService.getAlbumTracks(name, artist, albumId: id);
    } else {
      return _saavnService.getAlbumTracksById(id);
    }
  }

  Future<List<MusicTrack>> getPlaylistTracks(String id, {MusicSource? source}) async {
    final targetSource = source ?? _currentSource;
    if (targetSource == MusicSource.youtube) {
      return _youtubeService.getPlaylistTracks(id);
    } else {
      return _saavnService.getPlaylistTracks(id);
    }
  }

  Future<void> search(String query, {bool bothSources = false, bool saveToHistory = true}) async {
    _activeSearchQuery = query;
    if (query.isEmpty) {
      _songs = [];
      _albums = [];
      _artists = [];
      _playlists = [];
      await fetchTrending();
      if (_activeSearchQuery == query) notifyListeners();
      return;
    }
    
    if (saveToHistory) {
      await _addToSearchHistory(query);
    }

    _isLoading = true;
    notifyListeners();

    try {
      if (bothSources) {
        final results = await Future.wait([
          _youtubeService.search(query),
          _youtubeService.searchAlbums(query),
          _youtubeService.searchArtists(query),
          _youtubeService.searchPlaylists(query),
          _saavnService.search(query),
          _saavnService.searchAlbums(query),
          _saavnService.searchArtists(query),
        ]);
        if (_activeSearchQuery != query) return;
        _songs = [...results[0], ...results[4]];
        _albums = [...results[1], ...results[5]];
        _artists = [...results[2], ...results[6]];
        _playlists = results[3];
      } else if (_currentSource == MusicSource.youtube) {
        final results = await Future.wait([
          _youtubeService.search(query),
          _youtubeService.searchAlbums(query),
          _youtubeService.searchArtists(query),
          _youtubeService.searchPlaylists(query),
        ]);
        if (_activeSearchQuery != query) return;
        _songs = results[0];
        _albums = results[1];
        _artists = results[2];
        _playlists = results[3];
      } else {
        final results = await Future.wait([
          _saavnService.search(query),
          _saavnService.searchArtists(query),
          _saavnService.searchAlbums(query),
        ]);
        if (_activeSearchQuery != query) return;
        _songs = results[0];
        _artists = results[1];
        _albums = results[2];
        _playlists = [];
      }
    } catch (e) {
      print('Error during search: $e');
      if (_activeSearchQuery == query) _songs = [];
    } finally {
      if (_activeSearchQuery == query) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _youtubeService.dispose();
    super.dispose();
  }
}
