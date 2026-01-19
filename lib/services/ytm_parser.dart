import 'dart:convert';
import 'package:flutter/foundation.dart';

class YtmParser {
  /// Offloads JSON decoding and renderer finding to a background isolate.
  static Future<List<dynamic>> findRenderersInBackground(String responseBody, String targetKey) async {
    return compute(_parseAndFind, {
      'body': responseBody,
      'key': targetKey,
    });
  }

  static List<dynamic> _parseAndFind(Map<String, String> params) {
    try {
      final String body = params['body']!;
      final String key = params['key']!;
      final dynamic data = jsonDecode(body);
      final List<dynamic> results = [];
      _findRenderers(data, key, results);
      return results;
    } catch (e) {
      debugPrint('YtmParser Error: $e');
      return [];
    }
  }

  static void _findRenderers(dynamic obj, String targetKey, List<dynamic> results) {
    if (obj is Map) {
      final target = obj[targetKey];
      if (target != null) {
        results.add(target);
      }
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
