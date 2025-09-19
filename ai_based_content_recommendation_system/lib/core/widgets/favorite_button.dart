import 'package:flutter/material.dart';
import '../models/content_model.dart';
import '../services/favorites_service.dart';

class FavoriteButton extends StatefulWidget {
  final ContentItem content;
  final double size;
  final Color? color;

  const FavoriteButton({
    super.key,
    required this.content,
    this.size = 24,
    this.color,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  final FavoritesService _favoritesService = FavoritesService();
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      await _favoritesService.init();
      final isFavorite = await _favoritesService.isFavorite(widget.content.id);
      if (mounted) {
        setState(() {
          _isFavorite = isFavorite;
        });
      }
    } catch (e) {
      print('Error checking favorite status: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isFavorite) {
        await _favoritesService.removeFromFavorites(widget.content.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from favorites'),
              backgroundColor: Color(0xFF667eea),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        await _favoritesService.addToFavorites(widget.content);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to favorites'),
              backgroundColor: Color(0xFF667eea),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFavorite,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: _isLoading
            ? SizedBox(
                width: widget.size,
                height: widget.size,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                size: widget.size,
                color: _isFavorite 
                    ? Colors.red 
                    : (widget.color ?? Colors.white),
              ),
      ),
    );
  }
}
