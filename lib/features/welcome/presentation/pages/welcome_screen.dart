import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/storage_service.dart';
import '../providers/mood_provider.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/typing_indicator.dart';
import 'voice_mood_detection_screen.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _typeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _typeAnimation;

  bool _isTyping = true;
  bool _showChoiceScreen = false;
  bool _showChatInterface = false;
  String _displayText = '';
  final String _welcomeMessage = 'Welcome to ContentNation!';

  // Chat-related variables
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  bool _isTypingMessage = false;
  bool _isWaitingForInput = false;
  int _currentQuestionIndex = 0;
  final Map<String, dynamic> _moodData = {};

  final List<String> _conversationMessages = [
    "Hi! 👋 Welcome to ContentNation!",
    "I'm here to help you discover amazing content tailored to your mood.",
    "Let's start by getting to know you better. How are you feeling right now?",
  ];

  final List<ChatQuestion> _questions = [
    ChatQuestion(
      question: "Great! Now, what type of content are you in the mood for today?",
      options: [
        "🎵 Music & Audio",
        "🎬 Movies & Shows",
        "📺 Educational Videos",
        "🎮 Entertainment & Gaming",
      ],
      answerKey: "content_preference",
    ),
    ChatQuestion(
      question: "Excellent choice! What's your current energy level? This helps me suggest content that matches your vibe.",
      options: [
        "⚡ High Energy",
        "😊 Moderate Energy",
        "😴 Low Energy",
        "🎯 Focused Energy",
      ],
      answerKey: "energy_level",
    ),
    ChatQuestion(
      question: "Perfect! How much time do you have for content right now?",
      options: [
        "⏱️ Quick Break (5-15 min)",
        "☕ Coffee Break (15-30 min)",
        "📺 Relax Time (30+ min)",
        "🎯 Deep Dive Session",
      ],
      answerKey: "time_availability",
    ),
  ];

  int _conversationIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkIfFirstTime();
    _startWelcomeSequence();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _typeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _typeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  void _checkIfFirstTime() async {
    final hasCompletedWelcome = StorageService.getBool('has_completed_welcome');
    if (hasCompletedWelcome == true) {
      _navigateToHome();
    }
  }

  void _startWelcomeSequence() async {
    await Future.delayed(const Duration(milliseconds: 800));
    _typeController.forward();
    
    // Simulate typing effect
    for (int i = 0; i <= _welcomeMessage.length; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() {
          _displayText = _welcomeMessage.substring(0, i);
        });
      }
    }
    
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      setState(() {
        _isTyping = false;
      });
    }
  }

  void _showChoiceScreenOption() {
    setState(() {
      _showChoiceScreen = true;
    });
  }

  void _startChatInterface() {
    setState(() {
      _showChoiceScreen = false;
      _showChatInterface = true;
    });
    _startConversation();
  }

  void _startConversation() {
    _addBotMessage(_conversationMessages[_conversationIndex]);
  }

  void _startVoiceInterface() {
    // Navigate to voice mood detection screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const VoiceMoodDetectionScreen(),
      ),
    );
  }

  void _addBotMessage(String text) {
    setState(() {
      _isTypingMessage = true;
    });

    // Simulate typing delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: text,
            isBot: true,
            timestamp: DateTime.now(),
          ));
          _isTypingMessage = false;
          _isWaitingForInput = true;
        });
        _scrollToBottom();
      }
    });
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isBot: false,
        timestamp: DateTime.now(),
      ));
      _isWaitingForInput = false;
      _textController.clear();
    });
    _scrollToBottom();
    
    // Process user response
    _processUserResponse(text);
  }

  void _processUserResponse(String response) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // If we're in the initial conversation phase
    if (_conversationIndex < _conversationMessages.length - 1) {
      _conversationIndex++;
      _addBotMessage(_conversationMessages[_conversationIndex]);
    } 
    // If we're at the mood question, store the feeling and move to content questions
    else if (_conversationIndex == _conversationMessages.length - 1) {
      _moodData["feeling"] = response;
      _addBotMessage(_questions[_currentQuestionIndex].question);
      _currentQuestionIndex++;
    }
    // If we're in the content questions phase
    else if (_currentQuestionIndex < _questions.length) {
      final currentQuestion = _questions[_currentQuestionIndex - 1];
      _moodData[currentQuestion.answerKey] = response;
      
      if (_currentQuestionIndex < _questions.length) {
        _addBotMessage(_questions[_currentQuestionIndex].question);
        _currentQuestionIndex++;
      } else {
        _completeAssessment();
      }
    }
    // If all questions are done, complete
    else {
      _completeAssessment();
    }
  }

  void _completeAssessment() {
    // Assessment completed
    _addBotMessage("Perfect! 🎯 I've got everything I need to personalize your content experience. Let me set this up for you...");
    
    Future.delayed(const Duration(milliseconds: 2000), () {
      _completeWelcome();
    });
  }

  void _completeWelcome() async {
    // Save mood data
    await StorageService.setString('user_mood_data', _moodData.toString());
    ref.read(moodProvider.notifier).setMoodData(_moodData);
    await StorageService.setBool('has_completed_welcome', true);
    
    _addBotMessage("All set! 🚀 You're now ready to discover amazing content tailored just for you. Let's get started!");
    
    await Future.delayed(const Duration(milliseconds: 2000));
    _navigateToHome();
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/main');
  }

  void _skipAssessment() {
    if (_showChatInterface) {
      _addUserMessage("Skip for now");
      _completeWelcome();
    } else {
      _navigateToHome();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _typeController.dispose();
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: _showChatInterface 
            ? _buildChatInterface() 
            : _showChoiceScreen 
                ? _buildChoiceScreen() 
                : _buildWelcomeScreen(),
        ),
      ),
    );
  }

  Widget _buildChoiceScreen() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Choice Header
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: AppTheme.primaryGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.psychology_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      Text(
                        'Choose Your Experience',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Text(
                        'How would you like your mood to be analyzed?',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Start Chat Button
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: _startChatInterface,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: AppTheme.primaryGradient,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.3),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: const Icon(
                                      Icons.chat_bubble_rounded,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Chat Interface',
                                          style: GoogleFonts.inter(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Type or select responses to questions',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Voice Option
                      SizedBox(
                        width: double.infinity,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: _startVoiceInterface,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Icon(
                                      Icons.mic_rounded,
                                      color: AppTheme.accentColor,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Voice Interface',
                                          style: GoogleFonts.inter(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Speak your responses naturally',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: Colors.white.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white.withOpacity(0.5),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Back Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            setState(() {
                              _showChoiceScreen = false;
                            });
                          },
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Back',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Logo/Icon
                      AnimatedBuilder(
                        animation: _fadeAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _fadeAnimation.value,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: AppTheme.primaryGradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.psychology_rounded,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Welcome Message with Typing Effect
                      AnimatedBuilder(
                        animation: _typeAnimation,
                        builder: (context, child) {
                          return Text(
                            _displayText,
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          );
                        },
                      ),
                      
                      if (_isTyping)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          width: 20,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: AnimatedBuilder(
                            animation: _typeAnimation,
                            builder: (context, child) {
                              return LinearProgressIndicator(
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryColor.withOpacity(0.3),
                                ),
                                value: _typeAnimation.value,
                              );
                            },
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // Subtitle
                      if (!_isTyping)
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            'Your AI-powered content discovery companion',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      
                      const SizedBox(height: 60),
                      
                      // Action Buttons
                      if (!_isTyping)
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              // Get Started Button
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: AppTheme.primaryGradient,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(0.3),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: _showChoiceScreenOption,
                                    child: Center(
                                      child: Text(
                                        'Get Started',
                                        style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Skip Button
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: _skipAssessment,
                                    child: Center(
                                      child: Text(
                                        'Skip for Now',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ),
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
            
            // Bottom hint text
            if (!_isTyping)
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'We\'ll help you discover content that matches your mood',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInterface() {
    return Column(
      children: [
        // Chat Header
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppTheme.primaryGradient,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ContentNation AI',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Your content discovery companion',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _skipAssessment,
                child: Text(
                  'Skip',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Chat Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            itemCount: _messages.length + (_isTypingMessage ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length && _isTypingMessage) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: TypingIndicator(),
                );
              }
              
              final message = _messages[index];
                      return ChatMessageBubble(
                        message: message,
                        onOptionSelected: _isWaitingForInput && message.isBot ? _addUserMessage : null,
                        options: message.isBot && _isWaitingForInput && _conversationIndex >= _conversationMessages.length - 1 && _currentQuestionIndex > 0
                            ? _questions[_currentQuestionIndex - 1].options 
                            : null,
                      );
            },
          ),
        ),
        
        // Chat Input (for manual input if needed)
        if (_isWaitingForInput)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: ChatInputField(
              controller: _textController,
              focusNode: _focusNode,
              onSubmitted: _addUserMessage,
              enabled: true,
            ),
          ),
      ],
    );
  }
}

class ChatMessage {
  final String text;
  final bool isBot;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isBot,
    required this.timestamp,
  });
}

class ChatQuestion {
  final String question;
  final List<String> options;
  final String answerKey;

  ChatQuestion({
    required this.question,
    required this.options,
    required this.answerKey,
  });
}