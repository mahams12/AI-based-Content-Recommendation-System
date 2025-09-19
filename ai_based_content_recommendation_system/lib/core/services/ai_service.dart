import 'dart:math';
import 'package:collection/collection.dart';

/// AI Service for content recommendation and analysis
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // Sentiment analysis keywords and weights
  final Map<String, double> _positiveWords = {
    'love': 0.9, 'amazing': 0.8, 'awesome': 0.8, 'great': 0.7, 'excellent': 0.8,
    'fantastic': 0.8, 'wonderful': 0.7, 'beautiful': 0.6, 'perfect': 0.8,
    'incredible': 0.8, 'outstanding': 0.7, 'brilliant': 0.7, 'superb': 0.7,
    'magnificent': 0.8, 'spectacular': 0.7, 'marvelous': 0.7, 'delightful': 0.6,
    'enjoyable': 0.6, 'pleasurable': 0.6, 'satisfying': 0.6, 'thrilling': 0.7,
    'exciting': 0.7, 'fun': 0.6, 'happy': 0.7, 'joyful': 0.7, 'cheerful': 0.6,
    'upbeat': 0.6, 'energetic': 0.6, 'vibrant': 0.6, 'lively': 0.6,
  };

  final Map<String, double> _negativeWords = {
    'hate': -0.9, 'terrible': -0.8, 'awful': -0.8, 'bad': -0.6, 'horrible': -0.8,
    'disgusting': -0.8, 'disappointing': -0.7, 'boring': -0.6, 'stupid': -0.7,
    'annoying': -0.6, 'frustrating': -0.6, 'depressing': -0.7, 'sad': -0.6,
    'angry': -0.6, 'upset': -0.6, 'worried': -0.5, 'anxious': -0.5,
    'stressed': -0.5, 'tired': -0.4, 'exhausted': -0.5, 'sick': -0.5,
    'painful': -0.6, 'hurt': -0.5, 'broken': -0.5, 'failed': -0.6,
  };

  // Mood categories with associated content preferences
  static final Map<String, List<String>> moodGenres = {
    'happy': ['Comedy', 'Pop', 'Dance', 'Family', 'Romance', 'Musical'],
    'sad': ['Drama', 'Blues', 'Indie', 'Alternative', 'Soul', 'Ballad'],
    'energetic': ['Action', 'Dance', 'Electronic', 'Rock', 'Pop', 'Hip-Hop'],
    'relaxed': ['Ambient', 'Classical', 'Jazz', 'Acoustic', 'Meditation', 'Lounge'],
    'romantic': ['Romance', 'R&B', 'Soul', 'Pop', 'Love Songs', 'Soft Rock'],
    'adventurous': ['Adventure', 'Action', 'Thriller', 'Sci-Fi', 'Fantasy', 'Epic'],
    'focused': ['Documentary', 'Educational', 'Classical', 'Instrumental', 'Ambient'],
    'nostalgic': ['Classic', 'Retro', 'Vintage', 'Oldies', 'Traditional', 'Folk'],
    'angry': ['Metal', 'Punk', 'Rock', 'Alternative', 'Grunge', 'Hardcore'],
    'calm': ['Ambient', 'Classical', 'Jazz', 'Acoustic', 'New Age', 'Chill'],
  };

  /// Analyze sentiment of text input
  Future<SentimentResult> analyzeSentiment(String text) async {
    if (text.isEmpty) {
      return SentimentResult(score: 0.0, confidence: 0.0, mood: 'neutral');
    }

    final words = _tokenizeText(text.toLowerCase());
    double totalScore = 0.0;
    int wordCount = 0;

    for (final word in words) {
      if (_positiveWords.containsKey(word)) {
        totalScore += _positiveWords[word]!;
        wordCount++;
      } else if (_negativeWords.containsKey(word)) {
        totalScore += _negativeWords[word]!;
        wordCount++;
      }
    }

    if (wordCount == 0) {
      return SentimentResult(score: 0.0, confidence: 0.0, mood: 'neutral');
    }

    final averageScore = totalScore / wordCount;
    final confidence = min(wordCount / 10.0, 1.0); // Confidence based on word count
    final mood = _determineMood(averageScore);

    return SentimentResult(
      score: averageScore,
      confidence: confidence,
      mood: mood,
    );
  }

  /// Detect mood from user interactions and content preferences
  Future<String> detectMood(List<Map<String, dynamic>> interactions) async {
    if (interactions.isEmpty) {
      return 'neutral';
    }

    // Analyze recent interactions for mood patterns
    final recentInteractions = interactions.take(10).toList();
    final moodScores = <String, double>{};

    for (final interaction in recentInteractions) {
      final contentGenres = interaction['genres'] as List<String>? ?? [];
      final rating = interaction['rating'] as double? ?? 0.0;
      // final timeOfDay = _getTimeOfDay(interaction['timestamp'] as DateTime?);
      
      // Weight recent interactions more heavily
      final weight = _calculateTimeWeight(interaction['timestamp'] as DateTime?);
      
      for (final genre in contentGenres) {
        for (final mood in moodGenres.keys) {
          if (moodGenres[mood]!.contains(genre)) {
            moodScores[mood] = (moodScores[mood] ?? 0.0) + (rating * weight);
          }
        }
      }
    }

    // Find the mood with highest score
    if (moodScores.isEmpty) {
      return 'neutral';
    }

    final sortedMoods = moodScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedMoods.first.key;
  }

  /// Generate TF-IDF vectors for content analysis
  Map<String, double> calculateTFIDF(List<String> documents, String term) {
    final termFreq = <String, int>{};
    final docFreq = <String, int>{};
    
    // Calculate term frequency for each document
    for (final doc in documents) {
      final words = _tokenizeText(doc.toLowerCase());
      final docTermCount = words.where((w) => w == term).length;
      termFreq[doc] = docTermCount;
      
      if (docTermCount > 0) {
        docFreq[term] = (docFreq[term] ?? 0) + 1;
      }
    }

    final tfidfScores = <String, double>{};
    final totalDocs = documents.length;
    
    for (final doc in documents) {
      final tf = termFreq[doc]! / _tokenizeText(doc.toLowerCase()).length;
      final idf = log(totalDocs / (docFreq[term] ?? 1));
      tfidfScores[doc] = tf * idf;
    }

    return tfidfScores;
  }

  /// Generate Word2Vec-like embeddings using simple co-occurrence
  Map<String, List<double>> generateWordEmbeddings(List<String> documents) {
    final vocab = <String>{};
    final cooccurrenceMatrix = <String, Map<String, int>>{};
    
    // Build vocabulary and co-occurrence matrix
    for (final doc in documents) {
      final words = _tokenizeText(doc.toLowerCase());
      vocab.addAll(words);
      
      for (int i = 0; i < words.length; i++) {
        final word = words[i];
        cooccurrenceMatrix[word] ??= <String, int>{};
        
        // Look at context window of ±2 words
        for (int j = max(0, i - 2); j < min(words.length, i + 3); j++) {
          if (i != j) {
            final contextWord = words[j];
            cooccurrenceMatrix[word]![contextWord] = 
                (cooccurrenceMatrix[word]![contextWord] ?? 0) + 1;
          }
        }
      }
    }

    // Generate embeddings from co-occurrence matrix
    final embeddings = <String, List<double>>{};
    final vocabList = vocab.toList();
    
    for (final word in vocabList) {
      final embedding = <double>[];
      for (final contextWord in vocabList) {
        final count = cooccurrenceMatrix[word]?[contextWord] ?? 0;
        embedding.add(count.toDouble());
      }
      embeddings[word] = embedding;
    }

    return embeddings;
  }

  /// Content-Based Filtering recommendation
  List<Map<String, dynamic>> contentBasedFiltering(
    List<Map<String, dynamic>> userHistory,
    List<Map<String, dynamic>> availableContent,
  ) {
    if (userHistory.isEmpty) {
      return availableContent.take(10).toList();
    }

    // Extract user preferences from history
    final userGenres = <String, int>{};
    final userArtists = <String, int>{};
    final userRatings = <String, double>{};

    for (final item in userHistory) {
      final genres = item['genres'] as List<String>? ?? [];
      final artist = item['artist'] as String? ?? '';
      final rating = item['rating'] as double? ?? 0.0;

      for (final genre in genres) {
        userGenres[genre] = (userGenres[genre] ?? 0) + 1;
      }
      
      if (artist.isNotEmpty) {
        userArtists[artist] = (userArtists[artist] ?? 0) + 1;
      }
      
      userRatings[item['id'] as String] = rating;
    }

    // Calculate similarity scores
    final scoredContent = <Map<String, dynamic>>[];
    
    for (final content in availableContent) {
      double score = 0.0;
      final contentGenres = content['genres'] as List<String>? ?? [];
      final contentArtist = content['artist'] as String? ?? '';

      // Genre similarity
      for (final genre in contentGenres) {
        score += (userGenres[genre] ?? 0) * 0.4;
      }

      // Artist similarity
      if (contentArtist.isNotEmpty) {
        score += (userArtists[contentArtist] ?? 0) * 0.3;
      }

      // Content rating
      final contentRating = content['rating'] as double? ?? 0.0;
      score += contentRating * 0.3;

      scoredContent.add({
        ...content,
        'similarity_score': score,
      });
    }

    // Sort by similarity score
    scoredContent.sort((a, b) => 
        (b['similarity_score'] as double).compareTo(a['similarity_score'] as double));

    return scoredContent.take(20).toList();
  }

  /// Collaborative Filtering recommendation using KNN
  List<Map<String, dynamic>> collaborativeFiltering(
    Map<String, Map<String, double>> userItemMatrix,
    String targetUserId,
    List<Map<String, dynamic>> availableContent,
  ) {
    if (!userItemMatrix.containsKey(targetUserId)) {
      return availableContent.take(10).toList();
    }

    final targetUserRatings = userItemMatrix[targetUserId]!;
    final userSimilarities = <String, double>{};

    // Calculate similarity with other users
    for (final userId in userItemMatrix.keys) {
      if (userId == targetUserId) continue;

      final otherUserRatings = userItemMatrix[userId]!;
      final similarity = _calculateCosineSimilarity(targetUserRatings, otherUserRatings);
      
      if (similarity > 0.1) { // Only consider users with some similarity
        userSimilarities[userId] = similarity;
      }
    }

    // Sort users by similarity
    final sortedUsers = userSimilarities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Get top K similar users (KNN)
    final k = min(5, sortedUsers.length);
    final topKUsers = sortedUsers.take(k).toList();

    // Generate recommendations based on similar users
    final itemScores = <String, double>{};
    
    for (final userEntry in topKUsers) {
      final userId = userEntry.key;
      final similarity = userEntry.value;
      final userRatings = userItemMatrix[userId]!;

      for (final itemId in userRatings.keys) {
        if (!targetUserRatings.containsKey(itemId)) {
          final rating = userRatings[itemId]!;
          itemScores[itemId] = (itemScores[itemId] ?? 0.0) + (rating * similarity);
        }
      }
    }

    // Sort items by predicted score
    final sortedItems = itemScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Map item IDs back to content
    final recommendations = <Map<String, dynamic>>[];
    for (final itemEntry in sortedItems.take(20)) {
      final itemId = itemEntry.key;
      final score = itemEntry.value;
      
      final content = availableContent.firstWhereOrNull(
        (c) => c['id'] == itemId,
      );
      
      if (content != null) {
        recommendations.add({
          ...content,
          'predicted_rating': score,
        });
      }
    }

    return recommendations;
  }

  /// Singular Value Decomposition for matrix factorization
  Map<String, dynamic> performSVD(
    Map<String, Map<String, double>> userItemMatrix,
  ) {
    // Simplified SVD implementation
    final users = userItemMatrix.keys.toList();
    final items = <String>{};
    
    for (final userRatings in userItemMatrix.values) {
      items.addAll(userRatings.keys);
    }
    
    final itemList = items.toList();
    final matrix = <List<double>>[];
    
    // Build rating matrix
    for (final user in users) {
      final row = <double>[];
      for (final item in itemList) {
        row.add(userItemMatrix[user]?[item] ?? 0.0);
      }
      matrix.add(row);
    }

    // Simplified SVD using power iteration method
    final k = min(10, min(users.length, itemList.length)); // Number of factors
    final userFactors = <String, List<double>>{};
    final itemFactors = <String, List<double>>{};

    // Initialize factors randomly
    final random = Random(42);
    for (final user in users) {
      userFactors[user] = List.generate(k, (_) => random.nextDouble() - 0.5);
    }
    
    for (final item in itemList) {
      itemFactors[item] = List.generate(k, (_) => random.nextDouble() - 0.5);
    }

    // Simple matrix factorization (ALS-like)
    for (int iter = 0; iter < 10; iter++) {
      // Update user factors
      for (int u = 0; u < users.length; u++) {
        final user = users[u];
        final userFactor = userFactors[user]!;
        
        for (int f = 0; f < k; f++) {
          double numerator = 0.0;
          double denominator = 0.0;
          
          for (int i = 0; i < itemList.length; i++) {
            final item = itemList[i];
            final rating = matrix[u][i];
            if (rating > 0) {
              final itemFactor = itemFactors[item]![f];
              numerator += rating * itemFactor;
              denominator += itemFactor * itemFactor;
            }
          }
          
          if (denominator > 0) {
            userFactor[f] = numerator / denominator;
          }
        }
      }

      // Update item factors
      for (int i = 0; i < itemList.length; i++) {
        final item = itemList[i];
        final itemFactor = itemFactors[item]!;
        
        for (int f = 0; f < k; f++) {
          double numerator = 0.0;
          double denominator = 0.0;
          
          for (int u = 0; u < users.length; u++) {
            final rating = matrix[u][i];
            if (rating > 0) {
              final userFactor = userFactors[users[u]]![f];
              numerator += rating * userFactor;
              denominator += userFactor * userFactor;
            }
          }
          
          if (denominator > 0) {
            itemFactor[f] = numerator / denominator;
          }
        }
      }
    }

    return {
      'user_factors': userFactors,
      'item_factors': itemFactors,
    };
  }

  /// Generate smart playlists based on user preferences
  List<Map<String, dynamic>> generateSmartPlaylist(
    Map<String, dynamic> userPreferences,
    List<Map<String, dynamic>> availableContent,
    String playlistTheme,
  ) {
    final playlist = <Map<String, dynamic>>[];
    final preferredGenres = userPreferences['genres'] as List<String>? ?? [];
    final preferredArtists = userPreferences['artists'] as List<String>? ?? [];
    final mood = userPreferences['mood'] as String? ?? 'neutral';

    // Get mood-specific genres
    final moodGenres = AIService.moodGenres[mood] ?? [];

    // Filter content based on preferences and theme
    final filteredContent = availableContent.where((content) {
      final contentGenres = content['genres'] as List<String>? ?? [];
      final contentArtist = content['artist'] as String? ?? '';
      
      // Check genre match
      final genreMatch = contentGenres.any((genre) => 
          preferredGenres.contains(genre) || moodGenres.contains(genre));
      
      // Check artist match
      final artistMatch = preferredArtists.contains(contentArtist);
      
      return genreMatch || artistMatch;
    }).toList();

    // Sort by rating and popularity
    filteredContent.sort((a, b) {
      final aRating = a['rating'] as double? ?? 0.0;
      final bRating = b['rating'] as double? ?? 0.0;
      final aViews = a['viewCount'] as int? ?? 0;
      final bViews = b['viewCount'] as int? ?? 0;
      
      final aScore = aRating + (aViews / 1000000.0);
      final bScore = bRating + (bViews / 1000000.0);
      
      return bScore.compareTo(aScore);
    });

    // Create themed playlist
    final playlistLength = min(20, filteredContent.length);
    for (int i = 0; i < playlistLength; i++) {
      playlist.add({
        ...filteredContent[i],
        'playlist_position': i + 1,
        'theme': playlistTheme,
      });
    }

    return playlist;
  }

  /// Process user feedback to improve recommendations
  void processFeedback(
    String userId,
    String contentId,
    double rating,
    String? feedback,
  ) {
    // Store feedback for model improvement
    final feedbackData = {
      'user_id': userId,
      'content_id': contentId,
      'rating': rating,
      'feedback': feedback,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // In a real implementation, this would update the ML model
    // For now, we'll store it for future processing
    _storeFeedback(feedbackData);
  }

  // Helper methods
  List<String> _tokenizeText(String text) {
    return text
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  String _determineMood(double sentimentScore) {
    if (sentimentScore > 0.3) return 'happy';
    if (sentimentScore > 0.1) return 'positive';
    if (sentimentScore < -0.3) return 'sad';
    if (sentimentScore < -0.1) return 'negative';
    return 'neutral';
  }

  String _getTimeOfDay(DateTime? timestamp) {
    if (timestamp == null) return 'unknown';
    final hour = timestamp.hour;
    if (hour >= 6 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 18) return 'afternoon';
    if (hour >= 18 && hour < 22) return 'evening';
    return 'night';
  }

  double _calculateTimeWeight(DateTime? timestamp) {
    if (timestamp == null) return 0.5;
    final now = DateTime.now();
    final diff = now.difference(timestamp).inDays;
    return max(0.1, 1.0 - (diff / 30.0)); // Decay over 30 days
  }

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

  void _storeFeedback(Map<String, dynamic> feedbackData) {
    // In a real implementation, this would store to a database
    // For now, we'll just log it
    print('Feedback stored: $feedbackData');
  }
}

/// Sentiment analysis result
class SentimentResult {
  final double score;
  final double confidence;
  final String mood;

  SentimentResult({
    required this.score,
    required this.confidence,
    required this.mood,
  });

  @override
  String toString() {
    return 'SentimentResult(score: $score, confidence: $confidence, mood: $mood)';
  }
}
