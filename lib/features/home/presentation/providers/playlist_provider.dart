import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/content_model.dart';
import '../../../../core/services/recommendation_engine.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/services/api_service.dart';

// Smart playlist provider
final smartPlaylistProvider = StateNotifierProvider<SmartPlaylistNotifier, AsyncValue<List<SmartPlaylist>>>((ref) {
  return SmartPlaylistNotifier();
});

// Individual playlist provider
final playlistProvider = StateNotifierProvider.family<PlaylistNotifier, AsyncValue<SmartPlaylist>, String>((ref, playlistId) {
  return PlaylistNotifier(playlistId);
});

class SmartPlaylistNotifier extends StateNotifier<AsyncValue<List<SmartPlaylist>>> {
  SmartPlaylistNotifier() : super(const AsyncValue.data([]));

  final RecommendationEngine _recommendationEngine = RecommendationEngine();
  final FeedbackService _feedbackService = FeedbackService();
  final ApiService _apiService = ApiService();

  Future<void> loadSmartPlaylists() async {
    state = const AsyncValue.loading();

    try {
      // Get user data for personalized playlists
      final interactions = await _feedbackService.getUserInteractions(
        userId: 'current_user',
        limit: 100,
      );
      
      final userPreferences = await _feedbackService.getUserPreferences('current_user');
      final currentMood = userPreferences['current_mood'] as String? ?? 'neutral';

      // Get available content
      final result = await _apiService.getTrendingContent(maxResultsPerPlatform: 100);
      
      if (result.isSuccess && result.data != null) {
        // Convert interactions to the format expected by recommendation engine
        final formattedInteractions = interactions.map((interaction) => {
          'userId': interaction.userId,
          'contentId': interaction.contentId,
          'rating': _convertInteractionToRating(interaction),
          'content': _getContentFromInteraction(interaction),
        }).toList();

        // Generate smart playlists
        final playlists = await _recommendationEngine.generateSmartPlaylists(
          userId: 'current_user',
          availableContent: result.data!,
          userHistory: formattedInteractions,
          userPreferences: userPreferences,
          currentMood: currentMood,
        );

        state = AsyncValue.data(playlists);
      } else {
        state = AsyncValue.error(result.error ?? 'Failed to load playlists', StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> createCustomPlaylist({
    required String name,
    required String description,
    required List<ContentItem> content,
    String? theme,
  }) async {
    try {
      final playlist = SmartPlaylist(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        description: description,
        content: content,
        type: theme ?? 'Custom',
        createdAt: DateTime.now(),
      );

      // Add to current playlists
      final currentPlaylists = state.valueOrNull ?? [];
      final updatedPlaylists = [...currentPlaylists, playlist];
      state = AsyncValue.data(updatedPlaylists);

      // Record playlist creation interaction
      await _feedbackService.recordInteraction(
        userId: 'current_user',
        contentId: playlist.id,
        type: InteractionType.save,
        metadata: {
          'playlist_name': name,
          'playlist_type': theme ?? 'Custom',
          'content_count': content.length,
        },
      );
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updatePlaylist(String playlistId, List<ContentItem> newContent) async {
    try {
      final currentPlaylists = state.valueOrNull ?? [];
      final playlistIndex = currentPlaylists.indexWhere((p) => p.id == playlistId);
      
      if (playlistIndex != -1) {
        final updatedPlaylist = SmartPlaylist(
          id: currentPlaylists[playlistIndex].id,
          name: currentPlaylists[playlistIndex].name,
          description: currentPlaylists[playlistIndex].description,
          content: newContent,
          type: currentPlaylists[playlistIndex].type,
          createdAt: currentPlaylists[playlistIndex].createdAt,
        );

        final updatedPlaylists = [...currentPlaylists];
        updatedPlaylists[playlistIndex] = updatedPlaylist;
        state = AsyncValue.data(updatedPlaylists);

        // Record playlist update interaction
        await _feedbackService.recordInteraction(
          userId: 'current_user',
          contentId: playlistId,
          type: InteractionType.consume,
          metadata: {
            'action': 'playlist_update',
            'new_content_count': newContent.length,
          },
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    try {
      final currentPlaylists = state.valueOrNull ?? [];
      final updatedPlaylists = currentPlaylists.where((p) => p.id != playlistId).toList();
      state = AsyncValue.data(updatedPlaylists);

      // Record playlist deletion interaction
      await _feedbackService.recordInteraction(
        userId: 'current_user',
        contentId: playlistId,
        type: InteractionType.dislike,
        metadata: {
          'action': 'playlist_deletion',
        },
      );
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refreshPlaylists() async {
    await loadSmartPlaylists();
  }

  // Helper methods
  double _convertInteractionToRating(UserInteraction interaction) {
    switch (interaction.type) {
      case InteractionType.like:
        return 5.0;
      case InteractionType.consume:
        return 4.0;
      case InteractionType.share:
        return 4.5;
      case InteractionType.save:
        return 4.0;
      case InteractionType.dislike:
        return 1.0;
      case InteractionType.skip:
        return 2.0;
      default:
        return 3.0; // Neutral
    }
  }

  ContentItem? _getContentFromInteraction(UserInteraction interaction) {
    // In a real implementation, you would fetch the content from storage or API
    return null;
  }
}

class PlaylistNotifier extends StateNotifier<AsyncValue<SmartPlaylist>> {
  final String playlistId;
  // final RecommendationEngine _recommendationEngine = RecommendationEngine();
  final FeedbackService _feedbackService = FeedbackService();

  PlaylistNotifier(this.playlistId) : super(const AsyncValue.loading()) {
    loadPlaylist();
  }

  Future<void> loadPlaylist() async {
    try {
      // In a real implementation, you would load the specific playlist
      // For now, we'll create a placeholder
      final playlist = SmartPlaylist(
        id: playlistId,
        name: 'Loading...',
        description: 'Loading playlist...',
        content: [],
        type: 'Unknown',
        createdAt: DateTime.now(),
      );

      state = AsyncValue.data(playlist);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> addContentToPlaylist(ContentItem content) async {
    try {
      final currentPlaylist = state.valueOrNull;
      if (currentPlaylist != null) {
        final updatedContent = [...currentPlaylist.content, content];
        final updatedPlaylist = SmartPlaylist(
          id: currentPlaylist.id,
          name: currentPlaylist.name,
          description: currentPlaylist.description,
          content: updatedContent,
          type: currentPlaylist.type,
          createdAt: currentPlaylist.createdAt,
        );

        state = AsyncValue.data(updatedPlaylist);

        // Record content addition interaction
        await _feedbackService.recordInteraction(
          userId: 'current_user',
          contentId: content.id,
          type: InteractionType.save,
          metadata: {
            'playlist_id': playlistId,
            'action': 'add_to_playlist',
          },
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> removeContentFromPlaylist(String contentId) async {
    try {
      final currentPlaylist = state.valueOrNull;
      if (currentPlaylist != null) {
        final updatedContent = currentPlaylist.content
            .where((content) => content.id != contentId)
            .toList();
        
        final updatedPlaylist = SmartPlaylist(
          id: currentPlaylist.id,
          name: currentPlaylist.name,
          description: currentPlaylist.description,
          content: updatedContent,
          type: currentPlaylist.type,
          createdAt: currentPlaylist.createdAt,
        );

        state = AsyncValue.data(updatedPlaylist);

        // Record content removal interaction
        await _feedbackService.recordInteraction(
          userId: 'current_user',
          contentId: contentId,
          type: InteractionType.dislike,
          metadata: {
            'playlist_id': playlistId,
            'action': 'remove_from_playlist',
          },
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> reorderPlaylist(List<ContentItem> reorderedContent) async {
    try {
      final currentPlaylist = state.valueOrNull;
      if (currentPlaylist != null) {
        final updatedPlaylist = SmartPlaylist(
          id: currentPlaylist.id,
          name: currentPlaylist.name,
          description: currentPlaylist.description,
          content: reorderedContent,
          type: currentPlaylist.type,
          createdAt: currentPlaylist.createdAt,
        );

        state = AsyncValue.data(updatedPlaylist);

        // Record playlist reorder interaction
        await _feedbackService.recordInteraction(
          userId: 'current_user',
          contentId: playlistId,
          type: InteractionType.consume,
          metadata: {
            'action': 'reorder_playlist',
            'content_count': reorderedContent.length,
          },
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
