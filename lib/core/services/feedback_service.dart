import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_model.dart';
import 'ai_service.dart';

/// Feedback Service for collecting user interactions and improving recommendations
class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  final AIService _aiService = AIService();

  // Storage keys
  static const String _userInteractionsKey = 'user_interactions';
  static const String _userPreferencesKey = 'user_preferences';
  static const String _feedbackDataKey = 'feedback_data';
  static const String _modelMetricsKey = 'model_metrics';

  /// Record user interaction with content
  Future<void> recordInteraction({
    required String userId,
    required String contentId,
    required InteractionType type,
    Map<String, dynamic>? metadata,
  }) async {
    final interaction = UserInteraction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      contentId: contentId,
      type: type,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );

    await _storeInteraction(interaction);
    await _updateUserPreferences(userId, interaction);
  }

  /// Record explicit feedback (ratings, likes, dislikes)
  Future<void> recordFeedback({
    required String userId,
    required String contentId,
    required FeedbackType type,
    required double value,
    String? comment,
    Map<String, dynamic>? context,
  }) async {
    final feedback = UserFeedback(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      contentId: contentId,
      type: type,
      value: value,
      comment: comment,
      timestamp: DateTime.now(),
      context: context ?? {},
    );

    await _storeFeedback(feedback);
    await _processFeedbackForModelImprovement(feedback);
  }

  /// Record content consumption (play, watch, listen)
  Future<void> recordConsumption({
    required String userId,
    required ContentItem content,
    required Duration duration,
    double completionPercentage = 0.0,
    Map<String, dynamic>? context,
  }) async {
    // Record the consumption interaction
    await recordInteraction(
      userId: userId,
      contentId: content.id,
      type: InteractionType.consume,
      metadata: {
        'duration': duration.inSeconds,
        'completion_percentage': completionPercentage,
        'content_type': content.category.name,
        'platform': content.platform.name,
        'context': context,
      },
    );

    // Calculate implicit rating based on consumption behavior
    final implicitRating = _calculateImplicitRating(duration, completionPercentage, content);
    
    if (implicitRating > 0) {
      await recordFeedback(
        userId: userId,
        contentId: content.id,
        type: FeedbackType.implicit_rating,
        value: implicitRating,
        context: {
          'duration': duration.inSeconds,
          'completion_percentage': completionPercentage,
          'source': 'consumption_behavior',
        },
      );
    }
  }

  /// Record search behavior
  Future<void> recordSearch({
    required String userId,
    required String query,
    List<ContentItem>? results,
    String? selectedContentId,
    Map<String, dynamic>? filters,
  }) async {
    await recordInteraction(
      userId: userId,
      contentId: 'search_${DateTime.now().millisecondsSinceEpoch}',
      type: InteractionType.search,
      metadata: {
        'query': query,
        'result_count': results?.length ?? 0,
        'selected_content_id': selectedContentId,
        'filters': filters,
        'search_timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Analyze search query for mood detection
    if (query.isNotEmpty) {
      final sentiment = await _aiService.analyzeSentiment(query);
      if (sentiment.confidence > 0.5) {
        await _updateUserMood(userId, sentiment.mood, sentiment.confidence);
      }
    }
  }

  /// Record mood selection
  Future<void> recordMoodSelection({
    required String userId,
    required String mood,
    double confidence = 1.0,
    Map<String, dynamic>? context,
  }) async {
    await recordInteraction(
      userId: userId,
      contentId: 'mood_${mood}_${DateTime.now().millisecondsSinceEpoch}',
      type: InteractionType.mood_selection,
      metadata: {
        'mood': mood,
        'confidence': confidence,
        'context': context,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    await _updateUserMood(userId, mood, confidence);
  }

  /// Get user interaction history
  Future<List<UserInteraction>> getUserInteractions({
    required String userId,
    int? limit,
    DateTime? since,
  }) async {
    final allInteractions = await _getAllInteractions();
    
    var userInteractions = allInteractions
        .where((interaction) => interaction.userId == userId)
        .toList();

    if (since != null) {
      userInteractions = userInteractions
          .where((interaction) => interaction.timestamp.isAfter(since))
          .toList();
    }

    // Sort by timestamp (newest first)
    userInteractions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (limit != null) {
      userInteractions = userInteractions.take(limit).toList();
    }

    return userInteractions;
  }

  /// Get user feedback history
  Future<List<UserFeedback>> getUserFeedback({
    required String userId,
    int? limit,
    DateTime? since,
  }) async {
    final allFeedback = await _getAllFeedback();
    
    var userFeedback = allFeedback
        .where((feedback) => feedback.userId == userId)
        .toList();

    if (since != null) {
      userFeedback = userFeedback
          .where((feedback) => feedback.timestamp.isAfter(since))
          .toList();
    }

    // Sort by timestamp (newest first)
    userFeedback.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (limit != null) {
      userFeedback = userFeedback.take(limit).toList();
    }

    return userFeedback;
  }

  /// Get user preferences
  Future<Map<String, dynamic>> getUserPreferences(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final preferencesJson = prefs.getString('${_userPreferencesKey}_$userId');
    
    if (preferencesJson != null) {
      return jsonDecode(preferencesJson);
    }
    
    return {};
  }

  /// Update user preferences based on interactions
  Future<void> _updateUserPreferences(String userId, UserInteraction interaction) async {
    final currentPreferences = await getUserPreferences(userId);
    
    // Update preferences based on interaction type
    switch (interaction.type) {
      case InteractionType.like:
        _updateGenrePreferences(currentPreferences, interaction, 1.0);
        _updateArtistPreferences(currentPreferences, interaction, 1.0);
        break;
      case InteractionType.dislike:
        _updateGenrePreferences(currentPreferences, interaction, -0.5);
        _updateArtistPreferences(currentPreferences, interaction, -0.5);
        break;
      case InteractionType.consume:
        _updateGenrePreferences(currentPreferences, interaction, 0.3);
        _updateArtistPreferences(currentPreferences, interaction, 0.3);
        break;
      case InteractionType.share:
        _updateGenrePreferences(currentPreferences, interaction, 0.8);
        _updateArtistPreferences(currentPreferences, interaction, 0.8);
        break;
      default:
        break;
    }

    // Update time-based preferences
    _updateTimeBasedPreferences(currentPreferences, interaction);

    // Save updated preferences
    await _saveUserPreferences(userId, currentPreferences);
  }

  /// Update user mood based on interactions and feedback
  Future<void> _updateUserMood(String userId, String mood, double confidence) async {
    final preferences = await getUserPreferences(userId);
    
    final moodHistory = preferences['mood_history'] as List<dynamic>? ?? [];
    moodHistory.add({
      'mood': mood,
      'confidence': confidence,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Keep only last 50 mood entries
    if (moodHistory.length > 50) {
      moodHistory.removeRange(0, moodHistory.length - 50);
    }

    preferences['mood_history'] = moodHistory;
    preferences['current_mood'] = mood;
    preferences['mood_confidence'] = confidence;

    await _saveUserPreferences(userId, preferences);
  }

  /// Process feedback for model improvement
  Future<void> _processFeedbackForModelImprovement(UserFeedback feedback) async {
    // Store feedback for batch processing
    final allFeedback = await _getAllFeedback();
    allFeedback.add(feedback);
    
    // Keep only last 1000 feedback entries
    if (allFeedback.length > 1000) {
      allFeedback.removeRange(0, allFeedback.length - 1000);
    }
    
    await _saveAllFeedback(allFeedback);

    // Update model metrics
    await _updateModelMetrics(feedback);

    // Trigger model retraining if enough new feedback
    if (allFeedback.length % 100 == 0) {
      await _triggerModelRetraining();
    }
  }

  /// Calculate implicit rating from consumption behavior
  double _calculateImplicitRating(Duration duration, double completionPercentage, ContentItem content) {
    double rating = 0.0;

    // Completion percentage weight (0-0.6)
    rating += completionPercentage * 0.6;

    // Duration weight based on content length (0-0.4)
    if (content.durationSeconds != null && content.durationSeconds! > 0) {
      final durationRatio = duration.inSeconds / content.durationSeconds!;
      rating += min(durationRatio, 1.0) * 0.4;
    }

    return rating.clamp(0.0, 1.0);
  }

  /// Update genre preferences
  void _updateGenrePreferences(Map<String, dynamic> preferences, UserInteraction interaction, double weight) {
    final genres = interaction.metadata['genres'] as List<String>?;
    if (genres == null) return;

    final genrePreferences = preferences['genres'] as Map<String, double>? ?? {};
    
    for (final genre in genres) {
      genrePreferences[genre] = (genrePreferences[genre] ?? 0.0) + weight;
    }

    preferences['genres'] = genrePreferences;
  }

  /// Update artist preferences
  void _updateArtistPreferences(Map<String, dynamic> preferences, UserInteraction interaction, double weight) {
    final artist = interaction.metadata['artist'] as String?;
    if (artist == null || artist.isEmpty) return;

    final artistPreferences = preferences['artists'] as Map<String, double>? ?? {};
    artistPreferences[artist] = (artistPreferences[artist] ?? 0.0) + weight;

    preferences['artists'] = artistPreferences;
  }

  /// Update time-based preferences
  void _updateTimeBasedPreferences(Map<String, dynamic> preferences, UserInteraction interaction) {
    final hour = interaction.timestamp.hour;
    final dayOfWeek = interaction.timestamp.weekday;
    
    final timePreferences = preferences['time_preferences'] as Map<String, dynamic>? ?? {};
    
    // Update hourly preferences
    final hourlyPrefs = timePreferences['hourly'] as Map<String, double>? ?? {};
    hourlyPrefs[hour.toString()] = (hourlyPrefs[hour.toString()] ?? 0.0) + 0.1;
    timePreferences['hourly'] = hourlyPrefs;
    
    // Update daily preferences
    final dailyPrefs = timePreferences['daily'] as Map<String, double>? ?? {};
    dailyPrefs[dayOfWeek.toString()] = (dailyPrefs[dayOfWeek.toString()] ?? 0.0) + 0.1;
    timePreferences['daily'] = dailyPrefs;
    
    preferences['time_preferences'] = timePreferences;
  }

  /// Update model metrics
  Future<void> _updateModelMetrics(UserFeedback feedback) async {
    final prefs = await SharedPreferences.getInstance();
    final metricsJson = prefs.getString(_modelMetricsKey);
    
    final metrics = metricsJson != null ? jsonDecode(metricsJson) : <String, dynamic>{
      'total_feedback': 0,
      'average_rating': 0.0,
      'feedback_by_type': <String, int>{},
      'accuracy_metrics': <String, double>{},
    };

    // Update total feedback count
    metrics['total_feedback'] = (metrics['total_feedback'] as int) + 1;

    // Update average rating
    final totalFeedback = metrics['total_feedback'] as int;
    final currentAvg = metrics['average_rating'] as double;
    final newAvg = ((currentAvg * (totalFeedback - 1)) + feedback.value) / totalFeedback;
    metrics['average_rating'] = newAvg;

    // Update feedback by type
    final feedbackByType = metrics['feedback_by_type'] as Map<String, int>;
    final typeKey = feedback.type.name;
    feedbackByType[typeKey] = (feedbackByType[typeKey] ?? 0) + 1;

    await prefs.setString(_modelMetricsKey, jsonEncode(metrics));
  }

  /// Trigger model retraining (placeholder for actual implementation)
  Future<void> _triggerModelRetraining() async {
    // In a real implementation, this would trigger model retraining
    // For now, we'll just log that retraining would be triggered
    print('Model retraining triggered - ${DateTime.now()}');
    
    // Update retraining timestamp
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_model_retraining', DateTime.now().toIso8601String());
  }

  /// Get model performance metrics
  Future<Map<String, dynamic>> getModelMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    final metricsJson = prefs.getString(_modelMetricsKey);
    
    if (metricsJson != null) {
      return jsonDecode(metricsJson);
    }
    
    return {
      'total_feedback': 0,
      'average_rating': 0.0,
      'feedback_by_type': <String, int>{},
      'accuracy_metrics': <String, double>{},
    };
  }

  /// Clear all user data (for privacy/GDPR compliance)
  Future<void> clearUserData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Clear user-specific data
    await prefs.remove('${_userPreferencesKey}_$userId');
    
    // Remove user interactions
    final allInteractions = await _getAllInteractions();
    final filteredInteractions = allInteractions
        .where((interaction) => interaction.userId != userId)
        .toList();
    await _saveAllInteractions(filteredInteractions);
    
    // Remove user feedback
    final allFeedback = await _getAllFeedback();
    final filteredFeedback = allFeedback
        .where((feedback) => feedback.userId != userId)
        .toList();
    await _saveAllFeedback(filteredFeedback);
  }

  // Storage methods
  Future<void> _storeInteraction(UserInteraction interaction) async {
    final allInteractions = await _getAllInteractions();
    allInteractions.add(interaction);
    await _saveAllInteractions(allInteractions);
  }

  Future<void> _storeFeedback(UserFeedback feedback) async {
    final allFeedback = await _getAllFeedback();
    allFeedback.add(feedback);
    await _saveAllFeedback(allFeedback);
  }

  Future<List<UserInteraction>> _getAllInteractions() async {
    final prefs = await SharedPreferences.getInstance();
    final interactionsJson = prefs.getString(_userInteractionsKey);
    
    if (interactionsJson != null) {
      final List<dynamic> interactionsList = jsonDecode(interactionsJson);
      return interactionsList.map((json) => UserInteraction.fromJson(json)).toList();
    }
    
    return [];
  }

  Future<List<UserFeedback>> _getAllFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    final feedbackJson = prefs.getString(_feedbackDataKey);
    
    if (feedbackJson != null) {
      final List<dynamic> feedbackList = jsonDecode(feedbackJson);
      return feedbackList.map((json) => UserFeedback.fromJson(json)).toList();
    }
    
    return [];
  }

  Future<void> _saveAllInteractions(List<UserInteraction> interactions) async {
    final prefs = await SharedPreferences.getInstance();
    final interactionsJson = jsonEncode(interactions.map((i) => i.toJson()).toList());
    await prefs.setString(_userInteractionsKey, interactionsJson);
  }

  Future<void> _saveAllFeedback(List<UserFeedback> feedback) async {
    final prefs = await SharedPreferences.getInstance();
    final feedbackJson = jsonEncode(feedback.map((f) => f.toJson()).toList());
    await prefs.setString(_feedbackDataKey, feedbackJson);
  }

  Future<void> _saveUserPreferences(String userId, Map<String, dynamic> preferences) async {
    final prefs = await SharedPreferences.getInstance();
    final preferencesJson = jsonEncode(preferences);
    await prefs.setString('${_userPreferencesKey}_$userId', preferencesJson);
  }
}

/// User interaction types
enum InteractionType {
  view,
  like,
  dislike,
  share,
  save,
  consume,
  search,
  mood_selection,
  skip,
  replay,
}

/// Feedback types
enum FeedbackType {
  explicit_rating,
  implicit_rating,
  like,
  dislike,
  share,
  comment,
  skip,
  completion,
}

/// User interaction model
class UserInteraction {
  final String id;
  final String userId;
  final String contentId;
  final InteractionType type;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  UserInteraction({
    required this.id,
    required this.userId,
    required this.contentId,
    required this.type,
    required this.timestamp,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'contentId': contentId,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory UserInteraction.fromJson(Map<String, dynamic> json) {
    return UserInteraction(
      id: json['id'],
      userId: json['userId'],
      contentId: json['contentId'],
      type: InteractionType.values.firstWhere((e) => e.name == json['type']),
      timestamp: DateTime.parse(json['timestamp']),
      metadata: Map<String, dynamic>.from(json['metadata']),
    );
  }
}

/// User feedback model
class UserFeedback {
  final String id;
  final String userId;
  final String contentId;
  final FeedbackType type;
  final double value;
  final String? comment;
  final DateTime timestamp;
  final Map<String, dynamic> context;

  UserFeedback({
    required this.id,
    required this.userId,
    required this.contentId,
    required this.type,
    required this.value,
    this.comment,
    required this.timestamp,
    required this.context,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'contentId': contentId,
      'type': type.name,
      'value': value,
      'comment': comment,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
    };
  }

  factory UserFeedback.fromJson(Map<String, dynamic> json) {
    return UserFeedback(
      id: json['id'],
      userId: json['userId'],
      contentId: json['contentId'],
      type: FeedbackType.values.firstWhere((e) => e.name == json['type']),
      value: json['value'].toDouble(),
      comment: json['comment'],
      timestamp: DateTime.parse(json['timestamp']),
      context: Map<String, dynamic>.from(json['context']),
    );
  }
}


