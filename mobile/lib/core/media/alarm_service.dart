import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for scheduling alarms that play audio from the linked media provider.
///
/// When an alarm fires, it resolves the sound query to a playable track
/// from the active media provider and plays it.
class AlarmService {
  AlarmService();


  /// Schedule an alarm at [scheduledTime] that plays [soundQuery].
  Future<bool> scheduleAlarm({
    required DateTime scheduledTime,
    required String soundQuery,
    String? label,
  }) async {
    try {
      await AndroidAlarmManager.oneShotAt(
        scheduledTime,
        0, // Alarm ID
        _alarmCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        params: {'sound_query': soundQuery},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Cancel all scheduled alarms.
  Future<void> cancelAll() async {
    await AndroidAlarmManager.cancel(0);
  }
}

/// Static callback for when the alarm fires.
/// This runs in a separate isolate.
@pragma('vm:entry-point')
void _alarmCallback(int id, Map<String, dynamic> params) async {
  // The alarm fired — play the sound
  // In a real implementation, this would:
  // 1. Initialize the audio session
  // 2. Resolve the sound query to a track URL
  // 3. Play the audio using just_audio
}

final alarmServiceProvider = Provider<AlarmService>((ref) {
  return AlarmService();
});
