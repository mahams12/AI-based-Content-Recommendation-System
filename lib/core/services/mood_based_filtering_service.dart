import 'dart:math';
import '../models/content_model.dart';
import 'ai_service.dart';

/// Service for mood-based content filtering and recommendations
class MoodBasedFilteringService {
  static final MoodBasedFilteringService _instance = MoodBasedFilteringService._internal();
  factory MoodBasedFilteringService() => _instance;
  MoodBasedFilteringService._internal();

  final AIService _aiService = AIService();

  /// Enhanced mood-to-genre mapping with weights
  static final Map<String, Map<String, double>> moodGenreWeights = {
    'happy': {
      'Comedy': 0.9,
      'Pop': 0.8,
      'Dance': 0.8,
      'Family': 0.7,
      'Romance': 0.6,
      'Musical': 0.7,
      'Animation': 0.6,
      'Kids': 0.5,
    },
    'sad': {
      'Drama': 0.9,
      'Blues': 0.8,
      'Indie': 0.7,
      'Alternative': 0.7,
      'Soul': 0.6,
      'Ballad': 0.8,
      'Melancholic': 0.9,
      'Emotional': 0.8,
    },
    'energetic': {
      'Action': 0.9,
      'Dance': 0.9,
      'Electronic': 0.8,
      'Rock': 0.7,
      'Pop': 0.6,
      'Hip-Hop': 0.8,
      'Workout': 0.9,
      'Upbeat': 0.8,
    },
    'relaxed': {
      'Ambient': 0.9,
      'Classical': 0.8,
      'Jazz': 0.7,
      'Acoustic': 0.8,
      'Meditation': 0.9,
      'Lounge': 0.7,
      'Chill': 0.8,
      'Spa': 0.7,
    },
    'romantic': {
      'Romance': 0.9,
      'R&B': 0.8,
      'Soul': 0.7,
      'Pop': 0.6,
      'Love Songs': 0.9,
      'Soft Rock': 0.6,
      'Ballad': 0.7,
      'Intimate': 0.8,
    },
    'adventurous': {
      'Adventure': 0.9,
      'Action': 0.8,
      'Thriller': 0.7,
      'Sci-Fi': 0.7,
      'Fantasy': 0.6,
      'Epic': 0.8,
      'Exploration': 0.7,
      'Discovery': 0.6,
    },
    'focused': {
      'Documentary': 0.8,
      'Educational': 0.9,
      'Classical': 0.7,
      'Instrumental': 0.8,
      'Ambient': 0.6,
      'Concentration': 0.9,
      'Study': 0.8,
      'Productivity': 0.7,
    },
    'nostalgic': {
      'Classic': 0.9,
      'Retro': 0.8,
      'Vintage': 0.7,
      'Oldies': 0.8,
      'Traditional': 0.6,
      'Folk': 0.6,
      'Memory': 0.7,
      'Timeless': 0.6,
    },
    'angry': {
      'Metal': 0.9,
      'Punk': 0.8,
      'Rock': 0.7,
      'Alternative': 0.6,
      'Grunge': 0.7,
      'Hardcore': 0.8,
      'Aggressive': 0.9,
      'Intense': 0.7,
    },
    'calm': {
      'Ambient': 0.8,
      'Classical': 0.7,
      'Jazz': 0.6,
      'Acoustic': 0.7,
      'New Age': 0.8,
      'Chill': 0.7,
      'Peaceful': 0.9,
      'Serene': 0.8,
    },
  };

  /// Time-based mood adjustments
  static final Map<String, Map<int, double>> timeBasedMoodAdjustments = {
    'morning': {6: 1.2, 7: 1.1, 8: 1.0, 9: 0.9, 10: 0.8, 11: 0.7},
    'afternoon': {12: 0.8, 13: 0.9, 14: 1.0, 15: 1.0, 16: 0.9, 17: 0.8},
    'evening': {18: 0.9, 19: 1.0, 20: 1.1, 21: 1.0, 22: 0.9},
    'night': {23: 0.8, 0: 0.7, 1: 0.6, 2: 0.5, 3: 0.5, 4: 0.6, 5: 0.7},
  };

  /// Filter content based on mood with AI-enhanced scoring
  Future<List<ContentItem>> filterContentByMood({
    required List<ContentItem> content,
    required String mood,
    int maxResults = 20,
    bool includeTimeAdjustment = true,
  }) async {
    if (mood == 'all' || mood == 'neutral') {
      // Shuffle for variety even when mood is neutral
      final shuffled = List<ContentItem>.from(content)..shuffle();
      return shuffled.take(maxResults).toList();
    }

    final scoredContent = <MapEntry<ContentItem, double>>[];

    for (final item in content) {
      final score = await _calculateMoodScore(item, mood, includeTimeAdjustment);
      // Lower threshold to include more content, even if score is low
      // This ensures we get diverse results even when genres are missing
      if (score > 0.05) {
        scoredContent.add(MapEntry(item, score));
      }
    }

    // Sort by mood relevance score
    scoredContent.sort((a, b) => b.value.compareTo(a.value));

    // If we have enough high-scoring items, use them
    // Otherwise, include lower-scoring items to ensure diversity
    final highScoreItems = scoredContent.where((e) => e.value > 0.3).toList();
    final mediumScoreItems = scoredContent.where((e) => e.value > 0.1 && e.value <= 0.3).toList();
    final lowScoreItems = scoredContent.where((e) => e.value <= 0.1).toList();

    final result = <ContentItem>[];
    
    // Add high-scoring items first
    result.addAll(highScoreItems.take((maxResults * 0.6).round()).map((e) => e.key));
    
    // Add medium-scoring items for variety
    if (result.length < maxResults) {
      final needed = maxResults - result.length;
      result.addAll(mediumScoreItems.take(needed).map((e) => e.key));
    }
    
    // If still not enough, add some low-scoring items (shuffled for variety)
    if (result.length < maxResults) {
      final needed = maxResults - result.length;
      lowScoreItems.shuffle();
      result.addAll(lowScoreItems.take(needed).map((e) => e.key));
    }

    // Shuffle the final result to ensure variety
    result.shuffle();
    
    return result.take(maxResults).toList();
  }

  /// Calculate mood relevance score for a content item
  Future<double> _calculateMoodScore(
    ContentItem item,
    String mood,
    bool includeTimeAdjustment,
  ) async {
    double score = 0.0;
    double totalWeight = 0.0;

    // 1. Genre-based scoring (primary factor, but adjust weight if genres are missing)
    final genreScore = _calculateGenreScore(item.genres, mood);
    if (item.genres.isNotEmpty && genreScore > 0) {
      score += genreScore * 0.5;
      totalWeight += 0.5;
    } else {
      // If no genres, reduce genre weight and increase title/description weight
      score += genreScore * 0.2;
      totalWeight += 0.2;
    }

    // 2. Title sentiment analysis (increased weight if genres missing)
    final titleSentiment = await _aiService.analyzeSentiment(item.title);
    final sentimentScore = _mapSentimentToMood(titleSentiment.mood, mood);
    final titleWeight = item.genres.isEmpty ? 0.35 : 0.2;
    score += sentimentScore * titleWeight;
    totalWeight += titleWeight;
    
    // Also check title for mood keywords
    final titleMoodScore = _checkMoodKeywords(item.title, mood);
    score += titleMoodScore * 0.1;
    totalWeight += 0.1;

    // 3. Description sentiment analysis (if available, increased weight if genres missing)
    if (item.description.isNotEmpty) {
      final descSentiment = await _aiService.analyzeSentiment(item.description);
      final descScore = _mapSentimentToMood(descSentiment.mood, mood);
      final descWeight = item.genres.isEmpty ? 0.25 : 0.15;
      score += descScore * descWeight;
      totalWeight += descWeight;
      
      // Also check description for mood keywords
      final descMoodScore = _checkMoodKeywords(item.description, mood);
      score += descMoodScore * 0.1;
      totalWeight += 0.1;
    }

    // 4. Platform-specific adjustments
    final platformScore = _calculatePlatformScore(item.platform, mood);
    score += platformScore * 0.1;
    totalWeight += 0.1;

    // 5. Time-based adjustments
    if (includeTimeAdjustment) {
      final timeScore = _calculateTimeBasedScore(mood);
      score += timeScore * 0.05;
      totalWeight += 0.05;
    }

    return totalWeight > 0 ? score / totalWeight : 0.0;
  }

  /// Check for mood keywords in text
  double _checkMoodKeywords(String text, String mood) {
    final lowerText = text.toLowerCase();
    final moodKeywords = {
      'happy': ['happy', 'joy', 'fun', 'cheerful', 'upbeat', 'excited', 'celebration', 'party', 'smile', 'laugh'],
      'sad': ['sad', 'depressed', 'lonely', 'heartbreak', 'tears', 'crying', 'melancholy', 'grief', 'sorrow'],
      'angry': ['angry', 'rage', 'furious', 'mad', 'hate', 'aggressive', 'intense', 'violent', 'frustrated'],
      'calm': ['calm', 'peaceful', 'serene', 'relax', 'quiet', 'tranquil', 'zen', 'meditation', 'chill'],
      'energetic': ['energetic', 'energy', 'pump', 'workout', 'intense', 'powerful', 'strong', 'active', 'dynamic'],
      'relaxed': ['relax', 'chill', 'lounge', 'ambient', 'soft', 'gentle', 'smooth', 'easy', 'mellow'],
      'romantic': ['romantic', 'love', 'heart', 'kiss', 'romance', 'intimate', 'passion', 'sweet', 'tender'],
      'adventurous': ['adventure', 'explore', 'journey', 'quest', 'epic', 'thrilling', 'exciting', 'action'],
      'focused': ['focus', 'study', 'concentration', 'productivity', 'work', 'learn', 'educational', 'documentary'],
      'nostalgic': ['nostalgic', 'memory', 'remember', 'old', 'classic', 'retro', 'vintage', 'past', 'throwback'],
    };
    
    final keywords = moodKeywords[mood] ?? [];
    int matches = 0;
    for (final keyword in keywords) {
      if (lowerText.contains(keyword)) {
        matches++;
      }
    }
    
    // Return score based on number of keyword matches
    return min(matches * 0.15, 0.6);
  }

  /// Calculate genre-based mood score
  double _calculateGenreScore(List<String> genres, String mood) {
    final moodGenres = moodGenreWeights[mood] ?? {};
    if (moodGenres.isEmpty) return 0.0;

    double maxScore = 0.0;
    for (final genre in genres) {
      // Try exact match first
      var genreScore = moodGenres[genre] ?? 0.0;
      
      // Try case-insensitive match
      if (genreScore == 0.0) {
        for (final moodGenre in moodGenres.keys) {
          if (genre.toLowerCase() == moodGenre.toLowerCase()) {
            genreScore = moodGenres[moodGenre]!;
            break;
          }
        }
      }
      
      // Try partial match (e.g., "Hip-Hop" matches "Hip-Hop", "Hip Hop", "hiphop")
      if (genreScore == 0.0) {
        final genreLower = genre.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        for (final moodGenre in moodGenres.keys) {
          final moodGenreLower = moodGenre.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          if (genreLower.contains(moodGenreLower) || moodGenreLower.contains(genreLower)) {
            genreScore = moodGenres[moodGenre]! * 0.8; // Slightly lower score for partial match
            break;
          }
        }
      }
      
      maxScore = max(maxScore, genreScore);
    }

    return maxScore;
  }

  /// Map sentiment analysis result to mood relevance
  double _mapSentimentToMood(String detectedMood, String targetMood) {
    if (detectedMood == targetMood) return 1.0;
    
    // Define mood relationships
    final moodRelationships = {
      'happy': ['energetic', 'romantic'],
      'sad': ['nostalgic', 'calm'],
      'energetic': ['happy', 'adventurous'],
      'relaxed': ['calm', 'focused'],
      'romantic': ['happy', 'calm'],
      'adventurous': ['energetic', 'happy'],
      'focused': ['relaxed', 'calm'],
      'nostalgic': ['sad', 'calm'],
      'angry': ['energetic'],
      'calm': ['relaxed', 'focused', 'romantic'],
    };

    final relatedMoods = moodRelationships[detectedMood] ?? [];
    if (relatedMoods.contains(targetMood)) return 0.6;
    
    return 0.0;
  }

  /// Calculate platform-specific mood score
  double _calculatePlatformScore(ContentType platform, String mood) {
    final platformMoodPreferences = {
      ContentType.youtube: {
        'energetic': 0.8,
        'happy': 0.7,
        'focused': 0.6,
        'adventurous': 0.7,
      },
      ContentType.spotify: {
        'relaxed': 0.9,
        'romantic': 0.8,
        'energetic': 0.7,
        'focused': 0.8,
        'nostalgic': 0.7,
      },
      ContentType.tmdb: {
        'adventurous': 0.8,
        'romantic': 0.7,
        'happy': 0.6,
        'focused': 0.7,
      },
    };

    return platformMoodPreferences[platform]?[mood] ?? 0.5;
  }

  /// Calculate time-based mood adjustment
  double _calculateTimeBasedScore(String mood) {
    final now = DateTime.now();
    final hour = now.hour;
    
    // Determine time period
    String timePeriod;
    if (hour >= 6 && hour < 12) {
      timePeriod = 'morning';
    } else if (hour >= 12 && hour < 18) {
      timePeriod = 'afternoon';
    } else if (hour >= 18 && hour < 23) {
      timePeriod = 'evening';
    } else {
      timePeriod = 'night';
    }

    final adjustments = timeBasedMoodAdjustments[timePeriod] ?? {};
    return adjustments[hour] ?? 1.0;
  }

  /// Generate mood-based playlist with AI curation
  Future<List<ContentItem>> generateMoodPlaylist({
    required List<ContentItem> availableContent,
    required String mood,
    int playlistLength = 15,
    bool includeVariety = true,
  }) async {
    // Get mood-filtered content
    final moodContent = await filterContentByMood(
      content: availableContent,
      mood: mood,
      maxResults: playlistLength * 2, // Get more to allow for variety
    );

    if (moodContent.isEmpty) {
      return availableContent.take(playlistLength).toList();
    }

    if (!includeVariety) {
      return moodContent.take(playlistLength).toList();
    }

    // Add variety by ensuring different platforms and genres
    return _addVarietyToPlaylist(moodContent, playlistLength);
  }

  /// Add variety to playlist while maintaining mood relevance
  List<ContentItem> _addVarietyToPlaylist(
    List<ContentItem> moodContent,
    int targetLength,
  ) {
    final playlist = <ContentItem>[];
    final usedPlatforms = <ContentType>{};
    final usedGenres = <String>{};

    // First pass: Add diverse content
    for (final item in moodContent) {
      if (playlist.length >= targetLength) break;

      final hasNewPlatform = !usedPlatforms.contains(item.platform);
      final hasNewGenre = item.genres.any((genre) => !usedGenres.contains(genre));

      if (hasNewPlatform || hasNewGenre || playlist.length < targetLength * 0.7) {
        playlist.add(item);
        usedPlatforms.add(item.platform);
        usedGenres.addAll(item.genres);
      }
    }

    // Second pass: Fill remaining slots
    if (playlist.length < targetLength) {
      final usedIds = playlist.map((item) => item.id).toSet();
      final remainingItems = moodContent
          .where((item) => !usedIds.contains(item.id))
          .take(targetLength - playlist.length)
          .toList();
      
      playlist.addAll(remainingItems);
    }

    return playlist;
  }

  /// Get mood-specific content recommendations with explanations
  Future<List<MoodRecommendation>> getMoodRecommendations({
    required List<ContentItem> content,
    required String mood,
    int maxResults = 10,
  }) async {
    final filteredContent = await filterContentByMood(
      content: content,
      mood: mood,
      maxResults: maxResults,
    );

    return filteredContent.map((item) {
      return MoodRecommendation(
        content: item,
        mood: mood,
        relevanceScore: _calculateGenreScore(item.genres, mood),
        explanation: _generateRecommendationExplanation(item, mood),
      );
    }).toList();
  }

  /// Generate explanation for why content matches mood
  String _generateRecommendationExplanation(ContentItem item, String mood) {
    final moodGenres = moodGenreWeights[mood] ?? {};
    final matchingGenres = item.genres
        .where((genre) => moodGenres.containsKey(genre))
        .toList();

    if (matchingGenres.isNotEmpty) {
      final topGenre = matchingGenres.first;
      return 'Perfect for your $mood mood - features ${topGenre.toLowerCase()} content';
    }

    return 'Curated for your $mood mood based on AI analysis';
  }

  /// Analyze user's mood patterns from interaction history
  Future<MoodAnalysis> analyzeMoodPatterns(
    List<Map<String, dynamic>> interactions,
  ) async {
    final moodCounts = <String, int>{};
    final moodScores = <String, double>{};
    final timePatterns = <String, List<int>>{};

    for (final interaction in interactions) {
      final mood = interaction['mood'] as String? ?? 'neutral';
      final rating = interaction['rating'] as double? ?? 0.0;
      final timestamp = interaction['timestamp'] as DateTime?;

      moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
      moodScores[mood] = (moodScores[mood] ?? 0.0) + rating;

      if (timestamp != null) {
        timePatterns[mood] ??= [];
        timePatterns[mood]!.add(timestamp.hour);
      }
    }

    // Calculate average scores
    final avgScores = <String, double>{};
    for (final mood in moodCounts.keys) {
      avgScores[mood] = moodScores[mood]! / moodCounts[mood]!;
    }

    // Find dominant mood
    final dominantMood = avgScores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return MoodAnalysis(
      dominantMood: dominantMood,
      moodDistribution: moodCounts,
      averageScores: avgScores,
      timePatterns: timePatterns,
      totalInteractions: interactions.length,
    );
  }
}

/// Mood recommendation with explanation
class MoodRecommendation {
  final ContentItem content;
  final String mood;
  final double relevanceScore;
  final String explanation;

  MoodRecommendation({
    required this.content,
    required this.mood,
    required this.relevanceScore,
    required this.explanation,
  });
}

/// Mood analysis result
class MoodAnalysis {
  final String dominantMood;
  final Map<String, int> moodDistribution;
  final Map<String, double> averageScores;
  final Map<String, List<int>> timePatterns;
  final int totalInteractions;

  MoodAnalysis({
    required this.dominantMood,
    required this.moodDistribution,
    required this.averageScores,
    required this.timePatterns,
    required this.totalInteractions,
  });

  /// Get mood trend (increasing/decreasing)
  String getMoodTrend(String mood) {
    final scores = averageScores[mood] ?? 0.0;
    if (scores > 4.0) return 'increasing';
    if (scores < 2.0) return 'decreasing';
    return 'stable';
  }

  /// Get preferred time for mood
  String getPreferredTime(String mood) {
    final hours = timePatterns[mood] ?? [];
    if (hours.isEmpty) return 'anytime';
    
    final avgHour = hours.reduce((a, b) => a + b) / hours.length;
    if (avgHour >= 6 && avgHour < 12) return 'morning';
    if (avgHour >= 12 && avgHour < 18) return 'afternoon';
    if (avgHour >= 18 && avgHour < 23) return 'evening';
    return 'night';
  }
}

