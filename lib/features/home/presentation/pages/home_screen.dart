import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/models/content_model.dart';
import '../../../../core/widgets/media_player.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../widgets/trending_content_scroller.dart';


// Main Home Screen
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  
  String selectedCategory = 'All';
  final List<String> categories = ['All', 'YouTube Videos', 'Movies', 'Songs'];

  final ApiService _apiService = ApiService();
  List<ContentItem> _trendingContent = [];
  List<ContentItem> _categoryContent = [];
  bool _isLoadingCategory = false;
  bool _showApiWarning = false;
  

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _slideController.forward();
    _loadTrendingContent();
    _loadCategoryContent();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }



  // Check API status and show warning if needed
  void _checkApiStatus() {
    setState(() {
      _showApiWarning = ApiService.isYouTubeApiFailing;
    });
  }

  // Load trending content for the trending section (top 3 cards)
  Future<void> _loadTrendingContent() async {
    if (!mounted) return;
    
    try {
      final result = await _apiService.getTrendingContent(maxResultsPerPlatform: 5);
      if (!mounted) return;
      
      if (result.isSuccess && result.data != null) {
        setState(() {
          _trendingContent = result.data!;
          _showApiWarning = ApiService.isYouTubeApiFailing;
        });
      }
    } catch (e) {
      // Handle error silently for now
    }
  }

  // Load all types of content for general browsing sections (not just trending)
  Future<void> _loadCategoryContent() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingCategory = true;
    });

    try {
      List<ContentItem> content = [];
      
      if (selectedCategory == 'All') {
        // Use getAllContent for general browsing (not just trending)
        final result = await _apiService.getAllContent(maxResults: 50);
        if (result.isSuccess && result.data != null) {
          content = result.data!;
        }
      } else if (selectedCategory == 'YouTube Videos') {
        // Get diverse YouTube content (not just trending)
        final result = await _apiService.getAllContent(platform: ContentType.youtube, maxResults: 50);
        if (result.isSuccess && result.data != null) {
          content = result.data!;
        }
      } else if (selectedCategory == 'Movies') {
        // Get popular movies and TV shows (not just trending)
        final result = await _apiService.getAllContent(platform: ContentType.tmdb, maxResults: 50);
        if (result.isSuccess && result.data != null) {
          content = result.data!;
        }
      } else if (selectedCategory == 'Songs') {
        // Get diverse Spotify content (not just trending)
        final result = await _apiService.getAllContent(platform: ContentType.spotify, maxResults: 50);
        if (result.isSuccess && result.data != null) {
          content = result.data!;
        }
      }

      if (!mounted) return;
      setState(() {
        _categoryContent = content;
        _isLoadingCategory = false;
        _showApiWarning = ApiService.isYouTubeApiFailing;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingCategory = false;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  List<Color> _getGradientColors(ContentItem item) {
    switch (item.platform) {
      case ContentType.youtube:
        return [const Color(0xFFFF4444), const Color(0xFFFF6B6B)];
      case ContentType.tmdb:
        return [const Color(0xFF667eea), const Color(0xFF764ba2)];
      case ContentType.spotify:
        return [const Color(0xFF1DB954), const Color(0xFF1ED760)];
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'YouTube Videos':
        return Icons.play_circle_filled;
      case 'Movies':
        return Icons.movie_creation_rounded;
      case 'Songs':
        return Icons.music_note_rounded;
      default:
        return Icons.explore_rounded;
    }
  }





  void _openContent(ContentItem item) {
    showDialog(
      context: context,
      builder: (context) => MediaPlayer(content: item),
    );
  }

  void _openTrendingContentScroller(String title, ContentType platform, IconData icon, Color color, List<ContentItem> items) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrendingContentScroller(
          title: title,
          platform: platform,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildAppBar()),
                  if (_showApiWarning) SliverToBoxAdapter(child: _buildApiWarningBanner()),
                  SliverToBoxAdapter(
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildTrendingSection(),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildCategoryFilter()),
                  SliverToBoxAdapter(child: _buildContentSections()),
                ],
              ),
            ),
          ),
          
        ],
      ),
    );
  }


  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          // App Title and Greeting
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Content Nation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildTrendingSection() {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 28,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF4444), Color(0xFFFF6B6B)],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Trending Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Three trending categories in a row
          Row(
            children: [
              Expanded(
                child: _buildTrendingCategory(
                  'YouTube',
                  Icons.play_arrow_rounded,
                  const Color(0xFFFF4444),
                  _trendingContent.where((item) => item.platform == ContentType.youtube).toList(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTrendingCategory(
                  'Movies',
                  Icons.movie_rounded,
                  const Color(0xFF667eea),
                  _trendingContent.where((item) => item.platform == ContentType.tmdb).toList(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTrendingCategory(
                  'Songs',
                  Icons.music_note_rounded,
                  const Color(0xFF1DB954),
                  _trendingContent.where((item) => item.platform == ContentType.spotify).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingCategory(String title, IconData icon, Color color, List<ContentItem> items) {
    ContentType platform;
    switch (title.toLowerCase()) {
      case 'youtube':
        platform = ContentType.youtube;
        break;
      case 'movies':
        platform = ContentType.tmdb;
        break;
      case 'songs':
        platform = ContentType.spotify;
        break;
      default:
        platform = ContentType.youtube;
    }

    return GestureDetector(
      onTap: () {
        _openTrendingContentScroller(
          'Trending $title',
          platform,
          icon,
          color,
          items,
        );
      },
      child: Container(
        height: 240, // Increased height for better content display
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C2128),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Content area with proper constraints
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 32,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No $title',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: double.infinity,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: items.take(3).length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return Container(
                                  width: 85, // Good size, not too small
                                  margin: const EdgeInsets.only(right: 8),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        height: 85, // Good size for thumbnails
                                        width: 85,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          gradient: LinearGradient(
                                            colors: _getGradientColors(item),
                                          ),
                                        ),
                                        child: Stack(
                                          children: [
                                            if (item.thumbnailUrl.isNotEmpty)
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: SafeNetworkImage(
                                                  imageUrl: item.thumbnailUrl,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  borderRadius: BorderRadius.circular(12),
                                                  platform: item.platform,
                                                ),
                                              )
                                            else
                                              Center(
                                                child: Icon(
                                                  icon,
                                                  size: 24,
                                                  color: Colors.white,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            // See All Button - replaces the number display
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    color.withOpacity(0.2),
                    color.withOpacity(0.1),
                  ]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'See All',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: color,
                      size: 12,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCategoryFilter() {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = categories[index] == selectedCategory;
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = categories[index];
              });
              _loadCategoryContent();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      )
                    : null,
                color: isSelected ? null : const Color(0xFF1C2128),
                borderRadius: BorderRadius.circular(28),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF667eea).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getCategoryIcon(categories[index]),
                    size: 18,
                    color: isSelected ? Colors.white : Colors.grey[400],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    categories[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[400],
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentSections() {
    if (_isLoadingCategory) {
      return Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading $selectedCategory...',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (selectedCategory == 'All') ...[
          _buildContentSection(
            'YouTube Videos', 
            Icons.play_circle_filled, 
            _categoryContent.where((item) => item.platform == ContentType.youtube).toList(),
          ),
          _buildContentSection(
            'Movies & TV Shows', 
            Icons.movie_creation_rounded, 
            _categoryContent.where((item) => item.platform == ContentType.tmdb).toList(),
          ),
          _buildContentSection(
            'Songs & Music', 
            Icons.music_note_rounded, 
            _categoryContent.where((item) => item.platform == ContentType.spotify).toList(),
          ),
        ] else
          _buildContentSection(
            selectedCategory, 
            _getCategoryIcon(selectedCategory), 
            _categoryContent,
          ),
      ],
    );
  }

  Widget _buildContentSection(String title, IconData icon, List<ContentItem> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667eea).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _showAllCategoryContent(title, items);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C2128),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF667eea).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'See All',
                          style: const TextStyle(
                            color: Color(0xFF667eea),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: Color(0xFF667eea),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 340, // Increased height to accommodate content properly
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _buildEnhancedContentCard(items[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAllCategoryContent(String title, List<ContentItem> items) {
    ContentType platform;
    IconData icon;
    Color color;

    // Determine platform, icon, and color based on title
    if (title.contains('YouTube')) {
      platform = ContentType.youtube;
      icon = Icons.play_arrow_rounded;
      color = const Color(0xFFFF4444);
    } else if (title.contains('Movie') || title.contains('TV')) {
      platform = ContentType.tmdb;
      icon = Icons.movie_rounded;
      color = const Color(0xFF667eea);
    } else if (title.contains('Song') || title.contains('Music')) {
      platform = ContentType.spotify;
      icon = Icons.music_note_rounded;
      color = const Color(0xFF1DB954);
    } else {
      platform = ContentType.youtube;
      icon = Icons.explore_rounded;
      color = const Color(0xFF667eea);
    }

    _openTrendingContentScroller(title, platform, icon, color, items);
  }

  Widget _buildEnhancedContentCard(ContentItem item) {
    final colors = _getGradientColors(item);
    
    return GestureDetector(
      onTap: () => _openContent(item),
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1C2128),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey[700]!.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160, // Reduced image height to make room for text
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Stack(
                children: [
                  // Background gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                  ),
                  
                  // Thumbnail if available
                  if (item.thumbnailUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: SafeNetworkImage(
                        imageUrl: item.thumbnailUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        platform: item.platform,
                      ),
                    ),
                  
                  // Overlay gradient for better text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                  ),
                  
                  // Top badges
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colors[0].withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getPlatformIcon(item.platform),
                            size: 12,
                            color: colors[0],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.platform.name.toUpperCase(),
                            style: TextStyle(
                              color: colors[0],
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Rating badge for TMDB content
                  if (item.platform == ContentType.tmdb && item.rating != null)
                    Positioned(
                      top: 12,
                      right: 60, // Positioned to the left of play button
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  
                  // Year badge for TMDB content
                  if (item.platform == ContentType.tmdb && item.publishedAt != null)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.publishedAt!.year.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  
                  // Play button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  
                  // Bottom info overlay
                  if (item.viewCount != null || item.duration != null)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Row(
                        children: [
                          if (item.viewCount != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.visibility_rounded,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatNumber(item.viewCount!),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (item.duration != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.duration!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            // Content info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16), // Reduced padding for more space
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15, // Slightly smaller font
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6), // Reduced spacing
                    Text(
                      item.platform == ContentType.tmdb 
                        ? _getTMDBSubtitle(item)
                        : (item.channelName ?? item.artistName ?? item.description),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13, // Slightly smaller font
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 2, // Thinner progress bar
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: colors),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8), // Reduced spacing
                        Container(
                          width: 28, // Smaller button
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: colors),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 14, // Smaller icon
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

  // Build API warning banner
  Widget _buildApiWarningBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_rounded,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'YouTube API quota exceeded. Showing demo content.',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ApiService.resetYouTubeApiFailure();
              _checkApiStatus();
              _loadTrendingContent();
              _loadCategoryContent();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Retry',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}