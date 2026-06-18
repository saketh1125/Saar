import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../networking/connectivity.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';
import '../../data/models/models.dart';

/// Thin saffron warning banner that slides down when offline (design §4.2).
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: online
          ? const SizedBox.shrink()
          : Material(
              color: KashiColors.saffronGold,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Offline Mode — Showing Cached Kashi Data',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

/// Frosted-glass search header used above the map (design §3.1). Blurs whatever
/// sits behind it using [BackdropFilter].
class GlassSearchHeader extends StatelessWidget {
  const GlassSearchHeader({
    super.key,
    required this.hint,
    this.onMenu,
    this.onRefresh,
    this.refreshing = false,
    this.controller,
    this.onSubmitted,
    this.leading,
  });
  final String hint;
  final VoidCallback? onMenu;
  final VoidCallback? onRefresh;
  final bool refreshing;
  final TextEditingController? controller;
  final ValueChanged<String>? onSubmitted;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                leading ??
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: onMenu,
                    ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onSubmitted: onSubmitted,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
                if (onRefresh != null)
                  RefreshIcon(refreshing: refreshing, onPressed: onRefresh),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The force-live-refresh toggle icon; rotates continuously while refreshing
/// (design §4.1 step 2).
class RefreshIcon extends StatefulWidget {
  const RefreshIcon({super.key, required this.refreshing, this.onPressed});
  final bool refreshing;
  final VoidCallback? onPressed;

  @override
  State<RefreshIcon> createState() => _RefreshIconState();
}

class _RefreshIconState extends State<RefreshIcon>
    with SingleTickerProviderStateMixin {
  AnimationController? _spin;

  @override
  void didUpdateWidget(covariant RefreshIcon old) {
    super.didUpdateWidget(old);
    if (widget.refreshing && !old.refreshing) {
      _spin ??= AnimationController(
        vsync: this,
        duration: const Duration(seconds: 1),
      )..repeat();
      setState(() {});
    } else if (!widget.refreshing && old.refreshing) {
      _spin?.stop();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _spin?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = const Icon(Icons.refresh, color: KashiColors.neonSaffron);
    return IconButton(
      onPressed: widget.onPressed,
      icon: widget.refreshing && _spin != null
          ? RotationTransition(turns: _spin!, child: child)
          : child,
    );
  }
}

/// Semicircular crowd-density dial, 0–100, with Peaceful/Active/Congested bands
/// and an optional sparkline (design §4.5).
class CrowdDial extends StatelessWidget {
  const CrowdDial({super.key, required this.density});
  final CrowdDensity density;

  @override
  Widget build(BuildContext context) {
    final idx = density.indexScore;
    final color = idx <= 30
        ? KashiColors.riverJade
        : idx <= 70
            ? KashiColors.saffronGold
            : KashiColors.terracotta;
    final label = idx <= 30
        ? 'Peaceful'
        : idx <= 70
            ? 'Active'
            : 'Heavily Congested';
    return Row(
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: idx / 100,
                  strokeWidth: 6,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Text('$idx',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700, fontSize: 16)),
              if (density.prediction != null) ...[
                const SizedBox(height: 2),
                Text('Next peak: ${density.prediction!.nextPeak}',
                    style: Theme.of(context).textTheme.bodyMedium),
                Text(density.prediction!.recommendation,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Shimmering placeholder used while live data loads (design §4.1 step 5).
class ShimmerBlock extends StatefulWidget {
  const ShimmerBlock({super.key, this.height = 16, this.width = double.infinity, this.radius = 8});
  final double height;
  final double width;
  final double radius;
  @override
  State<ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 2, 0),
              end: Alignment(1 - t * 2, 0),
              colors: [
                surface,
                KashiColors.saffronGold.withValues(alpha: 0.35),
                surface,
              ],
            ),
          ),
        );
      },
    );
  }
}
