import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralised access to `.env` keys. Call [EnvConfig.init] once at app
/// startup (before any Riverpod provider resolves).
class EnvConfig {
  EnvConfig._();

  // ── Firebase ──────────────────────────────────────────────────────────
  static String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';

  // ── AI / LLM ─────────────────────────────────────────────────────────
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get deepseekApiKey => dotenv.env['DEEPSEEK_API_KEY'] ?? '';
  static String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  // ── Search ────────────────────────────────────────────────────────────
  static String get exaApiKey => dotenv.env['EXA_API_KEY'] ?? '';
  static String get tavilyApiKey => dotenv.env['TAVILY_API_KEY'] ?? '';

  // ── Media ─────────────────────────────────────────────────────────────
  static String get spotifyClientId => dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';

  // ── Maps / Routing ─────────────────────────────────────────────────────
  static String get osmUserAgent => dotenv.env['OSM_USER_AGENT'] ?? 'kashi-nav/0.1';
  static String get orsApiKey => dotenv.env['ORS_API_KEY'] ?? '';

  // ── Helpers ───────────────────────────────────────────────────────────

  /// Whether all critical keys are present (Firebase + at least one LLM).
  static bool get isFullyConfigured =>
      firebaseProjectId.isNotEmpty &&
      firebaseApiKey.isNotEmpty &&
      geminiApiKey.isNotEmpty;

  /// Returns a summary of which keys are set (for debug screen).
  static Map<String, bool> get keyStatus => {
        'FIREBASE_PROJECT_ID': firebaseProjectId.isNotEmpty,
        'FIREBASE_API_KEY': firebaseApiKey.isNotEmpty,
        'GEMINI_API_KEY': geminiApiKey.isNotEmpty,
        'DEEPSEEK_API_KEY': deepseekApiKey.isNotEmpty,
        'GROQ_API_KEY': groqApiKey.isNotEmpty,
        'EXA_API_KEY': exaApiKey.isNotEmpty,
        'TAVILY_API_KEY': tavilyApiKey.isNotEmpty,
        'SPOTIFY_CLIENT_ID': spotifyClientId.isNotEmpty,
        'ORS_API_KEY': orsApiKey.isNotEmpty,
      };
}
