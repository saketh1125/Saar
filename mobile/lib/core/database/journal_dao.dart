import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/journal_entry.dart';
import 'database.dart';

/// Data-access object for journal entries. Writes always go to local SQLite
/// first (handoff §4.3); the [JournalProcessingRepository] fills the AI
/// reflection fields asynchronously and they are merged back here.
class JournalDao {
  JournalDao(this._db);
  final AppDatabase _db;

  Future<List<JournalEntry>> all() async {
    final rows = await _db.raw.query(
      'journal_entries',
      orderBy: 'created_at DESC',
    );
    return rows.map(JournalEntry.fromRow).toList();
  }

  Future<JournalEntry> insert({
    required String content,
    required String mood,
    double? lat,
    double? lng,
  }) async {
    final entry = JournalEntry.create(
      content: content,
      mood: mood,
      lat: lat,
      lng: lng,
    );
    await _db.raw.insert('journal_entries', entry.toRow());
    return entry;
  }

  Future<void> applyReflection(
    String id, {
    required double score,
    required String label,
    required String reflection,
    required List<String> tags,
  }) async {
    await _db.raw.update(
      'journal_entries',
      {
        'sentiment_score': score,
        'sentiment_label': label,
        'ai_reflection': reflection,
        'tags': tags.join('|'),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(String id) async {
    await _db.raw.delete('journal_entries', where: 'id = ?', whereArgs: [id]);
  }
}

final journalDaoProvider = FutureProvider<JournalDao>((ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return JournalDao(db);
});
