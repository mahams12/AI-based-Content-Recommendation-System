import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/content_model.dart';

class FirebaseSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user ID from current user
  String? get _userId => _auth.currentUser?.uid;
  String? get _userEmail => _auth.currentUser?.email;

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Sync history to Firebase
  Future<void> syncHistoryToFirebase(ContentItem item) async {
    if (!isSignedIn || _userId == null) return;

    try {
      final historyData = {
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
        'timestamp': FieldValue.serverTimestamp(),
        'email': _userEmail,
      };

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('history')
          .doc(item.id)
          .set(historyData, SetOptions(merge: true));
    } catch (e) {
      print('Error syncing history to Firebase: $e');
    }
  }

  // Sync favorites to Firebase
  Future<void> syncFavoriteToFirebase(ContentItem item) async {
    if (!isSignedIn || _userId == null) return;

    try {
      final favoriteData = {
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
        'addedAt': FieldValue.serverTimestamp(),
        'email': _userEmail,
      };

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .doc(item.id)
          .set(favoriteData, SetOptions(merge: true));
    } catch (e) {
      print('Error syncing favorite to Firebase: $e');
    }
  }

  // Remove from Firebase history
  Future<void> removeHistoryFromFirebase(String itemId) async {
    if (!isSignedIn || _userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('history')
          .doc(itemId)
          .delete();
    } catch (e) {
      print('Error removing history from Firebase: $e');
    }
  }

  // Remove from Firebase favorites
  Future<void> removeFavoriteFromFirebase(String itemId) async {
    if (!isSignedIn || _userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .doc(itemId)
          .delete();
    } catch (e) {
      print('Error removing favorite from Firebase: $e');
    }
  }

  // Get history from Firebase
  Future<List<ContentItem>> getHistoryFromFirebase() async {
    if (!isSignedIn || _userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return _mapToContentItem(data);
      }).toList();
    } catch (e) {
      print('Error getting history from Firebase: $e');
      return [];
    }
  }

  // Get favorites from Firebase
  Future<List<ContentItem>> getFavoritesFromFirebase() async {
    if (!isSignedIn || _userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .orderBy('addedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return _mapToContentItem(data);
      }).toList();
    } catch (e) {
      print('Error getting favorites from Firebase: $e');
      return [];
    }
  }

  // Sync local history to Firebase (on sign in)
  Future<void> syncLocalHistoryToFirebase(List<ContentItem> localHistory) async {
    if (!isSignedIn || _userId == null) return;

    try {
      final batch = _firestore.batch();
      final historyRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('history');

      for (final item in localHistory) {
        final historyData = {
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
          'timestamp': FieldValue.serverTimestamp(),
          'email': _userEmail,
        };

        batch.set(historyRef.doc(item.id), historyData, SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      print('Error syncing local history to Firebase: $e');
    }
  }

  // Sync local favorites to Firebase (on sign in)
  Future<void> syncLocalFavoritesToFirebase(List<ContentItem> localFavorites) async {
    if (!isSignedIn || _userId == null) return;

    try {
      final batch = _firestore.batch();
      final favoritesRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites');

      for (final item in localFavorites) {
        final favoriteData = {
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
          'addedAt': FieldValue.serverTimestamp(),
          'email': _userEmail,
        };

        batch.set(favoritesRef.doc(item.id), favoriteData, SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      print('Error syncing local favorites to Firebase: $e');
    }
  }

  // Clear all history from Firebase
  Future<void> clearHistoryFromFirebase() async {
    if (!isSignedIn || _userId == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('history')
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error clearing history from Firebase: $e');
    }
  }

  // Clear all favorites from Firebase
  Future<void> clearFavoritesFromFirebase() async {
    if (!isSignedIn || _userId == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error clearing favorites from Firebase: $e');
    }
  }

  ContentItem _mapToContentItem(Map<String, dynamic> data) {
    return ContentItem(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
      platform: ContentType.values.firstWhere(
        (e) => e.name == data['platform'],
        orElse: () => ContentType.youtube,
      ),
      category: ContentCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => ContentCategory.video,
      ),
      channelName: data['channelName'] as String?,
      artistName: data['artistName'] as String?,
      duration: data['duration'] as String?,
      viewCount: data['viewCount'] as int?,
      publishedAt: data['publishedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['publishedAt'] as int)
          : null,
    );
  }
}

