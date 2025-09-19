import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/content_model.dart';
import '../models/api_response.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static Future<void> init() async {
    // Initialize any required services
  }

  // YouTube API Methods
  Future<ApiResponse<List<ContentItem>>> searchYouTubeContent({
    required String query,
    int maxResults = 20,
    String? categoryId,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.youtubeBaseUrl}/search').replace(
        queryParameters: {
          'part': 'snippet',
          'q': query,
          'maxResults': maxResults.toString(),
          'key': AppConstants.youtubeApiKey,
          'type': 'video',
          if (categoryId != null) 'videoCategoryId': categoryId,
        },
      );

      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = (data['items'] as List)
            .map((item) => ContentItem.fromYouTubeJson(item))
            .toList();
        
        return ApiResponse.success(items);
      } else {
        return ApiResponse.error('Failed to fetch YouTube content: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Error fetching YouTube content: $e');
    }
  }

  Future<ApiResponse<List<ContentItem>>> getYouTubeTrending({
    String regionCode = 'US',
    int maxResults = 20,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.youtubeBaseUrl}/videos').replace(
        queryParameters: {
          'part': 'snippet,statistics',
          'chart': 'mostPopular',
          'regionCode': regionCode,
          'maxResults': maxResults.toString(),
          'key': AppConstants.youtubeApiKey,
        },
      );

      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = (data['items'] as List)
            .map((item) => ContentItem.fromYouTubeTrendingJson(item))
            .toList();
        
        return ApiResponse.success(items);
      } else {
        return ApiResponse.error('Failed to fetch trending YouTube content: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Error fetching trending YouTube content: $e');
    }
  }

  // TMDB API Methods
  Future<ApiResponse<List<ContentItem>>> searchTMDBContent({
    required String query,
    String type = 'multi', // movie, tv, person, multi
    int page = 1,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.tmdbBaseUrl}/search/$type').replace(
        queryParameters: {
          'api_key': AppConstants.tmdbApiKey,
          'query': query,
          'page': page.toString(),
          'include_adult': 'false',
        },
      );

      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = (data['results'] as List)
            .map((item) => ContentItem.fromTMDBJson(item, type))
            .toList();
        
        return ApiResponse.success(items);
      } else {
        return ApiResponse.error('Failed to fetch TMDB content: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Error fetching TMDB content: $e');
    }
  }

  Future<ApiResponse<List<ContentItem>>> getTMDBTrending({
    String mediaType = 'all', // all, movie, tv, person
    String timeWindow = 'day', // day, week
    int page = 1,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.tmdbBaseUrl}/trending/$mediaType/$timeWindow').replace(
        queryParameters: {
          'api_key': AppConstants.tmdbApiKey,
          'page': page.toString(),
        },
      );

      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = (data['results'] as List)
            .map((item) => ContentItem.fromTMDBJson(item, mediaType))
            .toList();
        
        return ApiResponse.success(items);
      } else {
        return ApiResponse.error('Failed to fetch trending TMDB content: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Error fetching trending TMDB content: $e');
    }
  }

  Future<ApiResponse<List<ContentItem>>> getTMDBPopular({
    String type = 'movie', // movie, tv
    int page = 1,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.tmdbBaseUrl}/$type/popular').replace(
        queryParameters: {
          'api_key': AppConstants.tmdbApiKey,
          'page': page.toString(),
        },
      );

      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = (data['results'] as List)
            .map((item) => ContentItem.fromTMDBJson(item, type))
            .toList();
        
        return ApiResponse.success(items);
      } else {
        return ApiResponse.error('Failed to fetch popular TMDB content: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Error fetching popular TMDB content: $e');
    }
  }

  // Spotify API Methods (Mock implementation for web compatibility)
  Future<ApiResponse<List<ContentItem>>> searchSpotifyContent({
    required String query,
    String type = 'track', // track, album, artist, playlist
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // Mock implementation for web compatibility
      // In production, this would use Spotify Web API with OAuth
      return ApiResponse.success(_getMockSpotifyContent(query, type, limit));
    } catch (e) {
      return ApiResponse.error('Error fetching Spotify content: $e');
    }
  }

  Future<ApiResponse<List<ContentItem>>> getSpotifyFeaturedPlaylists({
    int limit = 20,
  }) async {
    try {
      // Mock implementation for web compatibility
      // In production, this would use Spotify Web API with OAuth
      return ApiResponse.success(_getMockSpotifyPlaylists(limit));
    } catch (e) {
      return ApiResponse.error('Error fetching Spotify playlists: $e');
    }
  }

  // Unified Search Method
  Future<ApiResponse<List<ContentItem>>> searchAllPlatforms({
    required String query,
    int maxResultsPerPlatform = 10,
  }) async {
    try {
      final results = <ContentItem>[];
      
      // Search YouTube
      final youtubeResult = await searchYouTubeContent(
        query: query,
        maxResults: maxResultsPerPlatform,
      );
      if (youtubeResult.isSuccess) {
        results.addAll(youtubeResult.data!);
      }
      
      // Search TMDB
      final tmdbResult = await searchTMDBContent(
        query: query,
        type: 'multi',
      );
      if (tmdbResult.isSuccess) {
        results.addAll(tmdbResult.data!.take(maxResultsPerPlatform));
      }
      
      // Search Spotify (mock for now)
      final spotifyResult = await searchSpotifyContent(
        query: query,
        type: 'track',
        limit: maxResultsPerPlatform,
      );
      if (spotifyResult.isSuccess) {
        results.addAll(spotifyResult.data!);
      }
      
      return ApiResponse.success(results);
    } catch (e) {
      return ApiResponse.error('Error searching all platforms: $e');
    }
  }

  // Get trending content from all platforms
  Future<ApiResponse<List<ContentItem>>> getTrendingContent({
    int maxResultsPerPlatform = 10,
  }) async {
    try {
      final results = <ContentItem>[];
      
      // Get YouTube trending
      final youtubeResult = await getYouTubeTrending(
        maxResults: maxResultsPerPlatform,
      );
      if (youtubeResult.isSuccess) {
        results.addAll(youtubeResult.data!);
      }
      
      // Get TMDB trending
      final tmdbResult = await getTMDBTrending(
        mediaType: 'all',
        timeWindow: 'day',
      );
      if (tmdbResult.isSuccess) {
        results.addAll(tmdbResult.data!.take(maxResultsPerPlatform));
      }
      
      // Get Spotify featured playlists (mock for now)
      final spotifyResult = await getSpotifyFeaturedPlaylists(
        limit: maxResultsPerPlatform,
      );
      if (spotifyResult.isSuccess) {
        results.addAll(spotifyResult.data!);
      }
      
      return ApiResponse.success(results);
    } catch (e) {
      return ApiResponse.error('Error fetching trending content: $e');
    }
  }

  // Mock Spotify data (Web-compatible implementation)
  List<ContentItem> _getMockSpotifyContent(String query, String type, int limit) {
    final mockTracks = [
      {
        'id': 'spotify_track_1',
        'name': 'Blinding Lights',
        'artists': [{'name': 'The Weeknd'}],
        'album': {'images': []},
        'external_urls': {'spotify': 'https://open.spotify.com/track/1'},
        'duration_ms': 200000,
        'popularity': 95,
      },
      {
        'id': 'spotify_track_2',
        'name': 'Watermelon Sugar',
        'artists': [{'name': 'Harry Styles'}],
        'album': {'images': []},
        'external_urls': {'spotify': 'https://open.spotify.com/track/2'},
        'duration_ms': 174000,
        'popularity': 88,
      },
      {
        'id': 'spotify_track_3',
        'name': 'Levitating',
        'artists': [{'name': 'Dua Lipa'}],
        'album': {'images': []},
        'external_urls': {'spotify': 'https://open.spotify.com/track/3'},
        'duration_ms': 203000,
        'popularity': 92,
      },
      {
        'id': 'spotify_track_4',
        'name': 'Good 4 U',
        'artists': [{'name': 'Olivia Rodrigo'}],
        'album': {'images': []},
        'external_urls': {'spotify': 'https://open.spotify.com/track/4'},
        'duration_ms': 178000,
        'popularity': 90,
      },
      {
        'id': 'spotify_track_5',
        'name': 'Stay',
        'artists': [{'name': 'The Kid LAROI'}, {'name': 'Justin Bieber'}],
        'album': {'images': []},
        'external_urls': {'spotify': 'https://open.spotify.com/track/5'},
        'duration_ms': 141000,
        'popularity': 94,
      },
    ];
    
    return mockTracks
        .where((track) => track['name'].toString().toLowerCase().contains(query.toLowerCase()))
        .take(limit)
        .map((track) => ContentItem.fromSpotifyJson(track))
        .toList();
  }

  List<ContentItem> _getMockSpotifyPlaylists(int limit) {
    final mockPlaylists = [
      {
        'id': 'spotify_playlist_1',
        'name': 'Today\'s Top Hits',
        'description': 'The most played songs right now',
        'images': [],
        'external_urls': {'spotify': 'https://open.spotify.com/playlist/1'},
        'tracks': {'total': 50},
      },
      {
        'id': 'spotify_playlist_2',
        'name': 'Discover Weekly',
        'description': 'Your weekly mixtape of fresh music',
        'images': [],
        'external_urls': {'spotify': 'https://open.spotify.com/playlist/2'},
        'tracks': {'total': 30},
      },
      {
        'id': 'spotify_playlist_3',
        'name': 'RapCaviar',
        'description': 'New music from Drake, Kendrick Lamar, Cardi B and more',
        'images': [],
        'external_urls': {'spotify': 'https://open.spotify.com/playlist/3'},
        'tracks': {'total': 60},
      },
      {
        'id': 'spotify_playlist_4',
        'name': 'Rock Classics',
        'description': 'Rock legends & epic songs that continue to inspire generations',
        'images': [],
        'external_urls': {'spotify': 'https://open.spotify.com/playlist/4'},
        'tracks': {'total': 75},
      },
    ];
    
    return mockPlaylists
        .take(limit)
        .map((playlist) => ContentItem.fromSpotifyPlaylistJson(playlist))
        .toList();
  }
}
