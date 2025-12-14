import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/models/content_model.dart';
import '../../../../core/widgets/media_player.dart';
import '../../../../core/widgets/safe_network_image.dart';

class YouTubeRecommendationsScreen extends StatefulWidget {
  const YouTubeRecommendationsScreen({super.key});

  @override
  State<YouTubeRecommendationsScreen> createState() => _YouTubeRecommendationsScreenState();
}

class _YouTubeRecommendationsScreenState extends State<YouTubeRecommendationsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final ApiService _apiService = ApiService();
  List<ContentItem> _youtubeContent = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _fadeController.forward();
    _loadTrendingYouTubeContent();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadTrendingYouTubeContent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load only trending YouTube content
      final result = await _apiService.getTrendingContent(maxResultsPerPlatform: 200);
      if (result.isSuccess && result.data != null) {
        setState(() {
          _youtubeContent = result.data!
              .where((item) => item.platform == ContentType.youtube)
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading trending YouTube content: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openContent(ContentItem item) {
    try {
      print('📺 Opening content: ${item.title} (${item.platform.name})');
      print('🔗 External URL: ${item.externalUrl}');
      showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        builder: (BuildContext dialogContext) => MediaPlayer(content: item),
      );
    } catch (e, stackTrace) {
      print('❌ Error showing dialog: $e');
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
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildAppBar()),
                  SliverToBoxAdapter(child: _buildContentGrid()),
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
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YouTube Videos',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Trending Videos',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.play_circle_filled,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildContentGrid() {
    if (_isLoading) {
      return Container(
        height: 400,
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
                    colors: [Color(0xFFFF0000), Color(0xFFCC0000)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading YouTube videos...',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_youtubeContent.isEmpty) {
      return Container(
        height: 400,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2128),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.video_library_outlined,
                  size: 64,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No videos found',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No trending videos available',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.65, // Reduced to prevent overflow
        ),
        itemCount: _youtubeContent.length,
        itemBuilder: (context, index) {
          final content = _youtubeContent[index];
          return _buildVideoCard(content);
        },
      ),
    );
  }

  Widget _buildVideoCard(ContentItem content) {
    return GestureDetector(
      onTap: () => _openContent(content),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C2128),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: SafeNetworkImage(
                    imageUrl: content.thumbnailUrl,
                    platform: ContentType.youtube,
                    placeholder: Container(
                      color: Colors.grey[800],
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_filled,
                          color: Colors.grey,
                          size: 48,
                        ),
                      ),
                    ),
                    errorWidget: Container(
                      color: Colors.grey[800],
                      child: const Center(
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.grey,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Content Info - Fixed height to prevent overflow
            Container(
              height: 80,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title - Fixed height
                  SizedBox(
                    height: 32,
                    child: Text(
                      content.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Channel/Artist - Fixed height
                  SizedBox(
                    height: 16,
                    child: Text(
                      content.artistName ?? 'Unknown Channel',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  
                  // Duration - Fixed at bottom
                  if (content.duration != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        content.duration!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
