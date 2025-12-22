import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/voice_recording_service.dart';
import '../../../../core/services/voice_mood_service.dart';
import '../../../../core/services/voice_mood_result.dart';
import '../../../../core/services/storage_service.dart';
import '../providers/mood_provider.dart';

/// Voice-based mood detection screen with 4-5 questions
class VoiceMoodDetectionScreen extends ConsumerStatefulWidget {
  const VoiceMoodDetectionScreen({super.key});

  @override
  ConsumerState<VoiceMoodDetectionScreen> createState() => _VoiceMoodDetectionScreenState();
}

class _VoiceMoodDetectionScreenState extends ConsumerState<VoiceMoodDetectionScreen>
    with TickerProviderStateMixin {
  final VoiceRecordingService _recordingService = VoiceRecordingService();
  final VoiceMoodService _moodService = VoiceMoodService();
  
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  int _currentQuestionIndex = 0;
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isInitialized = false;
  final List<String> _recordedAudioPaths = [];
  final Map<String, dynamic> _moodData = {};
  int _recordingDuration = 0; // in seconds
  Timer? _recordingTimer;

  final List<VoiceQuestion> _questions = [
    VoiceQuestion(
      question: "How are you feeling right now?",
      questionUrdu: "آپ اب کیسا محسوس کر رہے ہیں؟",
      key: "feeling",
    ),
    VoiceQuestion(
      question: "What type of content are you in the mood for today?",
      questionUrdu: "آج آپ کس قسم کے مواد کے موڈ میں ہیں؟",
      key: "content_preference",
    ),
    VoiceQuestion(
      question: "What's your current energy level?",
      questionUrdu: "آپ کی موجودہ توانائی کی سطح کیا ہے؟",
      key: "energy_level",
    ),
    VoiceQuestion(
      question: "How much time do you have for content right now?",
      questionUrdu: "آپ کے پاس اب مواد کے لیے کتنا وقت ہے؟",
      key: "time_availability",
    ),
    VoiceQuestion(
      question: "What would help you feel better right now?",
      questionUrdu: "اب آپ کو بہتر محسوس کرنے میں کیا مدد کرے گا؟",
      key: "wellness_need",
    ),
  ];

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
        // Don't navigate away - let user see the error
        return;
      }
    }
    
    // Check microphone permission
    final hasPermission = await _recordingService.hasPermission();
    if (!hasPermission) {
      final granted = await _recordingService.requestPermission();
      if (!granted && mounted) {
        _showError('Microphone permission is required for voice mood detection');
        Navigator.of(context).pop();
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

  Future<void> _startRecording() async {
    if (_isRecording) return;

    final started = await _recordingService.startRecording();
    if (started) {
      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
      });
      // Start timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && _isRecording) {
          setState(() {
            _recordingDuration++;
          });
        } else {
          timer.cancel();
        }
      });
    } else {
      _showError('Failed to start recording. Please check microphone permissions.');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    // Stop timer
    _recordingTimer?.cancel();
    _recordingTimer = null;

    setState(() {
      _isRecording = false;
      _isProcessing = true;
    });

    final audioPath = await _recordingService.stopRecording();
    
    // Validate recording
    if (audioPath == null || !File(audioPath).existsSync()) {
      setState(() => _isProcessing = false);
      _showError('Recording failed. Please try again.');
      return;
    }

    // Validate minimum duration (at least 1 second)
    if (_recordingDuration < 1) {
      setState(() => _isProcessing = false);
      _showError('Recording too short. Please record for at least 1 second.');
      // Delete the short recording
      try {
        await File(audioPath).delete();
      } catch (e) {
        print('Error deleting short recording: $e');
      }
      return;
    }

    // Validate file size (at least 1KB)
    final audioFile = File(audioPath);
    final fileSize = await audioFile.length();
    if (fileSize < 1024) {
      setState(() => _isProcessing = false);
      _showError('Recording file is too small. Please try again.');
      try {
        await audioFile.delete();
      } catch (e) {
        print('Error deleting small file: $e');
      }
      return;
    }

    _recordedAudioPaths.add(audioPath);
    
    // Process the audio to detect mood for this question
    final result = await _moodService.detectMoodFromAudio(audioPath);
    
    if (result.isSuccess) {
      _moodData[_questions[_currentQuestionIndex].key] = {
        'mood': result.mood,
        'confidence': result.confidence,
        'audio_path': audioPath,
        'duration': _recordingDuration,
      };
    } else {
      // Store even if processing failed, we'll analyze all at the end
      _moodData[_questions[_currentQuestionIndex].key] = {
        'audio_path': audioPath,
        'duration': _recordingDuration,
        'error': result.error,
      };
      print('⚠️  Mood detection failed: ${result.error}');
    }

    setState(() {
      _isProcessing = false;
      _recordingDuration = 0;
    });

    // Auto-advance to next question after a delay
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (mounted) {
      if (_currentQuestionIndex < _questions.length - 1) {
        _nextQuestion();
      } else {
        _completeAssessment();
      }
    }
  }

  void _nextQuestion() {
    setState(() {
      _currentQuestionIndex++;
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  Future<void> _completeAssessment() async {
    setState(() => _isProcessing = true);

    // Analyze all responses together for final mood
    VoiceMoodResult? overallResult;
    if (_recordedAudioPaths.isNotEmpty) {
      overallResult = await _moodService.analyzeMultipleResponses(_recordedAudioPaths);
      
      if (overallResult.isSuccess) {
        _moodData['overall_mood'] = {
          'mood': overallResult.mood,
          'confidence': overallResult.confidence,
          'all_probabilities': overallResult.allProbabilities,
        };
        print('✅ Overall mood: ${overallResult.mood} (${(overallResult.confidence * 100).toStringAsFixed(1)}%)');
      } else {
        print('⚠️  Overall mood detection failed: ${overallResult.error}');
      }
    }

    // Save mood data
    ref.read(moodProvider.notifier).setMoodData(_moodData);
    await StorageService.setString('user_mood_data', _moodData.toString());
    await StorageService.setBool('has_completed_welcome', true);
    await StorageService.setString('mood_detection_method', 'voice');

    setState(() => _isProcessing = false);

    if (mounted) {
      // Navigate to results screen instead of directly to main
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => VoiceMoodResultsScreen(
            questions: _questions,
            moodData: _moodData,
            overallResult: overallResult,
          ),
        ),
      );
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

    final currentQuestion = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

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
                child: Column(
                  children: [
                    Row(
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
                            Icons.mic_rounded,
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
                                'Voice Mood Detection',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
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
                    const SizedBox(height: 16),
                    // Progress Bar
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppTheme.primaryGradient,
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Question Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        
                        // Question Text (English)
                        Text(
                          currentQuestion.question,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Question Text (Urdu)
                        Text(
                          currentQuestion.questionUrdu,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.8),
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 60),
                        
                        // Recording Button
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _isRecording ? _pulseAnimation.value : 1.0,
                              child: GestureDetector(
                                onTap: () {
                                  if (_isRecording) {
                                    _stopRecording();
                                  } else {
                                    _startRecording();
                                  }
                                },
                                child: Container(
                                  width: 120,
                                  height: 120,
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
                                    size: 50,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Status Text with Timer
                        if (_isProcessing)
                          Column(
                            children: [
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Processing your response...\nDetecting mood from voice',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        else if (_isRecording)
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.5),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Recording: ${_formatDuration(_recordingDuration)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        color: Colors.red.shade300,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Speak clearly and naturally',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              if (_recordingDuration < 2)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Keep speaking... (minimum 2 seconds)',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.orange.shade300,
                                    ),
                                  ),
                                ),
                            ],
                          )
                        else
                          Text(
                            'Tap the button to start recording',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        
                        const SizedBox(height: 40),
                        
                        // Instructions
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppTheme.accentColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'You can answer in English or Urdu. Tap to start recording, tap again to stop. Record for at least 2 seconds.',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '${minutes}:${secs.toString().padLeft(2, '0')}';
    }
    return '0:${secs.toString().padLeft(2, '0')}';
  }
}

class VoiceQuestion {
  final String question;
  final String questionUrdu;
  final String key;

  VoiceQuestion({
    required this.question,
    required this.questionUrdu,
    required this.key,
  });
}

/// Results screen showing all answered questions and detected mood
class VoiceMoodResultsScreen extends StatelessWidget {
  final List<VoiceQuestion> questions;
  final Map<String, dynamic> moodData;
  final VoiceMoodResult? overallResult;

  const VoiceMoodResultsScreen({
    super.key,
    required this.questions,
    required this.moodData,
    this.overallResult,
  });

  String _getMoodDisplayName(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return 'Happy';
      case 'sad':
        return 'Sad';
      case 'energetic':
        return 'Energetic';
      case 'relaxed':
        return 'Relaxed';
      case 'romantic':
        return 'Romantic';
      case 'adventurous':
        return 'Adventurous';
      case 'focused':
        return 'Focused';
      case 'nostalgic':
        return 'Nostalgic';
      case 'angry':
        return 'Angry';
      case 'calm':
        return 'Calm';
      case 'neutral':
        return 'Neutral';
      case 'fear':
        return 'Fear';
      case 'surprise':
        return 'Surprise';
      case 'disgust':
        return 'Disgust';
      default:
        return mood.substring(0, 1).toUpperCase() + mood.substring(1);
    }
  }

  IconData _getMoodIcon(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'energetic':
        return Icons.bolt;
      case 'relaxed':
        return Icons.spa;
      case 'romantic':
        return Icons.favorite;
      case 'adventurous':
        return Icons.explore;
      case 'focused':
        return Icons.center_focus_strong;
      case 'nostalgic':
        return Icons.history;
      case 'angry':
        return Icons.mood_bad;
      case 'calm':
        return Icons.self_improvement;
      case 'fear':
        return Icons.warning;
      case 'surprise':
        return Icons.celebration;
      case 'disgust':
        return Icons.sick;
      default:
        return Icons.mood;
    }
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return Colors.yellow;
      case 'sad':
        return Colors.blue;
      case 'energetic':
        return Colors.orange;
      case 'relaxed':
        return Colors.green;
      case 'romantic':
        return Colors.pink;
      case 'adventurous':
        return Colors.purple;
      case 'focused':
        return Colors.indigo;
      case 'nostalgic':
        return Colors.brown;
      case 'angry':
        return Colors.red;
      case 'calm':
        return Colors.teal;
      case 'fear':
        return Colors.deepPurple;
      case 'surprise':
        return Colors.amber;
      case 'disgust':
        return Colors.orange.shade700;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final overallMood = overallResult?.mood ?? 'neutral';
    final overallConfidence = overallResult?.confidence ?? 0.0;

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
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: AppTheme.primaryGradient,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.psychology_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mood Detection Results',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Your voice analysis is complete',
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

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overall Mood Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getMoodColor(overallMood).withOpacity(0.3),
                              _getMoodColor(overallMood).withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getMoodColor(overallMood).withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: _getMoodColor(overallMood).withOpacity(0.2),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _getMoodColor(overallMood).withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _getMoodIcon(overallMood),
                                size: 72,
                                color: _getMoodColor(overallMood),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Overall Mood',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getMoodDisplayName(overallMood),
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Confidence: ${(overallConfidence * 100).toStringAsFixed(1)}%',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Questions and Answers
                      Text(
                        'Your Responses',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      ...questions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final question = entry.value;
                        final answerData = moodData[question.key] as Map<String, dynamic>?;
                        final detectedMood = answerData?['mood'] as String? ?? 'Not detected';
                        final confidence = answerData?['confidence'] as double? ?? 0.0;
                        final hasError = answerData?['error'] != null;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: AppTheme.primaryGradient,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      question.question,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (hasError)
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.error_outline,
                                        color: Colors.orange,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Could not detect mood from this recording',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Colors.orange.shade300,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _getMoodColor(detectedMood).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _getMoodColor(detectedMood).withOpacity(0.5),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: _getMoodColor(detectedMood).withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              _getMoodIcon(detectedMood),
                                              size: 22,
                                              color: _getMoodColor(detectedMood),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _getMoodDisplayName(detectedMood),
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: _getMoodColor(detectedMood),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '${(confidence * 100).toStringAsFixed(0)}% confidence',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Continue Button
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/main');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Continue to App',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
}



