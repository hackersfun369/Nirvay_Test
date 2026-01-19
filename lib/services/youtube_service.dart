import 'ytm_client.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/music_track.dart';

class YouTubeService {
  static final YouTubeService _instance = YouTubeService._internal();
  factory YouTubeService() => _instance;
  YouTubeService._internal();

  final _yt = YoutubeExplode();
  final _ytm = YtmClient();

  Future<List<MusicTrack>> search(String query) async {
    return _ytm.searchSongs(query);
  }

  Future<List<MusicTrack>> searchAlbums(String query) async {
    return _ytm.searchAlbums(query);
  }

  Future<List<MusicTrack>> searchArtists(String query) async {
    return _ytm.searchArtists(query);
  }

  Future<List<MusicTrack>> searchPlaylists(String query) async {
    return _ytm.searchPlaylists(query);
  }

  Future<List<MusicTrack>> getCharts() async {
    return search('Top 100 Music');
  }

  Future<List<MusicTrack>> getNewReleases() async {
    return search('New Music Releases');
  }

  Future<List<MusicTrack>> getArtistTracks(String artistName) async {
    // Use a more specific query to get actual songs by the artist
    // instead of generic search results that may include albums, playlists, etc.
    return search('$artistName songs');
  }

  Future<List<MusicTrack>> getAlbumTracks(String albumName, String artistName, {String? albumId}) async {
    // If we have an albumId (browse ID), use it to get exact album details
    if (albumId != null && albumId.isNotEmpty) {
      return _ytm.getAlbumDetails(albumId);
    }
    // Fallback: Use a more specific search query to find album tracks
    return search('$albumName $artistName album');
  }

  Future<List<MusicTrack>> getRelatedTracks(String videoId) async {
    return _ytm.getRelatedTracks(videoId);
  }

  Future<List<MusicTrack>> getPlaylistTracks(String playlistId) async {
    return _ytm.getPlaylistTracks(playlistId);
  }

  Future<String> getAudioStreamUrl(String videoId) async {
    final manifest = await _yt.videos.streamsClient.getManifest(videoId, ytClients: [YoutubeApiClient.androidVr]);
    final audioStream = manifest.audioOnly.withHighestBitrate();
    return audioStream.url.toString();
  }

  void dispose() {
    _yt.close();
  }
}
