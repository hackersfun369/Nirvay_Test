import 'package:isar/isar.dart';

part 'saved_item.g.dart';

@collection
class SavedItem {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String itemId;

  late String name;
  String? artistName;
  String? imageUrl;
  late String type; // 'album' or 'artist'
  late String source;
  late DateTime addedAt;
}
