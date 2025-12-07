import 'dart:math';
import '../models/content_model.dart';
import 'ai_service.dart';
import 'content_analysis_service.dart';

/// Advanced Recommendation Engine implementing multiple algorithms
class RecommendationEngine {
  static final RecommendationEngine _instance = RecommendationEngine._internal();
  factory RecommendationEngine() => _instance;
  RecommendationEngine._internal();

  final AIService _aiService = AIService();
  final ContentAnalysisService _contentAnalysis = ContentAnalysisService();

  // Algorithm weights for hybrid recommendations
  final Map<String, double> _algorithmWeights = {
    'content_based': 0.3,
    'collaborative': 0.25,
    'knn': 0.2,
    'svd': 0.15,
    'trending': 0.1,
  };

  /// Generate hybrid recommendations using multiple algorithms
  Future<List<RecommendationResult>> generateRecommendations({
    required String userId,
    required List<ContentItem> availableContent,
    List<Map<String, dynamic>>? userHistory,
    Map<String, dynamic>? userPreferences,
    String? currentMood,
    int maxRecommendations = 20,
  }) async {
    final recommendations = <String, RecommendationResult>{};

    // Get user history and preferences
    final history = userHistory ?? [];
    // final preferences = userPreferences ?? {};
    final mood = currentMood ?? 'neutral';

    // 1. Content-Based Filtering
    final cbfRecommendations = await _generateContentBasedRecommendations(
      history,
      availableContent,
      maxRecommendations,
    );

    // 2. Collaborative Filtering
    final cfRecommendations = await _generateCollaborativeRecommendations(
      userId,
      history,
      availableContent,
      maxRecommendations,
    );

    // 3. K-Nearest Neighbors
    final knnRecommendations = await _generateKNNRecommendations(
      history,
      availableContent,
      maxRecommendations,
    );

    // 4. Singular Value Decomposition
    final svdRecommendations = await _generateSVDRecommendations(
      userId,
      history,
      availableContent,
      maxRecommendations,
    );

    // 5. Trending Content
    final trendingRecommendations = await _generateTrendingRecommendations(
      availableContent,
      maxRecommendations,
    );

    // Combine recommendations using weighted scoring
    _combineRecommendations(recommendations, cbfRecommendations, 'content_based');
    _combineRecommendations(recommendations, cfRecommendations, 'collaborative');
    _combineRecommendations(recommendations, knnRecommendations, 'knn');
    _combineRecommendations(recommendations, svdRecommendations, 'svd');
    _combineRecommendations(recommendations, trendingRecommendations, 'trending');

    // Apply mood-based filtering
    final moodFilteredRecommendations = _applyMoodFiltering(
      recommendations.values.toList(),
      mood,
    );

    // Apply diversity filtering to avoid too similar content
    final diverseRecommendations = _applyDiversityFiltering(
      moodFilteredRecommendations,
      maxRecommendations,
    );

    // Sort by final score
    diverseRecommendations.sort((a, b) => b.finalScore.compareTo(a.finalScore));

    return diverseRecommendations.take(maxRecommendations).toList();
  }

  /// Content-Based Filtering (CBF) Recommendations
  Future<List<RecommendationResult>> _generateContentBasedRecommendations(
    List<Map<String, dynamic>> userHistory,
    List<ContentItem> availableContent,
    int maxRecommendations,
  ) async {
    if (userHistory.isEmpty) {
      return availableContent.take(maxRecommendations).map((content) =>
          RecommendationResult(
            content: content,
            score: 0.5,
            algorithm: 'content_based',
            explanation: 'No user history available',
          )).toList();
    }

    // Extract user preferences from history
    final userProfile = _buildUserProfile(userHistory);
    
    final recommendations = <RecommendationResult>[];

    for (final content in availableContent) {
      final similarity = await _calculateContentSimilarity(userProfile, content);
      
      if (similarity > 0.1) { // Only include relevant content
        recommendations.add(RecommendationResult(
          content: content,
          score: similarity,
          algorithm: 'content_based',
          explanation: 'Similar to your preferred content',
        ));
      }
    }

    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(maxRecommendations).toList();
  }

  /// Collaborative Filtering (CF) Recommendations
  Future<List<RecommendationResult>> _generateCollaborativeRecommendations(
    String userId,
    List<Map<String, dynamic>> userHistory,
    List<ContentItem> availableContent,
    int maxRecommendations,
  ) async {
    // Build user-item matrix from history
    final userItemMatrix = _buildUserItemMatrix(userHistory);
    
    if (!userItemMatrix.containsKey(userId)) {
      return [];
    }

    // Find similar users
    final similarUsers = _findSimilarUsers(userId, userItemMatrix);
    
    if (similarUsers.isEmpty) {
      return [];
    }

    final recommendations = <RecommendationResult>[];

    // Generate recommendations based on similar users
    for (final content in availableContent) {
      double predictedRating = 0.0;
      double totalSimilarity = 0.0;

      for (final userEntry in similarUsers) {
        final similarUserId = userEntry.key;
        final similarity = userEntry.value;
        final userRatings = userItemMatrix[similarUserId]!;

        if (userRatings.containsKey(content.id)) {
          final rating = userRatings[content.id]!;
          predictedRating += rating * similarity;
          totalSimilarity += similarity;
        }
      }

      if (totalSimilarity > 0) {
        predictedRating /= totalSimilarity;
        
        recommendations.add(RecommendationResult(
          content: content,
          score: predictedRating,
          algorithm: 'collaborative',
          explanation: 'Liked by users with similar tastes',
        ));
      }
    }

    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(maxRecommendations).toList();
  }

  /// K-Nearest Neighbors (KNN) Recommendations
  Future<List<RecommendationResult>> _generateKNNRecommendations(
    List<Map<String, dynamic>> userHistory,
    List<ContentItem> availableContent,
    int maxRecommendations,
  ) async {
    if (userHistory.isEmpty) {
      return [];
    }

    // Get user's liked content
    final likedContent = userHistory
        .where((item) => (item['rating'] as double? ?? 0.0) > 3.0)
        .map((item) => item['content'] as ContentItem)
        .toList();

    if (likedContent.isEmpty) {
      return [];
    }

    final recommendations = <RecommendationResult>[];

    for (final content in availableContent) {
      double maxSimilarity = 0.0;
      ContentItem? mostSimilarContent;

      // Find most similar content from user's liked items
      for (final likedItem in likedContent) {
        final similarity = await _contentAnalysis.calculateContentSimilarity(
          content,
          likedItem,
        );
        
        if (similarity > maxSimilarity) {
          maxSimilarity = similarity;
          mostSimilarContent = likedItem;
        }
      }

      if (maxSimilarity > 0.2) { // Threshold for similarity
        recommendations.add(RecommendationResult(
          content: content,
          score: maxSimilarity,
          algorithm: 'knn',
          explanation: 'Similar to "${mostSimilarContent?.title ?? 'your liked content'}"',
        ));
      }
    }

    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(maxRecommendations).toList();
  }

  /// Singular Value Decomposition (SVD) Recommendations
  Future<List<RecommendationResult>> _generateSVDRecommendations(
    String userId,
    List<Map<String, dynamic>> userHistory,
    List<ContentItem> availableContent,
    int maxRecommendations,
  ) async {
    // Build user-item matrix
    final userItemMatrix = _buildUserItemMatrix(userHistory);
    
    if (userItemMatrix.isEmpty) {
      return [];
    }

    // Perform SVD
    final svdResult = _aiService.performSVD(userItemMatrix);
    final userFactors = svdResult['user_factors'] as Map<String, List<double>>;
    final itemFactors = svdResult['item_factors'] as Map<String, List<double>>;

    if (!userFactors.containsKey(userId)) {
      return [];
    }

    final userFactor = userFactors[userId]!;
    final recommendations = <RecommendationResult>[];

    // Predict ratings for available content
    for (final content in availableContent) {
      if (itemFactors.containsKey(content.id)) {
        final itemFactor = itemFactors[content.id]!;
        
        // Calculate predicted rating using dot product
        double predictedRating = 0.0;
        for (int i = 0; i < userFactor.length; i++) {
          predictedRating += userFactor[i] * itemFactor[i];
        }

        // Normalize rating to 0-1 scale
        predictedRating = (predictedRating + 1) / 2; // Assuming ratings are -1 to 1
        predictedRating = predictedRating.clamp(0.0, 1.0);

        recommendations.add(RecommendationResult(
          content: content,
          score: predictedRating,
          algorithm: 'svd',
          explanation: 'Matrix factorization prediction',
        ));
      }
    }

    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(maxRecommendations).toList();
  }

  /// Trending Content Recommendations
  Future<List<RecommendationResult>> _generateTrendingRecommendations(
    List<ContentItem> availableContent,
    int maxRecommendations,
  ) async {
    final recommendations = <RecommendationResult>[];

    for (final content in availableContent) {
      // Calculate trending score based on views, likes, and recency
      double trendingScore = 0.0;
      
      // View count weight
      final viewCount = content.viewCount ?? 0;
      final viewScore = min(viewCount / 1000000.0, 1.0) * 0.4;
      
      // Like count weight
      final likeCount = content.likeCount ?? 0;
      final likeScore = min(likeCount / 100000.0, 1.0) * 0.3;
      
      // Recency weight
      double recencyScore = 0.0;
      if (content.publishedAt != null) {
        final daysSincePublished = DateTime.now().difference(content.publishedAt!).inDays;
        recencyScore = exp(-daysSincePublished / 30.0) * 0.3; // Decay over 30 days
      }
      
      trendingScore = viewScore + likeScore + recencyScore;

      recommendations.add(RecommendationResult(
        content: content,
        score: trendingScore,
        algorithm: 'trending',
        explanation: 'Currently trending content',
      ));
    }

    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(maxRecommendations).toList();
  }

  /// Build user profile from history
  Map<String, dynamic> _buildUserProfile(List<Map<String, dynamic>> userHistory) {
    final profile = <String, dynamic>{
      'genres': <String, int>{},
      'artists': <String, int>{},
      'channels': <String, int>{},
      'topics': <String, int>{},
      'avgRating': 0.0,
      'totalInteractions': userHistory.length,
    };

    double totalRating = 0.0;
    int ratedItems = 0;

    for (final item in userHistory) {
      final content = item['content'] as ContentItem?;
      final rating = item['rating'] as double? ?? 0.0;
      
      if (content != null) {
        // Count genres
        for (final genre in content.genres) {
          profile['genres'][genre] = (profile['genres'][genre] ?? 0) + 1;
        }
        
        // Count artists/channels
        if (content.artistName != null && content.artistName!.isNotEmpty) {
          profile['artists'][content.artistName!] = 
              (profile['artists'][content.artistName!] ?? 0) + 1;
        }
        
        if (content.channelName != null && content.channelName!.isNotEmpty) {
          profile['channels'][content.channelName!] = 
              (profile['channels'][content.channelName!] ?? 0) + 1;
        }
        
        if (rating > 0) {
          totalRating += rating;
          ratedItems++;
        }
      }
    }

    if (ratedItems > 0) {
      profile['avgRating'] = totalRating / ratedItems;
    }

    return profile;
  }

  /// Calculate content similarity for CBF
  Future<double> _calculateContentSimilarity(
    Map<String, dynamic> userProfile,
    ContentItem content,
  ) async {
    double similarity = 0.0;
    double totalWeight = 0.0;

    // Genre similarity
    final userGenres = userProfile['genres'] as Map<String, int>;
    if (userGenres.isNotEmpty) {
      int genreMatches = 0;
      for (final genre in content.genres) {
        if (userGenres.containsKey(genre)) {
          genreMatches += userGenres[genre]!;
        }
      }
      final genreSimilarity = genreMatches / userGenres.values.fold(0, (a, b) => a + b);
      similarity += genreSimilarity * 0.4;
      totalWeight += 0.4;
    }

    // Artist similarity
    final userArtists = userProfile['artists'] as Map<String, int>;
    if (userArtists.isNotEmpty && content.artistName != null) {
      final artistCount = userArtists[content.artistName!] ?? 0;
      final artistSimilarity = artistCount / userArtists.values.fold(0, (a, b) => a + b);
      similarity += artistSimilarity * 0.3;
      totalWeight += 0.3;
    }

    // Channel similarity
    final userChannels = userProfile['channels'] as Map<String, int>;
    if (userChannels.isNotEmpty && content.channelName != null) {
      final channelCount = userChannels[content.channelName!] ?? 0;
      final channelSimilarity = channelCount / userChannels.values.fold(0, (a, b) => a + b);
      similarity += channelSimilarity * 0.2;
      totalWeight += 0.2;
    }

    // Rating similarity
    final avgRating = userProfile['avgRating'] as double;
    if (avgRating > 0 && content.rating != null) {
      final ratingSimilarity = 1.0 - (avgRating - content.rating!).abs() / 5.0;
      similarity += ratingSimilarity * 0.1;
      totalWeight += 0.1;
    }

    return totalWeight > 0 ? similarity / totalWeight : 0.0;
  }

  /// Build user-item matrix for collaborative filtering
  Map<String, Map<String, double>> _buildUserItemMatrix(
    List<Map<String, dynamic>> userHistory,
  ) {
    final matrix = <String, Map<String, double>>{};

    for (final item in userHistory) {
      final userId = item['userId'] as String? ?? 'default_user';
      final contentId = item['contentId'] as String? ?? '';
      final rating = item['rating'] as double? ?? 0.0;

      if (contentId.isNotEmpty && rating > 0) {
        matrix[userId] ??= <String, double>{};
        matrix[userId]![contentId] = rating;
      }
    }

    return matrix;
  }

  /// Find similar users for collaborative filtering
  List<MapEntry<String, double>> _findSimilarUsers(
    String userId,
    Map<String, Map<String, double>> userItemMatrix,
  ) {
    final targetUserRatings = userItemMatrix[userId]!;
    final similarities = <String, double>{};

    for (final otherUserId in userItemMatrix.keys) {
      if (otherUserId == userId) continue;

      final otherUserRatings = userItemMatrix[otherUserId]!;
      final similarity = _calculateCosineSimilarity(targetUserRatings, otherUserRatings);
      
      if (similarity > 0.1) {
        similarities[otherUserId] = similarity;
      }
    }

    return similarities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  /// Calculate cosine similarity between two rating vectors
  double _calculateCosineSimilarity(
    Map<String, double> vectorA,
    Map<String, double> vectorB,
  ) {
    final commonKeys = vectorA.keys.where((key) => vectorB.containsKey(key)).toList();
    
    if (commonKeys.isEmpty) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (final key in commonKeys) {
      final a = vectorA[key]!;
      final b = vectorB[key]!;
      dotProduct += a * b;
      normA += a * a;
      normB += b * b;
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  /// Combine recommendations from different algorithms
  void _combineRecommendations(
    Map<String, RecommendationResult> combined,
    List<RecommendationResult> recommendations,
    String algorithm,
  ) {
    final weight = _algorithmWeights[algorithm] ?? 0.1;

    for (final rec in recommendations) {
      final contentId = rec.content.id;
      
      if (combined.containsKey(contentId)) {
        // Combine scores using weighted average
        final existing = combined[contentId]!;
        final newScore = (existing.score * existing.algorithmWeight + rec.score * weight) /
                        (existing.algorithmWeight + weight);
        
        combined[contentId] = RecommendationResult(
          content: rec.content,
          score: newScore,
          algorithm: 'hybrid',
          explanation: '${existing.explanation} + ${rec.explanation}',
          algorithmWeight: existing.algorithmWeight + weight,
        );
      } else {
        combined[contentId] = RecommendationResult(
          content: rec.content,
          score: rec.score,
          algorithm: algorithm,
          explanation: rec.explanation,
          algorithmWeight: weight,
        );
      }
    }
  }

  /// Apply mood-based filtering
  List<RecommendationResult> _applyMoodFiltering(
    List<RecommendationResult> recommendations,
    String mood,
  ) {
    if (mood == 'neutral' || mood == 'all') {
      return recommendations;
    }

    final moodGenres = AIService.moodGenres[mood] ?? [];
    
    return recommendations.where((rec) {
      final content = rec.content;
      return content.genres.any((genre) => moodGenres.contains(genre));
    }).toList();
  }

  /// Apply diversity filtering to avoid too similar content
  List<RecommendationResult> _applyDiversityFiltering(
    List<RecommendationResult> recommendations,
    int maxRecommendations,
  ) {
    if (recommendations.length <= maxRecommendations) {
      return recommendations;
    }

    final diverseRecommendations = <RecommendationResult>[];
    final usedGenres = <String>{};
    final usedArtists = <String>{};

    // First pass: Add diverse content
    for (final rec in recommendations) {
      final content = rec.content;
      final hasNewGenre = content.genres.any((genre) => !usedGenres.contains(genre));
      final hasNewArtist = content.artistName != null && 
                          !usedArtists.contains(content.artistName!);

      if (hasNewGenre || hasNewArtist || diverseRecommendations.length < maxRecommendations * 0.7) {
        diverseRecommendations.add(rec);
        usedGenres.addAll(content.genres);
        if (content.artistName != null) {
          usedArtists.add(content.artistName!);
        }
      }

      if (diverseRecommendations.length >= maxRecommendations) {
        break;
      }
    }

    // Second pass: Fill remaining slots with highest scoring content
    if (diverseRecommendations.length < maxRecommendations) {
      final remainingSlots = maxRecommendations - diverseRecommendations.length;
      final usedIds = diverseRecommendations.map((r) => r.content.id).toSet();
      
      final remainingRecommendations = recommendations
          .where((r) => !usedIds.contains(r.content.id))
          .take(remainingSlots)
          .toList();
      
      diverseRecommendations.addAll(remainingRecommendations);
    }

    return diverseRecommendations;
  }

  /// Generate smart playlists
  Future<List<SmartPlaylist>> generateSmartPlaylists({
    required String userId,
    required List<ContentItem> availableContent,
    List<Map<String, dynamic>>? userHistory,
    Map<String, dynamic>? userPreferences,
    String? currentMood,
  }) async {
    final playlists = <SmartPlaylist>[];
    final history = userHistory ?? [];
    final preferences = userPreferences ?? {};
    final mood = currentMood ?? 'neutral';

    // Generate different types of playlists
    final playlistTypes = [
      'Mood-Based',
      'Genre-Based',
      'Time-Based',
      'Trending',
      'Personalized',
    ];

    for (final type in playlistTypes) {
      final playlist = await _generatePlaylistByType(
        type,
        userId,
        availableContent,
        history,
        preferences,
        mood,
      );
      
      if (playlist.content.isNotEmpty) {
        playlists.add(playlist);
      }
    }

    return playlists;
  }

  /// Generate playlist by type
  Future<SmartPlaylist> _generatePlaylistByType(
    String type,
    String userId,
    List<ContentItem> availableContent,
    List<Map<String, dynamic>> userHistory,
    Map<String, dynamic> userPreferences,
    String mood,
  ) async {
    List<ContentItem> playlistContent = [];

    switch (type) {
      case 'Mood-Based':
        playlistContent = _generateMoodPlaylist(availableContent, mood);
        break;
      case 'Genre-Based':
        playlistContent = _generateGenrePlaylist(availableContent, userPreferences);
        break;
      case 'Time-Based':
        playlistContent = _generateTimeBasedPlaylist(availableContent);
        break;
      case 'Trending':
        playlistContent = _generateTrendingPlaylist(availableContent);
        break;
      case 'Personalized':
        final recommendations = await generateRecommendations(
          userId: userId,
          availableContent: availableContent,
          userHistory: userHistory,
          userPreferences: userPreferences,
          currentMood: mood,
          maxRecommendations: 20,
        );
        playlistContent = recommendations.map((r) => r.content).toList();
        break;
    }

    return SmartPlaylist(
      id: '${type.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
      name: '$type Playlist',
      description: 'Curated $type content for you',
      content: playlistContent,
      type: type,
      createdAt: DateTime.now(),
    );
  }

  List<ContentItem> _generateMoodPlaylist(List<ContentItem> content, String mood) {
    final moodGenres = AIService.moodGenres[mood] ?? [];
    
    return content
        .where((item) => item.genres.any((genre) => moodGenres.contains(genre)))
        .toList()
      ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
  }

  List<ContentItem> _generateGenrePlaylist(List<ContentItem> content, Map<String, dynamic> preferences) {
    final preferredGenres = preferences['genres'] as List<String>? ?? [];
    
    if (preferredGenres.isEmpty) {
      return content.take(20).toList();
    }

    return content
        .where((item) => item.genres.any((genre) => preferredGenres.contains(genre)))
        .toList()
      ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
  }

  List<ContentItem> _generateTimeBasedPlaylist(List<ContentItem> content) {
    final now = DateTime.now();
    final hour = now.hour;

    List<ContentItem> timeBasedContent = [];

    if (hour >= 6 && hour < 12) {
      // Morning: Energetic content
      timeBasedContent = content.where((item) => 
          item.genres.any((genre) => ['Pop', 'Rock', 'Electronic'].contains(genre))).toList();
    } else if (hour >= 12 && hour < 18) {
      // Afternoon: Balanced content
      timeBasedContent = content.where((item) => 
          item.genres.any((genre) => ['Pop', 'Indie', 'Alternative'].contains(genre))).toList();
    } else if (hour >= 18 && hour < 22) {
      // Evening: Relaxing content
      timeBasedContent = content.where((item) => 
          item.genres.any((genre) => ['Jazz', 'Ambient', 'Acoustic'].contains(genre))).toList();
    } else {
      // Night: Calm content
      timeBasedContent = content.where((item) => 
          item.genres.any((genre) => ['Classical', 'Ambient', 'Meditation'].contains(genre))).toList();
    }

    return timeBasedContent
      ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
  }

  List<ContentItem> _generateTrendingPlaylist(List<ContentItem> content) {
    return content
      ..sort((a, b) {
        final aViews = a.viewCount ?? 0;
        final bViews = b.viewCount ?? 0;
        return bViews.compareTo(aViews);
      });
  }
}

/// Recommendation result with algorithm information
class RecommendationResult {
  final ContentItem content;
  final double score;
  final String algorithm;
  final String explanation;
  final double algorithmWeight;
  late double finalScore;

  RecommendationResult({
    required this.content,
    required this.score,
    required this.algorithm,
    required this.explanation,
    this.algorithmWeight = 1.0,
  }) {
    finalScore = score * algorithmWeight;
  }
}

/// Smart playlist with metadata
class SmartPlaylist {
  final String id;
  final String name;
  final String description;
  final List<ContentItem> content;
  final String type;
  final DateTime createdAt;

  SmartPlaylist({
    required this.id,
    required this.name,
    required this.description,
    required this.content,
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'content': content.map((c) => c.toJson()).toList(),
      'type': type,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
