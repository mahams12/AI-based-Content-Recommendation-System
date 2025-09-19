import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/trending_card.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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
      curve: Curves.easeInOut,
    ));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  _buildHeader(),
                  
                  const SizedBox(height: 32),
                  
                  // Trending Music Section
                  _buildSection(
                    title: 'Trending Music',
                    subtitle: 'What\'s hot right now',
                    items: _getTrendingMusic(),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Trending Movies Section
                  _buildSection(
                    title: 'Trending Movies',
                    subtitle: 'Blockbusters & hits',
                    items: _getTrendingMovies(),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Trending Shows Section
                  _buildSection(
                    title: 'Trending Shows',
                    subtitle: 'Binge-worthy series',
                    items: _getTrendingShows(),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Trending Podcasts Section
                  _buildSection(
                    title: 'Trending Podcasts',
                    subtitle: 'Listen to the latest',
                    items: _getTrendingPodcasts(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trending Now',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Discover what\'s popular across all platforms',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to full section
              },
              child: Text(
                'View All',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < items.length - 1 ? 16 : 0,
                ),
                child: TrendingCard(
                  title: item['title'],
                  subtitle: item['subtitle'],
                  imageUrl: item['imageUrl'],
                  icon: item['icon'],
                  category: item['category'],
                  rating: item['rating'],
                  accentColor: item['accentColor'],
                  onTap: () {
                    _showContentDetails(item);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showContentDetails(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          item['title'],
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          item['subtitle'],
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getTrendingMusic() {
    return [
      {
        'title': 'Hackney Diamonds',
        'subtitle': 'The Rolling Stones',
        'imageUrl': null,
        'icon': Icons.music_note,
        'category': 'Rock',
        'rating': 4.8,
        'accentColor': AppTheme.primaryColor,
      },
      {
        'title': 'Midnights',
        'subtitle': 'Taylor Swift',
        'imageUrl': null,
        'icon': Icons.music_note,
        'category': 'Pop',
        'rating': 4.9,
        'accentColor': AppTheme.accentColor,
      },
      {
        'title': 'Renaissance',
        'subtitle': 'Beyoncé',
        'imageUrl': null,
        'icon': Icons.music_note,
        'category': 'R&B',
        'rating': 4.7,
        'accentColor': AppTheme.secondaryColor,
      },
      {
        'title': 'Un Verano Sin Ti',
        'subtitle': 'Bad Bunny',
        'imageUrl': null,
        'icon': Icons.music_note,
        'category': 'Reggaeton',
        'rating': 4.6,
        'accentColor': AppTheme.warningColor,
      },
    ];
  }

  List<Map<String, dynamic>> _getTrendingMovies() {
    return [
      {
        'title': 'Oppenheimer',
        'subtitle': 'Christopher Nolan',
        'imageUrl': null,
        'icon': Icons.movie,
        'category': 'Drama',
        'rating': 4.9,
        'accentColor': AppTheme.primaryColor,
      },
      {
        'title': 'Barbie',
        'subtitle': 'Greta Gerwig',
        'imageUrl': null,
        'icon': Icons.movie,
        'category': 'Comedy',
        'rating': 4.7,
        'accentColor': AppTheme.accentColor,
      },
      {
        'title': 'Spider-Man: Across the Spider-Verse',
        'subtitle': 'Joaquim Dos Santos',
        'imageUrl': null,
        'icon': Icons.movie,
        'category': 'Animation',
        'rating': 4.8,
        'accentColor': AppTheme.secondaryColor,
      },
      {
        'title': 'Guardians of the Galaxy Vol. 3',
        'subtitle': 'James Gunn',
        'imageUrl': null,
        'icon': Icons.movie,
        'category': 'Action',
        'rating': 4.6,
        'accentColor': AppTheme.warningColor,
      },
    ];
  }

  List<Map<String, dynamic>> _getTrendingShows() {
    return [
      {
        'title': 'The Last of Us',
        'subtitle': 'HBO Max',
        'imageUrl': null,
        'icon': Icons.tv,
        'category': 'Drama',
        'rating': 4.9,
        'accentColor': AppTheme.primaryColor,
      },
      {
        'title': 'Wednesday',
        'subtitle': 'Netflix',
        'imageUrl': null,
        'icon': Icons.tv,
        'category': 'Comedy',
        'rating': 4.7,
        'accentColor': AppTheme.accentColor,
      },
      {
        'title': 'House of the Dragon',
        'subtitle': 'HBO Max',
        'imageUrl': null,
        'icon': Icons.tv,
        'category': 'Fantasy',
        'rating': 4.8,
        'accentColor': AppTheme.secondaryColor,
      },
      {
        'title': 'Stranger Things',
        'subtitle': 'Netflix',
        'imageUrl': null,
        'icon': Icons.tv,
        'category': 'Sci-Fi',
        'rating': 4.6,
        'accentColor': AppTheme.warningColor,
      },
    ];
  }

  List<Map<String, dynamic>> _getTrendingPodcasts() {
    return [
      {
        'title': 'The Joe Rogan Experience',
        'subtitle': 'Joe Rogan',
        'imageUrl': null,
        'icon': Icons.radio,
        'category': 'Talk',
        'rating': 4.8,
        'accentColor': AppTheme.primaryColor,
      },
      {
        'title': 'Crime Junkie',
        'subtitle': 'audiochuck',
        'imageUrl': null,
        'icon': Icons.radio,
        'category': 'True Crime',
        'rating': 4.7,
        'accentColor': AppTheme.accentColor,
      },
      {
        'title': 'The Daily',
        'subtitle': 'The New York Times',
        'imageUrl': null,
        'icon': Icons.radio,
        'category': 'News',
        'rating': 4.9,
        'accentColor': AppTheme.secondaryColor,
      },
      {
        'title': 'Stuff You Should Know',
        'subtitle': 'iHeartPodcasts',
        'imageUrl': null,
        'icon': Icons.radio,
        'category': 'Education',
        'rating': 4.6,
        'accentColor': AppTheme.warningColor,
      },
    ];
  }
}
