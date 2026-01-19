import 'package:isar/isar.dart';

part 'search_history.g.dart';

@collection
class SearchHistory {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String query;

  late DateTime timestamp;
}
