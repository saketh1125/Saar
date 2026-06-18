import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/journal_dao.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/journal_entry.dart';
import '../../data/repositories/repositories.dart';

/// Tab 4 — Reflection Journal (PRD §3.2.2). Mood picker + composer; entries
/// persist to local SQLite first (handoff §4.3), then the AI reflection is
/// fetched asynchronously from `/processJournalEntry` and merged back.
class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  List<JournalEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final dao = await ref.read(journalDaoProvider.future);
    final entries = await dao.all();
    if (mounted) setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  void _openComposer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _ComposerSheet(),
    ).then((_) => _refresh());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reflection Journal'), actions: [
        IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.edit),
        label: const Text('New Entry'),
        backgroundColor: KashiColors.saffronGold,
        foregroundColor: Colors.white,
        onPressed: _openComposer,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: _entries.length,
                  itemBuilder: (_, i) => _EntryCard(entry: _entries[i], onChanged: _refresh),
                ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📖', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('No reflections yet',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Capture how Kashi makes you feel. Each entry gets an AI reflection.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.onChanged});
  final JournalEntry entry;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final mood = Mood.list.firstWhere(
      (m) => m.key == entry.mood,
      orElse: () => Mood.list.first,
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(mood.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('EEE, d MMM · h:mm a').format(entry.createdAt),
                          style: Theme.of(context).textTheme.bodySmall),
                      if (entry.sentimentLabel != null)
                        Text(entry.sentimentLabel!,
                            style: const TextStyle(
                                fontSize: 11, color: KashiColors.saffronGold)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () async {
                    final ctx = context;
                    final ref = ProviderScope.containerOf(context);
                    final dao = await ref.read(journalDaoProvider.future);
                    await dao.delete(entry.id);
                    if (ctx.mounted) onChanged();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(entry.content, style: Theme.of(context).textTheme.bodyLarge),
            if (entry.aiReflection != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: KashiColors.saffronGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                      left: BorderSide(color: KashiColors.saffronGold, width: 3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Text('🪔', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text('AI Reflection',
                          style: TextStyle(
                              color: KashiColors.terracotta,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 6),
                    Text(entry.aiReflection!,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
            if (entry.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: [
                  for (final t in entry.tags)
                    Chip(
                      label: Text('#$t', style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ComposerSheet extends ConsumerStatefulWidget {
  const _ComposerSheet();

  @override
  ConsumerState<_ComposerSheet> createState() => _ComposerSheetState();
}

class _ComposerSheetState extends ConsumerState<_ComposerSheet> {
  final _controller = TextEditingController();
  String _mood = Mood.list.first.key;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    final dao = await ref.read(journalDaoProvider.future);
    final entry = await dao.insert(content: text, mood: _mood);
    // Fire-and-forget the AI reflection; it merges back into SQLite.
    final processor = ref.read(journalProcessingRepositoryProvider);
    processor.process(content: text).then((r) async {
      await dao.applyReflection(
        entry.id,
        score: r.score,
        label: r.label,
        reflection: r.reflection,
        tags: r.tags,
      );
    });
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            Text('How does Kashi feel right now?',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in Mood.list)
                  ChoiceChip(
                    label: Text('${m.emoji} ${m.label}'),
                    selected: _mood == m.key,
                    selectedColor: KashiColors.saffronGold.withValues(alpha: 0.25),
                    onSelected: (_) => setState(() => _mood = m.key),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 5,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Spent the afternoon by Manikarnika…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_alt),
              label: const Text('Save Entry'),
              style: FilledButton.styleFrom(
                backgroundColor: KashiColors.terracotta,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
