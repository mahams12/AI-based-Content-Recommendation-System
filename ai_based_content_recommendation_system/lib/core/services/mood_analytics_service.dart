import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for tracking and analyzing user mood patterns
class MoodAnalyticsService {
  static final MoodAnalyticsService _instance = MoodAnalyticsService._internal();
  factory MoodAnalyticsService() => _instance;
  MoodAnalyticsService._internal();

  static const String _moodDataKey = 'mood_analytics_data';
  static const String _moodHistoryKey = 'mood_history';

  /// Record a mood selection with timestamp and context
  Future<void> recordMoodSelection({
    required String userId,
    required String mood,
    String? context,
    Map<String, dynamic>? metadata,
  }) async {
    final moodEntry = MoodEntry(
      userId: userId,
      mood: mood,
      timestamp: DateTime.now(),
      context: context,
      metadata: metadata ?? {},
    );

    await _saveMoodEntry(moodEntry);
    await _updateAnalytics(moodEntry);
  }

  /// Get mood history for a user
  Future<List<MoodEntry>> getMoodHistory({
    required String userId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('${_moodHistoryKey}_$userId') ?? [];
    
    final entries = historyJson
        .map((json) => MoodEntry.fromJson(jsonDecode(json)))
        .where((entry) {
          if (startDate != null && entry.timestamp.isBefore(startDate)) return false;
          if (endDate != null && entry.timestamp.isAfter(endDate)) return false;
          return true;
        })
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return limit != null ? entries.take(limit).toList() : entries;
  }

  /// Get mood analytics for a user
  Future<MoodAnalytics> getMoodAnalytics({
    required String userId,
    int days = 30,
  }) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    
    final moodHistory = await getMoodHistory(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );

    return _calculateAnalytics(moodHistory, days);
  }

  /// Get mood insights and recommendations
  Future<MoodInsights> getMoodInsights({
    required String userId,
    int days = 7,
  }) async {
    final analytics = await getMoodAnalytics(userId: userId, days: days);
    return _generateInsights(analytics);
  }

  /// Get mood trend over time
  Future<List<MoodTrendPoint>> getMoodTrend({
    required String userId,
    int days = 30,
    String interval = 'daily', // daily, weekly, monthly
  }) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    
    final moodHistory = await getMoodHistory(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );

    return _calculateTrend(moodHistory, interval);
  }

  /// Get mood patterns by time of day
  Future<Map<String, List<String>>> getMoodPatternsByTime({
    required String userId,
    int days = 30,
  }) async {
    final moodHistory = await getMoodHistory(userId: userId);
    final patterns = <String, List<String>>{};

    for (final entry in moodHistory) {
      final hour = entry.timestamp.hour;
      String timeSlot;
      
      if (hour >= 6 && hour < 12) {
        timeSlot = 'morning';
      } else if (hour >= 12 && hour < 18) {
        timeSlot = 'afternoon';
      } else if (hour >= 18 && hour < 23) {
        timeSlot = 'evening';
      } else {
        timeSlot = 'night';
      }

      patterns[timeSlot] ??= [];
      patterns[timeSlot]!.add(entry.mood);
    }

    return patterns;
  }

  /// Get mood correlation with content consumption
  Future<Map<String, double>> getMoodContentCorrelation({
    required String userId,
    int days = 30,
  }) async {
    final moodHistory = await getMoodHistory(userId: userId);
    final correlations = <String, double>{};

    // Analyze mood patterns with content metadata
    for (final entry in moodHistory) {
      final metadata = entry.metadata;
      if (metadata.containsKey('content_genres')) {
        final genres = List<String>.from(metadata['content_genres']);
        for (final genre in genres) {
          correlations[genre] = (correlations[genre] ?? 0.0) + 1.0;
        }
      }
    }

    // Normalize correlations
    final total = correlations.values.fold(0.0, (a, b) => a + b);
    if (total > 0) {
      correlations.updateAll((key, value) => value / total);
    }

    return correlations;
  }

  /// Predict mood based on historical patterns
  Future<String> predictMood({
    required String userId,
    DateTime? targetTime,
  }) async {
    final target = targetTime ?? DateTime.now();
    final hour = target.hour;
    
    // Get mood patterns by time
    final patterns = await getMoodPatternsByTime(userId: userId);
    
    String timeSlot;
    if (hour >= 6 && hour < 12) {
      timeSlot = 'morning';
    } else if (hour >= 12 && hour < 18) {
      timeSlot = 'afternoon';
    } else if (hour >= 18 && hour < 23) {
      timeSlot = 'evening';
    } else {
      timeSlot = 'night';
    }

    final timeMoods = patterns[timeSlot] ?? [];
    if (timeMoods.isEmpty) return 'neutral';

    // Find most common mood for this time slot
    final moodCounts = <String, int>{};
    for (final mood in timeMoods) {
      moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
    }

    return moodCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get mood wellness score
  Future<double> getMoodWellnessScore({
    required String userId,
    int days = 7,
  }) async {
    final analytics = await getMoodAnalytics(userId: userId, days: days);
    
    // Calculate wellness based on mood distribution
    final positiveMoods = ['happy', 'energetic', 'relaxed', 'romantic', 'calm'];
    final negativeMoods = ['sad', 'angry'];
    
    double positiveScore = 0.0;
    double negativeScore = 0.0;
    
    for (final entry in analytics.moodDistribution.entries) {
      final mood = entry.key;
      final count = entry.value;
      
      if (positiveMoods.contains(mood)) {
        positiveScore += count;
      } else if (negativeMoods.contains(mood)) {
        negativeScore += count;
      }
    }
    
    final total = positiveScore + negativeScore;
    if (total == 0) return 0.5; // Neutral score
    
    return (positiveScore / total).clamp(0.0, 1.0);
  }

  /// Export mood data for analysis
  Future<Map<String, dynamic>> exportMoodData({
    required String userId,
    int days = 30,
  }) async {
    final moodHistory = await getMoodHistory(userId: userId);
    final analytics = await getMoodAnalytics(userId: userId, days: days);
    final insights = await getMoodInsights(userId: userId, days: days);
    final trends = await getMoodTrend(userId: userId, days: days);
    final patterns = await getMoodPatternsByTime(userId: userId, days: days);
    final wellnessScore = await getMoodWellnessScore(userId: userId, days: days);

    return {
      'userId': userId,
      'exportDate': DateTime.now().toIso8601String(),
      'period': '$days days',
      'moodHistory': moodHistory.map((e) => e.toJson()).toList(),
      'analytics': analytics.toJson(),
      'insights': insights.toJson(),
      'trends': trends.map((t) => t.toJson()).toList(),
      'patterns': patterns,
      'wellnessScore': wellnessScore,
    };
  }

  // Private methods

  Future<void> _saveMoodEntry(MoodEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_moodHistoryKey}_${entry.userId}';
    final historyJson = prefs.getStringList(key) ?? [];
    
    historyJson.insert(0, jsonEncode(entry.toJson()));
    
    // Keep only last 1000 entries
    if (historyJson.length > 1000) {
      historyJson.removeRange(1000, historyJson.length);
    }
    
    await prefs.setStringList(key, historyJson);
  }

  Future<void> _updateAnalytics(MoodEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_moodDataKey}_${entry.userId}';
    final analyticsJson = prefs.getString(key);
    
    MoodAnalytics analytics;
    if (analyticsJson != null) {
      analytics = MoodAnalytics.fromJson(jsonDecode(analyticsJson));
    } else {
      analytics = MoodAnalytics(
        userId: entry.userId,
        totalMoods: 0,
        moodDistribution: {},
        averageMoodsPerDay: 0.0,
        mostCommonMood: 'neutral',
        moodTrend: 'stable',
        lastUpdated: DateTime.now(),
      );
    }
    
    // Update analytics
    final updatedDistribution = Map<String, int>.from(analytics.moodDistribution);
    updatedDistribution[entry.mood] = (updatedDistribution[entry.mood] ?? 0) + 1;
    
    // Update most common mood
    final mostCommonMood = updatedDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    final updatedAnalytics = MoodAnalytics(
      userId: analytics.userId,
      totalMoods: analytics.totalMoods + 1,
      moodDistribution: updatedDistribution,
      averageMoodsPerDay: analytics.averageMoodsPerDay,
      mostCommonMood: mostCommonMood,
      moodTrend: analytics.moodTrend,
      lastUpdated: DateTime.now(),
    );
    
    await prefs.setString(key, jsonEncode(updatedAnalytics.toJson()));
  }

  MoodAnalytics _calculateAnalytics(List<MoodEntry> moodHistory, int days) {
    if (moodHistory.isEmpty) {
      return MoodAnalytics(
        userId: '',
        totalMoods: 0,
        moodDistribution: {},
        averageMoodsPerDay: 0.0,
        mostCommonMood: 'neutral',
        moodTrend: 'stable',
        lastUpdated: DateTime.now(),
      );
    }

    final moodCounts = <String, int>{};
    for (final entry in moodHistory) {
      moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
    }

    final totalMoods = moodHistory.length;
    final averageMoodsPerDay = totalMoods / days;
    
    final mostCommonMood = moodCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // Calculate trend (simplified)
    String moodTrend = 'stable';
    if (moodHistory.length >= 2) {
      final recentMoods = moodHistory.take(5).map((e) => e.mood).toList();
      final olderMoods = moodHistory.skip(5).take(5).map((e) => e.mood).toList();
      
      final recentPositive = recentMoods.where((m) => 
          ['happy', 'energetic', 'relaxed'].contains(m)).length;
      final olderPositive = olderMoods.where((m) => 
          ['happy', 'energetic', 'relaxed'].contains(m)).length;
      
      if (recentPositive > olderPositive) {
        moodTrend = 'improving';
      } else if (recentPositive < olderPositive) {
        moodTrend = 'declining';
      }
    }

    return MoodAnalytics(
      userId: moodHistory.first.userId,
      totalMoods: totalMoods,
      moodDistribution: moodCounts,
      averageMoodsPerDay: averageMoodsPerDay,
      mostCommonMood: mostCommonMood,
      moodTrend: moodTrend,
      lastUpdated: DateTime.now(),
    );
  }

  MoodInsights _generateInsights(MoodAnalytics analytics) {
    final insights = <String>[];
    final recommendations = <String>[];

    // Generate insights based on analytics
    if (analytics.mostCommonMood == 'happy') {
      insights.add('You tend to be in a positive mood most of the time!');
      recommendations.add('Keep doing what makes you happy');
    } else if (analytics.mostCommonMood == 'sad') {
      insights.add('You might be going through a difficult period');
      recommendations.add('Consider activities that boost your mood');
    } else if (analytics.mostCommonMood == 'energetic') {
      insights.add('You have high energy levels');
      recommendations.add('Channel this energy into productive activities');
    }

    if (analytics.moodTrend == 'improving') {
      insights.add('Your mood has been improving recently');
    } else if (analytics.moodTrend == 'declining') {
      insights.add('Your mood has been declining recently');
      recommendations.add('Consider seeking support or changing your routine');
    }

    if (analytics.averageMoodsPerDay > 3) {
      insights.add('You track your mood frequently, which is great for self-awareness');
    }

    return MoodInsights(
      insights: insights,
      recommendations: recommendations,
      generatedAt: DateTime.now(),
    );
  }

  List<MoodTrendPoint> _calculateTrend(List<MoodEntry> moodHistory, String interval) {
    final trendPoints = <MoodTrendPoint>[];
    
    if (moodHistory.isEmpty) return trendPoints;

    // Group by interval
    final grouped = <String, List<MoodEntry>>{};
    
    for (final entry in moodHistory) {
      String key;
      if (interval == 'daily') {
        key = '${entry.timestamp.year}-${entry.timestamp.month}-${entry.timestamp.day}';
      } else if (interval == 'weekly') {
        final weekStart = entry.timestamp.subtract(Duration(days: entry.timestamp.weekday - 1));
        key = '${weekStart.year}-${weekStart.month}-${weekStart.day}';
      } else {
        key = '${entry.timestamp.year}-${entry.timestamp.month}';
      }
      
      grouped[key] ??= [];
      grouped[key]!.add(entry);
    }

    // Calculate average mood score for each interval
    for (final entry in grouped.entries) {
      final moods = entry.value.map((e) => e.mood).toList();
      final moodScores = moods.map((mood) => _moodToScore(mood)).toList();
      final averageScore = moodScores.reduce((a, b) => a + b) / moodScores.length;
      
      trendPoints.add(MoodTrendPoint(
        date: DateTime.parse(entry.key),
        averageScore: averageScore,
        moodCount: moods.length,
        dominantMood: _getMostCommonMood(moods),
      ));
    }

    trendPoints.sort((a, b) => a.date.compareTo(b.date));
    return trendPoints;
  }

  double _moodToScore(String mood) {
    switch (mood) {
      case 'happy': return 5.0;
      case 'energetic': return 4.5;
      case 'romantic': return 4.0;
      case 'relaxed': return 3.5;
      case 'calm': return 3.0;
      case 'focused': return 3.0;
      case 'adventurous': return 4.0;
      case 'nostalgic': return 2.5;
      case 'neutral': return 2.5;
      case 'sad': return 1.5;
      case 'angry': return 1.0;
      default: return 2.5;
    }
  }

  String _getMostCommonMood(List<String> moods) {
    final counts = <String, int>{};
    for (final mood in moods) {
      counts[mood] = (counts[mood] ?? 0) + 1;
    }
    
    return counts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}

/// Mood entry data model
class MoodEntry {
  final String userId;
  final String mood;
  final DateTime timestamp;
  final String? context;
  final Map<String, dynamic> metadata;

  MoodEntry({
    required this.userId,
    required this.mood,
    required this.timestamp,
    this.context,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'mood': mood,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
      'metadata': metadata,
    };
  }

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      userId: json['userId'],
      mood: json['mood'],
      timestamp: DateTime.parse(json['timestamp']),
      context: json['context'],
      metadata: Map<String, dynamic>.from(json['metadata']),
    );
  }
}

/// Mood analytics data model
class MoodAnalytics {
  final String userId;
  final int totalMoods;
  final Map<String, int> moodDistribution;
  final double averageMoodsPerDay;
  final String mostCommonMood;
  final String moodTrend; // improving, declining, stable
  final DateTime lastUpdated;

  MoodAnalytics({
    required this.userId,
    required this.totalMoods,
    required this.moodDistribution,
    required this.averageMoodsPerDay,
    required this.mostCommonMood,
    required this.moodTrend,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalMoods': totalMoods,
      'moodDistribution': moodDistribution,
      'averageMoodsPerDay': averageMoodsPerDay,
      'mostCommonMood': mostCommonMood,
      'moodTrend': moodTrend,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory MoodAnalytics.fromJson(Map<String, dynamic> json) {
    return MoodAnalytics(
      userId: json['userId'],
      totalMoods: json['totalMoods'],
      moodDistribution: Map<String, int>.from(json['moodDistribution']),
      averageMoodsPerDay: json['averageMoodsPerDay'],
      mostCommonMood: json['mostCommonMood'],
      moodTrend: json['moodTrend'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}

/// Mood insights data model
class MoodInsights {
  final List<String> insights;
  final List<String> recommendations;
  final DateTime generatedAt;

  MoodInsights({
    required this.insights,
    required this.recommendations,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'insights': insights,
      'recommendations': recommendations,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory MoodInsights.fromJson(Map<String, dynamic> json) {
    return MoodInsights(
      insights: List<String>.from(json['insights']),
      recommendations: List<String>.from(json['recommendations']),
      generatedAt: DateTime.parse(json['generatedAt']),
    );
  }
}

/// Mood trend point data model
class MoodTrendPoint {
  final DateTime date;
  final double averageScore;
  final int moodCount;
  final String dominantMood;

  MoodTrendPoint({
    required this.date,
    required this.averageScore,
    required this.moodCount,
    required this.dominantMood,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'averageScore': averageScore,
      'moodCount': moodCount,
      'dominantMood': dominantMood,
    };
  }

  factory MoodTrendPoint.fromJson(Map<String, dynamic> json) {
    return MoodTrendPoint(
      date: DateTime.parse(json['date']),
      averageScore: json['averageScore'],
      moodCount: json['moodCount'],
      dominantMood: json['dominantMood'],
    );
  }
}

