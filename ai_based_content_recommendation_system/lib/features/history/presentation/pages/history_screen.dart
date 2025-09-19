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

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _historyService.init();
      final history = await _historyService.getHistory();
      setState(() {
        _historyItems = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading history: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeFromHistory(String itemId) async {
    try {
      await _historyService.removeFromHistory(itemId);
      setState(() {
        _historyItems.removeWhere((item) => item.id == itemId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from history'),
          backgroundColor: Color(0xFF667eea),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing from history: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearAllHistory() async {
    try {
      await _historyService.clearAllHistory();
      setState(() {
        _historyItems.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('History cleared'),
          backgroundColor: Color(0xFF667eea),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing history: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openContent(ContentItem item) {
    showDialog(
      context: context,
      builder: (context) => MediaPlayer(content: item),
    );
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
            actions: [
              if (_historyItems.isNotEmpty)
                IconButton(
                  onPressed: _clearAllHistory,
                  icon: const Icon(Icons.clear_all_rounded),
                  tooltip: 'Clear All History',
                ),
            ],
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
