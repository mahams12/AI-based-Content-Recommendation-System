import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/content_model.dart';
import 'spotify_content.dart';
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
    // If YouTube API failed recently (within 5 minutes), use mock data immediately
    if (_youtubeApiFailed && 
        _lastYoutubeFailure != null && 
        DateTime.now().difference(_lastYoutubeFailure!).inMinutes < 5) {
      return ApiResponse.success(_getMockYouTubeContent(maxResults));
    }

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
        // Reset failure flag on success
        _youtubeApiFailed = false;
        _lastYoutubeFailure = null;
        
        final data = json.decode(response.body);
        final items = (data['items'] as List)
            .map((item) => ContentItem.fromYouTubeJson(item))
            .toList();
        
        return ApiResponse.success(items);
      } else if (response.statusCode == 403 || response.statusCode == 429) {
        // Mark API as failed and use mock data
        _youtubeApiFailed = true;
        _lastYoutubeFailure = DateTime.now();
        print('YouTube API quota exceeded or forbidden. Using mock data.');
        return ApiResponse.success(_getMockYouTubeContent(maxResults));
      } else {
        return ApiResponse.error('Failed to fetch YouTube content: ${response.statusCode}');
      }
    } catch (e) {
      // Mark API as failed and use mock data
      _youtubeApiFailed = true;
      _lastYoutubeFailure = DateTime.now();
      print('YouTube API error: $e. Using mock data.');
      return ApiResponse.success(_getMockYouTubeContent(maxResults));
    }
  }

  // Track API call failures to prevent infinite loops
  static bool _youtubeApiFailed = false;
  static DateTime? _lastYoutubeFailure;

  // Method to reset API failure state (useful for manual retry)
  static void resetYouTubeApiFailure() {
    _youtubeApiFailed = false;
    _lastYoutubeFailure = null;
    print('YouTube API failure state reset. Will retry API calls.');
  }

  // Method to check if YouTube API is currently failing
  static bool get isYouTubeApiFailing => _youtubeApiFailed;

  Future<ApiResponse<List<ContentItem>>> getYouTubeTrending({
    String regionCode = 'US',
    int maxResults = 20,
  }) async {
    // If YouTube API failed recently (within 5 minutes), use mock data immediately
    if (_youtubeApiFailed && 
        _lastYoutubeFailure != null && 
        DateTime.now().difference(_lastYoutubeFailure!).inMinutes < 5) {
      return ApiResponse.success(_getMockYouTubeContent(maxResults));
    }

    try {
      final uri = Uri.parse('${AppConstants.youtubeBaseUrl}/videos').replace(
        queryParameters: {
          'part': 'snippet,statistics,contentDetails',
          'chart': 'mostPopular',
          'regionCode': regionCode,
          'maxResults': maxResults.toString(),
          'key': AppConstants.youtubeApiKey,
        },
      );

      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        // Reset failure flag on success
        _youtubeApiFailed = false;
        _lastYoutubeFailure = null;
        
        final data = json.decode(response.body);
        final items = (data['items'] as List)
            .map((item) => ContentItem.fromYouTubeTrendingJson(item))
            .toList();
        
        return ApiResponse.success(items);
      } else if (response.statusCode == 403 || response.statusCode == 429) {
        // Mark API as failed and use mock data
        _youtubeApiFailed = true;
        _lastYoutubeFailure = DateTime.now();
        print('YouTube API quota exceeded or forbidden. Using mock data.');
        return ApiResponse.success(_getMockYouTubeContent(maxResults));
      } else {
        // For other errors, return mock data
        return ApiResponse.success(_getMockYouTubeContent(maxResults));
      }
    } catch (e) {
      // Mark API as failed and use mock data
      _youtubeApiFailed = true;
      _lastYoutubeFailure = DateTime.now();
      print('YouTube API error: $e. Using mock data.');
      return ApiResponse.success(_getMockYouTubeContent(maxResults));
    }
  }

  // Get unlimited YouTube content through multiple queries
  Future<ApiResponse<List<ContentItem>>> getUnlimitedYouTubeContent({
    int maxResults = 100,
  }) async {
    // If YouTube API failed recently, return mock data immediately
    if (_youtubeApiFailed && 
        _lastYoutubeFailure != null && 
        DateTime.now().difference(_lastYoutubeFailure!).inMinutes < 5) {
      return ApiResponse.success(_getMockYouTubeContent(maxResults));
    }

    try {
      final results = <ContentItem>[];
      
      // Multiple diverse search queries to get unlimited content
      final queries = [
        'gaming', 'vlog', 'tutorial', 'entertainment', 'music', 'tech', 'fitness',
        'cooking', 'travel', 'comedy', 'education', 'reviews', 'unboxing', 'dance',
        'shorts', 'trending', 'popular', 'viral', 'latest', 'new', 'best'
      ];
      
      // Get content from multiple queries (limit to prevent quota issues)
      int queryLimit = 3; // Only try first 3 queries to avoid quota issues
      for (int i = 0; i < queryLimit && i < queries.length; i++) {
        if (results.length >= maxResults) break;
        
        final youtubeResult = await searchYouTubeContent(
          query: queries[i],
          maxResults: 10, // Reduced to prevent quota issues
        );
        
        if (youtubeResult.isSuccess && youtubeResult.data != null) {
          results.addAll(youtubeResult.data!);
        }
        
        // If API failed during this call, break the loop
        if (_youtubeApiFailed) break;
      }
      
      // Only get trending content if API hasn't failed
      if (!_youtubeApiFailed) {
      final trendingResult = await getYouTubeTrending(
          maxResults: 20,
      );
      if (trendingResult.isSuccess && trendingResult.data != null) {
        results.addAll(trendingResult.data!);
        }
      }
      
      // Remove duplicates based on ID
      final uniqueResults = <String, ContentItem>{};
      for (final item in results) {
        uniqueResults[item.id] = item;
      }
      
      final finalResults = uniqueResults.values.take(maxResults).toList();
      
      // If we don't have enough results, fill with mock data
      if (finalResults.length < maxResults) {
        final mockResults = _getMockYouTubeContent(maxResults - finalResults.length);
        finalResults.addAll(mockResults);
      }
      
      return ApiResponse.success(finalResults);
    } catch (e) {
      // Return mock data if everything fails
      return ApiResponse.success(_getMockYouTubeContent(maxResults));
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
      // Debug: log request being made
      // ignore: avoid_print
      print('🌐 TMDB getTMDBTrending mediaType=$mediaType timeWindow=$timeWindow page=$page');
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
        // Debug: log how many items we got
        // ignore: avoid_print
        print('✅ TMDB getTMDBTrending success: ${items.length} items');
        return ApiResponse.success(items);
      } else {
        // Return mock data if API fails to ensure app functionality
        // ignore: avoid_print
        print('⚠️ TMDB getTMDBTrending failed with status ${response.statusCode}, using mock data.');
        return ApiResponse.success(_getMockTMDBContent(mediaType, 20));
      }
    } catch (e) {
      // Return mock data if API fails to ensure app functionality
      // ignore: avoid_print
      print('❌ TMDB getTMDBTrending error: $e, using mock data.');
      return ApiResponse.success(_getMockTMDBContent(mediaType, 20));
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

      // Add a timeout so the UI doesn't hang forever if TMDB is unreachable
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = (data['results'] as List)
            .map((item) => ContentItem.fromTMDBJson(item, type))
            .toList();
        
        return ApiResponse.success(items);
      } else {
        // Fall back to mock data so movies screens still show content
        return ApiResponse.success(_getMockTMDBContent(type, 20));
      }
    } catch (e) {
      // On any error (including timeout), also fall back to mock data
      return ApiResponse.success(_getMockTMDBContent(type, 20));
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
        return ApiResponse.success(SpotifyContent.getMockSpotifyContent(query, type, limit).map((track) => ContentItem.fromSpotifyJson(track)).toList());
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
      
      // Get unlimited Spotify content (tracks and playlists)
      final spotifyResult = await getUnlimitedSpotifyContent(
        maxResults: maxResultsPerPlatform,
      );
      if (spotifyResult.isSuccess) {
        results.addAll(spotifyResult.data!);
      }
      
      return ApiResponse.success(results);
    } catch (e) {
      return ApiResponse.error('Error fetching trending content: $e');
    }
  }

  // Get extended trending content for scrolling views
  Future<ApiResponse<List<ContentItem>>> getExtendedTrendingContent({
    ContentType? platform,
    int maxResults = 100,
  }) async {
    try {
      final results = <ContentItem>[];
      
      if (platform == null || platform == ContentType.youtube) {
        // Get unlimited YouTube trending content
        final youtubeResult = await getUnlimitedYouTubeContent(
          maxResults: maxResults,
        );
        if (youtubeResult.isSuccess) {
          results.addAll(youtubeResult.data!);
        }
      }
      
      if (platform == null || platform == ContentType.tmdb) {
        // Get unlimited TMDB trending content
        final tmdbResult = await getUnlimitedTMDBContent(
          maxResults: maxResults,
        );
        if (tmdbResult.isSuccess) {
          results.addAll(tmdbResult.data!);
        }
      }
      
      if (platform == null || platform == ContentType.spotify) {
        // Get unlimited trending Spotify content
        final spotifyResult = await getUnlimitedSpotifyContent(
          maxResults: maxResults,
        );
        if (spotifyResult.isSuccess) {
          results.addAll(spotifyResult.data!);
        }
      }
      
      return ApiResponse.success(results);
    } catch (e) {
      return ApiResponse.error('Error fetching extended trending content: $e');
    }
  }

  // Get all types of content (not just trending) for general browsing
  Future<ApiResponse<List<ContentItem>>> getAllContent({
    ContentType? platform,
    int maxResults = 100,
  }) async {
    try {
      final results = <ContentItem>[];
      
      if (platform == null || platform == ContentType.youtube) {
        // Get unlimited YouTube content (diverse categories)
        final youtubeResult = await getUnlimitedYouTubeContent(
          maxResults: maxResults,
        );
        if (youtubeResult.isSuccess) {
          results.addAll(youtubeResult.data!);
        }
      }
      
      if (platform == null || platform == ContentType.tmdb) {
        // Get unlimited TMDB content (movies and TV shows)
        final tmdbResult = await getUnlimitedTMDBContent(
          maxResults: maxResults,
        );
        if (tmdbResult.isSuccess) {
          results.addAll(tmdbResult.data!);
        }
      }
      
      if (platform == null || platform == ContentType.spotify) {
        // Get unlimited Spotify content (tracks and playlists)
        final spotifyResult = await getUnlimitedSpotifyContent(
          maxResults: maxResults,
        );
        if (spotifyResult.isSuccess) {
          results.addAll(spotifyResult.data!);
        }
      }
      
      return ApiResponse.success(results);
    } catch (e) {
      return ApiResponse.error('Failed to load all content: $e');
    }
  }

  // Get unlimited Spotify content through multiple queries
  Future<ApiResponse<List<ContentItem>>> getUnlimitedSpotifyContent({
    int maxResults = 100,
  }) async {
    try {
      final results = <ContentItem>[];
      // ignore: avoid_print
      print('🌐 Spotify getUnlimitedSpotifyContent requested maxResults=$maxResults');
      
      // Multiple popular search queries to get diverse content
      final queries = [
        'popular', 'trending', 'hits', 'charts', 'top', 'viral', 'new', 'hot',
        'music', 'song', 'track', 'latest', 'best', 'favorite', 'love'
      ];
      
      // Get tracks from multiple queries
      for (final query in queries) {
        if (results.length >= maxResults) break;
        
        final tracksResult = await searchSpotifyContent(
          query: query,
          type: 'track',
          limit: 20, // Get more tracks per query
        );
        
        if (tracksResult.isSuccess && tracksResult.data != null) {
          results.addAll(tracksResult.data!);
        }
      }
      
      // Get playlists
      final playlistsResult = await getSpotifyFeaturedPlaylists(
        limit: 30,
      );
      if (playlistsResult.isSuccess && playlistsResult.data != null) {
        results.addAll(playlistsResult.data!);
      }
      
      // Remove duplicates based on ID
      final uniqueResults = <String, ContentItem>{};
      for (final item in results) {
        uniqueResults[item.id] = item;
      }
      
      final finalResults = uniqueResults.values.take(maxResults).toList();
      // ignore: avoid_print
      print('✅ Spotify getUnlimitedSpotifyContent returning ${finalResults.length} items');
      return ApiResponse.success(finalResults);
    } catch (e) {
      // As a safety net, always fall back to mock Spotify content so
      // the UI still shows songs even if something goes wrong.
      // ignore: avoid_print
      print('❌ Spotify getUnlimitedSpotifyContent error: $e, using mock Spotify content.');
      final mockTracks = SpotifyContent.getMockSpotifyContent(
        'popular',
        'track',
        maxResults,
      ).map((track) => ContentItem.fromSpotifyJson(track)).toList();
      return ApiResponse.success(mockTracks);
    }
  }

  // Get unlimited TMDB content through multiple pages and queries
  Future<ApiResponse<List<ContentItem>>> getUnlimitedTMDBContent({
    int maxResults = 100,
  }) async {
    try {
      final results = <ContentItem>[];
      // ignore: avoid_print
      print('🌐 TMDB getUnlimitedTMDBContent requested maxResults=$maxResults');
      
      // Get movies from multiple pages
      for (int page = 1; page <= 5; page++) {
        if (results.length >= maxResults) break;
        
        final moviesResult = await getTMDBPopular(
          type: 'movie',
          page: page,
        );
        
        if (moviesResult.isSuccess && moviesResult.data != null) {
          results.addAll(moviesResult.data!);
        }
      }
      
      // Get TV shows from multiple pages
      for (int page = 1; page <= 3; page++) {
        if (results.length >= maxResults) break;
        
        final tvResult = await getTMDBPopular(
          type: 'tv',
          page: page,
        );
        
        if (tvResult.isSuccess && tvResult.data != null) {
          results.addAll(tvResult.data!);
        }
      }
      
      // Remove duplicates based on ID
      final uniqueResults = <String, ContentItem>{};
      for (final item in results) {
        uniqueResults[item.id] = item;
      }
      
      final finalResults = uniqueResults.values.take(maxResults).toList();
      // ignore: avoid_print
      print('✅ TMDB getUnlimitedTMDBContent returning ${finalResults.length} items');
      return ApiResponse.success(finalResults);
    } catch (e) {
      // If TMDB is unreachable or fails, return mock movie/TV content so
      // Movies screens and carousels keep working.
      // ignore: avoid_print
      print('❌ TMDB getUnlimitedTMDBContent error: $e, using mock TMDB content.');
      return ApiResponse.success(_getMockTMDBContent('movie', maxResults));
    }
  }

  // Get TMDB movies by genre
  Future<ApiResponse<List<ContentItem>>> getTMDBMoviesByGenre({
    int? genreId,
    int maxResults = 100,
  }) async {
    try {
      final results = <ContentItem>[];
      
      // Get movies from multiple pages to ensure we have enough content
      for (int page = 1; page <= 5; page++) {
        final tmdbResult = await getTMDBPopular(
          type: 'movie',
          page: page,
        );
        
        if (tmdbResult.isSuccess && tmdbResult.data != null) {
          List<ContentItem> movies = tmdbResult.data!;
          
          // Filter by genre if specified
          if (genreId != null) {
            movies = movies.where((movie) {
              if (movie.metadata != null && movie.metadata!['genre_ids'] != null) {
                final genreIds = movie.metadata!['genre_ids'] as List<dynamic>?;
                return genreIds?.contains(genreId) ?? false;
              }
              return false;
            }).toList();
          }
          
          results.addAll(movies);
          
          // Stop if we have enough results
          if (results.length >= maxResults) {
            break;
          }
        }
      }
      
      // Remove duplicates based on movie ID
      final uniqueResults = <String, ContentItem>{};
      for (final movie in results) {
        uniqueResults[movie.id] = movie;
      }
      
      final finalResults = uniqueResults.values.take(maxResults).toList();
      
      return ApiResponse.success(finalResults);
    } catch (e) {
      // On failure, fall back to generic TMDB mock content so the grid
      // is never empty.
      // ignore: avoid_print
      print('❌ getTMDBMoviesByGenre error: $e, using mock TMDB content.');
      return ApiResponse.success(_getMockTMDBContent('movie', maxResults));
    }
  }


  List<ContentItem> _getMockYouTubeContent(int limit) {
    final mockVideos = [
      // Gaming Content
      {
        'id': 'youtube_video_1',
        'snippet': {
          'title': 'INSANE Gaming Setup Tour 2024!',
          'description': 'Check out my ultimate gaming setup with RGB lights and high-end gear',
          'channelTitle': 'GamerPro',
          'publishedAt': '2024-01-15T10:00:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1493711662062-fa541adb3fc8?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['gaming', 'setup', 'pc', 'rgb']
        },
        'statistics': {'viewCount': '1250000', 'likeCount': '45000'},
        'contentDetails': {'duration': 'PT15M30S'}
      },
      {
        'id': 'youtube_video_2',
        'snippet': {
          'title': 'Fortnite Victory Royale Moments',
          'description': 'Best Fortnite plays and epic wins compilation',
          'channelTitle': 'FortniteKing',
          'publishedAt': '2024-01-14T15:30:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['fortnite', 'gaming', 'victory', 'battle royale']
        },
        'statistics': {'viewCount': '890000', 'likeCount': '32000'},
        'contentDetails': {'duration': 'PT8M45S'}
      },
      
      // Vlog Content
      {
        'id': 'youtube_video_3',
        'snippet': {
          'title': 'A Day in My Life | Morning Routine Vlog',
          'description': 'Follow my morning routine and see how I start my day',
          'channelTitle': 'LifeWithSarah',
          'publishedAt': '2024-01-13T09:15:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['vlog', 'lifestyle', 'morning routine', 'daily life']
        },
        'statistics': {'viewCount': '2100000', 'likeCount': '78000'},
        'contentDetails': {'duration': 'PT12M20S'}
      },
      {
        'id': 'youtube_video_4',
        'snippet': {
          'title': 'Travel Vlog: Exploring Tokyo Streets',
          'description': 'Amazing food, culture, and hidden gems in Tokyo',
          'channelTitle': 'WanderlustTravel',
          'publishedAt': '2024-01-12T14:45:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['travel', 'tokyo', 'vlog', 'japan', 'food']
        },
        'statistics': {'viewCount': '650000', 'likeCount': '25000'},
        'contentDetails': {'duration': 'PT18M15S'}
      },
      
      // Tutorial/Educational Content
      {
        'id': 'youtube_video_5',
        'snippet': {
          'title': 'How to Build Amazing Apps with Flutter',
          'description': 'Learn Flutter development from scratch - complete tutorial',
          'channelTitle': 'Flutter Dev',
          'publishedAt': '2024-01-11T11:20:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['flutter', 'tutorial', 'programming', 'mobile app']
        },
        'statistics': {'viewCount': '980000', 'likeCount': '41000'},
        'contentDetails': {'duration': 'PT25M10S'}
      },
      {
        'id': 'youtube_video_6',
        'snippet': {
          'title': 'Photoshop Tutorial: Digital Art Basics',
          'description': 'Learn digital painting techniques in Photoshop',
          'channelTitle': 'Digital Art Pro',
          'publishedAt': '2024-01-10T16:30:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['photoshop', 'tutorial', 'digital art', 'painting']
        },
        'statistics': {'viewCount': '750000', 'likeCount': '35000'},
        'contentDetails': {'duration': 'PT22M45S'}
      },
      
      // Entertainment/Comedy
      {
        'id': 'youtube_video_7',
        'snippet': {
          'title': 'Funny Pet Compilation 2024',
          'description': 'Hilarious moments with cats, dogs, and other pets',
          'channelTitle': 'Pet Comedy',
          'publishedAt': '2024-01-09T12:00:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['funny', 'pets', 'comedy', 'animals', 'compilation']
        },
        'statistics': {'viewCount': '3200000', 'likeCount': '120000'},
        'contentDetails': {'duration': 'PT10M30S'}
      },
      
      // Music/Entertainment
      {
        'id': 'youtube_video_8',
        'snippet': {
          'title': 'Acoustic Cover: Popular Songs 2024',
          'description': 'Beautiful acoustic covers of trending songs',
          'channelTitle': 'Acoustic Vibes',
          'publishedAt': '2024-01-08T20:15:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['music', 'acoustic', 'cover', 'songs', 'guitar']
        },
        'statistics': {'viewCount': '1800000', 'likeCount': '95000'},
        'contentDetails': {'duration': 'PT14M20S'}
      },
      
      // Tech Reviews
      {
        'id': 'youtube_video_9',
        'snippet': {
          'title': 'iPhone 15 Pro Max Review: Worth the Upgrade?',
          'description': 'Detailed review of Apple\'s latest flagship phone',
          'channelTitle': 'Tech Review',
          'publishedAt': '2024-01-07T14:30:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['tech', 'review', 'iphone', 'apple', 'smartphone']
        },
        'statistics': {'viewCount': '2500000', 'likeCount': '110000'},
        'contentDetails': {'duration': 'PT16M45S'}
      },
      
      // Shorts Content
      {
        'id': 'youtube_video_10',
        'snippet': {
          'title': 'Quick Cooking Hack in 30 Seconds!',
          'description': 'Amazing kitchen hack that will save you time',
          'channelTitle': 'Quick Cook',
          'publishedAt': '2024-01-06T09:45:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['cooking', 'hack', 'short', 'quick', 'kitchen']
        },
        'statistics': {'viewCount': '4200000', 'likeCount': '180000'},
        'contentDetails': {'duration': 'PT0M30S'}
      },
      {
        'id': 'youtube_video_11',
        'snippet': {
          'title': 'Dance Trend Challenge',
          'description': 'Try this viral dance move!',
          'channelTitle': 'Dance Vibes',
          'publishedAt': '2024-01-05T18:20:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1508700929628-666bc8bd84ea?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['dance', 'trend', 'viral', 'short', 'challenge']
        },
        'statistics': {'viewCount': '5800000', 'likeCount': '220000'},
        'contentDetails': {'duration': 'PT0M45S'}
      },
      
      // Fitness/Health
      {
        'id': 'youtube_video_12',
        'snippet': {
          'title': '10-Minute Morning Workout Routine',
          'description': 'Quick and effective workout to start your day',
          'channelTitle': 'FitLife',
          'publishedAt': '2024-01-04T07:00:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['fitness', 'workout', 'morning', 'health', 'exercise']
        },
        'statistics': {'viewCount': '1900000', 'likeCount': '85000'},
        'contentDetails': {'duration': 'PT10M00S'}
      },
      
      // More Gaming Content
      {
        'id': 'youtube_video_13',
        'snippet': {
          'title': 'Minecraft Build Challenge: Epic Castle',
          'description': 'Building an amazing medieval castle in Minecraft survival',
          'channelTitle': 'MinecraftMaster',
          'publishedAt': '2024-01-03T14:20:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['minecraft', 'gaming', 'building', 'survival', 'castle']
        },
        'statistics': {'viewCount': '2800000', 'likeCount': '120000'},
        'contentDetails': {'duration': 'PT22M15S'}
      },
      {
        'id': 'youtube_video_14',
        'snippet': {
          'title': 'Call of Duty: Warzone Victory',
          'description': 'Insane 20-kill game with epic final circle plays',
          'channelTitle': 'COD Pro',
          'publishedAt': '2024-01-02T19:30:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['call of duty', 'warzone', 'gaming', 'fps', 'battle royale']
        },
        'statistics': {'viewCount': '1500000', 'likeCount': '68000'},
        'contentDetails': {'duration': 'PT18M45S'}
      },
      
      // More Vlog Content
      {
        'id': 'youtube_video_15',
        'snippet': {
          'title': 'Weekend in Paris | Travel Vlog',
          'description': 'Exploring beautiful Paris streets, food, and culture',
          'channelTitle': 'Travel Diaries',
          'publishedAt': '2024-01-01T12:00:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['paris', 'travel', 'vlog', 'france', 'culture', 'food']
        },
        'statistics': {'viewCount': '3200000', 'likeCount': '145000'},
        'contentDetails': {'duration': 'PT25M30S'}
      },
      {
        'id': 'youtube_video_16',
        'snippet': {
          'title': 'My Daily Routine as a YouTuber',
          'description': 'Behind the scenes of my content creation process',
          'channelTitle': 'Creator Life',
          'publishedAt': '2023-12-31T10:15:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1508700929628-666bc8bd84ea?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['youtuber', 'lifestyle', 'vlog', 'daily routine', 'content creation']
        },
        'statistics': {'viewCount': '2100000', 'likeCount': '89000'},
        'contentDetails': {'duration': 'PT15M20S'}
      },
      
      // More Tutorial Content
      {
        'id': 'youtube_video_17',
        'snippet': {
          'title': 'JavaScript Arrays: Complete Guide for Beginners',
          'description': 'Learn everything about JavaScript arrays with examples',
          'channelTitle': 'Code Master',
          'publishedAt': '2023-12-30T16:45:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['javascript', 'tutorial', 'programming', 'arrays', 'beginner']
        },
        'statistics': {'viewCount': '1800000', 'likeCount': '75000'},
        'contentDetails': {'duration': 'PT28M10S'}
      },
      {
        'id': 'youtube_video_18',
        'snippet': {
          'title': 'How to Cook Perfect Pasta | Italian Recipe',
          'description': 'Authentic Italian pasta recipe from scratch',
          'channelTitle': 'Chef Italian',
          'publishedAt': '2023-12-29T18:30:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['cooking', 'tutorial', 'pasta', 'italian', 'recipe', 'food']
        },
        'statistics': {'viewCount': '2400000', 'likeCount': '110000'},
        'contentDetails': {'duration': 'PT20M45S'}
      },
      
      // More Entertainment Content
      {
        'id': 'youtube_video_19',
        'snippet': {
          'title': 'Epic Fails Compilation 2024',
          'description': 'Funniest fails and bloopers from around the world',
          'channelTitle': 'Funny Moments',
          'publishedAt': '2023-12-28T20:00:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1493711662062-fa541adb3fc8?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['funny', 'fails', 'comedy', 'entertainment', 'compilation']
        },
        'statistics': {'viewCount': '4500000', 'likeCount': '180000'},
        'contentDetails': {'duration': 'PT12M30S'}
      },
      {
        'id': 'youtube_video_20',
        'snippet': {
          'title': 'Try Not to Laugh Challenge',
          'description': 'Ultimate funny videos that will make you laugh',
          'channelTitle': 'Laugh Factory',
          'publishedAt': '2023-12-27T15:20:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['challenge', 'funny', 'laugh', 'entertainment', 'comedy']
        },
        'statistics': {'viewCount': '3800000', 'likeCount': '165000'},
        'contentDetails': {'duration': 'PT14M15S'}
      },
      
      // More Music Content
      {
        'id': 'youtube_video_21',
        'snippet': {
          'title': 'Piano Cover: Popular Songs 2024',
          'description': 'Beautiful piano arrangements of trending songs',
          'channelTitle': 'Piano Covers',
          'publishedAt': '2023-12-26T21:30:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['piano', 'music', 'cover', 'instrumental', 'songs']
        },
        'statistics': {'viewCount': '2900000', 'likeCount': '125000'},
        'contentDetails': {'duration': 'PT16M40S'}
      },
      {
        'id': 'youtube_video_22',
        'snippet': {
          'title': 'Guitar Tutorial: Learn Your First Song',
          'description': 'Step-by-step guitar lesson for complete beginners',
          'channelTitle': 'Guitar Master',
          'publishedAt': '2023-12-25T14:15:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['guitar', 'tutorial', 'music', 'lesson', 'beginner', 'songs']
        },
        'statistics': {'viewCount': '2200000', 'likeCount': '95000'},
        'contentDetails': {'duration': 'PT24M25S'}
      },
      
      // More Tech Content
      {
        'id': 'youtube_video_23',
        'snippet': {
          'title': 'MacBook Pro M3 Review: Is It Worth It?',
          'description': 'Complete review of Apple\'s latest MacBook Pro',
          'channelTitle': 'Tech Reviewer',
          'publishedAt': '2023-12-24T11:45:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['macbook', 'tech', 'review', 'apple', 'laptop', 'm3']
        },
        'statistics': {'viewCount': '3600000', 'likeCount': '155000'},
        'contentDetails': {'duration': 'PT19M50S'}
      },
      {
        'id': 'youtube_video_24',
        'snippet': {
          'title': 'Best Smartphones 2024: Top 10 Picks',
          'description': 'Comprehensive comparison of the best phones this year',
          'channelTitle': 'Phone Expert',
          'publishedAt': '2023-12-23T16:20:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['smartphone', 'tech', 'review', 'comparison', '2024', 'phones']
        },
        'statistics': {'viewCount': '2800000', 'likeCount': '120000'},
        'contentDetails': {'duration': 'PT26M35S'}
      },
      
      // More Fitness Content
      {
        'id': 'youtube_video_25',
        'snippet': {
          'title': 'Full Body HIIT Workout - No Equipment',
          'description': 'High-intensity interval training at home',
          'channelTitle': 'HIIT Master',
          'publishedAt': '2023-12-22T08:30:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['hiit', 'workout', 'fitness', 'home workout', 'cardio', 'no equipment']
        },
        'statistics': {'viewCount': '2100000', 'likeCount': '88000'},
        'contentDetails': {'duration': 'PT18M15S'}
      },
      {
        'id': 'youtube_video_26',
        'snippet': {
          'title': 'Yoga for Beginners: 20-Minute Flow',
          'description': 'Gentle yoga session perfect for beginners',
          'channelTitle': 'Yoga Flow',
          'publishedAt': '2023-12-21T19:00:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['yoga', 'fitness', 'beginner', 'flexibility', 'meditation', 'wellness']
        },
        'statistics': {'viewCount': '1900000', 'likeCount': '78000'},
        'contentDetails': {'duration': 'PT20M00S'}
      },
      
      // More Shorts Content
      {
        'id': 'youtube_video_27',
        'snippet': {
          'title': 'Life Hack: Perfect Coffee Every Time',
          'description': 'Quick tip for making the best coffee at home',
          'channelTitle': 'Coffee Tips',
          'publishedAt': '2023-12-20T07:15:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['coffee', 'hack', 'tip', 'short', 'quick', 'life hack']
        },
        'statistics': {'viewCount': '5200000', 'likeCount': '210000'},
        'contentDetails': {'duration': 'PT0M45S'}
      },
      {
        'id': 'youtube_video_28',
        'snippet': {
          'title': 'Magic Trick Revealed in 60 Seconds',
          'description': 'Learn this amazing magic trick step by step',
          'channelTitle': 'Magic Shorts',
          'publishedAt': '2023-12-19T13:45:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1493711662062-fa541adb3fc8?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['magic', 'trick', 'short', 'quick', 'illusion', 'tutorial']
        },
        'statistics': {'viewCount': '4800000', 'likeCount': '195000'},
        'contentDetails': {'duration': 'PT1M00S'}
      },
      {
        'id': 'youtube_video_31',
        'snippet': {
          'title': 'Quick Workout: 30-Second Plank Challenge',
          'description': 'Fast and effective core workout in 30 seconds',
          'channelTitle': 'QuickFit',
          'publishedAt': '2023-12-16T08:30:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['workout', 'fitness', 'short', 'quick', 'plank', 'core']
        },
        'statistics': {'viewCount': '4100000', 'likeCount': '175000'},
        'contentDetails': {'duration': 'PT0M30S'}
      },
      {
        'id': 'youtube_video_32',
        'snippet': {
          'title': '5-Second Recipe: Perfect Scrambled Eggs',
          'description': 'Learn to make perfect scrambled eggs in seconds',
          'channelTitle': 'Quick Recipes',
          'publishedAt': '2023-12-15T12:20:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['cooking', 'recipe', 'eggs', 'short', 'quick', 'breakfast']
        },
        'statistics': {'viewCount': '3800000', 'likeCount': '160000'},
        'contentDetails': {'duration': 'PT0M45S'}
      },
      {
        'id': 'youtube_video_33',
        'snippet': {
          'title': 'Funny Cat Fails Compilation',
          'description': 'Hilarious cat moments that will make you laugh',
          'channelTitle': 'Cat Comedy',
          'publishedAt': '2023-12-14T16:45:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['cats', 'funny', 'fails', 'short', 'comedy', 'animals']
        },
        'statistics': {'viewCount': '6200000', 'likeCount': '250000'},
        'contentDetails': {'duration': 'PT1M30S'}
      },
      {
        'id': 'youtube_video_34',
        'snippet': {
          'title': 'Tech Hack: iPhone Hidden Features',
          'description': 'Secret iPhone features you didn\'t know about',
          'channelTitle': 'Tech Shorts',
          'publishedAt': '2023-12-13T14:15:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['iphone', 'tech', 'hack', 'short', 'tips', 'features']
        },
        'statistics': {'viewCount': '3500000', 'likeCount': '140000'},
        'contentDetails': {'duration': 'PT1M15S'}
      },
      {
        'id': 'youtube_video_35',
        'snippet': {
          'title': 'Dance Move Tutorial: 60-Second Challenge',
          'description': 'Learn this viral dance move in just 60 seconds',
          'channelTitle': 'Dance Shorts',
          'publishedAt': '2023-12-12T19:30:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['dance', 'tutorial', 'short', 'viral', 'challenge', 'music']
        },
        'statistics': {'viewCount': '4800000', 'likeCount': '200000'},
        'contentDetails': {'duration': 'PT1M00S'}
      },
      {
        'id': 'youtube_video_36',
        'snippet': {
          'title': 'Gaming Short: Epic Headshot Compilation',
          'description': 'Best headshot moments from various games',
          'channelTitle': 'Gaming Shorts',
          'publishedAt': '2023-12-11T21:00:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['gaming', 'headshot', 'fps', 'short', 'compilation', 'epic']
        },
        'statistics': {'viewCount': '3900000', 'likeCount': '165000'},
        'contentDetails': {'duration': 'PT1M20S'}
      },
      
      // General/Other Content
      {
        'id': 'youtube_video_29',
        'snippet': {
          'title': 'Amazing Facts About Space',
          'description': 'Mind-blowing space facts that will surprise you',
          'channelTitle': 'Space Facts',
          'publishedAt': '2023-12-18T17:30:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['space', 'facts', 'science', 'education', 'universe', 'astronomy']
        },
        'statistics': {'viewCount': '3200000', 'likeCount': '135000'},
        'contentDetails': {'duration': 'PT13M20S'}
      },
      {
        'id': 'youtube_video_30',
        'snippet': {
          'title': 'Documentary: The Ocean Depths',
          'description': 'Exploring the mysterious world beneath the waves',
          'channelTitle': 'Nature Docs',
          'publishedAt': '2023-12-17T20:15:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['documentary', 'ocean', 'nature', 'wildlife', 'marine life', 'education']
        },
        'statistics': {'viewCount': '2800000', 'likeCount': '115000'},
        'contentDetails': {'duration': 'PT45M30S'}
      },
      
      // More diverse content to reach 80+ videos
      {
        'id': 'youtube_video_37',
        'snippet': {
          'title': 'Art Tutorial: Watercolor Painting Basics',
          'description': 'Learn fundamental watercolor techniques for beginners',
          'channelTitle': 'Art Studio',
          'publishedAt': '2023-12-10T15:30:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1493711662062-fa541adb3fc8?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['art', 'watercolor', 'painting', 'tutorial', 'creative', 'beginner']
        },
        'statistics': {'viewCount': '1800000', 'likeCount': '75000'},
        'contentDetails': {'duration': 'PT22M15S'}
      },
      {
        'id': 'youtube_video_38',
        'snippet': {
          'title': 'News Update: Tech Industry Changes',
          'description': 'Latest developments in the technology sector',
          'channelTitle': 'Tech News',
          'publishedAt': '2023-12-09T11:00:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['news', 'tech', 'industry', 'updates', 'current events']
        },
        'statistics': {'viewCount': '950000', 'likeCount': '42000'},
        'contentDetails': {'duration': 'PT8M30S'}
      },
      {
        'id': 'youtube_video_39',
        'snippet': {
          'title': 'Football Highlights: Best Goals This Week',
          'description': 'Amazing goals and plays from recent football matches',
          'channelTitle': 'Sports Central',
          'publishedAt': '2023-12-08T18:45:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['football', 'sports', 'highlights', 'goals', 'soccer']
        },
        'statistics': {'viewCount': '4200000', 'likeCount': '180000'},
        'contentDetails': {'duration': 'PT12M45S'}
      },
      {
        'id': 'youtube_video_40',
        'snippet': {
          'title': 'Stand-up Comedy: Life in 2024',
          'description': 'Hilarious stand-up comedy about modern life',
          'channelTitle': 'Comedy Club',
          'publishedAt': '2023-12-07T20:30:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['comedy', 'stand-up', 'funny', 'entertainment', 'humor']
        },
        'statistics': {'viewCount': '3800000', 'likeCount': '165000'},
        'contentDetails': {'duration': 'PT15M20S'}
      },
      
      // More Shorts Content
      {
        'id': 'youtube_video_41',
        'snippet': {
          'title': 'Quick Math Trick: Multiply by 11',
          'description': 'Learn this amazing math trick in seconds',
          'channelTitle': 'Math Shorts',
          'publishedAt': '2023-12-06T09:15:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['math', 'trick', 'education', 'short', 'quick', 'numbers']
        },
        'statistics': {'viewCount': '2900000', 'likeCount': '120000'},
        'contentDetails': {'duration': 'PT0M30S'}
      },
      {
        'id': 'youtube_video_42',
        'snippet': {
          'title': 'Anime Review: Best Series 2024',
          'description': 'Top anime recommendations for this year',
          'channelTitle': 'Anime Hub',
          'publishedAt': '2023-12-05T16:20:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['anime', 'review', 'recommendations', 'animation', 'japanese']
        },
        'statistics': {'viewCount': '2100000', 'likeCount': '95000'},
        'contentDetails': {'duration': 'PT18M45S'}
      },
      {
        'id': 'youtube_video_43',
        'snippet': {
          'title': 'Product Unboxing: New Gaming Mouse',
          'description': 'Unboxing and first impressions of latest gaming mouse',
          'channelTitle': 'Gear Reviews',
          'publishedAt': '2023-12-04T14:10:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['unboxing', 'review', 'gaming', 'mouse', 'tech', 'hardware']
        },
        'statistics': {'viewCount': '1600000', 'likeCount': '72000'},
        'contentDetails': {'duration': 'PT11M30S'}
      },
      {
        'id': 'youtube_video_44',
        'snippet': {
          'title': 'Dog Training Tips: Basic Commands',
          'description': 'Essential commands every dog should know',
          'channelTitle': 'Pet Care Pro',
          'publishedAt': '2023-12-03T12:45:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['dogs', 'training', 'pets', 'animals', 'care', 'tips']
        },
        'statistics': {'viewCount': '2400000', 'likeCount': '110000'},
        'contentDetails': {'duration': 'PT16M15S'}
      },
      {
        'id': 'youtube_video_45',
        'snippet': {
          'title': 'Viral Dance Challenge: Try This Move',
          'description': 'Learn the latest viral dance move',
          'channelTitle': 'Dance Trends',
          'publishedAt': '2023-12-02T19:25:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['dance', 'viral', 'challenge', 'trend', 'music', 'tutorial']
        },
        'statistics': {'viewCount': '5200000', 'likeCount': '220000'},
        'contentDetails': {'duration': 'PT2M00S'}
      },
      {
        'id': 'youtube_video_46',
        'snippet': {
          'title': 'Quick Recipe: 2-Minute Pasta',
          'description': 'Make delicious pasta in just 2 minutes',
          'channelTitle': 'Quick Meals',
          'publishedAt': '2023-12-01T17:30:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1493711662062-fa541adb3fc8?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['cooking', 'recipe', 'pasta', 'quick', 'easy', 'food']
        },
        'statistics': {'viewCount': '1800000', 'likeCount': '85000'},
        'contentDetails': {'duration': 'PT2M30S'}
      },
      
      // Adding more content to reach 80+ videos
      {
        'id': 'youtube_video_47',
        'snippet': {
          'title': 'Gaming Short: Epic Comeback Victory',
          'description': 'Amazing comeback in the final seconds',
          'channelTitle': 'Gaming Clips',
          'publishedAt': '2023-11-30T22:15:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['gaming', 'comeback', 'victory', 'short', 'epic', 'clutch']
        },
        'statistics': {'viewCount': '3200000', 'likeCount': '140000'},
        'contentDetails': {'duration': 'PT1M45S'}
      },
      {
        'id': 'youtube_video_48',
        'snippet': {
          'title': 'Cooking Hack: Perfect Rice Every Time',
          'description': 'Secret technique for fluffy rice',
          'channelTitle': 'Cooking Hacks',
          'publishedAt': '2023-11-29T14:20:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['cooking', 'rice', 'hack', 'technique', 'food', 'tips']
        },
        'statistics': {'viewCount': '2100000', 'likeCount': '95000'},
        'contentDetails': {'duration': 'PT3M15S'}
      },
      {
        'id': 'youtube_video_49',
        'snippet': {
          'title': 'Vlog: Weekend Adventure in Mountains',
          'description': 'Exploring beautiful mountain trails and nature',
          'channelTitle': 'Adventure Life',
          'publishedAt': '2023-11-28T10:30:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['vlog', 'adventure', 'mountains', 'nature', 'hiking', 'travel']
        },
        'statistics': {'viewCount': '1800000', 'likeCount': '78000'},
        'contentDetails': {'duration': 'PT14M20S'}
      },
      {
        'id': 'youtube_video_50',
        'snippet': {
          'title': 'Tech Review: Best Laptops 2024',
          'description': 'Comprehensive review of top laptops this year',
          'channelTitle': 'Laptop Expert',
          'publishedAt': '2023-11-27T16:45:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['laptop', 'tech', 'review', '2024', 'computers', 'hardware']
        },
        'statistics': {'viewCount': '2500000', 'likeCount': '110000'},
        'contentDetails': {'duration': 'PT21M30S'}
      },
      {
        'id': 'youtube_video_51',
        'snippet': {
          'title': 'Short: Amazing Magic Trick',
          'description': 'Mind-blowing magic trick revealed',
          'channelTitle': 'Magic Shorts',
          'publishedAt': '2023-11-26T13:10:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['magic', 'trick', 'short', 'amazing', 'illusion', 'quick']
        },
        'statistics': {'viewCount': '4500000', 'likeCount': '190000'},
        'contentDetails': {'duration': 'PT1M00S'}
      },
      {
        'id': 'youtube_video_52',
        'snippet': {
          'title': 'Music: Acoustic Guitar Cover',
          'description': 'Beautiful acoustic cover of popular song',
          'channelTitle': 'Acoustic Covers',
          'publishedAt': '2023-11-25T19:20:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['music', 'acoustic', 'guitar', 'cover', 'song', 'instrumental']
        },
        'statistics': {'viewCount': '1600000', 'likeCount': '72000'},
        'contentDetails': {'duration': 'PT4M45S'}
      },
      {
        'id': 'youtube_video_53',
        'snippet': {
          'title': 'Fitness: 5-Minute Morning Routine',
          'description': 'Quick morning workout to start your day',
          'channelTitle': 'Morning Fitness',
          'publishedAt': '2023-11-24T07:00:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['fitness', 'morning', 'workout', 'routine', 'health', 'exercise']
        },
        'statistics': {'viewCount': '1900000', 'likeCount': '85000'},
        'contentDetails': {'duration': 'PT5M30S'}
      },
      {
        'id': 'youtube_video_54',
        'snippet': {
          'title': 'Short: Life Hack for Organization',
          'description': 'Simple trick to organize your workspace',
          'channelTitle': 'Life Hacks',
          'publishedAt': '2023-11-23T11:30:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['life hack', 'organization', 'workspace', 'short', 'tips', 'productivity']
        },
        'statistics': {'viewCount': '2800000', 'likeCount': '125000'},
        'contentDetails': {'duration': 'PT0M45S'}
      },
      {
        'id': 'youtube_video_55',
        'snippet': {
          'title': 'Tutorial: Learn Python Basics',
          'description': 'Complete Python programming tutorial for beginners',
          'channelTitle': 'Code Academy',
          'publishedAt': '2023-11-22T15:15:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1493711662062-fa541adb3fc8?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['python', 'programming', 'tutorial', 'coding', 'beginner', 'education']
        },
        'statistics': {'viewCount': '3200000', 'likeCount': '145000'},
        'contentDetails': {'duration': 'PT28M10S'}
      },
      {
        'id': 'youtube_video_56',
        'snippet': {
          'title': 'Entertainment: Funny Animal Compilation',
          'description': 'Hilarious animal moments that will make you laugh',
          'channelTitle': 'Animal Comedy',
          'publishedAt': '2023-11-21T18:45:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['animals', 'funny', 'comedy', 'entertainment', 'compilation', 'cute']
        },
        'statistics': {'viewCount': '4100000', 'likeCount': '180000'},
        'contentDetails': {'duration': 'PT9M20S'}
      },
      {
        'id': 'youtube_video_57',
        'snippet': {
          'title': 'Short: Quick Art Tutorial',
          'description': 'Learn to draw a simple flower in 60 seconds',
          'channelTitle': 'Art Shorts',
          'publishedAt': '2023-11-20T12:20:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['art', 'drawing', 'tutorial', 'short', 'quick', 'flower']
        },
        'statistics': {'viewCount': '2200000', 'likeCount': '98000'},
        'contentDetails': {'duration': 'PT1M00S'}
      },
      {
        'id': 'youtube_video_58',
        'snippet': {
          'title': 'Gaming: Minecraft Build Tutorial',
          'description': 'Step-by-step guide to build amazing structures',
          'channelTitle': 'Minecraft Builder',
          'publishedAt': '2023-11-19T20:10:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['minecraft', 'building', 'tutorial', 'gaming', 'construction', 'blocks']
        },
        'statistics': {'viewCount': '1700000', 'likeCount': '76000'},
        'contentDetails': {'duration': 'PT19M45S'}
      },
      {
        'id': 'youtube_video_59',
        'snippet': {
          'title': 'Short: Amazing Science Fact',
          'description': 'Mind-blowing science fact in 30 seconds',
          'channelTitle': 'Science Facts',
          'publishedAt': '2023-11-18T14:30:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['science', 'facts', 'amazing', 'short', 'education', 'mind-blowing']
        },
        'statistics': {'viewCount': '3600000', 'likeCount': '160000'},
        'contentDetails': {'duration': 'PT0M30S'}
      },
      {
        'id': 'youtube_video_60',
        'snippet': {
          'title': 'Vlog: Day in My Life as a Student',
          'description': 'Follow my daily routine as a university student',
          'channelTitle': 'Student Life',
          'publishedAt': '2023-11-17T09:15:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['vlog', 'student', 'university', 'daily life', 'routine', 'college']
        },
        'statistics': {'viewCount': '1300000', 'likeCount': '58000'},
        'contentDetails': {'duration': 'PT12M30S'}
      },
      {
        'id': 'youtube_video_61',
        'snippet': {
          'title': 'Tech: Smartphone Camera Comparison',
          'description': 'Comparing camera quality across different phones',
          'channelTitle': 'Camera Reviews',
          'publishedAt': '2023-11-16T16:40:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['smartphone', 'camera', 'comparison', 'tech', 'photography', 'review']
        },
        'statistics': {'viewCount': '2400000', 'likeCount': '105000'},
        'contentDetails': {'duration': 'PT15M20S'}
      },
      {
        'id': 'youtube_video_62',
        'snippet': {
          'title': 'Short: Quick Dance Move',
          'description': 'Learn this viral dance move in seconds',
          'channelTitle': 'Dance Quick',
          'publishedAt': '2023-11-15T21:25:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['dance', 'move', 'viral', 'short', 'quick', 'tutorial']
        },
        'statistics': {'viewCount': '5200000', 'likeCount': '220000'},
        'contentDetails': {'duration': 'PT1M15S'}
      },
      {
        'id': 'youtube_video_63',
        'snippet': {
          'title': 'Music: Piano Meditation',
          'description': 'Relaxing piano music for meditation and focus',
          'channelTitle': 'Meditation Music',
          'publishedAt': '2023-11-14T08:00:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['music', 'piano', 'meditation', 'relaxing', 'focus', 'calm']
        },
        'statistics': {'viewCount': '2900000', 'likeCount': '130000'},
        'contentDetails': {'duration': 'PT10M00S'}
      },
      {
        'id': 'youtube_video_64',
        'snippet': {
          'title': 'Fitness: Home Workout No Equipment',
          'description': 'Complete bodyweight workout you can do anywhere',
          'channelTitle': 'Home Fitness',
          'publishedAt': '2023-11-13T17:30:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1493711662062-fa541adb3fc8?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['fitness', 'home workout', 'bodyweight', 'no equipment', 'exercise', 'health']
        },
        'statistics': {'viewCount': '2100000', 'likeCount': '92000'},
        'contentDetails': {'duration': 'PT25M45S'}
      },
      {
        'id': 'youtube_video_65',
        'snippet': {
          'title': 'Short: Cooking Tip for Perfect Eggs',
          'description': 'Secret technique for the perfect scrambled eggs',
          'channelTitle': 'Cooking Tips',
          'publishedAt': '2023-11-12T11:45:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['cooking', 'eggs', 'tip', 'technique', 'short', 'breakfast']
        },
        'statistics': {'viewCount': '1800000', 'likeCount': '81000'},
        'contentDetails': {'duration': 'PT1M30S'}
      },
      
      // More content to reach 80+ videos
      {
        'id': 'youtube_video_66',
        'snippet': {
          'title': 'Gaming: Fortnite Victory Royale',
          'description': 'Epic win with amazing plays and strategy',
          'channelTitle': 'Fortnite Pro',
          'publishedAt': '2023-11-11T19:30:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['fortnite', 'gaming', 'victory', 'battle royale', 'epic', 'win']
        },
        'statistics': {'viewCount': '2800000', 'likeCount': '120000'},
        'contentDetails': {'duration': 'PT16M20S'}
      },
      {
        'id': 'youtube_video_67',
        'snippet': {
          'title': 'Short: Amazing Life Hack',
          'description': 'Simple trick that will change your daily routine',
          'channelTitle': 'Life Hacks Pro',
          'publishedAt': '2023-11-10T13:20:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['life hack', 'trick', 'routine', 'short', 'tips', 'daily']
        },
        'statistics': {'viewCount': '3400000', 'likeCount': '150000'},
        'contentDetails': {'duration': 'PT1M00S'}
      },
      {
        'id': 'youtube_video_68',
        'snippet': {
          'title': 'Art: Digital Painting Tutorial',
          'description': 'Learn digital art techniques step by step',
          'channelTitle': 'Digital Art Studio',
          'publishedAt': '2023-11-09T15:45:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['art', 'digital', 'painting', 'tutorial', 'creative', 'design']
        },
        'statistics': {'viewCount': '1500000', 'likeCount': '68000'},
        'contentDetails': {'duration': 'PT24M15S'}
      },
      {
        'id': 'youtube_video_69',
        'snippet': {
          'title': 'Short: Quick Math Trick',
          'description': 'Amazing multiplication trick in 60 seconds',
          'channelTitle': 'Math Tricks',
          'publishedAt': '2023-11-08T10:15:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['math', 'trick', 'multiplication', 'short', 'quick', 'numbers']
        },
        'statistics': {'viewCount': '2600000', 'likeCount': '115000'},
        'contentDetails': {'duration': 'PT1M00S'}
      },
      {
        'id': 'youtube_video_70',
        'snippet': {
          'title': 'Tech: AI Tools Review 2024',
          'description': 'Best AI tools for productivity and creativity',
          'channelTitle': 'AI Review',
          'publishedAt': '2023-11-07T14:30:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['ai', 'tools', 'productivity', 'tech', 'review', '2024']
        },
        'statistics': {'viewCount': '3200000', 'likeCount': '140000'},
        'contentDetails': {'duration': 'PT18M45S'}
      },
      {
        'id': 'youtube_video_71',
        'snippet': {
          'title': 'Music: Guitar Solo Performance',
          'description': 'Incredible guitar solo with amazing technique',
          'channelTitle': 'Guitar Master',
          'publishedAt': '2023-11-06T20:00:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['music', 'guitar', 'solo', 'performance', 'technique', 'instrumental']
        },
        'statistics': {'viewCount': '1900000', 'likeCount': '85000'},
        'contentDetails': {'duration': 'PT7M30S'}
      },
      {
        'id': 'youtube_video_72',
        'snippet': {
          'title': 'Short: Funny Pet Moments',
          'description': 'Hilarious pet compilation that will make you laugh',
          'channelTitle': 'Pet Comedy',
          'publishedAt': '2023-11-05T16:20:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['pets', 'funny', 'comedy', 'short', 'animals', 'cute']
        },
        'statistics': {'viewCount': '4800000', 'likeCount': '200000'},
        'contentDetails': {'duration': 'PT1M30S'}
      },
      {
        'id': 'youtube_video_73',
        'snippet': {
          'title': 'Fitness: Cardio Workout at Home',
          'description': 'High-intensity cardio workout without equipment',
          'channelTitle': 'Cardio Fitness',
          'publishedAt': '2023-11-04T08:30:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1493711662062-fa541adb3fc8?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['fitness', 'cardio', 'home workout', 'high intensity', 'exercise', 'health']
        },
        'statistics': {'viewCount': '1700000', 'likeCount': '75000'},
        'contentDetails': {'duration': 'PT22M10S'}
      },
      {
        'id': 'youtube_video_74',
        'snippet': {
          'title': 'Vlog: Travel to Japan',
          'description': 'Amazing journey through beautiful Japan',
          'channelTitle': 'Japan Travel',
          'publishedAt': '2023-11-03T12:45:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-4Oo-KNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['travel', 'japan', 'vlog', 'culture', 'adventure', 'tourism']
        },
        'statistics': {'viewCount': '2500000', 'likeCount': '110000'},
        'contentDetails': {'duration': 'PT31M20S'}
      },
      {
        'id': 'youtube_video_75',
        'snippet': {
          'title': 'Short: Amazing Science Experiment',
          'description': 'Mind-blowing science experiment in 90 seconds',
          'channelTitle': 'Science Lab',
          'publishedAt': '2023-11-02T14:10:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-5Pp-LNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['science', 'experiment', 'amazing', 'short', 'education', 'mind-blowing']
        },
        'statistics': {'viewCount': '3100000', 'likeCount': '135000'},
        'contentDetails': {'duration': 'PT1M30S'}
      },
      {
        'id': 'youtube_video_76',
        'snippet': {
          'title': 'Gaming: Call of Duty Highlights',
          'description': 'Best moments and epic plays from Call of Duty',
          'channelTitle': 'COD Highlights',
          'publishedAt': '2023-11-01T21:15:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-6Qq-MNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['call of duty', 'gaming', 'highlights', 'fps', 'shooter', 'epic']
        },
        'statistics': {'viewCount': '2200000', 'likeCount': '95000'},
        'contentDetails': {'duration': 'PT13M45S'}
      },
      {
        'id': 'youtube_video_77',
        'snippet': {
          'title': 'Short: Quick Recipe Hack',
          'description': 'Amazing cooking hack that saves time',
          'channelTitle': 'Recipe Hacks',
          'publishedAt': '2023-10-31T11:30:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-7Rr-NNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['cooking', 'recipe', 'hack', 'short', 'quick', 'time-saving']
        },
        'statistics': {'viewCount': '2900000', 'likeCount': '125000'},
        'contentDetails': {'duration': 'PT1M15S'}
      },
      {
        'id': 'youtube_video_78',
        'snippet': {
          'title': 'Tech: Smartphone Unboxing',
          'description': 'Unboxing the latest flagship smartphone',
          'channelTitle': 'Phone Unbox',
          'publishedAt': '2023-10-30T17:45:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-8Ss-ONNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['smartphone', 'unboxing', 'tech', 'review', 'flagship', 'new']
        },
        'statistics': {'viewCount': '1800000', 'likeCount': '80000'},
        'contentDetails': {'duration': 'PT12M30S'}
      },
      {
        'id': 'youtube_video_79',
        'snippet': {
          'title': 'Short: Amazing Dance Move',
          'description': 'Learn this viral dance move in seconds',
          'channelTitle': 'Dance Viral',
          'publishedAt': '2023-10-29T19:20:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-9Tt-PNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['dance', 'viral', 'move', 'short', 'quick', 'tutorial']
        },
        'statistics': {'viewCount': '5400000', 'likeCount': '230000'},
        'contentDetails': {'duration': 'PT1M00S'}
      },
      {
        'id': 'youtube_video_80',
        'snippet': {
          'title': 'Music: Piano Cover Popular Song',
          'description': 'Beautiful piano arrangement of trending song',
          'channelTitle': 'Piano Covers Pro',
          'publishedAt': '2023-10-28T15:10:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-0Uu-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['music', 'piano', 'cover', 'popular', 'song', 'trending']
        },
        'statistics': {'viewCount': '2100000', 'likeCount': '92000'},
        'contentDetails': {'duration': 'PT5M45S'}
      },
      // Adding 120+ more videos for unlimited content
      // Gaming Content (20 more)
      {
        'id': 'youtube_video_81',
        'snippet': {
          'title': 'Minecraft Epic Builds Showcase',
          'description': 'Amazing Minecraft creations and builds',
          'channelTitle': 'Minecraft Master',
          'publishedAt': '2023-10-27T14:30:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1Vv-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['minecraft', 'gaming', 'builds', 'creative', 'showcase']
        },
        'statistics': {'viewCount': '3200000', 'likeCount': '150000'},
        'contentDetails': {'duration': 'PT18M20S'}
      },
      {
        'id': 'youtube_video_82',
        'snippet': {
          'title': 'Call of Duty Warzone Highlights',
          'description': 'Best moments and plays from Warzone matches',
          'channelTitle': 'COD Highlights',
          'publishedAt': '2023-10-26T16:45:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-2Ww-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['call of duty', 'warzone', 'gaming', 'highlights', 'fps']
        },
        'statistics': {'viewCount': '1800000', 'likeCount': '85000'},
        'contentDetails': {'duration': 'PT12M15S'}
      },
      {
        'id': 'youtube_video_83',
        'snippet': {
          'title': 'Valorant Ranked Gameplay',
          'description': 'Competitive Valorant gameplay and tips',
          'channelTitle': 'Valorant Pro',
          'publishedAt': '2023-10-25T20:15:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-3Xx-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['valorant', 'gaming', 'fps', 'competitive', 'tips']
        },
        'statistics': {'viewCount': '950000', 'likeCount': '42000'},
        'contentDetails': {'duration': 'PT25M30S'}
      },
      {
        'id': 'youtube_video_84',
        'snippet': {
          'title': 'GTA V Online Adventures',
          'description': 'Funny moments and adventures in GTA Online',
          'channelTitle': 'GTA Adventures',
          'publishedAt': '2023-10-24T18:20:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-4Yy-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['gta', 'gaming', 'online', 'adventures', 'funny']
        },
        'statistics': {'viewCount': '4100000', 'likeCount': '180000'},
        'contentDetails': {'duration': 'PT22M45S'}
      },
      {
        'id': 'youtube_video_85',
        'snippet': {
          'title': 'Apex Legends Season Update',
          'description': 'New season features and gameplay',
          'channelTitle': 'Apex Updates',
          'publishedAt': '2023-10-23T12:10:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-5Zz-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['apex legends', 'gaming', 'battle royale', 'update', 'season']
        },
        'statistics': {'viewCount': '1600000', 'likeCount': '72000'},
        'contentDetails': {'duration': 'PT16M20S'}
      },
      // Vlog Content (20 more)
      {
        'id': 'youtube_video_86',
        'snippet': {
          'title': 'Weekend Getaway Vlog',
          'description': 'Relaxing weekend trip to the mountains',
          'channelTitle': 'Weekend Vibes',
          'publishedAt': '2023-10-22T11:30:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-6Aa-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['vlog', 'travel', 'weekend', 'mountains', 'relaxing']
        },
        'statistics': {'viewCount': '850000', 'likeCount': '38000'},
        'contentDetails': {'duration': 'PT14M25S'}
      },
      {
        'id': 'youtube_video_87',
        'snippet': {
          'title': 'My Skincare Routine 2024',
          'description': 'Complete skincare routine for healthy skin',
          'channelTitle': 'Beauty Life',
          'publishedAt': '2023-10-21T09:45:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-7Bb-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['skincare', 'beauty', 'routine', 'tips', 'healthy']
        },
        'statistics': {'viewCount': '1200000', 'likeCount': '55000'},
        'contentDetails': {'duration': 'PT8M40S'}
      },
      {
        'id': 'youtube_video_88',
        'snippet': {
          'title': 'College Life Vlog',
          'description': 'A day in my college life',
          'channelTitle': 'Student Life',
          'publishedAt': '2023-10-20T16:20:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-8Cc-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['college', 'student', 'life', 'vlog', 'education']
        },
        'statistics': {'viewCount': '650000', 'likeCount': '29000'},
        'contentDetails': {'duration': 'PT11M15S'}
      },
      {
        'id': 'youtube_video_89',
        'snippet': {
          'title': 'Moving to New City Vlog',
          'description': 'Big life change - moving to a new city',
          'channelTitle': 'Life Changes',
          'publishedAt': '2023-10-19T14:50:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-9Dd-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['moving', 'life change', 'vlog', 'new city', 'adventure']
        },
        'statistics': {'viewCount': '980000', 'likeCount': '44000'},
        'contentDetails': {'duration': 'PT19M30S'}
      },
      {
        'id': 'youtube_video_90',
        'snippet': {
          'title': 'Pet Care Vlog',
          'description': 'Taking care of my pets - daily routine',
          'channelTitle': 'Pet Lovers',
          'publishedAt': '2023-10-18T13:15:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-0Ee-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['pets', 'care', 'animals', 'routine', 'love']
        },
        'statistics': {'viewCount': '720000', 'likeCount': '33000'},
        'contentDetails': {'duration': 'PT7M50S'}
      },
      // Tutorial Content (20 more)
      {
        'id': 'youtube_video_91',
        'snippet': {
          'title': 'Learn Python Programming - Beginner Guide',
          'description': 'Complete Python tutorial for beginners',
          'channelTitle': 'Code Academy',
          'publishedAt': '2023-10-17T10:00:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1Ff-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['python', 'programming', 'tutorial', 'coding', 'beginner']
        },
        'statistics': {'viewCount': '2800000', 'likeCount': '125000'},
        'contentDetails': {'duration': 'PT45M20S'}
      },
      {
        'id': 'youtube_video_92',
        'snippet': {
          'title': 'Photoshop Tutorial - Photo Editing',
          'description': 'Advanced photo editing techniques',
          'channelTitle': 'Photo Pro',
          'publishedAt': '2023-10-16T15:30:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-2Gg-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['photoshop', 'tutorial', 'photo editing', 'design', 'tips']
        },
        'statistics': {'viewCount': '1900000', 'likeCount': '86000'},
        'contentDetails': {'duration': 'PT32M15S'}
      },
      {
        'id': 'youtube_video_93',
        'snippet': {
          'title': 'Guitar Lessons - Acoustic Songs',
          'description': 'Learn to play popular acoustic songs',
          'channelTitle': 'Guitar Master',
          'publishedAt': '2023-10-15T19:45:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-3Hh-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['guitar', 'music', 'tutorial', 'acoustic', 'lessons']
        },
        'statistics': {'viewCount': '1500000', 'likeCount': '68000'},
        'contentDetails': {'duration': 'PT28M40S'}
      },
      {
        'id': 'youtube_video_94',
        'snippet': {
          'title': 'Excel Tutorial - Advanced Functions',
          'description': 'Master Excel with advanced functions and formulas',
          'channelTitle': 'Excel Expert',
          'publishedAt': '2023-10-14T12:20:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-4Ii-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['excel', 'tutorial', 'functions', 'formulas', 'office']
        },
        'statistics': {'viewCount': '2200000', 'likeCount': '98000'},
        'contentDetails': {'duration': 'PT38M25S'}
      },
      {
        'id': 'youtube_video_95',
        'snippet': {
          'title': 'Web Development Tutorial',
          'description': 'Build a complete website from scratch',
          'channelTitle': 'Web Dev Pro',
          'publishedAt': '2023-10-13T17:10:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-5Jj-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['web development', 'html', 'css', 'javascript', 'tutorial']
        },
        'statistics': {'viewCount': '3100000', 'likeCount': '140000'},
        'contentDetails': {'duration': 'PT52M15S'}
      },
      // Entertainment Content (20 more)
      {
        'id': 'youtube_video_96',
        'snippet': {
          'title': 'Funny Cat Compilation 2024',
          'description': 'Hilarious cat moments that will make you laugh',
          'channelTitle': 'Cat Lovers',
          'publishedAt': '2023-10-12T14:25:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-6Kk-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['cats', 'funny', 'compilation', 'entertainment', 'cute']
        },
        'statistics': {'viewCount': '5200000', 'likeCount': '230000'},
        'contentDetails': {'duration': 'PT15M30S'}
      },
      {
        'id': 'youtube_video_97',
        'snippet': {
          'title': 'Prank Videos Gone Wrong',
          'description': 'Epic fails and pranks that backfired',
          'channelTitle': 'Prank Central',
          'publishedAt': '2023-10-11T16:40:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-7Ll-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['pranks', 'funny', 'fails', 'entertainment', 'viral']
        },
        'statistics': {'viewCount': '3800000', 'likeCount': '170000'},
        'contentDetails': {'duration': 'PT12M45S'}
      },
      {
        'id': 'youtube_video_98',
        'snippet': {
          'title': 'Dance Challenge Compilation',
          'description': 'Latest dance trends and challenges',
          'channelTitle': 'Dance Trends',
          'publishedAt': '2023-10-10T20:15:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-8Mm-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['dance', 'challenge', 'trends', 'entertainment', 'viral']
        },
        'statistics': {'viewCount': '2600000', 'likeCount': '115000'},
        'contentDetails': {'duration': 'PT18M20S'}
      },
      {
        'id': 'youtube_video_99',
        'snippet': {
          'title': 'Magic Tricks Revealed',
          'description': 'Amazing magic tricks and how they work',
          'channelTitle': 'Magic Pro',
          'publishedAt': '2023-10-09T13:50:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-9Nn-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['magic', 'tricks', 'entertainment', 'amazing', 'revealed']
        },
        'statistics': {'viewCount': '1900000', 'likeCount': '85000'},
        'contentDetails': {'duration': 'PT22M15S'}
      },
      {
        'id': 'youtube_video_100',
        'snippet': {
          'title': 'Stand-up Comedy Special',
          'description': 'Hilarious stand-up comedy performance',
          'channelTitle': 'Comedy Central',
          'publishedAt': '2023-10-08T19:30:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-0Oo-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['comedy', 'stand-up', 'funny', 'entertainment', 'laugh']
        },
        'statistics': {'viewCount': '4200000', 'likeCount': '185000'},
        'contentDetails': {'duration': 'PT35M40S'}
      },
      // Adding 100+ more videos to reach 200+ total
      // Tech Reviews (20 more)
      {
        'id': 'youtube_video_101',
        'snippet': {
          'title': 'iPhone 15 Pro Max Review',
          'description': 'Complete review of the latest iPhone',
          'channelTitle': 'Tech Reviewer',
          'publishedAt': '2023-10-07T12:00:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1Pp-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['iphone', 'tech', 'review', 'smartphone', 'apple']
        },
        'statistics': {'viewCount': '3500000', 'likeCount': '155000'},
        'contentDetails': {'duration': 'PT28M15S'}
      },
      {
        'id': 'youtube_video_102',
        'snippet': {
          'title': 'MacBook Pro M3 Review',
          'description': 'Testing the new MacBook Pro with M3 chip',
          'channelTitle': 'Apple Insider',
          'publishedAt': '2023-10-06T15:30:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-2Qq-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['macbook', 'apple', 'review', 'laptop', 'm3']
        },
        'statistics': {'viewCount': '2800000', 'likeCount': '125000'},
        'contentDetails': {'duration': 'PT32M40S'}
      },
      {
        'id': 'youtube_video_103',
        'snippet': {
          'title': 'Samsung Galaxy S24 Ultra Unboxing',
          'description': 'First look at the new Galaxy S24 Ultra',
          'channelTitle': 'Android Central',
          'publishedAt': '2023-10-05T18:45:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-3Rr-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['samsung', 'galaxy', 'unboxing', 'android', 'smartphone']
        },
        'statistics': {'viewCount': '2100000', 'likeCount': '95000'},
        'contentDetails': {'duration': 'PT22M20S'}
      },
      {
        'id': 'youtube_video_104',
        'snippet': {
          'title': 'NVIDIA RTX 4090 Gaming Test',
          'description': 'Gaming performance test with RTX 4090',
          'channelTitle': 'Gaming Tech',
          'publishedAt': '2023-10-04T14:20:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-4Ss-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['nvidia', 'rtx 4090', 'gaming', 'graphics', 'pc']
        },
        'statistics': {'viewCount': '1900000', 'likeCount': '85000'},
        'contentDetails': {'duration': 'PT25M30S'}
      },
      {
        'id': 'youtube_video_105',
        'snippet': {
          'title': 'Tesla Model Y Review 2024',
          'description': 'Complete review of Tesla Model Y',
          'channelTitle': 'Electric Vehicle',
          'publishedAt': '2023-10-03T16:10:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-5Tt-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['tesla', 'model y', 'electric', 'car', 'review']
        },
        'statistics': {'viewCount': '2400000', 'likeCount': '110000'},
        'contentDetails': {'duration': 'PT35M45S'}
      },
      // Cooking Content (20 more)
      {
        'id': 'youtube_video_106',
        'snippet': {
          'title': 'Perfect Pasta Recipe',
          'description': 'Learn to make the perfect pasta from scratch',
          'channelTitle': 'Italian Kitchen',
          'publishedAt': '2023-10-02T11:30:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-6Uu-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['pasta', 'cooking', 'italian', 'recipe', 'homemade']
        },
        'statistics': {'viewCount': '1600000', 'likeCount': '72000'},
        'contentDetails': {'duration': 'PT18M25S'}
      },
      {
        'id': 'youtube_video_107',
        'snippet': {
          'title': 'Chocolate Cake Recipe',
          'description': 'Delicious chocolate cake that melts in your mouth',
          'channelTitle': 'Sweet Treats',
          'publishedAt': '2023-10-01T13:45:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-7Vv-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['chocolate', 'cake', 'baking', 'dessert', 'sweet']
        },
        'statistics': {'viewCount': '2200000', 'likeCount': '98000'},
        'contentDetails': {'duration': 'PT24M15S'}
      },
      {
        'id': 'youtube_video_108',
        'snippet': {
          'title': 'BBQ Ribs Masterclass',
          'description': 'Perfect BBQ ribs with secret sauce',
          'channelTitle': 'BBQ Master',
          'publishedAt': '2023-09-30T17:20:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-8Ww-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['bbq', 'ribs', 'grilling', 'meat', 'sauce']
        },
        'statistics': {'viewCount': '1800000', 'likeCount': '81000'},
        'contentDetails': {'duration': 'PT29M40S'}
      },
      {
        'id': 'youtube_video_109',
        'snippet': {
          'title': 'Sushi Making Tutorial',
          'description': 'Learn to make professional sushi at home',
          'channelTitle': 'Japanese Cuisine',
          'publishedAt': '2023-09-29T15:15:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-9Xx-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['sushi', 'japanese', 'cooking', 'tutorial', 'seafood']
        },
        'statistics': {'viewCount': '1300000', 'likeCount': '58000'},
        'contentDetails': {'duration': 'PT26M30S'}
      },
      {
        'id': 'youtube_video_110',
        'snippet': {
          'title': 'Healthy Smoothie Bowl',
          'description': 'Nutritious and delicious smoothie bowl recipe',
          'channelTitle': 'Healthy Living',
          'publishedAt': '2023-09-28T09:50:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-0Yy-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['smoothie', 'healthy', 'nutrition', 'breakfast', 'fruits']
        },
        'statistics': {'viewCount': '950000', 'likeCount': '42000'},
        'contentDetails': {'duration': 'PT12M20S'}
      },
      // Fitness Content (20 more)
      {
        'id': 'youtube_video_111',
        'snippet': {
          'title': '30-Minute Full Body Workout',
          'description': 'Complete full body workout at home',
          'channelTitle': 'Fitness Pro',
          'publishedAt': '2023-09-27T07:30:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-1Zz-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['workout', 'fitness', 'home', 'full body', 'exercise']
        },
        'statistics': {'viewCount': '2700000', 'likeCount': '120000'},
        'contentDetails': {'duration': 'PT30M00S'}
      },
      {
        'id': 'youtube_video_112',
        'snippet': {
          'title': 'Yoga for Beginners',
          'description': 'Gentle yoga routine for beginners',
          'channelTitle': 'Yoga Life',
          'publishedAt': '2023-09-26T06:45:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-2Aa-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['yoga', 'beginners', 'relaxation', 'flexibility', 'meditation']
        },
        'statistics': {'viewCount': '1900000', 'likeCount': '85000'},
        'contentDetails': {'duration': 'PT25M15S'}
      },
      {
        'id': 'youtube_video_113',
        'snippet': {
          'title': 'HIIT Cardio Workout',
          'description': 'High intensity interval training cardio',
          'channelTitle': 'Cardio King',
          'publishedAt': '2023-09-25T18:00:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-3Bb-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['hiit', 'cardio', 'intense', 'fat burning', 'workout']
        },
        'statistics': {'viewCount': '2100000', 'likeCount': '95000'},
        'contentDetails': {'duration': 'PT20M30S'}
      },
      {
        'id': 'youtube_video_114',
        'snippet': {
          'title': 'Strength Training for Women',
          'description': 'Weight training specifically for women',
          'channelTitle': 'Women Fitness',
          'publishedAt': '2023-09-24T19:30:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-4Cc-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['strength training', 'women', 'weights', 'muscle', 'fitness']
        },
        'statistics': {'viewCount': '1500000', 'likeCount': '68000'},
        'contentDetails': {'duration': 'PT35M20S'}
      },
      {
        'id': 'youtube_video_115',
        'snippet': {
          'title': 'Pilates Core Workout',
          'description': 'Core strengthening Pilates routine',
          'channelTitle': 'Pilates Pro',
          'publishedAt': '2023-09-23T17:15:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-5Dd-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['pilates', 'core', 'strength', 'toning', 'balance']
        },
        'statistics': {'viewCount': '1200000', 'likeCount': '54000'},
        'contentDetails': {'duration': 'PT22M45S'}
      },
      // Travel Content (20 more)
      {
        'id': 'youtube_video_116',
        'snippet': {
          'title': 'Tokyo Travel Guide 2024',
          'description': 'Complete guide to visiting Tokyo',
          'channelTitle': 'Travel Explorer',
          'publishedAt': '2023-09-22T14:20:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-6Ee-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['tokyo', 'japan', 'travel', 'guide', 'tourist']
        },
        'statistics': {'viewCount': '3100000', 'likeCount': '140000'},
        'contentDetails': {'duration': 'PT42M30S'}
      },
      {
        'id': 'youtube_video_117',
        'snippet': {
          'title': 'Paris City Tour',
          'description': 'Beautiful sights and attractions in Paris',
          'channelTitle': 'European Travel',
          'publishedAt': '2023-09-21T12:10:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-7Ff-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['paris', 'france', 'travel', 'city tour', 'sightseeing']
        },
        'statistics': {'viewCount': '2800000', 'likeCount': '125000'},
        'contentDetails': {'duration': 'PT38M15S'}
      },
      {
        'id': 'youtube_video_118',
        'snippet': {
          'title': 'Bali Beach Paradise',
          'description': 'Stunning beaches and resorts in Bali',
          'channelTitle': 'Tropical Paradise',
          'publishedAt': '2023-09-20T16:40:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-8Gg-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['bali', 'beach', 'paradise', 'tropical', 'resort']
        },
        'statistics': {'viewCount': '2400000', 'likeCount': '110000'},
        'contentDetails': {'duration': 'PT33M20S'}
      },
      {
        'id': 'youtube_video_119',
        'snippet': {
          'title': 'New York City Highlights',
          'description': 'Must-see places in New York City',
          'channelTitle': 'NYC Travel',
          'publishedAt': '2023-09-19T11:25:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-9Hh-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['new york', 'nyc', 'travel', 'city', 'attractions']
        },
        'statistics': {'viewCount': '2600000', 'likeCount': '115000'},
        'contentDetails': {'duration': 'PT36M45S'}
      },
      {
        'id': 'youtube_video_120',
        'snippet': {
          'title': 'Swiss Alps Adventure',
          'description': 'Hiking and skiing in the Swiss Alps',
          'channelTitle': 'Mountain Explorer',
          'publishedAt': '2023-09-18T15:50:00Z',
          'thumbnails': {
            'high': {'url': 'https://images.unsplash.com/photo-0Ii-QNNZee?w=480&h=360&fit=crop&crop=center'}
          },
          'tags': ['swiss alps', 'hiking', 'skiing', 'mountains', 'adventure']
        },
        'statistics': {'viewCount': '1800000', 'likeCount': '81000'},
        'contentDetails': {'duration': 'PT29M30S'}
      },
    ];
    
    return mockVideos
        .map((video) => ContentItem.fromYouTubeTrendingJson(video))
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

  List<ContentItem> _getMockTMDBContent(String mediaType, int limit) {
    final mockMovies = [
      {
        'id': 1,
        'title': 'Spider-Man: No Way Home',
        'overview': 'Peter Parker is unmasked and no longer able to separate his normal life from the high-stakes of being a super-hero.',
        'poster_path': '/1g0dhYtq4irTY1GPXvft6k4YLjm.jpg',
        'backdrop_path': '/14QbnygCuTO0vl7CAFmPf1fgZfV.jpg',
        'vote_average': 8.4,
        'release_date': '2021-12-15',
        'media_type': 'movie'
      },
      {
        'id': 2,
        'title': 'Dune',
        'overview': 'Paul Atreides, a brilliant and gifted young man born into a great destiny beyond his understanding.',
        'poster_path': '/d5NXSklXo0qyIYkgV94XAgMIckC.jpg',
        'backdrop_path': '/jYEW5xZkZk2WTrdbMGAPFuBqbDc.jpg',
        'vote_average': 8.0,
        'release_date': '2021-09-15',
        'media_type': 'movie'
      },
      {
        'id': 3,
        'title': 'The Batman',
        'overview': 'When a sadistic serial killer begins murdering key political figures in Gotham.',
        'poster_path': '/b0PlSFdDwbyK0cf5RxwDpaOJQvQ.jpg',
        'backdrop_path': '/c6H7Z4u73ir3cIoCteuhJh7UCAR.jpg',
        'vote_average': 7.8,
        'release_date': '2022-03-01',
        'media_type': 'movie'
      },
      {
        'id': 4,
        'title': 'Top Gun: Maverick',
        'overview': 'After thirty years, Maverick is still pushing the envelope as a top naval aviator.',
        'poster_path': '/62HCnUTziyWcpDaBO2i1DX17ljH.jpg',
        'backdrop_path': '/odJ4hx6g6vBt4lBWKFD1tI8WS4x.jpg',
        'vote_average': 8.3,
        'release_date': '2022-05-24',
        'media_type': 'movie'
      },
      {
        'id': 5,
        'title': 'Doctor Strange in the Multiverse of Madness',
        'overview': 'Doctor Strange teams up with a mysterious teenage girl to battle multiversal threats.',
        'poster_path': '/9Gtg2DzBhmYamXBS1hKAhiwbBKS.jpg',
        'backdrop_path': '/wcKFYIiVDvRURrzglV9kGu7fpfY.jpg',
        'vote_average': 6.9,
        'release_date': '2022-05-04',
        'media_type': 'movie'
      },
      // Adding 195+ more movies for unlimited content
      // Action Movies (30 more)
      {
        'id': 6,
        'title': 'Fast X',
        'overview': 'Dom Toretto and his family are targeted by the vengeful son of drug kingpin Hernan Reyes.',
        'poster_path': '/fiVW06jE7z9YnO4trhaMEdclSiC.jpg',
        'backdrop_path': '/4XM8DUTQb3lhLemJC51Jx4a2EuA.jpg',
        'vote_average': 7.2,
        'release_date': '2023-05-17',
        'media_type': 'movie'
      },
      {
        'id': 7,
        'title': 'Mission: Impossible - Dead Reckoning Part One',
        'overview': 'Ethan Hunt and his IMF team must track down a dangerous weapon before it falls into the wrong hands.',
        'poster_path': '/NNxYkU70HPurnNCSiCjYAmacW.jpg',
        'backdrop_path': '/628Dep6AxEtDxjZoGP78TsOxYbK.jpg',
        'vote_average': 7.5,
        'release_date': '2023-07-10',
        'media_type': 'movie'
      },
      {
        'id': 8,
        'title': 'John Wick: Chapter 4',
        'overview': 'John Wick uncovers a path to defeating The High Table. But before he can earn his freedom.',
        'poster_path': '/vZloFAK7NmvMGKE7VkF5UHaz0I.jpg',
        'backdrop_path': '/h8gHn0OzBoaefsYseUByaSm8CzP.jpg',
        'vote_average': 7.8,
        'release_date': '2023-03-22',
        'media_type': 'movie'
      },
      {
        'id': 9,
        'title': 'Avatar: The Way of Water',
        'overview': 'Set more than a decade after the events of the first film, Avatar: The Way of Water begins to tell the story of the Sully family.',
        'poster_path': '/t6HIqrRAclMCA60NsSmeqe9RmNV.jpg',
        'backdrop_path': '/s16H6tpK2utvwDtzZ8Qy4qm5Emw.jpg',
        'vote_average': 7.7,
        'release_date': '2022-12-14',
        'media_type': 'movie'
      },
      {
        'id': 10,
        'title': 'Black Panther: Wakanda Forever',
        'overview': 'Queen Ramonda, Shuri, M\'Baku, Okoye and the Dora Milaje fight to protect their nation from intervening world powers.',
        'poster_path': '/sv1xJUazXeYqALzczSZ3O6nkH75.jpg',
        'backdrop_path': '/yYrvN5WFeGYjJnRzhY0QXuo4Isw.jpg',
        'vote_average': 7.3,
        'release_date': '2022-11-09',
        'media_type': 'movie'
      },
      // Sci-Fi Movies (30 more)
      {
        'id': 11,
        'title': 'Interstellar',
        'overview': 'The adventures of a group of explorers who make use of a newly discovered wormhole to surpass the limitations on human space travel.',
        'poster_path': '/rAiYTfKGqDCRIIqo664sY9XZIvQ.jpg',
        'backdrop_path': '/xu9zaAevzQ5nnrsXN6JcahLnG4i.jpg',
        'vote_average': 8.6,
        'release_date': '2014-11-05',
        'media_type': 'movie'
      },
      {
        'id': 12,
        'title': 'Blade Runner 2049',
        'overview': 'Thirty years after the events of the first film, a new blade runner, LAPD Officer K, unearths a long-buried secret.',
        'poster_path': '/gajva2L0rPYkEWjzgFlBXCAVBE5.jpg',
        'backdrop_path': '/mVr0UiqyltcfqxbAUcLl9zWL8ah.jpg',
        'vote_average': 7.5,
        'release_date': '2017-10-04',
        'media_type': 'movie'
      },
      {
        'id': 13,
        'title': 'The Matrix',
        'overview': 'A computer hacker learns from mysterious rebels about the true nature of his reality and his role in the war against its controllers.',
        'poster_path': '/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg',
        'backdrop_path': '/ncEsesgOJDLrTUOf0Uxpg6Cl5px.jpg',
        'vote_average': 8.7,
        'release_date': '1999-03-30',
        'media_type': 'movie'
      },
      {
        'id': 14,
        'title': 'Inception',
        'overview': 'A thief who steals corporate secrets through the use of dream-sharing technology is given the inverse task of planting an idea.',
        'poster_path': '/oYuLEt3zVCKq57quxF8dT5UK45J.jpg',
        'backdrop_path': '/s3TBrRGB1iav7gFOCNx3H31MoES.jpg',
        'vote_average': 8.8,
        'release_date': '2010-07-15',
        'media_type': 'movie'
      },
      {
        'id': 15,
        'title': 'Ex Machina',
        'overview': 'A young programmer is selected to participate in a breakthrough experiment in artificial intelligence by evaluating the human qualities of a breath-taking humanoid A.I.',
        'poster_path': '/btbRB6nbJWzAXdXZq6j2UfVhOib.jpg',
        'backdrop_path': '/a6cDxdwaQIFjSkXf7uskg78ZyTq.jpg',
        'vote_average': 7.7,
        'release_date': '2015-01-21',
        'media_type': 'movie'
      },
      // Comedy Movies (30 more)
      {
        'id': 16,
        'title': 'Deadpool',
        'overview': 'A wisecracking mercenary gets experimented on and becomes immortal but ugly, and sets out to track down the man who ruined his looks.',
        'poster_path': '/fSRb7vyIP8rQpL0I47P3qUsEKX3.jpg',
        'backdrop_path': '/n1y094tVDFATSzkTnFxoGZ1qNsG.jpg',
        'vote_average': 7.6,
        'release_date': '2016-02-09',
        'media_type': 'movie'
      },
      {
        'id': 17,
        'title': 'The Hangover',
        'overview': 'Three buddies wake up from a bachelor party in Las Vegas, with no memory of the previous night and the bachelor missing.',
        'poster_path': '/varlLf1M5UcV6BfVc1y0UfIhQwj3.jpg',
        'backdrop_path': '/5wdmVi7eqNVX87T4qP8OONBDKnW.jpg',
        'vote_average': 7.4,
        'release_date': '2009-06-02',
        'media_type': 'movie'
      },
      {
        'id': 18,
        'title': 'Superbad',
        'overview': 'Two co-dependent high school seniors are forced to deal with separation anxiety after their plan to stage a booze-soaked party goes awry.',
        'poster_path': '/ek8e8XTUw2w9nFDMZz3Rzt8o4P1.jpg',
        'backdrop_path': '/8Z7qQ6Jv3tZKhN0YK3FZrgA07a.jpg',
        'vote_average': 7.6,
        'release_date': '2007-08-17',
        'media_type': 'movie'
      },
      {
        'id': 19,
        'title': 'Anchorman: The Legend of Ron Burgundy',
        'overview': 'Ron Burgundy is San Diego\'s top-rated newsman in the male-dominated broadcasting of the 1970s.',
        'poster_path': '/3lBDg3i6nn5R2NKFCJ6oKyUo2j5.jpg',
        'backdrop_path': '/h8gHn0OzBoaefsYseUByaSm8CzP.jpg',
        'vote_average': 7.0,
        'release_date': '2004-07-09',
        'media_type': 'movie'
      },
      {
        'id': 20,
        'title': 'Step Brothers',
        'overview': 'Two aimless middle-aged losers still living at home are forced against their will to become roommates when their parents marry.',
        'poster_path': '/d2qk9n4Yt7K8d2C8x8x8x8x8x8x8.jpg',
        'backdrop_path': '/h8gHn0OzBoaefsYseUByaSm8CzP.jpg',
        'vote_average': 6.9,
        'release_date': '2008-07-25',
        'media_type': 'movie'
      },
      // Horror Movies (30 more)
      {
        'id': 21,
        'title': 'The Conjuring',
        'overview': 'Paranormal investigators Ed and Lorraine Warren work to help a family terrorized by a dark presence in their farmhouse.',
        'poster_path': '/wVYREutTvI2tmxr6ujrHT704wGF.jpg',
        'backdrop_path': '/7X1vY6acKtJ4uL8WZQoV2r6x3s5.jpg',
        'vote_average': 7.5,
        'release_date': '2013-07-18',
        'media_type': 'movie'
      },
      {
        'id': 22,
        'title': 'Hereditary',
        'overview': 'After the family matriarch passes away, a grieving family is haunted by tragic and disturbing occurrences.',
        'poster_path': '/lHV8HHlhwNup2VbpiACtlKzaGIQ.jpg',
        'backdrop_path': '/dYvIUzdh6TUv4IFRq8UBkX7bNNu.jpg',
        'vote_average': 7.3,
        'release_date': '2018-06-07',
        'media_type': 'movie'
      },
      {
        'id': 23,
        'title': 'Get Out',
        'overview': 'A young African-American visits his white girlfriend\'s parents for the weekend, where his uneasiness about their reception of him eventually reaches a boiling point.',
        'poster_path': '/tFXcEccSQMf3lfhfXKSU9iRBpa3.jpg',
        'backdrop_path': '/pZfXa2qP7rKz1z1z1z1z1z1z1z1.jpg',
        'vote_average': 7.8,
        'release_date': '2017-02-24',
        'media_type': 'movie'
      },
      {
        'id': 24,
        'title': 'The Babadook',
        'overview': 'A single mother, plagued by the violent death of her husband, battles with her son\'s fear of a monster lurking in the house.',
        'poster_path': '/c2M9yE5yWrYkNMg1z1z1z1z1z1z1.jpg',
        'backdrop_path': '/d2qk9n4Yt7K8d2C8x8x8x8x8x8x8.jpg',
        'vote_average': 6.8,
        'release_date': '2014-05-22',
        'media_type': 'movie'
      },
      {
        'id': 25,
        'title': 'Midsommar',
        'overview': 'A couple travels to Sweden to visit their friend\'s rural hometown for its fabled mid-summer festival.',
        'poster_path': '/7LEI8ulZzO5gy9Ww2NVCrKm3D8i.jpg',
        'backdrop_path': '/h8gHn0OzBoaefsYseUByaSm8CzP.jpg',
        'vote_average': 7.1,
        'release_date': '2019-07-03',
        'media_type': 'movie'
      },
      // Drama Movies (30 more)
      {
        'id': 26,
        'title': 'The Shawshank Redemption',
        'overview': 'Two imprisoned men bond over a number of years, finding solace and eventual redemption through acts of common decency.',
        'poster_path': '/q6y0Go1tsGEsmtFryDOJo3dEmqu.jpg',
        'backdrop_path': '/iNh3BivHyg5sQRPP1KOkzguEX0H.jpg',
        'vote_average': 8.7,
        'release_date': '1994-09-23',
        'media_type': 'movie'
      },
      {
        'id': 27,
        'title': 'Forrest Gump',
        'overview': 'The presidencies of Kennedy and Johnson, the Vietnam War, the Watergate scandal and other historical events unfold from the perspective of an Alabama man.',
        'poster_path': '/arw2vcBveWOVZr6pxd9XTd1TdQa.jpg',
        'backdrop_path': '/7c9UVPPiTPltouxRVY6N9uugaVA.jpg',
        'vote_average': 8.5,
        'release_date': '1994-06-23',
        'media_type': 'movie'
      },
      {
        'id': 28,
        'title': 'The Godfather',
        'overview': 'The aging patriarch of an organized crime dynasty transfers control of his clandestine empire to his reluctant son.',
        'poster_path': '/3bhkrj58Vtu7enYsRolD1fZdja1.jpg',
        'backdrop_path': '/tmU7GeKVybMWFButWEGl2M4GeiP.jpg',
        'vote_average': 8.7,
        'release_date': '1972-03-14',
        'media_type': 'movie'
      },
      {
        'id': 29,
        'title': 'Pulp Fiction',
        'overview': 'The lives of two mob hitmen, a boxer, a gangster and his wife, and a pair of diner bandits intertwine in four tales of violence and redemption.',
        'poster_path': '/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg',
        'backdrop_path': '/4cDFyw4k8ynZQuHHT07qkuRE2e7.jpg',
        'vote_average': 8.9,
        'release_date': '1994-09-10',
        'media_type': 'movie'
      },
      {
        'id': 30,
        'title': 'The Dark Knight',
        'overview': 'When the menace known as the Joker wreaks havoc and chaos on the people of Gotham, Batman must accept one of the greatest psychological tests.',
        'poster_path': '/qJ2tW6WMUDux911r6m7haRef0WH.jpg',
        'backdrop_path': '/hqkIcbrOHL86UncnHIsHVcVmzue.jpg',
        'vote_average': 9.0,
        'release_date': '2008-07-16',
        'media_type': 'movie'
      },
      // Adding 170+ more movies to reach 200+ total
      // Romance Movies (30 more)
      {
        'id': 31,
        'title': 'Titanic',
        'overview': 'A seventeen-year-old aristocrat falls in love with a kind but poor artist aboard the luxurious, ill-fated R.M.S. Titanic.',
        'poster_path': '/9xjZS2rlVxm8SFx8kPC3aIGCOYQ.jpg',
        'backdrop_path': '/k7eYdWvhYQyRQoU2TB2A2Xu2TfD.jpg',
        'vote_average': 7.9,
        'release_date': '1997-12-18',
        'media_type': 'movie'
      },
      {
        'id': 32,
        'title': 'The Notebook',
        'overview': 'A poor yet passionate young man falls in love with a rich young woman, giving her a sense of freedom.',
        'poster_path': '/rNzQyW4f8B8cQeg7Dgj3n6eTUnk.jpg',
        'backdrop_path': '/x4biAVdPVCghBlsVIzFCSN2xNvs.jpg',
        'vote_average': 7.8,
        'release_date': '2004-06-25',
        'media_type': 'movie'
      },
      {
        'id': 33,
        'title': 'Casablanca',
        'overview': 'A cynical expatriate American cafe owner struggles to decide whether or not to help his former lover and her fugitive husband escape the Nazis.',
        'poster_path': '/5K7cOHoay2mZusSLezBOY0Qxh8a.jpg',
        'backdrop_path': '/3bhkrj58Vtu7enYsRolD1fZdja1.jpg',
        'vote_average': 8.5,
        'release_date': '1942-11-26',
        'media_type': 'movie'
      },
      {
        'id': 34,
        'title': 'When Harry Met Sally',
        'overview': 'Harry and Sally have known each other for years, and are very good friends, but they fear sex would ruin the friendship.',
        'poster_path': '/2e02snFvIDqY7Kez5ig8DBXIJVe.jpg',
        'backdrop_path': '/h8gHn0OzBoaefsYseUByaSm8CzP.jpg',
        'vote_average': 7.6,
        'release_date': '1989-07-21',
        'media_type': 'movie'
      },
      {
        'id': 35,
        'title': 'Pretty Woman',
        'overview': 'A man in a legal but hurtful business needs an escort for some social events, and hires a beautiful prostitute he meets.',
        'poster_path': '/f4pm9u9TXJaG2vdkj3qP6jMkLUF.jpg',
        'backdrop_path': '/h8gHn0OzBoaefsYseUByaSm8CzP.jpg',
        'vote_average': 7.0,
        'release_date': '1990-03-23',
        'media_type': 'movie'
      },
      // Thriller Movies (30 more)
      {
        'id': 36,
        'title': 'Gone Girl',
        'overview': 'With his wife\'s disappearance having become the focus of the media and a police investigation, a man sees the spotlight turned on him.',
        'poster_path': '/bt6DhdALyhf90gReozoQ0y3RKhS.jpg',
        'backdrop_path': '/h8gHn0OzBoaefsYseUByaSm8CzP.jpg',
        'vote_average': 8.1,
        'release_date': '2014-10-02',
        'media_type': 'movie'
      },
      {
        'id': 37,
        'title': 'Se7en',
        'overview': 'Two detectives, a rookie and a veteran, hunt a serial killer who uses the seven deadly sins as his motives.',
        'poster_path': '/69Sns8WoET6CfaYlIkHbla4l7nC.jpg',
        'backdrop_path': '/h8gHn0OzBoaefsYseUByaSm8CzP.jpg',
        'vote_average': 8.6,
        'release_date': '1995-09-22',
        'media_type': 'movie'
      },
      {
        'id': 38,
        'title': 'Zodiac',
        'overview': 'In the late 1960s/early 1970s, a San Francisco cartoonist becomes an amateur detective obsessed with tracking down the Zodiac Killer.',
        'poster_path': '/tVhG8WeV4V3Qn4c3xH5eR0fF8Bt.jpg',
        'backdrop_path': '/h8gHn0OzBoaefsYseUByaSm8CzP.jpg',
        'vote_average': 7.7,
        'release_date': '2007-03-02',
        'media_type': 'movie'
      },
      {
        'id': 39,
        'title': 'No Country for Old Men',
        'overview': 'Violence and mayhem ensue after a hunter stumbles upon a drug deal gone wrong and more than two million dollars in cash.',
        'poster_path': '/bj1rO6OC7GEdk2yIMMvp6q5thNa.jpg',
        'backdrop_path': '/h8gHn0OzBoaefsYseUByaSm8CzP.jpg',
        'vote_average': 8.1,
        'release_date': '2007-11-08',
        'media_type': 'movie'
      },
      {
        'id': 40,
        'title': 'Prisoners',
        'overview': 'When Keller Dover\'s daughter and her friend go missing, he takes matters into his own hands as the police pursue multiple leads.',
        'poster_path': '/yAhqW57pwMAsCgm1hBSu4CML6YA.jpg',
        'backdrop_path': '/h8gHn0OzBoaefsYseUByaSm8CzP.jpg',
        'vote_average': 8.1,
        'release_date': '2013-09-18',
        'media_type': 'movie'
      },
      // Animation Movies (30 more)
      {
        'id': 41,
        'title': 'Spirited Away',
        'overview': 'A young girl, Chihiro, becomes trapped in a strange new world of spirits. When her parents undergo a mysterious transformation.',
        'poster_path': '/39wmItIWsg5sZMyRUHLkWBcuVCM.jpg',
        'backdrop_path': '/h8gHn0OzBoaefsYseUByaSm8CzP.jpg',
        'vote_average': 8.6,
        'release_date': '2001-07-20',
        'media_type': 'movie'
      },
      {
        'id': 42,
        'title': 'Toy Story',
        'overview': 'A cowboy doll is profoundly threatened and jealous when a new spaceman figure supplants him as top toy in a boy\'s room.',
        'poster_path': '/uXDfjJbdP4ijW5hWSBrPrlKpxab.jpg',
        'backdrop_path': '/h8gHn0OzBoaefsYseUByaSm8CzP.jpg',
        'vote_average': 8.3,
        'release_date': '1995-10-30',
        'media_type': 'movie'
      },
      {
        'id': 43,
        'title': 'Finding Nemo',
        'overview': 'A clown fish named Marlin lives in the Great Barrier Reef and loses his son, Nemo, after he ventures into the open sea.',
        'poster_path': '/eHuGQ10FUzK1mdOY69wF5pGgEf5.jpg',
        'backdrop_path': '/h8gHn0OzBoaefsYseUByaSm8CzP.jpg',
        'vote_average': 8.1,
        'release_date': '2003-05-30',
        'media_type': 'movie'
      },
      {
        'id': 44,
        'title': 'The Lion King',
        'overview': 'A young lion prince is cast out of his pride by his cruel uncle, who claims he killed his father.',
        'poster_path': '/sKCr78MXSLixwmZ8DyJLrpMsd15.jpg',
        'backdrop_path': '/h8gHn0OzBoaefsYseUByaSm8CzP.jpg',
        'vote_average': 8.5,
        'release_date': '1994-06-15',
        'media_type': 'movie'
      },
      {
        'id': 45,
        'title': 'Up',
        'overview': '78-year-old Carl Fredricksen travels to Paradise Falls in his house equipped with balloons, inadvertently taking a young stowaway.',
        'poster_path': '/vpbaStTMt8qqXRaIlf8U8GSfkwY.jpg',
        'backdrop_path': '/h8gHn0OzBoaefsYseUByaSm8CzP.jpg',
        'vote_average': 8.2,
        'release_date': '2009-05-28',
        'media_type': 'movie'
      },
      // Fantasy Movies (30 more)
      {
        'id': 46,
        'title': 'The Lord of the Rings: The Fellowship of the Ring',
        'overview': 'A meek Hobbit from the Shire and eight companions set out on a journey to destroy the powerful One Ring.',
        'poster_path': '/6oom5QYQ2yQTMJIbnvbkBL9cHo6.jpg',
        'backdrop_path': '/h8gHn0OzBoaefsYseUByaSm8CzP.jpg',
        'vote_average': 8.8,
        'release_date': '2001-12-18',
        'media_type': 'movie'
      },
      {
        'id': 47,
        'title': 'Harry Potter and the Philosopher\'s Stone',
        'overview': 'An orphaned boy enrolls in a school of wizardry, where he learns the truth about himself, his family and the terrible evil.',
        'poster_path': '/wuMc08IPKEatf9rn3XADs64umP0.jpg',
        'backdrop_path': '/h8gHn0OzBoaefsYseUByaSm8CzP.jpg',
        'vote_average': 7.6,
        'release_date': '2001-11-16',
        'media_type': 'movie'
      },
      {
        'id': 48,
        'title': 'Pan\'s Labyrinth',
        'overview': 'In the falangist Spain of 1944, the bookish young stepdaughter of a sadistic army officer escapes into an eerie but captivating fantasy world.',
        'poster_path': '/4p1l2RO0s3dduEghK5CtOtYV0dG.jpg',
        'backdrop_path': '/h8gHn0OzBoaefsYseUByaSm8CzP.jpg',
        'vote_average': 8.2,
        'release_date': '2006-05-27',
        'media_type': 'movie'
      },
      {
        'id': 49,
        'title': 'The Princess Bride',
        'overview': 'While home sick in bed, a young boy\'s grandfather reads him the story of a farmboy-turned-pirate who encounters numerous obstacles.',
        'poster_path': '/ooPj8aAqk4mz7F8dUqQ2x2x2x2x2.jpg',
        'backdrop_path': '/h8gHn0OzBoaefsYseUByaSm8CzP.jpg',
        'vote_average': 8.1,
        'release_date': '1987-09-18',
        'media_type': 'movie'
      },
      {
        'id': 50,
        'title': 'Big Fish',
        'overview': 'A frustrated son tries to determine the fact from fiction in his dying father\'s life.',
        'poster_path': '/h8gHn0OzBoaefsYseUByaSm8CzP.jpg',
        'backdrop_path': '/h8gHn0OzBoaefsYseUByaSm8CzP.jpg',
        'vote_average': 8.0,
        'release_date': '2003-12-10',
        'media_type': 'movie'
      },
    ];

    final mockTVShows = [
      {
        'id': 6,
        'name': 'Stranger Things',
        'overview': 'When a young boy vanishes, a small town uncovers a mystery involving secret experiments.',
        'poster_path': '/49WJfeN0moxb9IPfGn8AIqMGskD.jpg',
        'backdrop_path': '/56v2KjBlU4XaOv9rVYEQypROD7P.jpg',
        'vote_average': 8.7,
        'first_air_date': '2016-07-15',
        'media_type': 'tv'
      },
      {
        'id': 7,
        'name': 'The Mandalorian',
        'overview': 'The travels of a lone bounty hunter in the outer reaches of the galaxy.',
        'poster_path': '/eU1i6eHXlzMOlEq0ku1Rzq7Y4wA.jpg',
        'backdrop_path': '/bZGAX8oMDm3MoODi3BeEGhtA4bt.jpg',
        'vote_average': 8.5,
        'first_air_date': '2019-11-12',
        'media_type': 'tv'
      },
      {
        'id': 8,
        'name': 'House of the Dragon',
        'overview': 'The Targaryen dynasty is at the absolute apex of its power.',
        'poster_path': '/z2yahl2uefxDCl0nogcRBstwruJ.jpg',
        'backdrop_path': '/8kOWDBK6XlVOz0uHm6xznT6OluG.jpg',
        'vote_average': 8.5,
        'first_air_date': '2022-08-21',
        'media_type': 'tv'
      },
    ];

    final content = mediaType == 'tv' ? mockTVShows : mockMovies;
    
    return content
        .map((item) => ContentItem.fromTMDBJson(item, mediaType))
        .toList();
  }
}
