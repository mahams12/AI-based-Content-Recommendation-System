import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/content_model.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/recommendation_engine.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/services/mood_based_filtering_service.dart';

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
  final MoodBasedFilteringService _moodFilteringService = MoodBasedFilteringService();

  Future<void> loadTrendingContent() async {
    state = const AsyncValue.loading();

    try {
      // Check cache first
      final cachedContent = StorageService.getCachedContent('trending');
      if (cachedContent != null && cachedContent.isNotEmpty) {
        _allContent = cachedContent;
        final filteredContent = await _applyFilters(_allContent);
        state = AsyncValue.data(filteredContent);
      }

      // Fetch fresh content
      final apiService = ApiService();
      final result = await apiService.getTrendingContent(maxResultsPerPlatform: 10);

      if (result.isSuccess && result.data != null) {
        _allContent = result.data!;
        
        // Cache the content
        await StorageService.cacheContent('trending', _allContent);
        
        // Apply current filters
        final filteredContent = await _applyFilters(_allContent);
        state = AsyncValue.data(filteredContent);
      } else {
        if (state is AsyncLoading) {
          state = AsyncValue.error(result.error ?? 'Failed to load trending content', StackTrace.current);
        }
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> filterByMood(String mood) async {
    _currentMood = mood;
    if (_allContent.isNotEmpty) {
      state = const AsyncValue.loading();
      try {
        final filteredContent = await _applyFilters(_allContent);
        state = AsyncValue.data(filteredContent);
      } catch (e) {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }

  Future<void> filterByPlatforms(List<ContentType> platforms) async {
    _currentPlatforms = platforms;
    if (_allContent.isNotEmpty) {
      state = const AsyncValue.loading();
      try {
        final filteredContent = await _applyFilters(_allContent);
        state = AsyncValue.data(filteredContent);
      } catch (e) {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }

  Future<List<ContentItem>> _applyFilters(List<ContentItem> content) async {
    var filteredContent = content;

    // Filter by platforms
    if (_currentPlatforms.length < ContentType.values.length) {
      filteredContent = filteredContent
          .where((item) => _currentPlatforms.contains(item.platform))
          .toList();
    }

    // Filter by mood using AI-powered filtering
    if (_currentMood != 'all') {
      filteredContent = await _moodFilteringService.filterContentByMood(
        content: filteredContent,
        mood: _currentMood,
        maxResults: 50,
      );
    }

    return filteredContent;
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

  final RecommendationEngine _recommendationEngine = RecommendationEngine();
  final FeedbackService _feedbackService = FeedbackService();
  final MoodBasedFilteringService _moodFilteringService = MoodBasedFilteringService();
  String _currentMood = 'neutral';

  Future<void> loadRecommendations({String? mood}) async {
    state = const AsyncValue.loading();

    try {
      // Update current mood if provided
      if (mood != null) {
        _currentMood = mood;
      }

      // Get user interactions for personalized recommendations
      final interactions = await _feedbackService.getUserInteractions(
        userId: 'current_user', // In real app, get from auth
        limit: 100,
      );
      
      final userPreferences = await _feedbackService.getUserPreferences('current_user');
      final currentMood = mood ?? userPreferences['current_mood'] as String? ?? 'neutral';

      // Get available content
      final apiService = ApiService();
      final result = await apiService.getTrendingContent(maxResultsPerPlatform: 100);
      
      if (result.isSuccess && result.data != null) {
        // Convert interactions to the format expected by recommendation engine
        final formattedInteractions = interactions.map((interaction) => {
          'userId': interaction.userId,
          'contentId': interaction.contentId,
          'rating': _convertInteractionToRating(interaction),
          'content': _getContentFromInteraction(interaction),
        }).toList();

        // Generate AI-powered recommendations with mood filtering
        final recommendationResults = await _recommendationEngine.generateRecommendations(
          userId: 'current_user',
          availableContent: result.data!,
          userHistory: formattedInteractions,
          userPreferences: userPreferences,
          currentMood: currentMood,
          maxRecommendations: 30,
        );

        // Extract content items from recommendation results
        var recommendations = recommendationResults.map((result) => result.content).toList();

        // Apply additional mood-based filtering for better results
        if (currentMood != 'neutral' && currentMood != 'all') {
          final moodRecommendations = await _moodFilteringService.getMoodRecommendations(
            content: recommendations,
            mood: currentMood,
            maxResults: 20,
          );
          recommendations = moodRecommendations.map((rec) => rec.content).toList();
        }

        state = AsyncValue.data(recommendations);
      } else {
        state = AsyncValue.error(result.error ?? 'Failed to load recommendations', StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Helper methods for converting interactions
  double _convertInteractionToRating(UserInteraction interaction) {
    switch (interaction.type) {
      case InteractionType.like:
        return 5.0;
      case InteractionType.consume:
        return 4.0;
      case InteractionType.share:
        return 4.5;
      case InteractionType.save:
        return 4.0;
      case InteractionType.dislike:
        return 1.0;
      case InteractionType.skip:
        return 2.0;
      default:
        return 3.0; // Neutral
    }
  }

  ContentItem? _getContentFromInteraction(UserInteraction interaction) {
    // In a real implementation, you would fetch the content from storage or API
    // For now, return null as we'll handle this differently
    return null;
  }

  // Record user interaction with content
  Future<void> recordInteraction({
    required String contentId,
    required InteractionType type,
    Map<String, dynamic>? metadata,
  }) async {
    await _feedbackService.recordInteraction(
      userId: 'current_user',
      contentId: contentId,
      type: type,
      metadata: metadata,
    );
  }

  // Record user feedback
  Future<void> recordFeedback({
    required String contentId,
    required FeedbackType type,
    required double value,
    String? comment,
  }) async {
    await _feedbackService.recordFeedback(
      userId: 'current_user',
      contentId: contentId,
      type: type,
      value: value,
      comment: comment,
    );
  }

  // Record mood selection
  Future<void> recordMoodSelection(String mood) async {
    await _feedbackService.recordMoodSelection(
      userId: 'current_user',
      mood: mood,
    );
  }

  // Generate mood-based playlist
  Future<List<ContentItem>> generateMoodPlaylist(String mood) async {
    try {
      // Get available content
      final apiService = ApiService();
      final result = await apiService.getTrendingContent(maxResultsPerPlatform: 100);
      
      if (result.isSuccess && result.data != null) {
        return await _moodFilteringService.generateMoodPlaylist(
          availableContent: result.data!,
          mood: mood,
          playlistLength: 20,
          includeVariety: true,
        );
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get current mood
  String get currentMood => _currentMood;

  // Mood filtering logic is now handled by the AI service
  // List<ContentItem> _filterByMood(List<ContentItem> content, String mood) {
  //   // Same mood filtering logic as in TrendingContentNotifier
  //   switch (mood) {
  //     case 'energetic':
  //       return content.where((item) => 
  //         item.genres.any((genre) => 
  //           ['Action', 'Dance', 'Electronic', 'Rock', 'Pop'].contains(genre)
  //         )
  //       ).toList();
  //     
  //     case 'relaxed':
  //       return content.where((item) => 
  //         item.genres.any((genre) => 
  //           ['Ambient', 'Classical', 'Jazz', 'Acoustic', 'Meditation'].contains(genre)
  //         )
  //       ).toList();
  //     
  //     case 'happy':
  //       return content.where((item) => 
  //         item.genres.any((genre) => 
  //           ['Comedy', 'Pop', 'Dance', 'Family', 'Romance'].contains(genre)
  //         )
  //       ).toList();
  //     
  //     case 'sad':
  //       return content.where((item) => 
  //         item.genres.any((genre) => 
  //           ['Drama', 'Blues', 'Indie', 'Alternative'].contains(genre)
  //         )
  //       ).toList();
  //     
  //     case 'focused':
  //       return content.where((item) => 
  //         item.genres.any((genre) => 
  //           ['Documentary', 'Educational', 'Classical', 'Instrumental'].contains(genre)
  //         )
  //       ).toList();
  //     
  //     case 'romantic':
  //       return content.where((item) => 
  //         item.genres.any((genre) => 
  //           ['Romance', 'R&B', 'Soul', 'Pop'].contains(genre)
  //         )
  //       ).toList();
  //     
  //     case 'adventurous':
  //       return content.where((item) => 
  //         item.genres.any((genre) => 
  //           ['Adventure', 'Action', 'Thriller', 'Sci-Fi'].contains(genre)
  //         )
  //       ).toList();
  //     
  //     case 'nostalgic':
  //       return content.where((item) => 
  //         item.genres.any((genre) => 
  //           ['Classic', 'Retro', 'Vintage', 'Oldies'].contains(genre)
  //         )
  //       ).toList();
  //     
  //     default:
  //       return content;
  //   }
  // }
}



