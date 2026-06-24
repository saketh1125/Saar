import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Voice-assistant overlay: a dark glassmorphic bottom sheet with a waveform
/// visualizer and live transcript (design §4.3). State is driven by the parent.
class VoiceOverlay extends StatelessWidget {
  const VoiceOverlay({
    super.key,
    required this.transcript,
    required this.listening,
    required this.parsing,
    this.onTap,
  });
  final String transcript;
  final bool listening;
  final bool parsing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: listening ? onTap : null,
      child: Container(
      decoration: BoxDecoration(
        color: KashiColors.nightCanvas.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: KashiColors.neonSaffron,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          _Waveform(active: listening),
          const SizedBox(height: 24),
          if (parsing)
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(KashiColors.neonSaffron),
              ),
            )
          else
            Text(
              transcript.isEmpty
                  ? (listening ? 'Tap to stop' : 'Tap the mic and speak')
                  : '"$transcript"',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: KashiColors.sunriseCanvas,
                fontFamily: 'Outfit',
                fontSize: 18,
                height: 1.3,
              ),
            ),
        ],
      ),
      ),
    );
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final bars = List.generate(28, (i) => i);
    return SizedBox(
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final i in bars)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200 + (i % 5) * 60),
                curve: Curves.easeInOut,
                height: active ? 12.0 + ((i * 37) % 44) : 6,
                width: 4,
                decoration: BoxDecoration(
                  color: KashiColors.saffronGold
                      .withValues(alpha: active ? 0.9 : 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
