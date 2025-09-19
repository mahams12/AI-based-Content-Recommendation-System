import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/models/content_model.dart';
import '../../../../core/widgets/media_player.dart';


// Main Home Screen
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _heroController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _heroAnimation;
  
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;
  
  
  String selectedCategory = 'All';
  final List<String> categories = ['All', 'YouTube Videos', 'Movies', 'Songs'];

  final ApiService _apiService = ApiService();
  List<ContentItem> _trendingContent = [];
  List<ContentItem> _categoryContent = [];
  bool _isLoading = false;
  bool _isLoadingCategory = false;
  String? _error;
  

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

    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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

    _heroAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heroController,
      curve: Curves.elasticOut,
    ));
    
    _fadeController.forward();
    _slideController.forward();
    _heroController.forward();
    _loadTrendingContent();
    _loadCategoryContent();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _heroController.dispose();
    _pageController.dispose();
    super.dispose();
  }



  Future<void> _loadTrendingContent() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _apiService.getTrendingContent(maxResultsPerPlatform: 5);
      if (!mounted) return;
      
      if (result.isSuccess && result.data != null) {
        setState(() {
          _trendingContent = result.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result.error ?? 'Failed to load trending content';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error loading content: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCategoryContent() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingCategory = true;
    });

    try {
      List<ContentItem> content = [];
      
      if (selectedCategory == 'All') {
        final result = await _apiService.getTrendingContent(maxResultsPerPlatform: 10);
        if (result.isSuccess && result.data != null) {
          content = result.data!;
        }
      } else if (selectedCategory == 'YouTube Videos') {
        final result = await _apiService.getYouTubeTrending(maxResults: 20);
        if (result.isSuccess && result.data != null) {
          content = result.data!;
        }
      } else if (selectedCategory == 'Movies') {
        final result = await _apiService.getTMDBPopular(type: 'movie');
        if (result.isSuccess && result.data != null) {
          content = result.data!;
        }
      } else if (selectedCategory == 'Songs') {
        final result = await _apiService.searchSpotifyContent(query: 'popular', limit: 20);
        if (result.isSuccess && result.data != null) {
          content = result.data!;
        }
      }

      if (!mounted) return;
      setState(() {
        _categoryContent = content;
        _isLoadingCategory = false;
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



  void _showAllTrendingContent() {
    if (_trendingContent.isEmpty) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2128),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text(
                  'All Trending Content',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_trendingContent.length} items',
                    style: const TextStyle(
                      color: Color(0xFF667eea),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _trendingContent.length,
                itemBuilder: (context, index) {
                  return _buildGridCard(_trendingContent[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard(ContentItem item) {
    final colors = _getGradientColors(item);
    
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _openContent(item);
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[700]!.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Stack(
                  children: [
                    if (item.thumbnailUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Image.network(
                          item.thumbnailUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                color: colors[0],
                                strokeWidth: 2,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                _getPlatformIcon(item.platform),
                                size: 32,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      )
                    else
                      Center(
                        child: Icon(
                          _getPlatformIcon(item.platform),
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.platform.name.toUpperCase(),
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
                    Text(
                      item.channelName ?? item.artistName ?? '',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  void _openContent(ContentItem item) {
    showDialog(
      context: context,
      builder: (context) => MediaPlayer(content: item),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
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
                GestureDetector(
                  onTap: _showAllTrendingContent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667eea).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'See All',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            SizedBox(
              height: 380,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Loading trending content...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_error != null)
            Container(
              height: 380,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2128),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Oops! Something went wrong',
                      style: TextStyle(
                        color: Colors.red[400],
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(color: Colors.grey[400]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadTrendingContent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  height: 380,
                  child: _trendingContent.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.trending_up_rounded,
                                size: 64,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No trending content available',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : AnimatedBuilder(
                          animation: _heroAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 0.9 + (_heroAnimation.value * 0.1),
                              child: PageView.builder(
                                controller: _pageController,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentPage = index;
                                  });
                                },
                                itemCount: _trendingContent.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 12),
                                    child: _buildNetflixStyleTrendingCard(_trendingContent[index]),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
                if (_trendingContent.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _trendingContent.length.clamp(0, 8), // Limit to 8 dots
                      (index) => GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 32 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: _currentPage == index
                                ? const LinearGradient(
                                    colors: [Color(0xFFFF4444), Color(0xFFFF6B6B)],
                                  )
                                : null,
                            color: _currentPage == index ? null : Colors.grey[600],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNetflixStyleTrendingCard(ContentItem item) {
    final colors = _getGradientColors(item);
    
    return GestureDetector(
      onTap: () => _openContent(item),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Background Image/Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors[0],
                      colors[1],
                      colors[0].withOpacity(0.8),
                    ],
                  ),
                ),
              ),
              
              // Thumbnail if available
              if (item.thumbnailUrl.isNotEmpty)
                Positioned.fill(
                  child: Image.network(
                    item.thumbnailUrl,
                    fit: BoxFit.cover,
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
                      return Container(); // Show gradient background
                    },
                  ),
                ),
              
              // Dark overlay for better text readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
              
              // Content overlay
              Positioned(
                left: 24,
                right: 24,
                top: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors[0].withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getPlatformIcon(item.platform),
                            size: 14,
                            color: colors[0],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.platform.name.toUpperCase(),
                            style: TextStyle(
                              color: colors[0],
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bottom content
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Icon(
                        _getPlatformIcon(item.platform),
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 4,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (item.channelName != null || item.artistName != null)
                      Text(
                        'By ${item.channelName ?? item.artistName}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          shadows: const [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 2,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.black87,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Play Now',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
                          '${items.length}',
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
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2128),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${items.length} items',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return _buildGridCard(items[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
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
                      child: Image.network(
                        item.thumbnailUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              color: colors[0],
                              strokeWidth: 2,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              _getPlatformIcon(item.platform),
                              size: 48,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          );
                        },
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
                      item.channelName ?? item.artistName ?? item.description,
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
}