import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/content_model.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/storage_service.dart';

// Trending content provider
final trendingContentProvider = StateNotifierProvider<TrendingContentNotifier, AsyncValue<List<ContentItem>>>((ref) {
  return TrendingContentNotifier();
});

// Search content provider
final searchContentProvider = StateNotifierProvider<SearchContentNotifier, AsyncValue<List<ContentItem>>>((ref) {
  return SearchContentNotifier();
});

// Recommendations provider
final recommendationsProvider = StateNotifierProvider<RecommendationsNotifier, AsyncValue<List<ContentItem>>>((ref) {
  return RecommendationsNotifier();
});

class TrendingContentNotifier extends StateNotifier<AsyncValue<List<ContentItem>>> {
  TrendingContentNotifier() : super(const AsyncValue.loading()) {
    loadTrendingContent();
  }

  List<ContentItem> _allContent = [];
  String _currentMood = 'all';
  List<ContentType> _currentPlatforms = ContentType.values;

  Future<void> loadTrendingContent() async {
    state = const AsyncValue.loading();

    try {
      // Check cache first
      final cachedContent = StorageService.getCachedContent('trending');
      if (cachedContent != null && cachedContent.isNotEmpty) {
        _allContent = cachedContent;
        state = AsyncValue.data(_applyFilters(_allContent));
      }

      // Fetch fresh content
      final apiService = ApiService();
      final result = await apiService.getTrendingContent(maxResultsPerPlatform: 10);

      if (result.isSuccess && result.data != null) {
        _allContent = result.data!;
        
        // Cache the content
        await StorageService.cacheContent('trending', _allContent);
        
        // Apply current filters
        state = AsyncValue.data(_applyFilters(_allContent));
      } else {
        if (state is AsyncLoading) {
          state = AsyncValue.error(result.error ?? 'Failed to load trending content', StackTrace.current);
        }
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void filterByMood(String mood) {
    _currentMood = mood;
    if (_allContent.isNotEmpty) {
      state = AsyncValue.data(_applyFilters(_allContent));
    }
  }

  void filterByPlatforms(List<ContentType> platforms) {
    _currentPlatforms = platforms;
    if (_allContent.isNotEmpty) {
      state = AsyncValue.data(_applyFilters(_allContent));
    }
  }

  List<ContentItem> _applyFilters(List<ContentItem> content) {
    var filteredContent = content;

    // Filter by platforms
    if (_currentPlatforms.length < ContentType.values.length) {
      filteredContent = filteredContent
          .where((item) => _currentPlatforms.contains(item.platform))
          .toList();
    }

    // Filter by mood (simplified implementation)
    if (_currentMood != 'all') {
      filteredContent = _filterByMood(filteredContent, _currentMood);
    }

    return filteredContent;
  }

  List<ContentItem> _filterByMood(List<ContentItem> content, String mood) {
    // This is a simplified mood filtering implementation
    // In a real app, this would use ML models and user behavior analysis
    
    switch (mood) {
      case 'energetic':
        return content.where((item) => 
          item.genres.any((genre) => 
            ['Action', 'Dance', 'Electronic', 'Rock', 'Pop'].contains(genre)
          )
        ).toList();
      
      case 'relaxed':
        return content.where((item) => 
          item.genres.any((genre) => 
            ['Ambient', 'Classical', 'Jazz', 'Acoustic', 'Meditation'].contains(genre)
          )
        ).toList();
      
      case 'happy':
        return content.where((item) => 
          item.genres.any((genre) => 
            ['Comedy', 'Pop', 'Dance', 'Family', 'Romance'].contains(genre)
          )
        ).toList();
      
      case 'sad':
        return content.where((item) => 
          item.genres.any((genre) => 
            ['Drama', 'Blues', 'Indie', 'Alternative'].contains(genre)
          )
        ).toList();
      
      case 'focused':
        return content.where((item) => 
          item.genres.any((genre) => 
            ['Documentary', 'Educational', 'Classical', 'Instrumental'].contains(genre)
          )
        ).toList();
      
      case 'romantic':
        return content.where((item) => 
          item.genres.any((genre) => 
            ['Romance', 'R&B', 'Soul', 'Pop'].contains(genre)
          )
        ).toList();
      
      case 'adventurous':
        return content.where((item) => 
          item.genres.any((genre) => 
            ['Adventure', 'Action', 'Thriller', 'Sci-Fi'].contains(genre)
          )
        ).toList();
      
      case 'nostalgic':
        return content.where((item) => 
          item.genres.any((genre) => 
            ['Classic', 'Retro', 'Vintage', 'Oldies'].contains(genre)
          )
        ).toList();
      
      default:
        return content;
    }
  }

  void refresh() {
    loadTrendingContent();
  }
}

class SearchContentNotifier extends StateNotifier<AsyncValue<List<ContentItem>>> {
  SearchContentNotifier() : super(const AsyncValue.data([]));

  Future<void> searchContent(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();

    try {
      // Check cache first
      final cacheKey = 'search_${query.toLowerCase()}';
      final cachedContent = StorageService.getCachedContent(cacheKey);
      if (cachedContent != null && cachedContent.isNotEmpty) {
        state = AsyncValue.data(cachedContent);
      }

      // Fetch fresh content
      final apiService = ApiService();
      final result = await apiService.searchAllPlatforms(query: query);

      if (result.isSuccess && result.data != null) {
        // Cache the search results
        await StorageService.cacheContent(cacheKey, result.data!);
        
        state = AsyncValue.data(result.data!);
      } else {
        state = AsyncValue.error(result.error ?? 'Search failed', StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void clearSearch() {
    state = const AsyncValue.data([]);
  }
}

class RecommendationsNotifier extends StateNotifier<AsyncValue<List<ContentItem>>> {
  RecommendationsNotifier() : super(const AsyncValue.data([]));

  Future<void> loadRecommendations() async {
    state = const AsyncValue.loading();

    try {
      // Get user interactions for personalized recommendations
      final interactions = StorageService.getUserInteractions();
      final userPreferences = StorageService.getUserPreferences();
      final currentMood = StorageService.getCurrentMood();

      // This is a simplified recommendation algorithm
      // In a real app, this would use ML models and collaborative filtering
      final recommendations = await _generateRecommendations(
        interactions,
        userPreferences,
        currentMood,
      );

      state = AsyncValue.data(recommendations);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<List<ContentItem>> _generateRecommendations(
    List<Map<String, dynamic>> interactions,
    Map<String, dynamic>? preferences,
    String? mood,
  ) async {
    // Simplified recommendation logic
    // In a real implementation, this would use ML models
    
    final apiService = ApiService();
    final result = await apiService.getTrendingContent(maxResultsPerPlatform: 15);
    
    if (result.isSuccess && result.data != null) {
      var recommendations = result.data!;
      
      // Apply user preferences
      if (preferences != null) {
        final preferredGenres = preferences['genres'] as List<String>? ?? [];
        if (preferredGenres.isNotEmpty) {
          recommendations = recommendations.where((item) =>
            item.genres.any((genre) => preferredGenres.contains(genre))
          ).toList();
        }
      }
      
      // Apply mood filtering
      if (mood != null && mood != 'all') {
        recommendations = _filterByMood(recommendations, mood);
      }
      
      // Sort by rating and popularity
      recommendations.sort((a, b) {
        final aScore = (a.rating ?? 0) + (a.viewCount ?? 0) / 1000000.0;
        final bScore = (b.rating ?? 0) + (b.viewCount ?? 0) / 1000000.0;
        return bScore.compareTo(aScore);
      });
      
      return recommendations.take(20).toList();
    }
    
    return [];
  }

  List<ContentItem> _filterByMood(List<ContentItem> content, String mood) {
    // Same mood filtering logic as in TrendingContentNotifier
    switch (mood) {
      case 'energetic':
        return content.where((item) => 
          item.genres.any((genre) => 
            ['Action', 'Dance', 'Electronic', 'Rock', 'Pop'].contains(genre)
          )
        ).toList();
      
      case 'relaxed':
        return content.where((item) => 
          item.genres.any((genre) => 
            ['Ambient', 'Classical', 'Jazz', 'Acoustic', 'Meditation'].contains(genre)
          )
        ).toList();
      
      case 'happy':
        return content.where((item) => 
          item.genres.any((genre) => 
            ['Comedy', 'Pop', 'Dance', 'Family', 'Romance'].contains(genre)
          )
        ).toList();
      
      case 'sad':
        return content.where((item) => 
          item.genres.any((genre) => 
            ['Drama', 'Blues', 'Indie', 'Alternative'].contains(genre)
          )
        ).toList();
      
      case 'focused':
        return content.where((item) => 
          item.genres.any((genre) => 
            ['Documentary', 'Educational', 'Classical', 'Instrumental'].contains(genre)
          )
        ).toList();
      
      case 'romantic':
        return content.where((item) => 
          item.genres.any((genre) => 
            ['Romance', 'R&B', 'Soul', 'Pop'].contains(genre)
          )
        ).toList();
      
      case 'adventurous':
        return content.where((item) => 
          item.genres.any((genre) => 
            ['Adventure', 'Action', 'Thriller', 'Sci-Fi'].contains(genre)
          )
        ).toList();
      
      case 'nostalgic':
        return content.where((item) => 
          item.genres.any((genre) => 
            ['Classic', 'Retro', 'Vintage', 'Oldies'].contains(genre)
          )
        ).toList();
      
      default:
        return content;
    }
  }
}

