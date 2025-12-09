/// Stub implementation for web platform where TFLite is not available
library;
import 'voice_mood_service_interface.dart';
import 'voice_mood_result.dart';

/// Factory function for web platform
VoiceMoodServiceInterface createVoiceMoodService() {
  return VoiceMoodServiceStub();
}

/// Stub service for voice mood detection on web
class VoiceMoodServiceStub implements VoiceMoodServiceInterface {
  VoiceMoodServiceStub._internal();
  factory VoiceMoodServiceStub() => VoiceMoodServiceStub._internal();

  @override
  Future<bool> initialize() async {
    // Web platform doesn't support TFLite
    return false;
  }

  @override
  Future<VoiceMoodResult> detectMoodFromAudio(String audioPath) async {
    return VoiceMoodResult(
      mood: 'neutral',
      confidence: 0.0,
      error: 'Voice mood detection is not available on web platform. Please use mobile app.',
    );
  }

  @override
  Future<VoiceMoodResult> analyzeMultipleResponses(List<String> audioPaths) async {
    return VoiceMoodResult(
      mood: 'neutral',
      confidence: 0.0,
      error: 'Voice mood detection is not available on web platform. Please use mobile app.',
    );
  }

  @override
  void dispose() {
    // No resources to dispose on web
  }
}

