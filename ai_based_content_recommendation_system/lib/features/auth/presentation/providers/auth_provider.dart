import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // This would require Google Sign-In implementation
      // For now, returning null as placeholder
      return null;
    } catch (e) {
      throw 'Google sign-in failed: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
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
