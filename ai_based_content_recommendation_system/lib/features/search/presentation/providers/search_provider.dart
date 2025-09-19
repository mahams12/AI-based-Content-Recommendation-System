import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/content_model.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/storage_service.dart';

// Search content provider
final searchContentProvider = StateNotifierProvider<SearchContentNotifier, AsyncValue<List<ContentItem>>>((ref) {
  return SearchContentNotifier();
});

class SearchContentNotifier extends StateNotifier<AsyncValue<List<ContentItem>>> {
  SearchContentNotifier() : super(const AsyncValue.data([]));

  Future<void> searchContent(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();

    try {
      // Check cache first
      final cacheKey = 'search_${query.toLowerCase()}';
      final cachedContent = StorageService.getCachedContent(cacheKey);
      if (cachedContent != null && cachedContent.isNotEmpty) {
        state = AsyncValue.data(cachedContent);
      }

      // Fetch fresh content
      final apiService = ApiService();
      final result = await apiService.searchAllPlatforms(query: query);

      if (result.isSuccess && result.data != null) {
        // Cache the search results
        await StorageService.cacheContent(cacheKey, result.data!);
        
        state = AsyncValue.data(result.data!);
      } else {
        state = AsyncValue.error(result.error ?? 'Search failed', StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void clearSearch() {
    state = const AsyncValue.data([]);
  }
}

