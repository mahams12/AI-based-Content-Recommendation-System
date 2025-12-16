import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/storage_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _notificationsEnabled = true;
  bool _aiRecommendations = true;
  bool _trendingContent = true;
  bool _moodBased = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    if (_notificationsEnabled) {
      await _notificationService.initialize();
    }
  }

  Future<void> _loadSettings() async {
    final settings = StorageService.getAppSettings();
    if (settings != null) {
      setState(() {
        _notificationsEnabled = settings['notificationsEnabled'] ?? true;
        _aiRecommendations = settings['aiRecommendations'] ?? true;
        _trendingContent = settings['trendingContent'] ?? true;
        _moodBased = settings['moodBased'] ?? true;
      });
    }
  }

  Future<void> _saveSettings() async {
    await StorageService.saveAppSettings({
      'notificationsEnabled': _notificationsEnabled,
      'aiRecommendations': _aiRecommendations,
      'trendingContent': _trendingContent,
      'moodBased': _moodBased,
    });
    if (_notificationsEnabled) {
      await _notificationService.initialize();
    } else {
      await _notificationService.cancelAllNotifications();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification settings saved!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: const Color(0xFF1C2128),
            child: SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: const Text('Receive AI-powered content recommendations'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                _saveSettings();
              },
            ),
          ),
          const SizedBox(height: 16),
          if (_notificationsEnabled) ...[
            Card(
              color: const Color(0xFF1C2128),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('AI Recommendations'),
                    subtitle: const Text('Get notified about personalized content'),
                    value: _aiRecommendations,
                    onChanged: (value) {
                      setState(() => _aiRecommendations = value);
                      _saveSettings();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Trending Content'),
                    subtitle: const Text('Notifications about trending movies, songs, and videos'),
                    value: _trendingContent,
                    onChanged: (value) {
                      setState(() => _trendingContent = value);
                      _saveSettings();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Mood-Based Alerts'),
                    subtitle: const Text('Fun and exciting mood-based notifications'),
                    value: _moodBased,
                    onChanged: (value) {
                      setState(() => _moodBased = value);
                      _saveSettings();
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

