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

  // Sign in with Google (Updated for FedCM compatibility)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('Starting Google Sign-In process...');
      
      // Check if user is already signed in
      final GoogleSignInAccount? currentUser = _googleSignIn.currentUser;
      if (currentUser != null) {
        print('User already signed in, signing out first...');
        await _googleSignIn.signOut();
      }

      GoogleSignInAccount? googleUser;
      
      if (kIsWeb) {
        // For web, use direct interactive sign-in to avoid FedCM issues
        print('Using direct interactive sign-in for web...');
        googleUser = await _googleSignIn.signIn();
      } else {
        // For mobile, use interactive sign-in directly
        print('Attempting interactive sign-in for mobile...');
        googleUser = await _googleSignIn.signIn();
      }
      
      if (googleUser == null) {
        print('Google Sign-In cancelled by user');
        throw 'Google Sign-In was cancelled by user.';
      }
      
      print('Google Sign-In successful, user: ${googleUser.email}');
      return await _processGoogleUser(googleUser);
      
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      print('Error details: ${e.toString()}');
      
      if (e.code == 'account-exists-with-different-credential') {
        throw 'An account already exists with the same email address but different sign-in credentials.';
      } else if (e.code == 'invalid-credential') {
        throw 'The credential is invalid or has expired. Please try again.';
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
      
      // Handle CORS errors
      if (e.toString().contains('CORS') || e.toString().contains('ERR_FAILED')) {
        throw 'CORS error detected. Please check your Google Cloud Console configuration and ensure your domain is properly configured.';
      }
      
      // Handle FedCM errors
      if (e.toString().contains('FedCM') || e.toString().contains('IdentityCredentialError')) {
        throw 'Authentication error. Please try refreshing the page and signing in again.';
      }
      
      // Handle popup closed errors
      if (e.toString().contains('popup_closed')) {
        throw 'Google Sign-In popup was closed. Please try again.';
      }
      
      // Handle specific Google Sign-In errors
      if (e.toString().contains('sign_in_failed')) {
        throw 'Google Sign-In failed. Please check your internet connection and try again.';
      }
      
      // Handle network errors
      if (e.toString().contains('network') || e.toString().contains('timeout')) {
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
