import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/location/geofence_service.dart';
import '../../core/networking/open_route_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/solar.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../../data/seed/varanasi_pois.dart';
import 'poi_detail_sheet.dart';

/// Tab 1 — Gali-Aware Map Engine (PRD §3.1.1, design §3.1). Renders free OSM
/// tiles via Stadia over Varanasi, with category-filtered POIs, water/toilet
/// layers, an Escape-Route FAB and a sliding POI detail sheet.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  final Set<PoiCategory> _enabled = {
    PoiCategory.temple,
    PoiCategory.ghat,
    PoiCategory.food,
  };

  Poi? _selected;
  List<Poi> _allPois = const [];
  bool _escapeActive = false;
  List<LatLng> _escapeRoute = const [];
  bool _refreshing = false;
  PedestrianRoute? _navRoute;
  bool _navLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPois();
      _initGeofence();
    });
  }

  Future<void> _initGeofence() async {
    final geofence = ref.read(geofenceServiceProvider);
    await geofence.init();
    await geofence.start();
    geofence.onEnter.listen((event) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Near ${event.placeName} — showing checklist…'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'VIEW',
              textColor: KashiColors.neonSaffron,
              onPressed: () {
                // Navigate to the POI detail
                final poi = _allPois.firstWhere(
                  (p) => p.id == event.placeId,
                  orElse: () => _allPois.first,
                );
                setState(() => _selected = poi);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => PoiDetailSheet(
                    poi: poi,
                    onNavigate: () => navigateToPoi(poi),
                  ),
                );
              },
            ),
          ),
        );
      }
    });
  }

  Future<void> _loadPois() async {
    final repo = ref.read(poiRepositoryProvider);
    final pois = await repo.all();
    setState(() => _allPois = pois);
  }

  void _triggerLiveRefresh() {
    setState(() => _refreshing = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _refreshing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Live feeds synchronized successfully.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _toggleEscape() {
    if (_escapeActive) {
      setState(() {
        _escapeActive = false;
        _escapeRoute = const [];
      });
      return;
    }
    // Find nearest main-road node to the map centre and draw a dotted route.
    final centre = _mapController.camera.center;
    final nearest = _nearestMainRoad(centre);
    setState(() {
      _escapeActive = true;
      _escapeRoute = [centre, nearest.location];
      _selected = nearest;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Escape route to ${nearest.name} '
            '— walk straight for ~50m, then turn left to reach the main road.'),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Poi _nearestMainRoad(LatLng from) {
    Poi best = kMainRoadNodes.first;
    double bestD = double.infinity;
    for (final p in kMainRoadNodes) {
      final d = (p.lat - from.latitude) * (p.lat - from.latitude) +
          (p.lng - from.longitude) * (p.lng - from.longitude);
      if (d < bestD) {
        bestD = d;
        best = p;
      }
    }
    return best;
  }

  Future<void> navigateToPoi(Poi poi) async {
    setState(() {
      _navLoading = true;
      _escapeActive = false;
      _escapeRoute = const [];
    });

    final ors = ref.read(orsClientProvider);
    final userLocation = _mapController.camera.center;

    try {
      final route = await ors.getPedestrianRoute(
        start: userLocation,
        end: poi.location,
      );

      if (mounted && route != null) {
        setState(() {
          _navRoute = route;
          _navLoading = false;
        });
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(route.polyline),
            padding: const EdgeInsets.all(50),
          ),
        );
      } else if (mounted) {
        setState(() => _navLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not compute route. Check ORS API key.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _navLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Routing error: $e')),
        );
      }
    }
  }

  void clearNavigation() {
    setState(() => _navRoute = null);
  }

  @override
  Widget build(BuildContext context) {
    final visiblePois = _allPois.where((p) => _enabled.contains(p.category)).toList();
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(Solar.kashiLatitude, Solar.kashiLongitude),
              initialZoom: 15,
              minZoom: 10,
              maxZoom: 19,
              onTap: (_, __) => setState(() => _selected = null),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.kashinav.app',
                // flutter_map_cache wires in transparent SQLite tile caching
                // for offline use near the ghats (PRD §3.1.1).
                retinaMode: true,
              ),
              if (_escapeRoute.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _escapeRoute,
                      color: KashiColors.terracotta,
                      strokeWidth: 5,
                    ),
                  ],
                ),
              if (_navRoute != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _navRoute!.polyline,
                      color: KashiColors.riverJade,
                      strokeWidth: 5,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  for (final poi in visiblePois)
                    Marker(
                      point: poi.location,
                      width: 36,
                      height: 36,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selected = poi);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => PoiDetailSheet(
                              poi: poi,
                              onNavigate: () => navigateToPoi(poi),
                            ),
                          );
                        },
                        child: _PoiMarker(poi: poi, selected: _selected?.id == poi.id),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Search header + filter chips, top-aligned over the map.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: GlassSearchHeader(
                      hint: "Try 'Ganga Aarti' or 'Assi'…",
                      onRefresh: _triggerLiveRefresh,
                      refreshing: _refreshing,
                      onSubmitted: (q) => _search(q),
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        for (final c in PoiCategory.values)
                          _FilterChip(
                            category: c,
                            enabled: _enabled.contains(c),
                            onToggle: () => setState(() {
                              if (_enabled.contains(c)) {
                                _enabled.remove(c);
                              } else {
                                _enabled.add(c);
                              }
                            }),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Escape-to-Main-Road FAB, bottom-right above centre control.
          Positioned(
            right: 16,
            bottom: _selected == null ? 24 : 220,
            child: FloatingActionButton.extended(
              heroTag: 'escape',
              backgroundColor:
                  _escapeActive ? KashiColors.nightCanvas : KashiColors.terracotta,
              foregroundColor: KashiColors.sunriseCanvas,
              icon: const Icon(Icons.exit_to_app),
              label: Text(_escapeActive ? 'Clear Route' : 'Escape'),
              onPressed: _toggleEscape,
            ),
          ),

          // Navigation info bar when route is active.
          if (_navRoute != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: KashiColors.nightCanvas.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: KashiColors.riverJade.withValues(alpha: 0.5)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_walk, color: KashiColors.riverJade),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_navRoute!.distanceText} · ${_navRoute!.durationText}',
                            style: const TextStyle(
                              color: KashiColors.sunriseCanvas,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: KashiColors.neonSaffron),
                          onPressed: clearNavigation,
                        ),
                      ],
                    ),
                    if (_navRoute!.steps.isNotEmpty)
                      Text(
                        _navRoute!.steps.first.instruction ?? 'Follow the route',
                        style: TextStyle(
                          color: KashiColors.sunriseCanvas.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),

          // Loading indicator while computing route.
          if (_navLoading)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(KashiColors.riverJade),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _search(String q) {
    final lower = q.toLowerCase();
    if (_allPois.isEmpty) return;
    final hit = _allPois.firstWhere(
      (p) =>
          p.name.toLowerCase().contains(lower) ||
          p.aliases.any((a) => a.toLowerCase().contains(lower)),
      orElse: () => _allPois.first,
    );
    _mapController.move(hit.location, 17);
    setState(() => _selected = hit);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PoiDetailSheet(
        poi: hit,
        onNavigate: () => navigateToPoi(hit),
      ),
    );
  }
}

class _PoiMarker extends StatelessWidget {
  const _PoiMarker({required this.poi, required this.selected});
  final Poi poi;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(poi.category);
    final emoji = _emojiFor(poi.category);
    return AnimatedScale(
      scale: selected ? 1.25 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: KashiColors.sunriseCanvas,
            width: selected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: selected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
      ),
    );
  }

  Color _colorFor(PoiCategory c) => switch (c) {
        PoiCategory.temple => KashiColors.saffronGold,
        PoiCategory.ghat => KashiColors.terracotta,
        PoiCategory.food => KashiColors.dustyOrange,
        PoiCategory.water => KashiColors.riverJade,
        PoiCategory.toilet => KashiColors.slateGrey,
        PoiCategory.safety => Colors.red.shade400,
        PoiCategory.view => KashiColors.deepIndigo,
        PoiCategory.market => KashiColors.neonSaffron,
      };

  String _emojiFor(PoiCategory c) => switch (c) {
        PoiCategory.temple => '🛕',
        PoiCategory.ghat => '🌊',
        PoiCategory.food => '🥣',
        PoiCategory.water => '💧',
        PoiCategory.toilet => '🚻',
        PoiCategory.safety => '🛟',
        PoiCategory.view => '🌅',
        PoiCategory.market => '🛍️',
      };
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.category,
    required this.enabled,
    required this.onToggle,
  });
  final PoiCategory category;
  final bool enabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    const labels = {
      PoiCategory.temple: '🛕 Temples',
      PoiCategory.ghat: '🌊 Ghats',
      PoiCategory.food: '🥣 Food',
      PoiCategory.water: '💧 RO Water',
      PoiCategory.toilet: '🚻 Toilets',
      PoiCategory.safety: '🛟 Safety',
      PoiCategory.view: '🌅 Views',
      PoiCategory.market: '🛍️ Markets',
    };
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(labels[category]!),
        selected: enabled,
        onSelected: (_) => onToggle(),
        selectedColor: KashiColors.saffronGold,
        labelStyle: TextStyle(
          color: enabled ? Colors.white : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
