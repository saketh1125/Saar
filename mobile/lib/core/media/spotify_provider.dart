import 'package:spotify_sdk/spotify_sdk.dart';

import 'media_player.dart';

/// Spotify media player implementation using the official Spotify SDK.
///
/// Requires the Spotify app to be installed on the device. This controls
/// the Spotify app remotely — it does not stream audio directly.
/// Requires Spotify Premium for playback control.
class SpotifyPlayer implements MediaPlayer {
  bool _connected = false;
  String? _accessToken;

  @override
  String get providerName => 'Spotify';

  @override
  bool get isConnected => _connected;

  @override
  Future<bool> authenticate() async {
    try {
      _accessToken = await SpotifySdk.getAccessToken(
        clientId: const String.fromEnvironment('SPOTIFY_CLIENT_ID', defaultValue: ''),
        redirectUrl: 'kashinav://callback',
        scope: 'user-read-playback-state,user-modify-playback-state,user-library-read',
      );
      _connected = _accessToken != null && _accessToken!.isNotEmpty;
      return _connected;
    } catch (e) {
      _connected = false;
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    _accessToken = null;
    _connected = false;
  }

  @override
  Future<List<MediaTrack>> search(String query) async {
    if (!_connected || _accessToken == null) return [];

    try {
      // Spotify SDK doesn't have a direct search API through App Remote.
      // For search, we would need to use the Spotify Web API with the access token.
      // For now, return an empty list — real implementation would call
      // https://api.spotify.com/v1/search?q={query}&type=track
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> play(MediaTrack track) async {
    if (!_connected) {
      final authenticated = await authenticate();
      if (!authenticated) return;
    }

    try {
      await SpotifySdk.play(spotifyUri: 'spotify:track:${track.id}');
    } catch (e) {
      // Playback failed — Spotify app may not be available
    }
  }

  @override
  Future<void> pause() async {
    if (!_connected) return;
    try {
      await SpotifySdk.pause();
    } catch (e) {
      // Pause failed
    }
  }

  @override
  Future<void> stop() async {
    if (!_connected) return;
    try {
      await SpotifySdk.pause();
    } catch (e) {
      // Stop failed
    }
  }

  @override
  Future<void> resume() async {
    if (!_connected) return;
    try {
      await SpotifySdk.resume();
    } catch (e) {
      // Resume failed
    }
  }
}
