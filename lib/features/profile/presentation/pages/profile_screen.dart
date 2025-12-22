import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/content_model.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/user_profile_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../history/presentation/pages/history_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final UserProfileService _profileService = UserProfileService();
  String? _displayName;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      print('📥 Loading user profile...');
      final profile = await _profileService.getUserProfile();
      print('✅ Profile loaded: name=${profile['name']}, photoUrl=${profile['photoUrl']}');
      
      if (mounted) {
        setState(() {
          _displayName = profile['name'];
          // Only set photo if it's not null and not empty
          final photoUrl = profile['photoUrl'];
          _photoUrl = (photoUrl != null && photoUrl.toString().trim().isNotEmpty) 
              ? photoUrl.toString() 
              : null;
        });
        print('✅ Profile state updated');
      }
    } catch (e) {
      print('❌ Error loading profile: $e');
    }
  }

  Widget _buildProfilePicture(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty || photoUrl.trim().isEmpty) {
      return Icon(
        Icons.person,
        size: 50,
        color: AppTheme.primaryColor,
      );
    }

    final photo = photoUrl.trim();
    
    if (photo.startsWith('http://') || photo.startsWith('https://')) {
      return ClipOval(
        child: SafeNetworkImage(
          imageUrl: photo,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          platform: ContentType.spotify,
        ),
      );
    } else if (photo.startsWith('/') || photo.startsWith('file://')) {
      final filePath = photo.replaceFirst('file://', '');
      try {
        final file = File(filePath);
        if (file.existsSync()) {
          return ClipOval(
            child: Image.file(
              file,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.person,
                  size: 50,
                  color: AppTheme.primaryColor,
                );
              },
            ),
          );
        } else {
          return Icon(
            Icons.person,
            size: 50,
            color: AppTheme.primaryColor,
          );
        }
      } catch (e) {
        print('❌ Error loading file image: $e');
        return Icon(
          Icons.person,
          size: 50,
          color: AppTheme.primaryColor,
        );
      }
    } else {
      return Icon(
        Icons.person,
        size: 50,
        color: AppTheme.primaryColor,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Redirect to login if not signed in - don't show "Not Signed In" screen
    authState.whenData((user) {
      if (user == null && mounted) {
        // User is not signed in, redirect to login immediately
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: authState.when(
          data: (user) {
            if (user == null) {
              // Show loading while redirecting to login
              return const Center(child: CircularProgressIndicator());
            }
            return _buildProfileContent(context, ref, user);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildError(context, error.toString()),
        ),
      ),
    );
  }


  Widget _buildProfileContent(BuildContext context, WidgetRef ref, user) {
    final currentName = _displayName ?? user.displayName ?? 'User';
    final currentPhoto = _photoUrl ?? user.photoURL;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppTheme.primaryGradient,
              ),
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            child: Column(
              children: [
                // Profile Picture with edit button
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: _buildProfilePicture(currentPhoto),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _showEditPhotoDialog(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Editable Name Field
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Text(
                          currentName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showEditNameDialog(context),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Email
                Text(
                  user.email ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Settings Section
          _buildSettingsSection(context, ref),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // History
        _buildSettingsTile(
          context,
          icon: Icons.history,
          title: 'Viewing History',
          subtitle: 'Manage your content history',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            );
          },
        ),
        
        // Notifications
        _buildSettingsTile(
          context,
          icon: Icons.notifications,
          title: 'Notifications',
          subtitle: 'Manage notification preferences',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
            );
          },
        ),
        
        const SizedBox(height: 24),
        
        // Account Section
        Text(
          'Account',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Logout
        _buildSettingsTile(
          context,
          icon: Icons.logout,
          title: 'Logout',
          subtitle: 'Sign out of your account',
          onTap: () => _showLogoutDialog(context, ref),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? AppTheme.errorColor : AppTheme.primaryColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? AppTheme.errorColor : null,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Profile',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // TODO: Retry loading profile
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }


  void _showEditPhotoDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2128),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Change Profile Picture',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                await _handleImageSelection(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                await _handleImageSelection(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImageSelection(ImageSource source) async {
    try {
      if (!mounted) return;
      
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Text(source == ImageSource.camera 
                    ? 'Taking photo...' 
                    : 'Selecting image...'),
              ],
            ),
            duration: const Duration(seconds: 30), // Long duration for upload
          ),
        );
      }
      
      File? file;
      String? errorMessage;
      
      try {
        if (source == ImageSource.gallery) {
          print('📷 Picking image from gallery...');
          file = await _profileService.pickImageFromGallery();
        } else {
          print('📸 Taking photo with camera...');
          file = await _profileService.pickImageFromCamera();
        }
      } catch (e) {
        print('❌ Error picking image: $e');
        errorMessage = 'Failed to access ${source == ImageSource.camera ? "camera" : "photo library"}. Please check permissions.';
      }
      
      // Hide loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      
      if (file == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage ?? 'No image selected'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      
      if (!mounted) return;
      
      print('📸 Image selected: ${file.path}');
      print('📏 File size: ${await file.length()} bytes');
      print('✅ File exists: ${file.existsSync()}');
      
      // Show uploading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                const Text('Uploading image...'),
              ],
            ),
            duration: const Duration(seconds: 60), // Long duration for upload
          ),
        );
      }
      
      // Upload and update
      final photoUrl = await _profileService.updateProfilePictureFromFile(file);
      
      // Hide uploading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      
      if (photoUrl != null && mounted) {
        print('✅ Photo URL received: $photoUrl');
        
        setState(() {
          _photoUrl = photoUrl;
        });
        
        // Reload profile to get updated data
        await _loadProfile();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Profile picture updated successfully!'),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Failed to upload image. Please check your internet connection and try again.'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error handling image selection: $e');
      print('Stack trace: $stackTrace');
      
      // Hide any loading snackbars
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Error: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showEditNameDialog(BuildContext context) {
    final controller = TextEditingController(text: _displayName ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2128),
        title: const Text('Edit Name', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter your name',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                try {
                  await _profileService.updateDisplayName(newName);
                  if (mounted) {
                    setState(() {
                      _displayName = newName;
                    });
                    // Reload profile to ensure sync
                    await _loadProfile();
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Name updated successfully!'),
                        backgroundColor: AppTheme.successColor,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                  Navigator.pop(context);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating name: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Name cannot be empty'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2128),
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                // Clear all user data
                await ref.read(authServiceProvider).signOut();
                // Clear welcome completion flag so user can go through onboarding again
                await StorageService.setBool('has_completed_welcome', false);
                await StorageService.remove('user_mood_data');
                
                // Navigate directly to login screen - remove all previous routes
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false, // Remove all previous routes
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Sign out failed: $e',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

}
