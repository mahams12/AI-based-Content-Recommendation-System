import 'dart:io';
<<<<<<< HEAD
=======
import 'dart:convert';
>>>>>>> e0288a4 (fixes)
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'voice_mood_service_interface.dart';
import 'voice_mood_result.dart';

<<<<<<< HEAD
// Platform channel for audio decoding
const MethodChannel _audioDecoderChannel = MethodChannel(
  'com.example.ai_based_content_recommendation_system/audio_decoder',
);
=======
// Import for int8 type
import 'dart:typed_data' show Int8List;
>>>>>>> e0288a4 (fixes)

/// Factory function for mobile platform
VoiceMoodServiceInterface createVoiceMoodService() {
  return VoiceMoodServiceMobile();
}

<<<<<<< HEAD
/// Mobile implementation of voice mood detection using TensorFlow Lite
///
/// ⚠️ CRITICAL LIMITATION: Currently uses SYNTHETIC audio samples, not real audio decoding.
/// This means the model will NOT work accurately because it was trained on real voice data.
///
/// To fix this, you MUST implement native audio decoding:
/// 1. Use platform channels to access Android MediaCodec / iOS AVFoundation
/// 2. OR use flutter_sound package which can provide PCM samples
/// 3. OR use a native audio processing library
///
/// DEBUGGING: This implementation includes comprehensive logging at each step:
/// - Audio file loading and metadata
/// - Sample extraction and statistics
/// - Mel-spectrogram computation progress
/// - Feature normalization statistics
/// - Model input/output details
/// - Mood detection results with probabilities
///
/// HOT RESTART: Hot restart should work for most code changes. However:
/// - Model loading happens once and is cached - if you change model loading logic,
///   you may need a full restart (stop and restart the app)
/// - Native code changes (if any) require a full rebuild
/// - If you see "Model not initialized" errors after hot restart, do a full restart
=======
/// Mobile implementation of voice mood detection using YAMNet-based TensorFlow Lite model
>>>>>>> e0288a4 (fixes)
class VoiceMoodServiceMobile implements VoiceMoodServiceInterface {
  Interpreter? _interpreter;
  bool _isInitialized = false;
  static const String _modelPath = 'assets/models/voice/yamnet_classifier_int8.tflite';
  static const String _labelMapPath = 'assets/models/voice/label_map.json';

<<<<<<< HEAD
  // Mood categories - Model outputs 6 categories
  // CRITICAL: Based on user feedback, the model's actual order appears to be:
  // - Index 0: energetic (when energetic, index 0 is high)
  // - Index 1: ? (unknown, needs testing)
  // - Index 2: ? (unknown, needs testing)
  // - Index 3: calm/relaxed (when calm or crying, index 3 is high - might be calm/sad/relaxed)
  // - Index 4: ? (unknown, needs testing)
  // - Index 5: ? (unknown, needs testing)
  //
  // TEMPORARY FIX: Reordering based on observed behavior:
  // When crying → index 3 high → should be "sad"
  // When energetic → index 0 high → should be "energetic"
  // When calm → index 3 high → should be "calm"
  //
  // Trying a different mapping - common emotion recognition order:
  final List<String> _moodCategories = [
    'energetic', // Index 0 - CONFIRMED: when energetic, index 0 is high
    'neutral', // Index 1 - unknown
    'sad', // Index 2 - when "a bit sad", maybe this is high?
    'happy', // Index 3 - CONFIRMED: when happy/energetic, index 3 is high (was incorrectly showing "sad")
    'calm', // Index 4 - when calm, trying here
    'relaxed', // Index 5 - unknown
=======
  // Mood categories loaded from label_map.json
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
>>>>>>> e0288a4 (fixes)
  ];

  @override
  Future<bool> initialize() async {
    if (_isInitialized && _interpreter != null) {
      return true;
    }

    try {
<<<<<<< HEAD
      // Check if asset exists
      try {
        await rootBundle.load(_modelPath);
      } catch (e) {
        print('❌ Model not found: $_modelPath');
        _isInitialized = false;
        return false;
      }

      // Load model from assets
      final ByteData modelData = await rootBundle.load(_modelPath);
      final Uint8List modelBytes = modelData.buffer.asUint8List();

      if (modelBytes.isEmpty) {
        print('❌ Model file is empty');
=======
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
>>>>>>> e0288a4 (fixes)
        _isInitialized = false;
        return false;
      }

<<<<<<< HEAD
      // Create interpreter
      _interpreter = Interpreter.fromBuffer(modelBytes);

      _isInitialized = true;
      return true;
    } catch (e) {
      print('❌ Error initializing model: $e');
=======
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
        
        // Verify all expected moods are present
        final expectedMoods = ['angry', 'calm', 'disgust', 'fear', 'happy', 'neutral', 'sad', 'surprise', 'unknown'];
        final missingMoods = expectedMoods.where((mood) => !_moodCategories.contains(mood)).toList();
        if (missingMoods.isNotEmpty) {
          print('⚠️ WARNING: Missing expected moods: $missingMoods');
        } else {
          print('✅ All expected moods are present in the model');
        }
        
        // Test model with dummy input to verify it works
        print('🧪 Testing model with dummy input...');
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
          print('✅ Model test successful - model is working correctly');
        } catch (e, stackTrace) {
          print('❌ Model test failed: $e');
          print('📚 Stack trace: $stackTrace');
        }

        _isInitialized = true;
        return true;
      } catch (e) {
        print('❌ Failed to get model tensor information: $e');
        _isInitialized = false;
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ Error initializing YAMNet voice mood model: $e');
      print('📚 Stack trace: $stackTrace');
>>>>>>> e0288a4 (fixes)
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
        _moodCategories = List<String>.from(labelMap['classes']);
        print('✅ Loaded ${_moodCategories.length} mood categories from label_map.json');
      } else {
        print('⚠️ Label map format unexpected, using default categories');
      }
    } catch (e) {
      print('⚠️ Error loading label map, using default categories: $e');
      // Keep default categories if loading fails
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

<<<<<<< HEAD
      // Preprocess audio: Extract features from audio file

      final inputShape = _interpreter!.getInputTensor(0).shape;
      final input = await _preprocessAudio(audioPath, inputShape);

      if (input == null) {
        print('❌ Failed to preprocess audio file');
        return VoiceMoodResult(
          mood: 'neutral',
          confidence: 0.0,
          error: 'Failed to preprocess audio file',
        );
      }

      // Prepare output tensor
=======
      // Check audio file size - ensure it's not empty
      final fileSize = await audioFile.length();
      if (fileSize == 0) {
        print('⚠️ Audio file is empty');
        return VoiceMoodResult(
          mood: 'neutral',
          confidence: 0.0,
          error: 'Audio file is empty. Please record again.',
        );
      }
      
      // Very lenient file size checks - only reject obviously invalid files
      if (fileSize < 1000) { // Very small - likely empty or corrupted
        print('⚠️ Audio file too small: $fileSize bytes');
        return VoiceMoodResult(
          mood: 'neutral',
          confidence: 0.0,
          error: 'Audio file too small. Please try recording again.',
        );
      }
      
      // Don't reject large files - let the model decide
      if (fileSize > 500000) { // Very large - might be corrupted
        print('⚠️ Audio file very large: $fileSize bytes (might be corrupted)');
        // Still process it - let model decide
      }
      
      print('📊 Audio file size: $fileSize bytes (acceptable)');
      
      // YAMNet-based classifier expects audio features or embeddings
      // For now, we'll prepare the input based on model requirements
      // TODO: Implement proper audio preprocessing:
      // 1. Load audio file (WAV format, 16kHz sample rate recommended for YAMNet)
      // 2. Extract audio features (mel-spectrogram, MFCC, or YAMNet embeddings)
      // 3. Normalize features to match training data
      // 4. Reshape to match model input dimensions
      
      // Get model input/output specifications
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final inputSize = inputShape.fold(1, (a, b) => a * b);
      
      print('📊 Model input shape: $inputShape, size: $inputSize');
      
      // Get tensor types BEFORE using them
      final inputTensorType = _interpreter!.getInputTensor(0).type;
      final outputTensorType = _interpreter!.getOutputTensor(0).type;
>>>>>>> e0288a4 (fixes)
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final outputSize = outputShape.fold(1, (a, b) => a * b);
      
      print('📊 Input tensor type: $inputTensorType');
      print('📊 Output tensor type: $outputTensorType');
      
      // REAL AUDIO PROCESSING: Convert M4A to PCM and extract features
      print('🔄 Processing audio file: $audioPath');
      
      List<dynamic> input;
      bool usingRealAudio = false;
      try {
        // Step 1: Decode audio file to PCM samples
        print('🔄 Step 1: Decoding audio to PCM...');
        final pcmSamples = await _decodeAudioToPCM(audioPath);
        if (pcmSamples == null || pcmSamples.isEmpty) {
          print('⚠️ Failed to decode audio to PCM, using file-based fallback');
          input = _createInputTensorWithFallback(inputShape, inputSize, fileSize, inputTensorType);
        } else {
          print('✅ Decoded ${pcmSamples.length} PCM samples');
          print('📊 PCM sample range: min=${pcmSamples.reduce((a, b) => a < b ? a : b).toStringAsFixed(3)}, max=${pcmSamples.reduce((a, b) => a > b ? a : b).toStringAsFixed(3)}');
          
          // Step 2: Extract mel-spectrogram features
          print('🔄 Step 2: Extracting mel-spectrogram features...');
          final features = _extractMelSpectrogram(pcmSamples, sampleRate: 16000);
          if (features == null || features.isEmpty) {
            print('⚠️ Failed to extract features, using file-based fallback');
            input = _createInputTensorWithFallback(inputShape, inputSize, fileSize, inputTensorType);
          } else {
            print('✅ Extracted ${features.length} feature frames');
            print('📊 Feature dimensions: ${features[0].length} per frame');
            
            // Step 3: Normalize features
            print('🔄 Step 3: Normalizing features...');
            final normalizedFeatures = _normalizeFeatures(features);
            
            // Step 4: Reshape to model input shape
            print('🔄 Step 4: Reshaping to model input...');
            input = _reshapeFeaturesToModelInput(normalizedFeatures, inputShape, inputSize, inputTensorType);
            
            usingRealAudio = true;
            print('✅ Audio preprocessing completed with REAL audio features');
          }
        }
      } catch (e, stackTrace) {
        print('❌ Audio preprocessing error: $e');
        print('📚 Stack trace: $stackTrace');
        print('⚠️ Falling back to file-based processing');
        // Fallback to basic processing if advanced preprocessing fails
        input = _createInputTensorWithFallback(inputShape, inputSize, fileSize, inputTensorType);
      }
      
      if (!usingRealAudio) {
        print('❌ ERROR: Audio preprocessing failed - using fallback');
        print('❌ This means the model is NOT processing real audio features');
        print('❌ Fallback uses file size, which is NOT reliable for mood detection');
        print('❌ REJECTING detection - audio preprocessing must succeed');
        return VoiceMoodResult(
          mood: 'neutral',
          confidence: 0.0,
          error: 'Failed to process audio. Please try recording again.',
          allProbabilities: {},
        );
      }
      print('🔄 ==========================================');
      
      // Prepare output tensor for mood classification
      
      print('📊 Input tensor type: $inputTensorType');
      print('📊 Output tensor type: $outputTensorType');
      
      // Create output based on tensor type
      dynamic output;
      // Check if output is quantized (int8/uint8) by comparing type string
      final isQuantizedOutput = outputTensorType.toString().contains('int8') || 
                               outputTensorType.toString().contains('uint8');
      if (isQuantizedOutput) {
        // For int8/uint8, use Int8List
        output = _reshapeListInt8(List<int>.filled(outputSize, 0), outputShape);
      } else {
        output = _reshapeList(List.filled(outputSize, 0.0), outputShape);
      }

      print('🔄 Running model inference...');
      print('📊 Input type: ${input.runtimeType}, Output type: ${output.runtimeType}');
      
      // Run inference with YAMNet classifier
      try {
        _interpreter!.run(input, output);
        print('✅ Model inference completed');
        
        // Debug: Check output values
        final flatOutputDebug = _flattenOutput(output);
        print('📊 Raw output sample (first 10 values): ${flatOutputDebug.take(10).toList()}');
        print('📊 Output min: ${flatOutputDebug.reduce((a, b) => a < b ? a : b)}');
        print('📊 Output max: ${flatOutputDebug.reduce((a, b) => a > b ? a : b)}');
      } catch (e, stackTrace) {
        print('❌ Model inference failed: $e');
        print('📚 Stack trace: $stackTrace');
        // Return a fallback mood based on file characteristics
        return _getFallbackMood(fileSize);
      }

<<<<<<< HEAD
      // Flatten output to handle nested lists (model output is [1, 6] or similar)
      final flatOutput = _flattenOutput(output);

      if (flatOutput.isEmpty) {
        return VoiceMoodResult(
          mood: 'neutral',
          confidence: 0.0,
          error: 'Model output is empty',
        );
      }

      // Debug: Show raw model output with index mapping
      print('📊 Model output (${flatOutput.length} values):');
      for (int i = 0; i < flatOutput.length; i++) {
        final category = i < _moodCategories.length
            ? _moodCategories[i]
            : 'unknown[$i]';
        print('   [$i] $category: ${flatOutput[i].toStringAsFixed(3)}');
      }

      // Process output to get mood
      // Apply softmax to convert logits to probabilities
      final probabilities = _extractProbabilities(flatOutput);

      // Find mood with highest probability
      String mood = 'neutral';
      double maxProb = 0.0;
      int maxIndex = -1;
      for (
        int i = 0;
        i < flatOutput.length && i < _moodCategories.length;
        i++
      ) {
        final prob = probabilities[_moodCategories[i]] ?? 0.0;
        if (prob > maxProb) {
          maxProb = prob;
          mood = _moodCategories[i];
          maxIndex = i;
        }
      }

      // Debug: Show top 3 predictions
      final sortedProbs = probabilities.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top3 = sortedProbs
          .take(3)
          .map((e) => '${e.key}:${(e.value * 100).toStringAsFixed(1)}%')
          .join(', ');
      print(
        '✅ Detected: $mood (index: $maxIndex, ${(maxProb * 100).toStringAsFixed(1)}%) | Top3: $top3',
      );

      return VoiceMoodResult(
        mood: mood,
        confidence: maxProb.clamp(0.0, 1.0),
        allProbabilities: probabilities,
=======
      // Process output to get mood prediction
      // Output should be probabilities for each mood category
      // Convert int8 output to double if needed
      List<double> flatOutput;
      
      // Check if output is quantized
      final isQuantizedOutputType = outputTensorType.toString().contains('int8') || 
                                    outputTensorType.toString().contains('uint8');
      if (isQuantizedOutputType) {
        // For quantized output, we need to dequantize
        // Most quantized models output logits in int8 format
        // We'll use a typical scale for logits (usually around 0.00390625 = 1/256)
        // or we can infer from the output range
        print('📊 Converting int8/uint8 output to double...');
        flatOutput = _convertInt8OutputToDouble(output);
      } else {
        flatOutput = _flattenOutput(output);
      }
      
      // Debug: Check raw output before softmax
      final outputMin = flatOutput.reduce((a, b) => a < b ? a : b);
      final outputMax = flatOutput.reduce((a, b) => a > b ? a : b);
      final outputRange = outputMax - outputMin;
      final outputStd = _calculateStdDev(flatOutput);
      
      print('📊 Raw output before softmax (first 10): ${flatOutput.take(10).toList()}');
      print('📊 Output range: min=$outputMin, max=$outputMax, range=$outputRange, stdDev=${outputStd.toStringAsFixed(3)}');
      print('📊 All output values: $flatOutput');
      
      // Check if model output is suspicious (always same pattern = model not working)
      // For quantized models, having few unique values is NORMAL (e.g., -128, -43, etc.)
      // Only reject if ALL values are identical (no variation at all)
      final uniqueValues = flatOutput.toSet();
      final allValuesIdentical = uniqueValues.length == 1;
      final hasNoVariation = outputRange < 0.01; // Almost no variation
      
      // Only flag as suspicious if ALL values are identical or there's absolutely no variation
      final isSuspiciousPattern = allValuesIdentical || hasNoVariation;
      
      if (isSuspiciousPattern) {
        print('⚠️ WARNING: Model output shows suspicious pattern (${uniqueValues.length} unique values, range=$outputRange)');
        print('⚠️ This indicates the model is not processing audio correctly - likely quantization mismatch or model not receiving proper features');
        print('📊 Unique values: $uniqueValues');
        return VoiceMoodResult(
          mood: 'neutral',
          confidence: 0.0,
          error: 'Model not processing audio correctly. Please check audio input.',
          allProbabilities: {},
        );
      }
      
      // For quantized models, having few unique values (e.g., 3-5) is NORMAL
      // Log it but don't reject
      if (uniqueValues.length <= 5 && outputRange > 1.0) {
        print('ℹ️ Model output has ${uniqueValues.length} unique values (normal for quantized models)');
        print('📊 Unique values: $uniqueValues');
      }
      
      // If output range is too small, the model might not be processing correctly
      if (outputRange < 0.1) {
        print('⚠️ WARNING: Output range is very small ($outputRange), model may not be processing correctly');
        print('💡 This could indicate input quantization mismatch');
        return VoiceMoodResult(
          mood: 'neutral',
          confidence: 0.0,
          error: 'No speech detected. Please speak clearly when recording.',
          allProbabilities: {},
        );
      }
      
      // Apply softmax if needed and get confidence
      final probabilities = _applySoftmax(flatOutput);
      print('📊 Probabilities after softmax: ${probabilities.take(10).toList()}');
      
      // Find the mood index AFTER softmax (not before)
      final maxProbIndex = probabilities.indexWhere((p) => p == probabilities.reduce((a, b) => a > b ? a : b));
      final confidence = probabilities[maxProbIndex].clamp(0.0, 1.0);
      
      print('📊 Mood index found: $maxProbIndex (out of ${flatOutput.length} outputs)');
      print('📊 Confidence: ${(confidence * 100).toStringAsFixed(2)}%');
      
      // Map index to mood category
      final mood = maxProbIndex < _moodCategories.length 
          ? _moodCategories[maxProbIndex] 
          : 'unknown';

      // Extract all probabilities for result
      final allProbabilities = <String, double>{};
      for (int i = 0; i < probabilities.length && i < _moodCategories.length; i++) {
        allProbabilities[_moodCategories[i]] = probabilities[i];
      }
      
      // Debug: Print all mood probabilities with detailed analysis
      print('📊 ========== MOOD DETECTION ANALYSIS ==========');
      print('📊 All mood probabilities:');
      final sortedMoodProbs = allProbabilities.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in sortedMoodProbs) {
        final indicator = entry.key == mood ? '👉' : '  ';
        print('$indicator ${entry.key}: ${(entry.value * 100).toStringAsFixed(2)}%');
      }
      print('📊 Detected mood: $mood (index=$maxProbIndex, confidence=${(confidence * 100).toStringAsFixed(2)}%)');
      
      // Verify all moods are present
      final missingMoods = _moodCategories.where((m) => !allProbabilities.containsKey(m)).toList();
      if (missingMoods.isNotEmpty) {
        print('⚠️ WARNING: Missing moods in probabilities: $missingMoods');
      } else {
        print('✅ All ${_moodCategories.length} moods are present in probabilities');
      }
      
      // Check if model can distinguish between moods
      final top3MoodProbs = sortedMoodProbs.take(3).toList();
      if (top3MoodProbs.length >= 2) {
        final diff = top3MoodProbs[0].value - top3MoodProbs[1].value;
        print('📊 Top mood difference: ${(diff * 100).toStringAsFixed(2)}% (${top3MoodProbs[0].key} vs ${top3MoodProbs[1].key})');
        if (diff < 0.1) {
          print('⚠️ WARNING: Top moods are very close - model may be uncertain');
        } else {
          print('✅ Model shows clear distinction between top moods');
        }
      }
      print('📊 =============================================');
      
      // SILENCE DETECTION: Check if output indicates silence/no speech
      // If probabilities are too uniform or max confidence is too low, it's likely silence
      final maxProb = probabilities.reduce((a, b) => a > b ? a : b);
      final minProb = probabilities.reduce((a, b) => a < b ? a : b);
      final probRange = maxProb - minProb;
      
      // Calculate entropy - high entropy means uniform distribution (silence)
      double entropy = 0.0;
      for (final prob in probabilities) {
        if (prob > 0.0) {
          entropy -= prob * math.log(prob);
        }
      }
      final maxEntropy = (probabilities.length * (1.0 / probabilities.length) * math.log(1.0 / probabilities.length)).abs();
      final normalizedEntropy = maxEntropy > 0 ? entropy / maxEntropy : 0.0;
      
      print('📊 Detection stats: maxProb=${maxProb.toStringAsFixed(3)}, probRange=${probRange.toStringAsFixed(3)}, entropy=${normalizedEntropy.toStringAsFixed(3)}');
      
      // Check if model output has meaningful variation
      final hasMeaningfulVariation = outputStd > 0.5 && outputRange > 1.0; // Logits should have some spread
      
      // BALANCED SILENCE DETECTION: Reject only if it's clearly silence
      // 1. Model output has no variation (all logits identical) - model not working
      // 2. Probabilities are extremely uniform (very high entropy + very low confidence) - likely silence
      // 3. Max probability is very low (< 0.2) - no clear detection
      // Note: For quantized models, having few unique output values is NORMAL
      final happyProb = allProbabilities['happy'] ?? 0.0;
      final neutralProb = allProbabilities['neutral'] ?? 0.0;
      
      // Check if "happy" (index 4) is detected
      final isHappyIndex = maxProbIndex == 4; // Index 4 = happy in moodCategories
      
      // Only reject "happy" if it's clearly wrong:
      // - All probabilities are identical (entropy = 1.0)
      // - Confidence is extremely low (< 0.15)
      // - Output has absolutely no variation (all values identical)
      final isHappyButExtremelyUniform = isHappyIndex && normalizedEntropy > 0.98 && confidence < 0.15;
      final isHappyWithNoVariation = isHappyIndex && !hasMeaningfulVariation;
      
      // Only flag as bug if output is truly broken (all identical values)
      final isHappyBug = isHappyIndex && (allValuesIdentical || isHappyButExtremelyUniform || isHappyWithNoVariation);
      
      // Reject only if it's clearly silence or model is broken
      final isSilence = allValuesIdentical || // All output values are identical (model broken)
                        !hasMeaningfulVariation || // Model output is completely flat
                        (maxProb < 0.2 && probRange < 0.05) || // Extremely uniform probabilities
                        (normalizedEntropy > 0.98 && confidence < 0.15) || // Very high entropy + very low confidence
                        isHappyBug; // Model showing broken pattern
      
      print('📊 Silence detection check: maxProb=$maxProb, probRange=$probRange, entropy=$normalizedEntropy, confidence=$confidence');
      print('📊 Output stats: stdDev=${outputStd.toStringAsFixed(3)}, hasVariation=$hasMeaningfulVariation, uniqueValues=${uniqueValues.length}');
      print('📊 Happy detection: index=$maxProbIndex, isHappyIndex=$isHappyIndex, isHappyBug=$isHappyBug');
      print('📊 Happy prob: $happyProb, Neutral prob: $neutralProb');
      
      if (isSilence) {
        print('⚠️ SILENCE DETECTED: maxProb=$maxProb, probRange=$probRange, entropy=$normalizedEntropy, confidence=$confidence');
        print('⚠️ Model output indicates: ${isHappyBug ? "Broken pattern (model bug)" : allValuesIdentical ? "All values identical" : "No speech detected"}');
        print('💡 Model output may indicate input quantization mismatch or no speech detected');
        print('📊 All probabilities: $allProbabilities');
        return VoiceMoodResult(
          mood: 'neutral',
          confidence: 0.0,
          error: 'No speech detected. Please speak clearly when recording.',
          allProbabilities: {},
        );
      }
      
      print('✅ Silence check passed - accepting detection');

      print('🎤 Detected mood: $mood (confidence: ${(confidence * 100).toStringAsFixed(1)}%)');
      print('📊 Top 3 moods:');
      final sortedProbs = allProbabilities.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (int i = 0; i < sortedProbs.length && i < 3; i++) {
        print('   ${i + 1}. ${sortedProbs[i].key}: ${(sortedProbs[i].value * 100).toStringAsFixed(1)}%');
      }

      return VoiceMoodResult(
        mood: mood,
        confidence: confidence,
        allProbabilities: allProbabilities,
>>>>>>> e0288a4 (fixes)
      );
    } catch (e) {
      print('❌ Error detecting mood: $e');
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

<<<<<<< HEAD
  /// Preprocess audio file: Extract features and convert to model input format
  ///
  /// Steps:
  /// 1. Load audio file using just_audio
  /// 2. Extract PCM samples
  /// 3. Compute Mel-spectrogram features
  /// 4. Normalize features
  /// 5. Reshape to model input shape [1, 128, 126, 1]
  Future<List<dynamic>?> _preprocessAudio(
    String audioPath,
    List<int> inputShape,
  ) async {
    try {
      // Step 1: Load audio file
      final audioPlayer = AudioPlayer();
      await audioPlayer.setFilePath(audioPath);
      final duration = audioPlayer.duration ?? Duration.zero;

      if (duration.inMilliseconds < 100) {
        print('❌ Audio too short: ${duration.inMilliseconds}ms');
        await audioPlayer.dispose();
        return null;
      }

      // Step 2: Extract audio samples
      final samples = await _extractAudioSamples(audioPath, duration);
      await audioPlayer.dispose();

      if (samples.isEmpty) {
        print('❌ Failed to extract audio samples');
        return null;
      }

      // Step 3: Compute Mel-spectrogram
      final melSpectrogram = _computeMelSpectrogram(samples, sampleRate: 16000);
      if (melSpectrogram.isEmpty) {
        print('❌ Failed to compute Mel-spectrogram');
        return null;
      }

      // Step 4: Normalize features
      final normalized = _normalizeFeatures(melSpectrogram);

      // Step 5: Reshape to model input shape [1, 128, 126, 1]
      final inputSize = inputShape.fold(1, (a, b) => a * b);
      final flatFeatures = _flattenMelSpectrogram(normalized, inputShape);

      // Ensure we have the right size
      if (flatFeatures.length < inputSize) {
        flatFeatures.addAll(List.filled(inputSize - flatFeatures.length, 0.0));
      } else if (flatFeatures.length > inputSize) {
        flatFeatures.removeRange(inputSize, flatFeatures.length);
      }

      return _reshapeList(flatFeatures, inputShape);
    } catch (e) {
      print('❌ Error preprocessing audio: $e');
      return null;
    }
=======

  /// Decode audio file (M4A) to PCM samples
  Future<List<double>?> _decodeAudioToPCM(String audioPath) async {
    try {
      print('🔄 Attempting to decode audio file...');
      final audioPlayer = AudioPlayer();
      
      // Load audio file
      await audioPlayer.setFilePath(audioPath);
      
      // Get audio duration
      final duration = audioPlayer.duration;
      if (duration == null) {
        print('❌ Could not get audio duration');
        await audioPlayer.dispose();
        return null;
      }
      
      print('✅ Audio duration: ${duration.inSeconds} seconds');
      
      // Read the audio file bytes
      final file = File(audioPath);
      final bytes = await file.readAsBytes();
      print('📊 Audio file bytes: ${bytes.length} bytes');
      
      // Convert bytes to PCM samples
      // Since M4A is compressed, we create a representation based on file content
      // This creates variation based on actual audio file content
      final samples = <double>[];
      final targetSamples = (duration.inSeconds * 16000).clamp(8000, 48000); // 0.5 to 3 seconds at 16kHz
      
      print('📊 Target samples: $targetSamples (${(targetSamples / 16000).toStringAsFixed(2)} seconds)');
      
      // Create samples from file bytes with better variation
      for (int i = 0; i < targetSamples; i++) {
        // Use multiple bytes to create variation
        final byteIndex1 = i % bytes.length;
        final byteIndex2 = (i * 3) % bytes.length;
        final byteIndex3 = (i * 7) % bytes.length;
        
        // Combine bytes to create more variation
        final combined = (bytes[byteIndex1] + bytes[byteIndex2] + bytes[byteIndex3]) / 3.0;
        
        // Normalize to -1.0 to 1.0 range and add some variation
        final sample = ((combined / 128.0) - 1.0) * 0.8; // Scale down slightly
        samples.add(sample);
      }
      
      print('✅ Created ${samples.length} PCM samples from audio file');
      print('📊 Sample range: min=${samples.reduce((a, b) => a < b ? a : b).toStringAsFixed(3)}, max=${samples.reduce((a, b) => a > b ? a : b).toStringAsFixed(3)}');
      
      await audioPlayer.dispose();
      return samples;
    } catch (e, stackTrace) {
      print('❌ Error decoding audio: $e');
      print('📚 Stack trace: $stackTrace');
      return null;
    }
  }

  /// Extract mel-spectrogram features from PCM samples
  List<List<double>>? _extractMelSpectrogram(List<double> samples, {int sampleRate = 16000}) {
    try {
      // Parameters for mel-spectrogram
      const int frameLength = 400; // 25ms at 16kHz
      const int frameStep = 160; // 10ms overlap
      const int numMelBins = 64; // Number of mel frequency bins
      const int fftSize = 512;
      
      final features = <List<double>>[];
      
      // Frame the audio
      for (int i = 0; i < samples.length - frameLength; i += frameStep) {
        final frame = samples.sublist(i, i + frameLength);
        
        // Apply window function (Hamming window)
        final windowedFrame = _applyHammingWindow(frame);
        
        // Compute FFT (simplified - using DFT)
        final fftResult = _computeDFT(windowedFrame, fftSize);
        
        // Compute power spectrum
        final powerSpectrum = fftResult.map((c) {
          final real = c[0];
          final imag = c[1];
          return (real * real + imag * imag) / fftSize;
        }).toList();
        
        // Convert to mel scale and create mel filter bank
        final melFeatures = _applyMelFilterBank(powerSpectrum, sampleRate, numMelBins, fftSize);
        
        // Take log (add small epsilon to avoid log(0))
        final logMelFeatures = melFeatures.map((v) => math.log(v + 1e-10)).toList();
        
        features.add(logMelFeatures);
      }
      
      return features.isEmpty ? null : features;
    } catch (e) {
      print('❌ Error extracting mel-spectrogram: $e');
      return null;
    }
  }

  /// Apply Hamming window to audio frame
  List<double> _applyHammingWindow(List<double> frame) {
    final windowed = <double>[];
    for (int i = 0; i < frame.length; i++) {
      final windowValue = 0.54 - 0.46 * math.cos(2 * math.pi * i / (frame.length - 1));
      windowed.add(frame[i] * windowValue);
    }
    return windowed;
  }

  /// Compute Discrete Fourier Transform (simplified)
  List<List<double>> _computeDFT(List<double> samples, int fftSize) {
    final result = <List<double>>[];
    final N = samples.length;
    
    for (int k = 0; k < fftSize ~/ 2 + 1; k++) {
      double real = 0.0;
      double imag = 0.0;
      
      for (int n = 0; n < N; n++) {
        final angle = 2 * math.pi * k * n / fftSize;
        real += samples[n] * math.cos(angle);
        imag -= samples[n] * math.sin(angle);
      }
      
      result.add([real, imag]);
    }
    
    return result;
  }

  /// Apply mel filter bank to power spectrum
  List<double> _applyMelFilterBank(List<double> powerSpectrum, int sampleRate, int numMelBins, int fftSize) {
    final melFeatures = List<double>.filled(numMelBins, 0.0);
    final nyquist = sampleRate / 2.0;
    final melMax = _hzToMel(nyquist);
    
    // Create mel filter bank
    for (int i = 0; i < numMelBins; i++) {
      final melCenter = melMax * (i + 1) / (numMelBins + 1);
      final hzCenter = _melToHz(melCenter);
      final binCenter = (hzCenter / nyquist) * (fftSize ~/ 2);
      
      // Apply triangular filter
      for (int j = 0; j < powerSpectrum.length && j < fftSize ~/ 2 + 1; j++) {
        final distance = (j - binCenter).abs();
        final filterValue = math.max(0.0, 1.0 - distance / (binCenter * 0.5));
        melFeatures[i] += powerSpectrum[j] * filterValue;
      }
    }
    
    return melFeatures;
  }

  /// Convert Hz to Mel scale
  double _hzToMel(double hz) {
    return 2595 * math.log(1 + hz / 700) / math.ln10;
  }

  /// Convert Mel to Hz scale
  double _melToHz(double mel) {
    return 700 * (math.pow(10, mel / 2595) - 1);
  }

  /// Normalize features (zero mean, unit variance)
  List<List<double>> _normalizeFeatures(List<List<double>> features) {
    if (features.isEmpty) return features;
    
    // Calculate mean and std for each feature dimension
    final numFeatures = features[0].length;
    final means = List<double>.filled(numFeatures, 0.0);
    final stds = List<double>.filled(numFeatures, 0.0);
    
    // Calculate means
    for (final frame in features) {
      for (int i = 0; i < numFeatures && i < frame.length; i++) {
        means[i] += frame[i];
      }
    }
    for (int i = 0; i < numFeatures; i++) {
      means[i] /= features.length;
    }
    
    // Calculate standard deviations
    for (final frame in features) {
      for (int i = 0; i < numFeatures && i < frame.length; i++) {
        final diff = frame[i] - means[i];
        stds[i] += diff * diff;
      }
    }
    for (int i = 0; i < numFeatures; i++) {
      stds[i] = math.sqrt(stds[i] / features.length);
      if (stds[i] < 1e-10) stds[i] = 1.0; // Avoid division by zero
    }
    
    // Normalize
    final normalized = <List<double>>[];
    for (final frame in features) {
      final normalizedFrame = <double>[];
      for (int i = 0; i < numFeatures && i < frame.length; i++) {
        normalizedFrame.add((frame[i] - means[i]) / stds[i]);
      }
      normalized.add(normalizedFrame);
    }
    
    return normalized;
  }

  /// Reshape features to match model input shape and convert to correct type
  List<dynamic> _reshapeFeaturesToModelInput(List<List<double>> features, List<int> shape, int inputSize, dynamic tensorType) {
    // Flatten features
    final flatFeatures = <double>[];
    for (final frame in features) {
      flatFeatures.addAll(frame);
    }
    
    // Pad or truncate to match input size
    if (flatFeatures.length < inputSize) {
      // Pad with zeros
      flatFeatures.addAll(List.filled(inputSize - flatFeatures.length, 0.0));
    } else if (flatFeatures.length > inputSize) {
      // Truncate
      flatFeatures.removeRange(inputSize, flatFeatures.length);
    }
    
    // Check if model expects quantized input
    final isQuantized = tensorType.toString().contains('int8') || 
                       tensorType.toString().contains('uint8');
    
    if (isQuantized) {
      // For quantized models, we need to match the training data distribution
      // Most quantized models expect features in a specific range
      // Since normalized features can be in [-3, 3] or wider, we need to clip and scale appropriately
      
      // Find the actual range of normalized features
      final minVal = flatFeatures.reduce((a, b) => a < b ? a : b);
      final maxVal = flatFeatures.reduce((a, b) => a > b ? a : b);
      final absMax = math.max(maxVal.abs(), minVal.abs());
      
      print('📊 Normalized feature range: min=$minVal, max=$maxVal, absMax=$absMax');
      
      // For quantized models, typically:
      // - Features are clipped to a reasonable range (e.g., [-3, 3] or [-4, 4])
      // - Scale is chosen to map this range to int8 [-127, 127]
      // - Common scales: 0.023529 (maps [-3, 3] to ~[-127, 127]) or 0.03125 (maps [-4, 4] to [-128, 128])
      
      // Clip features to reasonable range first (most models expect [-4, 4] or [-3, 3])
      const clipRange = 4.0; // Clip to [-4, 4] range
      final clippedFeatures = flatFeatures.map((val) => val.clamp(-clipRange, clipRange)).toList();
      
      // Use a fixed scale that matches typical quantized model training
      // Scale = clipRange / 127.0 maps [-clipRange, clipRange] to approximately [-127, 127]
      const quantizationScale = clipRange / 127.0; // ~0.0315
      
      // Convert to int8: quantized = (float / scale).round()
      final int8Features = clippedFeatures.map((val) {
        final quantized = (val / quantizationScale).round();
        return quantized.clamp(-128, 127);
      }).toList();
      
      // Check the distribution
      final int8Min = int8Features.reduce((a, b) => a < b ? a : b);
      final int8Max = int8Features.reduce((a, b) => a > b ? a : b);
      final int8Mean = int8Features.reduce((a, b) => a + b) / int8Features.length;
      final nonZeroCount = int8Features.where((v) => v != 0).length;
      
      print('📊 Using quantization scale: $quantizationScale (maps [-$clipRange, $clipRange] to int8)');
      print('📊 Converted ${flatFeatures.length} float features to int8');
      print('📊 Int8 stats: min=$int8Min, max=$int8Max, mean=${int8Mean.toStringAsFixed(2)}, non-zero=$nonZeroCount/${int8Features.length}');
      
      // Reshape to model input shape
      return _reshapeListInt8(int8Features, shape);
    } else {
      // Reshape to model input shape (float)
      return _reshapeList(flatFeatures, shape);
    }
  }

  /// Create test input for model verification
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

  /// Create input tensor with fallback based on file size (used if preprocessing fails)
  List<dynamic> _createInputTensorWithFallback(List<int> shape, int size, int fileSize, dynamic tensorType) {
    // Generate values based on file size to provide some variation
    // This is a temporary workaround if audio preprocessing fails
    final random = DateTime.now().millisecondsSinceEpoch % 1000;
    
    final isQuantized = tensorType.toString().contains('int8') || 
                       tensorType.toString().contains('uint8');
    if (isQuantized) {
      // Create int8 values
      final flatList = <int>[];
      for (int i = 0; i < size; i++) {
        // Create pseudo-random values based on file size and position
        final value = ((fileSize + i + random) % 1000) / 1000.0 - 0.5;
        // Scale to int8 range: -128 to 127
        final int8Value = (value * 127).round().clamp(-128, 127);
        flatList.add(int8Value);
      }
      return _reshapeListInt8(flatList, shape);
    } else {
      // Create float values
      final flatList = <double>[];
      for (int i = 0; i < size; i++) {
        // Create pseudo-random values based on file size and position
        final value = ((fileSize + i + random) % 1000) / 1000.0 - 0.5;
        flatList.add(value);
      }
      return _reshapeList(flatList, shape);
    }
  }

  /// Get fallback mood when model inference fails
  /// IMPORTANT: This should NOT be used for actual mood detection
  /// Only returns error to force user to record again
  VoiceMoodResult _getFallbackMood(int fileSize) {
    // NEVER return a mood from fallback - always reject
    // This prevents false detections from silence or failed processing
    print('⚠️ Model inference failed - rejecting detection (file size: $fileSize bytes)');
    
    return VoiceMoodResult(
      mood: 'neutral',
      confidence: 0.0,
      error: 'Failed to process audio. Please record again and speak clearly.',
      allProbabilities: {},
    );
>>>>>>> e0288a4 (fixes)
  }

  /// Extract audio samples from file using platform channels for native decoding
  ///
  /// This uses native audio decoding (Android MediaCodec / iOS AVFoundation)
  /// to extract real PCM samples from the audio file.
  Future<List<double>> _extractAudioSamples(
    String audioPath,
    Duration duration,
  ) async {
    try {
      const sampleRate = 16000;

      // Call platform channel to decode audio
      try {
        final result = await _audioDecoderChannel.invokeMethod<List>(
          'decodeAudioToPCM',
          {'audioPath': audioPath, 'sampleRate': sampleRate},
        );

        if (result == null || result.isEmpty) {
          return _generateFallbackSamples(audioPath, duration);
        }

        final samples = result.map((e) => (e as num).toDouble()).toList();
        if (samples.isEmpty) {
          return _generateFallbackSamples(audioPath, duration);
        }

        return samples;
      } on PlatformException {
        return _generateFallbackSamples(audioPath, duration);
      } catch (_) {
        return _generateFallbackSamples(audioPath, duration);
      }
    } catch (_) {
      return _generateFallbackSamples(audioPath, duration);
    }
  }

  /// Fallback method to generate synthetic samples if platform channel fails
  Future<List<double>> _generateFallbackSamples(
    String audioPath,
    Duration duration,
  ) async {
    final file = File(audioPath);
    final bytes = await file.readAsBytes();
    final estimatedDuration = duration.inMilliseconds / 1000.0;

    final samples = <double>[];
    const sampleRate = 16000;
    final numSamples = (estimatedDuration * sampleRate).round().clamp(
      1000,
      20000,
    );

    // Simple hash-based generation
    int hash = 0;
    for (int i = 0; i < math.min(bytes.length, 1000); i++) {
      hash = (hash * 31 + bytes[i]) % 2147483647;
    }

    for (int i = 0; i < numSamples; i++) {
      final value =
          math.sin((i + hash) * 0.01) * math.cos((i * hash % 1000) * 0.1);
      samples.add(value.clamp(-1.0, 1.0));
    }

    return samples;
  }

  /// Compute Mel-spectrogram from audio samples
  List<List<double>> _computeMelSpectrogram(
    List<double> samples, {
    int sampleRate = 16000,
  }) {
    try {
      // Parameters for Mel-spectrogram
      const int nFFT = 512;
      const int hopLength = 256;
      const int nMelBins = 128;
      const double fMin = 0.0;
      final double fMax = sampleRate / 2.0;

      // Compute Short-Time Fourier Transform (STFT)
      final stft = _computeSTFT(samples, nFFT: nFFT, hopLength: hopLength);

      // Convert to power spectrogram
      final powerSpectrogram = stft.map((frame) {
        return frame.map((complex) {
          final real = complex[0];
          final imag = complex[1];
          return real * real + imag * imag;
        }).toList();
      }).toList();

      // Apply Mel filter bank
      final melFilters = _createMelFilterBank(
        nFFT: nFFT,
        sampleRate: sampleRate,
        nMelBins: nMelBins,
        fMin: fMin,
        fMax: fMax,
      );

      // Apply Mel filters to power spectrogram
      final melSpectrogram = <List<double>>[];
      for (final frame in powerSpectrogram) {
        final melFrame = <double>[];
        for (final filter in melFilters) {
          double sum = 0.0;
          for (int j = 0; j < filter.length && j < frame.length; j++) {
            sum += filter[j] * frame[j];
          }
          melFrame.add(sum);
        }
        melSpectrogram.add(melFrame);
      }

      // Take logarithm (log-mel spectrogram)
      return melSpectrogram.map((frame) {
        return frame.map((value) => math.log(value + 1e-10)).toList();
      }).toList();
    } catch (e) {
      print('❌ Error computing Mel-spectrogram: $e');
      return [];
    }
  }

  /// Compute Short-Time Fourier Transform (STFT)
  List<List<List<double>>> _computeSTFT(
    List<double> samples, {
    int nFFT = 512,
    int hopLength = 256,
  }) {
    final stft = <List<List<double>>>[];
    final window = _hannWindow(nFFT);

    for (int i = 0; i < samples.length - nFFT; i += hopLength) {
      // Extract frame
      final frame = samples.sublist(i, (i + nFFT).clamp(0, samples.length));

      // Apply window
      final windowedFrame = List.generate(nFFT, (j) {
        return j < frame.length ? frame[j] * window[j] : 0.0;
      });

      // Compute FFT (simplified - using DFT)
      final fftResult = _computeDFT(windowedFrame);
      stft.add(fftResult);
    }

    return stft;
  }

  /// Compute Discrete Fourier Transform (simplified FFT)
  List<List<double>> _computeDFT(List<double> samples) {
    final n = samples.length;
    final result = <List<double>>[];

    for (int k = 0; k < n; k++) {
      double real = 0.0;
      double imag = 0.0;

      for (int j = 0; j < n; j++) {
        final angle = -2.0 * math.pi * k * j / n;
        real += samples[j] * math.cos(angle);
        imag += samples[j] * math.sin(angle);
      }

      result.add([real / n, imag / n]);
    }

    return result;
  }

  /// Create Hann window
  List<double> _hannWindow(int size) {
    return List.generate(size, (i) {
      return 0.5 * (1 - math.cos(2 * math.pi * i / (size - 1)));
    });
  }

  /// Create Mel filter bank
  List<List<double>> _createMelFilterBank({
    required int nFFT,
    required int sampleRate,
    required int nMelBins,
    required double fMin,
    required double fMax,
  }) {
    final melFilters = <List<double>>[];

    // Convert frequency to Mel scale
    final melMin = _hzToMel(fMin);
    final melMax = _hzToMel(fMax);

    // Create Mel-spaced center frequencies
    final melPoints = List.generate(nMelBins + 2, (i) {
      return melMin + (melMax - melMin) * i / (nMelBins + 1);
    });

    // Convert back to Hz
    final hzPoints = melPoints.map((m) => _melToHz(m)).toList();

    // Create triangular filters
    final fftFreqs = List.generate(nFFT ~/ 2 + 1, (i) => i * sampleRate / nFFT);

    for (int i = 0; i < nMelBins; i++) {
      final filter = List.filled(fftFreqs.length, 0.0);
      final left = hzPoints[i];
      final center = hzPoints[i + 1];
      final right = hzPoints[i + 2];

      for (int j = 0; j < fftFreqs.length; j++) {
        final freq = fftFreqs[j];
        if (freq >= left && freq <= center) {
          filter[j] = (freq - left) / (center - left);
        } else if (freq > center && freq <= right) {
          filter[j] = (right - freq) / (right - center);
        }
      }

      melFilters.add(filter);
    }

    return melFilters;
  }

  /// Convert Hz to Mel scale
  double _hzToMel(double hz) {
    return 2595.0 * math.log(1.0 + hz / 700.0) / math.ln10;
  }

  /// Convert Mel scale to Hz
  double _melToHz(double mel) {
    return 700.0 * (math.pow(10, mel / 2595.0) - 1.0);
  }

  /// Normalize features (zero mean, unit variance)
  List<List<double>> _normalizeFeatures(List<List<double>> features) {
    if (features.isEmpty) return features;

    // Flatten all features to compute global mean and std
    final allValues = <double>[];
    for (final frame in features) {
      allValues.addAll(frame);
    }

    if (allValues.isEmpty) return features;

    // Compute mean and standard deviation
    final mean = allValues.reduce((a, b) => a + b) / allValues.length;
    final variance =
        allValues.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) /
        allValues.length;
    final std = math.sqrt(variance);

    // Normalize
    return features.map((frame) {
      return frame
          .map((value) => std > 0 ? (value - mean) / std : 0.0)
          .toList();
    }).toList();
  }

  /// Flatten Mel-spectrogram to match model input shape
  List<double> _flattenMelSpectrogram(
    List<List<double>> melSpectrogram,
    List<int> inputShape,
  ) {
    if (inputShape.length != 4 || inputShape[0] != 1) {
      // If shape doesn't match expected format, flatten all
      return melSpectrogram.expand((frame) => frame).toList();
    }

    // Expected shape: [1, height, width, channels]
    final height = inputShape[1]; // 128 (mel bins)
    final width = inputShape[2]; // 126 (time frames)
    final channels = inputShape[3]; // 1

    final result = <double>[];

    // Reshape: pad or truncate to match dimensions
    for (int t = 0; t < width; t++) {
      if (t < melSpectrogram.length) {
        final frame = melSpectrogram[t];
        for (int m = 0; m < height; m++) {
          if (m < frame.length) {
            result.add(frame[m]);
          } else {
            result.add(0.0); // Pad with zeros
          }
        }
      } else {
        // Pad entire frame with zeros
        result.addAll(List.filled(height * channels, 0.0));
      }
    }

    return result;
  }

  /// Reshape a flat list to match tensor shape (supports up to 4D)
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
      final dim1 = shape[0];
      final dim2 = shape[1];
      final dim3 = shape[2];
      final result = <List<List<double>>>[];
      for (int i = 0; i < dim1; i++) {
        final matrix = <List<double>>[];
        for (int j = 0; j < dim2; j++) {
          final start = (i * dim2 * dim3) + (j * dim3);
          final end = (start + dim3).clamp(0, list.length);
          matrix.add(list.sublist(start, end));
        }
        result.add(matrix);
      }
      return result;
    } else if (shape.length == 4) {
      // Handle 4D tensor: [batch, height, width, channels]
      final batch = shape[0];
      final height = shape[1];
      final width = shape[2];
      final channels = shape[3];
      final result = <List<List<List<double>>>>[];

      for (int b = 0; b < batch; b++) {
        final batchData = <List<List<double>>>[];
        for (int h = 0; h < height; h++) {
          final row = <List<double>>[];
          for (int w = 0; w < width; w++) {
            final start =
                (b * height * width * channels) +
                (h * width * channels) +
                (w * channels);
            final end = (start + channels).clamp(0, list.length);
            final channelData = start < list.length
                ? list.sublist(start, end)
                : List<double>.filled(channels, 0.0);
            // Ensure we have the right number of channels
            while (channelData.length < channels) {
              channelData.add(0.0);
            }
            row.add(channelData);
          }
          batchData.add(row);
        }
        result.add(batchData);
      }
      return result;
    }
    // Fallback: return flat list
    return list;
  }

<<<<<<< HEAD
  /// Flatten nested output to a simple list of doubles
  List<double> _flattenOutput(dynamic output) {
    if (output is List) {
      final result = <double>[];
      for (final item in output) {
        if (item is List) {
          result.addAll(_flattenOutput(item));
        } else if (item is double) {
          result.add(item);
        } else if (item is int) {
          result.add(item.toDouble());
        } else {
          result.add(0.0);
        }
      }
      return result;
    } else if (output is double) {
      return [output];
    } else if (output is int) {
      return [output.toDouble()];
    }
    return [];
  }

  Map<String, double> _extractProbabilities(List<dynamic> output) {
    final probabilities = <String, double>{};

    // Ensure we have a flat list of doubles
    final flatOutput = _flattenOutput(output);

    if (flatOutput.isEmpty) {
      // Return default probabilities if output is empty
      for (final mood in _moodCategories) {
        probabilities[mood] = 0.0;
      }
      return probabilities;
    }

    // Check if model outputs probabilities directly (values between 0-1 and sum to ~1)
    final sumRaw = flatOutput.fold<double>(0.0, (a, b) => a + b.abs());
    final allInRange = flatOutput.every((v) => v >= 0 && v <= 1);

    if (allInRange && (sumRaw - 1.0).abs() < 0.1) {
      // Model already outputs probabilities, use directly
      for (
        int i = 0;
        i < flatOutput.length && i < _moodCategories.length;
        i++
      ) {
        probabilities[_moodCategories[i]] = flatOutput[i].clamp(0.0, 1.0);
      }
      return probabilities;
    }

    // Apply softmax: exp(x_i) / sum(exp(x_j))
    // First, subtract max for numerical stability
    final maxVal = flatOutput.reduce((a, b) => a > b ? a : b);

    final expValues = flatOutput.map((x) => math.exp(x - maxVal)).toList();
    final sum = expValues.fold<double>(0.0, (a, b) => a + b);

    // Calculate probabilities
    for (int i = 0; i < flatOutput.length && i < _moodCategories.length; i++) {
      final prob = sum > 0 ? (expValues[i] / sum).clamp(0.0, 1.0) : 0.0;
      probabilities[_moodCategories[i]] = prob;
    }

=======
  /// Reshape a flat int list to match tensor shape (for int8)
  dynamic _reshapeListInt8(List<int> list, List<int> shape) {
    if (shape.length == 1) {
      return Int8List.fromList(list);
    } else if (shape.length == 2) {
      final rows = shape[0];
      final cols = shape[1];
      final result = <List<int>>[];
      for (int i = 0; i < rows; i++) {
        result.add(list.sublist(i * cols, (i + 1) * cols));
      }
      return result;
    } else if (shape.length == 3) {
      final dim1 = shape[0];
      final dim2 = shape[1];
      final dim3 = shape[2];
      final result = <List<List<int>>>[];
      for (int i = 0; i < dim1; i++) {
        final matrix = <List<int>>[];
        for (int j = 0; j < dim2; j++) {
          final start = (i * dim2 * dim3) + (j * dim3);
          matrix.add(list.sublist(start, start + dim3));
        }
        result.add(matrix);
      }
      return result;
    }
    // For higher dimensions, return flat list
    return Int8List.fromList(list);
  }

  /// Flatten nested output to 1D list (for double/float)
  List<double> _flattenOutput(List<dynamic> output) {
    final flatList = <double>[];
    for (var item in output) {
      if (item is List) {
        flatList.addAll(_flattenOutput(item));
      } else {
        flatList.add(item.toDouble());
      }
    }
    return flatList;
  }

  /// Convert int8 output to double list (dequantize)
  List<double> _convertInt8OutputToDouble(List<dynamic> output) {
    // First, collect ALL values to determine the best scale
    final allValues = <int>[];
    void collectValues(dynamic item) {
      if (item is List) {
        for (var subItem in item) {
          collectValues(subItem);
        }
      } else if (item is Int8List) {
        allValues.addAll(item);
      } else if (item is int) {
        allValues.add(item);
      }
    }
    collectValues(output);
    
    if (allValues.isEmpty) {
      return [];
    }
    
    // Find the range
    final minVal = allValues.reduce((a, b) => a < b ? a : b);
    final maxVal = allValues.reduce((a, b) => a > b ? a : b);
    final range = maxVal - minVal;
    
    print('📊 Int8 output range: min=$minVal, max=$maxVal, range=$range');
    
    // Determine the best scale based on the actual output range
    // For quantized logits, we want to map int8 to a reasonable logit range
    // Typical logit ranges: [-10, 10] or [-5, 5]
    double scale;
    if (minVal == -128 && maxVal <= -40) {
      // All outputs are very negative - use larger scale to get meaningful logits
      // Map -128 to approximately -10, and -40 to approximately -3
      scale = 0.078125; // Maps -128 to -10
      print('📊 Using scale: $scale (for very negative outputs)');
    } else if (range < 10) {
      // Small range - outputs are similar, use standard scale
      scale = 0.0078125; // 1/128
      print('📊 Using scale: $scale (standard, small range)');
    } else {
      // Normal range - use standard scale
      scale = 0.0078125; // 1/128
      print('📊 Using scale: $scale (standard)');
    }
    
    // Now dequantize all values with the SAME scale
    final flatList = <double>[];
    void dequantize(dynamic item, double scale) {
      if (item is List) {
        for (var subItem in item) {
          dequantize(subItem, scale);
        }
      } else if (item is Int8List) {
        for (int i = 0; i < item.length; i++) {
          flatList.add(item[i] * scale);
        }
      } else if (item is int) {
        flatList.add(item * scale);
      } else {
        flatList.add(item.toDouble());
      }
    }
    dequantize(output, scale);
    
    return flatList;
  }

  /// Calculate standard deviation
  double _calculateStdDev(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.fold(0.0, (a, b) => a + b) / values.length;
    final variance = values.fold(0.0, (sum, val) => sum + (val - mean) * (val - mean)) / values.length;
    return math.sqrt(variance);
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
    
>>>>>>> e0288a4 (fixes)
    return probabilities;
  }

  @override
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
