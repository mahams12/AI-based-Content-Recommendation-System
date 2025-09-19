import 'dart:math';
import '../models/content_model.dart';
import 'ai_service.dart';

/// Content Analysis Service for extracting metadata and performing NLP
class ContentAnalysisService {
  static final ContentAnalysisService _instance = ContentAnalysisService._internal();
  factory ContentAnalysisService() => _instance;
  ContentAnalysisService._internal();

  final AIService _aiService = AIService();

  // Content feature extraction weights (for future use)
  // final Map<String, double> _featureWeights = {
  //   'title': 0.3,
  //   'description': 0.4,
  //   'genres': 0.2,
  //   'metadata': 0.1,
  // };

  // Genre mapping for better categorization
  final Map<String, List<String>> _genreMappings = {
    'Action': ['action', 'adventure', 'thriller', 'crime', 'war'],
    'Comedy': ['comedy', 'humor', 'funny', 'satire', 'parody'],
    'Drama': ['drama', 'emotional', 'serious', 'tragedy', 'melodrama'],
    'Horror': ['horror', 'scary', 'frightening', 'supernatural', 'ghost'],
    'Romance': ['romance', 'love', 'romantic', 'relationship', 'dating'],
    'Sci-Fi': ['sci-fi', 'science fiction', 'futuristic', 'space', 'alien'],
    'Fantasy': ['fantasy', 'magic', 'supernatural', 'mythical', 'enchanted'],
    'Documentary': ['documentary', 'educational', 'informative', 'factual'],
    'Music': ['music', 'song', 'album', 'concert', 'musical'],
    'Sports': ['sports', 'athletic', 'competition', 'game', 'fitness'],
  };

  /// Extract comprehensive content features
  Future<ContentFeatures> extractFeatures(ContentItem content) async {
    final features = ContentFeatures(
      id: content.id,
      title: content.title,
      description: content.description,
    );

    // Extract text features
    await _extractTextFeatures(content, features);
    
    // Extract genre features
    _extractGenreFeatures(content, features);
    
    // Extract temporal features
    _extractTemporalFeatures(content, features);
    
    // Extract popularity features
    _extractPopularityFeatures(content, features);
    
    // Extract audio/visual features
    _extractMediaFeatures(content, features);
    
    // Generate content embeddings
    await _generateContentEmbeddings(content, features);

    return features;
  }

  /// Analyze content similarity using multiple algorithms
  Future<double> calculateContentSimilarity(
    ContentItem contentA,
    ContentItem contentB,
  ) async {
    final featuresA = await extractFeatures(contentA);
    final featuresB = await extractFeatures(contentB);

    // Calculate different types of similarity
    final textSimilarity = _calculateTextSimilarity(featuresA, featuresB);
    final genreSimilarity = _calculateGenreSimilarity(featuresA, featuresB);
    final temporalSimilarity = _calculateTemporalSimilarity(featuresA, featuresB);
    final popularitySimilarity = _calculatePopularitySimilarity(featuresA, featuresB);

    // Weighted combination
    final totalSimilarity = (
      textSimilarity * 0.4 +
      genreSimilarity * 0.3 +
      temporalSimilarity * 0.2 +
      popularitySimilarity * 0.1
    );

    return totalSimilarity.clamp(0.0, 1.0);
  }

  /// Perform TF-IDF analysis on content descriptions
  Map<String, double> performTFIDFAnalysis(List<ContentItem> contentList) {
    final documents = contentList.map((c) => 
        '${c.title} ${c.description} ${c.genres.join(' ')}').toList();
    
    final allTerms = <String>{};
    final termFrequencies = <String, Map<String, int>>{};
    final documentFrequencies = <String, int>{};

    // Calculate term frequencies
    for (int i = 0; i < documents.length; i++) {
      final doc = documents[i];
      final terms = _tokenizeText(doc.toLowerCase());
      allTerms.addAll(terms);

      for (final term in terms) {
        termFrequencies[term] ??= <String, int>{};
        termFrequencies[term]![doc] = (termFrequencies[term]![doc] ?? 0) + 1;
      }
    }

    // Calculate document frequencies
    for (final term in allTerms) {
      documentFrequencies[term] = termFrequencies[term]!.length;
    }

    // Calculate TF-IDF scores
    final tfidfScores = <String, double>{};
    final totalDocs = documents.length;

    for (final term in allTerms) {
      double totalTfidf = 0.0;
      for (final doc in documents) {
        final tf = (termFrequencies[term]![doc] ?? 0) / 
                  _tokenizeText(doc.toLowerCase()).length;
        final idf = log(totalDocs / documentFrequencies[term]!);
        totalTfidf += tf * idf;
      }
      tfidfScores[term] = totalTfidf;
    }

    return tfidfScores;
  }

  /// Generate Word2Vec-like embeddings for content
  Map<String, List<double>> generateContentEmbeddings(List<ContentItem> contentList) {
    final documents = contentList.map((c) => 
        '${c.title} ${c.description} ${c.genres.join(' ')}').toList();
    
    return _aiService.generateWordEmbeddings(documents);
  }

  /// Analyze content sentiment and emotional tone
  Future<ContentSentiment> analyzeContentSentiment(ContentItem content) async {
    final text = '${content.title} ${content.description}';
    final sentimentResult = await _aiService.analyzeSentiment(text);
    
    // Analyze emotional tone based on content metadata
    final emotionalTone = _analyzeEmotionalTone(content);
    
    return ContentSentiment(
      sentiment: sentimentResult,
      emotionalTone: emotionalTone,
      contentId: content.id,
    );
  }

  /// Extract key topics and themes from content
  List<String> extractTopics(ContentItem content) {
    final text = '${content.title} ${content.description}';
    final words = _tokenizeText(text.toLowerCase());
    
    // Topic extraction using keyword analysis
    final topics = <String>[];
    
    // Check for common topic keywords
    final topicKeywords = {
      'Technology': ['tech', 'computer', 'software', 'digital', 'ai', 'robot'],
      'Nature': ['nature', 'environment', 'wildlife', 'outdoor', 'landscape'],
      'Food': ['food', 'cooking', 'recipe', 'restaurant', 'chef', 'kitchen'],
      'Travel': ['travel', 'trip', 'vacation', 'destination', 'journey'],
      'Education': ['education', 'learning', 'school', 'university', 'study'],
      'Health': ['health', 'fitness', 'medical', 'wellness', 'exercise'],
      'Business': ['business', 'finance', 'economy', 'market', 'investment'],
      'Entertainment': ['entertainment', 'fun', 'party', 'celebration', 'festival'],
    };

    for (final topic in topicKeywords.keys) {
      final keywords = topicKeywords[topic]!;
      if (keywords.any((keyword) => words.contains(keyword))) {
        topics.add(topic);
      }
    }

    return topics;
  }

  /// Analyze content complexity and readability
  ContentComplexity analyzeComplexity(ContentItem content) {
    final text = '${content.title} ${content.description}';
    final words = _tokenizeText(text);
    final sentences = text.split(RegExp(r'[.!?]+')).where((s) => s.trim().isNotEmpty).toList();
    
    // Calculate readability metrics
    final avgWordsPerSentence = words.length / sentences.length;
    final avgSyllablesPerWord = _calculateAvgSyllables(words);
    
    // Flesch Reading Ease Score
    final fleschScore = 206.835 - (1.015 * avgWordsPerSentence) - (84.6 * avgSyllablesPerWord);
    
    // Determine complexity level
    String complexityLevel;
    if (fleschScore >= 80) {
      complexityLevel = 'Easy';
    } else if (fleschScore >= 60) {
      complexityLevel = 'Medium';
    } else if (fleschScore >= 30) {
      complexityLevel = 'Hard';
    } else {
      complexityLevel = 'Very Hard';
    }

    return ContentComplexity(
      fleschScore: fleschScore,
      avgWordsPerSentence: avgWordsPerSentence,
      avgSyllablesPerWord: avgSyllablesPerWord,
      complexityLevel: complexityLevel,
      wordCount: words.length,
      sentenceCount: sentences.length,
    );
  }

  /// Generate content recommendations based on analysis
  Future<List<ContentItem>> generateContentRecommendations(
    ContentItem seedContent,
    List<ContentItem> candidateContent,
    int maxRecommendations,
  ) async {
    final similarities = <MapEntry<ContentItem, double>>[];
    
    for (final candidate in candidateContent) {
      if (candidate.id != seedContent.id) {
        final similarity = await calculateContentSimilarity(seedContent, candidate);
        similarities.add(MapEntry(candidate, similarity));
      }
    }

    // Sort by similarity and return top recommendations
    similarities.sort((a, b) => b.value.compareTo(a.value));
    
    return similarities
        .take(maxRecommendations)
        .map((entry) => entry.key)
        .toList();
  }

  // Private helper methods
  Future<void> _extractTextFeatures(ContentItem content, ContentFeatures features) async {
    final text = '${content.title} ${content.description}';
    final words = _tokenizeText(text.toLowerCase());
    
    features.wordCount = words.length;
    features.uniqueWords = words.toSet().length;
    features.avgWordLength = words.fold(0, (sum, word) => sum + word.length) / words.length;
    
    // Extract sentiment
    final sentiment = await _aiService.analyzeSentiment(text);
    features.sentimentScore = sentiment.score;
    features.sentimentMood = sentiment.mood;
    
    // Extract topics
    features.topics = extractTopics(content);
    
    // Extract complexity
    features.complexity = analyzeComplexity(content);
  }

  void _extractGenreFeatures(ContentItem content, ContentFeatures features) {
    features.genres = content.genres;
    features.genreCount = content.genres.length;
    
    // Map genres to broader categories
    features.genreCategories = <String>[];
    for (final genre in content.genres) {
      for (final category in _genreMappings.keys) {
        if (_genreMappings[category]!.any((keyword) => 
            genre.toLowerCase().contains(keyword))) {
          if (!features.genreCategories.contains(category)) {
            features.genreCategories.add(category);
          }
        }
      }
    }
  }

  void _extractTemporalFeatures(ContentItem content, ContentFeatures features) {
    if (content.publishedAt != null) {
      final now = DateTime.now();
      final published = content.publishedAt!;
      
      features.publishDate = published;
      features.ageInDays = now.difference(published).inDays;
      features.isRecent = features.ageInDays <= 30;
      features.isTrending = features.ageInDays <= 7;
      
      // Extract time-based features
      features.publishHour = published.hour;
      features.publishDayOfWeek = published.weekday;
      features.publishMonth = published.month;
    }
  }

  void _extractPopularityFeatures(ContentItem content, ContentFeatures features) {
    features.rating = content.rating ?? 0.0;
    features.viewCount = content.viewCount ?? 0;
    features.likeCount = content.likeCount ?? 0;
    
    // Calculate popularity score
    final ratingWeight = 0.4;
    final viewWeight = 0.4;
    final likeWeight = 0.2;
    
    final normalizedViews = min(features.viewCount / 1000000.0, 1.0);
    final normalizedLikes = min(features.likeCount / 100000.0, 1.0);
    
    features.popularityScore = (
      features.rating * ratingWeight +
      normalizedViews * viewWeight +
      normalizedLikes * likeWeight
    );
  }

  void _extractMediaFeatures(ContentItem content, ContentFeatures features) {
    features.hasThumbnail = content.thumbnailUrl.isNotEmpty;
    features.hasVideo = content.videoUrl != null;
    features.hasAudio = content.audioUrl != null;
    features.duration = content.durationSeconds ?? 0;
    
    // Categorize by duration
    if (features.duration < 180) { // Less than 3 minutes
      features.durationCategory = 'Short';
    } else if (features.duration < 600) { // Less than 10 minutes
      features.durationCategory = 'Medium';
    } else if (features.duration < 3600) { // Less than 1 hour
      features.durationCategory = 'Long';
    } else {
      features.durationCategory = 'Very Long';
    }
  }

  Future<void> _generateContentEmbeddings(ContentItem content, ContentFeatures features) async {
    final text = '${content.title} ${content.description}';
    final embeddings = _aiService.generateWordEmbeddings([text]);
    
    // Average word embeddings to get content embedding
    if (embeddings.isNotEmpty) {
      final words = _tokenizeText(text.toLowerCase());
      final validWords = words.where((word) => embeddings.containsKey(word)).toList();
      
      if (validWords.isNotEmpty) {
        final embeddingSize = embeddings[validWords.first]!.length;
        final contentEmbedding = List<double>.filled(embeddingSize, 0.0);
        
        for (final word in validWords) {
          final wordEmbedding = embeddings[word]!;
          for (int i = 0; i < embeddingSize; i++) {
            contentEmbedding[i] += wordEmbedding[i];
          }
        }
        
        // Average the embeddings
        for (int i = 0; i < embeddingSize; i++) {
          contentEmbedding[i] /= validWords.length;
        }
        
        features.contentEmbedding = contentEmbedding;
      }
    }
  }

  double _calculateTextSimilarity(ContentFeatures featuresA, ContentFeatures featuresB) {
    if (featuresA.contentEmbedding == null || featuresB.contentEmbedding == null) {
      return 0.0;
    }

    final embeddingA = featuresA.contentEmbedding!;
    final embeddingB = featuresB.contentEmbedding!;
    
    if (embeddingA.length != embeddingB.length) {
      return 0.0;
    }

    // Calculate cosine similarity
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < embeddingA.length; i++) {
      dotProduct += embeddingA[i] * embeddingB[i];
      normA += embeddingA[i] * embeddingA[i];
      normB += embeddingB[i] * embeddingB[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  double _calculateGenreSimilarity(ContentFeatures featuresA, ContentFeatures featuresB) {
    final genresA = featuresA.genres.toSet();
    final genresB = featuresB.genres.toSet();
    
    if (genresA.isEmpty && genresB.isEmpty) return 1.0;
    if (genresA.isEmpty || genresB.isEmpty) return 0.0;
    
    final intersection = genresA.intersection(genresB).length;
    final union = genresA.union(genresB).length;
    
    return intersection / union; // Jaccard similarity
  }

  double _calculateTemporalSimilarity(ContentFeatures featuresA, ContentFeatures featuresB) {
    if (featuresA.publishDate == null || featuresB.publishDate == null) {
      return 0.5; // Neutral similarity if no date info
    }

    final dateA = featuresA.publishDate!;
    final dateB = featuresB.publishDate!;
    
    final diffInDays = (dateA.difference(dateB).inDays).abs();
    
    // Similarity decreases with time difference
    return exp(-diffInDays / 365.0); // Decay over a year
  }

  double _calculatePopularitySimilarity(ContentFeatures featuresA, ContentFeatures featuresB) {
    final scoreA = featuresA.popularityScore;
    final scoreB = featuresB.popularityScore;
    
    // Similarity based on how close popularity scores are
    final diff = (scoreA - scoreB).abs();
    return exp(-diff * 2); // Exponential decay
  }

  String _analyzeEmotionalTone(ContentItem content) {
    final text = '${content.title} ${content.description}'.toLowerCase();
    
    final emotionalKeywords = {
      'Energetic': ['exciting', 'energetic', 'dynamic', 'fast', 'intense'],
      'Calm': ['calm', 'peaceful', 'relaxing', 'serene', 'gentle'],
      'Dramatic': ['dramatic', 'intense', 'emotional', 'powerful', 'moving'],
      'Humorous': ['funny', 'comedy', 'humor', 'laugh', 'joke'],
      'Romantic': ['romantic', 'love', 'passion', 'intimate', 'sweet'],
      'Mysterious': ['mystery', 'mysterious', 'secret', 'hidden', 'unknown'],
      'Inspiring': ['inspiring', 'motivational', 'uplifting', 'encouraging'],
    };

    final toneScores = <String, int>{};
    
    for (final tone in emotionalKeywords.keys) {
      final keywords = emotionalKeywords[tone]!;
      int score = 0;
      for (final keyword in keywords) {
        score += keyword.allMatches(text).length;
      }
      toneScores[tone] = score;
    }

    if (toneScores.isEmpty) return 'Neutral';
    
    final maxTone = toneScores.entries.reduce((a, b) => a.value > b.value ? a : b);
    return maxTone.value > 0 ? maxTone.key : 'Neutral';
  }

  List<String> _tokenizeText(String text) {
    return text
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  double _calculateAvgSyllables(List<String> words) {
    if (words.isEmpty) return 0.0;
    
    int totalSyllables = 0;
    for (final word in words) {
      totalSyllables += _countSyllables(word);
    }
    
    return totalSyllables / words.length;
  }

  int _countSyllables(String word) {
    word = word.toLowerCase();
    if (word.isEmpty) return 0;
    
    int syllables = 0;
    bool previousWasVowel = false;
    
    for (int i = 0; i < word.length; i++) {
      final char = word[i];
      final isVowel = 'aeiouy'.contains(char);
      
      if (isVowel && !previousWasVowel) {
        syllables++;
      }
      previousWasVowel = isVowel;
    }
    
    // Handle silent 'e'
    if (word.endsWith('e') && syllables > 1) {
      syllables--;
    }
    
    return max(1, syllables);
  }
}

/// Content features extracted from analysis
class ContentFeatures {
  final String id;
  final String title;
  final String description;
  
  // Text features
  int wordCount = 0;
  int uniqueWords = 0;
  double avgWordLength = 0.0;
  double sentimentScore = 0.0;
  String sentimentMood = 'neutral';
  List<String> topics = [];
  ContentComplexity? complexity;
  
  // Genre features
  List<String> genres = [];
  int genreCount = 0;
  List<String> genreCategories = [];
  
  // Temporal features
  DateTime? publishDate;
  int ageInDays = 0;
  bool isRecent = false;
  bool isTrending = false;
  int publishHour = 0;
  int publishDayOfWeek = 0;
  int publishMonth = 0;
  
  // Popularity features
  double rating = 0.0;
  int viewCount = 0;
  int likeCount = 0;
  double popularityScore = 0.0;
  
  // Media features
  bool hasThumbnail = false;
  bool hasVideo = false;
  bool hasAudio = false;
  int duration = 0;
  String durationCategory = 'Unknown';
  
  // Embeddings
  List<double>? contentEmbedding;

  ContentFeatures({
    required this.id,
    required this.title,
    required this.description,
  });
}

/// Content sentiment analysis result
class ContentSentiment {
  final SentimentResult sentiment;
  final String emotionalTone;
  final String contentId;

  ContentSentiment({
    required this.sentiment,
    required this.emotionalTone,
    required this.contentId,
  });
}

/// Content complexity analysis result
class ContentComplexity {
  final double fleschScore;
  final double avgWordsPerSentence;
  final double avgSyllablesPerWord;
  final String complexityLevel;
  final int wordCount;
  final int sentenceCount;

  ContentComplexity({
    required this.fleschScore,
    required this.avgWordsPerSentence,
    required this.avgSyllablesPerWord,
    required this.complexityLevel,
    required this.wordCount,
    required this.sentenceCount,
  });
}
