import 'package:hive_flutter/hive_flutter.dart';
import '../models/content_model.dart';
import 'firebase_sync_service.dart';

class HistoryService {
  static const String _historyBoxName = 'user_history';
  static const int _maxHistoryItems = 100;
  
  late Box<Map> _historyBox;
  final FirebaseSyncService _firebaseSync = FirebaseSyncService();

  Future<void> init() async {
    _historyBox = await Hive.openBox<Map>(_historyBoxName);
  }

  Future<void> addToHistory(ContentItem item) async {
    try {
      print('📝 Adding to history: ${item.title} (${item.id})');
      
      // Ensure box is initialized
      if (!_historyBox.isOpen) {
        await init();
      }
      
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

      // Remove if already exists to avoid duplicates
      await removeFromHistory(item.id);
      
      // Add to beginning of list (local storage)
      await _historyBox.put(item.id, historyItem);
      print('✅ Saved to local history: ${item.title}');
      
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
      await _historyBox.delete(itemId);
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
      List<ContentItem> history = [];
      
      // If user is signed in, get from Firebase first (for cross-device sync)
      if (_firebaseSync.isSignedIn) {
        final firebaseHistory = await _firebaseSync.getHistoryFromFirebase();
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
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            };
            await _historyBox.put(item.id, historyItem);
          }
        }
      }
      
      // If no Firebase history or user not signed in, use local history
      if (history.isEmpty) {
      final historyItems = _historyBox.values.toList();
      
      // Sort by timestamp (most recent first)
      historyItems.sort((a, b) {
        final timestampA = a['timestamp'] as int? ?? 0;
        final timestampB = b['timestamp'] as int? ?? 0;
        return timestampB.compareTo(timestampA);
      });

        history = historyItems.map((item) => _mapToContentItem(item)).toList();
      }

      return history;
    } catch (e) {
      print('Error getting history: $e');
      // Fallback to local history on error
      try {
        final historyItems = _historyBox.values.toList();
        historyItems.sort((a, b) {
          final timestampA = a['timestamp'] as int? ?? 0;
          final timestampB = b['timestamp'] as int? ?? 0;
          return timestampB.compareTo(timestampA);
        });
        return historyItems.map((item) => _mapToContentItem(item)).toList();
      } catch (e2) {
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

        // Remove excess items
        final itemsToRemove = items.take(items.length - _maxHistoryItems);
        for (final item in itemsToRemove) {
          await _historyBox.delete(item['id']);
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
