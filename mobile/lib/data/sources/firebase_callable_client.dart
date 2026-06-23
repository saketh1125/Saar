import 'package:cloud_functions/cloud_functions.dart';

import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';

/// Live implementation of all repository interfaces that calls Firebase
/// Cloud Functions (callable v2). Only instantiated when [RepoMode.live] is
/// active and Firebase is configured.
class FirebaseCallableClient {
  FirebaseCallableClient({FirebaseFunctions? functions})
      : _fn = functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseFunctions _fn;

  // ── Generic callable helper ─────────────────────────────────────────────

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    final result = await _fn.httpsCallable(name).call(data);
    return Map<String, dynamic>.from(result.data as Map);
  }

  // ── LiveSituationRepository ─────────────────────────────────────────────

  Future<({String text, String confidence, List<DataSource> sources, List<ToolCall> toolCalls})>
      getLiveSituation({
    required String query,
    required double lat,
    required double lng,
    bool forceLiveRefresh = false,
  }) async {
    final data = await _call('getLiveSituation', {
      'query': query,
      'location': {'lat': lat, 'lng': lng},
      'force_live_refresh': forceLiveRefresh,
    });

    final sources = (data['data_sources'] as List?)
            ?.map((s) => DataSource(
                  source: s['source'] as String? ?? 'unknown',
                  query: s['query'] as String?,
                  url: s['url'] as String?,
                  reliability: (s['reliability'] as num?)?.toDouble() ?? 1.0,
                ))
            .toList() ??
        [];

    final toolCalls = (data['alerts_triggered'] as List?)
            ?.map((t) => ToolCall(
                  name: t['name'] as String? ?? 'unknown',
                  arguments: Map<String, dynamic>.from(t['arguments'] as Map? ?? {}),
                ))
            .toList() ??
        [];

    return (
      text: data['synthesized_response'] as String? ?? '',
      confidence: data['confidence'] as String? ?? 'low',
      sources: sources,
      toolCalls: toolCalls,
    );
  }

  // ── ItineraryRepository ────────────────────────────────────────────────

  Future<Itinerary> generateItinerary({
    required double lat,
    required double lng,
  }) async {
    final data = await _call('generateItinerary', {
      'location': {'lat': lat, 'lng': lng},
      'current_time_iso': DateTime.now().toIso8601String(),
    });

    final steps = (data['itinerary_steps'] as List?)
            ?.map((s) => ItineraryStep.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];

    return Itinerary(
      date: data['date'] as String? ?? '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
      steps: steps,
    );
  }

  // ── PanchangRepository ─────────────────────────────────────────────────

  Future<Panchang> fetchPanchang(DateTime date) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final data = await _call('fetchDailyPanchang', {'date': dateStr});

    final rituals = (data['rituals'] as List?)
            ?.map((r) => PanchangRitual(
                  name: r['name'] as String? ?? '',
                  location: r['location'] as String? ?? '',
                  time: r['time'] as String? ?? '',
                ))
            .toList() ??
        [];

    return Panchang(
      date: data['date'] as String? ?? dateStr,
      tithi: data['tithi'] as String? ?? 'Unknown',
      nakshatra: data['nakshatra'] as String? ?? 'Unknown',
      abhijitMuhurta: data['auspicious_timings']?['abhijit_muhurta'] as String? ?? '',
      rituals: rituals,
      astrologicalWarning: data['astrological_warnings']?['description'] as String?,
    );
  }

  // ── VoiceIntentRepository ──────────────────────────────────────────────

  Future<VoiceIntent> parseVoiceIntent(String transcribedText) async {
    final data = await _call('parseVoiceIntent', {
      'transcribed_text': transcribedText,
      'current_time_iso': DateTime.now().toIso8601String(),
    });

    final toolCalls = (data['tool_calls'] as List?)
            ?.map((t) => ToolCall(
                  name: t['name'] as String? ?? 'unknown',
                  arguments: Map<String, dynamic>.from(t['arguments'] as Map? ?? {}),
                ))
            .toList() ??
        [];

    return VoiceIntent(
      ttsResponse: data['tts_response'] as String? ?? '',
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
      toolCalls: toolCalls,
    );
  }

  // ── CrowdDensityRepository ─────────────────────────────────────────────

  Future<CrowdDensity> getCrowdDensity(String placeId) async {
    final data = await _call('getCrowdDensity', {'place_id': placeId});

    final breakdown = data['breakdown'] as Map<String, dynamic>? ?? {};
    final prediction = data['prediction'] as Map<String, dynamic>? ?? {};

    return CrowdDensity(
      placeId: data['place_id'] as String? ?? placeId,
      crowdStatus: data['crowd_status'] as String? ?? 'unknown',
      indexScore: (data['index_score_0_to_100'] as num?)?.toInt() ?? 0,
      lastUpdated: DateTime.tryParse(data['last_updated_iso'] as String? ?? '') ?? DateTime.now(),
      breakdown: CrowdBreakdown(
        placesLiveOccupancy: (breakdown['places_live_occupancy'] as num?)?.toInt() ?? 0,
        activeAppInstances: (breakdown['active_app_instances_nearby'] as num?)?.toInt() ?? 0,
        recentSocialReports: (breakdown['recent_social_media_reports'] as num?)?.toInt() ?? 0,
      ),
      prediction: CrowdPrediction(
        trend: prediction['trend'] as String? ?? 'stable',
        nextPeak: prediction['next_peak'] as String? ?? '',
        recommendation: prediction['recommendation'] as String? ?? '',
      ),
    );
  }

  // ── FairPriceRepository ────────────────────────────────────────────────

  Future<FairPriceDirectory> fetchFairPrices(String locale) async {
    final data = await _call('getFairPrices', {'locale': locale});

    final rates = (data['rates'] as Map<String, dynamic>?)?.entries.map((e) {
          final v = e.value as Map<String, dynamic>;
          return FairRate(
            key: e.key,
            minInr: (v['min_inr'] as num?)?.toInt() ?? 0,
            maxInr: (v['max_inr'] as num?)?.toInt() ?? 0,
            unit: v['unit'] as String? ?? '',
          );
        }).toList() ??
        [];

    final advisories = (data['scam_shield_advisories'] as List?)
            ?.map((a) => ScamAdvisory(
                  triggerLocationId: a['trigger_location_id'] as String? ?? 'any',
                  warning: a['warning'] as String? ?? '',
                ))
            .toList() ??
        [];

    return FairPriceDirectory(
      lastUpdated: DateTime.tryParse(data['last_updated_iso'] as String? ?? '') ?? DateTime.now(),
      rates: rates,
      advisories: advisories,
    );
  }

  // ── JournalProcessingRepository ────────────────────────────────────────

  Future<({double score, String label, String reflection, List<String> tags})> processJournal({
    required String content,
    double? lat,
    double? lng,
  }) async {
    final data = await _call('processJournalEntry', {
      'entry_id': DateTime.now().millisecondsSinceEpoch.toString(),
      'content': content,
      if (lat != null && lng != null)
        'location': {'lat': lat, 'lng': lng},
      'timestamp_iso': DateTime.now().toIso8601String(),
    });

    return (
      score: (data['sentiment_score'] as num?)?.toDouble() ?? 0.0,
      label: data['sentiment_label'] as String? ?? 'neutral_reflective',
      reflection: data['ai_reflection'] as String? ?? '',
      tags: (data['suggested_tags'] as List?)?.cast<String>() ?? [],
    );
  }
}
