import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';

/// Sliding POI detail card (design §3.1): drag handle, title + category badge,
/// 3-sentence AI summary, navigation + audio-guide buttons, an expandable AI
/// source verification list, and a Crowd Dial (§4.5).
class PoiDetailSheet extends ConsumerStatefulWidget {
  const PoiDetailSheet({super.key, required this.poi});
  final Poi poi;

  @override
  ConsumerState<PoiDetailSheet> createState() => _PoiDetailSheetState();
}

class _PoiDetailSheetState extends ConsumerState<PoiDetailSheet> {
  CrowdDensity? _crowd;
  bool _loadingCrowd = true;
  bool _sourcesExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadCrowd();
  }

  Future<void> _loadCrowd() async {
    final repo = ref.read(crowdDensityRepositoryProvider);
    final c = await repo.forPlace(widget.poi.id);
    if (mounted) setState(() {
      _crowd = c;
      _loadingCrowd = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final poi = widget.poi;
    return DraggableScrollableSheet(
      initialChildSize: 0.42,
      minChildSize: 0.25,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: KashiColors.nightComponent,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: KashiColors.saffronGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    poi.name,
                    style: const TextStyle(
                      color: KashiColors.sunriseCanvas,
                      fontFamily: 'Outfit',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _CategoryBadge(category: poi.category),
              ],
            ),
            if (poi.summary != null) ...[
              const SizedBox(height: 12),
              Text(
                poi.summary!,
                style: TextStyle(
                  color: KashiColors.sunriseCanvas.withValues(alpha: 0.85),
                  height: 1.4,
                ),
              ),
            ],
            if (poi.accessibility != null) ...[
              const SizedBox(height: 8),
              Text(
                '🦽 Step access: ${poi.accessibility}',
                style: TextStyle(color: KashiColors.neonSaffron.withValues(alpha: 0.9)),
              ),
            ],
            const SizedBox(height: 16),
            if (_loadingCrowd)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              )
            else if (_crowd != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: KashiColors.nightCanvas,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: CrowdDial(density: _crowd!),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.directions_walk),
                    label: const Text('Navigate'),
                    style: FilledButton.styleFrom(
                      backgroundColor: KashiColors.saffronGold,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pedestrian route via OpenRouteService '
                            '(needs live ORS key to compute).'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.headphones),
                  label: const Text('Guide'),
                  style: FilledButton.styleFrom(
                    backgroundColor: KashiColors.terracotta,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Audio guide player triggered.')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // AI source verification list (expandable, design §3.1).
            GestureDetector(
              onTap: () => setState(() => _sourcesExpanded = !_sourcesExpanded),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: KashiColors.nightCanvas,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _sourcesExpanded ? Icons.expand_less : Icons.expand_more,
                      color: KashiColors.neonSaffron,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI Verification Sources',
                        style: TextStyle(
                          color: KashiColors.sunriseCanvas.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${poi.sources.isEmpty ? "OSM" : poi.sources.length} source(s)',
                      style: TextStyle(
                        color: KashiColors.neonSaffron.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_sourcesExpanded) ...[
              const SizedBox(height: 8),
              for (final s in (poi.sources.isEmpty ? ['osm'] : poi.sources))
                _SourceChip(source: s),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});
  final PoiCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: KashiColors.saffronGold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KashiColors.saffronGold.withValues(alpha: 0.5)),
      ),
      child: Text(
        category.name.toUpperCase(),
        style: const TextStyle(
          color: KashiColors.neonSaffron,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.source});
  final String source;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          const Icon(Icons.verified, size: 14, color: KashiColors.riverJade),
          const SizedBox(width: 6),
          Text(
            'Verified via $source',
            style: TextStyle(
              color: KashiColors.sunriseCanvas.withValues(alpha: 0.75),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
