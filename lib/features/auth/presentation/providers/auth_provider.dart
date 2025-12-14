import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

final authProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // OAuth client ID from Google Cloud Console
    clientId: '597878741733-94oh71atkf557uqhrveuaocgcaanacmc.apps.googleusercontent.com',
    scopes: ['openid', 'email', 'profile'],
    // For web: Disable FedCM to avoid CORS errors
    // For mobile: This is ignored and native SDK is used
  );

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      // Handle specific Firebase errors
      if (e.code == 'invalid-credential') {
        throw 'Invalid email or password. Please check your credentials and try again.';
      } else if (e.code == 'user-not-found') {
        throw 'No account found with this email address. Please sign up first.';
      } else if (e.code == 'wrong-password') {
        throw 'Incorrect password. Please try again.';
      } else if (e.code == 'too-many-requests') {
        throw 'Too many failed attempts. Please try again later.';
      } else if (e.code == 'network-request-failed') {
        throw 'Network error. Please check your internet connection.';
      }
      throw _handleAuthException(e);
    } catch (e) {
      print('General Error: $e');
      throw 'An unexpected error occurred: $e';
    }
  }

  // Create user with email and password
  Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      // Handle specific Firebase errors
      if (e.code == 'email-already-in-use') {
        throw 'An account already exists with this email address. Please sign in instead.';
      } else if (e.code == 'weak-password') {
        throw 'Password is too weak. Please choose a stronger password.';
      } else if (e.code == 'invalid-email') {
        throw 'Please enter a valid email address.';
      } else if (e.code == 'network-request-failed') {
        throw 'Network error. Please check your internet connection.';
      }
      throw _handleAuthException(e);
    } catch (e) {
      print('General Error: $e');
      throw 'An unexpected error occurred: $e';
    }
  }

  // Sign in with Google - Optimized for mobile reliability
  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('Starting Google Sign-In process...');
      
      GoogleSignInAccount? googleUser;
      
      // Step 1: Try silent sign-in first (works for both web and mobile)
      // This is the most reliable method and doesn't require user interaction
      try {
        print('Attempting silent sign-in...');
        googleUser = await _googleSignIn.signInSilently();
        if (googleUser != null) {
          print('✅ Silent sign-in successful, user: ${googleUser.email}');
        } else {
          print('Silent sign-in returned null, will try interactive sign-in');
        }
      } catch (e) {
        // Silent sign-in failure is expected if user hasn't signed in before
        print('Silent sign-in not available (expected for first-time users): $e');
      }

      // Step 2: If silent sign-in didn't work, use interactive sign-in
      if (googleUser == null) {
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

        if (kIsWeb) {
          // For web, use interactive sign-in directly
          // Note: This app is optimized for mobile - web support is secondary
          print('Using interactive sign-in for web...');
          print('⚠️ Note: This app is optimized for mobile devices.');
          googleUser = await _googleSignIn.signIn();
        } else {
          // For mobile, use interactive sign-in with timeout protection
          print('Attempting interactive sign-in for mobile...');
          try {
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
            // Check for Google Play Services errors
            final errorStr = e.toString().toLowerCase();
            if (errorStr.contains('play services') || 
                errorStr.contains('gms') || 
                errorStr.contains('unavailable') ||
                errorStr.contains('sign_in_required_activity')) {
              print('❌ Google Play Services error: $e');
              throw 'Google Play Services is required for Google Sign-In. Please use a Google Play Services enabled emulator or test on a real device.';
            }
            rethrow;
          }
        }
      }
      
      if (googleUser == null) {
        print('Google Sign-In cancelled by user');
        return null; // Return null instead of throwing for user cancellation
      }
      
      print('✅ Google Sign-In successful, user: ${googleUser.email}');
      return await _processGoogleUser(googleUser);
      
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      print('Error details: ${e.toString()}');
      
      if (e.code == 'account-exists-with-different-credential') {
        throw 'An account already exists with the same email address but different sign-in credentials.';
      } else if (e.code == 'invalid-credential') {
        // Clear any cached credentials and suggest retry
        try {
          await _googleSignIn.signOut();
        } catch (_) {}
        throw 'Authentication failed. Please try signing in again.';
      } else if (e.code == 'operation-not-allowed') {
        throw 'Google Sign-In is not enabled. Please enable it in Firebase Console.';
      } else if (e.code == 'user-disabled') {
        throw 'This user account has been disabled.';
      } else if (e.code == 'too-many-requests') {
        throw 'Too many requests. Please try again later.';
      }
      throw _handleAuthException(e);
    } catch (e) {
      print('Google Sign-In Error: $e');
      print('Error type: ${e.runtimeType}');
      
      final errorString = e.toString().toLowerCase();
      
      // Handle Google Play Services errors (common on emulators)
      if (errorString.contains('play services') || 
          errorString.contains('gms') || 
          errorString.contains('sign_in_required_activity') ||
          errorString.contains('unavailable')) {
        throw '⚠️ Google Play Services Required\n\n'
            'Google Sign-In requires Google Play Services.\n\n'
            'If using an emulator:\n'
            '• Use a Google Play Services enabled emulator image\n'
            '• Or test on a real Android device\n\n'
            'On a real device:\n'
            '• Make sure Google Play Services is installed and updated';
      }
      
      // Handle CORS errors
      if (errorString.contains('cors') || errorString.contains('err_failed')) {
        throw 'CORS error detected. Please check your Google Cloud Console configuration and ensure your domain is properly configured.';
      }
      
      // Handle FedCM errors
      if (errorString.contains('fedcm') || errorString.contains('identitycredentialerror')) {
        throw 'Authentication error. Please try refreshing the page and signing in again.';
      }
      
      // Handle popup closed errors
      if (errorString.contains('popup_closed')) {
        throw 'Google Sign-In popup was closed. Please try again.';
      }
      
      // Handle specific Google Sign-In errors
      if (errorString.contains('sign_in_failed')) {
        throw 'Google Sign-In failed. Please check your internet connection and try again.';
      }
      
      // Handle network errors
      if (errorString.contains('network') || errorString.contains('timeout')) {
        throw 'Network error. Please check your internet connection and try again.';
      }
      
      throw 'Google sign-in failed: $e';
    }
  }

  // Process Google user authentication (used by both silent and button sign-in)
  Future<UserCredential?> _processGoogleUser(GoogleSignInAccount googleUser) async {
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
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      print('Google Sign-In successful: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      print('Error processing Google user: $e');
      rethrow;
    }
  }


  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      throw 'Sign out failed: $e';
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.updatePhotoURL(photoURL);
      }
    } catch (e) {
      throw 'Profile update failed: $e';
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/Password authentication is not enabled. Please enable it in Firebase Console.';
      case 'invalid-credential':
        return 'The credential is invalid or has expired.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email address but different sign-in credentials.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please log in again.';
      default:
        return 'An error occurred: ${e.message} (Code: ${e.code})';
    }
  }
}
