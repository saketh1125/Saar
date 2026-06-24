import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';

/// Represents a geofence zone around a POI.
class GeofenceZone {
  final String placeId;
  final String placeName;
  final LatLng center;
  final double radiusMeters;
  final bool triggered;

  const GeofenceZone({
    required this.placeId,
    required this.placeName,
    required this.center,
    required this.radiusMeters,
    this.triggered = false,
  });

  GeofenceZone copyWith({bool? triggered}) => GeofenceZone(
        placeId: placeId,
        placeName: placeName,
        center: center,
        radiusMeters: radiusMeters,
        triggered: triggered ?? this.triggered,
      );
}

/// Result of a geofence check.
class GeofenceEvent {
  final String placeId;
  final String placeName;
  final double distanceMeters;

  const GeofenceEvent({
    required this.placeId,
    required this.placeName,
    required this.distanceMeters,
  });
}

/// Service that monitors the user's location and triggers checklists
/// when they approach a POI (within configurable radius).
class GeofenceService {
  GeofenceService({required this.poiRepository});

  final PoiRepository poiRepository;
  StreamSubscription<Position>? _positionSubscription;
  final _controller = StreamController<GeofenceEvent>.broadcast();
  final Map<String, GeofenceZone> _zones = {};
  bool _active = false;

  /// Stream of geofence events (user entered a zone).
  Stream<GeofenceEvent> get onEnter => _controller.stream;

  bool get isActive => _active;

  /// Initialize geofences from POI data.
  Future<void> init() async {
    final pois = await poiRepository.all();
    _zones.clear();
    for (final poi in pois) {
      _zones[poi.id] = GeofenceZone(
        placeId: poi.id,
        placeName: poi.name,
        center: poi.location,
        radiusMeters: _radiusForCategory(poi.category),
      );
    }
  }

  /// Start monitoring location.
  Future<void> start() async {
    if (_active) return;

    // Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
    }

    _active = true;

    // Listen to position updates (every 10 seconds, 50m distance filter)
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
        distanceFilter: 50,
      ),
    ).listen(_onPositionUpdate);
  }

  /// Stop monitoring.
  void stop() {
    _active = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Check if user is near any POI and return nearby ones.
  Future<List<GeofenceEvent>> checkProximity(LatLng userLocation) async {
    final events = <GeofenceEvent>[];

    for (final zone in _zones.values) {
      final distance = Geolocator.distanceBetween(
        userLocation.latitude,
        userLocation.longitude,
        zone.center.latitude,
        zone.center.longitude,
      );

      if (distance <= zone.radiusMeters && !zone.triggered) {
        _zones[zone.placeId] = zone.copyWith(triggered: true);
        events.add(GeofenceEvent(
          placeId: zone.placeId,
          placeName: zone.placeName,
          distanceMeters: distance,
        ));
      } else if (distance > zone.radiusMeters * 1.5) {
        // Reset trigger when user moves away
        _zones[zone.placeId] = zone.copyWith(triggered: false);
      }
    }

    return events;
  }

  void _onPositionUpdate(Position position) {
    final userLocation = LatLng(position.latitude, position.longitude);

    for (final zone in _zones.values) {
      final distance = Geolocator.distanceBetween(
        userLocation.latitude,
        userLocation.longitude,
        zone.center.latitude,
        zone.center.longitude,
      );

      if (distance <= zone.radiusMeters && !zone.triggered) {
        _zones[zone.placeId] = zone.copyWith(triggered: true);
        _controller.add(GeofenceEvent(
          placeId: zone.placeId,
          placeName: zone.placeName,
          distanceMeters: distance,
        ));
      } else if (distance > zone.radiusMeters * 1.5) {
        _zones[zone.placeId] = zone.copyWith(triggered: false);
      }
    }
  }

  /// Radius in meters based on POI category.
  double _radiusForCategory(PoiCategory category) {
    switch (category) {
      case PoiCategory.temple:
        return 100; // Approach from 100m
      case PoiCategory.ghat:
        return 150; // Ghats are larger
      case PoiCategory.food:
        return 50; // Food spots are smaller
      case PoiCategory.water:
      case PoiCategory.toilet:
        return 75;
      case PoiCategory.safety:
        return 100;
      case PoiCategory.view:
        return 120;
      case PoiCategory.market:
        return 80;
    }
  }

  void dispose() {
    stop();
    _controller.close();
  }
}

/// Riverpod provider for the geofence service.
final geofenceServiceProvider = Provider<GeofenceService>((ref) {
  final poiRepo = ref.watch(poiRepositoryProvider);
  final service = GeofenceService(poiRepository: poiRepo);
  ref.onDispose(() => service.dispose());
  return service;
});
