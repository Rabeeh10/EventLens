import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Authentication service layer for EventLens.
/// 
/// Abstracts Firebase Authentication operations from UI layer.
/// Provides clean methods for login, registration, and logout
/// with consistent error handling and return types.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns the currently authenticated user, if any.
  User? get currentUser => _auth.currentUser;

  /// Stream of authentication state changes.
  /// 
  /// Emits null when user logs out, User object when logged in.
  /// UI can listen to this stream for reactive authentication state.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Creates Firebase Authentication account and Firestore user document.
  /// User document includes email and default role ('user').
  /// 
  /// Returns AuthResult with success status and optional error message.
  /// 
  /// Example:
  /// ```dart
  /// final result = await authService.register('user@example.com', 'password123');
  /// if (result.success) {
  ///   // Navigate to home
  /// } else {
  ///   // Show error: result.error
  /// }
  /// ```
  Future<AuthResult> register({
    required String email,
    required String password,
  }) async {
    try {
      // Create Firebase Authentication account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Create user document in Firestore
      if (userCredential.user != null) {
        await _createUserDocument(
          uid: userCredential.user!.uid,
          email: email.trim(),
        );
      }

      // Optional: Send email verification
      await userCredential.user?.sendEmailVerification();

      return AuthResult(
        success: true,
        user: userCredential.user,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        error: _mapFirebaseError(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'An unexpected error occurred: $e',
      );
    }
  }

  /// Creates user document in Firestore with default role.
  /// 
  /// Document structure:
  /// ```
  /// users/{uid}
  ///   - email: String
  ///   - role: String (default: 'user')
  ///   - createdAt: Timestamp
  /// ```
  /// 
  /// Role determines user permissions:
  /// - 'user': Regular app user (can view events, create bookmarks)
  /// - 'admin': Administrator (can create/edit/delete events)
  /// - 'organizer': Event organizer (can create/manage own events)
  Future<void> _createUserDocument({
    required String uid,
    required String email,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'role': 'user', // Default role for new users
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Authenticates user with email and password.
  /// 
  /// Returns AuthResult with success status and optional error message.
  /// 
  /// Example:
  /// ```dart
  /// final result = await authService.login('user@example.com', 'password123');
  /// if (result.success) {
  ///   // User logged in successfully
  /// } else {
  ///   // Show error: result.error
  /// }
  /// ```
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return AuthResult(
        success: true,
        user: userCredential.user,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        error: _mapFirebaseError(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'An unexpected error occurred: $e',
      );
    }
  }

  /// Signs out the current user.
  /// 
  /// Returns AuthResult indicating success or failure.
  /// Clears all session data and authentication tokens.
  Future<AuthResult> logout() async {
    try {
      await _auth.signOut();
      
      return AuthResult(success: true);
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Failed to log out: $e',
      );
    }
  }

  /// Sends password reset email to the specified address.
  /// 
  /// Returns AuthResult indicating success or failure.
  Future<AuthResult> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      
      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        error: _mapFirebaseError(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Failed to send reset email: $e',
      );
    }
  }

  /// Retrieves user role from Firestore.
  /// 
  /// Returns role string ('user', 'admin', 'organizer') or null if not found.
  /// Used for role-based access control throughout the app.
  /// 
  /// Example:
  /// ```dart
  /// final role = await authService.getUserRole(uid);
  /// if (role == 'admin') {
  ///   // Show admin dashboard
  /// }
  /// ```
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['role'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Checks if current user has admin privileges.
  /// 
  /// Convenience method for admin access control.
  Future<bool> isAdmin() async {
    final user = currentUser;
    if (user == null) return false;
    
    final role = await getUserRole(user.uid);
    return role == 'admin';
  }

  /// Maps Firebase error codes to user-friendly error messages.
  /// 
  /// Centralizes error message handling for consistent UX.
  String _mapFirebaseError(String code) {
    switch (code) {
      // Registration errors
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters';
      
      // Login errors
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      
      // Common errors
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'Email/password authentication is not enabled';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      
      default:
        return 'Authentication error: $code';
    }
  }
}

/// Result object for authentication operations.
/// 
/// Provides consistent return type for all auth methods.
/// Success boolean indicates operation outcome.
/// Error message provided when success is false.
/// User object provided when success is true.
class AuthResult {
  final bool success;
  final String? error;
  final User? user;

  AuthResult({
    required this.success,
    this.error,
    this.user,
  });
}
