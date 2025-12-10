/// Result of voice mood detection
class VoiceMoodResult {
  final String mood;
  final double confidence;
  final Map<String, double>? allProbabilities;
  final String? error;

  VoiceMoodResult({
    required this.mood,
    required this.confidence,
    this.allProbabilities,
    this.error,
  });

  bool get isSuccess => error == null;
}



