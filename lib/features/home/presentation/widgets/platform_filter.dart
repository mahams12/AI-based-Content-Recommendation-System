import 'package:flutter/material.dart';
import '../../../../core/models/content_model.dart';

class PlatformFilter extends StatelessWidget {
  final List<ContentType> selectedPlatforms;
  final Function(List<ContentType>) onPlatformsChanged;

  const PlatformFilter({
    super.key,
    required this.selectedPlatforms,
    required this.onPlatformsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Platforms',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: ContentType.values.map((platform) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildPlatformChip(platform, context),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPlatformChip(ContentType platform, BuildContext context) {
    final isSelected = selectedPlatforms.contains(platform);
    
    return GestureDetector(
      onTap: () {
        if (isSelected) {
          if (selectedPlatforms.length > 1) {
            // Don't allow deselecting if it's the only selected platform
            onPlatformsChanged(selectedPlatforms.where((p) => p != platform).toList());
          }
        } else {
          onPlatformsChanged([...selectedPlatforms, platform]);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? _getPlatformColor(platform) 
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? _getPlatformColor(platform) 
                : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: _getPlatformColor(platform).withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getPlatformIcon(platform),
              size: 14,
              color: isSelected 
                  ? Colors.white 
                  : _getPlatformColor(platform),
            ),
            const SizedBox(width: 4),
            Text(
              _getPlatformName(platform),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected 
                    ? Colors.white 
                    : _getPlatformColor(platform),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPlatformColor(ContentType platform) {
    switch (platform) {
      case ContentType.youtube:
        return Colors.red;
      case ContentType.spotify:
        return Colors.green;
      case ContentType.tmdb:
        return Colors.blue;
    }
  }

  IconData _getPlatformIcon(ContentType platform) {
    switch (platform) {
      case ContentType.youtube:
        return Icons.play_circle_filled;
      case ContentType.spotify:
        return Icons.music_note;
      case ContentType.tmdb:
        return Icons.movie;
    }
  }

  String _getPlatformName(ContentType platform) {
    switch (platform) {
      case ContentType.youtube:
        return 'YouTube';
      case ContentType.spotify:
        return 'Spotify';
      case ContentType.tmdb:
        return 'Movies/TV';
    }
  }
}
