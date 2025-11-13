import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  /// Loads a saved user session if available.
  Future<User?> loadUserFromSession();

  /// Login using email & password.
  Future<User?> loginWithEmail(String email, String password);

  /// Register a new user with email & username.
  Future<User?> signUpWithEmail(String username, String email, String password);

  /// Login using Google.
  Future<User?> loginWithGoogle();

  /// Login using Apple.
  Future<User?> loginWithApple();

  /// Login using Apple.
  Future<void> loginAsGuest();

  /// Logout from Firebase & clear session.
  Future<void> logout();

  /// Validate a username input and return an error string, or null if valid.
  String? validateUsernameInput(String username);

  /// Maps FirebaseAuthException to a user-friendly message
  String getErrorMessage(Object e);

  /// Maps Apple Sign-In errors to a user-friendly message
  String getAppleLoginErrorMessage(Object e);

}
