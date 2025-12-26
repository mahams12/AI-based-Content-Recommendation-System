import 'package:equatable/equatable.dart';

enum ContentType {
  youtube,
  spotify,
  tmdb,
}

enum ContentCategory {
  video,
  music,
  movie,
  tvShow,
  playlist,
}

class ContentItem extends Equatable {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String? videoUrl;
  final String? audioUrl;
  final String? externalUrl;
  final ContentType platform;
  final ContentCategory category;
  final List<String> genres;
  final String? duration;
  final int? durationSeconds;
  final double? rating;
  final int? viewCount;
  final int? likeCount;
  final DateTime? publishedAt;
  final String? channelName;
  final String? artistName;
  final String? albumName;
  final String? contentType;
  final String? videoFormat;
  final Map<String, dynamic>? metadata;

  const ContentItem({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    this.videoUrl,
    this.audioUrl,
    this.externalUrl,
    required this.platform,
    required this.category,
    this.genres = const [],
    this.duration,
    this.durationSeconds,
    this.rating,
    this.viewCount,
    this.likeCount,
    this.publishedAt,
    this.channelName,
    this.artistName,
    this.albumName,
    this.contentType,
    this.videoFormat,
    this.metadata,
  });

  // YouTube JSON parsing
  factory ContentItem.fromYouTubeJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] ?? {};
    final thumbnails = snippet['thumbnails'] ?? {};
    final defaultThumbnail = thumbnails['default'] ?? {};
    final mediumThumbnail = thumbnails['medium'] ?? {};
    final highThumbnail = thumbnails['high'] ?? {};
    
    // Handle both search result format (id.videoId) and trending format (id as string)
    final videoId = json['id'] is Map 
        ? (json['id']['videoId'] ?? '')
        : (json['id'] ?? '');
    final title = snippet['title'] ?? '';
    final description = snippet['description'] ?? '';
    final categoryId = snippet['categoryId'] as String?;
    
    // Check if this is a mock video ID (starts with 'youtube_video_')
    // If so, create a search URL instead of a direct video URL
    final String externalUrl;
    if (videoId.startsWith('youtube_video_') || videoId.isEmpty) {
      // For mock content, redirect to YouTube search
      externalUrl = 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(title)}';
    } else {
      // For real YouTube video IDs, use direct video URL
      externalUrl = 'https://www.youtube.com/watch?v=$videoId';
    }
    
    // Extract genres from YouTube categoryId and tags
    final genres = <String>[];
    
    // Map YouTube category IDs to genres
    final categoryMap = {
      '1': 'Film & Animation',
      '2': 'Autos & Vehicles',
      '10': 'Music',
      '15': 'Pets & Animals',
      '17': 'Sports',
      '19': 'Travel & Events',
      '20': 'Gaming',
      '22': 'People & Blogs',
      '23': 'Comedy',
      '24': 'Entertainment',
      '25': 'News & Politics',
      '26': 'Howto & Style',
      '27': 'Education',
      '28': 'Science & Technology',
    };
    
    if (categoryId != null && categoryMap.containsKey(categoryId)) {
      final categoryName = categoryMap[categoryId]!;
      // Map to mood-compatible genres
      if (categoryName.contains('Music')) genres.add('Pop');
      if (categoryName.contains('Comedy')) genres.add('Comedy');
      if (categoryName.contains('Gaming')) genres.add('Action');
      if (categoryName.contains('Education')) genres.add('Documentary');
      if (categoryName.contains('Entertainment')) genres.add('Comedy');
    }
    
    // Extract genres from tags if available
    final tags = snippet['tags'] as List<dynamic>?;
    if (tags != null) {
      for (final tag in tags) {
        final tagStr = tag.toString().toLowerCase();
        // Map common tags to genres
        if (tagStr.contains('music') || tagStr.contains('song')) genres.add('Pop');
        if (tagStr.contains('comedy') || tagStr.contains('funny')) genres.add('Comedy');
        if (tagStr.contains('action') || tagStr.contains('fight')) genres.add('Action');
        if (tagStr.contains('drama') || tagStr.contains('emotional')) genres.add('Drama');
        if (tagStr.contains('romance') || tagStr.contains('love')) genres.add('Romance');
        if (tagStr.contains('horror') || tagStr.contains('scary')) genres.add('Horror');
        if (tagStr.contains('documentary') || tagStr.contains('educational')) genres.add('Documentary');
      }
    }
    
    // Infer from title/description if no genres found
    if (genres.isEmpty) {
      final combinedText = '${title.toLowerCase()} ${description.toLowerCase()}';
      if (combinedText.contains('music') || combinedText.contains('song') || combinedText.contains('album')) {
        genres.add('Pop');
      }
      if (combinedText.contains('comedy') || combinedText.contains('funny') || combinedText.contains('laugh')) {
        genres.add('Comedy');
      }
      if (combinedText.contains('action') || combinedText.contains('fight') || combinedText.contains('adventure')) {
        genres.add('Action');
      }
      if (combinedText.contains('drama') || combinedText.contains('emotional') || combinedText.contains('sad')) {
        genres.add('Drama');
      }
    }
    
    return ContentItem(
      id: videoId,
      title: title,
      description: description,
      thumbnailUrl: highThumbnail['url'] ?? 
                    mediumThumbnail['url'] ?? 
                    defaultThumbnail['url'] ?? '',
      externalUrl: externalUrl,
      platform: ContentType.youtube,
      category: ContentCategory.video,
      genres: genres,
      channelName: snippet['channelTitle'] ?? '',
      contentType: 'Video',
      videoFormat: 'Standard',
      publishedAt: snippet['publishedAt'] != null 
          ? DateTime.tryParse(snippet['publishedAt']) 
          : null,
      metadata: json,
    );
  }

  // YouTube Trending JSON parsing
  factory ContentItem.fromYouTubeTrendingJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] ?? {};
    final statistics = json['statistics'] ?? {};
    final thumbnails = snippet['thumbnails'] ?? {};
    final defaultThumbnail = thumbnails['default'] ?? {};
    final mediumThumbnail = thumbnails['medium'] ?? {};
    final highThumbnail = thumbnails['high'] ?? {};
    
    final videoId = json['id'] ?? '';
    final title = snippet['title'] ?? '';
    
    // Check if this is a mock video ID (starts with 'youtube_video_')
    // If so, create a search URL instead of a direct video URL
    final String externalUrl;
    if (videoId.startsWith('youtube_video_') || videoId.isEmpty) {
      // For mock content, redirect to YouTube search
      externalUrl = 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(title)}';
    } else {
      // For real YouTube video IDs, use direct video URL
      externalUrl = 'https://www.youtube.com/watch?v=$videoId';
    }
    
    return ContentItem(
      id: videoId,
      title: title,
      description: snippet['description'] ?? '',
      thumbnailUrl: highThumbnail['url'] ?? 
                    mediumThumbnail['url'] ?? 
                    defaultThumbnail['url'] ?? '',
      externalUrl: externalUrl,
      platform: ContentType.youtube,
      category: ContentCategory.video,
      channelName: snippet['channelTitle'] ?? '',
      contentType: 'Video',
      videoFormat: 'Standard',
      viewCount: int.tryParse(statistics['viewCount'] ?? '0'),
      likeCount: int.tryParse(statistics['likeCount'] ?? '0'),
      publishedAt: snippet['publishedAt'] != null 
          ? DateTime.tryParse(snippet['publishedAt']) 
          : null,
      metadata: json,
    );
  }

  // TMDB JSON parsing
  factory ContentItem.fromTMDBJson(Map<String, dynamic> json, String type) {
    final posterPath = json['poster_path'] ?? json['backdrop_path'];
    final thumbnailUrl = posterPath != null 
        ? 'https://image.tmdb.org/t/p/w500$posterPath'
        : 'https://images.unsplash.com/photo-1489599905202-4e7b9d7e8b7e?w=300&h=450&fit=crop&crop=center';
    
    ContentCategory category;
    if (type == 'movie' || json['media_type'] == 'movie') {
      category = ContentCategory.movie;
    } else if (type == 'tv' || json['media_type'] == 'tv') {
      category = ContentCategory.tvShow;
    } else {
      category = ContentCategory.movie; // default
    }
    
    final contentId = json['id']?.toString() ?? '';
    final externalUrl = category == ContentCategory.movie
        ? 'https://www.themoviedb.org/movie/$contentId'
        : 'https://www.themoviedb.org/tv/$contentId';
    
    // Map TMDB genre IDs to genre names
    final Map<int, String> tmdbGenreMap = {
      28: 'Action',
      12: 'Adventure',
      16: 'Animation',
      35: 'Comedy',
      80: 'Crime',
      99: 'Documentary',
      18: 'Drama',
      10751: 'Family',
      14: 'Fantasy',
      36: 'History',
      27: 'Horror',
      10402: 'Music',
      9648: 'Mystery',
      10749: 'Romance',
      878: 'Sci-Fi',
      10770: 'TV Movie',
      53: 'Thriller',
      10752: 'War',
      37: 'Western',
    };
    
    final genreIds = (json['genre_ids'] as List<dynamic>?) ?? [];
    final genreNames = genreIds
        .map((id) => tmdbGenreMap[id as int])
        .where((name) => name != null)
        .cast<String>()
        .toList();
    
    return ContentItem(
      id: contentId,
      title: json['title'] ?? json['name'] ?? '',
      description: json['overview'] ?? '',
      thumbnailUrl: thumbnailUrl,
      externalUrl: externalUrl,
      platform: ContentType.tmdb,
      category: category,
      genres: genreNames,
      rating: (json['vote_average'] as num?)?.toDouble(),
      contentType: category == ContentCategory.movie ? 'Movie' : 'TV Show',
      videoFormat: 'Standard',
      publishedAt: json['release_date'] != null 
          ? DateTime.tryParse(json['release_date']) 
          : (json['first_air_date'] != null 
              ? DateTime.tryParse(json['first_air_date']) 
              : null),
      metadata: json,
    );
  }

  // Spotify Track JSON parsing
  factory ContentItem.fromSpotifyJson(Map<String, dynamic> json) {
    final album = json['album'] ?? {};
    final images = album['images'] as List<dynamic>? ?? [];
    final thumbnailUrl = images.isNotEmpty 
        ? images.first['url'] 
        : 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=300&h=300&fit=crop&crop=center';
    
    final artists = json['artists'] as List<dynamic>? ?? [];
    final artistNames = artists.map((artist) => artist['name']).join(', ');
    
    final durationMs = json['duration_ms'] as int? ?? 0;
    final duration = Duration(milliseconds: durationMs);
    final durationString = '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    
    // Extract genres from Spotify data
    final genres = <String>[];
    
    // Get genres from album if available
    final albumGenres = album['genres'] as List<dynamic>?;
    if (albumGenres != null && albumGenres.isNotEmpty) {
      genres.addAll(albumGenres.map((g) => g.toString()).toList());
    }
    
    // Get genres from artists if available
    for (final artist in artists) {
      final artistGenres = artist['genres'] as List<dynamic>?;
      if (artistGenres != null && artistGenres.isNotEmpty) {
        genres.addAll(artistGenres.map((g) => g.toString()).toList());
      }
    }
    
    // Normalize genre names to match mood filtering expectations
    final normalizedGenres = genres.map((genre) {
      final g = genre.toLowerCase();
      // Map Spotify genres to mood-compatible genres
      if (g.contains('pop')) return 'Pop';
      if (g.contains('rock')) return 'Rock';
      if (g.contains('hip') || g.contains('rap')) return 'Hip-Hop';
      if (g.contains('electronic') || g.contains('edm') || g.contains('dance')) return 'Electronic';
      if (g.contains('jazz')) return 'Jazz';
      if (g.contains('classical')) return 'Classical';
      if (g.contains('country')) return 'Country';
      if (g.contains('r&b') || g.contains('rnb') || g.contains('soul')) return 'R&B';
      if (g.contains('reggae')) return 'Reggae';
      if (g.contains('blues')) return 'Blues';
      if (g.contains('metal')) return 'Metal';
      if (g.contains('punk')) return 'Punk';
      if (g.contains('alternative') || g.contains('indie')) return 'Alternative';
      if (g.contains('ambient')) return 'Ambient';
      if (g.contains('acoustic')) return 'Acoustic';
      return genre; // Return original if no match
    }).where((g) => g.isNotEmpty).toSet().toList();
    
    // Infer from title/artist if no genres found
    if (normalizedGenres.isEmpty) {
      final combinedText = '${json['name']?.toString().toLowerCase() ?? ''} ${artistNames.toLowerCase()}';
      if (combinedText.contains('pop') || combinedText.contains('dance')) normalizedGenres.add('Pop');
      if (combinedText.contains('rock')) normalizedGenres.add('Rock');
      if (combinedText.contains('hip') || combinedText.contains('rap')) normalizedGenres.add('Hip-Hop');
      if (combinedText.contains('electronic') || combinedText.contains('edm')) normalizedGenres.add('Electronic');
      if (combinedText.contains('jazz')) normalizedGenres.add('Jazz');
      if (combinedText.contains('classical')) normalizedGenres.add('Classical');
      if (combinedText.contains('metal')) normalizedGenres.add('Metal');
      if (combinedText.contains('punk')) normalizedGenres.add('Punk');
      if (combinedText.contains('acoustic')) normalizedGenres.add('Acoustic');
    }
    
    return ContentItem(
      id: json['id'] ?? '',
      title: json['name'] ?? '',
      description: 'Track by $artistNames',
      thumbnailUrl: thumbnailUrl,
      audioUrl: null, // No preview playback - only recommendations
      externalUrl: json['external_urls']?['spotify'],
      platform: ContentType.spotify,
      category: ContentCategory.music,
      genres: normalizedGenres,
      duration: durationString,
      durationSeconds: duration.inSeconds,
      artistName: artistNames,
      albumName: album['name'],
      contentType: 'Music',
      videoFormat: null,
      metadata: json,
    );
  }

  // Spotify Playlist JSON parsing
  factory ContentItem.fromSpotifyPlaylistJson(Map<String, dynamic> json) {
    final images = json['images'] as List<dynamic>? ?? [];
    final thumbnailUrl = images.isNotEmpty 
        ? images.first['url'] 
        : 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=300&h=300&fit=crop&crop=center';
    
    final tracks = json['tracks'] ?? {};
    final trackCount = tracks['total'] as int? ?? 0;
    
    return ContentItem(
      id: json['id'] ?? '',
      title: json['name'] ?? '',
      description: json['description'] ?? 'Playlist with $trackCount tracks',
      thumbnailUrl: thumbnailUrl,
      externalUrl: json['external_urls']?['spotify'],
      platform: ContentType.spotify,
      category: ContentCategory.playlist,
      contentType: 'Playlist',
      videoFormat: null,
      metadata: json,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'externalUrl': externalUrl,
      'platform': platform.name,
      'category': category.name,
      'genres': genres,
      'duration': duration,
      'durationSeconds': durationSeconds,
      'rating': rating,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'publishedAt': publishedAt?.toIso8601String(),
      'channelName': channelName,
      'artistName': artistName,
      'albumName': albumName,
      'contentType': contentType,
      'videoFormat': videoFormat,
      'metadata': metadata,
    };
  }

  // Create copy with updated fields
  ContentItem copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    String? videoUrl,
    String? audioUrl,
    String? externalUrl,
    ContentType? platform,
    ContentCategory? category,
    List<String>? genres,
    String? duration,
    int? durationSeconds,
    double? rating,
    int? viewCount,
    int? likeCount,
    DateTime? publishedAt,
    String? channelName,
    String? artistName,
    String? albumName,
    String? contentType,
    String? videoFormat,
    Map<String, dynamic>? metadata,
  }) {
    return ContentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      externalUrl: externalUrl ?? this.externalUrl,
      platform: platform ?? this.platform,
      category: category ?? this.category,
      genres: genres ?? this.genres,
      duration: duration ?? this.duration,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      rating: rating ?? this.rating,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      publishedAt: publishedAt ?? this.publishedAt,
      channelName: channelName ?? this.channelName,
      artistName: artistName ?? this.artistName,
      albumName: albumName ?? this.albumName,
      contentType: contentType ?? this.contentType,
      videoFormat: videoFormat ?? this.videoFormat,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        thumbnailUrl,
        videoUrl,
        audioUrl,
        externalUrl,
        platform,
        category,
        genres,
        duration,
        durationSeconds,
        rating,
        viewCount,
        likeCount,
        publishedAt,
        channelName,
        artistName,
        albumName,
        contentType,
        videoFormat,
        metadata,
      ];
}

