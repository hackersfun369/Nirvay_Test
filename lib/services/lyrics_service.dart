import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';

import '../models/lyric_line.dart';
import '../services/saavn_service.dart';

class LyricsService {
  final HtmlUnescape _unescape = HtmlUnescape();
  final JioSaavnService _saavnService = JioSaavnService();



  Future<List<LyricLine>> getLyrics(String trackId, String title, String artist) async {
    // Try Lrclib first (good public lyrics API)
    try {
      final url = Uri.parse('https://lrclib.net/api/get?artist=${Uri.encodeComponent(artist)}&track=${Uri.encodeComponent(title)}');
      
      // Use HttpClient to avoid HandshakeException
      final client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      final request = await client.getUrl(url);
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody);
        final String? syncedLyrics = data['syncedLyrics'];
        final String? plainLyrics = data['plainLyrics'];

        if (syncedLyrics != null) {
          return _parseLrc(syncedLyrics);
        } else if (plainLyrics != null) {
          return _parsePlain(plainLyrics);
        }
      }
    } catch (e) {
      print('Lrclib Lyrics Error: $e');
    }

    // Fallback: Try JioSaavn
    try {
      final saavnLyrics = await _saavnService.getLyrics(trackId);
      if (saavnLyrics != null && saavnLyrics.isNotEmpty) {
        // Saavn usually returns plain text, but we'll try to parse just in case it's LRC
        return _parsePlain(saavnLyrics);
      }
    } catch (e) {
      print('Saavn Fallback Error: $e');
    }
    
    return [];
  }

  List<LyricLine> _parseLrc(String lrc) {
    final List<LyricLine> lines = [];
    final RegExp regExp = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');
    
    for (final line in lrc.split('\n')) {
      final match = regExp.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final milliseconds = int.parse(match.group(3)!);
        final text = match.group(4)!.trim();
        
        // Correctly handle 2-digit vs 3-digit milliseconds
        final actualMs = match.group(3)!.length == 2 ? milliseconds * 10 : milliseconds;

        lines.add(LyricLine(
          startTime: Duration(minutes: minutes, seconds: seconds, milliseconds: actualMs),
          text: text,
        ));
      }
    }
    return lines;
  }

  List<LyricLine> _parsePlain(String plain) {
    return plain.split('\n')
      .where((line) => line.trim().isNotEmpty)
      .map((line) => LyricLine(startTime: Duration.zero, text: line.trim()))
      .toList();
  }
}
