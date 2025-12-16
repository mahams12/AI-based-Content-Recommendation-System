import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/storage_service.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  bool _autoPlay = false;
  bool _darkMode = true;
  String _defaultCategory = 'All';
  int _maxRecommendations = 10;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = StorageService.getUserPreferences();
    if (prefs != null) {
      setState(() {
        _autoPlay = prefs['autoPlay'] ?? false;
        _darkMode = prefs['darkMode'] ?? true;
        _defaultCategory = prefs['defaultCategory'] ?? 'All';
        _maxRecommendations = prefs['maxRecommendations'] ?? 10;
      });
    }
  }

  Future<void> _savePreferences() async {
    await StorageService.saveUserPreferences({
      'autoPlay': _autoPlay,
      'darkMode': _darkMode,
      'defaultCategory': _defaultCategory,
      'maxRecommendations': _maxRecommendations,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences saved!'),
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
        title: const Text('Preferences'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('Playback', [
            SwitchListTile(
              title: const Text('Auto-play videos'),
              subtitle: const Text('Automatically play videos when opened'),
              value: _autoPlay,
              onChanged: (value) {
                setState(() => _autoPlay = value);
                _savePreferences();
              },
            ),
          ]),
          _buildSection('Content', [
            ListTile(
              title: const Text('Default Category'),
              subtitle: Text(_defaultCategory),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showCategoryDialog(),
            ),
            ListTile(
              title: const Text('Max Recommendations'),
              subtitle: Text('$_maxRecommendations items'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showRecommendationsDialog(),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Card(
          color: const Color(0xFF1C2128),
          child: Column(children: children),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2128),
        title: const Text('Select Default Category', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['All', 'YouTube Videos', 'Movies', 'Songs'].map((category) {
            return ListTile(
              title: Text(category, style: const TextStyle(color: Colors.white)),
              onTap: () {
                setState(() => _defaultCategory = category);
                _savePreferences();
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showRecommendationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2128),
        title: const Text('Max Recommendations', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [5, 10, 15, 20].map((count) {
            return ListTile(
              title: Text('$count items', style: const TextStyle(color: Colors.white)),
              onTap: () {
                setState(() => _maxRecommendations = count);
                _savePreferences();
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

