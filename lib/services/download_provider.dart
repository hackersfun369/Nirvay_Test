import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../models/music_track.dart';
import '../models/downloaded_track.dart';
import '../models/local_playlist.dart';
import 'download_service.dart';
import 'database_service.dart';

class DownloadProvider with ChangeNotifier {
  final DownloadService _downloadService = DownloadService();
  late Isar _isar;
  List<MusicTrack> _downloadedTracks = [];
  Map<String, double> _downloadProgress = {};

  List<MusicTrack> get downloadedTracks => _downloadedTracks;
  Map<String, double> get downloadProgress => _downloadProgress;

  Future<void> init() async {
    await _loadDownloadedTracks();
  }

  Future<void> _loadDownloadedTracks() async {
    final tracks = await DatabaseService.isar.downloadedTracks.where().findAll();
    _downloadedTracks = tracks.map((t) => t.toMusicTrack()).toList();
    notifyListeners();
  }

  Future<bool> download(MusicTrack track) async {
    if (_downloadProgress.containsKey(track.id)) return false;

    _downloadProgress[track.id] = 0.0;
    notifyListeners();

    final filePath = await _downloadService.downloadTrack(track, (progress) {
      _downloadProgress[track.id] = progress;
      notifyListeners();
    });

    if (filePath != null) {
      final downloadedTrack = DownloadedTrack.fromMusicTrack(track, filePath);
      await DatabaseService.isar.writeTxn(() async {
        await DatabaseService.isar.downloadedTracks.put(downloadedTrack);
      });
      await _loadDownloadedTracks();
      
      _downloadProgress.remove(track.id);
      notifyListeners();
      return true;
    }

    _downloadProgress.remove(track.id);
    notifyListeners();
    return false;
  }

  bool isDownloaded(String trackId) {
    return _downloadedTracks.any((t) => t.id == trackId);
  }

  Future<void> delete(String trackId) async {
    final track = await DatabaseService.isar.downloadedTracks.filter().trackIdEqualTo(trackId).findFirst();
    if (track != null) {
      await _downloadService.deleteDownloadedTrack(track.localPath);
      await DatabaseService.isar.writeTxn(() async {
        await DatabaseService.isar.downloadedTracks.delete(track.id);
      });
      await _loadDownloadedTracks();
    }
  }
}
