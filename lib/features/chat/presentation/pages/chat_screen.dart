import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/openai_service.dart';
import '../../../../core/models/chat_message.dart';
import '../../../welcome/presentation/widgets/chat_message_bubble.dart';
import '../../../welcome/presentation/widgets/chat_input_field.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final OpenAIService _openAIService = OpenAIService();

  String? _detectedMood;
  bool _isLoading = false;
  bool _waitingForMood = false;
  bool _waitingForContentType = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeChat() {
    // Start with greeting and mood question
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addBotMessage(
        'Hi! How\'s your mood today?',
        options: ['😊 Happy', '😢 Sad', '😡 Angry', '😨 Fear', '😮 Surprise', '😐 Neutral'],
      );
      setState(() {
        _waitingForMood = true;
      });
    });
  }

  void _addBotMessage(String text, {List<String>? options}) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isBot: true,
        timestamp: DateTime.now(),
        options: options,
      ));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isBot: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
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

  Future<void> _handleUserInput(String input) async {
    if (_isLoading) return;

    _addUserMessage(input);
    setState(() {
      _isLoading = true;
    });

    try {
      if (_waitingForMood) {
        // Detect mood from user input
        await _handleMoodInput(input);
      } else if (_waitingForContentType) {
        // Handle content type selection
        await _handleContentTypeInput(input);
      } else {
        // General chat
        await _handleGeneralChat(input);
      }
    } catch (e) {
      _addBotMessage('Sorry, I encountered an error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleMoodInput(String input) async {
    // Extract mood from input
    final moodMap = {
      'happy': ['happy', 'joy', 'joyful', 'cheerful', 'excited', 'great', 'good', '😊'],
      'sad': ['sad', 'depressed', 'down', 'unhappy', 'melancholy', '😢'],
      'angry': ['angry', 'mad', 'furious', 'annoyed', 'irritated', '😡'],
      'fear': ['fear', 'afraid', 'scared', 'anxious', 'worried', 'nervous', '😨'],
      'surprise': ['surprise', 'surprised', 'shocked', 'amazed', 'wow', '😮'],
      'neutral': ['neutral', 'okay', 'fine', 'normal', 'alright', '😐'],
    };

    String detectedMood = 'neutral';
    final lowerInput = input.toLowerCase();

    for (final entry in moodMap.entries) {
      if (entry.value.any((keyword) => lowerInput.contains(keyword))) {
        detectedMood = entry.key;
        break;
      }
    }

    setState(() {
      _detectedMood = detectedMood;
      _waitingForMood = false;
      _waitingForContentType = true;
    });

    _addBotMessage(
      'Great! I detected you\'re feeling ${detectedMood}. What type of content would you like?\n\nChoose one:',
      options: ['🎬 Movies', '🎵 Songs', '📺 Videos'],
    );
  }

  Future<void> _handleContentTypeInput(String input) async {
    // Extract content type
    String contentType = 'videos';
    final lowerInput = input.toLowerCase();

    if (lowerInput.contains('movie') || lowerInput.contains('film')) {
      contentType = 'movies';
    } else if (lowerInput.contains('song') || lowerInput.contains('music') || lowerInput.contains('track')) {
      contentType = 'songs';
    } else if (lowerInput.contains('video') || lowerInput.contains('youtube')) {
      contentType = 'videos';
    }

    setState(() {
      _waitingForContentType = false;
    });

    // Get recommendations
    _addBotMessage('Perfect! Let me find some ${contentType} recommendations for your ${_detectedMood} mood...');

    try {
      final recommendations = await _openAIService.getContentRecommendations(
        mood: _detectedMood ?? 'neutral',
        contentType: contentType,
      );

      if (recommendations.isEmpty) {
        _addBotMessage(
          'I couldn\'t find any ${contentType} for your mood. Would you like to try a different content type?',
          options: ['🎬 Movies', '🎵 Songs', '📺 Videos'],
        );
        setState(() {
          _waitingForContentType = true;
        });
      } else {
        final response = _openAIService.formatContentResponse(
          mood: _detectedMood ?? 'neutral',
          contentType: contentType,
          content: recommendations,
        );
        _addBotMessage(response);
        
        // Ask if they want more
        _addBotMessage(
          'Would you like to search for something else?',
          options: ['🔄 New Search', '👋 End Chat'],
        );
      }
    } catch (e) {
      _addBotMessage('Sorry, I couldn\'t fetch recommendations. Please try again.');
    }
  }

  Future<void> _handleGeneralChat(String input) async {
    // Use OpenAI for general conversation
    try {
      final messages = [
        {'role': 'system', 'content': 'You are a helpful assistant for Content Nation, an app that recommends movies, songs, and videos based on user mood. Be friendly and concise.'},
        {'role': 'user', 'content': input},
      ];

      final response = await _openAIService.getChatCompletion(messages: messages);
      _addBotMessage(response);
    } catch (e) {
      _addBotMessage('Sorry, I\'m having trouble responding. Please try again.');
    }
  }

  void _handleOptionSelected(String option) {
    if (option.contains('🔄') || option.contains('New Search')) {
      // Reset and start over
    setState(() {
      _detectedMood = null;
      _waitingForMood = true;
      _waitingForContentType = false;
    });
      _addBotMessage(
        'Great! Let\'s start over. How\'s your mood today?',
        options: ['😊 Happy', '😢 Sad', '😡 Angry', '😨 Fear', '😮 Surprise', '😐 Neutral'],
      );
    } else if (option.contains('👋') || option.contains('End Chat')) {
      _addBotMessage('Thanks for using Content Nation! Have a great day! 🎉');
    } else {
      // Handle mood or content type selection
      _handleUserInput(option);
    }
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
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: AppTheme.primaryGradient),
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
                            'Chat Assistant',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'AI-Powered Recommendations',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Messages
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Text(
                          'Starting conversation...',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            // Loading indicator
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: AppTheme.primaryGradient),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.psychology_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final message = _messages[index];
                          return ChatMessageBubble(
                            message: message,
                            options: message.options,
                            onOptionSelected: _handleOptionSelected,
                          );
                        },
                      ),
              ),

              // Input field
              Container(
                padding: const EdgeInsets.all(16),
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
                  onSubmitted: _handleUserInput,
                  enabled: !_isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

