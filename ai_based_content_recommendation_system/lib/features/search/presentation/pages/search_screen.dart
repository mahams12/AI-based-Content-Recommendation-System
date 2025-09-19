import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/content_model.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/media_player.dart';
import '../providers/search_provider.dart';
import '../widgets/search_result_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      ref.read(searchContentProvider.notifier).searchContent(query);
      StorageService.addToSearchHistory(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchContentProvider);
    final searchHistory = StorageService.getSearchHistory() ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search YouTube, Spotify, Movies...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchContentProvider.notifier).clearSearch();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                onSubmitted: _performSearch,
                onChanged: (value) {
                  setState(() {});
                  if (value.trim().isNotEmpty) {
                    _performSearch(value);
                  } else {
                    ref.read(searchContentProvider.notifier).clearSearch();
                  }
                },
              ),
            ),

            // Search Results or History
            Expanded(
              child: searchResults.when(
                data: (results) {
                  if (results.isEmpty && _searchController.text.isEmpty) {
                    return _buildSearchHistory(searchHistory);
                  } else if (results.isEmpty && _searchController.text.isNotEmpty) {
                    return _buildNoResults();
                  } else {
                    return _buildSearchResults(results);
                  }
                },
                loading: () => _buildLoadingState(),
                error: (error, stack) => _buildErrorState(error.toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHistory(List<String> history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Text(
            'Recent Searches',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final searchTerm = history[index];
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(searchTerm),
                onTap: () {
                  _searchController.text = searchTerm;
                  _performSearch(searchTerm);
                },
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    final newHistory = List<String>.from(history);
                    newHistory.removeAt(index);
                    StorageService.saveSearchHistory(newHistory);
                    setState(() {});
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(List<ContentItem> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Text(
            '${results.length} results found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final content = results[index];
              return SearchResultCard(
                content: content,
                onTap: () => _onContentTap(content),
                onLike: () => _onContentLike(content),
                onShare: () => _onContentShare(content),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords or check your spelling',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Searching...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Search failed',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_searchController.text.isNotEmpty) {
                _performSearch(_searchController.text);
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _onContentTap(ContentItem content) {
    // Record interaction
    StorageService.recordInteraction(
      contentId: content.id,
      action: 'view',
    );

    // Open media player
    showDialog(
      context: context,
      builder: (context) => MediaPlayer(content: content),
    );
  }

  void _onContentLike(ContentItem content) {
    // Record interaction
    StorageService.recordInteraction(
      contentId: content.id,
      action: 'like',
      sentimentScore: 1.0,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Liked ${content.title}'),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _onContentShare(ContentItem content) {
    // Record interaction
    StorageService.recordInteraction(
      contentId: content.id,
      action: 'share',
    );

    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${content.title}...'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
