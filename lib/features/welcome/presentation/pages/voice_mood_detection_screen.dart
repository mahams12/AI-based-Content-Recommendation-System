import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/voice_recording_service.dart';
import '../../../../core/services/voice_mood_service.dart';
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
  List<String> _recordedAudioPaths = [];
  Map<String, dynamic> _moodData = {};

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
    final moodInitialized = await _moodService.initialize();
    
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

    if (!moodInitialized && mounted) {
      _showError('Failed to initialize voice mood detection model');
    }
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;

    final started = await _recordingService.startRecording();
    if (started) {
      setState(() => _isRecording = true);
    } else {
      _showError('Failed to start recording. Please check microphone permissions.');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    setState(() {
      _isRecording = false;
      _isProcessing = true;
    });

    final audioPath = await _recordingService.stopRecording();
    
    if (audioPath != null && File(audioPath).existsSync()) {
      _recordedAudioPaths.add(audioPath);
      
      // Process the audio to detect mood for this question
      final result = await _moodService.detectMoodFromAudio(audioPath);
      
      if (result.isSuccess) {
        _moodData[_questions[_currentQuestionIndex].key] = {
          'mood': result.mood,
          'confidence': result.confidence,
          'audio_path': audioPath,
        };
      } else {
        // Store even if processing failed, we'll analyze all at the end
        _moodData[_questions[_currentQuestionIndex].key] = {
          'audio_path': audioPath,
          'error': result.error,
        };
      }
    }

    setState(() => _isProcessing = false);

    // Auto-advance to next question after a delay
    await Future.delayed(const Duration(milliseconds: 1000));
    
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
    if (_recordedAudioPaths.isNotEmpty) {
      final overallResult = await _moodService.analyzeMultipleResponses(_recordedAudioPaths);
      
      if (overallResult.isSuccess) {
        _moodData['overall_mood'] = {
          'mood': overallResult.mood,
          'confidence': overallResult.confidence,
          'all_probabilities': overallResult.allProbabilities,
        };
      }
    }

    // Save mood data
    ref.read(moodProvider.notifier).setMoodData(_moodData);
    await StorageService.setString('user_mood_data', _moodData.toString());
    await StorageService.setBool('has_completed_welcome', true);
    await StorageService.setString('mood_detection_method', 'voice');

    setState(() => _isProcessing = false);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/main');
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
                                onTapDown: (_) => _startRecording(),
                                onTapUp: (_) => _stopRecording(),
                                onTapCancel: () => _stopRecording(),
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
                            'Recording... Speak now',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.red.shade300,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else
                          Text(
                            'Hold to record your answer',
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
                                  'You can answer in English or Urdu. Hold the button while speaking.',
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


