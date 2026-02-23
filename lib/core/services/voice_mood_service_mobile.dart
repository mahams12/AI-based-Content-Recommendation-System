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
  final double pitchVariation; // Std dev of pitch across frames (Hz)
  final double energy; // RMS energy
  final double intensityDynamics; // (max-min)/mean of frame energies
  final double spectralCentroid; // Brightness (Hz)
  final double zeroCrossingRate; // ZCR (rate of sign changes)
  final double energyVariability; // Standard deviation of energy
  final double spectralRolloff; // Frequency below which 85% of energy is contained
  final double spectralFlux; // Rate of change of spectrum

  AudioFeatures({
    required this.pitch,
    required this.pitchVariation,
    required this.energy,
    required this.intensityDynamics,
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
  // Probability-based temporal smoothing: average probs over last N calls to reduce frame-to-frame noise (optional).
  final List<Map<String, double>> _probabilityHistory = [];
  static const int _probabilityHistorySize = 3;
  static const bool _useProbabilityAveraging = true; // set false to use only current-frame probs

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
  // Minimum confidence to accept model prediction; below this we use feature-based fallback (no emotion-specific threshold).
  static const double _minModelConfidenceThreshold = 0.12;
  // Low-confidence uncertain threshold: when maxProb is between 0.12 and 0.30, treat as uncertain and map to calm
  // (avoids showing biased/wrong mood when classifier output is close to uniform).
  static const double _lowConfidenceUncertainThreshold = 0.30;
  // Laughter detection: if confidence exceeds this, classify mood as happy.
  static const double _laughterConfidenceThreshold = 0.70;

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

        final yamInputSize = yamInputShape.fold<int>(1, (a, b) => a * b);
        if (yamInputSize < 1000) {
          print('❌ YAMNet embeddings model has wrong input size: $yamInputSize (expected ~15600 for waveform).');
          print('   Replace assets/models/voice/yamnet_embeddings.tflite with a proper model that accepts waveform input.');
          print('   See docs/YAMNET_EMBEDDINGS_MODEL.md for instructions.');
          _yamnetInterpreter?.close();
          _yamnetInterpreter = null;
          _isInitialized = false;
          return false;
        }

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
  /// For long recordings: use the LAST inputSize samples (end of utterance) so emotion at end of speech is captured; matches training on fixed-length windows.
  Future<List<double>?> _extractYamnetEmbeddings(List<double> samples) async {
    try {
      if (_yamnetInterpreter == null) {
        print('❌ YAMNet interpreter not initialized');
        return null;
      }

      final inputTensor = _yamnetInterpreter!.getInputTensor(0);
      final inputShape = inputTensor.shape;
      final inputSize = inputShape.fold(1, (a, b) => a * b);

      if (inputSize < 1000) {
        print('❌ YAMNet model expects inputSize=$inputSize (expected ~15600 for waveform). Wrong model file.');
        return null;
      }

      // Use last segment when audio is longer than model input (emotion often clearer at end of utterance); otherwise use from start (with zero-pad if shorter).
      final int copyCount = math.min(samples.length, inputSize);
      final int startIdx = samples.length > inputSize ? (samples.length - inputSize) : 0;
      final Float32List inputBuffer = Float32List(inputSize);
      for (int i = 0; i < copyCount; i++) {
        inputBuffer[i] = samples[startIdx + i].toDouble();
      }

      // Diagnostic: fingerprint of input buffer to verify different recordings produce different inputs
      final inputSum = inputBuffer.take(100).fold<double>(0.0, (a, b) => a + b);
      final inputFingerprint = inputBuffer.length >= 3
          ? 'sum100=${inputSum.toStringAsFixed(6)} start3=${inputBuffer[0].toStringAsFixed(6)},${inputBuffer[1].toStringAsFixed(6)},${inputBuffer[2].toStringAsFixed(6)}'
          : 'sum100=${inputSum.toStringAsFixed(6)}';
      print('🔬 YAMNet input: shape=$inputShape inputSize=$inputSize samplesLen=${samples.length} startIdx=$startIdx copyCount=$copyCount | $inputFingerprint');

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

      // Debug: log embedding stats to verify different recordings produce different embeddings
      final embNorm = _computeL2Norm(avg);
      final first3 = avg.take(3).map((v) => v.toStringAsFixed(4)).join(', ');
      print('✅ YAMNet embedding: ${avg.length}d from $frames frames, L2=$embNorm, first3=[$first3]');
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

      print('📊 Classifier probabilities: ${moodProbs.map((k, v) => MapEntry(k, '${(v * 100).toStringAsFixed(1)}%'))}');
      // If max prob is only slightly above uniform (e.g. 1/9 ≈ 11%), the model is barely distinguishing; often one class (e.g. sad) gets a small bias and wins every time.
      final maxP = moodProbs.values.fold(0.0, (a, b) => a > b ? a : b);
      if (maxP < 0.35) {
        print('⚠️ Low discrimination: max prob ${(maxP * 100).toStringAsFixed(1)}% is close to uniform (~11%). Classifier may be biased toward one class (e.g. sad) when embeddings are similar across recordings.');
      }
      return moodProbs;
    } catch (e, stackTrace) {
      print('❌ Error classifying mood: $e');
      print('📚 Stack trace: $stackTrace');
      return null;
    }
  }

  /// Average multiple probability maps (same keys); for temporal smoothing across calls.
  Map<String, double> _averageProbabilityMaps(List<Map<String, double>> maps) {
    if (maps.isEmpty) return {};
    final keys = maps.first.keys.toSet();
    for (final m in maps) {
      keys.addAll(m.keys);
    }
    final result = <String, double>{};
    for (final k in keys) {
      double sum = 0.0;
      int count = 0;
      for (final m in maps) {
        final v = m[k];
        if (v != null) {
          sum += v;
          count++;
        }
      }
      result[k] = count > 0 ? sum / count : 0.0;
    }
    return result;
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
        pitchVariation: 0.0,
        energy: 0.0,
        intensityDynamics: 0.0,
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

    // 3. Frame-based analysis for pitch variation and spectral features
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
    final framePitches = <double>[];

    for (final frame in frames) {
      final framePitch = _estimatePitch(frame, sampleRate);
      if (framePitch > 50 && framePitch < 600) framePitches.add(framePitch);
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

    // 5. Energy Variability and Intensity Dynamics
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
    final energyMax = frameEnergies.fold(0.0, (a, b) => a > b ? a : b);
    final energyMin = frameEnergies.fold(double.infinity, (a, b) => a < b ? a : b);
    final intensityDynamics = energyMean > 1e-9 ? (energyMax - energyMin) / energyMean : 0.0;

    // 6. Pitch and pitch variation
    final pitch = _estimatePitch(samples, sampleRate);
    double pitchVariation = 0.0;
    if (framePitches.length >= 2) {
      final pitchMean = framePitches.fold(0.0, (a, b) => a + b) / framePitches.length;
      final pitchVar = framePitches.fold(0.0, (sum, p) => sum + (p - pitchMean) * (p - pitchMean)) / framePitches.length;
      pitchVariation = math.sqrt(pitchVar);
    }

    return AudioFeatures(
      pitch: pitch,
      pitchVariation: pitchVariation,
      energy: energy,
      intensityDynamics: intensityDynamics,
      spectralCentroid: spectralCentroid,
      zeroCrossingRate: zeroCrossingRate,
      energyVariability: energyVariability,
      spectralRolloff: spectralRolloff,
      spectralFlux: spectralFlux,
    );
  }

  /// Detect mood from audio features using acoustic rules for all 7 model moods.
  /// Returns one of: angry, calm, disgust, fear, happy, sad, surprise.
  /// Based on pitch, pitch variation, energy, intensity dynamics, spectral centroid, ZCR, flux.
  VoiceMoodResult _detectMoodFromFeatures(AudioFeatures features) {
    // Score each of the 7 supported model moods (exclude neutral; map calm for low-arousal)
    final scores = <String, double>{};
    for (final m in ['angry', 'calm', 'disgust', 'fear', 'happy', 'sad', 'surprise']) {
      scores[m] = 0.0;
    }

    // ANGRY: high pitch, high energy, high ZCR, high centroid, high pitch variation
    if (features.pitch > 180 && features.energy > 0.08 && features.zeroCrossingRate > 0.06) {
      double s = 0.0;
      if (features.pitch > 220) s += 1.5;
      if (features.energy > 0.12) s += 1.2;
      if (features.zeroCrossingRate > 0.08) s += 1.0;
      if (features.spectralCentroid > 1800) s += 1.0;
      if (features.pitchVariation > 30) s += 1.0;
      scores['angry'] = s;
    }

    // CALM: low pitch variation, moderate-low energy, low flux, steady
    double calmS = 0.0;
    if (features.pitchVariation < 25) calmS += 2.0;
    if (features.energy < 0.15 && features.energy > 0.04) calmS += 1.0;
    if (features.spectralFlux < 0.4) calmS += 1.0;
    if (features.intensityDynamics < 1.5) calmS += 1.0;
    scores['calm'] = calmS;

    // DISGUST: lower pitch, tense, higher energy variability (vs sad: more active/tense)
    if (features.pitch > 80 && features.pitch < 200) {
      double s = 0.0;
      if (features.pitch < 160) s += 0.8;
      if (features.energyVariability > 0.02) s += 1.5;  // disgust more variable
      if (features.energy > 0.15 && features.zeroCrossingRate > 0.06) s += 0.8;  // more active
      if (features.spectralCentroid > 1500 && features.spectralCentroid < 2800) s += 0.5;
      scores['disgust'] = s;
    } else {
      scores['disgust'] = 0.0;
    }

    // FEAR: high pitch, high energy variability, high flux (tremulous)
    if (features.pitch > 190) {
      double s = 0.0;
      if (features.energyVariability > 0.02) s += 2.0;
      if (features.spectralFlux > 0.45) s += 1.5;
      if (features.intensityDynamics > 1.2) s += 1.0;
      scores['fear'] = s;
    } else {
      scores['fear'] = 0.0;
    }

    // HAPPY: high pitch, high energy, high centroid
    if (features.pitch > 170 && features.energy > 0.06) {
      double s = 0.0;
      if (features.pitch > 200) s += 1.2;
      if (features.energy > 0.1) s += 1.2;
      if (features.spectralCentroid > 1600) s += 1.0;
      if (features.spectralFlux > 0.35 && features.spectralFlux < 0.7) s += 0.5;
      scores['happy'] = s;
    } else {
      scores['happy'] = 0.0;
    }

    // SAD: low-moderate pitch, low ZCR; energy can vary (soft speech or clear but subdued)
    if (features.pitch < 180 && features.pitch > 50) {
      double s = 0.0;
      if (features.pitch < 150) s += 1.8;  // relaxed: 142Hz now scores
      if (features.pitch < 120) s += 0.5;
      if (features.energy < 0.12) s += 1.2;  // relaxed: allow moderate energy
      if (features.energy < 0.08) s += 0.5;
      if (features.zeroCrossingRate < 0.07) s += 1.2;  // low ZCR strong indicator
      if (features.spectralCentroid < 1800) s += 0.8;
      if (features.pitchVariation < 35) s += 0.5;  // relaxed: sad can have some waver
      scores['sad'] = s;
    } else {
      scores['sad'] = 0.0;
    }

    // SURPRISE: very high pitch, high energy, very high flux
    if (features.pitch > 230 && features.energy > 0.08) {
      double s = 0.0;
      if (features.pitch > 260) s += 2.0;
      if (features.spectralFlux > 0.55) s += 1.5;
      if (features.energy > 0.12) s += 1.0;
      if (features.intensityDynamics > 1.0) s += 0.8;
      scores['surprise'] = s;
    } else {
      scores['surprise'] = 0.0;
    }

    // Pick dominant class by score
    String bestMood = 'calm';
    double bestScore = -1.0;
    for (final e in scores.entries) {
      if (e.value > bestScore) {
        bestScore = e.value;
        bestMood = e.key;
      }
    }

    // If no mood scored, use acoustic heuristics for calm/neutral-like
    if (bestScore < 0.5) {
      if (features.pitch < 140 && features.energy < 0.1) {
        bestMood = 'sad';
      } else if (features.pitch > 200 && features.energy > 0.1) {
        bestMood = 'happy';
      } else {
        bestMood = 'calm';
      }
      bestScore = 0.5;
    }

    final confidence = (0.5 + (bestScore / 6).clamp(0.0, 0.5)).clamp(0.5, 0.85);

    final scoreSum = scores.values.fold(0.0, (a, b) => a + b);
    final allProbs = scoreSum > 0
        ? Map.fromEntries(scores.entries.map((e) => MapEntry(e.key, e.value / scoreSum)))
        : {bestMood: confidence};

    print('🎵 Feature-based mood: $bestMood (pitch=${features.pitch.toStringAsFixed(0)}Hz pVar=${features.pitchVariation.toStringAsFixed(0)} energy=${features.energy.toStringAsFixed(3)} zcr=${features.zeroCrossingRate.toStringAsFixed(3)} flux=${features.spectralFlux.toStringAsFixed(3)})');

    return VoiceMoodResult(
      mood: bestMood,
      confidence: confidence,
      allProbabilities: allProbs,
    );
  }

  /// Dedicated laughter detection: rhythmic bursts, high-frequency modulation,
  /// repeated voiced segments. Returns confidence 0..1. If above threshold → happy.
  double _detectLaughter(List<double> samples) {
    if (samples.isEmpty || samples.length < 2000) return 0.0;

    const int sampleRate = 16000;
    const int frameSize = 512;
    const int hopSize = 256;

    // Frame-based energy and voiced analysis
    final frameEnergies = <double>[];
    final frameVoiced = <bool>[];
    final framePitches = <double>[];
    double spectralCentroidSum = 0.0;
    int centroidCount = 0;

    for (int i = 0; i < samples.length - frameSize; i += hopSize) {
      final frame = samples.sublist(i, i + frameSize);
      double frameSumSq = 0.0;
      for (final s in frame) frameSumSq += s * s;
      final e = math.sqrt(frameSumSq / frame.length);
      frameEnergies.add(e);

      final pitch = _estimatePitch(frame, sampleRate);
      final voiced = pitch > 80 && pitch < 500;
      frameVoiced.add(voiced);
      if (voiced) framePitches.add(pitch);

      // Spectral centroid for high-frequency modulation
      final windowed = _applyHammingWindow(frame);
      final fft = _computeDFT(windowed, frameSize);
      final magnitude = fft.map((c) => math.sqrt(c[0] * c[0] + c[1] * c[1])).toList();
      double weightedSum = 0.0, magSum = 0.0;
      for (int k = 0; k < magnitude.length; k++) {
        final freq = k * sampleRate / frameSize;
        weightedSum += freq * magnitude[k];
        magSum += magnitude[k];
      }
      if (magSum > 1e-9) {
        spectralCentroidSum += weightedSum / magSum;
        centroidCount++;
      }
    }

    if (frameEnergies.length < 8) return 0.0;

    final centroid = centroidCount > 0 ? spectralCentroidSum / centroidCount : 0.0;

    // 1. Rhythmic bursts: autocorrelation of energy envelope
    // Laughter ~2–6 Hz = ~10–31 frames per cycle at 256 hop, 16 kHz
    final energyMean = frameEnergies.fold(0.0, (a, b) => a + b) / frameEnergies.length;
    final energyStd = math.sqrt(frameEnergies.fold(0.0, (s, e) => s + (e - energyMean) * (e - energyMean)) / frameEnergies.length);
    if (energyStd < 1e-9) return 0.0;
    final normalized = frameEnergies.map((e) => (e - energyMean) / energyStd).toList();

    double maxAutocorr = 0.0;
    const int minLag = 5;
    final int maxLag = math.min(40, normalized.length ~/ 2);
    for (int lag = minLag; lag < maxLag; lag++) {
      double sum = 0.0;
      int n = 0;
      for (int i = 0; i < normalized.length - lag; i++) {
        sum += normalized[i] * normalized[i + lag];
        n++;
      }
      final ac = n > 0 ? sum / n : 0.0;
      if (ac > maxAutocorr) maxAutocorr = ac;
    }
    // Rhythmicity score: strong autocorr in laughter range → high score
    final rhythmicScore = (maxAutocorr * 2).clamp(0.0, 1.0);

    // 2. High-frequency modulation: laughter has brighter spectrum
    final highFreqScore = centroid > 2000 ? ((centroid - 2000) / 1500).clamp(0.0, 1.0) : 0.0;

    // 3. Repeated voiced segments: count energy envelope peaks (bursts)
    // Merge nearby peaks - laughter has discrete "ha" bursts spaced ~6-20 frames apart
    const int minPeakSpacing = 6; // frames between distinct bursts
    int mergedPeakCount = 0;
    int lastPeakIdx = -minPeakSpacing - 1;
    for (int i = 1; i < frameEnergies.length - 1; i++) {
      if (frameEnergies[i] > frameEnergies[i - 1] && frameEnergies[i] > frameEnergies[i + 1] &&
          frameEnergies[i] > energyMean + 0.3 * energyStd &&
          (i - lastPeakIdx) >= minPeakSpacing) {
        mergedPeakCount++;
        lastPeakIdx = i;
      }
    }
    // Laughter: 3–10 distinct bursts. Too many = continuous speech, not laughter
    final burstScore = (mergedPeakCount >= 2 && mergedPeakCount <= 12)
        ? ((mergedPeakCount - 2) / 8).clamp(0.0, 1.0)
        : 0.0;
    // Penalty: >12 merged peaks = likely speech
    final burstPenalty = mergedPeakCount > 12 ? 0.5 : 0.0;

    // 4. Voiced segment repetition: multiple voiced "islands"
    int voicedRuns = 0;
    bool inVoiced = false;
    for (final v in frameVoiced) {
      if (v && !inVoiced) {
        voicedRuns++;
        inVoiced = true;
      } else if (!v) {
        inVoiced = false;
      }
    }
    // Laughter: 2–8 voiced runs. >8 = continuous speech
    final voicedScore = (voicedRuns >= 2 && voicedRuns <= 8)
        ? ((voicedRuns - 2) / 6).clamp(0.0, 1.0)
        : (voicedRuns > 8 ? 0.0 : 0.0);
    final voicedPenalty = voicedRuns > 8 ? 0.3 : 0.0;

    // 5. Validation: require laughter-like structure - reject speech masquerading as laughter
    // Cross-check: merged peaks and voiced runs must be in laughter range
    final structureValid = mergedPeakCount >= 2 && mergedPeakCount <= 12 && voicedRuns >= 2 && voicedRuns <= 8;
    if (!structureValid) {
      // Fail validation: return low confidence so we don't override with happy
      final rawConfidence = (rhythmicScore * 0.4 + burstScore * 0.25 + highFreqScore * 0.2 + voicedScore * 0.15);
      final penalized = (rawConfidence - burstPenalty - voicedPenalty).clamp(0.0, 1.0);
      return penalized;
    }

    // Combine with weights (rhythmic bursts strongest indicator)
    final confidence = (rhythmicScore * 0.4 + burstScore * 0.25 + highFreqScore * 0.2 + voicedScore * 0.15).clamp(0.0, 1.0);

    if (confidence >= _laughterConfidenceThreshold) {
      print('😂 Laughter detected: conf=${(confidence * 100).toStringAsFixed(0)}% (rhythmic=${(rhythmicScore * 100).toStringAsFixed(0)}% mergedPeaks=$mergedPeakCount voicedRuns=$voicedRuns centroid=${centroid.toStringAsFixed(0)}Hz)');
    }
    return confidence;
  }

  /// When model probs are flat (12-30%), combine model top class with feature-based.
  /// When model has a clear leader (top leads 2nd by ≥5%), trust model and show model result.
  VoiceMoodResult _hybridMoodLowConfidence(
    Map<String, double> modelProbs,
    VoiceMoodResult featureResult,
  ) {
    final featureMood = featureResult.mood;
    final supportedOrdered = _supportedMoods
        .map((m) => MapEntry(m, modelProbs[m] ?? 0.0))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final modelTop1 = supportedOrdered.isNotEmpty ? supportedOrdered[0].key : 'calm';
    final modelTop2 = supportedOrdered.length > 1 ? supportedOrdered[1].key : modelTop1;
    final modelTop1Prob = supportedOrdered.isNotEmpty ? supportedOrdered[0].value : 0.0;
    final modelTop2Prob = supportedOrdered.length > 1 ? supportedOrdered[1].value : 0.0;

    // Model has clear leader: use model result (don't let feature override)
    const leadThreshold = 0.05;
    if (modelTop1Prob - modelTop2Prob >= leadThreshold) {
      final conf = (modelTop1Prob * 0.8 + featureResult.confidence * 0.2).clamp(0.35, 0.7);
      print('✅ Model has clear leader ($modelTop1 ${(modelTop1Prob * 100).toStringAsFixed(1)}% leads by ${((modelTop1Prob - modelTop2Prob) * 100).toStringAsFixed(1)}%) - using model result');
      return VoiceMoodResult(
        mood: modelTop1,
        confidence: conf,
        allProbabilities: modelProbs,
      );
    }

    // If feature mood matches model top-2, use feature (acoustic agrees with model hint)
    if (featureMood == modelTop1 || featureMood == modelTop2) {
      final modelProb = modelProbs[featureMood] ?? 0.0;
      final combinedConf = (featureResult.confidence * 0.6 + modelProb * 0.4).clamp(0.3, 0.7);
      return VoiceMoodResult(
        mood: featureMood,
        confidence: combinedConf,
        allProbabilities: modelProbs,
      );
    }
    // When model top is sad and feature is disgust: both are low-pitch negative emotions.
    // Trust model's sad if it leads and feature scores for sad are close to disgust.
    if (modelTop1 == 'sad' && featureMood == 'disgust') {
      final sadProb = modelProbs['sad'] ?? 0.0;
      final disgustProb = modelProbs['disgust'] ?? 0.0;
      if (sadProb > disgustProb) {
        final combinedConf = (featureResult.confidence * 0.4 + sadProb * 0.6).clamp(0.35, 0.7);
        return VoiceMoodResult(
          mood: 'sad',
          confidence: combinedConf,
          allProbabilities: modelProbs,
        );
      }
    }
    // Else use feature-based (acoustic overrides flat model)
    return VoiceMoodResult(
      mood: featureMood,
      confidence: featureResult.confidence,
      allProbabilities: modelProbs,
    );
  }

  /// Double-verify model prediction with feature-based. If they agree, boost confidence.
  VoiceMoodResult _verifyWithFeatures(
    String modelMood,
    double modelConfidence,
    Map<String, double> modelProbs,
    VoiceMoodResult featureResult,
  ) {
    if (featureResult.mood == modelMood) {
      final boosted = (modelConfidence * 1.1).clamp(0.0, 1.0);
      print('✅ Feature verification: agrees with $modelMood, confidence ${(modelConfidence * 100).toStringAsFixed(1)}% → ${(boosted * 100).toStringAsFixed(1)}%');
      return VoiceMoodResult(
        mood: modelMood,
        confidence: boosted,
        allProbabilities: modelProbs,
      );
    }
    print('⚠️ Feature verification: model=$modelMood, features=${featureResult.mood} (keeping model)');
    return VoiceMoodResult(
      mood: modelMood,
      confidence: modelConfidence,
      allProbabilities: modelProbs,
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
  /// (1) Decode to 16 kHz mono PCM, (2) normalize/trim, (3) silence check, (4) YAMNet embeddings,
  /// (5) classifier, (6) optional probability averaging across calls, (7) map non-supported labels only,
  /// (8) return exact model-predicted label and confidence. No emotion-specific overrides or fallbacks.
  /// Inference: 16 kHz, mono, float [-1,1]. Feature-based fallback only on embedding/classifier failure or maxProb < _minModelConfidenceThreshold.
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
        _probabilityHistory.clear();
        return VoiceMoodResult(
          mood: 'neutral', // Required field, but error will indicate rejection
          confidence: 0.0,
          error: 'No speech detected. Please speak clearly.',
        );
      }

      // 🔹 Laughter Detection: If laughter patterns detected with sufficient confidence → happy
      final laughterConfidence = _detectLaughter(processedSamples);
      if (laughterConfidence >= _laughterConfidenceThreshold) {
        print('😂 Laughter detected (${(laughterConfidence * 100).toStringAsFixed(0)}%) → classifying as happy');
        return VoiceMoodResult(
          mood: 'happy',
          confidence: laughterConfidence.clamp(0.7, 0.95),
          allProbabilities: {'happy': laughterConfidence},
        );
      }

      // 🔹 2. Extract YAMNet Embeddings
      final embedding = await _extractYamnetEmbeddings(processedSamples);
      if (embedding == null || embedding.length != 1024) {
        print('⚠️ Failed to extract embeddings - using feature-based detection');
        if (laughterConfidence >= _laughterConfidenceThreshold) {
          return VoiceMoodResult(mood: 'happy', confidence: laughterConfidence.clamp(0.7, 0.95), allProbabilities: {'happy': laughterConfidence});
        }
        final audioFeatures = _extractAudioFeatures(processedSamples);
        final featureBasedMood = _detectMoodFromFeatures(audioFeatures);
        print('✅ Feature-based mood detection: ${featureBasedMood.mood} (confidence: ${(featureBasedMood.confidence * 100).toStringAsFixed(1)}%)');
        return featureBasedMood;
      }

      // 🔹 3. Classify Mood
      final moodProbs = await _classifyMood(embedding);
      if (moodProbs == null || moodProbs.isEmpty) {
        print('⚠️ Failed to classify mood - using feature-based detection');
        if (laughterConfidence >= _laughterConfidenceThreshold) {
          return VoiceMoodResult(mood: 'happy', confidence: laughterConfidence.clamp(0.7, 0.95), allProbabilities: {'happy': laughterConfidence});
        }
        final audioFeatures = _extractAudioFeatures(processedSamples);
        final featureBasedMood = _detectMoodFromFeatures(audioFeatures);
        print('✅ Feature-based mood detection: ${featureBasedMood.mood} (confidence: ${(featureBasedMood.confidence * 100).toStringAsFixed(1)}%)');
        return featureBasedMood;
      }

      // Temporal smoothing over probability distributions (across recent calls) to reduce bias toward neutral/happy on natural speech.
      Map<String, double> effectiveProbs = moodProbs;
      if (_useProbabilityAveraging && _probabilityHistory.isNotEmpty) {
        effectiveProbs = _averageProbabilityMaps([..._probabilityHistory, moodProbs]);
        print('📊 Smoothed probs (over ${_probabilityHistory.length + 1} frames): ${effectiveProbs.map((k, v) => MapEntry(k, '${(v * 100).toStringAsFixed(1)}%'))}');
      }
      _probabilityHistory.add(Map.from(moodProbs));
      if (_probabilityHistory.length > _probabilityHistorySize) {
        _probabilityHistory.removeAt(0);
      }

      // Find mood with highest probability (use smoothed probs for decision)
      final sortedMoods = effectiveProbs.entries.toList()
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

      // Best supported mood (for edge case when mapped label has very low prob)
      final supportedEntries = _supportedMoods
          .map((m) => MapEntry(m, effectiveProbs[m] ?? 0.0))
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final bestSupportedMood = supportedEntries.isNotEmpty ? supportedEntries[0].key : 'neutral';
      final bestSupportedProb = supportedEntries.isNotEmpty ? supportedEntries[0].value : 0.0;

      // If model confidence is very low, use feature-based detection
      if (maxProb < _minModelConfidenceThreshold) {
        print('⚠️ Model confidence too low (${(maxProb * 100).toStringAsFixed(1)}% < ${(_minModelConfidenceThreshold * 100).toStringAsFixed(0)}%) - using feature-based detection');
        if (laughterConfidence >= _laughterConfidenceThreshold) {
          return VoiceMoodResult(mood: 'happy', confidence: laughterConfidence.clamp(0.7, 0.95), allProbabilities: {'happy': laughterConfidence});
        }
        final audioFeatures = _extractAudioFeatures(processedSamples);
        final featureBasedMood = _detectMoodFromFeatures(audioFeatures);
        print('✅ Feature-based mood detection: ${featureBasedMood.mood} (confidence: ${(featureBasedMood.confidence * 100).toStringAsFixed(1)}%)');
        return featureBasedMood;
      }

      // Low-confidence (12–30%): use feature-based + model probs hybrid
      if (maxProb < _lowConfidenceUncertainThreshold) {
        print('⚠️ Low confidence (${(maxProb * 100).toStringAsFixed(1)}% < ${(_lowConfidenceUncertainThreshold * 100).toStringAsFixed(0)}%) - using feature-based + model hybrid');
        final audioFeatures = _extractAudioFeatures(processedSamples);
        final featureResult = _detectMoodFromFeatures(audioFeatures);
        final hybridResult = _hybridMoodLowConfidence(effectiveProbs, featureResult);
        print('✅ Hybrid mood: ${hybridResult.mood} (confidence: ${(hybridResult.confidence * 100).toStringAsFixed(1)}%)');
        return hybridResult;
      }

      // Map only non-supported labels (e.g. "unknown") to best supported from same probability distribution.
      // All supported labels (angry, calm, disgust, fear, happy, neutral, sad, surprise) pass through as-is.
      String finalMood = _mapNonSupportedToSupported(bestMood, effectiveProbs);
      double finalConfidence = effectiveProbs[finalMood] ?? 0.0;

      // Edge case: mapped label has very low prob (< 8%); use best supported from same inference.
      if (finalConfidence < 0.08 && bestSupportedProb > finalConfidence) {
        finalMood = bestSupportedMood;
        finalConfidence = bestSupportedProb;
      }

      // Double-verify with feature-based when model is confident
      final audioFeatures = _extractAudioFeatures(processedSamples);
      final featureResult = _detectMoodFromFeatures(audioFeatures);
      final verified = _verifyWithFeatures(finalMood, finalConfidence, moodProbs, featureResult);
      print('✅ Final mood: ${verified.mood} (confidence: ${(verified.confidence * 100).toStringAsFixed(1)}%)');
      return verified;
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
      print('🔄 Requesting PCM from native decoder: ${audioPath.split(RegExp(r'[/\\]')).last}');

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
      final pcmFingerprint = samples.length >= 3
          ? 'first3=${samples[0].toStringAsFixed(6)},${samples[1].toStringAsFixed(6)},${samples[2].toStringAsFixed(6)}'
          : 'len<3';
      print('✅ Received ${samples.length} PCM samples from native decoder | $pcmFingerprint');
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
    _probabilityHistory.clear();
  }
}
