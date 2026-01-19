import 'package:isar/isar.dart';
import '../models/music_track.dart';

part 'downloaded_track.g.dart';

@collection
class DownloadedTrack {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String trackId;
  
  late String title;
  late String artist;
  late String album;
  String? albumArtUrl;
  String? duration;
  late String source;
  late String localPath;

  DownloadedTrack();

  factory DownloadedTrack.fromMusicTrack(MusicTrack track, String localPath) {
    return DownloadedTrack()
      ..trackId = track.id
      ..title = track.title
      ..artist = track.artist
      ..album = track.album
      ..albumArtUrl = track.albumArtUrl
      ..duration = track.duration
      ..source = track.source.toString()
      ..localPath = localPath;
  }

  MusicTrack toMusicTrack() {
    return MusicTrack(
      id: trackId,
      title: title,
      artist: artist,
      album: album,
      albumArtUrl: albumArtUrl,
      duration: duration,
      source: source == 'MusicSource.youtube' ? MusicSource.youtube : MusicSource.saavn,
      isDownloaded: true,
      localPath: localPath,
    );
  }
}
