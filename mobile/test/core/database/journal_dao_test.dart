import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kashi_nav/core/database/database.dart';
import 'package:kashi_nav/core/database/journal_dao.dart';

void main() {
  late AppDatabase db;
  late JournalDao dao;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Create an in-memory database for testing
    final database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          final batch = db.batch();
          batch.execute('''
            CREATE TABLE journal_entries (
              id TEXT PRIMARY KEY,
              content TEXT NOT NULL,
              mood TEXT NOT NULL,
              latitude REAL,
              longitude REAL,
              created_at INTEGER NOT NULL,
              sentiment_score REAL,
              sentiment_label TEXT,
              ai_reflection TEXT,
              tags TEXT
            )
          ''');
          batch.execute(
            'CREATE INDEX idx_journal_created ON journal_entries(created_at DESC)',
          );
          await batch.commit(noResult: true);
        },
      ),
    );
    db = AppDatabase(database);
    dao = JournalDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('JournalDao', () {
    test('insert() creates entry and all() retrieves it', () async {
      final entry = await dao.insert(
        content: 'Test journal entry',
        mood: 'peaceful',
        lat: 25.3176,
        lng: 83.0130,
      );

      expect(entry.id, isNotEmpty);
      expect(entry.content, 'Test journal entry');
      expect(entry.mood, 'peaceful');
      expect(entry.lat, 25.3176);
      expect(entry.lng, 83.0130);

      final all = await dao.all();
      expect(all, hasLength(1));
      expect(all.first.id, entry.id);
    });

    test('insert() without coordinates works', () async {
      final entry = await dao.insert(
        content: 'No location entry',
        mood: 'curious',
      );

      expect(entry.lat, isNull);
      expect(entry.lng, isNull);

      final retrieved = await dao.all();
      expect(retrieved.first.lat, isNull);
      expect(retrieved.first.lng, isNull);
    });

    test('all() returns entries ordered by created_at DESC', () async {
      await dao.insert(content: 'First', mood: 'blissful');
      await Future.delayed(const Duration(milliseconds: 10));
      await dao.insert(content: 'Second', mood: 'peaceful');

      final all = await dao.all();
      expect(all, hasLength(2));
      expect(all.first.content, 'Second');
      expect(all.last.content, 'First');
    });

    test('applyReflection() updates sentiment and reflection fields', () async {
      final entry = await dao.insert(
        content: 'Reflect on this',
        mood: 'reflective',
      );

      await dao.applyReflection(
        entry.id,
        score: 0.75,
        label: 'positive',
        reflection: 'A thoughtful reflection.',
        tags: ['reflection', 'mindfulness'],
      );

      final all = await dao.all();
      final updated = all.first;
      expect(updated.sentimentScore, 0.75);
      expect(updated.sentimentLabel, 'positive');
      expect(updated.aiReflection, 'A thoughtful reflection.');
      expect(updated.tags, ['reflection', 'mindfulness']);
    });

    test('delete() removes entry', () async {
      final entry = await dao.insert(
        content: 'To be deleted',
        mood: 'heavy',
      );

      var all = await dao.all();
      expect(all, hasLength(1));

      await dao.delete(entry.id);

      all = await dao.all();
      expect(all, isEmpty);
    });

    test('delete() with non-existent id does not throw', () async {
      await dao.insert(content: 'Keep me', mood: 'peaceful');

      // Should not throw
      await dao.delete('nonexistent_id');

      final all = await dao.all();
      expect(all, hasLength(1));
    });

    test('multiple entries can be inserted and retrieved', () async {
      await dao.insert(content: 'Entry 1', mood: 'blissful');
      await dao.insert(content: 'Entry 2', mood: 'curious');
      await dao.insert(content: 'Entry 3', mood: 'overwhelmed');

      final all = await dao.all();
      expect(all, hasLength(3));
    });

    test('applyReflection() with empty tags works', () async {
      final entry = await dao.insert(
        content: 'Empty tags test',
        mood: 'peaceful',
      );

      await dao.applyReflection(
        entry.id,
        score: 0.0,
        label: 'neutral',
        reflection: 'Neutral reflection.',
        tags: [],
      );

      final all = await dao.all();
      expect(all.first.tags, isEmpty);
    });
  });
}
