import 'voice_mood_service_interface.dart';
import 'voice_mood_result.dart';

// Conditional import - only load TFLite on mobile platforms
// On web (dart.library.html exists), use stub. On mobile, use mobile implementation.
import 'voice_mood_service_mobile.dart'
    if (dart.library.html) 'voice_mood_service_stub.dart'
    as impl;

/// Service for voice-based mood detection using TensorFlow Lite
/// This is a factory that returns the appropriate implementation based on platform
class VoiceMoodService implements VoiceMoodServiceInterface {
  static final VoiceMoodService _instance = VoiceMoodService._internal();
  factory VoiceMoodService() => _instance;
  VoiceMoodService._internal();

  // Use the appropriate implementation based on platform
  // Conditional import handles platform selection at compile time
  late final VoiceMoodServiceInterface _delegate = impl
      .createVoiceMoodService();

  @override
  Future<bool> initialize() async {
    return _delegate.initialize();
  }

  @override
  Future<VoiceMoodResult> detectMoodFromAudio(String audioPath) async {
    return _delegate.detectMoodFromAudio(audioPath);
  }

  @override
  Future<VoiceMoodResult> analyzeMultipleResponses(
    List<String> audioPaths,
  ) async {
    return _delegate.analyzeMultipleResponses(audioPaths);
  }

  @override
  void dispose() {
    _delegate.dispose();
  }
}
