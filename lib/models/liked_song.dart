import 'package:isar/isar.dart';

part 'liked_song.g.dart';

@collection
class LikedSong {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String trackId;

  late String title;
  late String artist;
  late String? albumArtUrl;
  late DateTime addedAt;
  late String source;

  LikedSong({
    required this.trackId,
    required this.title,
    required this.artist,
    this.albumArtUrl,
    required this.addedAt,
    required this.source,
  });
}
