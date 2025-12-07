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
  );

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
        onPressed: widget.isLoading ? null : _handleWebGoogleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.glassBackground,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.glassBorder),
          ),
        ),
        icon: widget.isLoading 
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
          widget.isLoading ? 'Signing in...' : 'Continue with Google',
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
        onPressed: widget.isLoading ? null : _handleMobileGoogleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.glassBackground,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.glassBorder),
          ),
        ),
        icon: widget.isLoading 
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
          widget.isLoading ? 'Signing in...' : 'Continue with Google',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Web-specific Google Sign-In using direct approach (bypassing FedCM)
  Future<void> _handleWebGoogleSignIn() async {
    try {
      print('Starting Google Sign-In for web...');
      
      // Check if user is already signed in
      final GoogleSignInAccount? currentUser = _googleSignIn.currentUser;
      if (currentUser != null) {
        print('User already signed in, signing out first...');
        await _googleSignIn.signOut();
      }

      // For web, skip silent sign-in and use direct interactive sign-in
      // This avoids FedCM issues and uses the traditional popup flow
      print('Using direct interactive sign-in for web...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('Google Sign-In cancelled by user');
        return;
      }
      
      print('Google Sign-In successful, user: ${googleUser.email}');
      
      // Process the Google user
      await _processGoogleUser(googleUser);
      
    } catch (e) {
      print('Web Google Sign-In Error: $e');
      print('Error type: ${e.runtimeType}');
      
      String errorMessage = 'Google sign-in failed. Please try again.';
      
      // Handle specific errors with more detailed messages
      if (e.toString().contains('CORS') || e.toString().contains('ERR_FAILED')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      } else if (e.toString().contains('FedCM') || e.toString().contains('IdentityCredentialError')) {
        errorMessage = 'Browser authentication error. Please try using a different browser or disable popup blockers.';
      } else if (e.toString().contains('popup_closed')) {
        errorMessage = 'Google Sign-In popup was closed. Please try again.';
      } else if (e.toString().contains('network') || e.toString().contains('timeout')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      } else if (e.toString().contains('redirect_uri_mismatch')) {
        errorMessage = 'Configuration error. Please check your Google Cloud Console settings.';
      } else if (e.toString().contains('invalid_client')) {
        errorMessage = 'Client configuration error. Please check your OAuth client settings.';
      } else if (e.toString().contains('unknown_reason')) {
        errorMessage = 'Authentication failed. Please try refreshing the page and signing in again.';
      }
      
      if (widget.onError != null) {
        widget.onError!(errorMessage);
      }
    }
  }

  // Mobile-specific Google Sign-In
  Future<void> _handleMobileGoogleSignIn() async {
    try {
      print('Starting Google Sign-In for mobile...');
      
      // Check if user is already signed in
      final GoogleSignInAccount? currentUser = _googleSignIn.currentUser;
      if (currentUser != null) {
        print('User already signed in, signing out first...');
        await _googleSignIn.signOut();
      }

      // For mobile, use interactive sign-in directly
      print('Attempting interactive sign-in...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('Google Sign-In cancelled by user');
        return;
      }
      
      print('Google Sign-In successful, user: ${googleUser.email}');
      
      // Process the Google user
      await _processGoogleUser(googleUser);
      
    } catch (e) {
      print('Mobile Google Sign-In Error: $e');
      print('Error type: ${e.runtimeType}');
      
      String errorMessage = 'Google sign-in failed. Please try again.';
      
      // Handle specific errors with more detailed messages
      if (e.toString().contains('CORS') || e.toString().contains('ERR_FAILED')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      } else if (e.toString().contains('FedCM') || e.toString().contains('IdentityCredentialError')) {
        errorMessage = 'Authentication error. Please try refreshing the page and signing in again.';
      } else if (e.toString().contains('popup_closed')) {
        errorMessage = 'Google Sign-In popup was closed. Please try again.';
      } else if (e.toString().contains('network') || e.toString().contains('timeout')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      } else if (e.toString().contains('redirect_uri_mismatch')) {
        errorMessage = 'Configuration error. Please check your Google Cloud Console settings.';
      } else if (e.toString().contains('invalid_client')) {
        errorMessage = 'Client configuration error. Please check your OAuth client settings.';
      }
      
      if (widget.onError != null) {
        widget.onError!(errorMessage);
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
