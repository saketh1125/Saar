import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/config/env_config.dart';

/// A single step in a pedestrian route.
class RouteStep {
  final List<LatLng> points;
  final double distanceMeters;
  final int durationSeconds;
  final String? instruction;
  final String? streetName;

  const RouteStep({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.instruction,
    this.streetName,
  });
}

/// A complete pedestrian route between two points.
class PedestrianRoute {
  final LatLng start;
  final LatLng end;
  final List<RouteStep> steps;
  final double totalDistanceMeters;
  final int totalDurationSeconds;
  final List<LatLng> polyline;

  const PedestrianRoute({
    required this.start,
    required this.end,
    required this.steps,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
    required this.polyline,
  });

  String get distanceText {
    if (totalDistanceMeters < 1000) {
      return '${totalDistanceMeters.round()} m';
    }
    return '${(totalDistanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String get durationText {
    final mins = (totalDurationSeconds / 60).round();
    if (mins < 60) return '$mins min';
    final hours = mins ~/ 60;
    final remainMins = mins % 60;
    return '${hours}h ${remainMins}m';
  }
}

/// Client for OpenRouteService pedestrian routing API.
/// Uses the free tier (2000 requests/day, 50km total).
class OpenRouteServiceClient {
  OpenRouteServiceClient({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Fetch a pedestrian route between two points.
  Future<PedestrianRoute?> getPedestrianRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    final apiKey = EnvConfig.orsApiKey;
    if (apiKey.isEmpty) {
      throw StateError('ORS_API_KEY not configured');
    }

    try {
      final response = await _dio.post(
        'https://api.openrouteservice.org/v2/directions/foot-walking/geojson',
        data: {
          'coordinates': [
            [start.longitude, start.latitude],
            [end.longitude, end.latitude],
          ],
          'instructions': true,
          'geometry': true,
          'geometry_simplify': true,
        },
        options: Options(
          headers: {
            'Authorization': apiKey,
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      final geojson = response.data;
      if (geojson == null) return null;

      return _parseRoute(start, end, geojson);
    } on DioException {
      return null;
    }
  }

  PedestrianRoute? _parseRoute(LatLng start, LatLng end, Map<String, dynamic> geojson) {
    final features = geojson['features'] as List?;
    if (features == null || features.isEmpty) return null;

    final feature = features[0] as Map<String, dynamic>;
    final properties = feature['properties'] as Map<String, dynamic>?;
    final geometry = feature['geometry'] as Map<String, dynamic>?;

    if (geometry == null) return null;

    // Parse polyline coordinates
    final coords = geometry['coordinates'] as List?;
    if (coords == null || coords.isEmpty) return null;

    final polyline = coords.map<LatLng>((c) {
      final list = c as List;
      return LatLng(list[1] as double, list[0] as double);
    }).toList();

    // Parse segments/steps
    final segments = properties?['segments'] as List?;
    final steps = <RouteStep>[];

    double totalDist = 0;
    int totalDur = 0;

    if (segments != null && segments.isNotEmpty) {
      final segment = segments[0] as Map<String, dynamic>;
      totalDist = (segment['distance'] as num?)?.toDouble() ?? 0;
      totalDur = (segment['duration'] as num?)?.toInt() ?? 0;

      final segSteps = segment['steps'] as List?;
      if (segSteps != null) {
        for (final step in segSteps) {
          final s = step as Map<String, dynamic>;
          final sCoords = s['way_points'] as List?;
          final startIdx = sCoords != null && sCoords.isNotEmpty ? sCoords[0] as int : 0;
          final endIdx = sCoords != null && sCoords.length > 1 ? sCoords[1] as int : polyline.length - 1;

          final stepPoints = polyline.sublist(
            startIdx.clamp(0, polyline.length),
            (endIdx + 1).clamp(0, polyline.length),
          );

          steps.add(RouteStep(
            points: stepPoints,
            distanceMeters: (s['distance'] as num?)?.toDouble() ?? 0,
            durationSeconds: (s['duration'] as num?)?.toInt() ?? 0,
            instruction: s['instruction'] as String?,
            streetName: s['name'] as String?,
          ));
        }
      }
    }

    return PedestrianRoute(
      start: start,
      end: end,
      steps: steps,
      totalDistanceMeters: totalDist,
      totalDurationSeconds: totalDur,
      polyline: polyline,
    );
  }
}

/// Riverpod provider for the ORS client.
final orsClientProvider = Provider<OpenRouteServiceClient>((ref) {
  return OpenRouteServiceClient();
});
