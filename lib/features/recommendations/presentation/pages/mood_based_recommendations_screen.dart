import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/content_model.dart';
import '../../../../core/widgets/media_player.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/mood_based_filtering_service.dart';
import '../../../home/presentation/widgets/mood_selector.dart';

class MoodBasedRecommendationsScreen extends ConsumerStatefulWidget {
  const MoodBasedRecommendationsScreen({super.key});

  @override
  ConsumerState<MoodBasedRecommendationsScreen> createState() => _MoodBasedRecommendationsScreenState();
}

class _MoodBasedRecommendationsScreenState extends ConsumerState<MoodBasedRecommendationsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _selectedMood = 'all';
  String _selectedCategory = 'all';
  bool _isGeneratingPlaylist = false;
  List<ContentItem> _moodPlaylist = [];
  final ApiService _apiService = ApiService();
  final MoodBasedFilteringService _moodFilterService = MoodBasedFilteringService();

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
    
    // Initialize mood-based recommendations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Mood-based recommendations are now handled locally
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _onMoodChanged(String mood) async {
    setState(() {
      _selectedMood = mood;
    });

    // Mood-based recommendations are now handled locally
    // No need for external provider calls
  }

  Future<void> _generateMoodPlaylist() async {
    if (_selectedMood == 'all') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a specific mood to generate a playlist',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isGeneratingPlaylist = true;
    });

    try {
      // Generate mood-based playlist locally
      final playlist = await _generateLocalMoodPlaylist(_selectedMood);
      
      setState(() {
        _moodPlaylist = playlist;
        _isGeneratingPlaylist = false;
      });

      if (playlist.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Generated ${playlist.length} items for your $_selectedMood mood!',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            backgroundColor: const Color(0xFF667eea),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGeneratingPlaylist = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to generate playlist: $e',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.red,
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
    // Refresh playlist after closing media player
    if (_moodPlaylist.isNotEmpty) {
      _refreshPlaylist();
    }
  }

  Future<void> _refreshPlaylist() async {
    if (_selectedMood != 'all') {
      await _generateMoodPlaylist();
    }
  }

  String _getMoodDescription(String mood) {
    switch (mood) {
      case 'happy':
        return 'Upbeat and cheerful content to lift your spirits';
      case 'sad':
        return 'Emotional and comforting content for reflection';
      case 'energetic':
        return 'High-energy content to get you moving';
      case 'relaxed':
        return 'Calm and peaceful content for unwinding';
      case 'romantic':
        return 'Intimate and loving content for special moments';
      case 'adventurous':
        return 'Exciting and thrilling content for exploration';
      case 'focused':
        return 'Concentrated content for productivity and learning';
      case 'nostalgic':
        return 'Classic and timeless content for reminiscing';
      case 'angry':
        return 'Intense and powerful content for release';
      case 'calm':
        return 'Serene and peaceful content for tranquility';
      default:
        return 'Personalized content recommendations';
    }
  }

  List<Color> _getMoodColors(String mood) {
    switch (mood) {
      case 'happy':
        return [const Color(0xFFFFD700), const Color(0xFFFFA500)];
      case 'sad':
        return [const Color(0xFF4169E1), const Color(0xFF6495ED)];
      case 'energetic':
        return [const Color(0xFFFF4444), const Color(0xFFFF6B6B)];
      case 'relaxed':
        return [const Color(0xFF32CD32), const Color(0xFF90EE90)];
      case 'romantic':
        return [const Color(0xFFFF69B4), const Color(0xFFFFB6C1)];
      case 'adventurous':
        return [const Color(0xFF8A2BE2), const Color(0xFF9370DB)];
      case 'focused':
        return [const Color(0xFF2E8B57), const Color(0xFF3CB371)];
      case 'nostalgic':
        return [const Color(0xFFCD853F), const Color(0xFFD2B48C)];
      case 'angry':
        return [const Color(0xFFDC143C), const Color(0xFFFF6347)];
      case 'calm':
        return [const Color(0xFF20B2AA), const Color(0xFF40E0D0)];
      default:
        return [const Color(0xFF667eea), const Color(0xFF764ba2)];
    }
  }

  Future<List<ContentItem>> _generateLocalMoodPlaylist(String mood) async {
    print('🎵 Generating mood playlist for: $mood, category: $_selectedCategory');
    List<ContentItem> allContent = [];
    
    try {
      // Fetch content based on selected category
      // Use the \"unlimited\" APIs so we have a large pool and can
      // build playlists of 20–30+ items without repeating.
      if (_selectedCategory == 'all') {
        print('📺 Fetching extended YouTube content...');
        final youtubeResult =
            await _apiService.getUnlimitedYouTubeContent(maxResults: 60);
        if (youtubeResult.isSuccess && youtubeResult.data != null) {
          allContent.addAll(youtubeResult.data!);
          print('✅ Fetched ${youtubeResult.data!.length} YouTube videos');
        } else {
          print('⚠️ YouTube fetch failed: ${youtubeResult.error}');
        }
        
        print('🎵 Fetching extended Spotify content...');
        final spotifyResult =
            await _apiService.getUnlimitedSpotifyContent(maxResults: 60);
        if (spotifyResult.isSuccess && spotifyResult.data != null) {
          allContent.addAll(spotifyResult.data!);
          print('✅ Fetched ${spotifyResult.data!.length} Spotify items');
        } else {
          print('⚠️ Spotify fetch failed: ${spotifyResult.error}');
        }
        
        print('🎬 Fetching extended TMDB content...');
        final tmdbResult =
            await _apiService.getUnlimitedTMDBContent(maxResults: 60);
        if (tmdbResult.isSuccess && tmdbResult.data != null) {
          allContent.addAll(tmdbResult.data!);
          print('✅ Fetched ${tmdbResult.data!.length} TMDB items');
        } else {
          print('⚠️ TMDB fetch failed: ${tmdbResult.error}');
        }
      } else if (_selectedCategory == 'youtube') {
        print('📺 Fetching extended YouTube content...');
        final youtubeResult =
            await _apiService.getUnlimitedYouTubeContent(maxResults: 60);
        if (youtubeResult.isSuccess && youtubeResult.data != null) {
          allContent.addAll(youtubeResult.data!);
          print('✅ Fetched ${youtubeResult.data!.length} YouTube videos');
        } else {
          print('⚠️ YouTube fetch failed: ${youtubeResult.error}');
        }
      } else if (_selectedCategory == 'music') {
        print('🎵 Fetching extended Spotify content...');
        final spotifyResult =
            await _apiService.getUnlimitedSpotifyContent(maxResults: 60);
        if (spotifyResult.isSuccess && spotifyResult.data != null) {
          allContent.addAll(spotifyResult.data!);
          print('✅ Fetched ${spotifyResult.data!.length} Spotify items');
        } else {
          print('⚠️ Spotify fetch failed: ${spotifyResult.error}');
        }
      } else if (_selectedCategory == 'movies') {
        print('🎬 Fetching extended TMDB content...');
        final tmdbResult =
            await _apiService.getUnlimitedTMDBContent(maxResults: 60);
        if (tmdbResult.isSuccess && tmdbResult.data != null) {
          allContent.addAll(tmdbResult.data!);
          print('✅ Fetched ${tmdbResult.data!.length} TMDB items');
        } else {
          print('⚠️ TMDB fetch failed: ${tmdbResult.error}');
        }
      }
      
      print('📊 Total content fetched: ${allContent.length}');
      
      // Shuffle content for variety before filtering
      allContent.shuffle();
      
      // Filter by mood using MoodBasedFilteringService
      List<ContentItem> filteredContent;
      if (mood == 'all' || mood == 'neutral') {
        // For \"all\" mood, just take a larger slice from each platform (shuffled).
        if (_selectedCategory == 'all') {
          final youtubeItems = allContent
              .where((item) => item.platform == ContentType.youtube)
              .take(10)
              .toList();
          final spotifyItems = allContent
              .where((item) => item.platform == ContentType.spotify)
              .take(10)
              .toList();
          final tmdbItems = allContent
              .where((item) => item.platform == ContentType.tmdb)
              .take(10)
              .toList();
          filteredContent = [...youtubeItems, ...spotifyItems, ...tmdbItems];
          filteredContent.shuffle(); // Shuffle final result
        } else {
          // For specific category, return 20–30 items (shuffled)
          filteredContent = allContent.take(30).toList();
          filteredContent.shuffle();
        }
      } else {
        // Use mood-based filtering service for a larger playlist
        print('🎯 Filtering content by mood: $mood');
        filteredContent = await _moodFilterService.filterContentByMood(
          content: allContent,
          mood: mood,
          maxResults: 30,
        );
        print('✅ Filtered to ${filteredContent.length} items for mood: $mood');
        
        // Log sample items for debugging
        if (filteredContent.isNotEmpty) {
          print('📋 Sample filtered items:');
          for (int i = 0; i < min(3, filteredContent.length); i++) {
            final item = filteredContent[i];
            print('   ${i + 1}. ${item.title} (${item.platform.name}) - Genres: ${item.genres.join(", ")}');
          }
        }
      }
      
      // Ensure we have at least some content (fallback)
      if (filteredContent.isEmpty && allContent.isNotEmpty) {
        print('⚠️ Mood filtering returned empty, using shuffled top items');
        filteredContent = allContent.take(30).toList();
        filteredContent.shuffle();
      }
      
      print('🎉 Final playlist size: ${filteredContent.length}');
      return filteredContent;
    } catch (e) {
      print('❌ Error generating mood playlist: $e');
      // Return empty list on error
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildAppBar()),
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildMoodSelector(),
                ),
              ),
              SliverToBoxAdapter(child: _buildMoodDescription()),
              SliverToBoxAdapter(child: _buildCategorySelector()),
              SliverToBoxAdapter(child: _buildPlaylistSection()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1C2128), Color(0xFF2A2D3A)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.grey[700]!.withOpacity(0.3),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white70,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mood-Based Recommendations',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI-powered content for your mood',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: MoodSelector(
        selectedMood: _selectedMood,
        onMoodChanged: _onMoodChanged,
        showAIDetection: true,
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = [
      {'id': 'all', 'name': 'All', 'icon': Icons.all_inclusive_rounded},
      {'id': 'youtube', 'name': 'YouTube Videos', 'icon': Icons.play_arrow_rounded},
      {'id': 'music', 'name': 'Songs', 'icon': Icons.music_note_rounded},
      {'id': 'movies', 'name': 'Movies', 'icon': Icons.movie_rounded},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Content Category',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((category) {
                final isSelected = _selectedCategory == category['id'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category['id'] as String;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            )
                          : null,
                      color: isSelected ? null : const Color(0xFF1C2128),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected 
                            ? Colors.transparent 
                            : Colors.grey[700]!.withOpacity(0.3),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF667eea).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category['icon'] as IconData,
                          size: 16,
                          color: isSelected ? Colors.white : Colors.grey[400],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category['name'] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[400],
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodDescription() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getMoodColors(_selectedMood),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getMoodColors(_selectedMood)[0].withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              _getMoodIcon(_selectedMood),
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getMoodDisplayName(_selectedMood),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getMoodDescription(_selectedMood),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mood Playlist',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_selectedCategory != 'all')
                      Text(
                        '${_getCategoryDisplayName(_selectedCategory)} Content',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _isGeneratingPlaylist ? null : _generateMoodPlaylist,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isGeneratingPlaylist)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(
                          Icons.playlist_add_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _isGeneratingPlaylist ? 'Generating...' : 'Generate',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_moodPlaylist.isEmpty)
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF1C2128),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey[700]!.withOpacity(0.3),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.playlist_play_rounded,
                      size: 32,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Generate a playlist for your mood',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _moodPlaylist.length,
                itemBuilder: (context, index) {
                  return _buildPlaylistItem(_moodPlaylist[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaylistItem(ContentItem item) {
    return GestureDetector(
      onTap: () => _openContent(item),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C2128),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[700]!.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: SafeNetworkImage(
                  imageUrl: item.thumbnailUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  platform: item.platform,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }


  // Helper methods
  String _getMoodDisplayName(String mood) {
    switch (mood) {
      case 'energetic':
        return 'Energetic';
      case 'relaxed':
        return 'Relaxed';
      case 'sad':
        return 'Sad';
      case 'happy':
        return 'Happy';
      case 'focused':
        return 'Focused';
      case 'romantic':
        return 'Romantic';
      case 'adventurous':
        return 'Adventurous';
      case 'nostalgic':
        return 'Nostalgic';
      case 'angry':
        return 'Angry';
      case 'calm':
        return 'Calm';
      default:
        return 'All Moods';
    }
  }

  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case 'energetic':
        return Icons.bolt;
      case 'relaxed':
        return Icons.spa;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'focused':
        return Icons.center_focus_strong;
      case 'romantic':
        return Icons.favorite;
      case 'adventurous':
        return Icons.explore;
      case 'nostalgic':
        return Icons.history;
      case 'angry':
        return Icons.mood_bad;
      case 'calm':
        return Icons.self_improvement;
      default:
        return Icons.all_inclusive;
    }
  }


  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'youtube':
        return 'YouTube Videos';
      case 'music':
        return 'Songs';
      case 'movies':
        return 'Movies';
      default:
        return 'All';
    }
  }
}

