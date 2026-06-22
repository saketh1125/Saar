/// Abstract media player interface for Spotify, Apple Music, and YouTube.
///
/// Each provider implements this interface to provide a unified API for
/// searching and playing tracks across different music services.
abstract class MediaPlayer {
  /// Display name of the provider (e.g., "Spotify", "Apple Music").
  String get providerName;

  /// Whether the provider is currently connected/authenticated.
  bool get isConnected;

  /// Authenticate with the provider. Returns true if successful.
  Future<bool> authenticate();

  /// Disconnect from the provider.
  Future<void> disconnect();

  /// Search for tracks matching [query].
  Future<List<MediaTrack>> search(String query);

  /// Play a track. If the provider is not connected, attempts to connect first.
  Future<void> play(MediaTrack track);

  /// Pause playback.
  Future<void> pause();

  /// Stop playback.
  Future<void> stop();

  /// Resume playback.
  Future<void> resume();
}

/// A media track that can be played by any provider.
class MediaTrack {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? imageUrl;
  final Duration? duration;
  final String? streamUrl;

  const MediaTrack({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.imageUrl,
    this.duration,
    this.streamUrl,
  });

  @override
  String toString() => '$title — $artist';
}
