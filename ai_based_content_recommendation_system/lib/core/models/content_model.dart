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
    
    return ContentItem(
      id: json['id']['videoId'] ?? '',
      title: snippet['title'] ?? '',
      description: snippet['description'] ?? '',
      thumbnailUrl: highThumbnail['url'] ?? 
                    mediumThumbnail['url'] ?? 
                    defaultThumbnail['url'] ?? '',
      externalUrl: 'https://www.youtube.com/watch?v=${json['id']['videoId']}',
      platform: ContentType.youtube,
      category: ContentCategory.video,
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
    
    return ContentItem(
      id: json['id'] ?? '',
      title: snippet['title'] ?? '',
      description: snippet['description'] ?? '',
      thumbnailUrl: highThumbnail['url'] ?? 
                    mediumThumbnail['url'] ?? 
                    defaultThumbnail['url'] ?? '',
      externalUrl: 'https://www.youtube.com/watch?v=${json['id']}',
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
    
    return ContentItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['name'] ?? '',
      description: json['overview'] ?? '',
      thumbnailUrl: thumbnailUrl,
      platform: ContentType.tmdb,
      category: category,
      genres: (json['genre_ids'] as List<dynamic>?)
          ?.map((id) => id.toString())
          .toList() ?? [],
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
    
    return ContentItem(
      id: json['id'] ?? '',
      title: json['name'] ?? '',
      description: 'Track by $artistNames',
      thumbnailUrl: thumbnailUrl,
      audioUrl: null, // No preview playback - only recommendations
      externalUrl: json['external_urls']?['spotify'],
      platform: ContentType.spotify,
      category: ContentCategory.music,
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

