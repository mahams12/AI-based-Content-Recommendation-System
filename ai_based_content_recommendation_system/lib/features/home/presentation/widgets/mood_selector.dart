import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/ai_service.dart';

class MoodSelector extends StatefulWidget {
  final String selectedMood;
  final Function(String) onMoodChanged;
  final bool showAIDetection;

  const MoodSelector({
    super.key,
    required this.selectedMood,
    required this.onMoodChanged,
    this.showAIDetection = true,
  });

  @override
  State<MoodSelector> createState() => _MoodSelectorState();
}

class _MoodSelectorState extends State<MoodSelector> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final AIService _aiService = AIService();
  bool _isDetectingMood = false;
  String? _detectedMood;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _detectMoodFromText() async {
    setState(() {
      _isDetectingMood = true;
    });

    try {
      // Show text input dialog for mood detection
      final text = await _showMoodInputDialog();
      if (text != null && text.isNotEmpty) {
        final result = await _aiService.analyzeSentiment(text);
        setState(() {
          _detectedMood = result.mood;
        });
        
        if (_detectedMood != null && _detectedMood != 'neutral') {
          widget.onMoodChanged(_detectedMood!);
          _showMoodDetectionResult(result);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to detect mood: $e');
    } finally {
      setState(() {
        _isDetectingMood = false;
      });
    }
  }

  Future<String?> _showMoodInputDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) {
        String inputText = '';
        return AlertDialog(
          backgroundColor: const Color(0xFF1C2128),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'How are you feeling?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          content: TextField(
            onChanged: (value) => inputText = value,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Tell me about your mood...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              filled: true,
              fillColor: const Color(0xFF0D1117),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, inputText),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Detect Mood', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showMoodDetectionResult(SentimentResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getMoodIcon(result.mood),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text('Detected mood: ${_getMoodDisplayName(result.mood)}'),
          ],
        ),
        backgroundColor: const Color(0xFF667eea),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'How are you feeling?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (widget.showAIDetection)
                  GestureDetector(
                    onTap: _isDetectingMood ? null : _detectMoodFromText,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667eea).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isDetectingMood)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else
                            const Icon(
                              Icons.psychology_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          const SizedBox(width: 6),
                          Text(
                            _isDetectingMood ? 'Detecting...' : 'AI Detect',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: AppConstants.moodTypes.length + 1, // +1 for "All"
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildMoodChip('all', 'All', Icons.all_inclusive, context);
                  }
                  final mood = AppConstants.moodTypes[index - 1];
                  return _buildMoodChip(mood, _getMoodDisplayName(mood), _getMoodIcon(mood), context);
                },
              ),
            ),
            if (_detectedMood != null && _detectedMood != widget.selectedMood) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF667eea).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: const Color(0xFF667eea),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI detected: ${_getMoodDisplayName(_detectedMood!)}',
                      style: const TextStyle(
                        color: Color(0xFF667eea),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => widget.onMoodChanged(_detectedMood!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667eea),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Apply',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMoodChip(String mood, String displayName, IconData icon, BuildContext context) {
    final isSelected = widget.selectedMood == mood;
    
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => widget.onMoodChanged(mood),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected 
                ? const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  )
                : null,
            color: isSelected ? null : const Color(0xFF1C2128),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected 
                  ? Colors.transparent
                  : Colors.grey.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: const Color(0xFF667eea).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected 
                    ? Colors.white 
                    : Colors.grey[400],
              ),
              const SizedBox(width: 8),
              Text(
                displayName,
                style: TextStyle(
                  color: isSelected 
                      ? Colors.white 
                      : Colors.grey[400],
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMoodDisplayName(String mood) {
    switch (mood) {
      case 'energetic':
        return 'Energetic';
      case 'relaxed':
        return 'Relaxed';
      case 'sad':
        return 'Sad';
      case 'happy':
        return 'Happy';
      case 'focused':
        return 'Focused';
      case 'romantic':
        return 'Romantic';
      case 'adventurous':
        return 'Adventurous';
      case 'nostalgic':
        return 'Nostalgic';
      default:
        return mood;
    }
  }

  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case 'energetic':
        return Icons.bolt;
      case 'relaxed':
        return Icons.spa;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'focused':
        return Icons.center_focus_strong;
      case 'romantic':
        return Icons.favorite;
      case 'adventurous':
        return Icons.explore;
      case 'nostalgic':
        return Icons.history;
      default:
        return Icons.mood;
    }
  }
}




