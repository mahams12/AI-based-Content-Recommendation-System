import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/user_profile_service.dart';
import '../../core/models/content_model.dart';
import '../../core/widgets/safe_network_image.dart';
import '../../features/recommendations/presentation/pages/mood_based_recommendations_screen.dart';
import '../../features/history/presentation/pages/history_screen.dart';
import '../../features/favorites/presentation/pages/favorites_screen.dart';
import '../../features/welcome/presentation/pages/simple_voice_welcome_screen.dart';
import '../../features/chat/presentation/pages/chat_screen.dart';

class PurpleSidebar extends ConsumerStatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isOpen;
  final VoidCallback onClose;

  const PurpleSidebar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.isOpen,
    required this.onClose,
  });

  @override
  ConsumerState<PurpleSidebar> createState() => _PurpleSidebarState();
}

class _PurpleSidebarState extends ConsumerState<PurpleSidebar>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  final UserProfileService _profileService = UserProfileService();
  String? _userName;
  String? _userPhoto;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      print('📥 Loading user profile for sidebar...');
      final profile = await _profileService.getUserProfile();
      print('✅ Sidebar profile loaded: name=${profile['name']}, photoUrl=${profile['photoUrl']}');
      
      if (mounted) {
        setState(() {
          _userName = profile['name'];
          // Only set photo if it's not null and not empty
          final photoUrl = profile['photoUrl'];
          _userPhoto = (photoUrl != null && photoUrl.toString().trim().isNotEmpty) 
              ? photoUrl.toString() 
              : null;
        });
        print('✅ Sidebar profile updated');
      }
    } catch (e) {
      print('❌ Error loading profile for sidebar: $e');
    }
  }

  Widget _buildSidebarProfilePicture() {
    if (_userPhoto == null || _userPhoto!.isEmpty || _userPhoto!.trim().isEmpty) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(
          Icons.auto_awesome_rounded,
          color: Colors.white,
          size: 28,
        ),
      );
    }

    final photo = _userPhoto!.trim();
    
    return CircleAvatar(
      radius: 25,
      backgroundColor: Colors.white.withOpacity(0.1),
      child: photo.startsWith('http://') || photo.startsWith('https://')
          ? ClipOval(
              child: SafeNetworkImage(
                imageUrl: photo,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                platform: ContentType.spotify,
              ),
            )
          : photo.startsWith('/') || photo.startsWith('file://')
              ? _buildFileImage(photo)
              : Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
    );
  }

  Widget _buildFileImage(String photo) {
    final filePath = photo.replaceFirst('file://', '');
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        return ClipOval(
          child: Image.file(
            file,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 28,
                ),
              );
            },
          ),
        );
      } else {
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 28,
          ),
        );
      }
    } catch (e) {
      print('❌ Error loading file image in sidebar: $e');
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Icon(
          Icons.person,
          color: Colors.white,
          size: 28,
        ),
      );
    }
  }

  @override
  void didUpdateWidget(PurpleSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _slideController.forward();
        // Reload profile when sidebar opens
        _loadUserProfile();
      } else {
        _slideController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0: // Home
        widget.onTap(0);
        break;
      case 1: // Mood-Based Recommendations
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MoodBasedRecommendationsScreen(),
          ),
        );
        break;
      case 2: // Voice Mood Detection
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SimpleVoiceWelcomeScreen(),
          ),
        );
        break;
      case 3: // History
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HistoryScreen(),
          ),
        );
        break;
      case 4: // Favorites
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FavoritesScreen(),
          ),
        );
        break;
      case 5: // Profile
        widget.onTap(4);
        break;
      case 6: // Chat Interface
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ChatScreen(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: 300,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A1D29),
                Color(0xFF2D1B69),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(4, 0),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Profile Picture or App Icon
                      _buildSidebarProfilePicture(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userName ?? 'Content Nation',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _userName != null ? 'Welcome back!' : 'AI-Powered Discovery',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Navigation Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildNavItem(Icons.home_rounded, 'Home', 0),
                      _buildNavItem(Icons.chat_bubble_rounded, 'Chat Interface', 6),
                      _buildNavItem(Icons.mood_rounded, 'Mood-Based Recommendations', 1),
                      _buildNavItem(Icons.mic_rounded, 'Voice Mood Detection', 2),
                      _buildNavItem(Icons.history_rounded, 'History', 3),
                      _buildNavItem(Icons.favorite_rounded, 'Favorites', 4),
                      _buildNavItem(Icons.person_rounded, 'Profile', 5),
                    ],
                  ),
                ),
                
                // Footer
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Connected Platforms',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildPlatformBadge('YouTube', Icons.play_arrow_rounded, const Color(0xFFFF4444)),
                                _buildPlatformBadge('Spotify', Icons.music_note_rounded, const Color(0xFF1DB954)),
                                _buildPlatformBadge('TMDB', Icons.movie_rounded, const Color(0xFF667eea)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, int index) {
    final isSelected = widget.currentIndex == index;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            widget.onClose();
            _handleNavigation(index);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected 
                  ? Colors.white.withOpacity(0.15)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: isSelected 
                  ? Border.all(color: Colors.white.withOpacity(0.2), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.white.withOpacity(0.2)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : Colors.white70,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformBadge(String name, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
