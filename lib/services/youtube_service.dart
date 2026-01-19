import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../models/music_track.dart';
import 'ytm_client.dart';

class YouTubeService {
  static final YouTubeService _instance = YouTubeService._internal();
  factory YouTubeService() => _instance;
  YouTubeService._internal() {
    // Global HTTP overrides are now handled in main.dart
  }

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
    return searchPlaylists('Top Charts');
  }

  Future<List<MusicTrack>> getNewReleases() async {
    return searchAlbums('New Albums');
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

  /// Extract audio stream URL from YouTube video using nirvay_audio_success approach
  /// Fetches the best muxed stream (audio+video) to ensure highest quality audio
  Future<String> getAudioStreamUrl(String videoId) async {
    try {
      // Get video manifest with multiple API clients for better reliability
      final manifest = await _yt.videos.streamsClient.getManifest(
        videoId,
        /* ytClients: [YoutubeApiClient.androidVr, YoutubeApiClient.android], */
      );
      
      // Prefer muxed streams (audio+video) for better quality
      if (manifest.muxed.isNotEmpty) {
        final audioStream = manifest.muxed.withHighestBitrate();
        return audioStream.url.toString();
      }
      
      // Fallback to audio-only streams if muxed not available
      if (manifest.audioOnly.isNotEmpty) {
        final audioStream = manifest.audioOnly.withHighestBitrate();
        return audioStream.url.toString();
      }
      
      throw Exception('No audio streams available for video ID: $videoId');
    } catch (e) {
      throw Exception('Failed to extract audio URL: $e');
    }
  }

  void dispose() {
    _yt.close();
  }
}
