import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks online/offline state. Used by the offline banner (design §4.2) and
/// to make repositories degrade to cached/local data when the network drops.
class ConnectivityController extends StateNotifier<bool> {
  ConnectivityController() : super(true) {
    _sub = Connectivity().onConnectivityChanged.listen((result) {
      state = result != ConnectivityResult.none;
    });
    Connectivity().checkConnectivity().then((result) {
      state = result != ConnectivityResult.none;
    });
  }

  late final StreamSubscription _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final isOnlineProvider =
    StateNotifierProvider<ConnectivityController, bool>(
        (ref) => ConnectivityController());
