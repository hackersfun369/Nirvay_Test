import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ytm_parser.dart';
import '../models/music_track.dart';

class YtmClient {
  static const String _baseUrl = 'https://music.youtube.com/youtubei/v1';
  static const String _apiKey = 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30';
  
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Origin': 'https://music.youtube.com',
  };

  Map<String, dynamic> _getContext() {
    final date = DateTime.now().toIso8601String().split('T')[0].replaceAll('-', '');
    return {
      'client': {
        'clientName': 'WEB_REMIX',
        'clientVersion': '1.$date.01.00',
        'hl': 'en',
        'gl': 'US',
      }
    };
  }

  Future<http.Response> _rawRequest(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl/$endpoint?key=$_apiKey');
    body['context'] ??= _getContext();

    return await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );
  }

  Future<Map<String, dynamic>> _sendRequest(String endpoint, Map<String, dynamic> body) async {
    final response = await _rawRequest(endpoint, body);
    return jsonDecode(response.body);
  }

  Future<List<MusicTrack>> searchSongs(String query) async {
    return _searchType(query, 'EgWKAQIIAWoKEAkQAxAEEAkQBRgA'); // Songs param
  }

  Future<List<MusicTrack>> searchAlbums(String query) async {
    return _searchType(query, 'EgWKAQIYAWoKEAkQAxAEEAkQBRgA'); // Albums param (approx)
  }

  Future<List<MusicTrack>> searchArtists(String query) async {
    return _searchType(query, 'EgWKAQI4AWoKEAkQAxAEEAkQBRgA'); // Artists param (approx)
  }

  Future<List<MusicTrack>> searchPlaylists(String query) async {
    return _searchType(query, 'EgWKAQIoAWoKEAkQAxAEEAkQBRgA'); // Playlists param (approx)
  }

  Future<List<MusicTrack>> _searchType(String query, String params) async {
    try {
      final response = await _rawRequest('search', {
        'query': query,
        'params': params,
      });

      // Offload heavy parsing to background
      final sections = await YtmParser.findRenderersInBackground(response.body, 'musicShelfRenderer');
      
      final List<MusicTrack> items = [];
      for (var shelf in sections) {
        final shelfItems = shelf['contents'] ?? [];
        for (var item in shelfItems) {
          final renderer = item['musicResponsiveListItemRenderer'];
          if (renderer == null) continue;
          final track = _parseTrackItem(renderer);
          if (track != null) items.add(track);
        }
      }
      return items;
    } catch (e) {
      print('YTM Search Error: $e');
      return [];
    }
  }

  Future<List<MusicTrack>> getRelatedTracks(String videoId) async {
    try {
      final response = await _rawRequest('next', {
        'videoId': videoId,
        'playlistId': 'RDAMVM$videoId',
      });

      // Offload heavy parsing to background
      List renderers = await YtmParser.findRenderersInBackground(response.body, 'playlistPanelVideoRenderer');
      
      if (renderers.isEmpty) {
        renderers = await YtmParser.findRenderersInBackground(response.body, 'musicResponsiveListItemRenderer');
      }

      if (renderers.isEmpty) {
        // Fallback: Find the "Related" tab browseId and fetch results
        final data = jsonDecode(response.body);
        final List tabs = [];
        _findRenderers(data, 'tabRenderer', tabs);
        
        String? browseId;
        for (var tab in tabs) {
          final title = tab['title']?.toString().toLowerCase();
          if (title == 'related') {
            browseId = tab['endpoint']?['browseEndpoint']?['browseId'];
            break;
          }
        }

        if (browseId != null) {
          final browseResponse = await _rawRequest('browse', {'browseId': browseId});
          renderers = await YtmParser.findRenderersInBackground(browseResponse.body, 'musicResponsiveListItemRenderer');
        }
      }

      final List<MusicTrack> tracks = [];
      for (var renderer in renderers) {
        final trackId = renderer['videoId'] ?? renderer['playlistItemData']?['videoId'];
        if (trackId == null || trackId == videoId) continue;

        final track = _parseTrackItem(renderer);
        if (track != null) {
          tracks.add(track);
        }
      }
      return tracks;
    } catch (e) {
      print('YTM Related Tracks Error: $e');
      return [];
    }
  }

  Future<List<MusicTrack>> getPlaylistTracks(String playlistId) async {
    try {
      String browseId = playlistId;
      if (!playlistId.startsWith('VL') && playlistId.startsWith('PL')) {
         browseId = 'VL$playlistId';
      }

      final data = await _sendRequest('browse', {'browseId': browseId});
      
      // Try to get playlist art for fallback
      String? playlistArt;
      try {
        final List? thumbs = data['header']?['musicEditablePlaylistDetailHeaderRenderer']?['header']?['musicPlaylistDetailHeaderRenderer']?['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] ??
                           data['header']?['musicPlaylistDetailHeaderRenderer']?['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'];
        if (thumbs != null && thumbs.isNotEmpty) {
           playlistArt = thumbs.last['url'];
        }
      } catch (e) {}

      final List<MusicTrack> items = [];
      List renderers = [];

      _findRenderers(data, 'musicPlaylistShelfRenderer', renderers);

      if (renderers.isNotEmpty) {
        final contents = renderers.first['contents'];
        if (contents is List) {
           for (var item in contents) {
              final renderer = item['musicResponsiveListItemRenderer'];
              if (renderer == null) continue;
               final track = _parseTrackItem(renderer, fallbackArt: playlistArt, forceArt: true);
               if (track != null) items.add(track);
           }
        }
      }
      return items;
    } catch (e) {
      print('YTM Playlist Tracks Error: $e');
      return [];
    }
  }

  Future<List<MusicTrack>> getAlbumDetails(String albumId) async {
    try {
      final data = await _sendRequest('browse', {'browseId': albumId});
      
      // Get the best possible album art ONLY from the header
      String? albumArt;
      try {
        final List headerRenderers = [];
        // Only look in the top-level header property
        if (data['header'] != null) {
          _findRenderers(data['header'], 'musicAlbumReleaseHeaderRenderer', headerRenderers);
          _findRenderers(data['header'], 'musicPlaylistDetailHeaderRenderer', headerRenderers);
          _findRenderers(data['header'], 'musicEditablePlaylistDetailHeaderRenderer', headerRenderers);
        }

        for (var h in headerRenderers) {
          final List? thumbs = h['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] ??
                             h['header']?['musicPlaylistDetailHeaderRenderer']?['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'];
          if (thumbs != null && thumbs.isNotEmpty) {
            albumArt = thumbs.last['url'];
            break;
          }
        }
      } catch (e) {}

      final List<MusicTrack> items = [];
      
      dynamic contents;
      try {
        contents = data['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
      } catch (e) {}

      if (contents == null || contents is! List) {
        List renderers = [];
        _findRenderers(data, 'musicPlaylistShelfRenderer', renderers);
        if (renderers.isEmpty) {
          _findRenderers(data, 'musicShelfRenderer', renderers);
        }
        
        if (renderers.isNotEmpty) {
           final list = renderers.first['contents'];
           if (list is List) {
             for (var item in list) {
               final renderer = item['musicResponsiveListItemRenderer'];
               if (renderer == null) continue;
               final track = _parseTrackItem(renderer, fallbackArt: albumArt, forceArt: true);
               if (track != null) items.add(track);
             }
           }
        }
        return items;
      }

      for (var section in contents) {
        final shelf = section['musicPlaylistShelfRenderer'] ?? section['musicShelfRenderer'];
        if (shelf == null) continue;
        
        final shelfContents = shelf['contents'];
        if (shelfContents is List) {
          for (var item in shelfContents) {
            final renderer = item['musicResponsiveListItemRenderer'];
            if (renderer == null) continue;
            final track = _parseTrackItem(renderer, fallbackArt: albumArt, forceArt: true);
            if (track != null) items.add(track);
          }
          if (items.isNotEmpty) break;
        }
      }
      
      return items;
    } catch (e) {
      print('YTM Album Details Error: $e');
      return [];
    }
  }

  MusicTrack? _parseTrackItem(dynamic renderer, {bool isCard = false, String? fallbackArt, bool forceArt = false}) {
    try {
      dynamic videoId;
      if (isCard) {
        videoId = renderer['buttons']?[0]?['buttonRenderer']?['command']?['watchEndpoint']?['videoId'];
      } else {
        videoId = renderer['playlistItemData']?['videoId'] ??
                  renderer['navigationEndpoint']?['watchEndpoint']?['videoId'] ??
                  renderer['onTap']?['watchEndpoint']?['videoId'] ??
                  renderer['overlay']?['musicItemThumbnailOverlayRenderer']?['content']?['musicPlayButtonRenderer']?['playNavigationEndpoint']?['watchEndpoint']?['videoId'];
      }

      // If no videoId, check for browseId (for Albums/Artists)
      videoId ??= renderer['navigationEndpoint']?['browseEndpoint']?['browseId'] ?? 
                  renderer['onTap']?['browseEndpoint']?['browseId'];
      
      if (videoId == null) return null;

      String? title;
      if (isCard) {
        title = renderer['title']?['runs']?[0]?['text'];
      } else {
        final flexColumns = renderer['flexColumns'] as List?;
        if (flexColumns != null && flexColumns.isNotEmpty) {
          title = flexColumns[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0]?['text'];
        }
        title ??= renderer['title']?['runs']?[0]?['text']; // Fallback for playlistPanelVideoRenderer
      }

      List? runs;
      if (isCard) {
        runs = renderer['subtitle']?['runs'] as List?;
      } else {
        final flexColumns = renderer['flexColumns'] as List?;
        if (flexColumns != null && flexColumns.length > 1) {
          runs = flexColumns[1]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List?;
        }
        runs ??= renderer['longBylineText']?['runs'] as List? ?? 
                renderer['shortBylineText']?['runs'] as List?; // Fallback
      }
      final finalRuns = runs ?? [];

      String? artist, album, duration;

      for (var run in finalRuns) {
        if (run is! Map) continue;
        final text = run['text']?.toString() ?? '';
        final endpoint = run['navigationEndpoint']?['browseEndpoint'];
        final String? browseId = endpoint?['browseId'];
        
        if (browseId != null && browseId.startsWith('UC')) {
          artist = text;
        } else if (text == ' • ') {
          continue;
        } else if (text.contains(' views') || text.contains(' subscribers')) {
          continue;
        } else if (artist == null && (browseId != null || endpoint != null)) {
          artist = text;
        } else if (album == null && browseId != null && browseId.startsWith('MPRE')) {
           album = text;
        } else if (duration == null && text.contains(':')) {
           duration = text;
        }
      }

      // Final fallback for artist if still null
      if (artist == null && finalRuns.isNotEmpty) {
        for (var run in finalRuns) {
           final text = run['text']?.toString() ?? '';
           if (text != ' • ' && !text.contains(':') && !text.contains(' views')) {
             artist = text;
             break;
           }
        }
      }

      final List thumbnailsList = renderer['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] as List? ?? 
                                  renderer['thumbnail']?['thumbnails'] as List? ?? [];
      final String image = thumbnailsList.isNotEmpty ? thumbnailsList.last['url'] : '';
      
      final Map<String, String> thumbnails = {};
      for (var thumb in thumbnailsList) {
        final url = thumb['url']?.toString() ?? '';
        final width = thumb['width'] ?? 0;
        if (width <= 120) thumbnails['small'] = url;
        else if (width <= 256) thumbnails['medium'] = url;
        else thumbnails['large'] = url;
      }
      
      // Ensure we have a high-res large one if possible
      if (!thumbnails.containsKey('large') && image.isNotEmpty) {
        thumbnails['large'] = image.replaceAll('w60-h60', 'w500-h500').replaceAll('w120-h120', 'w500-h500');
      }

      final String artUrl = (forceArt && fallbackArt != null && fallbackArt.isNotEmpty)
          ? fallbackArt
          : (image.isNotEmpty 
              ? image.replaceAll('w60-h60', 'w500-h500').replaceAll('w120-h120', 'w500-h500')
              : (fallbackArt ?? 'https://music.youtube.com/img/on__music_logo_mono.png')); 

      // Ensure high-res if using fallbackArt
      final String finalArt = artUrl.replaceAll('w60-h60', 'w500-h500').replaceAll('w120-h120', 'w500-h500');

      if (forceArt && fallbackArt != null && fallbackArt.isNotEmpty) {
        thumbnails['large'] = finalArt;
        thumbnails['medium'] = finalArt;
        thumbnails['small'] = finalArt;
      } else if (!thumbnails.containsKey('large')) {
        thumbnails['large'] = finalArt;
      }
          
      return MusicTrack(
        id: videoId as String,
        title: title ?? 'Unknown',
        artist: artist ?? 'Unknown',
        album: album ?? 'YouTube Music',
        albumArtUrl: finalArt,
        thumbnails: thumbnails,
        duration: duration,
        source: MusicSource.youtube,
      );
    } catch (e) {
      print('Error parsing track: $e');
      return null;
    }
  }

  void _findRenderers(dynamic obj, String targetKey, List results) {
    if (obj is Map) {
      final target = obj[targetKey];
      if (target != null) {
        results.add(target);
      }
      // Continue searching children
      for (var value in obj.values) {
        if (value is Map || value is List) {
          _findRenderers(value, targetKey, results);
        }
      }
    } else if (obj is List) {
      for (var item in obj) {
        if (item is Map || item is List) {
          _findRenderers(item, targetKey, results);
        }
      }
    }
  }
}
