class AppConstants {
  // App Information
  static const String appName = 'Content Nation';
  static const String appVersion = '1.0.0';
  
  // API Keys
  static const String youtubeApiKey = 'AIzaSyDdwTVftDl6nRqRuofWlfx1p8-enTPNFnc';
  static const String spotifyClientId = '071b9c2312f64b2495e7135f3dfbf317';
  static const String tmdbApiKey = '146bd026e1a4e8b5998458984ac771ce';
  
  // API Endpoints
  static const String youtubeBaseUrl = 'https://www.googleapis.com/youtube/v3';
  static const String spotifyBaseUrl = 'https://api.spotify.com/v1';
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p';
  
  // Rate Limits
  static const int youtubeDailyLimit = 10000;
  static const int spotifyHourlyLimit = 2000;
  static const int tmdbRateLimit = 40; // per 10 seconds
  
  // Content Types
  static const String contentTypeYouTube = 'youtube';
  static const String contentTypeSpotify = 'spotify';
  static const String contentTypeTMDB = 'tmdb';
  
  // Mood Types
  static const List<String> moodTypes = [
    'energetic',
    'relaxed',
    'sad',
    'happy',
    'focused',
    'romantic',
    'adventurous',
    'nostalgic',
  ];
  
  // Genres
  static const List<String> youtubeGenres = [
    'Music',
    'Entertainment',
    'Gaming',
    'Sports',
    'News',
    'Education',
    'Science & Technology',
    'Travel',
    'Comedy',
    'Howto & Style',
  ];
  
  static const List<String> spotifyGenres = [
    'pop',
    'rock',
    'hip-hop',
    'electronic',
    'jazz',
    'classical',
    'country',
    'r&b',
    'reggae',
    'blues',
  ];
  
  static const List<String> tmdbGenres = [
    'Action',
    'Adventure',
    'Animation',
    'Comedy',
    'Crime',
    'Documentary',
    'Drama',
    'Family',
    'Fantasy',
    'History',
    'Horror',
    'Music',
    'Mystery',
    'Romance',
    'Science Fiction',
    'TV Movie',
    'Thriller',
    'War',
    'Western',
  ];
  
  // Performance Targets
  static const int maxAppLaunchTime = 3000; // 3 seconds
  static const int maxRecommendationsLoadTime = 2000; // 2 seconds
  static const int maxSearchResultsTime = 1500; // 1.5 seconds
  static const int maxContentMetadataTime = 1000; // 1 second
  static const int maxMemoryUsage = 150; // 150MB
  
  // Cache Settings
  static const int cacheExpirationHours = 24;
  static const int maxCacheSize = 100; // MB
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 4.0;
}
