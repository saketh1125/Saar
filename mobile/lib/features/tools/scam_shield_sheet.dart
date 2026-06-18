import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';

/// Scam Shield & fair-price benchmark sheet (design §4.8). Double-panel: fair
/// rates directory + active warnings, with a copy/speak button for Hindi
/// negotiation phrases.
class ScamShieldSheet extends ConsumerStatefulWidget {
  const ScamShieldSheet({super.key});

  @override
  ConsumerState<ScamShieldSheet> createState() => _ScamShieldSheetState();
}

class _ScamShieldSheetState extends ConsumerState<ScamShieldSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  FairPriceDirectory? _dir;
  bool _loading = true;
  final _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = ref.read(fairPriceRepositoryProvider);
    final dir = await repo.directory('en_US');
    if (mounted) setState(() {
      _dir = dir;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: KashiColors.saffronGold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(children: [
                const Text('🛡️', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text('Scam Shield', style: Theme.of(context).textTheme.titleLarge),
              ]),
            ),
            TabBar(
              controller: _tab,
              tabs: const [Tab(text: 'Fair Rates'), Tab(text: 'Active Warnings')],
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tab,
                      children: [
                        _RatesTab(dir: _dir!, controller: controller),
                        _WarningsTab(advisories: _dir!.advisories, controller: controller),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatesTab extends StatelessWidget {
  const _RatesTab({required this.dir, required this.controller});
  final FairPriceDirectory dir;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(20),
      children: [
        Text('Last updated ${dir.lastUpdated.toIso8601String().substring(0, 10)}',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        for (final r in dir.rates)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(r.key,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text('₹${r.minInr}–${r.maxInr}',
                    style: const TextStyle(
                        color: KashiColors.saffronGold,
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        const SizedBox(height: 16),
        const _PhraseCard(
          hindi: 'अस्सी घाट के लिए कितना लोगे?',
          english: 'Assi ghat ke liye kitna loge?',
          meaning: 'How much will you charge for Assi Ghat?',
        ),
      ],
    );
  }
}

class _WarningsTab extends StatelessWidget {
  const _WarningsTab({required this.advisories, required this.controller});
  final List<ScamAdvisory> advisories;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(20),
      children: [
        for (final a in advisories)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: KashiColors.terracotta.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: KashiColors.terracotta.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('⚠️', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(a.triggerLocationId == 'any' ? 'General Advisory' : a.triggerLocationId,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: KashiColors.terracotta)),
                ]),
                const SizedBox(height: 6),
                Text(a.warning, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
      ],
    );
  }
}

class _PhraseCard extends StatefulWidget {
  const _PhraseCard({required this.hindi, required this.english, required this.meaning});
  final String hindi;
  final String english;
  final String meaning;

  @override
  State<_PhraseCard> createState() => _PhraseCardState();
}

class _PhraseCardState extends State<_PhraseCard> {
  final _tts = FlutterTts();
  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KashiColors.riverJade.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.hindi,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                Text(widget.english,
                    style: TextStyle(
                        color: KashiColors.riverJade, fontStyle: FontStyle.italic)),
                Text(widget.meaning, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Copied: ${widget.english}')),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: () async {
              await _tts.setLanguage('hi-IN');
              await _tts.speak(widget.english);
            },
          ),
        ],
      ),
    );
  }
}
