import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/execution_feed.dart';
import '../../core/widgets/voice_overlay.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';

/// Tab 3 — The AI Brain (PRD §3.1.2, design §3.2). Chat window with RAG + live
/// search, agentic tool-calling (execution feed), confidence labels, source
/// chips, voice overlay, and an offline fallback state.
class BrainScreen extends ConsumerStatefulWidget {
  const BrainScreen({super.key});

  @override
  ConsumerState<BrainScreen> createState() => _BrainScreenState();
}

class _BrainScreenState extends ConsumerState<BrainScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _tts = FlutterTts();
  final List<ChatMessage> _messages = [];

  bool _refreshing = false;
  bool _voiceOpen = false;
  bool _voiceListening = false;
  bool _voiceParsing = false;
  String _voiceTranscript = '';

  List<ToolCall>? _activeCalls;
  int _completedCalls = 0;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _messages.add(const ChatMessage(
      id: 'welcome',
      text: 'Namaste 🙏 I am your Kashi Brain. Ask me anything — festival timings, '
          'the best lassi nearby, or say "Set a 4:30 AM alarm".',
      fromUser: false,
      timestamp: null,
      confidence: 'high',
    ));
  }

  Future<void> _send({String? override}) async {
    final text = (override ?? _input.text).trim();
    if (text.isEmpty) return;
    _input.clear();
    final online = ref.read(isOnlineProvider);

    setState(() {
      _messages.add(ChatMessage(
        id: const Uuid().v4(),
        text: text,
        fromUser: true,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();

    if (!online) {
      setState(() {
        _messages.add(ChatMessage(
          id: const Uuid().v4(),
          text: 'I am offline, but I can search your saved places and cached '
              'cultural guides. Here is what I know from local data: …',
          fromUser: false,
          timestamp: DateTime.now(),
          isOfflineAnswer: true,
          confidence: 'low',
        ));
      });
      _scrollToBottom();
      return;
    }

    setState(() => _refreshing = true);
    try {
      final repo = ref.read(liveSituationRepositoryProvider);
      final result = await repo.getLiveSituation(
        query: text,
        lat: 25.3176,
        lng: 83.0130,
        forceLiveRefresh: _refreshing,
      );
      final msg = ChatMessage(
        id: const Uuid().v4(),
        text: result.text,
        fromUser: false,
        timestamp: DateTime.now(),
        confidence: result.confidence,
        sources: result.sources,
        toolCalls: result.toolCalls,
      );
      setState(() {
        _messages.add(msg);
        _refreshing = false;
      });
      if (result.toolCalls.isNotEmpty) {
        _runExecutionFeed(result.toolCalls);
      }
      _scrollToBottom();
      await _tts.speak(result.text.split('. ').first);
    } catch (_) {
      setState(() => _refreshing = false);
    }
  }

  void _runExecutionFeed(List<ToolCall> calls) {
    setState(() {
      _activeCalls = calls;
      _completedCalls = 0;
    });
    for (var i = 0; i < calls.length; i++) {
      Future.delayed(Duration(milliseconds: 700 * (i + 1)), () {
        if (mounted) setState(() => _completedCalls = i + 1);
      });
    }
    Future.delayed(Duration(milliseconds: 700 * calls.length + 2500), () {
      if (mounted) setState(() => _activeCalls = null);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openVoice() {
    setState(() {
      _voiceOpen = true;
      _voiceListening = true;
      _voiceParsing = false;
      _voiceTranscript = '';
    });
    // Simulated capture; real STT via Groq/Whisper lives behind the voice
    // intent repository (design §4.3 step 4).
    const sample = 'Wake me up at 4:30 AM with morning flute music';
    final words = sample.split(' ');
    for (var i = 0; i < words.length; i++) {
      Future.delayed(Duration(milliseconds: 280 * (i + 1)), () {
        if (mounted && _voiceListening) {
          setState(() => _voiceTranscript = words.sublist(0, i + 1).join(' '));
        }
      });
    }
    Future.delayed(Duration(milliseconds: 280 * (words.length + 1)), () {
      if (!mounted) return;
      setState(() {
        _voiceListening = false;
        _voiceParsing = true;
      });
      _parseVoice(sample);
    });
  }

  Future<void> _parseVoice(String text) async {
    final repo = ref.read(voiceIntentRepositoryProvider);
    final intent = await repo.parse(text);
    if (!mounted) return;
    setState(() {
      _voiceOpen = false;
      _voiceParsing = false;
    });
    if (intent.toolCalls.isNotEmpty) {
      _runExecutionFeed(intent.toolCalls);
    }
    _send(override: text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kashi Brain'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: const Icon(Icons.bolt, size: 14, color: KashiColors.riverJade),
              label: const Text('Gemini Flash'),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => _MessageBubble(message: _messages[i]),
                ),
                if (_activeCalls != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 12,
                    child: ExecutionFeed(
                      calls: _activeCalls!,
                      completed: _completedCalls,
                      onDone: () => setState(() => _activeCalls = null),
                    ),
                  ),
                _voiceOverlayIfOpen(),
              ],
            ),
          ),
          _promptChips(),
          _inputBar(),
        ],
      ),
    );
  }

  // Voice overlay rendered inline at the bottom of the chat (design §4.3) so
  // it rebuilds with live transcript/parsing state.
  Widget _voiceOverlayIfOpen() {
    if (!_voiceOpen) return const SizedBox.shrink();
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: VoiceOverlay(
        transcript: _voiceTranscript,
        listening: _voiceListening,
        parsing: _voiceParsing,
      ),
    );
  }

  Widget _promptChips() {
    const prompts = [
      'Is the Ganga Aarti on tonight?',
      'Best lassi near me?',
      'Set a 4:30 AM alarm',
    ];
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final p in prompts)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(p),
                labelStyle: const TextStyle(color: KashiColors.saffronGold),
                side: BorderSide(color: KashiColors.saffronGold.withValues(alpha: 0.5)),
                onPressed: () => _send(override: p),
              ),
            ),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            RefreshIcon(refreshing: _refreshing, onPressed: () => setState(() => _refreshing = !_refreshing)),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: _input,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Ask the Brain…',
                  filled: true,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton.filled(
              icon: const Icon(Icons.mic),
              style: const ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(KashiColors.terracotta),
                foregroundColor: WidgetStatePropertyAll(Colors.white),
              ),
              onPressed: _openVoice,
            ),
            const SizedBox(width: 4),
            IconButton.filled(
              icon: const Icon(Icons.send),
              style: const ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(KashiColors.saffronGold),
                foregroundColor: WidgetStatePropertyAll(Colors.white),
              ),
              onPressed: () => _send(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final fromUser = message.fromUser;
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          gradient: fromUser
              ? const LinearGradient(colors: [KashiColors.terracotta, KashiColors.dustyOrange])
              : null,
          color: fromUser ? null : KashiColors.nightComponent,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: fromUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: fromUser ? Radius.zero : const Radius.circular(16),
          ),
          border: fromUser
              ? null
              : Border.all(color: KashiColors.saffronGold.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: fromUser ? KashiColors.sunriseCanvas : KashiColors.sunriseCanvas,
                height: 1.4,
              ),
            ),
            if (message.isOfflineAnswer) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: KashiColors.saffronGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Offline · cached answer',
                    style: TextStyle(fontSize: 10, color: KashiColors.neonSaffron)),
              ),
            ],
            if (message.confidence.isNotEmpty) ...[
              const SizedBox(height: 8),
              _ConfidenceLabel(confidence: message.confidence),
            ],
            if (message.sources.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final s in message.sources)
                    _SourceChip(source: s.source),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConfidenceLabel extends StatelessWidget {
  const _ConfidenceLabel({required this.confidence});
  final String confidence;

  @override
  Widget build(BuildContext context) {
    final (color, text) = switch (confidence) {
      'high' => (KashiColors.riverJade, 'Verified just now'),
      'medium' => (KashiColors.saffronGold, 'Typical, cross-checked'),
      'low' => (KashiColors.terracotta, 'Best guess · verify locally'),
      _ => (KashiColors.slateGrey, confidence),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified, size: 12, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.source});
  final String source;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: KashiColors.nightCanvas,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(source,
            style: const TextStyle(fontSize: 10, color: KashiColors.neonSaffron)),
      );
}
