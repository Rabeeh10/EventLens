import 'package:firebase_auth/firebase_auth.dart';

/// Authentication service layer for EventLens.
/// 
/// Abstracts Firebase Authentication operations from UI layer.
/// Provides clean methods for login, registration, and logout
/// with consistent error handling and return types.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns the currently authenticated user, if any.
  User? get currentUser => _auth.currentUser;

  /// Stream of authentication state changes.
  /// 
  /// Emits null when user logs out, User object when logged in.
  /// UI can listen to this stream for reactive authentication state.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Registers a new user with email and password.
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
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

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
