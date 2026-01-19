import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/music_track.dart';
import 'youtube_service.dart';
import 'saavn_service.dart';

class DownloadService {
  final Dio _dio = Dio();
  final YouTubeService _youtubeService = YouTubeService();
  final JioSaavnService _saavnService = JioSaavnService();

  Future<String?> downloadTrack(MusicTrack track, Function(double) onProgress) async {
    try {
      final directory = await getApplicationDocumentsDirection();
      final downloadsDir = Directory('${directory.path}/downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final filePath = '${downloadsDir.path}/${track.id}.mp3';
      
      String? url;
      if (track.source == MusicSource.youtube) {
        url = await _youtubeService.getAudioStreamUrl(track.id);
      } else {
        url = await _saavnService.getAudioStreamUrl(track.id, highQuality: false);
      }

      if (url == null) return null;

      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );

      return filePath;
    } catch (e) {
      print('Download Error: $e');
      return null;
    }
  }

  Future<void> deleteDownloadedTrack(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

// Fixed typo in getApplicationDocumentsDirectory
Future<Directory> getApplicationDocumentsDirection() async {
  return await getApplicationDocumentsDirectory();
}
