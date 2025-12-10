/// Interface for voice mood detection service
library;
import 'voice_mood_result.dart';

abstract class VoiceMoodServiceInterface {
  Future<bool> initialize();
  Future<VoiceMoodResult> detectMoodFromAudio(String audioPath);
  Future<VoiceMoodResult> analyzeMultipleResponses(List<String> audioPaths);
  void dispose();
}


