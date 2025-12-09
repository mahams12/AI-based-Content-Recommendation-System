import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'voice_mood_service_interface.dart';
import 'voice_mood_result.dart';

/// Factory function for mobile platform
VoiceMoodServiceInterface createVoiceMoodService() {
  return VoiceMoodServiceMobile();
}

/// Mobile implementation of voice mood detection using TensorFlow Lite
class VoiceMoodServiceMobile implements VoiceMoodServiceInterface {
  Interpreter? _interpreter;
  bool _isInitialized = false;
  static const String _modelPath = 'assets/models/voice/my_model.tflite';

  // Mood categories (adjust based on your model's output)
  final List<String> _moodCategories = [
    'happy',
    'sad',
    'energetic',
    'relaxed',
    'romantic',
    'adventurous',
    'focused',
    'nostalgic',
    'angry',
    'calm',
    'neutral',
  ];

  @override
  Future<bool> initialize() async {
    if (_isInitialized && _interpreter != null) {
      return true;
    }

    try {
      // Load model from assets
      final ByteData modelData = await rootBundle.load(_modelPath);
      final Uint8List modelBytes = modelData.buffer.asUint8List();

      // Create interpreter
      _interpreter = Interpreter.fromBuffer(modelBytes);

      // Get input and output shapes
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;

      print('Model loaded successfully');
      print('Input shape: $inputShape');
      print('Output shape: $outputShape');

      _isInitialized = true;
      return true;
    } catch (e) {
      print('Error initializing voice mood model: $e');
      _isInitialized = false;
      return false;
    }
  }

  @override
  Future<VoiceMoodResult> detectMoodFromAudio(String audioPath) async {
    if (!_isInitialized || _interpreter == null) {
      final initialized = await initialize();
      if (!initialized) {
        return VoiceMoodResult(
          mood: 'neutral',
          confidence: 0.0,
          error: 'Model not initialized',
        );
      }
    }

    try {
      // Read audio file
      final audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        return VoiceMoodResult(
          mood: 'neutral',
          confidence: 0.0,
          error: 'Audio file not found',
        );
      }

      // IMPORTANT: This is a placeholder implementation
      // You need to implement proper audio preprocessing based on your model's requirements:
      // 1. Load audio file and convert to raw audio samples
      // 2. Apply feature extraction (MFCC, Mel-spectrogram, etc.)
      // 3. Normalize features to match training data
      // 4. Reshape to match model input dimensions
      // Consider using packages like: flutter_sound, audioplayers, or native audio processing
      
      // Placeholder: Create input tensor with zeros (replace with actual preprocessing)
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final inputSize = inputShape.fold(1, (a, b) => a * b);
      final input = _createInputTensor(inputShape, inputSize);
      
      // Prepare output tensor
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final outputSize = outputShape.fold(1, (a, b) => a * b);
      final output = _reshapeList(List.filled(outputSize, 0.0), outputShape);

      // Run inference
      _interpreter!.run(input, output);

      // Process output to get mood
      final moodIndex = _findMaxIndex(output);
      final confidence = output[moodIndex].abs().toDouble();
      final mood = moodIndex < _moodCategories.length 
          ? _moodCategories[moodIndex] 
          : 'neutral';

      return VoiceMoodResult(
        mood: mood,
        confidence: confidence.clamp(0.0, 1.0),
        allProbabilities: _extractProbabilities(output),
      );
    } catch (e) {
      print('Error detecting mood from audio: $e');
      return VoiceMoodResult(
        mood: 'neutral',
        confidence: 0.0,
        error: 'Error processing audio: $e',
      );
    }
  }

  @override
  Future<VoiceMoodResult> analyzeMultipleResponses(List<String> audioPaths) async {
    if (audioPaths.isEmpty) {
      return VoiceMoodResult(
        mood: 'neutral',
        confidence: 0.0,
        error: 'No audio files provided',
      );
    }

    final List<VoiceMoodResult> results = [];
    
    for (final audioPath in audioPaths) {
      final result = await detectMoodFromAudio(audioPath);
      if (result.error == null) {
        results.add(result);
      }
    }

    if (results.isEmpty) {
      return VoiceMoodResult(
        mood: 'neutral',
        confidence: 0.0,
        error: 'Failed to analyze any audio files',
      );
    }

    // Aggregate results (weighted average)
    final moodScores = <String, double>{};
    double totalConfidence = 0.0;

    for (final result in results) {
      moodScores[result.mood] = (moodScores[result.mood] ?? 0.0) + result.confidence;
      totalConfidence += result.confidence;
    }

    // Find mood with highest score
    final dominantMood = moodScores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    final overallConfidence = moodScores[dominantMood]! / totalConfidence;

    return VoiceMoodResult(
      mood: dominantMood,
      confidence: overallConfidence.clamp(0.0, 1.0),
      allProbabilities: moodScores.map((k, v) => MapEntry(k, v / totalConfidence)),
    );
  }

  /// Create input tensor - PLACEHOLDER: Replace with actual audio preprocessing
  List<dynamic> _createInputTensor(List<int> shape, int size) {
    // This creates a tensor filled with zeros
    // Replace this with actual audio feature extraction
    final flatList = List.filled(size, 0.0);
    
    // Reshape to match model input
    return _reshapeList(flatList, shape);
  }

  /// Reshape a flat list to match tensor shape
  dynamic _reshapeList(List<double> list, List<int> shape) {
    if (shape.length == 1) {
      return list;
    } else if (shape.length == 2) {
      final rows = shape[0];
      final cols = shape[1];
      final result = <List<double>>[];
      for (int i = 0; i < rows; i++) {
        result.add(list.sublist(i * cols, (i + 1) * cols));
      }
      return result;
    } else if (shape.length == 3) {
      final dim1 = shape[0];
      final dim2 = shape[1];
      final dim3 = shape[2];
      final result = <List<List<double>>>[];
      for (int i = 0; i < dim1; i++) {
        final matrix = <List<double>>[];
        for (int j = 0; j < dim2; j++) {
          final start = (i * dim2 * dim3) + (j * dim3);
          matrix.add(list.sublist(start, start + dim3));
        }
        result.add(matrix);
      }
      return result;
    }
    // For higher dimensions, return flat list (may need more complex reshaping)
    return list;
  }

  int _findMaxIndex(List<dynamic> list) {
    double max = double.negativeInfinity;
    int maxIndex = 0;
    for (int i = 0; i < list.length; i++) {
      final value = list[i] is List ? list[i][0] : list[i];
      if (value > max) {
        max = value.toDouble();
        maxIndex = i;
      }
    }
    return maxIndex;
  }

  Map<String, double> _extractProbabilities(List<dynamic> output) {
    final probabilities = <String, double>{};
    final flatOutput = output.expand((e) => e is List ? e : [e]).toList();
    
    // Normalize probabilities
    final sum = flatOutput.fold<double>(0.0, (a, b) => a + b.abs().toDouble());
    
    for (int i = 0; i < flatOutput.length && i < _moodCategories.length; i++) {
      final prob = sum > 0 
          ? (flatOutput[i].abs().toDouble() / sum)
          : 0.0;
      probabilities[_moodCategories[i]] = prob;
    }
    
    return probabilities;
  }

  @override
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}

