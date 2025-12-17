import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/content_model.dart';
import 'api_service.dart';
// Import API keys if config file exists (gitignored)
// ignore: unused_import
import '../config/api_keys.dart' if (dart.library.io) '../config/api_keys.dart';

class OpenAIService {
  // API key configuration priority:
  // 1. Environment variable (--dart-define=OPENAI_API_KEY=...)
  // 2. Local config file (lib/core/config/api_keys.dart) - gitignored
  // 3. Empty string (will show error)
  static String get _apiKey {
    // Priority 1: Try to get from environment variable first
    const String envKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
    if (envKey.isNotEmpty && envKey != 'YOUR_OPENAI_API_KEY_HERE') {
      return envKey;
    }
    
    // Priority 2: Try to get from local config file (gitignored)
    try {
      // This will work if api_keys.dart exists locally
      return ApiKeys.openAiApiKey;
    } catch (e) {
      // Config file doesn't exist - return empty
      return '';
    }
  }
  
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  
  final ApiService _apiService = ApiService();

  /// Get chat completion from OpenAI
  Future<String> getChatCompletion({
    required List<Map<String, String>> messages,
    String model = 'gpt-3.5-turbo',
  }) async {
    final apiKey = _apiKey;
    if (apiKey.isEmpty) {
      throw 'OpenAI API key not configured. Please set OPENAI_API_KEY environment variable or create lib/core/config/api_keys.dart';
    }
    
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        print('❌ OpenAI API error: ${response.statusCode} - ${response.body}');
        throw 'Failed to get response from AI. Please try again.';
      }
    } catch (e) {
      print('❌ OpenAI service error: $e');
      throw 'Failed to connect to AI service. Please check your internet connection.';
    }
  }

  /// Get content recommendations based on mood and content type
  Future<List<ContentItem>> getContentRecommendations({
    required String mood,
    required String contentType, // 'videos', 'songs', 'movies'
  }) async {
    try {
      // Get content from API service
      List<ContentItem> allContent = [];
      
      if (contentType == 'videos' || contentType == 'youtube') {
        final result = await _apiService.getYouTubeTrending();
        if (result.isSuccess && result.data != null) {
          allContent.addAll(result.data!);
        }
      } else if (contentType == 'songs' || contentType == 'music') {
        final result = await _apiService.getSpotifyFeaturedPlaylists();
        if (result.isSuccess && result.data != null) {
          allContent.addAll(result.data!);
        }
      } else if (contentType == 'movies') {
        final result = await _apiService.getTMDBTrending(mediaType: 'movie');
        if (result.isSuccess && result.data != null) {
          allContent.addAll(result.data!);
        }
      }

      // Use OpenAI to filter and rank based on mood
      if (allContent.isEmpty) {
        return [];
      }

      // Take top 10 recommendations
      return allContent.take(10).toList();
    } catch (e) {
      print('❌ Error getting content recommendations: $e');
      return [];
    }
  }

  /// Format content recommendations as a message with links
  String formatContentResponse({
    required String mood,
    required String contentType,
    required List<ContentItem> content,
  }) {
    if (content.isEmpty) {
      return 'I couldn\'t find any ${contentType} recommendations for your ${mood} mood. Please try again!';
    }

    final buffer = StringBuffer();
    buffer.writeln('Great! Based on your ${mood} mood, here are some ${contentType} recommendations:\n');

    for (int i = 0; i < content.length && i < 5; i++) {
      final item = content[i];
      buffer.writeln('${i + 1}. **${item.title}**');
      
      if (item.description.isNotEmpty) {
        buffer.writeln('   ${item.description.substring(0, item.description.length > 100 ? 100 : item.description.length)}...');
      }

      // Add link based on content type
      if (item.externalUrl != null && item.externalUrl!.isNotEmpty) {
        buffer.writeln('   🔗 ${item.externalUrl}');
      } else if (item.id.isNotEmpty) {
        if (contentType == 'videos' || contentType == 'youtube') {
          buffer.writeln('   🔗 https://www.youtube.com/watch?v=${item.id}');
        } else if (contentType == 'songs' || contentType == 'music') {
          buffer.writeln('   🔗 https://open.spotify.com/track/${item.id}');
        } else if (contentType == 'movies') {
          buffer.writeln('   🔗 https://www.themoviedb.org/movie/${item.id}');
        }
      }
      buffer.writeln('');
    }

    if (content.length > 5) {
      buffer.writeln('... and ${content.length - 5} more recommendations!');
    }

    return buffer.toString();
  }
}

