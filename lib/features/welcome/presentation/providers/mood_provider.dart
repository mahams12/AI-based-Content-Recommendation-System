import 'package:flutter_riverpod/flutter_riverpod.dart';

class MoodData {
  final Map<String, dynamic> data;
  final DateTime timestamp;

  MoodData({
    required this.data,
    required this.timestamp,
  });

  MoodData copyWith({
    Map<String, dynamic>? data,
    DateTime? timestamp,
  }) {
    return MoodData(
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory MoodData.fromJson(Map<String, dynamic> json) {
    return MoodData(
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class MoodNotifier extends StateNotifier<MoodData?> {
  MoodNotifier() : super(null);

  void setMoodData(Map<String, dynamic> moodData) {
    state = MoodData(
      data: moodData,
      timestamp: DateTime.now(),
    );
  }

  void clearMoodData() {
    state = null;
  }

  void updateMoodData(Map<String, dynamic> moodData) {
    if (state != null) {
      state = state!.copyWith(data: moodData);
    } else {
      setMoodData(moodData);
    }
  }

  // Helper methods to get specific mood data
  String? getCurrentMood() {
    if (state?.data == null) return null;
    
    final feelingData = state!.data['How are you feeling right now?'];
    return feelingData?['key'];
  }

  String? getContentPreference() {
    if (state?.data == null) return null;
    
    final contentData = state!.data['What type of content are you in the mood for?'];
    return contentData?['key'];
  }

  String? getEnergyLevel() {
    if (state?.data == null) return null;
    
    final energyData = state!.data['What\'s your current energy level?'];
    return energyData?['key'];
  }

  String? getTimeAvailability() {
    if (state?.data == null) return null;
    
    final timeData = state!.data['How much time do you have?'];
    return timeData?['key'];
  }

  bool get hasMoodData => state != null;
  
  bool get isRecent {
    if (state == null) return false;
    final now = DateTime.now();
    final difference = now.difference(state!.timestamp);
    return difference.inHours < 24; // Consider data fresh for 24 hours
  }
}

final moodProvider = StateNotifierProvider<MoodNotifier, MoodData?>((ref) {
  return MoodNotifier();
});

// Computed providers for easy access to specific mood data
final currentMoodProvider = Provider<String?>((ref) {
  return ref.watch(moodProvider.notifier).getCurrentMood();
});

final contentPreferenceProvider = Provider<String?>((ref) {
  return ref.watch(moodProvider.notifier).getContentPreference();
});

final energyLevelProvider = Provider<String?>((ref) {
  return ref.watch(moodProvider.notifier).getEnergyLevel();
});

final timeAvailabilityProvider = Provider<String?>((ref) {
  return ref.watch(moodProvider.notifier).getTimeAvailability();
});

final hasMoodDataProvider = Provider<bool>((ref) {
  return ref.watch(moodProvider.notifier).hasMoodData;
});

final isMoodDataRecentProvider = Provider<bool>((ref) {
  return ref.watch(moodProvider.notifier).isRecent;
});

