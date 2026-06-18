import 'package:uuid/uuid.dart';

/// A reflection journal entry. Local-first: every entry lives in SQLite
/// (`sqflite`) and the AI reflection fields are filled asynchronously by the
/// `/processJournalEntry` Cloud Function (handoff §4.3, PRD §3.2.2).
class JournalEntry {
  final String id;
  final String content;
  final String mood; // emoji key, see MoodPicker
  final double? lat;
  final double? lng;
  final DateTime createdAt;

  final double? sentimentScore; // -1..1
  final String? sentimentLabel; // e.g. neutral_reflective
  final String? aiReflection;
  final List<String> tags;

  const JournalEntry({
    required this.id,
    required this.content,
    required this.mood,
    this.lat,
    this.lng,
    required this.createdAt,
    this.sentimentScore,
    this.sentimentLabel,
    this.aiReflection,
    this.tags = const [],
  });

  factory JournalEntry.create({
    required String content,
    required String mood,
    double? lat,
    double? lng,
  }) {
    return JournalEntry(
      id: const Uuid().v4(),
      content: content,
      mood: mood,
      lat: lat,
      lng: lng,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toRow() => {
        'id': id,
        'content': content,
        'mood': mood,
        'latitude': lat,
        'longitude': lng,
        'created_at': createdAt.millisecondsSinceEpoch,
        'sentiment_score': sentimentScore,
        'sentiment_label': sentimentLabel,
        'ai_reflection': aiReflection,
        'tags': tags.join('|'),
      };

  factory JournalEntry.fromRow(Map<String, dynamic> r) => JournalEntry(
        id: r['id'] as String,
        content: r['content'] as String,
        mood: r['mood'] as String,
        lat: (r['latitude'] as num?)?.toDouble(),
        lng: (r['longitude'] as num?)?.toDouble(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
        sentimentScore: (r['sentiment_score'] as num?)?.toDouble(),
        sentimentLabel: r['sentiment_label'] as String?,
        aiReflection: r['ai_reflection'] as String?,
        tags: (r['tags'] as String?)?.split('|').where((s) => s.isNotEmpty).toList() ?? const [],
      );
}

/// Mood options for the journal picker (PRD §3.2.2 + design warm accents).
class Mood {
  final String key;
  final String emoji;
  final String label;
  const Mood(this.key, this.emoji, this.label);

  static const list = <Mood>[
    Mood('blissful', '🪔', 'Blissful'),
    Mood('peaceful', '🕉️', 'Peaceful'),
    Mood('curious', '🌌', 'Curious'),
    Mood('reflective', '🌙', 'Reflective'),
    Mood('heavy', '🌫️', 'Heavy'),
    Mood('overwhelmed', '🌊', 'Overwhelmed'),
  ];
}
