import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/content_model.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../../../core/services/storage_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../welcome/presentation/widgets/mood_assessment_widget.dart';
import '../../../welcome/presentation/providers/mood_provider.dart';
import '../../../welcome/presentation/pages/welcome_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: authState.when(
          data: (user) => user != null ? _buildProfileContent(context, ref, user) : _buildNotLoggedIn(context),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildError(context, error.toString()),
        ),
      ),
    );
  }


  Widget _buildProfileContent(BuildContext context, WidgetRef ref, user) {
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
                // Profile Picture
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: user.photoURL != null
                      ? ClipOval(
                          child: SafeNetworkImage(
                            imageUrl: user.photoURL!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            platform: ContentType.spotify, // Default platform for profile images
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 50,
                          color: AppTheme.primaryColor,
                        ),
                ),
                const SizedBox(height: 16),
                // Name
                Text(
                  user.displayName ?? 'User',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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
        
        // Preferences
        _buildSettingsTile(
          context,
          icon: Icons.tune,
          title: 'Preferences',
          subtitle: 'Customize your content preferences',
          onTap: () {
            // TODO: Navigate to preferences screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Preferences coming soon!')),
            );
          },
        ),
        
        // Mood Assessment
        Consumer(
          builder: (context, ref, child) {
            final hasMoodData = ref.watch(hasMoodDataProvider);
            final isRecent = ref.watch(isMoodDataRecentProvider);
            
            return _buildSettingsTile(
              context,
              icon: Icons.psychology_rounded,
              title: 'Mood Assessment',
              subtitle: hasMoodData 
                  ? (isRecent ? 'Update your mood preferences' : 'Your mood data is outdated')
                  : 'Take mood assessment for better recommendations',
              onTap: () => _showMoodAssessmentDialog(context, ref),
            );
          },
        ),
        
        // History
        _buildSettingsTile(
          context,
          icon: Icons.history,
          title: 'Viewing History',
          subtitle: 'Manage your content history',
          onTap: () {
            // TODO: Navigate to history screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('History coming soon!')),
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
            // TODO: Navigate to notifications settings
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications coming soon!')),
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
        
        // Start Over (for testing)
        _buildSettingsTile(
          context,
          icon: Icons.refresh,
          title: 'Start Over',
          subtitle: 'Reset mood assessment and start fresh',
          onTap: () => _showStartOverDialog(context, ref),
        ),
        
        const SizedBox(height: 8),
        
        // Sign Out
        _buildSettingsTile(
          context,
          icon: Icons.logout,
          title: 'Sign Out',
          subtitle: 'Sign out of your account',
          onTap: () => _showSignOutDialog(context, ref),
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

  Widget _buildNotLoggedIn(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Not Signed In',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sign in to access your profile and personalized recommendations.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate to login screen
              },
              child: const Text('Sign In'),
            ),
          ],
        ),
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


  void _showMoodAssessmentDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MoodAssessmentDialog(
        onCompleted: (moodData) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Mood assessment completed!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        },
        onSkip: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2128),
        title: const Text(
          'Sign Out',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
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
                
                // Navigate to login screen
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
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
              'Sign Out',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showStartOverDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2128),
        title: const Text(
          'Start Over',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'This will reset your mood assessment and take you back to the welcome screen. Continue?',
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
                // Clear welcome completion and mood data
                await StorageService.setBool('has_completed_welcome', false);
                await StorageService.remove('user_mood_data');
                await StorageService.remove('mood_detection_method');
                
                // Clear mood provider state
                ref.read(moodProvider.notifier).clearMoodData();
                
                // Navigate to welcome screen
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const WelcomeScreen(),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to reset: $e',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text(
              'Start Over',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
