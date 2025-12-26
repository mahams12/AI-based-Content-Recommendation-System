import 'package:flutter/material.dart';
import '../../../../core/models/content_model.dart';
import '../../../../core/services/history_service.dart';
import '../../../../core/widgets/media_player.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  List<ContentItem> _historyItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // Reload history when screen becomes visible again
  void _refreshHistory() {
    _loadHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload history when screen becomes visible
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize with timeout to prevent hanging
      await _historyService.init().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          print('⚠️ History init timed out, continuing anyway');
        },
      );
      
      // Get history with timeout
      final history = await _historyService.getHistory().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⚠️ Get history timed out, returning empty list');
          return <ContentItem>[];
        },
      );
      
      setState(() {
        _historyItems = history;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading history: $e');
      setState(() {
        _historyItems = [];
        _isLoading = false;
      });
      // Don't show error snackbar for timeout - just show empty state
      if (!e.toString().contains('TimeoutException')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeFromHistory(String itemId) async {
    // Store all items with this ID in case we need to restore them
    final itemsToRemove = _historyItems.where((item) => item.id == itemId).toList();
    
    // Optimistically update UI first for immediate feedback
    setState(() {
      _historyItems.removeWhere((item) => item.id == itemId);
    });
    
    try {
      // Then remove from service
      await _historyService.removeFromHistory(itemId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from history'),
            backgroundColor: Color(0xFF667eea),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // If removal failed, restore the items in the UI
      setState(() {
        _historyItems.addAll(itemsToRemove);
        // Sort by timestamp to maintain order (most recent first)
        _historyItems.sort((a, b) {
          // You might want to add timestamp comparison here if available
          return 0; // For now, just restore
        });
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing from history: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _openContent(ContentItem item) async {
    await showDialog(
      context: context,
      builder: (context) => MediaPlayer(content: item),
    );
    // Reload history after closing the media player
    _refreshHistory();
  }

  IconData _getPlatformIcon(ContentType platform) {
    switch (platform) {
      case ContentType.youtube:
        return Icons.play_arrow_rounded;
      case ContentType.tmdb:
        return Icons.movie_rounded;
      case ContentType.spotify:
        return Icons.music_note_rounded;
    }
  }

  Color _getPlatformColor(ContentType platform) {
    switch (platform) {
      case ContentType.youtube:
        return Colors.red;
      case ContentType.tmdb:
        return Colors.blue;
      case ContentType.spotify:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0F1419),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                ),
              ),
            ),
          ),

          // Content
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF667eea),
                ),
              ),
            )
          else if (_historyItems.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 80,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No History Yet',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start watching content to build your history',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _historyItems[index];
                    return _buildHistoryItem(item);
                  },
                  childCount: _historyItems.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(ContentItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[700]!.withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openContent(item),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail
                Container(
                  width: 80,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: item.thumbnailUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(item.thumbnailUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: item.thumbnailUrl.isEmpty 
                        ? _getPlatformColor(item.platform).withOpacity(0.2)
                        : null,
                  ),
                  child: item.thumbnailUrl.isEmpty
                      ? Icon(
                          _getPlatformIcon(item.platform),
                          color: _getPlatformColor(item.platform),
                          size: 24,
                        )
                      : null,
                ),
                
                const SizedBox(width: 12),
                
                // Content Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getPlatformColor(item.platform).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.platform.name.toUpperCase(),
                              style: TextStyle(
                                color: _getPlatformColor(item.platform),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.channelName ?? item.artistName ?? '',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (item.duration != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.duration!,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Delete Button
                IconButton(
                  onPressed: () => _removeFromHistory(item.id),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  tooltip: 'Remove from History',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
