import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/content_model.dart';

class SafeNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final ContentType platform;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    required this.platform,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<SafeNetworkImage> createState() => _SafeNetworkImageState();
}

class _SafeNetworkImageState extends State<SafeNetworkImage> {
  @override
  Widget build(BuildContext context) {
    // Safety check to prevent disposed view errors
    if (!mounted) {
      return const SizedBox.shrink();
    }

    // If no image URL provided, show platform-specific placeholder
    if (widget.imageUrl.isEmpty) {
      return _buildPlatformPlaceholder();
    }

    // Check if URL is valid
    if (!_isValidUrl(widget.imageUrl)) {
      return _buildErrorWidget();
    }

    Widget imageWidget;

    // Handle different image sources with appropriate strategies
    if (widget.imageUrl.startsWith('https://via.placeholder.com') || 
        widget.imageUrl.startsWith('https://picsum.photos')) {
      // For placeholder services, use regular Image.network
      imageWidget = Image.network(
        widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingWidget();
        },
        errorBuilder: (context, error, stackTrace) {
          if (!mounted) return const SizedBox.shrink();
          return _buildErrorWidget();
        },
      );
    } else if (widget.imageUrl.startsWith('https://i.ytimg.com')) {
      // For YouTube thumbnails, try direct image loading first, then fallback
      imageWidget = Image.network(
        widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingWidget();
        },
        errorBuilder: (context, error, stackTrace) {
          if (!mounted) return const SizedBox.shrink();
          // If direct loading fails due to CORS, show platform placeholder immediately
          return _buildPlatformPlaceholder();
        },
      );
    } else {
      // For other URLs, use CachedNetworkImage
      imageWidget = CachedNetworkImage(
        imageUrl: widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (context, url) => _buildLoadingWidget(),
        errorWidget: (context, url, error) {
          if (!mounted) return const SizedBox.shrink();
          return _buildErrorWidget();
        },
      );
    }

    // Apply border radius if provided
    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }



  Widget _buildLoadingWidget() {
    return Container(
      width: widget.width?.isFinite == true ? widget.width : 100,
      height: widget.height?.isFinite == true ? widget.height : 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getGradientColors(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: Colors.white.withOpacity(0.8),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    return Container(
      width: widget.width?.isFinite == true ? widget.width : 100,
      height: widget.height?.isFinite == true ? widget.height : 100,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: widget.borderRadius,
      ),
      child: Center(
        child: Icon(
          Icons.broken_image,
          size: _getIconSize(),
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildPlatformPlaceholder() {
    return Container(
      width: widget.width?.isFinite == true ? widget.width : 100,
      height: widget.height?.isFinite == true ? widget.height : 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getGradientColors(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          _getPlatformIcon(),
          size: _getIconSize(),
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  List<Color> _getGradientColors() {
    switch (widget.platform) {
      case ContentType.youtube:
        return [const Color(0xFFFF4444), const Color(0xFFFF6B6B)];
      case ContentType.tmdb:
        return [const Color(0xFF667eea), const Color(0xFF764ba2)];
      case ContentType.spotify:
        return [const Color(0xFF1DB954), const Color(0xFF1ED760)];
    }
  }

  IconData _getPlatformIcon() {
    switch (widget.platform) {
      case ContentType.youtube:
        return Icons.play_circle_outline;
      case ContentType.tmdb:
        return Icons.movie_outlined;
      case ContentType.spotify:
        return Icons.music_note;
    }
  }

  double _getIconSize() {
    if (widget.width != null && widget.height != null && widget.width!.isFinite && widget.height!.isFinite) {
      final calculatedSize = (widget.width! + widget.height!) / 8;
      // Ensure the size is finite and within reasonable bounds
      if (calculatedSize.isFinite && calculatedSize > 0 && calculatedSize < 200) {
        return calculatedSize;
      }
    }
    return 48.0; // Default size - ensure it's finite
  }
}