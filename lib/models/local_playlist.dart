import 'package:isar/isar.dart';
import 'music_track.dart';

part 'local_playlist.g.dart';

@collection
class LocalPlaylist {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name;

  String? description;
  
  // Store track IDs or full JSON list. For simplicity and offline support, 
  // we'll store a list of track IDs and fetch them from the DownloadedTrack collection or memory.
  // Actually, to support both online and offline songs in playlists, 
  // we'll store the list of MusicTrack objects as JSON strings.
  List<String> trackJsonList = [];

  LocalPlaylist();

  int get trackCount => trackJsonList.length;

  List<MusicTrack> getTracks() {
    // This requires jsonDecode, so we might move it to a helper or provider
    return []; 
  }
}
