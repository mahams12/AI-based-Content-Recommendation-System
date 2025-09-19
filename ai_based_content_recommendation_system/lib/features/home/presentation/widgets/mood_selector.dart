import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

class MoodSelector extends StatelessWidget {
  final String selectedMood;
  final Function(String) onMoodChanged;

  const MoodSelector({
    super.key,
    required this.selectedMood,
    required this.onMoodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How are you feeling?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
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
      ],
    );
  }

  Widget _buildMoodChip(String mood, String displayName, IconData icon, BuildContext context) {
    final isSelected = selectedMood == mood;
    
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => onMoodChanged(mood),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppTheme.primaryColor 
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected 
                  ? AppTheme.primaryColor 
                  : Colors.grey.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected 
                    ? Colors.white 
                    : Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 6),
              Text(
                displayName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isSelected 
                      ? Colors.white 
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

