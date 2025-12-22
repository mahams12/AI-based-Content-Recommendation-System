import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'voice_mood_service_interface.dart';
import 'voice_mood_result.dart';

/// Factory function for mobile platform
VoiceMoodServiceInterface createVoiceMoodService() {
  return VoiceMoodServiceMobile();
}

/// Audio features extracted from PCM samples
class AudioFeatures {
  final double pitch; // Fundamental frequency (Hz)
  final double energy; // RMS energy
  final double spectralCentroid; // Brightness (Hz)
  final double zeroCrossingRate; // ZCR (rate of sign changes)
  final double energyVariability; // Standard deviation of energy
  final double spectralRolloff; // Frequency below which 85% of energy is contained
  final double spectralFlux; // Rate of change of spectrum

  AudioFeatures({
    required this.pitch,
    required this.energy,
    required this.spectralCentroid,
    required this.zeroCrossingRate,
    required this.energyVariability,
    required this.spectralRolloff,
    required this.spectralFlux,
  });
}

/// Mobile implementation of voice mood detection using YAMNet-based TensorFlow Lite model
class VoiceMoodServiceMobile implements VoiceMoodServiceInterface {
  // Classifier that takes a 1024‑dimensional YAMNet embedding and outputs
  // mood probabilities.
  Interpreter? _interpreter;

  // Base YAMNet model that converts raw 16 kHz waveform → 1024‑dim embeddings.
  Interpreter? _yamnetInterpreter;

  bool _isInitialized = false;
  static const String _modelPath = 'assets/models/voice/yamnet_classifier.tflite';
  // NEW: single-output YAMNet embeddings model (frames × 1024)
  static const String _yamnetBaseModelPath =
      'assets/models/voice/yamnet_embeddings.tflite';
  static const String _labelMapPath = 'assets/models/voice/label_map.json';

  // Mood categories loaded from label_map.json.
  // IMPORTANT: This list MUST match the classifier model output index order.
  // We keep non-supported labels (e.g., calm/disgust/unknown) so we can map them
  // to the closest supported mood later (Option C).
  List<String> _moodCategories = [
    'angry',
    'calm',
    'disgust',
    'fear',
    'happy',
    'neutral',
    'sad',
    'surprise',
    'unknown',
  ];

  // Temporal smoothing: Store last 5 predictions for majority vote
  final List<String> _predictionHistory = [];
  static const int _historySize = 5;
  static const int _majorityThreshold = 3; // Need ≥3 votes to return a mood

  // Supported moods (final labels) - including all detected moods
  static const List<String> _supportedMoods = [
    'angry',
    'happy',
    'sad',
    'neutral',
    'fear',
    'surprise',
    'calm',
    'disgust',
  ];

  // Audio preprocessing constants
  static const double _silenceThreshold = 0.08; // RMS threshold for silence detection (very strict - reject if RMS < 0.08)
  static const double _sadConfidenceThreshold = 0.6; // Require higher confidence for "sad"
  
  // Track recent moods to avoid always showing the same one
  final List<String> _recentMoods = [];
  static const int _recentMoodsHistory = 3; // Track last 3 moods

  @override
  Future<bool> initialize() async {
    if (_isInitialized && _interpreter != null) {
      return true;
    }

    try {
      print('🔄 Starting YAMNet model initialization...');
      print('📁 Model path: $_modelPath');
      print('📁 Label map path: $_labelMapPath');

      // Load label map from JSON
      await _loadLabelMap();

      // Load YAMNet classifier model from assets
      print('📦 Loading model from assets...');
      ByteData modelData;
      try {
        modelData = await rootBundle.load(_modelPath);
        print('✅ Model file loaded from assets (${modelData.lengthInBytes} bytes)');
      } catch (e) {
        print('❌ Failed to load model file from assets: $e');
        print('💡 Make sure the file exists at: $_modelPath');
        print('💡 Run: flutter pub get and flutter clean, then rebuild');
        _isInitialized = false;
        return false;
      }

      final Uint8List modelBytes = modelData.buffer.asUint8List();
      print('📦 Model bytes prepared (${modelBytes.length} bytes)');

      // Create interpreter with optimized settings for mobile
      print('🔧 Creating TFLite interpreter...');
      Interpreter? interpreter;
      
      try {
        // Try with optimized options first
        final options = InterpreterOptions();
        options.threads = 4; // Use 4 threads for better performance
        
        try {
          interpreter = Interpreter.fromBuffer(modelBytes, options: options);
          print('✅ TFLite interpreter created successfully with optimized options');
        } catch (e) {
          print('⚠️ Failed with optimized options, trying default options: $e');
          // Fallback to default options if optimized fails
          interpreter = Interpreter.fromBuffer(modelBytes);
          print('✅ TFLite interpreter created successfully with default options');
        }
        
        _interpreter = interpreter;
      } catch (e) {
        print('❌ Failed to create TFLite interpreter: $e');
        print('💡 The model file might be corrupted or in wrong format');
        print('💡 Make sure the model is a valid TensorFlow Lite file');
        print('💡 Model file size: ${modelBytes.length} bytes');
        _isInitialized = false;
        return false;
      }

      // Get input and output shapes
      try {
        final inputShape = _interpreter!.getInputTensor(0).shape;
        final outputShape = _interpreter!.getOutputTensor(0).shape;

        print('✅ YAMNet classifier model loaded successfully');
        print('📊 Input shape: $inputShape');
        print('📊 Output shape: $outputShape');
        print('📊 Input tensor type: ${_interpreter!.getInputTensor(0).type}');
        print('📊 Output tensor type: ${_interpreter!.getOutputTensor(0).type}');
        print('📋 Mood categories (${_moodCategories.length}): $_moodCategories');
        
        // Verify all supported moods are present (ignore "unknown")
        final missingSupportedMoods = _supportedMoods.where((mood) => !_moodCategories.contains(mood)).toList();
        if (missingSupportedMoods.isNotEmpty) {
          print('⚠️ WARNING: Missing supported moods: $missingSupportedMoods');
        } else {
          print('✅ All ${_supportedMoods.length} supported moods are present in the model: $_supportedMoods');
        }
        
        // Test classifier with dummy input to verify it works
        print('🧪 Testing classifier with dummy input...');
        try {
          final inputSize = inputShape.fold(1, (a, b) => a * b);
          final outputSize = outputShape.fold(1, (a, b) => a * b);
          final inputTensorType = _interpreter!.getInputTensor(0).type;
          final outputTensorTypeTest = _interpreter!.getOutputTensor(0).type;
          final testInput = _createTestInput(inputShape, inputSize, inputTensorType);
          
          dynamic testOutput;
          // Check if output is quantized (int8/uint8) by comparing type
          final isQuantizedTest = outputTensorTypeTest.toString().contains('int8') || 
                                 outputTensorTypeTest.toString().contains('uint8');
          if (isQuantizedTest) {
            testOutput = _reshapeListInt8(List<int>.filled(outputSize, 0), outputShape);
          } else {
            testOutput = _reshapeList(List.filled(outputSize, 0.0), outputShape);
          }
          
          _interpreter!.run(testInput, testOutput);
          print('✅ Classifier test successful - model is working correctly');
        } catch (e, stackTrace) {
          print('❌ Classifier test failed: $e');
          print('📚 Stack trace: $stackTrace');
        }
      } catch (e) {
        print('❌ Failed to get classifier tensor information: $e');
        _isInitialized = false;
        return false;
      }

      // Load YAMNet base model for embeddings
      try {
        print('📦 Loading YAMNet base model from assets: $_yamnetBaseModelPath');
        final yamData = await rootBundle.load(_yamnetBaseModelPath);
        final yamBytes = yamData.buffer.asUint8List();
        final yamOptions = InterpreterOptions()..threads = 2;
        _yamnetInterpreter =
            Interpreter.fromBuffer(yamBytes, options: yamOptions);

        final yamInputShape = _yamnetInterpreter!.getInputTensor(0).shape;
        final yamOutputShapes =
            _yamnetInterpreter!.getOutputTensors().map((t) => t.shape).toList();

        print('✅ YAMNet base model loaded successfully');
        print('📊 YAMNet input shape: $yamInputShape');
        print('📊 YAMNet output shapes: $yamOutputShapes');

        _isInitialized = true;
        return true;
      } catch (e) {
        print('❌ Failed to load YAMNet base model: $e');
        _isInitialized = false;
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ Error initializing YAMNet voice mood model: $e');
      print('📚 Stack trace: $stackTrace');
      _isInitialized = false;
      return false;
    }
  }

  /// Load mood categories from label_map.json
  Future<void> _loadLabelMap() async {
    try {
      final String labelMapJson = await rootBundle.loadString(_labelMapPath);
      final Map<String, dynamic> labelMap = json.decode(labelMapJson);
      
      if (labelMap.containsKey('classes') && labelMap['classes'] is List) {
        // Keep the original order from label_map.json because it must align with model output indices.
        final raw = List<String>.from(labelMap['classes'])
            .map((e) => e.toString().trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toList();

        // De-duplicate while preserving order
        final seen = <String>{};
        final ordered = <String>[];
        for (final m in raw) {
          if (!seen.contains(m)) {
            seen.add(m);
            ordered.add(m);
          }
        }

        _moodCategories = ordered;
        print('✅ Loaded ${_moodCategories.length} mood categories from label_map.json (kept output order)');
        print('📋 Model output labels: $_moodCategories');

        // Warn if supported moods are missing (we don't auto-add because that would break index alignment)
        final missing = _supportedMoods.where((m) => !_moodCategories.contains(m)).toList();
        if (missing.isNotEmpty) {
          print('⚠️ WARNING: label_map.json is missing supported moods: $missing');
        }
      } else {
        print('⚠️ Label map format unexpected, using default categories');
        // Keep default categories (includes calm/disgust/unknown) to preserve index assumptions.
      }
    } catch (e) {
      print('⚠️ Error loading label map, using default categories: $e');
      // Keep default categories if loading fails
    }
  }

  /// 🔹 1. Audio Preprocessing (MANDATORY)
  /// Convert mic audio to mono, resample to 16 kHz, normalize, trim silence
  Future<List<double>?> _preprocessAudio(String audioPath) async {
    try {
      // Decode audio → PCM (16 kHz mono, [-1, 1])
      final pcmSamples = await _decodeAudioToPCM(audioPath);
      if (pcmSamples == null || pcmSamples.length < 1000) {
        print('❌ Failed to decode audio or audio too short (${pcmSamples?.length ?? 0} samples)');
        return null;
      }

      // Calculate RMS before normalization to detect silence early
      double sumSq = 0.0;
      for (final s in pcmSamples) {
        sumSq += s * s;
      }
      final rmsBeforeNorm = math.sqrt(sumSq / pcmSamples.length);
      
      // Convert to float32 and normalize amplitude
      final maxAbs = pcmSamples.map((s) => s.abs()).reduce((a, b) => a > b ? a : b);
      if (maxAbs < 1e-10 || rmsBeforeNorm < 0.02) {
        print('❌ Audio is too quiet/silent (maxAbs=$maxAbs, RMS=$rmsBeforeNorm < 0.02)');
        return null;
      }

      // Normalize to [-1, 1]
      final normalized = pcmSamples.map((s) => (s / maxAbs).clamp(-1.0, 1.0)).toList();

      // Very light trimming - only remove extreme silence at very edges
      // Don't be aggressive - keep most of the audio
      final trimmed = _trimSilence(normalized);
      
      // Only reject if audio is extremely short after trimming (less than 1/4 of original)
      final minLength = (pcmSamples.length * 0.25).round().clamp(1000, 5000);
      if (trimmed.length < minLength) {
        print('⚠️ Audio short after trimming (${trimmed.length} < $minLength), but keeping it');
        // Don't reject - return trimmed anyway, let silence detection handle it
        return trimmed.length >= 1000 ? trimmed : normalized;
      }

      return trimmed;
    } catch (e) {
      print('❌ Error preprocessing audio: $e');
      return null;
    }
  }

  /// Trim silence from beginning and end of audio
  List<double> _trimSilence(List<double> samples) {
    // Very low threshold - only trim extreme silence, not quiet speech
    const double silenceThreshold = 0.001;
    int start = 0;
    int end = samples.length;

    // Find first non-silent sample (only trim if it's truly silent)
    for (int i = 0; i < samples.length && i < samples.length * 0.1; i++) {
      if (samples[i].abs() > silenceThreshold) {
        start = i;
        break;
      }
    }

    // Find last non-silent sample (only trim if it's truly silent)
    for (int i = samples.length - 1; i >= samples.length * 0.9 && i >= 0; i--) {
      if (samples[i].abs() > silenceThreshold) {
        end = i + 1;
        break;
      }
    }

    // Don't trim too aggressively - keep at least 80% of original audio
    final minLength = (samples.length * 0.8).round();
    if ((end - start) < minLength) {
      return samples; // Return original if trimming would remove too much
    }

    return samples.sublist(start, end);
  }

  /// Silence detector: If RMS < threshold → return "no_speech"
  String? _detectSilence(List<double> samples) {
    if (samples.isEmpty) return 'no_speech';

    // Calculate RMS energy
    double sumSq = 0.0;
    for (final s in samples) {
      sumSq += s * s;
    }
    final rms = math.sqrt(sumSq / samples.length);

    // Calculate max amplitude
    final maxAmplitude = samples.map((s) => s.abs()).reduce((a, b) => a > b ? a : b);

    // Calculate variance (to detect static/uniform audio vs actual speech)
    final mean = samples.fold(0.0, (a, b) => a + b) / samples.length;
    double variance = 0.0;
    for (final s in samples) {
      variance += (s - mean) * (s - mean);
    }
    variance /= samples.length;
    final stdDev = math.sqrt(variance);

    print('📊 Audio RMS: ${rms.toStringAsFixed(6)}, maxAmplitude: ${maxAmplitude.toStringAsFixed(6)}, stdDev: ${stdDev.toStringAsFixed(6)}, threshold: $_silenceThreshold');

    // Reject if ANY of these conditions are true (very strict silence detection):
    // 1. RMS is too low (actual silence) - use threshold
    // 2. Max amplitude is very low (very quiet) - stricter
    // 3. Standard deviation is very low (static/uniform audio, not speech) - stricter
    // 4. RMS is low AND max amplitude is low (double check for silence)
    final isSilence = rms < _silenceThreshold || 
                     maxAmplitude < 0.1 || 
                     stdDev < 0.02 || 
                     (rms < 0.1 && maxAmplitude < 0.2);
    
    if (isSilence) {
      print('🔇 Silence detected - REJECTING (RMS=$rms < $_silenceThreshold, maxAmplitude=$maxAmplitude < 0.1, stdDev=$stdDev < 0.02)');
      return 'no_speech';
    }

    print('✅ Speech detected (RMS=$rms >= $_silenceThreshold, maxAmplitude=$maxAmplitude >= 0.1, stdDev=$stdDev >= 0.02)');
    return null; // Not silence
  }

  /// 🔹 2. Feature Extraction: Use YAMNet to extract embeddings
  /// Get (T, 1024) embeddings, compute mean across time → (1024,)
  Future<List<double>?> _extractYamnetEmbeddings(List<double> samples) async {
    try {
      if (_yamnetInterpreter == null) {
        print('❌ YAMNet interpreter not initialized');
        return null;
      }

      final inputTensor = _yamnetInterpreter!.getInputTensor(0);
      final inputSize = inputTensor.shape.fold(1, (a, b) => a * b);

      // Prepare input buffer (float32)
      final Float32List inputBuffer = Float32List(inputSize);
      final int copyCount = math.min(samples.length, inputSize);
      for (int i = 0; i < copyCount; i++) {
        inputBuffer[i] = samples[i].toDouble();
      }

      // Get output tensor shape [frames, 1024]
      final outputTensor = _yamnetInterpreter!.getOutputTensor(0);
      final embShape = outputTensor.shape;
      if (embShape.length != 2 || embShape[1] != 1024) {
        print('❌ YAMNet: unexpected embedding tensor shape $embShape');
        return null;
      }

      final frames = embShape[0];
      final dim = embShape[1];

      // Allocate output buffer [frames, 1024]
      final embeddingOutput = List.generate(
        frames,
        (_) => List<double>.filled(dim, 0.0),
      );

      // Run YAMNet
      _yamnetInterpreter!.run(inputBuffer, embeddingOutput);

      // Average over frames to get single 1024-dim embedding
      final avg = List<double>.filled(dim, 0.0);
      for (final row in embeddingOutput) {
        for (int d = 0; d < dim && d < row.length; d++) {
          avg[d] += row[d];
        }
      }
      for (int d = 0; d < dim; d++) {
        avg[d] /= frames;
      }

      print('✅ YAMNet embedding extracted: ${avg.length} dimensions from $frames frames');
      return avg;
    } catch (e, stackTrace) {
      print('❌ Error extracting YAMNet embeddings: $e');
      print('📚 Stack trace: $stackTrace');
      return null;
    }
  }

  /// 🔹 3. Classifier Inference: Load yamnet_classifier.tflite
  /// Output is softmax probability vector
  Future<Map<String, double>?> _classifyMood(List<double> embedding) async {
    try {
      if (_interpreter == null) {
        print('❌ Classifier interpreter not initialized');
        return null;
      }

      // Normalize embedding (L2 normalization)
      final normalizedEmbedding = _normalizeEmbedding(embedding);

      // Prepare classifier input
      final classifierInputTensor = _interpreter!.getInputTensor(0);
      final inputType = classifierInputTensor.type.toString();

      dynamic classifierInput;
      if (inputType.contains('int8')) {
        final scale = classifierInputTensor.params.scale;
        final zeroPoint = classifierInputTensor.params.zeroPoint;
        final quantized = normalizedEmbedding
            .map((v) => ((v / scale) + zeroPoint).round().clamp(-128, 127))
            .toList();
        classifierInput = [quantized];
      } else {
        classifierInput = [normalizedEmbedding];
      }

      // Run classifier
      final outputTensor = _interpreter!.getOutputTensor(0);
      final outputType = outputTensor.type.toString();
      final outputSize = outputTensor.shape.fold(1, (a, b) => a * b);

      dynamic rawOutput;
      if (outputType.contains('int8')) {
        rawOutput = [List<int>.filled(outputSize, 0)];
      } else {
        rawOutput = [List<double>.filled(outputSize, 0.0)];
      }

      _interpreter!.run(classifierInput, rawOutput);

      // Convert to probabilities
      List<double> logits;
      if (outputType.contains('int8')) {
        final scale = outputTensor.params.scale;
        final zeroPoint = outputTensor.params.zeroPoint;
        final ints = (rawOutput as List<List<int>>)[0];
        logits = ints.map((v) => (v - zeroPoint) * scale.toDouble()).toList();
      } else {
        logits = (rawOutput as List<List<double>>)[0];
      }

      // Apply softmax to get probabilities
      final probs = _applySoftmax(logits);

      // Map to mood categories (ALL labels, preserving model output mapping)
      final moodProbs = <String, double>{};
      for (int i = 0; i < _moodCategories.length && i < probs.length; i++) {
        final mood = _moodCategories[i];
        moodProbs[mood] = probs[i];
      }

      print('📊 Classifier probabilities: ${moodProbs.map((k, v) => MapEntry(k, (v * 100).toStringAsFixed(1) + '%'))}');
      return moodProbs;
    } catch (e, stackTrace) {
      print('❌ Error classifying mood: $e');
      print('📚 Stack trace: $stackTrace');
      return null;
    }
  }

  /// Pick the best supported mood from a probability map.
  String _bestSupportedMood(Map<String, double> probs) {
    String best = 'neutral';
    double bestP = -1.0;
    for (final m in _supportedMoods) {
      final p = probs[m] ?? 0.0;
      if (p > bestP) {
        bestP = p;
        best = m;
      }
    }
    return best;
  }

  /// Option C mapping: if classifier predicts unknown (or any unsupported),
  /// map it to the closest among the supported moods.
  String _mapNonSupportedToSupported(String predicted, Map<String, double> probs) {
    final p = predicted.toLowerCase();

    // If already supported (including calm and disgust), return as-is.
    if (_supportedMoods.contains(p)) return p;

    // Unknown or any other non-supported label → best supported.
    return _bestSupportedMood(probs);
  }

  /// Extract audio features from PCM samples (pitch, energy, spectral features)
  AudioFeatures _extractAudioFeatures(List<double> samples) {
    if (samples.isEmpty) {
      return AudioFeatures(
        pitch: 0.0,
        energy: 0.0,
        spectralCentroid: 0.0,
        zeroCrossingRate: 0.0,
        energyVariability: 0.0,
        spectralRolloff: 0.0,
        spectralFlux: 0.0,
      );
    }

    const int sampleRate = 16000;
    const int frameSize = 512;
    const int hopSize = 256;

    // 1. Energy (RMS)
    double sumSq = 0.0;
    for (final s in samples) {
      sumSq += s * s;
    }
    final energy = math.sqrt(sumSq / samples.length);

    // 2. Zero Crossing Rate
    int zeroCrossings = 0;
    for (int i = 1; i < samples.length; i++) {
      if ((samples[i] >= 0) != (samples[i - 1] >= 0)) {
        zeroCrossings++;
      }
    }
    final zeroCrossingRate = zeroCrossings / samples.length;

    // 3. Pitch estimation (autocorrelation-based)
    final pitch = _estimatePitch(samples, sampleRate);

    // 4. Spectral features (simplified - using frame-based analysis)
    final frames = <List<double>>[];
    for (int i = 0; i < samples.length - frameSize; i += hopSize) {
      frames.add(samples.sublist(i, i + frameSize));
    }

    if (frames.isEmpty) {
      frames.add(samples.length >= frameSize 
          ? samples.sublist(0, frameSize) 
          : samples + List.filled(frameSize - samples.length, 0.0));
    }

    double spectralCentroidSum = 0.0;
    double spectralRolloffSum = 0.0;
    double spectralFluxSum = 0.0;
    List<double>? prevMagnitude;

    for (final frame in frames) {
      // Apply window
      final windowed = _applyHammingWindow(frame);
      
      // Compute FFT magnitude spectrum (simplified)
      final fft = _computeDFT(windowed, frameSize);
      final magnitude = fft.map((c) {
        final real = c[0];
        final imag = c[1];
        return math.sqrt(real * real + imag * imag);
      }).toList();

      // Spectral Centroid (brightness)
      double weightedSum = 0.0;
      double magnitudeSum = 0.0;
      for (int i = 0; i < magnitude.length; i++) {
        final freq = i * sampleRate / frameSize;
        weightedSum += freq * magnitude[i];
        magnitudeSum += magnitude[i];
      }
      if (magnitudeSum > 0) {
        spectralCentroidSum += weightedSum / magnitudeSum;
      }

      // Spectral Rolloff (85% energy)
      double cumSum = 0.0;
      final totalEnergy = magnitude.fold(0.0, (a, b) => a + b);
      double rolloffFreq = 0.0;
      for (int i = 0; i < magnitude.length; i++) {
        cumSum += magnitude[i];
        if (cumSum >= 0.85 * totalEnergy) {
          rolloffFreq = i * sampleRate / frameSize;
          break;
        }
      }
      spectralRolloffSum += rolloffFreq;

      // Spectral Flux (rate of change)
      if (prevMagnitude != null) {
        double flux = 0.0;
        for (int i = 0; i < math.min(magnitude.length, prevMagnitude.length); i++) {
          final diff = magnitude[i] - prevMagnitude[i];
          if (diff > 0) flux += diff;
        }
        spectralFluxSum += flux;
      }
      prevMagnitude = magnitude;
    }

    final frameCount = frames.length.toDouble();
    final spectralCentroid = frameCount > 0 ? spectralCentroidSum / frameCount : 0.0;
    final spectralRolloff = frameCount > 0 ? spectralRolloffSum / frameCount : 0.0;
    final spectralFlux = frameCount > 1 ? spectralFluxSum / (frameCount - 1) : 0.0;

    // 5. Energy Variability (standard deviation of frame energies)
    final frameEnergies = <double>[];
    for (final frame in frames) {
      double frameSumSq = 0.0;
      for (final s in frame) {
        frameSumSq += s * s;
      }
      frameEnergies.add(math.sqrt(frameSumSq / frame.length));
    }
    final energyMean = frameEnergies.fold(0.0, (a, b) => a + b) / frameEnergies.length;
    final energyVariance = frameEnergies.fold(0.0, (sum, e) => sum + (e - energyMean) * (e - energyMean)) / frameEnergies.length;
    final energyVariability = math.sqrt(energyVariance);

    return AudioFeatures(
      pitch: pitch,
      energy: energy,
      spectralCentroid: spectralCentroid,
      zeroCrossingRate: zeroCrossingRate,
      energyVariability: energyVariability,
      spectralRolloff: spectralRolloff,
      spectralFlux: spectralFlux,
    );
  }

  /// Detect mood from audio features using rule-based logic
  VoiceMoodResult _detectMoodFromFeatures(AudioFeatures features) {
    String mood = 'neutral';
    double confidence = 0.5;

    // Rule-based mood detection based on audio features
    
    // ANGRY: High pitch, high energy, high ZCR, high spectral centroid
    if (features.pitch > 200 && features.energy > 0.1 && 
        features.zeroCrossingRate > 0.15 && features.spectralCentroid > 2000) {
      mood = 'angry';
      confidence = 0.7;
    }
    // HAPPY: High pitch, moderate-high energy, moderate ZCR, high spectral centroid
    else if (features.pitch > 180 && features.energy > 0.08 && 
             features.spectralCentroid > 1800) {
      mood = 'happy';
      confidence = 0.7;
    }
    // SAD: Low pitch, low energy, low ZCR, low spectral centroid
    else if (features.pitch < 120 && features.energy < 0.05 && 
             features.zeroCrossingRate < 0.08 && features.spectralCentroid < 1500) {
      mood = 'sad';
      confidence = 0.7;
    }
    // FEAR: High pitch, high energy variability, high spectral flux
    else if (features.pitch > 200 && features.energyVariability > 0.02 && 
             features.spectralFlux > 0.5) {
      mood = 'fear';
      confidence = 0.6;
    }
    // SURPRISE: Very high pitch, high energy, high spectral flux
    else if (features.pitch > 250 && features.energy > 0.1 && 
             features.spectralFlux > 0.6) {
      mood = 'surprise';
      confidence = 0.6;
    }
    // NEUTRAL: Moderate values across all features
    else {
      mood = 'neutral';
      confidence = 0.5;
    }

    print('🎵 Feature-based mood: $mood (pitch=${features.pitch.toStringAsFixed(1)}Hz, energy=${features.energy.toStringAsFixed(4)}, zcr=${features.zeroCrossingRate.toStringAsFixed(4)})');

    return VoiceMoodResult(
      mood: mood,
      confidence: confidence,
      allProbabilities: {mood: confidence},
    );
  }

  /// Estimate pitch using autocorrelation
  double _estimatePitch(List<double> samples, int sampleRate) {
    if (samples.length < 512) return 0.0;

    // Use a subset for autocorrelation
    final windowSize = math.min(2048, samples.length);
    final window = samples.sublist(0, windowSize);

    // Autocorrelation
    final autocorr = <double>[];
    for (int lag = 0; lag < windowSize ~/ 2; lag++) {
      double sum = 0.0;
      for (int i = 0; i < windowSize - lag; i++) {
        sum += window[i] * window[i + lag];
      }
      autocorr.add(sum);
    }

    // Find peak (excluding first few samples)
    double maxVal = 0.0;
    int maxIdx = 0;
    for (int i = sampleRate ~/ 800; i < autocorr.length; i++) {
      if (autocorr[i] > maxVal) {
        maxVal = autocorr[i];
        maxIdx = i;
      }
    }

    if (maxIdx > 0) {
      return sampleRate / maxIdx;
    }
    return 0.0;
  }

  /// Apply Hamming window
  List<double> _applyHammingWindow(List<double> frame) {
    final windowed = <double>[];
    for (int i = 0; i < frame.length; i++) {
      final windowValue = 0.54 - 0.46 * math.cos(2 * math.pi * i / (frame.length - 1));
      windowed.add(frame[i] * windowValue);
    }
    return windowed;
  }

  /// Compute DFT (Discrete Fourier Transform)
  List<List<double>> _computeDFT(List<double> samples, int n) {
    final result = <List<double>>[];
    for (int k = 0; k < n; k++) {
      double real = 0.0;
      double imag = 0.0;
      for (int i = 0; i < samples.length; i++) {
        final angle = 2 * math.pi * k * i / samples.length;
        real += samples[i] * math.cos(angle);
        imag -= samples[i] * math.sin(angle);
      }
      result.add([real, imag]);
    }
    return result;
  }

  /// 🔹 5. Prediction Smoothing: Temporal smoothing with majority vote
  /// Store last 5 predictions, always return one of the 6 moods
  String _smoothPrediction(String mood) {
    // Filter out "unknown" - only keep valid moods
    if (!_supportedMoods.contains(mood)) {
      mood = 'neutral'; // Default to neutral if invalid mood
    }
    
    // Add new prediction to history
    _predictionHistory.add(mood);
    
    // Keep only last N predictions
    if (_predictionHistory.length > _historySize) {
      _predictionHistory.removeAt(0);
    }

    // Count occurrences of each mood (only supported moods)
    final counts = <String, int>{};
    for (final m in _predictionHistory) {
      if (_supportedMoods.contains(m)) {
        counts[m] = (counts[m] ?? 0) + 1;
      }
    }

    // Find mood with most votes and second most votes
    String bestMood = 'neutral'; // Default fallback
    int maxCount = 0;
    String secondBestMood = 'neutral';
    int secondMaxCount = 0;
    
    for (final entry in counts.entries) {
      if (entry.value > maxCount) {
        secondMaxCount = maxCount;
        secondBestMood = bestMood;
        maxCount = entry.value;
        bestMood = entry.key;
      } else if (entry.value > secondMaxCount && entry.key != bestMood) {
        secondMaxCount = entry.value;
        secondBestMood = entry.key;
      }
    }

    // If same mood appears too many times (4+ out of 5), use second most common for variation
    // This prevents always returning the same mood
    if (maxCount >= 4 && secondMaxCount >= 2 && secondBestMood != bestMood && secondBestMood != 'neutral') {
      print('⚠️ Same mood "$bestMood" appears $maxCount/$_historySize times - using second most common "$secondBestMood" ($secondMaxCount times) for variation');
      return secondBestMood;
    }

    // Always return a mood (never "unknown")
    if (maxCount >= _majorityThreshold) {
      print('✅ Smoothed prediction: $bestMood (appears $maxCount/$_historySize times)');
    } else {
      print('⚠️ No clear majority (best: $bestMood with $maxCount votes), using best available mood');
    }
    return bestMood;
  }

  /// 🔹 Main Detection Pipeline
  @override
  Future<VoiceMoodResult> detectMoodFromAudio(String audioPath) async {
    // Initialize models if needed
    if (!_isInitialized || _interpreter == null || _yamnetInterpreter == null) {
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
      // Basic file checks
      final audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        return VoiceMoodResult(
          mood: 'neutral',
          confidence: 0.0,
          error: 'Audio file not found',
        );
      }

      final fileSize = await audioFile.length();
      if (fileSize < 4000) {
        return VoiceMoodResult(
          mood: 'neutral',
          confidence: 0.0,
          error: 'Recording too short',
        );
      }

      // 🔹 1. Audio Preprocessing
      final processedSamples = await _preprocessAudio(audioPath);
      if (processedSamples == null) {
        // Audio preprocessing failed (likely silence or too short)
        return VoiceMoodResult(
          mood: 'neutral',
          confidence: 0.0,
          error: 'No speech detected. Please speak clearly.',
        );
      }

      // 🔹 Silence Detection: Reject silence - don't detect mood when user doesn't speak
      final silenceResult = _detectSilence(processedSamples);
      if (silenceResult != null) {
        print('🔇 Silence detected - rejecting mood detection');
        // Clear recent moods history when silence is detected
        _recentMoods.clear();
        _predictionHistory.clear();
        return VoiceMoodResult(
          mood: 'neutral', // Required field, but error will indicate rejection
          confidence: 0.0,
          error: 'No speech detected. Please speak clearly.',
        );
      }

      // 🔹 2. Extract YAMNet Embeddings
      final embedding = await _extractYamnetEmbeddings(processedSamples);
      if (embedding == null || embedding.length != 1024) {
        // Use feature-based detection as fallback
        print('⚠️ Failed to extract embeddings - using feature-based detection');
        final audioFeatures = _extractAudioFeatures(processedSamples);
        final featureBasedMood = _detectMoodFromFeatures(audioFeatures);
        print('✅ Feature-based mood detection: ${featureBasedMood.mood} (confidence: ${(featureBasedMood.confidence * 100).toStringAsFixed(1)}%)');
        return featureBasedMood;
      }

      // 🔹 3. Classify Mood
      final moodProbs = await _classifyMood(embedding);
      if (moodProbs == null || moodProbs.isEmpty) {
        // Use feature-based detection as fallback
        print('⚠️ Failed to classify mood - using feature-based detection');
        final audioFeatures = _extractAudioFeatures(processedSamples);
        final featureBasedMood = _detectMoodFromFeatures(audioFeatures);
        print('✅ Feature-based mood detection: ${featureBasedMood.mood} (confidence: ${(featureBasedMood.confidence * 100).toStringAsFixed(1)}%)');
        return featureBasedMood;
      }

      // Find mood with highest probability
      final sortedMoods = moodProbs.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      if (sortedMoods.isEmpty) {
    return VoiceMoodResult(
      mood: 'neutral',
      confidence: 0.0,
          error: 'No mood predictions',
        );
      }

      final bestMood = sortedMoods[0].key;
      final maxProb = sortedMoods[0].value;
      
      // Compute supported top-2 (used for repetition avoidance + happy dominance guard)
      final supportedEntries = _supportedMoods
          .map((m) => MapEntry(m, moodProbs[m] ?? 0.0))
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final bestSupportedMood = supportedEntries.isNotEmpty ? supportedEntries[0].key : 'neutral';
      final bestSupportedProb = supportedEntries.isNotEmpty ? supportedEntries[0].value : 0.0;
      final secondSupportedMood = supportedEntries.length > 1 ? supportedEntries[1].key : null;
      final secondSupportedProb = supportedEntries.length > 1 ? supportedEntries[1].value : 0.0;

      // If model confidence is very low (< 15%), use feature-based detection
      if (maxProb < 0.15) {
        print('⚠️ Model confidence too low (${(maxProb * 100).toStringAsFixed(1)}% < 15%) - using feature-based detection');
        final audioFeatures = _extractAudioFeatures(processedSamples);
        final featureBasedMood = _detectMoodFromFeatures(audioFeatures);
        print('✅ Feature-based mood detection: ${featureBasedMood.mood} (confidence: ${(featureBasedMood.confidence * 100).toStringAsFixed(1)}%)');
        return featureBasedMood;
      }

      // Option C: Map calm/disgust/unknown (or any unsupported) to the closest supported mood.
      String finalMood = _mapNonSupportedToSupported(bestMood, moodProbs);
      // Confidence should be the probability of the final (mapped) mood.
      double finalConfidence = moodProbs[finalMood] ?? 0.0;

      // If the model is confident in non-supported but supported are super low, prefer the best supported anyway.
      if (finalConfidence < 0.08 && bestSupportedProb > finalConfidence) {
        finalMood = bestSupportedMood;
        finalConfidence = bestSupportedProb;
      }

      // Happy dominance guard: if happy wins but is not clearly separated, try 2nd supported or features.
      if (finalMood == 'happy' &&
          secondSupportedMood != null &&
          (finalConfidence < 0.55 || (finalConfidence - secondSupportedProb) < 0.10) &&
          secondSupportedProb > 0.12) {
        print('⚠️ "happy" not strongly separated (p=${(finalConfidence * 100).toStringAsFixed(1)}%, second=${(secondSupportedProb * 100).toStringAsFixed(1)}%) - using second supported "$secondSupportedMood"');
        finalMood = secondSupportedMood;
        finalConfidence = secondSupportedProb;
      }

      // 🔹 Avoid always returning the same mood - check if this mood appears too often
      final moodCount = _predictionHistory.where((m) => m == finalMood).length;
      final isMoodTooCommon = moodCount >= 2; // If 2+ out of 5 are the same mood
      
      // If the same mood is appearing too often, use second highest probability instead
      if (isMoodTooCommon && secondSupportedMood != null && secondSupportedMood != finalMood) {
        // Check if second mood has reasonable confidence (> 8%)
        if (secondSupportedProb > 0.08) {
          print('⚠️ "$finalMood" appears too often in history ($moodCount/$_historySize) - using second supported "$secondSupportedMood" (${(secondSupportedProb * 100).toStringAsFixed(1)}%) instead');
          finalMood = secondSupportedMood;
          finalConfidence = secondSupportedProb;
    } else {
          // If second mood confidence is too low, use feature-based detection
          print('⚠️ "$finalMood" appears too often but second mood confidence too low - using feature-based detection');
          final audioFeatures = _extractAudioFeatures(processedSamples);
          final featureBasedMood = _detectMoodFromFeatures(audioFeatures);
          if (featureBasedMood.mood != finalMood && _supportedMoods.contains(featureBasedMood.mood)) {
            print('✅ Feature-based mood detection: ${featureBasedMood.mood} (confidence: ${(featureBasedMood.confidence * 100).toStringAsFixed(1)}%)');
            return featureBasedMood;
          }
        }
      }
      
      // Special handling for "neutral" - be more aggressive in avoiding it
      if (finalMood == 'neutral') {
        final neutralCount = _predictionHistory.where((m) => m == 'neutral').length;
        // If neutral appears 2+ times, always try to use second highest or feature-based
        if (neutralCount >= 2 && secondSupportedMood != null && secondSupportedMood != 'neutral') {
          if (secondSupportedProb > 0.08) {
            print('⚠️ "neutral" appears too often ($neutralCount/$_historySize) - using second supported "$secondSupportedMood" (${(secondSupportedProb * 100).toStringAsFixed(1)}%)');
            finalMood = secondSupportedMood;
            finalConfidence = secondSupportedProb;
    } else {
            // Use feature-based detection to avoid neutral
            print('⚠️ "neutral" appears too often - using feature-based detection to avoid repetition');
            final audioFeatures = _extractAudioFeatures(processedSamples);
            final featureBasedMood = _detectMoodFromFeatures(audioFeatures);
            if (featureBasedMood.mood != 'neutral' && _supportedMoods.contains(featureBasedMood.mood)) {
              print('✅ Feature-based mood detection: ${featureBasedMood.mood} (confidence: ${(featureBasedMood.confidence * 100).toStringAsFixed(1)}%)');
              return featureBasedMood;
            }
          }
        }
      }

      // 🔹 6. Emotion Bias Protection
      // If "sad" is predicted but confidence < 0.6 → use feature-based detection
      if (finalMood == 'sad' && finalConfidence < _sadConfidenceThreshold) {
        print('⚠️ "sad" predicted with low confidence (${(finalConfidence * 100).toStringAsFixed(1)}% < ${(_sadConfidenceThreshold * 100).toStringAsFixed(0)}%) - using feature-based detection');
        final audioFeatures = _extractAudioFeatures(processedSamples);
        final featureBasedMood = _detectMoodFromFeatures(audioFeatures);
        print('✅ Feature-based mood detection: ${featureBasedMood.mood} (confidence: ${(featureBasedMood.confidence * 100).toStringAsFixed(1)}%)');
        return featureBasedMood;
      }

      // Track recent moods to avoid repetition
      _recentMoods.add(finalMood);
      if (_recentMoods.length > _recentMoodsHistory) {
        _recentMoods.removeAt(0);
      }
      
      // If the same mood appears in all recent detections, use second highest instead
      if (_recentMoods.length == _recentMoodsHistory && _recentMoods.every((m) => m == finalMood)) {
        if (secondSupportedMood != null && secondSupportedMood != finalMood && secondSupportedProb > 0.08) {
          print('⚠️ Same mood "$finalMood" detected ${_recentMoodsHistory} times in a row - using second supported "$secondSupportedMood" (${(secondSupportedProb * 100).toStringAsFixed(1)}%) for variation');
          finalMood = secondSupportedMood;
          finalConfidence = secondSupportedProb;
          // Update recent moods
          _recentMoods[_recentMoods.length - 1] = finalMood;
    } else {
          // Use feature-based detection for variation
          print('⚠️ Same mood "$finalMood" detected ${_recentMoodsHistory} times in a row - using feature-based detection for variation');
          final audioFeatures = _extractAudioFeatures(processedSamples);
          final featureBasedMood = _detectMoodFromFeatures(audioFeatures);
          if (featureBasedMood.mood != finalMood && _supportedMoods.contains(featureBasedMood.mood)) {
            print('✅ Feature-based mood detection: ${featureBasedMood.mood} (confidence: ${(featureBasedMood.confidence * 100).toStringAsFixed(1)}%)');
            _recentMoods[_recentMoods.length - 1] = featureBasedMood.mood;
            return featureBasedMood;
          }
        }
      }

      // 🔹 5. Prediction Smoothing: Temporal smoothing with majority vote
      final smoothedMood = _smoothPrediction(finalMood);

      // Final result - always return one of the 6 moods
      print('✅ Final mood: $smoothedMood (confidence: ${(finalConfidence * 100).toStringAsFixed(1)}%)');
      return VoiceMoodResult(
        mood: smoothedMood,
        confidence: finalConfidence,
        allProbabilities: moodProbs,
      );
    } catch (e, stackTrace) {
      print('❌ Error detecting mood: $e');
      print('📚 Stack trace: $stackTrace');
    return VoiceMoodResult(
      mood: 'neutral',
      confidence: 0.0,
        error: 'Error processing audio: $e',
      );
    }
  }

  @override
  Future<VoiceMoodResult> analyzeMultipleResponses(
    List<String> audioPaths,
  ) async {
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
      moodScores[result.mood] =
          (moodScores[result.mood] ?? 0.0) + result.confidence;
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
      allProbabilities: moodScores.map(
        (k, v) => MapEntry(k, v / totalConfidence),
      ),
    );
  }

  /// Decode audio file (M4A) to PCM samples
  Future<List<double>?> _decodeAudioToPCM(String audioPath) async {
    try {
      const channel =
          MethodChannel('com.example.ai_based_content_recommendation_system/audio_decoder');
      print('🔄 Requesting PCM samples from native decoder...');

      final List<dynamic>? result = await channel.invokeMethod<List<dynamic>>(
        'decodeAudioToPCM',
        {
          'audioPath': audioPath,
          'sampleRate': 16000,
        },
      );

      if (result == null || result.isEmpty) {
        print('❌ Native decoder returned empty result');
        return null;
      }
      
      final samples = result.map((e) => (e as num).toDouble()).toList();
      print('✅ Received ${samples.length} PCM samples from native decoder');
      return samples;
    } catch (e, stackTrace) {
      print('❌ Error decoding audio via native decoder: $e');
      print('📚 Stack trace: $stackTrace');
      return null;
    }
  }

  /// Helper method: Create test input for model verification during initialization
  List<dynamic> _createTestInput(List<int> shape, int size, dynamic tensorType) {
    final isQuantized = tensorType.toString().contains('int8') || 
                       tensorType.toString().contains('uint8');
    if (isQuantized) {
      final flatList = List.generate(size, (i) => ((i % 100) / 100.0 - 0.5) * 127).map((v) => v.round().clamp(-128, 127)).toList();
      return _reshapeListInt8(flatList, shape);
          } else {
      final flatList = List.generate(size, (i) => (i % 100) / 100.0 - 0.5);
      return _reshapeList(flatList, shape);
    }
  }

  /// Helper method: Reshape list to match tensor shape (for float32)
  dynamic _reshapeList(List<double> list, List<int> shape) {
    if (shape.length == 1) {
      return list;
    } else if (shape.length == 2) {
      final rows = shape[0];
      final cols = shape[1];
      final result = <List<double>>[];
      for (int i = 0; i < rows; i++) {
        final start = i * cols;
        final end = (start + cols).clamp(0, list.length);
        result.add(list.sublist(start, end));
      }
      return result;
    } else if (shape.length == 3) {
      final dim0 = shape[0];
      final dim1 = shape[1];
      final dim2 = shape[2];
      final result = <List<List<double>>>[];
      for (int i = 0; i < dim0; i++) {
        final frame = <List<double>>[];
        for (int j = 0; j < dim1; j++) {
          final start = (i * dim1 * dim2) + (j * dim2);
          final end = (start + dim2).clamp(0, list.length);
          frame.add(list.sublist(start, end));
        }
        result.add(frame);
      }
      return result;
    } else if (shape.length == 4) {
      final dim0 = shape[0];
      final dim1 = shape[1];
      final dim2 = shape[2];
      final dim3 = shape[3];
      final result = <List<List<List<double>>>>[];
      for (int i = 0; i < dim0; i++) {
        final batch = <List<List<double>>>[];
        for (int j = 0; j < dim1; j++) {
          final row = <List<double>>[];
          for (int k = 0; k < dim2; k++) {
            final start = (i * dim1 * dim2 * dim3) + (j * dim2 * dim3) + (k * dim3);
            final end = (start + dim3).clamp(0, list.length);
            row.add(list.sublist(start, end));
          }
          batch.add(row);
        }
        result.add(batch);
      }
      return result;
    }
    return list;
  }

  /// Helper method: Reshape int8 list to match tensor shape
  dynamic _reshapeListInt8(List<int> list, List<int> shape) {
    if (shape.length == 1) {
      return list;
    } else if (shape.length == 2) {
      final rows = shape[0];
      final cols = shape[1];
      final result = <List<int>>[];
      for (int i = 0; i < rows; i++) {
        final start = i * cols;
        final end = (start + cols).clamp(0, list.length);
        result.add(list.sublist(start, end));
      }
      return result;
    } else if (shape.length == 3) {
      final dim0 = shape[0];
      final dim1 = shape[1];
      final dim2 = shape[2];
      final result = <List<List<int>>>[];
      for (int i = 0; i < dim0; i++) {
        final frame = <List<int>>[];
        for (int j = 0; j < dim1; j++) {
          final start = (i * dim1 * dim2) + (j * dim2);
          final end = (start + dim2).clamp(0, list.length);
          frame.add(list.sublist(start, end));
        }
        result.add(frame);
      }
      return result;
    } else if (shape.length == 4) {
      final dim0 = shape[0];
      final dim1 = shape[1];
      final dim2 = shape[2];
      final dim3 = shape[3];
      final result = <List<List<List<int>>>>[];
      for (int i = 0; i < dim0; i++) {
        final batch = <List<List<int>>>[];
        for (int j = 0; j < dim1; j++) {
          final row = <List<int>>[];
          for (int k = 0; k < dim2; k++) {
            final start = (i * dim1 * dim2 * dim3) + (j * dim2 * dim3) + (k * dim3);
            final end = (start + dim3).clamp(0, list.length);
            row.add(list.sublist(start, end));
          }
          batch.add(row);
        }
        result.add(batch);
      }
      return result;
    }
    return list;
  }

  /// Compute L2 norm of a vector
  double _computeL2Norm(List<double> vec) {
    double sumSq = 0.0;
    for (final v in vec) {
      sumSq += v * v;
    }
    return math.sqrt(sumSq);
  }

  /// Normalize embedding using L2 normalization (standard for YAMNet embeddings)
  List<double> _normalizeEmbedding(List<double> embedding) {
    final norm = _computeL2Norm(embedding);
    if (norm < 1e-8) {
      // If norm is too small, return zero vector (shouldn't happen with real audio)
      print('⚠️ Embedding norm too small: $norm, returning zero vector');
      return List.filled(embedding.length, 0.0);
    }
    return embedding.map((v) => v / norm).toList();
  }

  /// Apply softmax to convert raw scores to probabilities
  List<double> _applySoftmax(List<double> scores) {
    if (scores.isEmpty) return [];
    
    // Find max for numerical stability
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final minScore = scores.reduce((a, b) => a < b ? a : b);
    final scoreRange = maxScore - minScore;
    
    print('📊 Softmax input: min=$minScore, max=$maxScore, range=$scoreRange');
    
    // If all scores are very similar (within 0.1), the model output is essentially uniform
    if (scoreRange < 0.1) {
      print('⚠️ Logits are too uniform (range=$scoreRange), returning uniform probabilities');
      return List.filled(scores.length, 1.0 / scores.length);
    }
    
    // Compute exp(x - max) for each score to prevent overflow
    final expScores = scores.map((s) => math.exp((s - maxScore).clamp(-50.0, 50.0))).toList();
    
    // Sum of exponentials
    final sum = expScores.fold(0.0, (a, b) => a + b);
    
    if (sum == 0.0 || sum.isInfinite || sum.isNaN) {
      print('⚠️ Invalid sumExp: $sum, returning uniform probabilities');
      return List.filled(scores.length, 1.0 / scores.length);
    }
    
    // Normalize to probabilities
    final probabilities = expScores.map((exp) => exp / sum).toList();
    
    // Debug: Check if probabilities are uniform
    final probRange = probabilities.reduce((a, b) => a > b ? a : b) - probabilities.reduce((a, b) => a < b ? a : b);
    final maxProb = probabilities.reduce((a, b) => a > b ? a : b);
    print('📊 Softmax output: probRange=$probRange, maxProb=$maxProb');
    return probabilities;
  }

  @override
  void dispose() {
    _interpreter?.close();
    _yamnetInterpreter?.close();
    _interpreter = null;
    _yamnetInterpreter = null;
    _isInitialized = false;
    _predictionHistory.clear();
  }
}
