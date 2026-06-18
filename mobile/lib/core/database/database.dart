import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Opens the local SQLite database and runs migrations. The database is the
/// local-first source of truth for journals, checklist state, cached POIs and
/// cached fair-price data. Per the handoff doc §4.3, all writes go here first
/// and sync to Firestore as a background best-effort operation.
class AppDatabase {
  AppDatabase(this._db);
  final Database _db;

  static Future<AppDatabase> create() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'kashi_nav.db');
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return AppDatabase(db);
  }

  static Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    // Journal entries (local-first; reflection fields filled by
    // /processJournalEntry).
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

    // Checklist items, keyed by a context id (e.g. a place_id or 'packing').
    batch.execute('''
      CREATE TABLE checklist_items (
        id TEXT PRIMARY KEY,
        context_id TEXT NOT NULL,
        title TEXT NOT NULL,
        detail TEXT,
        done INTEGER NOT NULL DEFAULT 0,
        ord INTEGER NOT NULL DEFAULT 0
      )
    ''');
    batch.execute(
      'CREATE INDEX idx_checklist_context ON checklist_items(context_id)',
    );

    // Media provider link state (Spotify / Apple / JioSaavn).
    batch.execute('''
      CREATE TABLE media_providers (
        id TEXT PRIMARY KEY,
        connected INTEGER NOT NULL DEFAULT 0,
        account TEXT
      )
    ''');

    // Cached POIs (seeded from bundled Overpass export, refreshed live).
    batch.execute('''
      CREATE TABLE pois (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accessibility TEXT,
        summary TEXT,
        aliases TEXT,
        sources TEXT,
        updated_at INTEGER NOT NULL
      )
    ''');
    batch.execute('CREATE INDEX idx_pois_category ON pois(category)');

    // Cached fair-price directory + scam advisories.
    batch.execute('''
      CREATE TABLE fair_prices (
        key TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await batch.commit(noResult: true);
  }

  static Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    // Future migrations branch on (oldV, newV) here.
  }

  Database get raw => _db;

  Future<void> close() async {
    await _db.close();
  }
}

/// Provides a single shared [AppDatabase] for the app lifetime.
final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  final db = await AppDatabase.create();
  ref.onDispose(db.close);
  return db;
});
