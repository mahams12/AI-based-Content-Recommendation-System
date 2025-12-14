import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for recording voice audio
class VoiceRecordingService {
  static final VoiceRecordingService _instance = VoiceRecordingService._internal();
  factory VoiceRecordingService() => _instance;
  VoiceRecordingService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;

  /// Check and request microphone permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Start recording audio
  Future<bool> startRecording() async {
    try {
      // Check permission first
      if (!await hasPermission()) {
        final granted = await requestPermission();
        if (!granted) {
          return false;
        }
      }

      // Get temporary directory for recording
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/voice_recording_$timestamp.m4a';

      // Start recording
      if (await _recorder.hasPermission()) {
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 16000, // Standard for voice recognition
          ),
          path: _currentRecordingPath!,
        );
        _isRecording = true;
        _recordingStartTime = DateTime.now();
        return true;
      }
      return false;
    } catch (e) {
      print('Error starting recording: $e');
      return false;
    }
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    try {
      if (_isRecording) {
        final path = await _recorder.stop();
        _isRecording = false;
        
        // Check minimum recording duration (at least 1 second)
        if (_recordingStartTime != null) {
          final duration = DateTime.now().difference(_recordingStartTime!);
          if (duration.inMilliseconds < 1000) {
            print('⚠️ Recording too short: ${duration.inMilliseconds}ms');
            // Delete the short recording
            if (path != null) {
              final file = File(path);
              if (await file.exists()) {
                await file.delete();
              }
            }
            _recordingStartTime = null;
            return null; // Return null to indicate invalid recording
          }
        }
        
        _recordingStartTime = null;
        return path;
      }
      return _currentRecordingPath;
    } catch (e) {
      print('Error stopping recording: $e');
      _isRecording = false;
      _recordingStartTime = null;
      return null;
    }
  }

  /// Validate that audio file contains actual speech (not just silence)
  Future<bool> validateAudioHasSpeech(String audioPath) async {
    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        return false;
      }

      // Check file size - very small files are likely silence
      final fileSize = await file.length();
      if (fileSize < 8000) { // Less than 8KB is likely silence or very short (increased from 5KB)
        print('⚠️ Audio file too small: $fileSize bytes (likely silence)');
        return false;
      }

      // Check if file is reasonable size (not too large either - might be corrupted or long silence)
      if (fileSize > 200000) { // More than 200KB is suspicious for voice (reduced from 10MB)
        print('⚠️ Audio file too large: $fileSize bytes (might be silence or corrupted)');
        return false;
      }

      // Basic validation passed
      print('✅ Audio file validation passed: $fileSize bytes');
      return true;
    } catch (e) {
      print('Error validating audio: $e');
      return false;
    }
  }

  /// Cancel current recording
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;
      }
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
        _currentRecordingPath = null;
      }
    } catch (e) {
      print('Error canceling recording: $e');
    }
  }

  /// Check if currently recording
  bool get isRecording => _isRecording;

  /// Get current recording path
  String? get currentRecordingPath => _currentRecordingPath;

  /// Dispose resources
  Future<void> dispose() async {
    if (_isRecording) {
      await stopRecording();
    }
    await _recorder.dispose();
  }
}




