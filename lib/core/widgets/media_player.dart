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
    try {
      // Initialize history service
      await _historyService.init();
      
      // Add to history when MediaPlayer opens
      if (!_historyAdded) {
        print('📝 Adding ${widget.content.title} to history...');
        await _historyService.addToHistory(widget.content);
        _historyAdded = true;
        print('✅ Successfully added to history');
      }
    } catch (e) {
      print('❌ Error adding to history: $e');
      // Don't block the UI if history fails
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

            // Media Preview - Make entire area tappable
            GestureDetector(
              onTap: _isLoading ? null : _handlePlay,
              child: Container(
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
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                      ),
                    ),
                  ],
                ),
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
        return 'Open in Spotify';
    }
  }

  Future<void> _handlePlay() async {
    if (_isLoading) return; // Prevent multiple clicks
    
    setState(() {
      _isLoading = true;
    });

    // Build URL first (fast, synchronous)
    String url;
    switch (widget.content.platform) {
      case ContentType.youtube:
        if (widget.content.externalUrl != null && widget.content.externalUrl!.isNotEmpty) {
          url = widget.content.externalUrl!;
        } else if (widget.content.id.isNotEmpty && !widget.content.id.startsWith('youtube_video_')) {
          url = 'https://www.youtube.com/watch?v=${widget.content.id}';
        } else {
          url = 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(widget.content.title)}';
        }
        break;
      case ContentType.spotify:
        if (widget.content.externalUrl != null && widget.content.externalUrl!.isNotEmpty) {
          url = widget.content.externalUrl!;
        } else {
          url = 'https://open.spotify.com/search/${Uri.encodeComponent(widget.content.title)}';
        }
        break;
      case ContentType.tmdb:
        if (widget.content.externalUrl != null && widget.content.externalUrl!.isNotEmpty) {
          url = widget.content.externalUrl!;
        } else {
          url = 'https://www.themoviedb.org/search?query=${Uri.encodeComponent(widget.content.title)}';
        }
        break;
    }

    print('🔗 Launching URL: $url');
    
    // Launch URL immediately (don't wait for history)
    try {
      final uri = Uri.parse(url);
      
      // Try to launch quickly with minimal timeout
      bool launched = false;
      
      // First attempt: externalApplication (fastest)
      try {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        ).timeout(
          const Duration(seconds: 3), // Shorter timeout for faster response
          onTimeout: () => false,
        );
      } catch (e) {
        print('⚠️ ExternalApplication error: $e');
      }
      
      // Quick fallback if first attempt failed
      if (!launched) {
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          ).timeout(
            const Duration(seconds: 3),
            onTimeout: () => false,
          );
        } catch (e) {
          print('⚠️ PlatformDefault error: $e');
        }
      }
      
      // Close dialog immediately if launched
      if (launched && mounted) {
        setState(() {
          _isLoading = false;
        });
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
            duration: const Duration(seconds: 1),
          ),
        );
        
        // Add to history in background (non-blocking)
        _addToHistoryInBackground();
        return;
      }
      
      // If launch failed, show error
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError('Could not open ${widget.content.platform.name}. Please try again.');
      }
    } catch (e) {
      print('❌ Launch error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError('Error opening content: ${e.toString()}');
      }
    }
  }

  // Add to history in background without blocking
  void _addToHistoryInBackground() {
    if (_historyAdded) return;
    
    Future.microtask(() async {
      try {
        await _historyService.init();
        await _historyService.addToHistory(widget.content);
        _historyAdded = true;
        print('✅ Added ${widget.content.title} to history');
      } catch (e) {
        print('⚠️ Error adding to history: $e');
        // Don't show error to user - history is not critical
      }
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SingleChildScrollView(
          child: Text(
            message,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

