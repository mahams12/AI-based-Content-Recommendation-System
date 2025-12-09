import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/content_model.dart';
import '../constants/app_constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static late SharedPreferences _prefs;
  static late Box _contentBox;
  static late Box _userBox;
  static late Box _interactionBox;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Initialize Hive boxes (skip on web)
    if (!kIsWeb) {
      _contentBox = await Hive.openBox('content_cache');
      _userBox = await Hive.openBox('user_data');
      _interactionBox = await Hive.openBox('user_interactions');
    }
  }

  // SharedPreferences methods
  static Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  static String? getString(String key) {
    return _prefs.getString(key);
  }

  static Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  static Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  static int? getInt(String key) {
    return _prefs.getInt(key);
  }

  static Future<void> setDouble(String key, double value) async {
    await _prefs.setDouble(key, value);
  }

  static double? getDouble(String key) {
    return _prefs.getDouble(key);
  }

  static Future<void> setStringList(String key, List<String> value) async {
    await _prefs.setStringList(key, value);
  }

  static List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }

  static Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  static Future<void> clear() async {
    await _prefs.clear();
  }

  // Content caching methods (Web-compatible)
  static Future<void> cacheContent(String key, List<ContentItem> content) async {
    if (kIsWeb) {
      // Use SharedPreferences for web
      final contentJson = content.map((item) => item.toJson()).toList();
      await _prefs.setString(key, jsonEncode(contentJson));
      await _prefs.setInt('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
    } else {
      // Use Hive for mobile
      final contentJson = content.map((item) => item.toJson()).toList();
      await _contentBox.put(key, jsonEncode(contentJson));
      await _contentBox.put('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
    }
  }

  static List<ContentItem>? getCachedContent(String key) {
    String? contentJson;
    int? timestamp;
    
    if (kIsWeb) {
      // Use SharedPreferences for web
      contentJson = _prefs.getString(key);
      timestamp = _prefs.getInt('${key}_timestamp');
    } else {
      // Use Hive for mobile
      contentJson = _contentBox.get(key);
      timestamp = _contentBox.get('${key}_timestamp') as int?;
    }
    
    if (timestamp == null) return null;

    // Check if cache is expired (24 hours)
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    if (now.difference(cacheTime).inHours > AppConstants.cacheExpirationHours) {
      if (kIsWeb) {
        _prefs.remove(key);
        _prefs.remove('${key}_timestamp');
      } else {
        _contentBox.delete(key);
        _contentBox.delete('${key}_timestamp');
      }
      return null;
    }
    
    try {
      if (contentJson == null) return null;
      final List<dynamic> contentList = jsonDecode(contentJson);
      return contentList.map((json) => ContentItemJson.fromJson(json)).toList();
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearContentCache() async {
    if (!kIsWeb) {
      await _contentBox.clear();
    }
  }

  // User data methods (Web-compatible)
  static Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    if (kIsWeb) {
      await _prefs.setString('preferences', jsonEncode(preferences));
    } else {
      await _userBox.put('preferences', jsonEncode(preferences));
    }
  }

  static Map<String, dynamic>? getUserPreferences() {
    String? preferencesJson;
    if (kIsWeb) {
      preferencesJson = _prefs.getString('preferences');
    } else {
      preferencesJson = _userBox.get('preferences');
    }
    
    try {
      if (preferencesJson == null) return null;
      return jsonDecode(preferencesJson);
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveUserMood(String mood) async {
    if (kIsWeb) {
      await _prefs.setString('current_mood', mood);
      await _prefs.setInt('mood_timestamp', DateTime.now().millisecondsSinceEpoch);
    } else {
      await _userBox.put('current_mood', mood);
      await _userBox.put('mood_timestamp', DateTime.now().millisecondsSinceEpoch);
    }
  }

  static String? getCurrentMood() {
    if (kIsWeb) {
      return _prefs.getString('current_mood');
    } else {
      return _userBox.get('current_mood');
    }
  }

  static Future<void> saveUserHistory(List<String> contentIds) async {
    if (kIsWeb) {
      await _prefs.setStringList('history', contentIds);
    } else {
      await _userBox.put('history', contentIds);
    }
  }

  static List<String>? getUserHistory() {
    if (kIsWeb) {
      return _prefs.getStringList('history');
    } else {
      final history = _userBox.get('history');
      if (history is List) {
        return history.cast<String>();
      }
      return null;
    }
  }

  // User interaction methods (Web-compatible)
  static Future<void> recordInteraction({
    required String contentId,
    required String action, // view, like, skip, share
    int? duration,
    double? sentimentScore,
  }) async {
    final interaction = {
      'contentId': contentId,
      'action': action,
      'duration': duration,
      'sentimentScore': sentimentScore,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    if (kIsWeb) {
      final interactionsJson = _prefs.getString('interactions') ?? '[]';
      final interactions = (jsonDecode(interactionsJson) as List).cast<Map<String, dynamic>>();
      interactions.add(interaction);

      // Keep only last 1000 interactions
      if (interactions.length > 1000) {
        interactions.removeRange(0, interactions.length - 1000);
      }

      await _prefs.setString('interactions', jsonEncode(interactions));
    } else {
      final interactions = _interactionBox.get('interactions', defaultValue: <Map>[]) as List;
      interactions.add(interaction);

      // Keep only last 1000 interactions
      if (interactions.length > 1000) {
        interactions.removeRange(0, interactions.length - 1000);
      }

      await _interactionBox.put('interactions', interactions);
    }
  }

  static List<Map<String, dynamic>> getUserInteractions() {
    if (kIsWeb) {
      final interactionsJson = _prefs.getString('interactions') ?? '[]';
      return (jsonDecode(interactionsJson) as List).cast<Map<String, dynamic>>();
    } else {
      final interactions = _interactionBox.get('interactions', defaultValue: <Map>[]) as List;
      return interactions.cast<Map<String, dynamic>>();
    }
  }

  static Future<void> clearUserInteractions() async {
    if (kIsWeb) {
      await _prefs.remove('interactions');
    } else {
      await _interactionBox.clear();
    }
  }

  // Search history
  static Future<void> saveSearchHistory(List<String> searches) async {
    await setStringList('search_history', searches);
  }

  static List<String>? getSearchHistory() {
    return getStringList('search_history');
  }

  static Future<void> addToSearchHistory(String search) async {
    final history = getSearchHistory() ?? [];
    history.remove(search); // Remove if already exists
    history.insert(0, search); // Add to beginning
    if (history.length > 20) {
      history.removeRange(20, history.length); // Keep only last 20
    }
    await saveSearchHistory(history);
  }

  // App settings (Web-compatible)
  static Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    if (kIsWeb) {
      await _prefs.setString('app_settings', jsonEncode(settings));
    } else {
      await _userBox.put('app_settings', jsonEncode(settings));
    }
  }

  static Map<String, dynamic>? getAppSettings() {
    String? settingsJson;
    if (kIsWeb) {
      settingsJson = _prefs.getString('app_settings');
    } else {
      settingsJson = _userBox.get('app_settings');
    }
    
    try {
      if (settingsJson == null) return null;
      return jsonDecode(settingsJson);
    } catch (e) {
      return null;
    }
  }

  // Clear all data (Web-compatible)
  static Future<void> clearAllData() async {
    await clear();
    if (!kIsWeb) {
      await _contentBox.clear();
      await _userBox.clear();
      await _interactionBox.clear();
    }
  }

  // Get cache size (Web-compatible)
  static int getCacheSize() {
    if (kIsWeb) {
      return 0; // Not applicable for web
    } else {
      return _contentBox.length;
    }
  }

  // Clean old cache entries (Web-compatible)
  static Future<void> cleanOldCache() async {
    if (kIsWeb) {
      // For web, we'll clean SharedPreferences cache
      final keys = _prefs.getKeys();
      final now = DateTime.now();

      for (final key in keys) {
        if (key.endsWith('_timestamp')) {
          final timestamp = _prefs.getInt(key);
          if (timestamp != null) {
            final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
            if (now.difference(cacheTime).inHours > AppConstants.cacheExpirationHours) {
              final contentKey = key.replaceAll('_timestamp', '');
              await _prefs.remove(contentKey);
              await _prefs.remove(key);
            }
          }
        }
      }
    } else {
      final keys = _contentBox.keys.toList();
      final now = DateTime.now();

      for (final key in keys) {
        if (key.toString().endsWith('_timestamp')) {
          final timestamp = _contentBox.get(key) as int?;
          if (timestamp != null) {
            final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
            if (now.difference(cacheTime).inHours > AppConstants.cacheExpirationHours) {
              final contentKey = key.toString().replaceAll('_timestamp', '');
              await _contentBox.delete(contentKey);
              await _contentBox.delete(key);
            }
          }
        }
      }
    }
  }
}

// Extension to add fromJson method to ContentItem
extension ContentItemJson on ContentItem {
  static ContentItem fromJson(Map<String, dynamic> json) {
    return ContentItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      videoUrl: json['videoUrl'],
      audioUrl: json['audioUrl'],
      externalUrl: json['externalUrl'],
      platform: ContentType.values.firstWhere(
        (e) => e.name == json['platform'],
        orElse: () => ContentType.youtube,
      ),
      category: ContentCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ContentCategory.video,
      ),
      genres: List<String>.from(json['genres'] ?? []),
      duration: json['duration'],
      durationSeconds: json['durationSeconds'],
      rating: json['rating']?.toDouble(),
      viewCount: json['viewCount'],
      likeCount: json['likeCount'],
      publishedAt: json['publishedAt'] != null 
          ? DateTime.tryParse(json['publishedAt']) 
          : null,
      channelName: json['channelName'],
      artistName: json['artistName'],
      albumName: json['albumName'],
      metadata: json['metadata'],
    );
  }
}
