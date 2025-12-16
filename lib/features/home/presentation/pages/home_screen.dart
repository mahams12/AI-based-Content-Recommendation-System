import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/user_profile_service.dart';
import '../../../../core/models/content_model.dart';
import '../../../../core/widgets/media_player.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../welcome/presentation/pages/simple_voice_welcome_screen.dart';
import '../../../chat/presentation/pages/chat_screen.dart';
import '../../../recommendations/presentation/pages/mood_based_recommendations_screen.dart';
import '../../../youtube/presentation/pages/youtube_recommendations_screen.dart';
import '../../../music/presentation/pages/music_recommendations_screen.dart';
import '../../../movies/presentation/pages/movies_recommendations_screen.dart';


// Main Home Screen
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  final UserProfileService _profileService = UserProfileService();
  String? _userName;
  String? _userPhoto;
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
    _loadUserProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload profile when screen becomes visible again
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      print('📥 Loading user profile for home screen...');
      final profile = await _profileService.getUserProfile();
      print('✅ Profile loaded: name=${profile['name']}, photoUrl=${profile['photoUrl']}');
      
      if (mounted) {
        setState(() {
          _userName = profile['name'];
          // Only set photo if it's not null and not empty
          final photoUrl = profile['photoUrl'];
          _userPhoto = (photoUrl != null && photoUrl.toString().trim().isNotEmpty) 
              ? photoUrl.toString() 
              : null;
        });
        print('✅ Home screen profile updated');
      }
    } catch (e) {
      print('❌ Error loading profile for home: $e');
    }
  }

  Widget _buildProfilePicture() {
    if (_userPhoto == null || _userPhoto!.isEmpty) {
      return const Icon(Icons.person, size: 20, color: Colors.white);
    }

    final photo = _userPhoto!.trim();
    
    if (photo.startsWith('http://') || photo.startsWith('https://')) {
      return ClipOval(
        child: SafeNetworkImage(
          imageUrl: photo,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          platform: ContentType.spotify,
        ),
      );
    } else if (photo.startsWith('/') || photo.startsWith('file://')) {
      final filePath = photo.replaceFirst('file://', '');
      try {
        final file = File(filePath);
        if (file.existsSync()) {
          return ClipOval(
            child: Image.file(
              file,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.person, size: 20, color: Colors.white);
              },
            ),
          );
        } else {
          return const Icon(Icons.person, size: 20, color: Colors.white);
        }
      } catch (e) {
        print('❌ Error loading file image: $e');
        return const Icon(Icons.person, size: 20, color: Colors.white);
      }
    } else {
      return const Icon(Icons.person, size: 20, color: Colors.white);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }




  // Load trending content for the trending section (top 3 cards)
  Future<void> _loadTrendingContent() async {
    if (!mounted) return;
    
    try {
      // Fetch maximum trending content
      final result = await _apiService.getTrendingContent(maxResultsPerPlatform: 20);
      if (!mounted) return;
      
      if (result.isSuccess && result.data != null) {
        setState(() {
          _trendingContent = result.data!;
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
        // Use getAllContent for general browsing (not just trending) - fetch maximum
        final result = await _apiService.getAllContent(maxResults: 200);
        if (result.isSuccess && result.data != null) {
          content = result.data!;
        }
      } else if (selectedCategory == 'YouTube Videos') {
        // Get diverse YouTube content (not just trending) - fetch maximum
        final result = await _apiService.getAllContent(platform: ContentType.youtube, maxResults: 200);
        if (result.isSuccess && result.data != null) {
          content = result.data!;
        }
      } else if (selectedCategory == 'Movies') {
        // Get popular movies and TV shows (not just trending) - fetch maximum
        final result = await _apiService.getAllContent(platform: ContentType.tmdb, maxResults: 200);
        if (result.isSuccess && result.data != null) {
          content = result.data!;
        }
      } else if (selectedCategory == 'Songs') {
        // Get diverse Spotify content (not just trending) - fetch maximum
        final result = await _apiService.getAllContent(platform: ContentType.spotify, maxResults: 200);
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





  void _openContent(ContentItem item) {
    try {
      print('🎬 Opening content: ${item.title} (${item.platform.name})');
      print('🔗 External URL: ${item.externalUrl}');
      print('🆔 Content ID: ${item.id}');
      
      if (!mounted) {
        print('⚠️ Context not mounted, cannot show dialog');
        return;
      }
      
      showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        builder: (BuildContext dialogContext) {
          return MediaPlayer(content: item);
        },
      ).catchError((error) {
        print('❌ Error showing dialog: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error opening content: $error'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    } catch (e, stackTrace) {
      print('❌ Error in _openContent: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening content: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
                  SliverToBoxAdapter(child: _buildExperienceChoiceSection()),
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
                Row(
                  children: [
                    if (_userPhoto != null && _userPhoto!.isNotEmpty && _userPhoto!.trim().isNotEmpty) ...[
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        child: _buildProfilePicture(),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        _userName ?? 'Content Nation',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
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
          // Three trending categories in a row - only show if they have content
          Builder(
            builder: (context) {
              final youtubeItems = _trendingContent.where((item) => item.platform == ContentType.youtube).toList();
              final movieItems = _trendingContent.where((item) => item.platform == ContentType.tmdb).toList();
              final songItems = _trendingContent.where((item) => item.platform == ContentType.spotify).toList();
              
              final categories = <Widget>[];
              
              if (youtubeItems.isNotEmpty) {
                categories.add(
                  Expanded(
                    child: _buildTrendingCategory(
                      'YouTube',
                      Icons.play_arrow_rounded,
                      const Color(0xFFFF4444),
                      youtubeItems,
                    ),
                  ),
                );
                if (movieItems.isNotEmpty || songItems.isNotEmpty) {
                  categories.add(const SizedBox(width: 12));
                }
              }
              
              if (movieItems.isNotEmpty) {
                categories.add(
                  Expanded(
                    child: _buildTrendingCategory(
                      'Movies',
                      Icons.movie_rounded,
                      const Color(0xFF667eea),
                      movieItems,
                    ),
                  ),
                );
                if (songItems.isNotEmpty) {
                  categories.add(const SizedBox(width: 12));
                }
              }
              
              if (songItems.isNotEmpty) {
                categories.add(
                  Expanded(
                    child: _buildTrendingCategory(
                      'Songs',
                      Icons.music_note_rounded,
                      const Color(0xFF1DB954),
                      songItems,
                    ),
                  ),
                );
              }
              
              // If no categories have content, show a message
              if (categories.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Loading trending content...',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }
              
              return Row(children: categories);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingCategory(String title, IconData icon, Color color, List<ContentItem> items) {
    ContentType platform;
    final titleLower = title.toLowerCase();
    if (titleLower.contains('youtube') || titleLower.contains('video')) {
      platform = ContentType.youtube;
    } else if (titleLower.contains('movie') || titleLower.contains('tv')) {
      platform = ContentType.tmdb;
    } else if (titleLower.contains('song') || titleLower.contains('music')) {
      platform = ContentType.spotify;
    } else {
      platform = ContentType.youtube;
    }

    return GestureDetector(
      onTap: () {
        // Open dedicated simple trending screens without extra filters/search
        if (platform == ContentType.youtube) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const YouTubeRecommendationsScreen(),
            ),
          );
        } else if (platform == ContentType.tmdb) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const MoviesRecommendationsScreen(),
            ),
          );
        } else if (platform == ContentType.spotify) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const MusicRecommendationsScreen(),
            ),
          );
        }
      },
      child: Container(
        // Slightly taller cards to avoid any bottom overflow on small screens
        constraints: const BoxConstraints(
          minHeight: 300,
          maxHeight: 320,
        ),
        padding: const EdgeInsets.all(18),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.4),
                        color.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Content area with proper constraints
            Flexible(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
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
                  : SizedBox(
                      // Slightly taller to prevent bottom overflow of the
                      // thumbnail + title column on smaller screens.
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: items.take(3).length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 10),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  height: 100,
                                  width: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: _getGradientColors(item),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      if (item.thumbnailUrl.isNotEmpty)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: SafeNetworkImage(
                                            imageUrl: item.thumbnailUrl,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            borderRadius: BorderRadius.circular(16),
                                            platform: item.platform,
                                          ),
                                        )
                                      else
                                        Center(
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              icon,
                                              size: 44,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 28,
                                  width: 100,
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      height: 1.0,
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
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Colors.white.withOpacity(0.2) 
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(categories[index]),
                      size: 22,
                      color: isSelected ? Colors.white : Colors.grey[400],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    categories[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[400],
                      fontSize: 16,
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667eea).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.viewCount != null) ...[
                            Flexible(
                              child: Container(
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
                                    Flexible(
                                      child: Text(
                                        _formatNumber(item.viewCount!),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 36,
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 16,
                      child: Text(
                        item.platform == ContentType.tmdb 
                          ? _getTMDBSubtitle(item)
                          : (item.channelName ?? item.artistName ?? item.description),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: colors),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: colors),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 11,
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

  // Build Experience Choice Section
  Widget _buildExperienceChoiceSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppTheme.primaryGradient,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Choose Your Experience',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Chat Interface Card
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ChatScreen(),
                    ),
                  );
                },
                onTapDown: (_) {
                  // Visual feedback handled by Material
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppTheme.primaryGradient,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chat Interface',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Type or select responses to questions',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Voice Interface Card
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SimpleVoiceWelcomeScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.mic_rounded,
                          color: AppTheme.accentColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Voice Interface',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Speak your responses naturally',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withOpacity(0.7),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Mood-Based Recommendations Card
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MoodBasedRecommendationsScreen(),
                    ),
                  );
                },
                splashColor: const Color(0xFF8B5CF6).withOpacity(0.3),
                highlightColor: const Color(0xFF8B5CF6).withOpacity(0.1),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.mood_rounded,
                          color: Color(0xFF8B5CF6),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mood-Based Recommendations',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Get content based on your mood',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withOpacity(0.7),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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

}