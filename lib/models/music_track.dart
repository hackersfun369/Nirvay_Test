enum MusicSource { youtube, saavn }

class MusicTrack {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String? albumArtUrl;
  final Map<String, String>? thumbnails; // Store multiple sizes: 'small', 'medium', 'large'
  final String? duration;
  final MusicSource source;
  final String? encryptedMediaUrl;
  final bool isDownloaded;
  final String? localPath;

  MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.albumArtUrl,
    this.thumbnails,
    this.duration,
    required this.source,
    this.isDownloaded = false,
    this.localPath,
    this.encryptedMediaUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'albumArtUrl': albumArtUrl,
      'thumbnails': thumbnails,
      'duration': duration,
      'source': source.toString(),
      'isDownloaded': isDownloaded,
      'localPath': localPath,
      'encryptedMediaUrl': encryptedMediaUrl,
    };
  }

  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    return MusicTrack(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      album: json['album'],
      albumArtUrl: json['albumArtUrl'],
      thumbnails: json['thumbnails'] != null ? Map<String, String>.from(json['thumbnails']) : null,
      duration: json['duration'],
      source: json['source'] == 'MusicSource.youtube' ? MusicSource.youtube : MusicSource.saavn,
      isDownloaded: json['isDownloaded'] ?? false,
      localPath: json['localPath'],
      encryptedMediaUrl: json['encryptedMediaUrl'],
    );
  }

  MusicTrack copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? albumArtUrl,
    Map<String, String>? thumbnails,
    String? duration,
    MusicSource? source,
    bool? isDownloaded,
    String? localPath,
    String? encryptedMediaUrl,
  }) {
    return MusicTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumArtUrl: albumArtUrl ?? this.albumArtUrl,
      thumbnails: thumbnails ?? this.thumbnails,
      duration: duration ?? this.duration,
      source: source ?? this.source,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      localPath: localPath ?? this.localPath,
      encryptedMediaUrl: encryptedMediaUrl ?? this.encryptedMediaUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MusicTrack && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
