import 'package:hive_flutter/hive_flutter.dart';
import '../models/content_model.dart';

class HistoryService {
  static const String _historyBoxName = 'user_history';
  static const int _maxHistoryItems = 100;
  
  late Box<Map> _historyBox;

  Future<void> init() async {
    _historyBox = await Hive.openBox<Map>(_historyBoxName);
  }

  Future<void> addToHistory(ContentItem item) async {
    try {
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

      // Remove if already exists to avoid duplicates
      await removeFromHistory(item.id);
      
      // Add to beginning of list
      await _historyBox.put(item.id, historyItem);
      
      // Limit history size
      await _limitHistorySize();
    } catch (e) {
      print('Error adding to history: $e');
    }
  }

  Future<void> removeFromHistory(String itemId) async {
    try {
      await _historyBox.delete(itemId);
    } catch (e) {
      print('Error removing from history: $e');
    }
  }

  Future<void> clearAllHistory() async {
    try {
      await _historyBox.clear();
    } catch (e) {
      print('Error clearing history: $e');
    }
  }

  Future<List<ContentItem>> getHistory() async {
    try {
      final historyItems = _historyBox.values.toList();
      
      // Sort by timestamp (most recent first)
      historyItems.sort((a, b) {
        final timestampA = a['timestamp'] as int? ?? 0;
        final timestampB = b['timestamp'] as int? ?? 0;
        return timestampB.compareTo(timestampA);
      });

      return historyItems.map((item) => _mapToContentItem(item)).toList();
    } catch (e) {
      print('Error getting history: $e');
      return [];
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
    );
  }

  Future<void> close() async {
    await _historyBox.close();
  }
}
