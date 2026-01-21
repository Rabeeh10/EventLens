import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Service for handling Firebase Storage operations.
///
/// Manages image uploads for events, stalls, and AR marker references.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload event image to Firebase Storage.
  ///
  /// Returns the download URL on success, null on failure.
  /// Path: events/{eventId}/event_image.jpg
  Future<String?> uploadEventImage({
    required String eventId,
    required File imageFile,
  }) async {
    try {
      final ref = _storage.ref().child('events/$eventId/event_image.jpg');
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading event image: $e');
      return null;
    }
  }

  /// Upload stall image to Firebase Storage.
  ///
  /// Returns the download URL on success, null on failure.
  /// Path: stalls/{stallId}/stall_image.jpg
  Future<String?> uploadStallImage({
    required String stallId,
    required File imageFile,
  }) async {
    try {
      final ref = _storage.ref().child('stalls/$stallId/stall_image.jpg');
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading stall image: $e');
      return null;
    }
  }

  /// Upload AR marker reference image to Firebase Storage.
  ///
  /// This is the reference image used for AR marker detection.
  /// Returns the download URL on success, null on failure.
  /// Path: markers/{markerId}/marker_reference.jpg
  Future<String?> uploadMarkerImage({
    required String markerId,
    required File imageFile,
  }) async {
    try {
      final ref = _storage.ref().child(
        'markers/$markerId/marker_reference.jpg',
      );
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading marker image: $e');
      return null;
    }
  }

  /// Delete an image from Firebase Storage.
  ///
  /// Returns true on success, false on failure.
  Future<bool> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  /// Upload image with progress tracking.
  ///
  /// Returns a stream of upload progress (0.0 to 1.0).
  /// Useful for showing progress indicators during large uploads.
  Stream<double> uploadImageWithProgress({
    required String path,
    required File imageFile,
  }) {
    final ref = _storage.ref().child(path);
    final uploadTask = ref.putFile(imageFile);

    return uploadTask.snapshotEvents.map((snapshot) {
      return snapshot.bytesTransferred / snapshot.totalBytes;
    });
  }

  /// Get download URL for an existing file.
  ///
  /// Returns the download URL on success, null on failure.
  Future<String?> getDownloadUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error getting download URL: $e');
      return null;
    }
  }
}
