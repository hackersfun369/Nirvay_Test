import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/music_track.dart';

class ShareService {
  // final ScreenshotController _screenshotController = ScreenshotController();

  static Future<void> shareTrack(MusicTrack track) async {
    final text = 'Check out "${track.title}" by ${track.artist} on Nirvay!\n\nListen here: https://music.youtube.com/watch?v=${track.id}';
    await Share.share(text);
  }
}
