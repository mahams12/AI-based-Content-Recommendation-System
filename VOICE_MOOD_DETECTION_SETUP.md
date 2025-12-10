# Voice Mood Detection Setup Guide

## Overview
This document explains the voice-based mood detection feature and how to complete the audio preprocessing implementation.

## Current Implementation Status

✅ **Completed:**
- Voice recording service with microphone permissions
- TFLite model loading infrastructure
- Voice mood detection UI with 4-5 questions (English & Urdu support)
- Integration into welcome screen flow
- Mood data storage and provider integration

⚠️ **Needs Implementation:**
- Audio preprocessing (converting audio to model input format)

## Audio Preprocessing Requirements

The current implementation includes a **placeholder** for audio preprocessing. You need to implement proper audio feature extraction based on your model's training requirements.

### What Your Model Likely Needs:

1. **Audio Format Conversion**
   - Convert recorded audio (M4A/AAC) to raw PCM samples
   - Resample to match training sample rate (typically 16kHz or 22kHz)
   - Normalize audio levels

2. **Feature Extraction**
   - **MFCC (Mel-Frequency Cepstral Coefficients)** - Common for speech/voice models
   - **Mel-Spectrogram** - Alternative feature representation
   - **Log-Mel Spectrogram** - Often used for emotion recognition
   - Frame-based features (typically 25ms windows with 10ms overlap)

3. **Normalization**
   - Normalize features to match training data distribution
   - Mean/variance normalization or min-max scaling

4. **Tensor Reshaping**
   - Reshape features to match model input shape
   - Typically: `[batch_size, time_frames, feature_dim]` or `[batch_size, feature_dim, time_frames]`

### Implementation Steps

1. **Add Audio Processing Package**
   ```yaml
   dependencies:
     # Choose one based on your needs:
     flutter_sound: ^9.2.13  # For audio processing
     # OR
     audioplayers: ^5.2.1    # Simpler audio handling
   ```

2. **Implement Audio Preprocessing**
   - Update `_createInputTensor()` method in `lib/core/services/voice_mood_service.dart`
   - Load audio file and extract features
   - Convert to model input format

3. **Example Structure** (pseudo-code):
   ```dart
   Future<List<dynamic>> _preprocessAudio(String audioPath) async {
     // 1. Load audio file
     final audioData = await loadAudioFile(audioPath);
     
     // 2. Convert to PCM samples
     final samples = convertToPCM(audioData, sampleRate: 16000);
     
     // 3. Extract features (MFCC or Mel-spectrogram)
     final features = extractMFCC(samples, 
       frameLength: 400,  // 25ms at 16kHz
       frameStep: 160,    // 10ms overlap
       numCoefficients: 13
     );
     
     // 4. Normalize features
     final normalized = normalizeFeatures(features);
     
     // 5. Reshape to model input shape
     return _reshapeList(normalized, inputShape);
   }
   ```

### Model Input/Output Information

To implement preprocessing correctly, you need to know:
- **Input shape**: Check your model's expected input dimensions
- **Feature type**: What features your model was trained on (MFCC, Mel-spectrogram, etc.)
- **Normalization**: How features were normalized during training
- **Sample rate**: Audio sample rate used during training

You can inspect your model using:
```python
import tensorflow as tf
interpreter = tf.lite.Interpreter(model_path="my_model.tflite")
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()
print("Input shape:", input_details[0]['shape'])
print("Input type:", input_details[0]['dtype'])
```

## Testing

1. **Test Recording**
   - Verify microphone permissions are granted
   - Test recording starts/stops correctly
   - Check audio files are saved properly

2. **Test Model Loading**
   - Verify model loads without errors
   - Check input/output shapes match expectations

3. **Test Mood Detection**
   - Record test audio samples
   - Verify mood detection returns reasonable results
   - Test with both English and Urdu speech

## Troubleshooting

### Model Not Loading
- Check model file path: `assets/models/voice/my_model.tflite`
- Verify model is included in `pubspec.yaml` assets
- Check model file size (should be reasonable, not 0 bytes)

### Audio Processing Errors
- Verify audio file format is supported
- Check sample rate matches model expectations
- Ensure feature extraction matches training pipeline

### Low Accuracy
- Verify audio preprocessing matches training pipeline exactly
- Check normalization is applied correctly
- Ensure input shape matches model expectations
- Consider adding noise reduction or voice activity detection

## Next Steps

1. **Implement Audio Preprocessing**
   - Replace placeholder in `_createInputTensor()` method
   - Test with sample audio files
   - Verify output matches model input requirements

2. **Optimize Performance**
   - Consider caching preprocessed features
   - Optimize feature extraction for real-time use
   - Add progress indicators for long processing

3. **Enhance User Experience**
   - Add voice activity detection (auto-stop when silent)
   - Show audio waveform visualization
   - Add playback of recorded audio before submission

## Resources

- [TensorFlow Lite Flutter Plugin](https://pub.dev/packages/tflite_flutter)
- [Record Package Documentation](https://pub.dev/packages/record)
- [Audio Processing in Flutter](https://docs.flutter.dev/development/data-and-backend/state-mgmt/options)

## Support

For issues or questions:
1. Check model input/output requirements
2. Verify audio preprocessing matches training pipeline
3. Test with known good audio samples
4. Review error logs for specific issues




