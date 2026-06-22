import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'media_player.dart';
import 'spotify_provider.dart';
import 'youtube_provider.dart';

/// State of the media provider manager.
class MediaProviderState {
  final MediaPlayer? activeProvider;
  final List<MediaPlayer> availableProviders;
  final bool isLoading;

  const MediaProviderState({
    this.activeProvider,
    this.availableProviders = const [],
    this.isLoading = false,
  });

  MediaProviderState copyWith({
    MediaPlayer? activeProvider,
    List<MediaPlayer>? availableProviders,
    bool? isLoading,
    bool clearActive = false,
  }) {
    return MediaProviderState(
      activeProvider: clearActive ? null : (activeProvider ?? this.activeProvider),
      availableProviders: availableProviders ?? this.availableProviders,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Manages media providers and handles fallback logic.
///
/// Fallback chain: Spotify → Apple Music → YouTube → "No provider"
class MediaProviderManager extends StateNotifier<MediaProviderState> {
  MediaProviderManager() : super(const MediaProviderState()) {
    _initProviders();
  }

  void _initProviders() {
    final providers = <MediaPlayer>[
      SpotifyPlayer(),
      YoutubePlayer(),
    ];
    state = state.copyWith(availableProviders: providers);
  }

  /// Connect to a specific provider.
  Future<bool> connectProvider(MediaPlayer provider) async {
    state = state.copyWith(isLoading: true);
    try {
      final success = await provider.authenticate();
      if (success) {
        state = state.copyWith(
          activeProvider: provider,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  /// Disconnect the active provider.
  Future<void> disconnectActive() async {
    final current = state.activeProvider;
    if (current != null) {
      await current.disconnect();
      state = state.copyWith(clearActive: true);
    }
  }

  /// Play a track using the active provider.
  /// Falls back through the chain if the active provider fails.
  Future<void> playTrack(MediaTrack track) async {
    final provider = state.activeProvider;
    if (provider == null) {
      // Try to connect the first available provider
      for (final p in state.availableProviders) {
        if (await p.authenticate()) {
          state = state.copyWith(activeProvider: p);
          await p.play(track);
          return;
        }
      }
      return;
    }

    try {
      await provider.play(track);
    } catch (e) {
      // Active provider failed, try fallback
      for (final p in state.availableProviders) {
        if (p != provider && await p.authenticate()) {
          state = state.copyWith(activeProvider: p);
          await p.play(track);
          return;
        }
      }
    }
  }
}

final mediaProviderManagerProvider =
    StateNotifierProvider<MediaProviderManager, MediaProviderState>((ref) {
  return MediaProviderManager();
});
