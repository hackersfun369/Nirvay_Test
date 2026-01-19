import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/downloaded_track.dart';
import '../models/local_playlist.dart';
import '../models/search_history.dart';

import '../models/watch_history.dart';
import '../models/liked_song.dart';
import '../models/saved_item.dart';

class DatabaseService {
  static late Isar isar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    if (Isar.instanceNames.isEmpty) {
      isar = await Isar.open(
        [
          DownloadedTrackSchema, 
          LocalPlaylistSchema, 
          SearchHistorySchema,
          WatchHistorySchema,
          LikedSongSchema,
          SavedItemSchema,
        ],
        directory: dir.path,
      );
    } else {
      isar = Isar.getInstance()!;
    }
  }
}
