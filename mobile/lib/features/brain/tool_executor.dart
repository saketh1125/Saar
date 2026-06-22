import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/media/alarm_service.dart';
import '../../core/media/media_provider_manager.dart';
import '../../data/models/models.dart';

/// Executes tool calls from the Brain's voice intent parser.
///
/// When the Brain emits a tool call (e.g., `set_alarm`, `play_music`),
/// this class dispatches it to the appropriate service.
class ToolExecutor {
  ToolExecutor(this._ref);
  final Ref _ref;

  /// Execute a list of tool calls sequentially.
  Future<List<ToolExecutionResult>> executeAll(List<ToolCall> toolCalls) async {
    final results = <ToolExecutionResult>[];

    for (final toolCall in toolCalls) {
      final result = await execute(toolCall);
      results.add(result);
    }

    return results;
  }

  /// Execute a single tool call.
  Future<ToolExecutionResult> execute(ToolCall toolCall) async {
    try {
      switch (toolCall.name) {
        case 'set_alarm':
          return await _executeSetAlarm(toolCall);
        case 'play_music':
          return await _executePlayMusic(toolCall);
        case 'start_navigation':
          return await _executeStartNavigation(toolCall);
        case 'show_checklist':
          return await _executeShowChecklist(toolCall);
        default:
          return ToolExecutionResult(
            toolCall: toolCall,
            success: false,
            message: 'Unknown tool: ${toolCall.name}',
          );
      }
    } catch (e) {
      return ToolExecutionResult(
        toolCall: toolCall,
        success: false,
        message: 'Error: $e',
      );
    }
  }

  Future<ToolExecutionResult> _executeSetAlarm(ToolCall toolCall) async {
    final time = toolCall.arguments['time'] as String?;
    final soundQuery = toolCall.arguments['sound_query'] as String? ?? 'morning music';

    if (time == null) {
      return ToolExecutionResult(
        toolCall: toolCall,
        success: false,
        message: 'No time specified',
      );
    }

    // Parse the time string (e.g., "04:30")
    final parts = time.split(':');
    if (parts.length != 2) {
      return ToolExecutionResult(
        toolCall: toolCall,
        success: false,
        message: 'Invalid time format',
      );
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return ToolExecutionResult(
        toolCall: toolCall,
        success: false,
        message: 'Invalid time values',
      );
    }

    // Schedule for tomorrow
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day + 1, hour, minute);

    final alarmService = _ref.read(alarmServiceProvider);
    final success = await alarmService.scheduleAlarm(
      scheduledTime: scheduledTime,
      soundQuery: soundQuery,
      label: 'Kashi Nav Alarm',
    );

    return ToolExecutionResult(
      toolCall: toolCall,
      success: success,
      message: success ? 'Alarm set for $time' : 'Failed to set alarm',
    );
  }

  Future<ToolExecutionResult> _executePlayMusic(ToolCall toolCall) async {
    final soundQuery = toolCall.arguments['sound_query'] as String? ?? '';

    final mediaManager = _ref.read(mediaProviderManagerProvider.notifier);
    final provider = _ref.read(mediaProviderManagerProvider).activeProvider;

    if (provider == null) {
      return ToolExecutionResult(
        toolCall: toolCall,
        success: false,
        message: 'No media provider connected',
      );
    }

    // Search for the track
    final tracks = await provider.search(soundQuery);
    if (tracks.isEmpty) {
      return ToolExecutionResult(
        toolCall: toolCall,
        success: false,
        message: 'No results for "$soundQuery"',
      );
    }

    // Play the first result
    await mediaManager.playTrack(tracks.first);
    return ToolExecutionResult(
      toolCall: toolCall,
      success: true,
      message: 'Playing ${tracks.first}',
    );
  }

  Future<ToolExecutionResult> _executeStartNavigation(ToolCall toolCall) async {
    // Navigation is handled by the map screen
    return ToolExecutionResult(
      toolCall: toolCall,
      success: true,
      message: 'Navigation started',
    );
  }

  Future<ToolExecutionResult> _executeShowChecklist(ToolCall toolCall) async {
    // Checklist is handled by the tools screen
    return ToolExecutionResult(
      toolCall: toolCall,
      success: true,
      message: 'Checklist opened',
    );
  }
}

/// Result of executing a tool call.
class ToolExecutionResult {
  final ToolCall toolCall;
  final bool success;
  final String message;

  const ToolExecutionResult({
    required this.toolCall,
    required this.success,
    required this.message,
  });
}

final toolExecutorProvider = Provider<ToolExecutor>((ref) {
  return ToolExecutor(ref);
});
