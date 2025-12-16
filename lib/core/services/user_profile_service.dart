import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'storage_service.dart';

class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  /// Get current user profile data
  Future<Map<String, String?>> getUserProfile() async {
    // Always prioritize local storage first (most up-to-date)
    final localName = StorageService.getString('user_display_name');
    final localPhoto = StorageService.getString('user_photo_url');
    
    final user = _auth.currentUser;
    if (user == null) {
      // No user logged in, return local storage only
      return {
        'name': localName,
        'photoUrl': localPhoto,
      };
    }

    // Reload user to get latest Firebase data
    await user.reload();
    final reloadedUser = _auth.currentUser;

    // Prioritize local storage, then Firebase, then empty
    return {
      'name': (localName != null && localName.isNotEmpty) 
          ? localName 
          : (reloadedUser?.displayName ?? ''),
      'photoUrl': (localPhoto != null && localPhoto.isNotEmpty) 
          ? localPhoto 
          : (reloadedUser?.photoURL ?? ''),
      'email': reloadedUser?.email ?? user.email,
    };
  }

  /// Update user display name
  Future<void> updateDisplayName(String name) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(name);
        await user.reload();
      }
      // Also save locally
      await StorageService.setString('user_display_name', name);
    } catch (e) {
      print('Error updating display name: $e');
      // Still save locally even if Firebase fails
      await StorageService.setString('user_display_name', name);
    }
  }

  /// Update user profile picture
  Future<String?> updateProfilePicture(String? photoUrl) async {
    try {
      final user = _auth.currentUser;
      if (user != null && photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
        await user.reload();
      }
      // Also save locally
      if (photoUrl != null) {
        await StorageService.setString('user_photo_url', photoUrl);
      }
      return photoUrl;
    } catch (e) {
      print('Error updating profile picture: $e');
      // Still save locally even if Firebase fails
      if (photoUrl != null) {
        await StorageService.setString('user_photo_url', photoUrl);
      }
      return photoUrl;
    }
  }

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  /// Upload image to Firebase Storage and get URL
  Future<String?> uploadImageToFirebase(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('⚠️ No user logged in, cannot upload to Firebase');
        // Still save locally as file path for offline use
        return imageFile.path;
      }

      print('📤 Uploading image to Firebase Storage...');
      final fileName = path.basename(imageFile.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef = _storage.ref().child('profile_pictures/${user.uid}_$timestamp$fileName');

      // Upload with metadata
      await storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'public, max-age=31536000',
        ),
      );
      
      final downloadUrl = await storageRef.getDownloadURL();
      print('✅ Image uploaded successfully: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading image to Firebase: $e');
      // Fallback: return local file path
      print('📁 Using local file path as fallback: ${imageFile.path}');
      return imageFile.path;
    }
  }

  /// Update profile picture from file
  Future<String?> updateProfilePictureFromFile(File imageFile) async {
    try {
      print('📸 Updating profile picture from file: ${imageFile.path}');
      
      // Upload to Firebase Storage (or get local path)
      final photoUrl = await uploadImageToFirebase(imageFile);
      
      if (photoUrl != null) {
        print('✅ Got photo URL: $photoUrl');
        
        // Update user profile in Firebase
        await updateProfilePicture(photoUrl);
        
        // Also save file path locally as backup
        await StorageService.setString('user_photo_file_path', imageFile.path);
        
        print('✅ Profile picture updated successfully');
        return photoUrl;
      } else {
        print('⚠️ Failed to get photo URL');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Error updating profile picture from file: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
}

