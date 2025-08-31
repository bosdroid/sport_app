import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart' as crypto;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final DatabaseReference _usernamesRef;
  final DatabaseReference _usersDetailsRef;

  AuthRepositoryImpl(this._firebaseAuth, FirebaseDatabase database)
      : _usernamesRef = database.ref().child('USERNAMES/'),
        _usersDetailsRef = database.ref().child('USERS_DETAILS/');

  @override
  Future<User?> loadUserFromSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email != null) {
      return _firebaseAuth.currentUser;
    }
    return null;
  }

  @override
  Future<User?> loginWithEmail(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
    final user = credential.user;

    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final userSnapshot = await _usernamesRef.child(user.uid).get();

      if (userSnapshot.exists) {
        final value = userSnapshot.value as Map?;
        prefs.setString('user_name', value?['username']);
      }
      prefs.setString('user_email', user.email!);
    }

    return user;
  }

  @override
  Future<User?> signUpWithEmail(String username, String email, String password) async {
    final snapshot = await _usernamesRef.orderByChild('username').equalTo(username).get();
    if (snapshot.exists) {
      throw FirebaseAuthException(code: 'username-taken', message: 'Username already exists.');
    }

    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      await _usernamesRef.child(user.uid).set({'username': username});
      await _usersDetailsRef.child(username).update({
        'id': user.uid,
        'username': username,
        'email': user.email,
        'type': 'email',
      });

      final prefs = await SharedPreferences.getInstance();
      prefs.setString('user_email', user.email!);
      prefs.setString('user_name', username);
    }
    return user;
  }

  @override
  Future<User?> loginWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final authResult = await _firebaseAuth.signInWithCredential(credential);
    final user = authResult.user;

    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final userSnapshot = await _usernamesRef.child(user.uid).get();

      if (!userSnapshot.exists) {
        final defaultUsername = await _generateDefaultUsername();
        await _usernamesRef.child(user.uid).set({'username': defaultUsername});
        await _usersDetailsRef.child(defaultUsername).update({
          'id': user.uid,
          'username': defaultUsername,
          'email': user.email,
          'type': 'google',
        });
        prefs.setString('user_name', defaultUsername);
      } else {
        final value = userSnapshot.value as Map?;
        final username = value?['username'];
        prefs.setString('user_name', username);
      }

      prefs.setString('user_email', user.email!);
    }
    return user;
  }

  @override
  Future<User?> loginWithApple() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      nonce: nonce,
    );

    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    final authResult = await _firebaseAuth.signInWithCredential(oauthCredential);
    final user = authResult.user;

    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final userSnapshot = await _usernamesRef.child(user.uid).get();

      if (!userSnapshot.exists) {
        final defaultUsername = await _generateDefaultUsername();
        await _usernamesRef.child(user.uid).set({'username': defaultUsername});
        await _usersDetailsRef.child(defaultUsername).update({
          'id': user.uid,
          'username': defaultUsername,
          'email': user.email,
          'type': 'apple',
        });
        prefs.setString('user_name', defaultUsername);
      }
      prefs.setString('user_email', user.email ?? "");
    }
    return user;
  }

  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await GoogleSignIn().signOut();
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('user_email');
    prefs.remove('user_name');
  }

  @override
  String? validateUsernameInput(String username) {
    if (username.isEmpty) {
      return 'Username cannot be empty';
    }
    if (username.length < 6) {
      return 'Username must be at least 6 characters long';
    }
    final usernameRegExp = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegExp.hasMatch(username)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null; // ✅ valid
  }

  // Helpers
  Future<String> _generateDefaultUsername() async {
    final snapshot = await _usernamesRef.orderByChild('username').limitToLast(1).get();
    if (!snapshot.exists) return 'user001';

    final value = snapshot.children.last.value as Map?;
    final lastUsername = value?['username'] as String? ?? '';
    final lastNumber = int.tryParse(lastUsername.replaceFirst(RegExp(r'user'), '')) ?? 0;
    return 'user${(lastNumber + 1).toString().padLeft(3, '0')}';
  }

  String _generateNonce([int length = 32]) {
    final random = Random.secure();
    final charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = crypto.sha256.convert(bytes);
    return digest.toString();
  }

  @override
  String getErrorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found for that email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many failed attempts. Try again later.';
        case 'username-taken':
          return 'This username is already taken. Please choose another.';
        default:
          return 'Unexpected error during login: ${e.message}';
      }
    }
    return 'Unexpected error: ${e.toString()}';
  }

  @override
  String getAppleLoginErrorMessage(Object e) {
    if (e is SignInWithAppleAuthorizationException) {
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          return "Apple login was cancelled by the user.";
        case AuthorizationErrorCode.failed:
          return "Apple login failed. Please try again.";
        case AuthorizationErrorCode.invalidResponse:
          return "Invalid response from Apple login.";
        case AuthorizationErrorCode.notHandled:
          return "Apple login was not handled.";
        case AuthorizationErrorCode.unknown:
          return "An unknown error occurred during Apple login.";
        default:
          return 'Unexpected error during login: ${e.message}';
      }
    }
    return "Unexpected error during Apple login: ${e.toString()}";
  }
}
