import 'package:flutter/material.dart';

class YouTubeContentFilter extends StatefulWidget {
  final String? selectedContentType;
  final String? selectedVideoFormat;
  final Function(String?) onContentTypeChanged;
  final Function(String?) onVideoFormatChanged;

  const YouTubeContentFilter({
    super.key,
    required this.selectedContentType,
    required this.selectedVideoFormat,
    required this.onContentTypeChanged,
    required this.onVideoFormatChanged,
  });

  @override
  State<YouTubeContentFilter> createState() => _YouTubeContentFilterState();
}

class _YouTubeContentFilterState extends State<YouTubeContentFilter> {
  static const List<String> contentTypes = [
    'All',
    'Gaming',
    'Vlog',
    'Tutorial',
    'Entertainment',
    'Music',
    'Tech',
    'Fitness',
  ];

  static const List<String> videoFormats = [
    'All',
    'Video',
    'Short',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // Content Type Filter
          _buildFilterSection(
            title: 'Content Type',
            filters: contentTypes,
            selectedFilter: widget.selectedContentType ?? 'All',
            onFilterChanged: widget.onContentTypeChanged,
          ),
          const SizedBox(height: 16),
          // Video Format Filter
          _buildFilterSection(
            title: 'Video Format',
            filters: videoFormats,
            selectedFilter: widget.selectedVideoFormat ?? 'All',
            onFilterChanged: widget.onVideoFormatChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required List<String> filters,
    required String selectedFilter,
    required Function(String?) onFilterChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filters.map((filter) {
              final isSelected = filter == selectedFilter;
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onFilterChanged(filter == 'All' ? null : filter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFFFF4444).withOpacity(0.2)
                          : Colors.grey[800]!.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected 
                            ? const Color(0xFFFF4444)
                            : Colors.grey[600]!.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          Icon(
                            Icons.check_circle_rounded,
                            color: const Color(0xFFFF4444),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          filter,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFFFF4444) : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        // Search hint for discovering more content types
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[800]!.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey[600]!.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.amber[400],
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Search for specific content like "cooking", "documentary", "science", "art", etc.',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
