import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Checks and requests location permissions at app startup.
/// Returns true if permissions are granted, false otherwise.
Future<bool> ensureLocationPermissions() async {
  // Check if location services are enabled
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return false;
  }

  // Check current permission status
  LocationPermission permission = await Geolocator.checkPermission();

  // If denied, request permission
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return false;
    }
  }

  // If permanently denied, show settings prompt
  if (permission == LocationPermission.deniedForever) {
    return false;
  }

  // Either "whileInUse" or "always" counts as granted
  return permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always;
}

/// Shows a dialog explaining why location is needed and prompting the user
/// to open settings if permissions are permanently denied.
Future<void> showLocationPermissionDialog(BuildContext context) async {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Location Permission'),
      content: const Text(
        'Kashi Nav needs your location to show nearby POIs, trigger checklists when '
        'you approach temples and ghats, and provide pedestrian navigation.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.of(ctx).pop();
            await Geolocator.openAppSettings();
          },
          child: const Text('Open Settings'),
        ),
      ],
    ),
  );
}
