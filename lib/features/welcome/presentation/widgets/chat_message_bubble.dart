import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/chat_message.dart';
import '../../../../core/models/content_model.dart';
import '../../../../core/services/history_service.dart';

class ChatMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final Function(String)? onOptionSelected;
  final List<String>? options;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onOptionSelected,
    this.options,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final HistoryService _historyService = HistoryService();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
      begin: widget.message.isBot 
          ? const Offset(-0.3, 0) 
          : const Offset(0.3, 0),
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

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.message.isBot) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppTheme.primaryGradient,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              
              Expanded(
                child: Column(
                  crossAxisAlignment: widget.message.isBot 
                      ? CrossAxisAlignment.start 
                      : CrossAxisAlignment.end,
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: widget.message.isBot
                            ? Colors.white.withOpacity(0.1)
                            : AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(18).copyWith(
                          bottomLeft: widget.message.isBot 
                              ? const Radius.circular(4) 
                              : const Radius.circular(18),
                          bottomRight: widget.message.isBot 
                              ? const Radius.circular(18) 
                              : const Radius.circular(4),
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: _buildMessageWithLinks(widget.message.text),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Option buttons for bot messages
                    if (widget.message.isBot && widget.options != null)
                      ...widget.options!.map((option) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => widget.onOptionSelected?.call(option),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      option.split(' ').first, // Get emoji only
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      option.split(' ').skip(1).join(' '), // Get text without emoji
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    
                    // Timestamp
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatTime(widget.message.timestamp),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              if (!widget.message.isBot) ...[
                const SizedBox(width: 12),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildMessageWithLinks(String text) {
    // Regular expression to find URLs
    final urlRegex = RegExp(
      r'https?://[^\s]+',
      caseSensitive: false,
    );

    final matches = urlRegex.allMatches(text);
    if (matches.isEmpty) {
      // No URLs found, return plain text
      return Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 15,
          color: Colors.white,
          height: 1.4,
        ),
      );
    }

    // Build RichText with clickable links
    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      // Add text before the URL
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.white,
            height: 1.4,
          ),
        ));
      }

      // Add clickable URL
      final url = match.group(0)!;
      spans.add(
        TextSpan(
        text: url,
        style: GoogleFonts.inter(
          fontSize: 15,
          color: AppTheme.primaryColor,
          height: 1.4,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
              try {
            final uri = Uri.parse(url);
                
                // Add to history when link is clicked
                _addUrlToHistory(url);
                
                bool launched = false;

                // First try opening in the external app (Spotify / YouTube / browser)
                try {
                  launched = await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );
                } catch (e) {
                  // Fallback below
                  // ignore: avoid_print
                  print('⚠️ Chat link external launch error for $url: $e');
                }

                // Quick fallback to platform default if external app launch failed
                if (!launched) {
                  try {
                    await launchUrl(
                      uri,
                      mode: LaunchMode.platformDefault,
                    );
                  } catch (e) {
                    // ignore: avoid_print
                    print('❌ Chat link platform launch error for $url: $e');
                  }
                }
              } catch (e) {
                // ignore: avoid_print
                print('❌ Chat link parse error for $url: $e');
            }
          },
        ),
      );

      lastEnd = match.end;
    }

    // Add remaining text after the last URL
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: GoogleFonts.inter(
          fontSize: 15,
          color: Colors.white,
          height: 1.4,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  /// Add URL to history when clicked from chat
  Future<void> _addUrlToHistory(String url) async {
    try {
      await _historyService.init();
      
      // Parse URL to determine platform and create ContentItem
      ContentType platform = ContentType.youtube;
      ContentCategory category = ContentCategory.video;
      String title = 'Content';
      String id = url;
      
      if (url.contains('spotify.com')) {
        platform = ContentType.spotify;
        category = ContentCategory.music;
        // Try to extract track name from search URL
        final searchMatch = RegExp(r'search/([^?&]+)').firstMatch(url);
        if (searchMatch != null) {
          title = Uri.decodeComponent(searchMatch.group(1)!.replaceAll('+', ' '));
        } else {
          title = 'Spotify Track';
        }
        // Extract track ID if possible
        final trackMatch = RegExp(r'/track/([a-zA-Z0-9]+)').firstMatch(url);
        if (trackMatch != null) {
          id = trackMatch.group(1)!;
        }
      } else if (url.contains('youtube.com') || url.contains('youtu.be')) {
        platform = ContentType.youtube;
        category = ContentCategory.video;
        // Extract video ID
        final videoMatch = RegExp(r'(?:v=|/)([a-zA-Z0-9_-]{11})').firstMatch(url);
        if (videoMatch != null) {
          id = videoMatch.group(1)!;
          title = 'YouTube Video';
        } else {
          // For search URLs, try to extract query
          final searchMatch = RegExp(r'search_query=([^&]+)').firstMatch(url);
          if (searchMatch != null) {
            title = Uri.decodeComponent(searchMatch.group(1)!.replaceAll('+', ' '));
          } else {
            title = 'YouTube Video';
          }
        }
      } else if (url.contains('themoviedb.org')) {
        platform = ContentType.tmdb;
        category = ContentCategory.movie;
        // Extract movie ID
        final movieMatch = RegExp(r'/movie/(\d+)').firstMatch(url);
        if (movieMatch != null) {
          id = movieMatch.group(1)!;
          title = 'Movie';
        } else {
          // For search URLs
          final searchMatch = RegExp(r'query=([^&]+)').firstMatch(url);
          if (searchMatch != null) {
            title = Uri.decodeComponent(searchMatch.group(1)!.replaceAll('+', ' '));
          } else {
            title = 'Movie';
          }
        }
      }
      
      final contentItem = ContentItem(
        id: id,
        title: title,
        description: 'Opened from chat',
        thumbnailUrl: '',
        platform: platform,
        category: category,
        externalUrl: url,
      );
      
      await _historyService.addToHistory(contentItem);
      print('✅ Added chat link to history: $url');
    } catch (e) {
      print('⚠️ Could not add chat link to history: $e');
      // Don't block the user if history fails
    }
  }
}

