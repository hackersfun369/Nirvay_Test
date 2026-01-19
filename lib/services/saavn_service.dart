import 'dart:convert';
import 'package:dart_des/dart_des.dart';
import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart' as enc;
import 'package:html_unescape/html_unescape.dart';
import '../models/music_track.dart';

class JioSaavnService {
  static final JioSaavnService _instance = JioSaavnService._internal();
  factory JioSaavnService() => _instance;
  JioSaavnService._internal();

  final String baseUrl = 'https://www.jiosaavn.com/api.php';

  Future<List<MusicTrack>> search(String query) async {
    try {
      final url = Uri.parse('$baseUrl?__call=search.getResults&_format=json&_marker=0&cc=in&includeMetaTags=1&q=${Uri.encodeComponent(query)}&n=20');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        final List? songs = (data is Map && data['results'] is List) ? (data['results'] as List) : null;
        if (songs == null) return [];
        
        return songs.map((song) => MusicTrack(
          id: song['id']?.toString() ?? '',
          title: _decodeHtml(song['song'] ?? song['title'] ?? 'Unknown'),
          artist: _decodeHtml(song['more_info']?['primary_artists'] ?? song['primary_artists'] ?? song['singers'] ?? 'Unknown'),
          album: _decodeHtml(song['album'] ?? 'Unknown'),
          albumArtUrl: _formatImage(song['image'], '500x500'),
          thumbnails: {
            'small': _formatImage(song['image'], '50x50'),
            'medium': _formatImage(song['image'], '150x150'),
            'large': _formatImage(song['image'], '500x500'),
          },
          duration: song['duration']?.toString(),
          source: MusicSource.saavn,
          encryptedMediaUrl: song['more_info']?['encrypted_media_url'] ?? song['encrypted_media_url'],
        )).toList();
      }
    } catch (e) {
      print('Saavn Search Error: $e');
    }
    return [];
  }

  Future<List<MusicTrack>> searchAlbums(String query) async {
    try {
      final url = Uri.parse('$baseUrl?__call=search.getAlbumResults&_format=json&_marker=0&cc=in&includeMetaTags=1&q=${Uri.encodeComponent(query)}&n=20');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        final List? results = (data is Map && data['results'] is List) ? (data['results'] as List) : null;
        if (results == null) return [];
        return results.map((item) => MusicTrack(
          id: item['id']?.toString() ?? '',
          title: _decodeHtml(item['name'] ?? item['title'] ?? 'Unknown'),
          artist: _decodeHtml(item['music'] ?? item['artist'] ?? 'Unknown'),
          album: _decodeHtml(item['name'] ?? 'Unknown'),
          albumArtUrl: _formatImage(item['image'], '500x500'),
          thumbnails: {
            'small': _formatImage(item['image'], '50x50'),
            'medium': _formatImage(item['image'], '150x150'),
            'large': _formatImage(item['image'], '500x500'),
          },
          duration: null,
          source: MusicSource.saavn,
        )).toList();
      }
    } catch (e) {
      print('Saavn Album Search Error: $e');
    }
    return [];
  }

  Future<List<MusicTrack>> searchArtists(String query) async {
    try {
      final url = Uri.parse('$baseUrl?__call=search.getArtistResults&_format=json&_marker=0&cc=in&includeMetaTags=1&q=${Uri.encodeComponent(query)}&n=20');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        final List? results = (data is Map && data['results'] is List) ? (data['results'] as List) : null;
        if (results == null) return [];
        return results.map((item) => MusicTrack(
          id: item['id']?.toString() ?? '',
          title: _decodeHtml(item['name'] ?? 'Unknown Artist'),
          artist: 'Artist',
          album: 'JioSaavn',
          albumArtUrl: _formatImage(item['image'], '500x500'),
          thumbnails: {
            'small': _formatImage(item['image'], '50x50'),
            'medium': _formatImage(item['image'], '150x150'),
            'large': _formatImage(item['image'], '500x500'),
          },
          duration: null,
          source: MusicSource.saavn,
        )).toList();
      }
    } catch (e) {
      print('Saavn Artist Search Error: $e');
    }
    return [];
  }

  Future<List<MusicTrack>> searchPlaylists(String query) async {
    try {
      final url = Uri.parse('$baseUrl?__call=search.getPlaylistResults&_format=json&_marker=0&cc=in&includeMetaTags=1&q=${Uri.encodeComponent(query)}&n=20');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        final List? results = (data is Map && data['results'] is List) ? (data['results'] as List) : null;
        if (results == null) return [];
        return results.map((item) => MusicTrack(
          id: item['id']?.toString() ?? '',
          title: _decodeHtml(item['name'] ?? 'Unknown Playlist'),
          artist: 'Playlist',
          album: 'JioSaavn',
          albumArtUrl: _formatImage(item['image'], '500x500'),
          thumbnails: {
            'small': _formatImage(item['image'], '50x50'),
            'medium': _formatImage(item['image'], '150x150'),
            'large': _formatImage(item['image'], '500x500'),
          },
          duration: null,
          source: MusicSource.saavn,
        )).toList();
      }
    } catch (e) {
      print('Saavn Playlist Search Error: $e');
    }
    return [];
  }

  Future<List<MusicTrack>> getCharts() async {
    try {
      final url = Uri.parse('$baseUrl?__call=content.getCharts&_format=json&_marker=0&cc=in');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        final List? dataList = (data is List) ? data : null;
        if (dataList != null && dataList.isNotEmpty) {
          return getPlaylistTracks(dataList[0]['listid']?.toString() ?? '');
        }
      }
    } catch (e) {
      print('Saavn Charts Error: $e');
    }
    return [];
  }

  Future<List<MusicTrack>> getNewReleases() async {
    try {
      final url = Uri.parse('$baseUrl?__call=content.getAlbumNewReleases&_format=json&_marker=0&cc=in');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        final List? dataList = (data is List) ? data : null;
        if (dataList == null) return [];
        return dataList.take(10).map((item) => MusicTrack(
          id: item['id']?.toString() ?? '',
          title: _decodeHtml(item['name'] ?? 'New Release'),
          artist: _decodeHtml(item['music'] ?? item['artist'] ?? 'Unknown Artist'),
          album: _decodeHtml(item['name'] ?? 'Unknown Album'),
          albumArtUrl: _formatImage(item['image'], '500x500'),
          thumbnails: {
            'small': _formatImage(item['image'], '50x50'),
            'medium': _formatImage(item['image'], '150x150'),
            'large': _formatImage(item['image'], '500x500'),
          },
          duration: null,
          source: MusicSource.saavn,
        )).toList();
      }
    } catch (e) {
      print('Saavn New Releases Error: $e');
    }
    return [];
  }

  Future<List<MusicTrack>> getPlaylistTracks(String listId) async {
    try {
      final url = Uri.parse('$baseUrl?__call=playlist.getDetails&_format=json&_marker=0&cc=in&listid=$listId');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        final List? songs = (data is Map && data['songs'] is List) ? (data['songs'] as List) : null;
        if (songs == null) return [];
        return songs.map((song) => MusicTrack(
          id: song['id']?.toString() ?? '',
          title: _decodeHtml(song['song'] ?? 'Unknown'),
          artist: _decodeHtml(song['more_info']?['primary_artists'] ?? song['primary_artists'] ?? song['singers'] ?? 'Unknown'),
          album: _decodeHtml(song['album'] ?? 'Unknown'),
          albumArtUrl: _formatImage(song['image'], '500x500'),
          thumbnails: {
            'small': _formatImage(song['image'], '50x50'),
            'medium': _formatImage(song['image'], '150x150'),
            'large': _formatImage(song['image'], '500x500'),
          },
          duration: song['duration']?.toString(),
          source: MusicSource.saavn,
          encryptedMediaUrl: song['more_info']?['encrypted_media_url'] ?? song['encrypted_media_url'],
        )).toList();
      }
    } catch (e) {
      print('Saavn Playlist Tracks Error: $e');
    }
    return [];
  }

  Future<List<MusicTrack>> getArtistTracks(String artistId) async {
    try {
      final url = Uri.parse('$baseUrl?__call=artist.getArtistPageDetails&_format=json&_marker=0&cc=in&artistId=$artistId');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        final List? songs = (data is Map && data['topSongs'] is List) ? (data['topSongs'] as List) : null;
        if (songs == null) return [];
        return songs.map((song) => MusicTrack(
          id: song['id']?.toString() ?? '',
          title: _decodeHtml(song['song'] ?? 'Unknown'),
          artist: _decodeHtml(song['more_info']?['primary_artists'] ?? song['primary_artists'] ?? song['singers'] ?? 'Unknown'),
          album: _decodeHtml(song['album'] ?? 'Unknown'),
          albumArtUrl: _formatImage(song['image'], '500x500'),
          thumbnails: {
            'small': _formatImage(song['image'], '50x50'),
            'medium': _formatImage(song['image'], '150x150'),
            'large': _formatImage(song['image'], '500x500'),
          },
          duration: song['duration']?.toString(),
          source: MusicSource.saavn,
          encryptedMediaUrl: song['more_info']?['encrypted_media_url'] ?? song['encrypted_media_url'],
        )).toList();
      }
    } catch (e) {
      print('Saavn Artist Tracks Error: $e');
    }
    return [];
  }

  Future<List<MusicTrack>> getAlbumTracksById(String albumId) async {
    try {
      final url = Uri.parse('$baseUrl?__call=content.getAlbumDetails&_format=json&_marker=0&cc=in&albumid=$albumId');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        final List? songs = (data is Map && data['songs'] is List) ? (data['songs'] as List) : null;
        if (songs == null) return [];
        return songs.map((song) => MusicTrack(
          id: song['id']?.toString() ?? '',
          title: _decodeHtml(song['song'] ?? 'Unknown'),
          artist: _decodeHtml(song['more_info']?['primary_artists'] ?? song['primary_artists'] ?? song['singers'] ?? 'Unknown'),
          album: _decodeHtml(song['album'] ?? 'Unknown'),
          albumArtUrl: _formatImage(song['image'], '500x500'),
          thumbnails: {
            'small': _formatImage(song['image'], '50x50'),
            'medium': _formatImage(song['image'], '150x150'),
            'large': _formatImage(song['image'], '500x500'),
          },
          duration: song['duration']?.toString(),
          source: MusicSource.saavn,
          encryptedMediaUrl: song['more_info']?['encrypted_media_url'] ?? song['encrypted_media_url'],
        )).toList();
      }
    } catch (e) {
      print('Saavn Album Tracks Error: $e');
    }
    return [];
  }

  Future<MusicTrack?> getSongDetails(String songId) async {
    try {
      final url = Uri.parse('$baseUrl?__call=song.getDetails&_format=json&_marker=0&cc=in&pids=$songId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        final dynamic song = (data is Map) ? data[songId] : null;
        if (song != null) {
          return MusicTrack(
            id: song['id']?.toString() ?? songId,
            title: _decodeHtml(song['song'] ?? song['title'] ?? 'Unknown'),
            artist: _decodeHtml(song['more_info']?['primary_artists'] ?? song['primary_artists'] ?? song['singers'] ?? 'Unknown'),
            album: _decodeHtml(song['album'] ?? 'Unknown'),
            albumArtUrl: _formatImage(song['image'], '500x500'),
            thumbnails: {
              'small': _formatImage(song['image'], '50x50'),
              'medium': _formatImage(song['image'], '150x150'),
              'large': _formatImage(song['image'], '500x500'),
            },
            duration: song['duration']?.toString(),
            source: MusicSource.saavn,
            encryptedMediaUrl: song['more_info']?['encrypted_media_url'] ?? song['encrypted_media_url'],
          );
        }
      }
    } catch (e) {
      print('Saavn Song Details Error: $e');
    }
    return null;
  }

  Future<List<MusicTrack>> getRelatedTracks(String songId) async {
    try {
      final url = Uri.parse('$baseUrl?__call=reco.getreco&_format=json&_marker=0&cc=in&pid=$songId&ctx=web6dot0');
      final response = await http.get(url, headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
      });

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        List? results;
        if (data is List) {
          results = data;
        } else if (data is Map && data['results'] is List) {
          results = data['results'];
        }

        if (results == null || results.isEmpty) return [];
        
        return results
            .where((song) => song['id']?.toString() != songId)
            .map((song) {
               final moreInfo = song['more_info'];
               return MusicTrack(
                id: song['id']?.toString() ?? '',
                title: _decodeHtml(song['title'] ?? song['song'] ?? 'Unknown'),
                artist: _decodeHtml(moreInfo?['primary_artists'] ?? song['primary_artists'] ?? song['singers'] ?? 'Unknown'),
                album: _decodeHtml(moreInfo?['album'] ?? song['album'] ?? 'Unknown'),
                albumArtUrl: _formatImage(song['image'], '500x500'),
                thumbnails: {
                  'small': _formatImage(song['image'], '50x50'),
                  'medium': _formatImage(song['image'], '150x150'),
                  'large': _formatImage(song['image'], '500x500'),
                },
                duration: (song['duration'] ?? moreInfo?['duration'])?.toString(),
                source: MusicSource.saavn,
                encryptedMediaUrl: moreInfo?['encrypted_media_url'] ?? song['encrypted_media_url'],
              );
            }).toList();
      }
    } catch (e) {
      print('Saavn Related Tracks Error: $e');
    }
    return [];
  }

  Future<String?> getAudioStreamUrl(String songId, {bool highQuality = true, String? encryptedUrl}) async {
    try {
      String? encUrl = encryptedUrl;
      
      if (encUrl == null) {
        final detailsUrl = Uri.parse('$baseUrl?__call=song.getDetails&_format=json&_marker=0&cc=in&pids=$songId');
        final detailsResponse = await http.get(detailsUrl, headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
        });

        if (detailsResponse.statusCode == 200) {
          final dynamic data = jsonDecode(detailsResponse.body);
          dynamic song;
          if (data is Map && data.containsKey(songId)) {
            song = data[songId];
          } else if (data is List && data.isNotEmpty) {
            song = data.firstWhere((s) => s['id'] == songId, orElse: () => null);
          } else if (data is Map && data['songs'] is List) {
            song = (data['songs'] as List).firstWhere((s) => s['id'] == songId, orElse: () => null);
          }
          
          if (song != null) {
            encUrl = (song['more_info']?['encrypted_media_url'] ?? song['encrypted_media_url'])?.toString();
          }
        }
      }
      
      if (encUrl != null) {
        return await _getAuthUrl(encUrl, highQuality: highQuality);
      }
    } catch (e) {
      print('Saavn Fetch Audio Error: $e');
    }
    return null;
  }

  Future<String?> _getAuthUrl(String encryptedUrl, {bool highQuality = true}) async {
    try {
      final bitrate = highQuality ? '320' : '160';
      final url = Uri.parse('$baseUrl?__call=song.generateAuthToken&_format=json&_marker=0&cc=in&includeMetaTags=1&url=${Uri.encodeComponent(encryptedUrl)}&bitrate=$bitrate&api_version=4');
      
      final response = await http.get(url, headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
      });
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final authUrl = data['auth_url']?.toString();
        if (authUrl != null) {
          // IMPORTANT: Do NOT replace extensions in signed URLs as it breaks the signature!
          return authUrl;
        }
      }
    } catch (e) {
      print('Saavn Auth Token Error: $e');
    }
    return null;
  }


  Future<String?> getLyrics(String songId) async {
    try {
      final url = Uri.parse('$baseUrl?__call=lyrics.getLyrics&_format=json&_marker=0&cc=in&lyrics_id=$songId');
      final response = await http.get(url, headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['lyrics'] != null) {
          return _decodeHtml(data['lyrics']);
        }
      }
    } catch (e) {
      print('Saavn Lyrics Error: $e');
    }
    return null;
  }

  String _formatImage(dynamic imageUrl, String size) {
    if (imageUrl == null) return '';
    String url = imageUrl.toString();
    if (url.contains('150x150')) {
      return url.replaceAll('150x150', size);
    } else if (url.contains('50x50')) {
      return url.replaceAll('50x50', size);
    } else if (url.contains('500x500')) {
      return url.replaceAll('500x500', size);
    }
    return url;
  }

  String _decodeHtml(String text) {
    return HtmlUnescape().convert(text);
  }
}
