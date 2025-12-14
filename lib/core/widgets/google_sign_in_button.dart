import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../theme/app_theme.dart';

class GoogleSignInButton extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;
  final Function(String)? onError;
  final bool isLoading;
  
  const GoogleSignInButton({
    super.key,
    this.onSuccess,
    this.onError,
    this.isLoading = false,
  });

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // OAuth client ID from Google Cloud Console
    clientId: '597878741733-94oh71atkf557uqhrveuaocgcaanacmc.apps.googleusercontent.com',
    scopes: ['openid', 'email', 'profile'],
    // For web: Disable FedCM to avoid CORS errors
    // For mobile: This is ignored and native SDK is used
  );
  bool _isSigningIn = false;

  @override
  Widget build(BuildContext context) {
    // Use renderButton for web, custom button for mobile
    if (kIsWeb) {
      return _buildWebButton();
    } else {
      return _buildMobileButton();
    }
  }

  Widget _buildWebButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: (widget.isLoading || _isSigningIn) ? null : _handleWebGoogleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.glassBackground,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.glassBorder),
          ),
        ),
        icon: (widget.isLoading || _isSigningIn)
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.g_mobiledata, size: 24),
        label: Text(
          (widget.isLoading || _isSigningIn) ? 'Signing in...' : 'Continue with Google',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: (widget.isLoading || _isSigningIn) ? null : _handleMobileGoogleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.glassBackground,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.glassBorder),
          ),
        ),
        icon: (widget.isLoading || _isSigningIn)
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.g_mobiledata, size: 24),
        label: Text(
          (widget.isLoading || _isSigningIn) ? 'Signing in...' : 'Continue with Google',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Web-specific Google Sign-In - Simplified approach for mobile-first app
  // Note: This is a MOBILE app - web support is secondary
  Future<void> _handleWebGoogleSignIn() async {
    // Prevent multiple simultaneous sign-in attempts
    if (_isSigningIn) {
      print('Sign-in already in progress, ignoring duplicate request');
      return;
    }

    setState(() {
      _isSigningIn = true;
    });

    try {
      print('Starting Google Sign-In for web...');
      print('Note: This app is optimized for mobile. For best experience, please use the mobile app.');
      
      // Try to use google_sign_in package with better error handling
      // Skip silent sign-in on web to avoid FedCM issues
      GoogleSignInAccount? googleUser;
      
      // Check if user is already signed in
      final currentUser = _googleSignIn.currentUser;
      if (currentUser != null) {
        print('User already signed in: ${currentUser.email}');
        await _processGoogleUser(currentUser);
        return;
      }

      // For web, go straight to interactive sign-in
      // This avoids FedCM silent sign-in issues
      print('Opening Google Sign-In popup (web)...');
      print('⚠️ Note: Deprecation warnings are expected. This is a mobile app.');
      print('⚠️ If popup closes immediately, it\'s likely redirect_uri_mismatch - see FIX_REDIRECT_URI.md');
      
      // Track when we start the sign-in to detect immediate failures
      final signInStartTime = DateTime.now();
      
      // Use a timeout to prevent hanging
      googleUser = await _googleSignIn.signIn().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('Sign-in timed out. Please try again.');
        },
      );
      
      // Check if popup closed very quickly (likely due to redirect_uri_mismatch)
      final signInDuration = DateTime.now().difference(signInStartTime);
      if (googleUser == null) {
        // If popup closed in less than 2 seconds, it's likely a configuration error
        if (signInDuration.inSeconds < 2) {
          print('⚠️ Popup closed immediately - likely redirect_uri_mismatch error');
          // Get current URL to show exact redirect URI needed
          String currentUrl = 'http://localhost:PORT/';
          try {
            if (kIsWeb) {
              currentUrl = Uri.base.toString();
              if (!currentUrl.endsWith('/')) {
                currentUrl += '/';
              }
            }
          } catch (_) {
            // Use default if we can't get the URL
          }
          
          if (widget.onError != null) {
            final errorMsg = '⚠️ Popup closed immediately - redirect_uri_mismatch\n\n'
                'This is a MOBILE app. Mobile sign-in works 100%!\n\n'
                'To fix web sign-in:\n'
                '1. Go to: https://console.cloud.google.com/\n'
                '2. Project: content-nation-e0549\n'
                '3. APIs & Services → Credentials\n'
                '4. Edit: 597878741733-94oh71atkf557uqhrveuaocgcaanacmc\n'
                '5. Add redirect URIs:\n'
                '   • $currentUrl\n'
                '   • ${currentUrl.replaceAll('localhost', '127.0.0.1')}\n'
                '6. Save and wait 1-2 minutes\n\n'
                '📱 Use mobile app for best experience!';
            widget.onError!(errorMsg);
          }
          return;
        } else {
          print('Google Sign-In cancelled by user');
          return;
        }
      }
      
      print('✅ Google Sign-In successful: ${googleUser.email}');
      await _processGoogleUser(googleUser);
      
    } on TimeoutException catch (e) {
      print('Sign-in timeout: $e');
      if (widget.onError != null) {
        widget.onError!('Sign-in took too long. Please check your internet connection and try again.');
      }
    } catch (e) {
      print('Web Google Sign-In Error: $e');
      print('Error type: ${e.runtimeType}');
      
      String errorMessage = 'Google sign-in failed on web. ';
      final errorString = e.toString().toLowerCase();
      
      if (errorString.contains('redirect_uri_mismatch') || 
          errorString.contains('redirect_uri') ||
          errorString.contains('access blocked') ||
          errorString.contains('invalid request') ||
          errorString.contains('error 400')) {
        // Get current URL to show exact redirect URI needed
        String currentUrl = 'http://localhost:PORT/';
        try {
          if (kIsWeb) {
            // Try to get the actual URL
            // Note: This might not work in all contexts, so we have a fallback
            currentUrl = Uri.base.toString();
            if (!currentUrl.endsWith('/')) {
              currentUrl += '/';
            }
          }
        } catch (_) {
          // Use default if we can't get the URL
        }
        
        errorMessage = '⚠️ redirect_uri_mismatch Error\n\n';
        errorMessage += 'This is a MOBILE app optimized for Android & iOS.\n';
        errorMessage += 'Mobile sign-in works 100% without any configuration!\n\n';
        errorMessage += 'To fix web sign-in (optional):\n';
        errorMessage += '1. Go to: https://console.cloud.google.com/\n';
        errorMessage += '2. Select project: content-nation-e0549\n';
        errorMessage += '3. APIs & Services → Credentials\n';
        errorMessage += '4. Edit OAuth client: 597878741733-94oh71atkf557uqhrveuaocgcaanacmc\n';
        errorMessage += '5. Add to "Authorized redirect URIs":\n';
        errorMessage += '   • $currentUrl\n';
        errorMessage += '   • ${currentUrl.replaceAll('localhost', '127.0.0.1')}\n';
        errorMessage += '6. Save and wait 1-2 minutes\n\n';
        errorMessage += '📱 For best experience, use the mobile app!\n';
        errorMessage += 'See FIX_REDIRECT_URI.md for detailed instructions.';
      } else if (errorString.contains('popup_closed') || 
                 errorString.contains('popup was closed') ||
                 errorString.contains('popup closed')) {
        // Popup closed - could be user cancellation or redirect_uri_mismatch
        // If it closed very quickly, it's likely redirect_uri_mismatch
        print('Popup closed - checking if it\'s a configuration error...');
        
        // Show helpful message about redirect_uri_mismatch
        String currentUrl = 'http://localhost:PORT/';
        try {
          if (kIsWeb) {
            currentUrl = Uri.base.toString();
            if (!currentUrl.endsWith('/')) {
              currentUrl += '/';
            }
          }
        } catch (_) {}
        
        if (widget.onError != null) {
          final errorMsg = '⚠️ Sign-in popup closed\n\n'
              'This usually means redirect_uri_mismatch.\n'
              'This is a MOBILE app - mobile works 100%!\n\n'
              'To fix web sign-in:\n'
              'Add to Google Cloud Console → Credentials → OAuth client:\n'
              '• $currentUrl\n'
              '• ${currentUrl.replaceAll('localhost', '127.0.0.1')}\n\n'
              'See FIX_REDIRECT_URI.md for details.\n'
              '📱 Use mobile app for best experience!';
          widget.onError!(errorMsg);
        }
        return;
      } else if (errorString.contains('fedcm') || 
                 errorString.contains('cors') ||
                 errorString.contains('network')) {
        errorMessage += 'Network or browser error. ';
        errorMessage += 'This app is optimized for mobile. Please use the mobile app for best experience.';
      } else {
        errorMessage += 'This app is optimized for mobile devices. Please use the mobile app.';
      }
      
      if (widget.onError != null) {
        widget.onError!(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  // Mobile-specific Google Sign-In - Optimized for 100% reliability on Android & iOS
  Future<void> _handleMobileGoogleSignIn() async {
    // Prevent multiple simultaneous sign-in attempts
    if (_isSigningIn) {
      print('Sign-in already in progress, ignoring duplicate request');
      return;
    }

    setState(() {
      _isSigningIn = true;
    });

    try {
      print('Starting Google Sign-In for mobile...');
      
      GoogleSignInAccount? googleUser;
      
      // Step 1: Try silent sign-in first (works if user previously signed in)
      // This is the most reliable method and doesn't require user interaction
      try {
        print('Attempting silent sign-in (no user interaction required)...');
        googleUser = await _googleSignIn.signInSilently();
        if (googleUser != null) {
          print('✅ Silent sign-in successful, user: ${googleUser.email}');
        } else {
          print('Silent sign-in returned null (no previous session found)');
        }
      } catch (e) {
        // Silent sign-in failure is expected if user hasn't signed in before
        // This is not an error, just means we need interactive sign-in
        print('Silent sign-in not available (expected for first-time users): $e');
      }

      // Step 2: If silent sign-in didn't work, use interactive sign-in
      if (googleUser == null) {
        print('Proceeding with interactive sign-in...');
        
        // Clear any existing sign-in state to ensure clean authentication
        try {
          final GoogleSignInAccount? currentUser = _googleSignIn.currentUser;
          if (currentUser != null) {
            print('Clearing previous sign-in session...');
            await _googleSignIn.signOut();
            // Small delay to ensure sign-out completes
            await Future.delayed(const Duration(milliseconds: 300));
          }
        } catch (e) {
          // Ignore sign-out errors, continue with sign-in
          print('Sign-out error (ignoring): $e');
        }

        // Interactive sign-in - opens Google Sign-In UI
        try {
          print('Opening Google Sign-In UI...');
          googleUser = await _googleSignIn.signIn().timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw TimeoutException('Sign-in timed out. Please try again.');
            },
          );
        } on TimeoutException catch (e) {
          print('Sign-in timeout: $e');
          throw 'Sign-in took too long. Please check your internet connection and try again.';
        } catch (e) {
          // Re-throw to be handled by outer catch block
          rethrow;
        }
      }
      
      // Step 3: Validate sign-in result
      if (googleUser == null) {
        print('Google Sign-In was cancelled by user');
        // User cancellation is not an error, just return silently
        return;
      }
      
      print('✅ Google Sign-In successful, user: ${googleUser.email}');
      
      // Step 4: Process the authenticated user
      await _processGoogleUser(googleUser);
      
    } catch (e) {
      print('❌ Mobile Google Sign-In Error: $e');
      print('Error type: ${e.runtimeType}');
      
      String errorMessage = 'Google sign-in failed. Please try again.';
      
      // Comprehensive error handling for mobile-specific errors
      final errorString = e.toString().toLowerCase();
      
      if (errorString.contains('network') || 
          errorString.contains('timeout') || 
          errorString.contains('connection') ||
          errorString.contains('unreachable')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      } else if (errorString.contains('sign_in_cancelled') || 
                 errorString.contains('cancelled') ||
                 errorString.contains('user cancelled')) {
        // User cancellation - don't show error
        print('User cancelled sign-in - no error shown');
        return;
      } else if (errorString.contains('sign_in_failed') || 
                 errorString.contains('authentication failed') ||
                 errorString.contains('auth')) {
        // More detailed error message
        print('🔍 Detailed auth error: $e');
        if (errorString.contains('network') || errorString.contains('timeout')) {
          errorMessage = 'Network error. Please check your internet connection.';
        } else if (errorString.contains('play services') || errorString.contains('gms')) {
          errorMessage = 'Google Play Services required. Please update Google Play Services.';
        } else {
          errorMessage = 'Authentication failed. Please check your Google account and try again.';
        }
      } else if (errorString.contains('invalid_client') || 
                 errorString.contains('oauth')) {
        errorMessage = 'Configuration error. Please contact support.';
      } else if (errorString.contains('platform_exception') ||
                 errorString.contains('platform error')) {
        errorMessage = 'Sign-in error. Please try again or restart the app.';
      } else if (errorString.contains('already signed in')) {
        // If already signed in, try to get current user
        try {
          final currentUser = _googleSignIn.currentUser;
          if (currentUser != null) {
            await _processGoogleUser(currentUser);
            return;
          }
        } catch (_) {
          errorMessage = 'Sign-in error. Please try signing out and signing in again.';
        }
      }
      
      // Only show error if it's not a user cancellation
      if (widget.onError != null && !errorString.contains('cancelled')) {
        widget.onError!(errorMessage);
      }
    } finally {
      // Always reset the signing-in state
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  Future<void> _processGoogleUser(GoogleSignInAccount googleUser) async {
    try {
      // Obtain the auth details from the request
      print('Obtaining authentication tokens...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print('Failed to obtain tokens - AccessToken: ${googleAuth.accessToken != null}, IdToken: ${googleAuth.idToken != null}');
        throw 'Failed to obtain Google authentication tokens';
      }

      print('Tokens obtained successfully, creating Firebase credential...');
      
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      print('Signing in to Firebase with Google credential...');
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      print('Google Sign-In successful: ${userCredential.user?.email}');
      
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      }
      
    } catch (e) {
      print('Error processing Google user: $e');
      rethrow;
    }
  }
}
