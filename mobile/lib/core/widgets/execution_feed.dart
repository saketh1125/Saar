import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import '../theme/app_colors.dart';

/// The agentic execution feed — a small terminal-style overlay that shows the
/// Brain's tool calls executing sequentially (design §4.6). Slides off-screen
/// once all commands complete.
class ExecutionFeed extends StatelessWidget {
  const ExecutionFeed({
    super.key,
    required this.calls,
    required this.completed,
    this.onDone,
  });
  final List<ToolCall> calls;
  final int completed; // how many have finished
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    if (calls.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KashiColors.nightCanvas.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KashiColors.neonSaffron.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text('Brain executing actions…',
                  style: TextStyle(
                    color: KashiColors.sunriseCanvas,
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  )),
              const Spacer(),
              if (completed == calls.length)
                GestureDetector(
                  onTap: onDone,
                  child: Icon(Icons.close,
                      size: 16, color: KashiColors.sunriseCanvas.withValues(alpha: 0.6)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < calls.length; i++)
            _ExecutionLine(
              call: calls[i],
              status: i < completed ? _ExecStatus.ok : _ExecStatus.pending,
            ),
        ],
      ),
    );
  }
}

enum _ExecStatus { pending, ok }

class _ExecutionLine extends StatelessWidget {
  const _ExecutionLine({required this.call, required this.status});
  final ToolCall call;
  final _ExecStatus status;

  @override
  Widget build(BuildContext context) {
    final done = status == _ExecStatus.ok;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            done ? '✓ ' : '├─',
            style: TextStyle(
              color: done
                  ? KashiColors.riverJade
                  : KashiColors.neonSaffron.withValues(alpha: 0.7),
              fontFamily: 'Outfit',
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${call.describe()}  [${done ? "OK" : "…"}]',
              style: TextStyle(
                color: KashiColors.sunriseCanvas.withValues(alpha: done ? 1 : 0.6),
                fontFamily: 'Outfit',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
