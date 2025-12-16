import 'dart:math';
import '../services/api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final ApiService _apiService = ApiService();
  final Random _random = Random();

  // AI-generated notification messages
  final List<String> _moodBasedMessages = [
    "🎬 New movie just dropped that matches your vibe!",
    "🎵 We found the perfect song for your mood today!",
    "📺 Trending content that'll turn your day around!",
    "✨ Don't be angry, I'm here to turn on your mood! 😊",
    "🎉 Exciting new content waiting for you!",
    "🔥 This trending video is going to make your day!",
    "💫 We've got something special for your current mood!",
    "🎭 Feeling down? We've got content to lift you up!",
    "🚀 Ready for an adventure? Check out this new release!",
    "💖 Perfect content match for your mood right now!",
  ];

  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Schedule random notifications
      _scheduleRandomNotifications();
      _isInitialized = true;
      print('✅ Notification service initialized');
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  /// Schedule random AI-powered notifications
  void _scheduleRandomNotifications() {
    // Schedule notifications at random intervals (every 2-6 hours)
    for (int i = 0; i < 3; i++) {
      final delay = Duration(hours: 2 + _random.nextInt(4));
      Future.delayed(delay, () {
        _sendRandomNotification();
        // Schedule next notification
        _scheduleRandomNotifications();
      });
    }
  }

  /// Send a random AI-powered notification
  Future<void> _sendRandomNotification() async {
    try {
      // Get trending content
      final result = await _apiService.getTrendingContent(maxResultsPerPlatform: 5);
      if (result.isSuccess && result.data != null && result.data!.isNotEmpty) {
        final content = result.data![_random.nextInt(result.data!.length)];
        final message = _moodBasedMessages[_random.nextInt(_moodBasedMessages.length)];

        await _showLocalNotification(
          title: 'Content Nation',
          body: message,
          payload: content.id,
        );
      }
    } catch (e) {
      print('Error sending random notification: $e');
    }
  }

  /// Show local notification (simplified version - can be enhanced with flutter_local_notifications)
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // For now, just print - can be enhanced with actual local notifications
    print('📬 Notification: $title - $body');
    // TODO: Implement actual local notifications when flutter_local_notifications is added
  }

  /// Send custom notification
  Future<void> sendCustomNotification(String title, String body, {String? payload}) async {
    await _showLocalNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    // TODO: Implement when flutter_local_notifications is added
    print('Notifications cancelled');
  }
}

