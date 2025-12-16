import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/content_model.dart';
import '../../../../core/widgets/safe_network_image.dart';

class ContentCard extends StatelessWidget {
  final ContentItem content;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onShare;

  const ContentCard({
    super.key,
    required this.content,
    this.onTap,
    this.onLike,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thumbnail - Use fixed height instead of Expanded for ListView compatibility
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppConstants.borderRadius),
                    ),
                    child: SafeNetworkImage(
                      imageUrl: content.thumbnailUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppConstants.borderRadius),
                      ),
                      platform: content.platform,
                    ),
                  ),
                  
                  // Platform indicator
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getPlatformColor().withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getPlatformIcon(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  // Duration indicator (for videos)
                  if (content.duration != null)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          content.duration!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  
                  // Action buttons
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Row(
                      children: [
                        if (onLike != null)
                          _buildActionButton(
                            icon: Icons.favorite_border,
                            onPressed: onLike!,
                          ),
                        if (onShare != null) ...[
                          const SizedBox(width: 4),
                          _buildActionButton(
                            icon: Icons.share,
                            onPressed: onShare!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content info - Use fixed padding instead of Expanded
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      content.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Subtitle (channel/artist name)
                    Text(
                      content.channelName ?? content.artistName ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Stats row
                    Row(
                      children: [
                        // Rating
                        if (content.rating != null) ...[
                          Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.amber[600],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            content.rating!.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        
                        // View count
                        if (content.viewCount != null) ...[
                          Icon(
                            Icons.visibility,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _formatViewCount(content.viewCount!),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                        ],
                        
                        const Spacer(),
                        
                        // Category icon
                        Icon(
                          _getCategoryIcon(),
                          size: 12,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 14,
          color: Colors.white,
        ),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Color _getPlatformColor() {
    switch (content.platform) {
      case ContentType.youtube:
        return Colors.red;
      case ContentType.spotify:
        return Colors.green;
      case ContentType.tmdb:
        return Colors.blue;
    }
  }

  String _getPlatformIcon() {
    switch (content.platform) {
      case ContentType.youtube:
        return 'YT';
      case ContentType.spotify:
        return 'SP';
      case ContentType.tmdb:
        return 'TM';
    }
  }

  IconData _getCategoryIcon() {
    switch (content.category) {
      case ContentCategory.video:
        return Icons.play_circle_outline;
      case ContentCategory.music:
        return Icons.music_note;
      case ContentCategory.movie:
        return Icons.movie;
      case ContentCategory.tvShow:
        return Icons.tv;
      case ContentCategory.playlist:
        return Icons.playlist_play;
    }
  }

  String _formatViewCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
}
