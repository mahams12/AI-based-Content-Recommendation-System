import 'package:hive_flutter/hive_flutter.dart';
import '../models/content_model.dart';
import 'firebase_sync_service.dart';

class FavoritesService {
  static const String _favoritesBoxName = 'user_favorites';
  
  late Box<Map> _favoritesBox;
  final FirebaseSyncService _firebaseSync = FirebaseSyncService();

  Future<void> init() async {
    _favoritesBox = await Hive.openBox<Map>(_favoritesBoxName);
  }

  Future<void> addToFavorites(ContentItem item) async {
    try {
      final favoriteItem = {
        'id': item.id,
        'title': item.title,
        'description': item.description,
        'thumbnailUrl': item.thumbnailUrl,
        'platform': item.platform.name,
        'channelName': item.channelName,
        'artistName': item.artistName,
        'duration': item.duration,
        'viewCount': item.viewCount,
        'publishedAt': item.publishedAt?.millisecondsSinceEpoch,
        'category': item.category.name,
        'addedAt': DateTime.now().millisecondsSinceEpoch,
      };

      // Save locally
      await _favoritesBox.put(item.id, favoriteItem);
      
      // Sync to Firebase if user is signed in
      await _firebaseSync.syncFavoriteToFirebase(item);
    } catch (e) {
      print('Error adding to favorites: $e');
    }
  }

  Future<void> removeFromFavorites(String itemId) async {
    try {
      await _favoritesBox.delete(itemId);
      // Also remove from Firebase
      await _firebaseSync.removeFavoriteFromFirebase(itemId);
    } catch (e) {
      print('Error removing from favorites: $e');
    }
  }

  Future<bool> isFavorite(String itemId) async {
    try {
      return _favoritesBox.containsKey(itemId);
    } catch (e) {
      print('Error checking if favorite: $e');
      return false;
    }
  }

  Future<List<ContentItem>> getFavorites() async {
    try {
      List<ContentItem> favorites = [];
      
      // Always load local favorites first (fast and reliable)
      final favoriteItems = _favoritesBox.values.toList();
      
      // Sort by added date (most recent first)
      favoriteItems.sort((a, b) {
        final addedAtA = a['addedAt'] as int? ?? 0;
        final addedAtB = b['addedAt'] as int? ?? 0;
        return addedAtB.compareTo(addedAtA);
      });

      favorites = favoriteItems.map((item) => _mapToContentItem(item)).toList();
      
      // If user is signed in, try to sync with Firebase (non-blocking, with timeout)
      if (_firebaseSync.isSignedIn && favorites.isEmpty) {
        try {
          final firebaseFavorites = await _firebaseSync.getFavoritesFromFirebase()
              .timeout(const Duration(seconds: 5), onTimeout: () {
            print('⚠️ Firebase favorites fetch timed out, using local favorites');
            return <ContentItem>[];
          });
          
          if (firebaseFavorites.isNotEmpty) {
            favorites = firebaseFavorites;
            // Also sync Firebase favorites to local storage
            for (final item in firebaseFavorites) {
              final favoriteItem = {
                'id': item.id,
                'title': item.title,
                'description': item.description,
                'thumbnailUrl': item.thumbnailUrl,
                'platform': item.platform.name,
                'channelName': item.channelName,
                'artistName': item.artistName,
                'duration': item.duration,
                'viewCount': item.viewCount,
                'publishedAt': item.publishedAt?.millisecondsSinceEpoch,
                'category': item.category.name,
                'addedAt': DateTime.now().millisecondsSinceEpoch,
              };
              await _favoritesBox.put(item.id, favoriteItem);
            }
          }
        } catch (e) {
          print('⚠️ Error syncing Firebase favorites (non-critical): $e');
          // Continue with local favorites
        }
      }

      return favorites;
    } catch (e) {
      print('❌ Error getting favorites: $e');
      // Fallback to empty list on error
      return [];
    }
  }

  Future<void> clearAllFavorites() async {
    try {
      await _favoritesBox.clear();
      // Also clear from Firebase
      await _firebaseSync.clearFavoritesFromFirebase();
    } catch (e) {
      print('Error clearing favorites: $e');
    }
  }

  ContentItem _mapToContentItem(Map item) {
    return ContentItem(
      id: item['id'] as String,
      title: item['title'] as String,
      description: item['description'] as String,
      thumbnailUrl: item['thumbnailUrl'] as String,
      platform: ContentType.values.firstWhere(
        (e) => e.name == item['platform'],
        orElse: () => ContentType.youtube,
      ),
      category: ContentCategory.values.firstWhere(
        (e) => e.name == item['category'],
        orElse: () => ContentCategory.video,
      ),
      channelName: item['channelName'] as String?,
      artistName: item['artistName'] as String?,
      duration: item['duration'] as String?,
      viewCount: item['viewCount'] as int?,
      publishedAt: item['publishedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(item['publishedAt'] as int)
          : null,
    );
  }

  Future<void> close() async {
    await _favoritesBox.close();
  }
}
