import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../models/music_track.dart';
import '../models/liked_song.dart';
import '../models/saved_item.dart';
import 'database_service.dart';

class FavoritesProvider with ChangeNotifier {
  List<LikedSong> _likedSongs = [];
  List<SavedItem> _savedItems = [];

  List<LikedSong> get likedSongs => _likedSongs;
  List<SavedItem> get savedItems => _savedItems;

  Future<void> loadFavorites() async {
    _likedSongs = await DatabaseService.isar.likedSongs.where().sortByAddedAtDesc().findAll();
    _savedItems = await DatabaseService.isar.savedItems.where().sortByAddedAtDesc().findAll();
    notifyListeners();
  }

  bool isLiked(String trackId) {
    return _likedSongs.any((s) => s.trackId == trackId);
  }

  bool isSaved(String itemId) {
    return _savedItems.any((item) => item.itemId == itemId);
  }

  Future<void> toggleLike(MusicTrack track) async {
    if (isLiked(track.id)) {
      await _remove(track.id);
    } else {
      await _add(track);
    }
  }

  Future<void> toggleSave(dynamic item, String type) async {
    final String id = item is MusicTrack ? item.id : (item as dynamic).id;
    print('toggleSave called for id: $id, type: $type, currently saved: ${isSaved(id)}');
    if (isSaved(id)) {
       await _removeSaved(id);
       print('Removed item $id from saved items');
    } else {
       await _addSaved(item, type);
       print('Added item $id to saved items');
    }
  }

  Future<void> _add(MusicTrack track) async {
    final song = LikedSong(
      trackId: track.id,
      title: track.title,
      artist: track.artist,
      albumArtUrl: track.albumArtUrl,
      source: track.source.toString(),
      addedAt: DateTime.now(),
    );

    await DatabaseService.isar.writeTxn(() async {
      await DatabaseService.isar.likedSongs.put(song);
    });
    
    await loadFavorites();
  }

  Future<void> _remove(String trackId) async {
    await DatabaseService.isar.writeTxn(() async {
      await DatabaseService.isar.likedSongs.filter().trackIdEqualTo(trackId).deleteAll();
    });
    
    await loadFavorites();
  }

  Future<void> _addSaved(dynamic item, String type) async {
    try {
      // Extract values with proper null handling
      final String itemId = (item is MusicTrack) ? item.id : (item as dynamic).id;
      final String name = (item is MusicTrack) ? item.title : (item as dynamic).title ?? 'Unknown';
      final String? artistName = (item is MusicTrack) ? item.artist : null;
      final String? imageUrl = (item is MusicTrack) ? item.albumArtUrl : (item as dynamic).albumArtUrl;
      final String source = (item is MusicTrack) ? item.source.toString() : 'MusicSource.youtube';
      
      final savedItem = SavedItem()
        ..itemId = itemId
        ..name = name
        ..artistName = artistName
        ..imageUrl = imageUrl
        ..type = type
        ..source = source
        ..addedAt = DateTime.now();

      print('Adding saved item: ${savedItem.itemId}, name: ${savedItem.name}, type: ${savedItem.type}');
      
      await DatabaseService.isar.writeTxn(() async {
        await DatabaseService.isar.savedItems.put(savedItem);
      });
      
      await loadFavorites();
      print('Saved items count after add: ${_savedItems.length}');
    } catch (e, stackTrace) {
      print('Error in _addSaved: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _removeSaved(String itemId) async {
    await DatabaseService.isar.writeTxn(() async {
      await DatabaseService.isar.savedItems.filter().itemIdEqualTo(itemId).deleteAll();
    });
    await loadFavorites();
  }
}
