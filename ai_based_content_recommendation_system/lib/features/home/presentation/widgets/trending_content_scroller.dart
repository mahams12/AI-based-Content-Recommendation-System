import 'package:flutter/material.dart';
import '../../../../core/models/content_model.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/models/api_response.dart';
import 'youtube_content_filter.dart';
import 'tmdb_genre_filter.dart';
import '../../../../core/widgets/media_player.dart';

class TrendingContentScroller extends StatefulWidget {
  final String title;
  final ContentType platform;
  final Color color;

  const TrendingContentScroller({
    super.key,
    required this.title,
    required this.platform,
    required this.color,
  });

  @override
  State<TrendingContentScroller> createState() => _TrendingContentScrollerState();
}

class _TrendingContentScrollerState extends State<TrendingContentScroller>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  final ApiService _apiService = ApiService();
  List<ContentItem> _allContent = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _selectedContentType;
  String? _selectedVideoFormat;
  String? _selectedGenre;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadMoreContent();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );


    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMoreContent() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      ApiResponse<List<ContentItem>> response;
      
      // Use genre-specific API for TMDB when a genre is selected
      if (widget.platform == ContentType.tmdb && _selectedGenre != null) {
        // Get the genre ID from the genre name
        final genreId = _getGenreIdFromName(_selectedGenre!);
        response = await _apiService.getTMDBMoviesByGenre(
          genreId: genreId,
          maxResults: 100,
        );
      } else {
        // Use regular extended trending content API
        response = await _apiService.getExtendedTrendingContent(
          platform: widget.platform,
          maxResults: 100,
        );
      }

      if (response.isSuccess && response.data != null) {
        setState(() {
          _allContent = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load content: $e';
        _isLoading = false;
      });
    }
  }

  List<ContentItem> get _filteredContent {
    return _allContent.where((item) {
      bool matchesSearch = _searchQuery.isEmpty;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        matchesSearch = 
            item.title.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query) ||
            (item.channelName?.toLowerCase().contains(query) ?? false) ||
            (item.artistName?.toLowerCase().contains(query) ?? false) ||
            (item.contentType?.toLowerCase().contains(query) ?? false) ||
            _searchInTags(item, query);

        if (!matchesSearch) {
          matchesSearch = _handleSpecialSearchTerms(query, item);
        }
      }

      bool matchesContentType = true;
      if (widget.platform == ContentType.youtube && _selectedContentType != null) {
        matchesContentType = item.contentType == _selectedContentType;
      }

      bool matchesVideoFormat = true;
      if (widget.platform == ContentType.youtube && _selectedVideoFormat != null) {
        matchesVideoFormat = item.videoFormat == _selectedVideoFormat;
      }

      bool matchesGenre = true;
      if (widget.platform == ContentType.tmdb && _selectedGenre != null && _selectedGenre != 'All Genres') {
        if (item.metadata != null && item.metadata!['genre_ids'] != null) {
          final genreIds = item.metadata!['genre_ids'] as List<dynamic>?;
          final genreId = _getGenreIdFromName(_selectedGenre!);
          matchesGenre = genreIds?.contains(genreId) ?? false;
        } else {
          matchesGenre = false;
        }
      }

      return matchesSearch && matchesContentType && matchesVideoFormat && matchesGenre;
    }).toList();
  }

  bool _searchInTags(ContentItem item, String query) {
    if (item.metadata != null && item.metadata!['snippet'] != null) {
      final tags = item.metadata!['snippet']['tags'] as List<dynamic>?;
      if (tags != null) {
        return tags.any((tag) => tag.toString().toLowerCase().contains(query));
      }
    }
    return false;
  }

  bool _handleSpecialSearchTerms(String query, ContentItem item) {
    final specialTerms = {
      'cooking': ['cooking', 'recipe', 'food', 'chef', 'kitchen'],
      'documentary': ['documentary', 'nature', 'wildlife', 'history', 'science'],
      'science': ['science', 'space', 'facts', 'education', 'university'],
      'art': ['art', 'painting', 'drawing', 'creative', 'design'],
    };

    for (final entry in specialTerms.entries) {
      if (query.contains(entry.key)) {
        final relatedTerms = entry.value;
        return relatedTerms.any((term) => 
          item.title.toLowerCase().contains(term) ||
          item.description.toLowerCase().contains(term) ||
          (item.contentType?.toLowerCase().contains(term) ?? false) ||
          _searchInTags(item, term)
        );
      }
    }
    return false;
  }

  void _openContent(ContentItem item) {
    showDialog(
      context: context,
      builder: (context) => MediaPlayer(content: item),
    );
  }

  void _onContentTypeChanged(String? contentType) {
    setState(() {
      _selectedContentType = contentType;
    });
  }

  void _onVideoFormatChanged(String? videoFormat) {
    setState(() {
      _selectedVideoFormat = videoFormat;
    });
  }

  void _onGenreChanged(String? genre) {
    setState(() {
      _selectedGenre = genre;
    });
    // Reload content when genre changes
    _loadMoreContent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(),
            _buildSearchBar(),
            if (widget.platform == ContentType.youtube)
              YouTubeContentFilter(
                selectedContentType: _selectedContentType,
                selectedVideoFormat: _selectedVideoFormat,
                onContentTypeChanged: _onContentTypeChanged,
                onVideoFormatChanged: _onVideoFormatChanged,
              ),
            if (widget.platform == ContentType.tmdb)
              TMDBGenreFilter(
                selectedGenre: _selectedGenre,
                onGenreChanged: _onGenreChanged,
              ),
            Expanded(
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildContentGrid(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[800]!.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Browse Content',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.color,
                  widget.color.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.platform.name.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF1C2128),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.grey[700]!.withOpacity(0.3),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: Colors.grey[400],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search content, channels, or topics...',
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[600]!.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.clear_rounded,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentGrid() {
    if (_error != null) {
      return _buildErrorState();
    }

    if (_filteredContent.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadMoreContent,
      color: widget.color,
      backgroundColor: const Color(0xFF1C2128),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: GridView.builder(
          key: ValueKey(_filteredContent.length),
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _filteredContent.length + (_isLoading ? 2 : 0),
          itemBuilder: (context, index) {
            if (index >= _filteredContent.length) {
              return _buildLoadingCard();
            }
            return _buildContentCard(_filteredContent[index]);
          },
        ),
      ),
    );
  }

  Widget _buildContentCard(ContentItem item) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: GestureDetector(
              onTap: () => _openContent(item),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2128),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey[800]!.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          image: DecorationImage(
                            image: NetworkImage(item.thumbnailUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Duration badge (for YouTube content)
                            if (item.duration != null && item.duration != 'N/A' && item.platform != ContentType.tmdb)
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.duration!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            // Rating badge for TMDB content
                            if (item.platform == ContentType.tmdb && item.rating != null)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.amber.withOpacity(0.6),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: Colors.amber[400],
                                        size: 12,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        item.rating!.toStringAsFixed(1),
                                        style: TextStyle(
                                          color: Colors.amber[400],
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            // Short badge for YouTube
                            if (item.videoFormat == 'Short' && item.platform == ContentType.youtube)
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF4444),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'SHORT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            // Year badge for TMDB content
                            if (item.platform == ContentType.tmdb && item.publishedAt != null)
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.publishedAt!.year.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title
                            Expanded(
                              flex: 3,
                              child: Text(
                                item.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Subtitle (Channel/Artist/Genre for TMDB)
                            Expanded(
                              flex: 2,
                              child: Text(
                                item.platform == ContentType.tmdb 
                                  ? _getTMDBSubtitle(item)
                                  : (item.channelName ?? item.artistName ?? ''),
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Overview for TMDB content (truncated)
                            if (item.platform == ContentType.tmdb && item.description.isNotEmpty)
                              Expanded(
                                flex: 3,
                                child: Text(
                                  item.description,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 9,
                                    fontWeight: FontWeight.w400,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 2,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [
                                        widget.color,
                                        widget.color.withOpacity(0.5),
                                      ]),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      widget.color,
                                      widget.color.withOpacity(0.7),
                                    ]),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getTMDBSubtitle(ContentItem item) {
    // Get genre names from metadata
    if (item.metadata != null && item.metadata!['genre_ids'] != null) {
      final genreIds = item.metadata!['genre_ids'] as List<dynamic>?;
      if (genreIds != null && genreIds.isNotEmpty) {
        // Map genre IDs to names (simplified mapping)
        final genreMap = {
          28: 'Action', 12: 'Adventure', 16: 'Animation', 35: 'Comedy',
          80: 'Crime', 99: 'Documentary', 18: 'Drama', 10751: 'Family',
          14: 'Fantasy', 36: 'History', 27: 'Horror', 10402: 'Music',
          9648: 'Mystery', 10749: 'Romance', 878: 'Sci-Fi', 10770: 'TV Movie',
          53: 'Thriller', 10752: 'War', 37: 'Western'
        };
        
        final genres = genreIds
            .take(2) // Show max 2 genres
            .map((id) => genreMap[id] ?? 'Unknown')
            .where((genre) => genre != 'Unknown')
            .toList();
        
        if (genres.isNotEmpty) {
          return genres.join(' • ');
        }
      }
    }
    
    // Fallback to category
    return item.category.toString().split('.').last.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim();
  }

  Widget _buildLoadingCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[800]!.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 8,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            color: Colors.grey[600],
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No content found',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search terms',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.red[400],
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadMoreContent,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.color,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  int? _getGenreIdFromName(String genreName) {
    const genreMap = {
      'Action': 28,
      'Adventure': 12,
      'Animation': 16,
      'Comedy': 35,
      'Crime': 80,
      'Documentary': 99,
      'Drama': 18,
      'Family': 10751,
      'Fantasy': 14,
      'History': 36,
      'Horror': 27,
      'Music': 10402,
      'Mystery': 9648,
      'Romance': 10749,
      'Sci-Fi': 878,
      'Thriller': 53,
      'War': 10752,
      'Western': 37,
    };
    
    return genreMap[genreName];
  }
}
