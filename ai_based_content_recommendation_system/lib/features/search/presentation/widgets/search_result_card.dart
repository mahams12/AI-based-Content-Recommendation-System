import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/content_model.dart';

class SearchResultCard extends StatelessWidget {
  final ContentItem content;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onShare;

  const SearchResultCard({
    super.key,
    required this.content,
    this.onTap,
    this.onLike,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: content.thumbnailUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.error_outline,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Content info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      content.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Subtitle
                    Text(
                      content.channelName ?? content.artistName ?? content.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Platform and stats
                    Row(
                      children: [
                        // Platform indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPlatformColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _getPlatformColor().withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            _getPlatformName(),
                            style: TextStyle(
                              color: _getPlatformColor(),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Category
                        Icon(
                          _getCategoryIcon(),
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        
                        const SizedBox(width: 4),
                        
                        Text(
                          _getCategoryName(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Duration or rating
                        if (content.duration != null)
                          Text(
                            content.duration!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          )
                        else if (content.rating != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action buttons
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.favorite_border, size: 20),
                    onPressed: onLike,
                    color: Colors.grey[600],
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, size: 20),
                    onPressed: onShare,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ],
          ),
        ),
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

  String _getPlatformName() {
    switch (content.platform) {
      case ContentType.youtube:
        return 'YouTube';
      case ContentType.spotify:
        return 'Spotify';
      case ContentType.tmdb:
        return 'TMDB';
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

  String _getCategoryName() {
    switch (content.category) {
      case ContentCategory.video:
        return 'Video';
      case ContentCategory.music:
        return 'Music';
      case ContentCategory.movie:
        return 'Movie';
      case ContentCategory.tvShow:
        return 'TV Show';
      case ContentCategory.playlist:
        return 'Playlist';
    }
  }
}
