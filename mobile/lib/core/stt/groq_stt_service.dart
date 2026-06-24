import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

import '../../core/config/env_config.dart';

/// Speech-to-text service using Groq's Whisper API.
/// Records audio via `record` package, sends to Groq for transcription.
class GroqSttService {
  GroqSttService({Dio? dio, AudioRecorder? recorder})
      : _dio = dio ?? Dio(),
        _recorder = recorder ?? AudioRecorder();

  final Dio _dio;
  final AudioRecorder _recorder;
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  /// Start recording audio from the microphone.
  Future<void> startRecording() async {
    if (_isRecording) return;

    if (!await _recorder.hasPermission()) {
      throw StateError('Audio recording permission not granted');
    }

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 16000,
      ),
      path: '',
    );
    _isRecording = true;
  }

  /// Stop recording and transcribe via Groq Whisper.
  /// Returns the transcribed text, or empty string if no speech detected.
  Future<String> stopAndTranscribe() async {
    if (!_isRecording) return '';
    _isRecording = false;

    final path = await _recorder.stop();
    if (path == null || path.isEmpty) return '';

    final file = File(path);
    if (!await file.exists()) return '';

    try {
      final apiKey = EnvConfig.groqApiKey;
      if (apiKey.isEmpty) {
        throw StateError('GROQ_API_KEY not configured');
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          path,
          filename: 'recording.m4a',
        ),
        'model': 'whisper-large-v3',
        'language': 'hi', // Prioritize Hindi, but Whisper handles mixed Hindi-English
        'response_format': 'verbose_json',
      });

      final response = await _dio.post(
        'https://api.groq.com/openai/v1/audio/transcriptions',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data['text'] as String? ?? '';
      }
      return data.toString();
    } catch (e) {
      // Clean up file on error
      try {
        await file.delete();
      } catch (_) {}
      rethrow;
    } finally {
      // Clean up temp file
      try {
        await file.delete();
      } catch (_) {}
    }
  }

  /// Cancel recording without transcribing.
  Future<void> cancelRecording() async {
    if (!_isRecording) return;
    _isRecording = false;
    final path = await _recorder.stop();
    if (path != null && path.isNotEmpty) {
      try {
        await File(path).delete();
      } catch (_) {}
    }
  }

  void dispose() {
    _recorder.dispose();
    _dio.close();
  }
}

/// Riverpod provider for the STT service.
final groqSttServiceProvider = Provider<GroqSttService>((ref) {
  final service = GroqSttService();
  ref.onDispose(() => service.dispose());
  return service;
});
