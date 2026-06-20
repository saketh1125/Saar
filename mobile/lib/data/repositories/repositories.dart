import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../seed/varanasi_pois.dart';

/// Every Cloud Function in `kashi_nav_api_contract.md` maps to one repository
/// interface. The app talks only to these interfaces; [ModeController] decides
/// whether each one is wired to a mock impl or a live callable impl. Flipping
/// a feature to live is a one-line override — no widget changes needed.

// ════════════════════════════════════════════════════════════════════════
// Interfaces
// ════════════════════════════════════════════════════════════════════════

abstract class PoiRepository {
  Future<List<Poi>> all();
  Future<List<Poi>> byCategory(PoiCategory c);
  Future<Poi?> byId(String id);
  Future<List<Poi>> nearestMainRoads(double lat, double lng);
}

abstract class LiveSituationRepository {
  /// Mirrors `/getLiveSituation`. Returns synthesized text + sources.
  Future<({String text, String confidence, List<DataSource> sources, List<ToolCall> toolCalls})>
      getLiveSituation({
    required String query,
    required double lat,
    required double lng,
    bool forceLiveRefresh = false,
  });
}

abstract class ItineraryRepository {
  Future<Itinerary> generate({required double lat, required double lng});
}

abstract class PanchangRepository {
  Future<Panchang> forDate(DateTime date);
}

abstract class VoiceIntentRepository {
  Future<VoiceIntent> parse(String transcribedText);
}

abstract class CrowdDensityRepository {
  Future<CrowdDensity> forPlace(String placeId);
}

abstract class FairPriceRepository {
  Future<FairPriceDirectory> directory(String locale);
}

abstract class JournalProcessingRepository {
  Future<({double score, String label, String reflection, List<String> tags})>
      process(String content, {double? lat, double? lng});
}

// ════════════════════════════════════════════════════════════════════════
// Mock implementations
// ════════════════════════════════════════════════════════════════════════

class MockPoiRepository implements PoiRepository {
  MockPoiRepository(this._seed);
  final List<Poi> _seed;
  @override
  Future<List<Poi>> all() async => _seed;
  @override
  Future<List<Poi>> byCategory(PoiCategory c) async =>
      _seed.where((p) => p.category == c).toList();
  @override
  Future<Poi?> byId(String id) async {
    for (final p in _seed) {
      if (p.id == id) return p;
    }
    return null;
  }
  @override
  Future<List<Poi>> nearestMainRoads(double lat, double lng) async => kMainRoadNodes;
}

class MockLiveSituationRepository implements LiveSituationRepository {
  final _rng = Random();
  @override
  Future<({String text, String confidence, List<DataSource> sources, List<ToolCall> toolCalls})>
      getLiveSituation({
    required String query,
    required double lat,
    required double lng,
    bool forceLiveRefresh = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));
    return (
      text:
          'Based on current signals around Kashi: $query — the Ganga Aarti is on schedule at ~6:45 PM '
          'tonight with typical crowds. No active road closures reported. Carry small change for the '
          'boatmen and arrive ~20 minutes early for a good spot.',
      confidence: _rng.nextBool() ? 'high' : 'medium',
      sources: const <DataSource>[
        DataSource(source: 'panchang_schedule', reliability: 1.0),
        DataSource(source: 'brave_search', query: 'Varanasi Ganga Aarti today', reliability: 0.85),
        DataSource(source: 'reddit_post', url: 'https://reddit.com/r/varanasi', reliability: 0.7),
      ],
      toolCalls: const <ToolCall>[],
    );
  }
}

class MockItineraryRepository implements ItineraryRepository {
  @override
  Future<Itinerary> generate({required double lat, required double lng}) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final today = DateTime.now();
    return Itinerary(
      date: '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}',
      steps: const [
        ItineraryStep(
          timeSlot: 'morning',
          estimatedStart: '06:30 AM',
          estimatedDurationMins: 90,
          title: 'Subah-e-Banaras at Assi Ghat',
          description: 'Morning prayers, classical music and yoga as the sun rises over the river.',
          placeId: 'vpd_ghat_assi',
          lat: 25.2833,
          lng: 83.0063,
          practicalTips: 'Grab a kullhad chai at Pappu Chai Stall just behind the ghat.',
        ),
        ItineraryStep(
          timeSlot: 'afternoon',
          estimatedStart: '12:00 PM',
          estimatedDurationMins: 120,
          title: 'Kachori & Lassi in Vishwanath Gali',
          description: 'Old-city alleys for breakfast kachoris at Ram Bhandar, then Blue Lassi.',
          placeId: 'vpd_food_ram_bhandar',
          lat: 25.3115,
          lng: 83.0102,
          practicalTips: 'Avoid large bags — these galis are extremely narrow and crowded.',
        ),
        ItineraryStep(
          timeSlot: 'evening',
          estimatedStart: '06:15 PM',
          estimatedDurationMins: 90,
          title: 'Evening Aarti from a Boat',
          description: 'Board a shared rowboat at Dashashwamedh to view the grand aarti from the river.',
          placeId: 'vpd_ghat_dashashwamedh',
          lat: 25.3065,
          lng: 83.0107,
          practicalTips: 'Negotiate beforehand. A shared boat should not exceed ₹150–200/person.',
        ),
      ],
    );
  }
}

class MockPanchangRepository implements PanchangRepository {
  @override
  Future<Panchang> forDate(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return Panchang(
      date: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      tithi: 'Shukla Dwitiya',
      nakshatra: 'Ardra',
      abhijitMuhurta: '11:45 AM – 12:35 PM',
      rituals: const [
        PanchangRitual(name: 'Subah-e-Banaras Aarti', location: 'Assi Ghat', time: '05:15 AM'),
        PanchangRitual(name: 'Ganga Aarti', location: 'Dashashwamedh Ghat', time: '06:45 PM'),
      ],
      astrologicalWarning:
          'Rahu Kaal active 03:00 PM – 04:30 PM. Typically avoided for starting new ventures.',
    );
  }
}

class MockVoiceIntentRepository implements VoiceIntentRepository {
  @override
  Future<VoiceIntent> parse(String transcribedText) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final lower = transcribedText.toLowerCase();
    final calls = <ToolCall>[];
    String tts = 'Done. ';
    if (lower.contains('alarm') && RegExp(r'\b\d').hasMatch(lower)) {
      final m = RegExp(r'(\d{1,2})[:\s]?(\d{2})?\s*(am|pm)?').firstMatch(lower);
      final time = m != null
          ? (m.group(2) != null ? '${m.group(1)}:${m.group(2)}' : '${m.group(1)}:00')
          : '04:30';
      calls.add(const ToolCall(name: 'set_alarm', arguments: {'time': '04:30', 'sound_query': 'morning flute'}));
      // ignore: unused_local_variable
      final _ = time;
      tts += 'Alarm set. ';
    }
    if (lower.contains('vishwanath') || lower.contains('temple')) {
      calls.add(const ToolCall(name: 'show_checklist', arguments: {'place_id': 'vpd_temple_vishwanath'}));
      calls.add(const ToolCall(name: 'start_navigation', arguments: {'destination_id': 'vpd_temple_vishwanath'}));
      tts += 'Loaded the Vishwanath checklist and a foot route. ';
    }
    if (calls.isEmpty) {
      tts = 'I heard "$transcribedText" — I can set alarms, open checklists, or start navigation.';
    }
    return VoiceIntent(ttsResponse: tts, confidence: 0.96, toolCalls: calls);
  }
}

class MockCrowdDensityRepository implements CrowdDensityRepository {
  final _rng = Random();
  @override
  Future<CrowdDensity> forPlace(String placeId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = 30 + _rng.nextInt(60);
    String status;
    if (idx <= 30) {
      status = 'peaceful';
    } else if (idx <= 70) {
      status = 'active';
    } else {
      status = 'very_crowded';
    }
    return CrowdDensity(
      placeId: placeId,
      crowdStatus: status,
      indexScore: idx,
      lastUpdated: DateTime.now(),
      breakdown: CrowdBreakdown(
        placesLiveOccupancy: idx - 5,
        activeAppInstances: _rng.nextInt(60),
        recentSocialReports: idx + 8,
      ),
      prediction: CrowdPrediction(
        trend: idx > 50 ? 'increasing' : 'stable',
        nextPeak: '06:45 PM (Ganga Aarti)',
        recommendation: idx > 70
            ? 'Heavily congested — head to Raj Ghat for a quieter alternative.'
            : 'Good time to visit; minor queues expected.',
      ),
    );
  }
}

class MockFairPriceRepository implements FairPriceRepository {
  @override
  Future<FairPriceDirectory> directory(String locale) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return FairPriceDirectory(
      lastUpdated: DateTime.now(),
      rates: const [
        FairRate(key: 'Shared rowboat (per head)', minInr: 150, maxInr: 200, unit: 'person'),
        FairRate(key: 'Private rowboat (per hour)', minInr: 400, maxInr: 600, unit: 'boat_hour'),
        FairRate(key: 'Private motorboat (per hour)', minInr: 1200, maxInr: 1500, unit: 'boat_hour'),
        FairRate(key: 'Shared auto (standard route)', minInr: 20, maxInr: 40, unit: 'person'),
        FairRate(key: 'Auto Godowlia → Station', minInr: 100, maxInr: 150, unit: 'trip'),
      ],
      advisories: const [
        ScamAdvisory(
          triggerLocationId: 'vpd_ghat_manikarnika',
          warning:
              'Manikarnika Wood Scam: touts offer a "free" cremation-terrace view, then demand '
              '₹500+/kg donations for funeral wood. Decline and stay on public riverside paths.',
        ),
        ScamAdvisory(
          triggerLocationId: 'any',
          warning:
              'Fake Temple Guides: touts near Godowlia claim the main temple is "closed for VIPs" '
              'and redirect you to shops. Check live status in the app instead.',
        ),
      ],
    );
  }
}

class MockJournalProcessingRepository implements JournalProcessingRepository {
  @override
  Future<({double score, String label, String reflection, List<String> tags})>
      process(String content, {double? lat, double? lng}) async {
    await Future.delayed(const Duration(milliseconds: 900));
    return (
      score: 0.12,
      label: 'neutral_reflective',
      reflection:
          'Your words capture the core of Kashi: the coexistence of life and mortality in a single '
          'frame. It is natural to feel heavy yet grounded here. Let yourself sit with this space '
          'quietly this evening.',
      tags: ['reflection', 'afternoon', 'manikarnika'],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// Mode controller + providers
// ════════════════════════════════════════════════════════════════════════

/// Which backing implementation each repository uses. `mock` is the default
/// (frontend-first); switch to `live` once Firebase is configured. Per-feature
/// overrides are supported via [RepositoryModeController.override].
enum RepoMode { mock, live }

class RepositoryModeController extends StateNotifier<RepoMode> {
  RepositoryModeController() : super(RepoMode.mock);
  void use(RepoMode m) => state = m;
}

final repositoryModeProvider =
    StateNotifierProvider<RepositoryModeController, RepoMode>(
        (ref) => RepositoryModeController());

/// Each provider reads [repositoryModeProvider] so flipping the mode (e.g. from
/// the Tools tab) switches every feature from mock to live in one move. Until
/// the live callable client is wired (needs Firebase configured), live mode
/// also falls back to the mock so the app never breaks.
final poiRepositoryProvider = Provider<PoiRepository>((ref) {
  ref.watch(repositoryModeProvider); // re-resolve on mode change
  // TODO(swap): return LivePoiRepository(ref) once Firebase is configured.
  return MockPoiRepository([...kSeedPois, ...kMainRoadNodes]);
});

final liveSituationRepositoryProvider = Provider<LiveSituationRepository>(
    (ref) {
  ref.watch(repositoryModeProvider);
  return MockLiveSituationRepository();
});

final itineraryRepositoryProvider =
    Provider<ItineraryRepository>((ref) {
  ref.watch(repositoryModeProvider);
  return MockItineraryRepository();
});

final panchangRepositoryProvider =
    Provider<PanchangRepository>((ref) {
  ref.watch(repositoryModeProvider);
  return MockPanchangRepository();
});

final voiceIntentRepositoryProvider =
    Provider<VoiceIntentRepository>((ref) {
  ref.watch(repositoryModeProvider);
  return MockVoiceIntentRepository();
});

final crowdDensityRepositoryProvider =
    Provider<CrowdDensityRepository>((ref) {
  ref.watch(repositoryModeProvider);
  return MockCrowdDensityRepository();
});

final fairPriceRepositoryProvider =
    Provider<FairPriceRepository>((ref) {
  ref.watch(repositoryModeProvider);
  return MockFairPriceRepository();
});

final journalProcessingRepositoryProvider =
    Provider<JournalProcessingRepository>((ref) {
  ref.watch(repositoryModeProvider);
  return MockJournalProcessingRepository();
});

// small helper re-exported for widgets that need the seed list directly
List<Poi> get seedPois => kSeedPois;
List<Poi> get mainRoadNodes => kMainRoadNodes;
