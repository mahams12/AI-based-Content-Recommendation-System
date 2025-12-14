import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/content_model.dart';
import '../services/history_service.dart';
import 'favorite_button.dart';
import 'safe_network_image.dart';

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
  final bool _isPlaying = false;
  bool _isLoading = false;
  final HistoryService _historyService = HistoryService();
  bool _historyAdded = false;

  @override
  void initState() {
    super.initState();
    _initializeHistory();
  }

  Future<void> _initializeHistory() async {
    await _historyService.init();
    // Add to history when MediaPlayer opens
    if (!_historyAdded) {
      await _historyService.addToHistory(widget.content);
      _historyAdded = true;
    }
  }

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
                    SafeNetworkImage(
                      imageUrl: widget.content.thumbnailUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(16),
                      platform: widget.content.platform,
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
                    onPressed: _isLoading ? null : () {
                      _handlePlay();
                    },
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
        return 'Open in Spotify';
    }
  }

  Future<void> _handlePlay() async {
    if (_isLoading) return; // Prevent multiple clicks
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Always redirect to external platform - no direct playback
      String url;
      
      switch (widget.content.platform) {
        case ContentType.youtube:
          // Use externalUrl if available, otherwise construct from ID
          if (widget.content.externalUrl != null && widget.content.externalUrl!.isNotEmpty) {
            url = widget.content.externalUrl!;
          } else if (widget.content.id.isNotEmpty && !widget.content.id.startsWith('youtube_video_')) {
            // Only use direct video URL if ID is a real YouTube video ID
            url = 'https://www.youtube.com/watch?v=${widget.content.id}';
          } else {
            // For mock content, redirect to YouTube search
            url = 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(widget.content.title)}';
          }
          break;
        case ContentType.spotify:
          // Always redirect to Spotify - no preview playback
          if (widget.content.externalUrl != null && widget.content.externalUrl!.isNotEmpty) {
            url = widget.content.externalUrl!;
          } else {
            // Fallback: redirect to Spotify search for the track
            url = 'https://open.spotify.com/search/${Uri.encodeComponent(widget.content.title)}';
          }
          break;
      case ContentType.tmdb:
        // For TMDB, try external URL first, then fallback to search
        if (widget.content.externalUrl != null && widget.content.externalUrl!.isNotEmpty) {
          url = widget.content.externalUrl!;
        } else {
          // Fallback: redirect to TMDB search for the movie
          url = 'https://www.themoviedb.org/search?query=${Uri.encodeComponent(widget.content.title)}';
        }
        break;
      }

      print('🔗 Attempting to launch URL: $url');
      
      try {
        final uri = Uri.parse(url);
        
        // Try to launch URL directly - canLaunchUrl can be unreliable on Android
        try {
          print('🚀 Launching with externalApplication mode...');
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          
          print('✅ Launch result: $launched');
          
          if (launched) {
            // Close the dialog after successful launch
            if (mounted) {
              Navigator.of(context).pop();
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Opening ${widget.content.title}...'),
                  backgroundColor: widget.content.platform == ContentType.spotify 
                      ? const Color(0xFF1DB954) 
                      : widget.content.platform == ContentType.youtube
                          ? const Color(0xFFFF4444)
                          : const Color(0xFF667eea),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } else {
            // If launchUrl returns false, try with platformDefault mode
            print('⚠️ ExternalApplication failed, trying platformDefault...');
            try {
              final launched2 = await launchUrl(
                uri,
                mode: LaunchMode.platformDefault,
              );
              print('✅ PlatformDefault launch result: $launched2');
              if (launched2 && mounted) {
                Navigator.of(context).pop();
              } else {
                _showError('Could not open ${widget.content.platform.name}. Please install the app or try again.');
              }
            } catch (e2) {
              print('❌ PlatformDefault error: $e2');
              _showError('Could not open ${widget.content.platform.name}. Error: ${e2.toString()}');
            }
          }
        } catch (launchError) {
          // If launchUrl throws an error, show helpful message
          print('❌ Launch error: $launchError');
          _showError('Could not open ${widget.content.platform.name}. Please make sure the app is installed or try opening in browser.');
        }
      } catch (e) {
        print('❌ URL parse error: $e');
        _showError('Invalid URL: ${e.toString()}');
      }
    } catch (e) {
      print('❌ General error: $e');
      _showError('Error opening content: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
