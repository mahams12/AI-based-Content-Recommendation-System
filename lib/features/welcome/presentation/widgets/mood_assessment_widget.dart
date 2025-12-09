import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

class MoodAssessmentDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onCompleted;
  final VoidCallback onSkip;

  const MoodAssessmentDialog({
    super.key,
    required this.onCompleted,
    required this.onSkip,
  });

  @override
  State<MoodAssessmentDialog> createState() => _MoodAssessmentDialogState();
}

class _MoodAssessmentDialogState extends State<MoodAssessmentDialog>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentQuestionIndex = 0;
  String? _selectedAnswer;
  final Map<String, dynamic> _moodData = {};

  final List<MoodQuestion> _questions = [
    MoodQuestion(
      question: "How are you feeling right now?",
      answers: [
        MoodAnswer("😊 Happy & Energetic", "happy_energetic", "Happy & Energetic"),
        MoodAnswer("😌 Calm & Relaxed", "calm_relaxed", "Calm & Relaxed"),
        MoodAnswer("🤔 Thoughtful & Focused", "thoughtful_focused", "Thoughtful & Focused"),
        MoodAnswer("💭 Nostalgic & Reflective", "nostalgic_reflective", "Nostalgic & Reflective"),
      ],
    ),
    MoodQuestion(
      question: "What type of content are you in the mood for?",
      answers: [
        MoodAnswer("🎵 Music & Audio", "music_audio", "Music & Audio"),
        MoodAnswer("🎬 Movies & Shows", "movies_shows", "Movies & Shows"),
        MoodAnswer("📺 Educational Videos", "educational_videos", "Educational Videos"),
        MoodAnswer("🎮 Entertainment & Gaming", "entertainment_gaming", "Entertainment & Gaming"),
      ],
    ),
    MoodQuestion(
      question: "What's your current energy level?",
      answers: [
        MoodAnswer("⚡ High Energy", "high_energy", "High Energy"),
        MoodAnswer("😊 Moderate Energy", "moderate_energy", "Moderate Energy"),
        MoodAnswer("😴 Low Energy", "low_energy", "Low Energy"),
        MoodAnswer("🎯 Focused Energy", "focused_energy", "Focused Energy"),
      ],
    ),
    MoodQuestion(
      question: "How much time do you have?",
      answers: [
        MoodAnswer("⏱️ Quick Break (5-15 min)", "quick_break", "Quick Break"),
        MoodAnswer("☕ Coffee Break (15-30 min)", "coffee_break", "Coffee Break"),
        MoodAnswer("📺 Relax Time (30+ min)", "relax_time", "Relax Time"),
        MoodAnswer("🎯 Deep Dive Session", "deep_dive", "Deep Dive Session"),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  void _selectAnswer(String answerKey, String answerLabel) {
    setState(() {
      _selectedAnswer = answerKey;
    });

    // Store the answer
    _moodData[_questions[_currentQuestionIndex].question] = {
      'key': answerKey,
      'label': answerLabel,
    };

    // Auto-advance to next question after a short delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (_currentQuestionIndex < _questions.length - 1) {
        _nextQuestion();
      } else {
        _completeAssessment();
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      _currentQuestionIndex++;
      _selectedAnswer = null;
    });
    
    // Restart animations for new question
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
  }

  void _completeAssessment() {
    widget.onCompleted(_moodData);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppTheme.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
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
                              'Mood Assessment',
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
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: widget.onSkip,
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Question Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question
                      Text(
                        currentQuestion.question,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Answer Options
                      ...currentQuestion.answers.map((answer) {
                        final isSelected = _selectedAnswer == answer.key;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _selectAnswer(answer.key, answer.label),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? AppTheme.primaryColor.withOpacity(0.2)
                                      : Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected 
                                        ? AppTheme.primaryColor
                                        : Colors.white.withOpacity(0.1),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      answer.label.split(' ')[0], // Get emoji from label
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        answer.label,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      
                      const SizedBox(height: 24),
                      
                      // Voice Option (Coming Soon)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.mic_rounded,
                                color: AppTheme.accentColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Voice Response',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Coming Soon',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Soon',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.accentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Skip Button
                      Center(
                        child: TextButton(
                          onPressed: widget.onSkip,
                          child: Text(
                            'Skip Assessment',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                              decoration: TextDecoration.underline,
                            ),
                          ),
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
    );
  }
}

class MoodQuestion {
  final String question;
  final List<MoodAnswer> answers;

  MoodQuestion({
    required this.question,
    required this.answers,
  });
}

class MoodAnswer {
  final String label;
  final String key;
  final String displayName;

  MoodAnswer(this.label, this.key, this.displayName);
}
