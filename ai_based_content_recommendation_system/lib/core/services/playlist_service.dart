import 'package:hive_flutter/hive_flutter.dart';
import '../models/content_model.dart';

class PlaylistItem {
  final String id;
  final String playlistId;
  final ContentItem content;
  final DateTime addedAt;

  PlaylistItem({
    required this.id,
    required this.playlistId,
    required this.content,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'playlistId': playlistId,
      'contentId': content.id,
      'contentTitle': content.title,
      'contentDescription': content.description,
      'contentThumbnailUrl': content.thumbnailUrl,
      'contentPlatform': content.platform.name,
      'contentCategory': content.category.name,
      'contentChannelName': content.channelName,
      'contentArtistName': content.artistName,
      'contentDuration': content.duration,
      'contentViewCount': content.viewCount,
      'contentPublishedAt': content.publishedAt?.millisecondsSinceEpoch,
      'addedAt': addedAt.millisecondsSinceEpoch,
    };
  }

  factory PlaylistItem.fromMap(Map<String, dynamic> map) {
    return PlaylistItem(
      id: map['id'] as String,
      playlistId: map['playlistId'] as String,
      content: ContentItem(
        id: map['contentId'] as String,
        title: map['contentTitle'] as String,
        description: map['contentDescription'] as String,
        thumbnailUrl: map['contentThumbnailUrl'] as String,
        platform: ContentType.values.firstWhere(
          (e) => e.name == map['contentPlatform'],
          orElse: () => ContentType.youtube,
        ),
        category: ContentCategory.values.firstWhere(
          (e) => e.name == map['contentCategory'],
          orElse: () => ContentCategory.video,
        ),
        channelName: map['contentChannelName'] as String?,
        artistName: map['contentArtistName'] as String?,
        duration: map['contentDuration'] as String?,
        viewCount: map['contentViewCount'] as int?,
        publishedAt: map['contentPublishedAt'] != null 
            ? DateTime.fromMillisecondsSinceEpoch(map['contentPublishedAt'] as int)
            : null,
      ),
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['addedAt'] as int),
    );
  }
}

class UserPlaylist {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PlaylistItem> items;

  UserPlaylist({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }

  factory UserPlaylist.fromMap(Map<String, dynamic> map) {
    return UserPlaylist(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      items: (map['items'] as List<dynamic>?)
          ?.map((item) => PlaylistItem.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class PlaylistService {
  static const String _playlistsBoxName = 'user_playlists';
  
  late Box<Map> _playlistsBox;

  Future<void> init() async {
    _playlistsBox = await Hive.openBox<Map>(_playlistsBoxName);
  }

  Future<String> createPlaylist({
    required String name,
    String description = '',
  }) async {
    try {
      final playlistId = DateTime.now().millisecondsSinceEpoch.toString();
      final playlist = UserPlaylist(
        id: playlistId,
        name: name,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _playlistsBox.put(playlistId, playlist.toMap());
      return playlistId;
    } catch (e) {
      print('Error creating playlist: $e');
      rethrow;
    }
  }

  Future<void> addToPlaylist(String playlistId, ContentItem content) async {
    try {
      final playlistData = _playlistsBox.get(playlistId);
      if (playlistData == null) {
        throw Exception('Playlist not found');
      }

      final playlist = UserPlaylist.fromMap(Map<String, dynamic>.from(playlistData));
      
      // Check if content already exists in playlist
      final existingItem = playlist.items.where((item) => item.content.id == content.id).firstOrNull;
      if (existingItem != null) {
        throw Exception('Content already exists in playlist');
      }

      final playlistItem = PlaylistItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        playlistId: playlistId,
        content: content,
        addedAt: DateTime.now(),
      );

      final updatedItems = [...playlist.items, playlistItem];
      final updatedPlaylist = UserPlaylist(
        id: playlist.id,
        name: playlist.name,
        description: playlist.description,
        createdAt: playlist.createdAt,
        updatedAt: DateTime.now(),
        items: updatedItems,
      );

      await _playlistsBox.put(playlistId, updatedPlaylist.toMap());
    } catch (e) {
      print('Error adding to playlist: $e');
      rethrow;
    }
  }

  Future<void> removeFromPlaylist(String playlistId, String contentId) async {
    try {
      final playlistData = _playlistsBox.get(playlistId);
      if (playlistData == null) {
        throw Exception('Playlist not found');
      }

      final playlist = UserPlaylist.fromMap(Map<String, dynamic>.from(playlistData));
      final updatedItems = playlist.items.where((item) => item.content.id != contentId).toList();
      
      final updatedPlaylist = UserPlaylist(
        id: playlist.id,
        name: playlist.name,
        description: playlist.description,
        createdAt: playlist.createdAt,
        updatedAt: DateTime.now(),
        items: updatedItems,
      );

      await _playlistsBox.put(playlistId, updatedPlaylist.toMap());
    } catch (e) {
      print('Error removing from playlist: $e');
      rethrow;
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    try {
      await _playlistsBox.delete(playlistId);
    } catch (e) {
      print('Error deleting playlist: $e');
      rethrow;
    }
  }

  Future<void> updatePlaylist(String playlistId, {String? name, String? description}) async {
    try {
      final playlistData = _playlistsBox.get(playlistId);
      if (playlistData == null) {
        throw Exception('Playlist not found');
      }

      final playlist = UserPlaylist.fromMap(Map<String, dynamic>.from(playlistData));
      final updatedPlaylist = UserPlaylist(
        id: playlist.id,
        name: name ?? playlist.name,
        description: description ?? playlist.description,
        createdAt: playlist.createdAt,
        updatedAt: DateTime.now(),
        items: playlist.items,
      );

      await _playlistsBox.put(playlistId, updatedPlaylist.toMap());
    } catch (e) {
      print('Error updating playlist: $e');
      rethrow;
    }
  }

  Future<List<UserPlaylist>> getPlaylists() async {
    try {
      final playlistsData = _playlistsBox.values.toList();
      
      // Sort by updated date (most recent first)
      playlistsData.sort((a, b) {
        final updatedAtA = a['updatedAt'] as int? ?? 0;
        final updatedAtB = b['updatedAt'] as int? ?? 0;
        return updatedAtB.compareTo(updatedAtA);
      });

      return playlistsData.map((data) => UserPlaylist.fromMap(Map<String, dynamic>.from(data))).toList();
    } catch (e) {
      print('Error getting playlists: $e');
      return [];
    }
  }

  Future<UserPlaylist?> getPlaylist(String playlistId) async {
    try {
      final playlistData = _playlistsBox.get(playlistId);
      if (playlistData == null) return null;
      
      return UserPlaylist.fromMap(Map<String, dynamic>.from(playlistData));
    } catch (e) {
      print('Error getting playlist: $e');
      return null;
    }
  }

  Future<void> close() async {
    await _playlistsBox.close();
  }
}
