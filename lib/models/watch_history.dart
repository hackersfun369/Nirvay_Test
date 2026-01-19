import 'package:isar/isar.dart';

part 'watch_history.g.dart';

@collection
class WatchHistory {
  Id id = Isar.autoIncrement;

  @Index()
  late String trackId;

  late String title;
  late String artist;
  late String? albumArtUrl;
  late DateTime timestamp;
  late String source; // 'youtube' or 'saavn'

  // Helper constructor
  WatchHistory({
    required this.trackId,
    required this.title,
    required this.artist,
    this.albumArtUrl,
    required this.timestamp,
    required this.source,
  });
}
