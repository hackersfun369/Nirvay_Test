import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../models/music_track.dart';
import '../models/local_playlist.dart';
import 'database_service.dart';

class PlaylistProvider with ChangeNotifier {
  List<LocalPlaylist> _playlists = [];
  List<LocalPlaylist> get playlists => _playlists;

  Future<void> loadPlaylists() async {
    _playlists = await DatabaseService.isar.localPlaylists.where().findAll();
    notifyListeners();
  }

  Future<void> createPlaylist(String name, {String? description, MusicTrack? initialTrack}) async {
    final playlist = LocalPlaylist()
      ..name = name
      ..description = description;

    if (initialTrack != null) {
      playlist.trackJsonList.add(jsonEncode(initialTrack.toJson()));
    }

    await DatabaseService.isar.writeTxn(() async {
      await DatabaseService.isar.localPlaylists.put(playlist);
    });
    await loadPlaylists();
  }

  Future<void> addToPlaylist(LocalPlaylist playlist, MusicTrack track) async {
    try {
      final trackJson = jsonEncode(track.toJson());
      // Check if track already exists (by ID parsing to be safe, or direct string match)
      final exists = playlist.trackJsonList.any((json) => json.contains('"id":"${track.id}"'));
      
      if (!exists) {
        // Create a new list to ensure Isar detects the change (and handles potential unmodifiable lists)
        playlist.trackJsonList = List<String>.from(playlist.trackJsonList)..add(trackJson);
        
        await DatabaseService.isar.writeTxn(() async {
          await DatabaseService.isar.localPlaylists.put(playlist);
        });
        print('Added track ${track.title} to playlist ${playlist.name}. New count: ${playlist.trackJsonList.length}');
        await loadPlaylists();
      } else {
        print('Track already exists in playlist');
      }
    } catch (e) {
      print('Error adding to playlist: $e');
      rethrow;
    }
  }

  Future<void> removeFromPlaylist(LocalPlaylist playlist, String trackId) async {
    final newList = List<String>.from(playlist.trackJsonList);
    newList.removeWhere((json) {
      final track = MusicTrack.fromJson(jsonDecode(json));
      return track.id == trackId;
    });
    playlist.trackJsonList = newList;
    
    await DatabaseService.isar.writeTxn(() async {
      await DatabaseService.isar.localPlaylists.put(playlist);
    });
    await loadPlaylists();
  }

  Future<void> deletePlaylist(int id) async {
    await DatabaseService.isar.writeTxn(() async {
      await DatabaseService.isar.localPlaylists.delete(id);
    });
    await loadPlaylists();
  }

  List<MusicTrack> getPlaylistTracks(LocalPlaylist playlist) {
    return playlist.trackJsonList.map((json) => MusicTrack.fromJson(jsonDecode(json))).toList();
  }
}
