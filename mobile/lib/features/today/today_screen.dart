import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';

/// Tab 2 — Contextual "Today" Hub (PRD §3.2.1). A dynamic home screen that
/// adapts to time of day with a sun-guided gradient header, the Panchang card,
/// and a 3-slot (morning / afternoon / evening) itinerary block.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  Itinerary? _itinerary;
  Panchang? _panchang;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final results = await Future.wait([
      ref.read(itineraryRepositoryProvider).generate(lat: 25.3176, lng: 83.0130),
      ref.read(panchangRepositoryProvider).forDate(now),
    ]);
    if (mounted) {
      setState(() {
        _itinerary = results[0] as Itinerary;
        _panchang = results[1] as Panchang;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _gradientHeader(context)),
          const SliverToBoxAdapter(child: OfflineBanner()),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(child: _panchangCard(context)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const _SectionTitle('Your Day'),
                  const SizedBox(height: 8),
                  if (_itinerary != null)
                    for (final step in _itinerary!.steps) _ItineraryCard(step: step),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _gradientHeader(BuildContext context) {
    final hour = DateTime.now().hour;
    final List<Color> colors;
    if (hour >= 5 && hour < 9) {
      colors = [KashiColors.saffronGold, KashiColors.terracotta];
    } else if (hour >= 9 && hour < 18) {
      colors = [KashiColors.dustyOrange, KashiColors.deepIndigo];
    } else if (hour >= 18 && hour < 20) {
      colors = [KashiColors.deepIndigo, KashiColors.nightCanvas];
    } else {
      colors = [KashiColors.nightCanvas, Colors.black];
    }
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        bottom: 28,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greeting(),
            style: const TextStyle(
              color: KashiColors.sunriseCanvas,
              fontFamily: 'Outfit',
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Namaste 🙏 — here is your Kashi for today',
            style: TextStyle(
              color: KashiColors.sunriseCanvas.withValues(alpha: 0.85),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h >= 4 && h < 12) return 'Subah Benaras';
    if (h >= 12 && h < 17) return 'Good Afternoon';
    if (h >= 17 && h < 20) return 'Sandhya Aarti';
    return 'Good Night';
  }

  Widget _panchangCard(BuildContext context) {
    final p = _panchang;
    if (p == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🪔', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('Panchang · ${p.date}',
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              _Pill('Tithi: ${p.tithi}'),
              _Pill('Nakshatra: ${p.nakshatra}'),
              _Pill('Abhijit: ${p.abhijitMuhurta}'),
            ],
          ),
          const SizedBox(height: 12),
          for (final r in p.rituals)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: KashiColors.saffronGold),
                  const SizedBox(width: 6),
                  Text('${r.time} — ${r.name} (${r.location})'),
                ],
              ),
            ),
          if (p.astrologicalWarning != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: KashiColors.terracotta.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(p.astrologicalWarning!,
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(text,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.w700,
            )),
      );
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: KashiColors.saffronGold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: const TextStyle(fontSize: 12)),
      );
}

class _ItineraryCard extends StatelessWidget {
  const _ItineraryCard({required this.step});
  final ItineraryStep step;

  Color _accent() => switch (step.timeSlot) {
        'morning' => KashiColors.saffronGold,
        'afternoon' => KashiColors.dustyOrange,
        _ => KashiColors.deepIndigo,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: _accent(), width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(step.estimatedStart,
                  style: TextStyle(
                    color: _accent(),
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Outfit',
                  )),
              const SizedBox(width: 8),
              Text('${step.estimatedDurationMins} min',
                  style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              Text(step.timeSlot.toUpperCase(),
                  style: TextStyle(
                      color: _accent(), fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(step.title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(step.description, style: Theme.of(context).textTheme.bodyMedium),
          if (step.practicalTips.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(step.practicalTips,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
