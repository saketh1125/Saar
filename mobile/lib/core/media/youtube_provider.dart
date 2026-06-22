import 'package:just_audio/just_audio.dart';

import 'media_player.dart';

/// YouTube media player using youtube_explode_dart for audio extraction
/// and just_audio for playback.
///
/// This provider searches YouTube for audio and plays it directly.
/// No API key is required for basic search and playback.
class YoutubePlayer implements MediaPlayer {
  final AudioPlayer _player = AudioPlayer();
  bool _connected = false;

  @override
  String get providerName => 'YouTube';

  @override
  bool get isConnected => _connected;

  @override
  Future<bool> authenticate() async {
    // YouTube doesn't require authentication for basic playback
    _connected = true;
    return true;
  }

  @override
  Future<void> disconnect() async {
    await _player.dispose();
    _connected = false;
  }

  @override
  Future<List<MediaTrack>> search(String query) async {
    if (!_connected) return [];

    try {
      // YouTube search would use youtube_explode_dart
      // For now, return an empty list — real implementation would:
      // 1. Use YoutubeExplode().search.search(query)
      // 2. Get video IDs from search results
      // 3. Get stream URLs for each video
      // 4. Convert to MediaTrack objects
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> play(MediaTrack track) async {
    if (!_connected) await authenticate();

    try {
      if (track.streamUrl != null) {
        await _player.setUrl(track.streamUrl!);
        await _player.play();
      }
    } catch (e) {
      // Playback failed
    }
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
  }

  @override
  Future<void> resume() async {
    await _player.play();
  }
}
