import 'package:hive_flutter/hive_flutter.dart';
import '../models/content_model.dart';
import 'firebase_sync_service.dart';

class HistoryService {
  static const String _historyBoxName = 'user_history';
  static const int _maxHistoryItems = 100;
  
  late Box<Map> _historyBox;
  final FirebaseSyncService _firebaseSync = FirebaseSyncService();

  Future<void> init() async {
    try {
      if (!_historyBox.isOpen) {
        _historyBox = await Hive.openBox<Map>(_historyBoxName);
        print('✅ History service initialized');
      }
    } catch (e) {
      print('❌ Error initializing history service: $e');
      // Try to reinitialize
      try {
        _historyBox = await Hive.openBox<Map>(_historyBoxName);
      } catch (e2) {
        print('❌ Failed to reinitialize history service: $e2');
      }
    }
  }

  Future<void> addToHistory(ContentItem item) async {
    try {
      print('📝 Adding to history: ${item.title} (${item.id})');
      print('📝 Platform: ${item.platform.name}, Category: ${item.category.name}');
      
      // Ensure box is initialized
      if (!_historyBox.isOpen) {
        await init();
      }
      
      // Create unique key combining platform and ID to avoid conflicts
      // This ensures movies, videos, and songs don't overwrite each other
      final uniqueKey = '${item.platform.name}_${item.id}';
      
      final historyItem = {
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
        'externalUrl': item.externalUrl, // Add externalUrl for links
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Remove if already exists to avoid duplicates (using unique key)
      await _historyBox.delete(uniqueKey);
      
      // Add to beginning of list (local storage) using unique key
      await _historyBox.put(uniqueKey, historyItem);
      print('✅ Saved to local history: ${item.title} (${item.platform.name}) with key: $uniqueKey');
      
      // Sync to Firebase if user is signed in (non-blocking, with timeout)
      if (_firebaseSync.isSignedIn) {
        try {
          await _firebaseSync.syncHistoryToFirebase(item).timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              print('⚠️ Firebase history sync timed out (non-critical)');
            },
          );
        } catch (e) {
          print('⚠️ Firebase history sync error (non-critical): $e');
        }
      }
      
      // Limit history size
      await _limitHistorySize();
      print('✅ Successfully added ${item.title} to history');
    } catch (e) {
      print('❌ Error adding to history: $e');
      rethrow; // Re-throw so caller knows it failed
    }
  }

  Future<void> removeFromHistory(String itemId) async {
    try {
      // Find and delete by ID across all platforms (since we use platform_id as key)
      final keysToDelete = <String>[];
      for (final key in _historyBox.keys) {
        final item = _historyBox.get(key);
        if (item != null && item['id'] == itemId) {
          keysToDelete.add(key.toString());
        }
      }
      for (final key in keysToDelete) {
        await _historyBox.delete(key);
        print('🗑️ Removed history item with key: $key');
      }
      // Also remove from Firebase
      await _firebaseSync.removeHistoryFromFirebase(itemId);
    } catch (e) {
      print('Error removing from history: $e');
    }
  }

  Future<void> clearAllHistory() async {
    try {
      await _historyBox.clear();
      // Also clear from Firebase
      await _firebaseSync.clearHistoryFromFirebase();
    } catch (e) {
      print('Error clearing history: $e');
    }
  }

  Future<List<ContentItem>> getHistory() async {
    try {
      // Ensure box is initialized
      if (!_historyBox.isOpen) {
        await init();
      }
      
      List<ContentItem> history = [];
      
      // If user is signed in, get from Firebase first (for cross-device sync)
      if (_firebaseSync.isSignedIn) {
        try {
          final firebaseHistory = await _firebaseSync.getHistoryFromFirebase().timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              print('⚠️ Firebase history fetch timed out, using local');
              return <ContentItem>[];
            },
          );
          if (firebaseHistory.isNotEmpty) {
            // Merge Firebase history with local history
            history = firebaseHistory;
            // Also sync Firebase history to local storage
            for (final item in firebaseHistory) {
              final historyItem = {
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
                'externalUrl': item.externalUrl,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
              };
              await _historyBox.put(item.id, historyItem);
            }
          }
        } catch (e) {
          print('⚠️ Error fetching Firebase history: $e, using local');
        }
      }
      
      // If no Firebase history or user not signed in, use local history
      if (history.isEmpty) {
        final historyItems = _historyBox.values.toList();
        
        // Filter out invalid items and sort by timestamp (most recent first)
        final validItems = historyItems.where((item) {
          final title = item['title'] as String? ?? '';
          final platform = item['platform'] as String? ?? '';
          return title.isNotEmpty && platform.isNotEmpty;
        }).toList();
        
        validItems.sort((a, b) {
          final timestampA = a['timestamp'] as int? ?? 0;
          final timestampB = b['timestamp'] as int? ?? 0;
          return timestampB.compareTo(timestampA);
        });

        history = validItems.map((item) => _mapToContentItem(item)).toList();
        print('📚 Loaded ${history.length} items from local history');
        print('📚 Platforms: ${history.map((h) => h.platform.name).toSet().join(", ")}');
      }

      print('📚 Loaded ${history.length} history items');
      return history;
    } catch (e) {
      print('❌ Error getting history: $e');
      // Fallback to local history on error
      try {
        if (!_historyBox.isOpen) {
          await init();
        }
        final historyItems = _historyBox.values.toList();
        
        // Filter out invalid items
        final validItems = historyItems.where((item) {
          final title = item['title'] as String? ?? '';
          final platform = item['platform'] as String? ?? '';
          return title.isNotEmpty && platform.isNotEmpty;
        }).toList();
        
        validItems.sort((a, b) {
          final timestampA = a['timestamp'] as int? ?? 0;
          final timestampB = b['timestamp'] as int? ?? 0;
          return timestampB.compareTo(timestampA);
        });
        final fallbackHistory = validItems.map((item) => _mapToContentItem(item)).toList();
        print('📚 Fallback: Loaded ${fallbackHistory.length} history items');
        print('📚 Platforms: ${fallbackHistory.map((h) => h.platform.name).toSet().join(", ")}');
        return fallbackHistory;
      } catch (e2) {
        print('❌ Fallback also failed: $e2');
        return [];
      }
    }
  }

  Future<void> _limitHistorySize() async {
    try {
      final items = _historyBox.values.toList();
      if (items.length > _maxHistoryItems) {
        // Sort by timestamp and remove oldest items
        items.sort((a, b) {
          final timestampA = a['timestamp'] as int? ?? 0;
          final timestampB = b['timestamp'] as int? ?? 0;
          return timestampA.compareTo(timestampB);
        });

        // Remove excess items - need to find keys for these items
        final itemsToRemove = items.take(items.length - _maxHistoryItems);
        for (final itemToRemove in itemsToRemove) {
          // Find the key for this item
          for (final key in _historyBox.keys) {
            final item = _historyBox.get(key);
            if (item != null && 
                item['id'] == itemToRemove['id'] && 
                item['platform'] == itemToRemove['platform']) {
              await _historyBox.delete(key);
              break;
            }
          }
        }
      }
    } catch (e) {
      print('Error limiting history size: $e');
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
      externalUrl: item['externalUrl'] as String?, // Include externalUrl for links
    );
  }

  Future<void> close() async {
    await _historyBox.close();
  }
}
