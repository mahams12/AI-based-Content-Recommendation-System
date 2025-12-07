import 'package:flutter/material.dart';
import '../models/content_model.dart';
import '../services/history_service.dart';
import 'media_player.dart';

class SearchDropdown extends StatefulWidget {
  final Function(String) onSearch;
  final List<ContentItem> searchResults;
  final bool isLoading;
  final String query;

  const SearchDropdown({
    super.key,
    required this.onSearch,
    required this.searchResults,
    required this.isLoading,
    required this.query,
  });

  @override
  State<SearchDropdown> createState() => _SearchDropdownState();
}

class _SearchDropdownState extends State<SearchDropdown> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final HistoryService _historyService = HistoryService();
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.query;
    _focusNode.addListener(_onFocusChange);
    _historyService.init();
  }

  @override
  void didUpdateWidget(covariant SearchDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchResults != oldWidget.searchResults) {
      setState(() {
        _showDropdown = _focusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _showDropdown = _focusNode.hasFocus;
    });
  }

  void _onSearchChanged(String query) {
    if (query.trim().isNotEmpty) {
      widget.onSearch(query.trim());
      setState(() {
        _showDropdown = true;
      });
    } else {
      setState(() {
        _showDropdown = false;
      });
    }
  }

  void _openContent(ContentItem item) {
    // Close the dropdown first
    _focusNode.unfocus();
    
    // Add to history
    _addToHistory(item);
    
    // Navigate based on content type
    _navigateToContent(item);
  }

  void _addToHistory(ContentItem item) {
    _historyService.addToHistory(item);
  }

  void _navigateToContent(ContentItem item) {
    switch (item.platform) {
      case ContentType.youtube:
        _navigateToYouTubeSection(item);
        break;
      case ContentType.tmdb:
        _navigateToMoviesSection(item);
        break;
      case ContentType.spotify:
        _navigateToMusicSection(item);
        break;
    }
  }

  void _navigateToYouTubeSection(ContentItem item) {
    // Navigate to YouTube section or show video player
    showDialog(
      context: context,
      builder: (context) => MediaPlayer(content: item),
    );
  }

  void _navigateToMoviesSection(ContentItem item) {
    // Navigate to Movies section or show movie player
    showDialog(
      context: context,
      builder: (context) => MediaPlayer(content: item),
    );
  }

  void _navigateToMusicSection(ContentItem item) {
    // Navigate to Music section or show music player
    showDialog(
      context: context,
      builder: (context) => MediaPlayer(content: item),
    );
  }

  String _getPlatformName(ContentType platform) {
    switch (platform) {
      case ContentType.youtube:
        return 'YouTube';
      case ContentType.tmdb:
        return 'TMDB';
      case ContentType.spotify:
        return 'Spotify';
    }
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
        return const Color(0xFFFF4444);
      case ContentType.tmdb:
        return const Color(0xFF667eea);
      case ContentType.spotify:
        return const Color(0xFF1DB954);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Close dropdown when tapping outside
        _focusNode.unfocus();
      },
      child: Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C2128), Color(0xFF2A2D3A)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey[700]!.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Input
          TextField(
            controller: _searchController,
            focusNode: _focusNode,
            onChanged: _onSearchChanged,
            onSubmitted: (query) {
              if (query.trim().isNotEmpty) {
                widget.onSearch(query.trim());
              }
            },
            decoration: InputDecoration(
              hintText: 'Search videos, movies, music...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Colors.white70,
                size: 20,
              ),
              suffixIcon: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF667eea),
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          
          // Dropdown Results
          if (_showDropdown && widget.query.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2128),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[700]!.withOpacity(0.3),
                  ),
                ),
              ),
              child: widget.isLoading
                  ? Container(
                      padding: const EdgeInsets.all(20),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF667eea),
                        ),
                      ),
                    )
                  : widget.searchResults.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 32,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No results found for "${widget.query}"',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: widget.searchResults.length,
                          itemBuilder: (context, index) {
                            final item = widget.searchResults[index];
                            return _buildSearchResultItem(item);
                          },
                        ),
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildSearchResultItem(ContentItem item) {
    final platformColor = _getPlatformColor(item.platform);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openContent(item),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[700]!.withOpacity(0.2),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: item.thumbnailUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(item.thumbnailUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: item.thumbnailUrl.isEmpty 
                      ? platformColor.withOpacity(0.2)
                      : null,
                ),
                child: item.thumbnailUrl.isEmpty
                    ? Icon(
                        _getPlatformIcon(item.platform),
                        color: platformColor,
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
                        fontSize: 14,
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
                            color: platformColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getPlatformName(item.platform),
                            style: TextStyle(
                              color: platformColor,
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
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.description,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Action Icon
              Icon(
                item.platform == ContentType.spotify
                    ? Icons.play_arrow_rounded
                    : Icons.play_circle_outline_rounded,
                color: platformColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
