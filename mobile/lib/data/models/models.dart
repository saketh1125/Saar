import 'package:latlong2/latlong.dart' show LatLng;

/// A Point of Interest on the Kashi map: temple, ghat, food spot, water/toilet
/// node, etc. Mirrors the VPD schema in `kashi_nav_master_plan.md` §5.
class Poi {
  final String id;
  final String name;
  final PoiCategory category;
  final double lat;
  final double lng;
  final String? accessibility; // High / Medium / Low step difficulty for ghats
  final String? summary;
  final List<String> aliases;
  final List<String> sources;
  final double confidence;

  const Poi({
    required this.id,
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
    this.accessibility,
    this.summary,
    this.aliases = const [],
    this.sources = const [],
    this.confidence = 1.0,
  });

  LatLng get location => LatLng(lat, lng);

  factory Poi.fromJson(Map<String, dynamic> j) => Poi(
        id: j['id'] as String,
        name: j['name'] as String,
        category: PoiCategory.values.byName(j['category'] as String),
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        accessibility: j['accessibility'] as String?,
        summary: j['summary'] as String?,
        aliases: (j['aliases'] as List?)?.cast<String>() ?? const [],
        sources: (j['sources'] as List?)?.cast<String>() ?? const [],
        confidence: (j['confidence'] as num?)?.toDouble() ?? 1.0,
      );

  Map<String, dynamic> toRow() => {
        'id': id,
        'name': name,
        'category': category.name,
        'latitude': lat,
        'longitude': lng,
        'accessibility': accessibility,
        'summary': summary,
        'aliases': aliases.join('|'),
        'sources': sources.join('|'),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      };

  factory Poi.fromRow(Map<String, dynamic> r) => Poi(
        id: r['id'] as String,
        name: r['name'] as String,
        category: PoiCategory.values.byName(r['category'] as String),
        lat: (r['latitude'] as num).toDouble(),
        lng: (r['longitude'] as num).toDouble(),
        accessibility: r['accessibility'] as String?,
        summary: r['summary'] as String?,
        aliases: (r['aliases'] as String?)?.split('|').where((s) => s.isNotEmpty).toList() ?? const [],
        sources: (r['sources'] as String?)?.split('|').where((s) => s.isNotEmpty).toList() ?? const [],
      );
}

enum PoiCategory { temple, ghat, food, water, toilet, safety, view, market }

/// One step of a generated itinerary, part of `/generateItinerary`.
class ItineraryStep {
  final String timeSlot; // morning | afternoon | evening
  final String estimatedStart;
  final int estimatedDurationMins;
  final String title;
  final String description;
  final String? placeId;
  final double? lat;
  final double? lng;
  final String practicalTips;

  const ItineraryStep({
    required this.timeSlot,
    required this.estimatedStart,
    required this.estimatedDurationMins,
    required this.title,
    required this.description,
    this.placeId,
    this.lat,
    this.lng,
    required this.practicalTips,
  });

  factory ItineraryStep.fromJson(Map<String, dynamic> j) => ItineraryStep(
        timeSlot: j['time_slot'] as String,
        estimatedStart: j['estimated_start'] as String,
        estimatedDurationMins: j['estimated_duration_mins'] as int,
        title: j['title'] as String,
        description: j['description'] as String,
        placeId: j['place_id'] as String?,
        lat: (j['coordinates']?['lat'] as num?)?.toDouble(),
        lng: (j['coordinates']?['lng'] as num?)?.toDouble(),
        practicalTips: j['practical_tips'] as String? ?? '',
      );
}

class Itinerary {
  final String date;
  final List<ItineraryStep> steps;
  const Itinerary({required this.date, required this.steps});
}

/// Panchang / ritual calendar, from `/fetchDailyPanchang`.
class Panchang {
  final String date;
  final String tithi;
  final String nakshatra;
  final String abhijitMuhurta;
  final List<PanchangRitual> rituals;
  final String? astrologicalWarning;

  const Panchang({
    required this.date,
    required this.tithi,
    required this.nakshatra,
    required this.abhijitMuhurta,
    required this.rituals,
    this.astrologicalWarning,
  });
}

class PanchangRitual {
  final String name;
  final String location;
  final String time;
  const PanchangRitual({required this.name, required this.location, required this.time});
}

/// Crowd density at a POI, from `/getCrowdDensity`.
class CrowdDensity {
  final String placeId;
  final String crowdStatus; // peaceful | active | very_crowded
  final int indexScore; // 0..100
  final DateTime lastUpdated;
  final CrowdBreakdown breakdown;
  final CrowdPrediction? prediction;

  const CrowdDensity({
    required this.placeId,
    required this.crowdStatus,
    required this.indexScore,
    required this.lastUpdated,
    required this.breakdown,
    this.prediction,
  });
}

class CrowdBreakdown {
  final int placesLiveOccupancy;
  final int activeAppInstances;
  final int recentSocialReports;
  const CrowdBreakdown({
    required this.placesLiveOccupancy,
    required this.activeAppInstances,
    required this.recentSocialReports,
  });
}

class CrowdPrediction {
  final String trend; // increasing | stable | decreasing
  final String nextPeak;
  final String recommendation;
  const CrowdPrediction({
    required this.trend,
    required this.nextPeak,
    required this.recommendation,
  });
}

/// Fair-price directory + scam advisories, from `/getFairPrices`.
class FairPriceDirectory {
  final DateTime lastUpdated;
  final List<FairRate> rates;
  final List<ScamAdvisory> advisories;
  const FairPriceDirectory({
    required this.lastUpdated,
    required this.rates,
    required this.advisories,
  });
}

class FairRate {
  final String key;
  final int minInr;
  final int maxInr;
  final String unit;
  const FairRate({required this.key, required this.minInr, required this.maxInr, required this.unit});
}

class ScamAdvisory {
  final String triggerLocationId;
  final String warning;
  const ScamAdvisory({required this.triggerLocationId, required this.warning});
}

/// A chat message in the AI Brain. User messages use a terracotta gradient;
/// AI messages use deep slate with a saffron outline (design spec §3.2).
class ChatMessage {
  final String id;
  final String text;
  final bool fromUser;
  final DateTime? timestamp;
  final String confidence; // high | medium | low | ''
  final List<DataSource> sources;
  final List<ToolCall> toolCalls;
  final bool isOfflineAnswer;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.fromUser,
    this.timestamp,
    this.confidence = '',
    this.sources = const [],
    this.toolCalls = const [],
    this.isOfflineAnswer = false,
  });

  ChatMessage copyWith({
    String? text,
    String? confidence,
    List<DataSource>? sources,
    List<ToolCall>? toolCalls,
    bool? isOfflineAnswer,
  }) =>
      ChatMessage(
        id: id,
        text: text ?? this.text,
        fromUser: fromUser,
        timestamp: timestamp,
        confidence: confidence ?? this.confidence,
        sources: sources ?? this.sources,
        toolCalls: toolCalls ?? this.toolCalls,
        isOfflineAnswer: isOfflineAnswer ?? this.isOfflineAnswer,
      );
}

class DataSource {
  final String source;
  final String? query;
  final String? url;
  final double reliability;
  final DateTime? timestamp;
  const DataSource({
    required this.source,
    this.query,
    this.url,
    this.reliability = 1.0,
    this.timestamp,
  });
}

/// An agentic tool call the Brain emits to control the app
/// (`set_alarm`, `play_music`, `start_navigation`, `show_checklist`,
/// `add_journal_entry`, `toggle_tab`, `view_places`).
class ToolCall {
  final String name;
  final Map<String, dynamic> arguments;
  const ToolCall({required this.name, this.arguments = const {}});

  String describe() {
    switch (name) {
      case 'set_alarm':
        return '🔔 Alarm ${arguments['time']} ${arguments['sound_query'] != null ? '· ${arguments['sound_query']}' : ''}';
      case 'play_music':
        return '🎵 Play ${arguments['sound_query'] ?? arguments['provider'] ?? ''}';
      case 'start_navigation':
        return '🧭 Navigate → ${arguments['destination_id'] ?? ''}';
      case 'show_checklist':
        return '📋 Checklist ${arguments['place_id'] ?? ''}';
      case 'add_journal_entry':
        return '✍️ Journal entry';
      case 'toggle_tab':
        return '🧭 Open ${arguments['tab'] ?? ''} tab';
      case 'view_places':
        return '📍 View ${arguments['category'] ?? 'places'}';
      default:
        return '⚙️ $name';
    }
  }
}

/// A parsed voice intent, from `/parseVoiceIntent`.
class VoiceIntent {
  final String ttsResponse;
  final double confidence;
  final List<ToolCall> toolCalls;
  const VoiceIntent({required this.ttsResponse, required this.confidence, required this.toolCalls});
}
