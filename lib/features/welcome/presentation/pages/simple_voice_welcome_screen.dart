import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/voice_recording_service.dart';
import '../../../../core/services/voice_mood_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/mood_based_filtering_service.dart';
import '../../../../core/models/content_model.dart';
import '../providers/mood_provider.dart';
import 'content_results_screen.dart';

/// Simplified welcome screen with single voice question and content fetching
class SimpleVoiceWelcomeScreen extends ConsumerStatefulWidget {
  const SimpleVoiceWelcomeScreen({super.key});

  @override
  ConsumerState<SimpleVoiceWelcomeScreen> createState() => _SimpleVoiceWelcomeScreenState();
}

class _SimpleVoiceWelcomeScreenState extends ConsumerState<SimpleVoiceWelcomeScreen>
    with TickerProviderStateMixin {
  final VoiceRecordingService _recordingService = VoiceRecordingService();
  final VoiceMoodService _moodService = VoiceMoodService();
  final ApiService _apiService = ApiService();
  final MoodBasedFilteringService _moodFilteringService = MoodBasedFilteringService();
  
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isInitialized = false;
  bool _showFilters = false;
  bool _isFetchingContent = false;
  String? _detectedMood;
  String? _gptInterpretedMood;
  Timer? _recordingTimer;
  DateTime? _recordingStartTime;

  // Dual mode: tap-to-record vs hold-to-record
  static const int _holdThresholdMs = 400; // Press longer than this = hold gesture
  static const int _minTapToStopRecordingMs = 600; // Min recording time before tap can stop (prevents accidental double-tap)
  bool _recordingStartedByHold = false; // true = started by long-press; false = started by tap
  DateTime? _pressStartTime;
  Timer? _holdTimer;
  DateTime? _tapModeRecordingStartedAt; // When tap-mode recording started (for min duration before tap-to-stop)

  // Content type filters
  final Set<ContentType> _selectedContentTypes = {ContentType.youtube, ContentType.tmdb, ContentType.spotify};

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeServices();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _fadeController.forward();
  }

  Future<void> _initializeServices() async {
    setState(() => _isProcessing = true);

    // Initialize voice mood service
    print('🔄 Initializing voice mood detection service...');
    final moodInitialized = await _moodService.initialize();
    
    if (!moodInitialized) {
      print('❌ Voice mood service initialization failed');
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _isProcessing = false;
        });
        _showError('Failed to initialize voice mood detection model. Please check console logs for details.');
        return;
      }
    }
    
    // Check microphone permission
    final hasPermission = await _recordingService.hasPermission();
    if (!hasPermission) {
      final granted = await _recordingService.requestPermission();
      if (!granted && mounted) {
        _showError('Microphone permission is required for voice mood detection');
        return;
      }
    }

    setState(() {
      _isInitialized = moodInitialized;
      _isProcessing = false;
    });

    if (moodInitialized) {
      print('✅ Voice mood detection service initialized successfully');
    }
  }

  /// Called when press ends (tap up or cancel). Differentiates tap vs hold and starts/stops recording.
  void _handlePressEnd({required bool cancel}) {
    _holdTimer?.cancel();
    _holdTimer = null;
    if (_pressStartTime == null) return;
    final duration = DateTime.now().difference(_pressStartTime!);
    _pressStartTime = null;

    if (_isRecording) {
      if (_recordingStartedByHold) {
        _stopRecording();
        return;
      }
      // Tap mode: stop only if min duration elapsed (prevents accidental double-tap) or gesture was cancelled
      if (_tapModeRecordingStartedAt != null) {
        final recordingDuration = DateTime.now().difference(_tapModeRecordingStartedAt!);
        if (recordingDuration.inMilliseconds >= _minTapToStopRecordingMs || cancel) {
          _stopRecording();
        }
      } else {
        _stopRecording();
      }
      return;
    }

    if (cancel) return;
    // Short press = tap to start recording
    if (duration.inMilliseconds < _holdThresholdMs) {
      _recordingStartedByHold = false;
      _tapModeRecordingStartedAt = DateTime.now();
      _startRecording();
    }
    // Long press but timer didn't fire in time (e.g. scheduler delay): start recording so release can stop
    else if (mounted && _isInitialized) {
      _recordingStartedByHold = true;
      _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (_isRecording || !_isInitialized) return;

    final started = await _recordingService.startRecording();
    if (started) {
      _recordingStartTime = DateTime.now();
      setState(() => _isRecording = true);
      // Auto-stop after 10 seconds maximum (both modes)
      _recordingTimer = Timer(const Duration(seconds: 10), () {
        if (_isRecording) {
          _stopRecording();
        }
      });
    } else {
      _showError('Failed to start recording. Please check microphone permissions.');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    _holdTimer?.cancel();
    _holdTimer = null;
    _pressStartTime = null;
    _tapModeRecordingStartedAt = null;
    _recordingStartedByHold = false;

    // Cancel auto-stop timer
    _recordingTimer?.cancel();
    _recordingTimer = null;

    // Check minimum duration (2 seconds)
    if (_recordingStartTime != null) {
      final duration = DateTime.now().difference(_recordingStartTime!);
      if (duration.inMilliseconds < 2000) {
        // Too short - wait a bit more or show message
        final remaining = 2000 - duration.inMilliseconds;
        print('⚠️ Recording too short: ${duration.inMilliseconds}ms, need ${remaining}ms more');
        
        // Wait for minimum duration
        await Future.delayed(Duration(milliseconds: remaining));
      }
    }

    setState(() {
      _isRecording = false;
      _isProcessing = true;
    });

    final audioPath = await _recordingService.stopRecording();
    _recordingStartTime = null;
    
    print('🎤 ========== AUDIO RECORDING CHECK ==========');
    print('🎤 Audio path: $audioPath');
    
    if (audioPath == null) {
      print('❌ Recording returned null - too short or failed');
      _showError('Recording too short. Please speak for at least 1 second.');
      setState(() {
        _isProcessing = false;
      });
      return;
    }
    
    final audioFile = File(audioPath);
    if (!audioFile.existsSync()) {
      print('❌ Audio file does not exist at path: $audioPath');
      _showError('Failed to record audio. Please try again.');
      setState(() {
        _isProcessing = false;
      });
      return;
    }
    
    // Check audio file properties
    final fileSize = await audioFile.length();
    print('🎤 Audio file size: $fileSize bytes');
    
    if (fileSize == 0) {
      print('❌ Audio file is empty');
      _showError('Audio file is empty. Please try recording again.');
      setState(() {
        _isProcessing = false;
      });
      return;
    }
    
    // Strict validation: require that the recording actually contains speech.
    // This prevents detecting a mood when the user doesn't say anything.
    final hasSpeech = await _recordingService.validateAudioHasSpeech(audioPath);
    if (!hasSpeech) {
      print('❌ validateAudioHasSpeech returned false – likely silence.');
      _showError('No speech detected. Please hold the button and speak clearly.');
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    print('🎤 Audio validation passed, proceeding to mood detection...');
    print('🎤 ===========================================');

    // Process the audio to detect mood using YAMNet
    print('🎤 Processing audio with YAMNet model...');
    final result = await _moodService.detectMoodFromAudio(audioPath);
    // result.mood is the single source of truth from the model pipeline; UI displays it without overwriting.
    // VERY RELAXED Validation: Accept almost all detections
    // Only reject if it's clearly an error or extremely low confidence
    final isNeutralWithExtremelyHighConfidence = result.mood == 'neutral' && result.confidence > 0.85;
    
    print('📊 ========== DETECTION RESULT ==========');
    print('📊 Mood: ${result.mood}');
    print('📊 Confidence: ${(result.confidence * 100).toStringAsFixed(2)}%');
    print('📊 Error: ${result.error ?? "None"}');
    print('📊 Is Success: ${result.isSuccess}');
    if (result.allProbabilities != null && result.allProbabilities!.isNotEmpty) {
      print('📊 All probabilities:');
      result.allProbabilities!.forEach((mood, prob) {
        print('   $mood: ${(prob * 100).toStringAsFixed(2)}%');
      });
    }
    print('📊 ======================================');
    
    // Accept if successful - accept any mood regardless of confidence (like before)
    // Only reject if there's an actual error or extremely dominant neutral (likely silence)
    if (result.isSuccess && result.error == null && !isNeutralWithExtremelyHighConfidence) {
      setState(() {
        _detectedMood = result.mood; // Exact label from backend; no default or override.
      });
      
      print('✅ ACCEPTED: YAMNet detected mood: ${result.mood} (confidence: ${(result.confidence * 100).toStringAsFixed(1)}%)');
      
      // Use GPT to interpret the mood (enhanced interpretation)
      await _interpretMoodWithGPT(result);
    } else {
      // Only reject if error or extremely dominant neutral (likely silence)
      String errorMsg;
      if (isNeutralWithExtremelyHighConfidence) {
        errorMsg = 'No speech detected. Please speak clearly when recording.';
      } else if (result.error != null) {
        errorMsg = result.error!;
      } else {
        errorMsg = 'Failed to detect mood from voice. Please try again.';
      }
      
      print('❌ REJECTED: confidence=${result.confidence}, mood=${result.mood}, error=${result.error}');
      print('💡 Try speaking louder or closer to the microphone');
      _showError(errorMsg);
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _interpretMoodWithGPT(dynamic yamnetResult) async {
    try {
      print('🤖 Interpreting mood with GPT...');
      
      // For now, use AI service sentiment analysis as GPT fallback
      // TODO: Integrate OpenAI GPT API for enhanced mood interpretation
      // In production, you'd call OpenAI API here
      final interpretedMood = _enhanceMoodInterpretation(yamnetResult.mood, yamnetResult.allProbabilities);
      
      setState(() {
        _gptInterpretedMood = interpretedMood;
        _showFilters = true;
        _isProcessing = false;
      });
      
      print('✅ GPT interpreted mood: $interpretedMood');
    } catch (e) {
      print('⚠️ GPT interpretation failed, using YAMNet result: $e');
      setState(() {
        _gptInterpretedMood = _detectedMood ?? 'neutral';
        _showFilters = true;
        _isProcessing = false;
      });
    }
  }

  String _enhanceMoodInterpretation(String baseMood, Map<String, double>? probabilities) {
    // Enhanced mood interpretation based on probabilities
    if (probabilities == null || probabilities.isEmpty) {
      return baseMood;
    }
    
    // Find top 2 moods
    final sorted = probabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (sorted.length >= 2) {
      final top1 = sorted[0];
      final top2 = sorted[1];
      
      // If top moods are close, use combined interpretation
      if ((top1.value - top2.value) < 0.2) {
        // Combine moods for better interpretation
        if ((top1.key == 'happy' && top2.key == 'excited') || 
            (top1.key == 'excited' && top2.key == 'happy')) {
          return 'excited';
        }
        if ((top1.key == 'sad' && top2.key == 'calm') || 
            (top1.key == 'calm' && top2.key == 'sad')) {
          return 'melancholic';
        }
      }
    }
    
    return baseMood;
  }

  void _toggleContentType(ContentType type) {
    setState(() {
      if (_selectedContentTypes.contains(type)) {
        _selectedContentTypes.remove(type);
      } else {
        _selectedContentTypes.add(type);
      }
    });
  }

  Future<void> _fetchAndShowContent() async {
    if (_selectedContentTypes.isEmpty) {
      _showError('Please select at least one content type');
      return;
    }

    setState(() {
      _isFetchingContent = true;
    });

    try {
      final finalMood = _gptInterpretedMood ?? _detectedMood ?? 'neutral';
      print('📡 Fetching content for mood: $finalMood, types: $_selectedContentTypes');
      
      // Fetch content based on selected types
      final List<ContentItem> allContent = [];
      
      for (final contentType in _selectedContentTypes) {
        print('📡 Fetching ${contentType.name} content...');
        final result = await _apiService.getExtendedTrendingContent(
          platform: contentType,
          maxResults: 50, // Fetch maximum data
        );
        
        if (result.isSuccess && result.data != null && result.data!.isNotEmpty) {
          allContent.addAll(result.data!);
          print('✅ Fetched ${result.data!.length} items from ${contentType.name}');
        } else {
          print('⚠️ Failed to fetch ${contentType.name} content: ${result.error ?? "Unknown error"}');
          // Try alternative method if extended fails
          try {
            final altResult = await _apiService.getTrendingContent(maxResultsPerPlatform: 20);
            if (altResult.isSuccess && altResult.data != null && altResult.data!.isNotEmpty) {
              // Filter by platform
              final platformContent = altResult.data!.where((item) => item.platform == contentType).toList();
              if (platformContent.isNotEmpty) {
                allContent.addAll(platformContent);
                print('✅ Fetched ${platformContent.length} items from ${contentType.name} (alternative method)');
              }
            }
          } catch (e) {
            print('❌ Alternative fetch also failed for ${contentType.name}: $e');
          }
        }
      }
      
      print('📦 Total content fetched: ${allContent.length}');
      
      // If still no content, show error
      if (allContent.isEmpty) {
        _showError('No content available. Please check your internet connection and try again.');
        setState(() {
          _isFetchingContent = false;
        });
        return;
      }
      
      // Shuffle content for variety before filtering
      allContent.shuffle();
      
      // Filter content by mood using mood filtering service
      List<ContentItem> moodFilteredContent;
      if (allContent.isEmpty) {
        print('⚠️ No content fetched from APIs, using empty list');
        moodFilteredContent = [];
      } else {
        print('🎯 Filtering ${allContent.length} items by mood: $finalMood');
        moodFilteredContent = await _moodFilteringService.filterContentByMood(
          content: allContent,
          mood: finalMood,
          maxResults: 100,
        );
        
        print('✅ Mood-filtered content: ${moodFilteredContent.length} items for mood: $finalMood');
        
        // Log sample items for debugging
        if (moodFilteredContent.isNotEmpty) {
          print('📋 Sample filtered items:');
          for (int i = 0; i < min(3, moodFilteredContent.length); i++) {
            final item = moodFilteredContent[i];
            print('   ${i + 1}. ${item.title} (${item.platform.name}) - Genres: ${item.genres.join(", ")}');
          }
        }
        
        // If mood filtering returns too few items, use original content (with limit, shuffled)
        if (moodFilteredContent.length < 10 && allContent.isNotEmpty) {
          print('⚠️ Mood filtering returned too few items (${moodFilteredContent.length}), using shuffled top 50 items from all content');
          moodFilteredContent = allContent.take(50).toList();
          moodFilteredContent.shuffle();
        }
      }
      
      // Final validation - ensure we have content to show (shuffled)
      if (moodFilteredContent.isEmpty) {
        print('⚠️ No content after filtering, using shuffled all fetched content');
        moodFilteredContent = allContent.take(50).toList();
        moodFilteredContent.shuffle();
      }
      
      print('✅ Final content count: ${moodFilteredContent.length} items');
      
      // Debug: Log first few content items
      if (moodFilteredContent.isNotEmpty) {
        print('📋 Sample content items:');
        for (int i = 0; i < moodFilteredContent.length && i < 3; i++) {
          final item = moodFilteredContent[i];
          print('   ${i + 1}. ${item.title} (${item.platform.name})');
        }
      } else {
        print('⚠️ WARNING: moodFilteredContent is EMPTY!');
        print('📊 allContent length: ${allContent.length}');
      }
      
      // Save mood data
      final moodData = {
        'detected_mood': _detectedMood,
        'interpreted_mood': finalMood,
        'content_types': _selectedContentTypes.map((e) => e.name).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      ref.read(moodProvider.notifier).setMoodData(moodData);
      await StorageService.setString('user_mood_data', moodData.toString());
      await StorageService.setBool('has_completed_welcome', true);
      await StorageService.saveUserMood(finalMood);
      
      // Navigate to content results screen
      if (mounted) {
        print('🚀 Navigating to ContentResultsScreen with ${moodFilteredContent.length} items');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ContentResultsScreen(
              content: moodFilteredContent,
              mood: finalMood,
              contentTypes: _selectedContentTypes.toList(),
            ),
          ),
        );
      } else {
        print('⚠️ Widget not mounted, cannot navigate');
      }
    } catch (e) {
      print('❌ Error fetching content: $e');
      _showError('Failed to fetch content. Please try again.');
      setState(() {
        _isFetchingContent = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _holdTimer?.cancel();
    _pulseController.dispose();
    _fadeController.dispose();
    _recordingService.dispose();
    _moodService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppTheme.backgroundGradient,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  'Initializing voice mood detection...',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: AppTheme.primaryGradient,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.psychology_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ContentNation',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Voice Mood Detection',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        
                        if (!_showFilters) ...[
                          // Question Text
                          Text(
                            'Say something to detect your mood',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 60),
                          
                          // Recording Button (tap to start/stop, or hold to record)
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _isRecording ? _pulseAnimation.value : 1.0,
                                child: GestureDetector(
                                  onTapDown: (_) {
                                    _holdTimer?.cancel();
                                    _pressStartTime = DateTime.now();
                                    _holdTimer = Timer(
                                      Duration(milliseconds: _holdThresholdMs),
                                      () {
                                        _holdTimer = null;
                                        if (mounted && !_isRecording && _isInitialized) {
                                          _recordingStartedByHold = true;
                                          _startRecording();
                                        }
                                      },
                                    );
                                  },
                                  onTapUp: (_) => _handlePressEnd(cancel: false),
                                  onTapCancel: () => _handlePressEnd(cancel: true),
                                  child: Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: _isRecording
                                          ? LinearGradient(
                                              colors: [
                                                Colors.red,
                                                Colors.red.shade700,
                                              ],
                                            )
                                          : LinearGradient(
                                              colors: AppTheme.primaryGradient,
                                            ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_isRecording ? Colors.red : AppTheme.primaryColor)
                                              .withOpacity(0.4),
                                          blurRadius: 30,
                                          spreadRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _isRecording ? Icons.stop : Icons.mic,
                                      color: Colors.white,
                                      size: 60,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Status Text
                          if (_isProcessing)
                            Column(
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                Text(
                                  'Processing your response...',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            )
                          else if (_isRecording)
                            Text(
                              _recordingStartedByHold
                                  ? 'Recording... Release to stop'
                                  : 'Recording... Tap again to stop',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                color: Colors.red.shade300,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          else
                            Text(
                              'Tap to start, tap again to stop\nOr hold to record',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                        ],
                        
                        // Filters Section
                        if (_showFilters) ...[
                          // Mood Result
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: AppTheme.primaryGradient,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Your Mood',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _gptInterpretedMood?.toUpperCase() ?? 'NEUTRAL',
                                  style: GoogleFonts.inter(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                if (_detectedMood != null)
                                  Text(
                                    'Detected: $_detectedMood', // Exact backend label (angry, fear, sad, etc.); no remap or default.
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Content Type Filters
                          Text(
                            'What would you like to watch or listen to?',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Content Type Options
                          _buildContentTypeFilter(
                            '🎬 Movies & Shows',
                            ContentType.tmdb,
                            Icons.movie_rounded,
                          ),
                          const SizedBox(height: 12),
                          _buildContentTypeFilter(
                            '🎵 Music & Songs',
                            ContentType.spotify,
                            Icons.music_note_rounded,
                          ),
                          const SizedBox(height: 12),
                          _buildContentTypeFilter(
                            '📺 YouTube Videos',
                            ContentType.youtube,
                            Icons.play_circle_rounded,
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Fetch Content Button
                          if (_isFetchingContent)
                            const CircularProgressIndicator()
                          else
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _fetchAndShowContent,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'Get My Content',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentTypeFilter(String label, ContentType type, IconData icon) {
    final isSelected = _selectedContentTypes.contains(type);
    
    return GestureDetector(
      onTap: () => _toggleContentType(type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryColor
                : Colors.white.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.7),
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: Colors.white,
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

