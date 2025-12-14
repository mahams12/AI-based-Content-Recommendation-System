# YAMNet Model Integration Guide

## ⚠️ Current Issue

The YAMNet model is **NOT actually processing audio** - it's using a fallback method that generates pseudo-random values based on file size. This is why you're seeing "neutral" detected most of the time.

## Why This Is Happening

The current implementation in `voice_mood_service_mobile.dart` uses `_createInputTensorWithFallback()` which:
- Generates random values based on file size
- Does NOT extract actual audio features
- Does NOT convert audio to the format YAMNet expects

## What YAMNet Actually Needs

YAMNet requires:
1. **Raw audio samples** (PCM format, 16kHz sample rate)
2. **Mel-spectrogram extraction** (or similar audio features)
3. **Proper normalization** matching your training data

## Solutions

### Option 1: Use a Flutter Audio Processing Package (Recommended)

Add proper audio preprocessing using a package like `flutter_sound` or `audioplayers`:

```yaml
dependencies:
  flutter_sound: ^9.2.13  # For audio processing
  # OR
  audioplayers: ^5.2.1    # Simpler option
```

Then implement proper audio feature extraction in `_createInputTensor()` method.

### Option 2: Use Platform Channels (More Complex)

Create native Android/iOS code to:
1. Load audio file
2. Extract mel-spectrogram features
3. Return features to Flutter
4. Pass to TFLite model

### Option 3: Pre-process Audio Server-Side

1. Send audio to a server
2. Server extracts features
3. Return features to app
4. Run model inference locally

## Quick Test to Verify Model Works

To test if your model actually works:

1. **Check model input/output shapes:**
   ```dart
   final inputShape = _interpreter!.getInputTensor(0).shape;
   final outputShape = _interpreter!.getOutputTensor(0).shape;
   print('Input shape: $inputShape');
   print('Output shape: $outputShape');
   ```

2. **Test with known audio samples:**
   - Record a clear "happy" voice sample
   - Record a clear "sad" voice sample
   - If model detects correctly → model works, preprocessing needed
   - If model always detects "neutral" → model or preprocessing issue

3. **Check model output:**
   - Look at console logs for probability distributions
   - If all probabilities are similar → silence or preprocessing issue
   - If one probability is much higher → model is working, but preprocessing may be wrong

## Implementation Steps (Option 1 - Recommended)

### Step 1: Add Audio Processing Package

```yaml
dependencies:
  flutter_sound: ^9.2.13
```

### Step 2: Update `voice_mood_service_mobile.dart`

Replace `_createInputTensorWithFallback()` with:

```dart
Future<List<dynamic>> _preprocessAudio(String audioPath) async {
  // 1. Load audio file
  final audioFile = File(audioPath);
  final bytes = await audioFile.readAsBytes();
  
  // 2. Convert M4A to PCM (16kHz)
  // Use flutter_sound or similar to decode audio
  final pcmSamples = await _decodeAudioToPCM(bytes, sampleRate: 16000);
  
  // 3. Extract mel-spectrogram
  final melSpectrogram = _extractMelSpectrogram(pcmSamples);
  
  // 4. Normalize
  final normalized = _normalizeFeatures(melSpectrogram);
  
  // 5. Reshape to model input
  return _reshapeList(normalized, inputShape);
}
```

### Step 3: Implement Feature Extraction

You'll need to implement:
- Audio decoding (M4A → PCM)
- Mel-spectrogram extraction
- Feature normalization

## Debugging Tips

1. **Check console logs:**
   - Look for "⚠️ WARNING: Using fallback audio processing"
   - Check probability distributions
   - Verify file sizes are reasonable

2. **Test with different audio:**
   - Try speaking loudly vs quietly
   - Try different durations
   - Try different emotions

3. **Verify model file:**
   - Check model file size (should be reasonable, not 0 bytes)
   - Verify model loads without errors
   - Check input/output shapes match expectations

## Current Workaround

Until proper preprocessing is implemented:
- The model will mostly detect "neutral"
- Silence detection helps reject empty recordings
- File size-based fallback provides some variation (but not accurate)

## Next Steps

1. **Immediate:** The silence detection is improved to reject more false positives
2. **Short-term:** Implement basic audio preprocessing (PCM conversion)
3. **Long-term:** Full mel-spectrogram extraction matching training pipeline

## Resources

- [TensorFlow Lite Flutter](https://pub.dev/packages/tflite_flutter)
- [Flutter Sound Package](https://pub.dev/packages/flutter_sound)
- [YAMNet Paper](https://arxiv.org/abs/1809.04381)
- [Audio Feature Extraction Guide](https://www.tensorflow.org/tutorials/audio/simple_audio)

