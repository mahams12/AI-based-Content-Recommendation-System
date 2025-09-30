import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/content_model.dart';
import 'favorite_button.dart';

class MediaPlayer extends StatefulWidget {
  final ContentItem content;

  const MediaPlayer({
    super.key,
    required this.content,
  });

  @override
  State<MediaPlayer> createState() => _MediaPlayerState();
}

class _MediaPlayerState extends State<MediaPlayer> {
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1C2128),
              Color(0xFF2D1B69),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: _getGradientColors()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getPlatformIcon(),
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
                        widget.content.platform.name.toUpperCase(),
                        style: TextStyle(
                          color: _getGradientColors()[0],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.content.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Favorite Button
                FavoriteButton(
                  content: widget.content,
                  size: 20,
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white70,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Media Preview
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: _getGradientColors()),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Thumbnail or placeholder
                  if (widget.content.thumbnailUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        widget.content.thumbnailUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder();
                        },
                      ),
                    )
                  else
                    _buildPlaceholder(),

                  // Play overlay
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: IconButton(
                        onPressed: _handlePlay,
                        icon: Icon(
                          _isLoading
                              ? Icons.hourglass_empty_rounded
                              : _isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Content Info
            if (widget.content.channelName != null || widget.content.artistName != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_rounded,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'By ${widget.content.channelName ?? widget.content.artistName}',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Description
            if (widget.content.description.isNotEmpty) ...[
              Text(
                'Description',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.content.description,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[600]!),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handlePlay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getGradientColors()[0],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getPlatformIcon(),
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getPlayButtonText(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: _getGradientColors()),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(
          _getPlatformIcon(),
          size: 64,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }

  List<Color> _getGradientColors() {
    switch (widget.content.platform) {
      case ContentType.youtube:
        return [const Color(0xFFFF4444), const Color(0xFFFF6B6B)];
      case ContentType.tmdb:
        return [const Color(0xFF667eea), const Color(0xFF764ba2)];
      case ContentType.spotify:
        return [const Color(0xFF1DB954), const Color(0xFF1ED760)];
    }
  }

  IconData _getPlatformIcon() {
    switch (widget.content.platform) {
      case ContentType.youtube:
        return Icons.play_arrow_rounded;
      case ContentType.tmdb:
        return Icons.movie_rounded;
      case ContentType.spotify:
        return Icons.music_note_rounded;
    }
  }

  String _getPlayButtonText() {
    switch (widget.content.platform) {
      case ContentType.youtube:
        return 'Watch on YouTube';
      case ContentType.tmdb:
        return 'View Details';
      case ContentType.spotify:
        if (widget.content.audioUrl != null && widget.content.audioUrl!.isNotEmpty) {
          return _isPlaying ? 'Pause Preview' : 'Play Preview';
        }
        return 'Open in Spotify';
    }
  }

  Future<void> _handlePlay() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Handle Spotify tracks with audio preview
      if (widget.content.platform == ContentType.spotify && 
          widget.content.audioUrl != null && 
          widget.content.audioUrl!.isNotEmpty) {
        // Play the audio preview directly
        setState(() {
          _isPlaying = !_isPlaying;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isPlaying 
                ? 'Playing preview: ${widget.content.title}'
                : 'Preview paused'),
            backgroundColor: const Color(0xFF1DB954),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }

      // For other platforms or Spotify without preview, open external URL
      String url;
      
      switch (widget.content.platform) {
        case ContentType.youtube:
          url = widget.content.externalUrl ?? 
                'https://www.youtube.com/watch?v=${widget.content.id}';
          break;
        case ContentType.spotify:
          // If no preview available, show message
          if (widget.content.audioUrl == null || widget.content.audioUrl!.isEmpty) {
            _showError('No preview available for this track. Please visit Spotify to listen.');
            return;
          }
          url = widget.content.externalUrl ?? 
                'https://open.spotify.com/track/${widget.content.id}';
          break;
        case ContentType.tmdb:
          // For TMDB, we'll show details or open in browser
          url = widget.content.externalUrl ?? 
                'https://www.themoviedb.org/movie/${widget.content.id}';
          break;
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        setState(() {
          _isPlaying = true;
        });
      } else {
        _showError('Could not open ${widget.content.platform.name}');
      }
    } catch (e) {
      _showError('Error opening content: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
