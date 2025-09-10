  import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart' as crypto;

class AuthProvider with ChangeNotifier {
  final DatabaseReference _usernamesRef = FirebaseDatabase.instance.ref().child('USERNAMES/');
  final DatabaseReference _usersDetailsRef = FirebaseDatabase.instance.ref().child('USERS_DETAILS/');
  final DatabaseReference _foldersRef = FirebaseDatabase.instance.ref().child('FOLDERS/');
  final DatabaseReference _goalsRef = FirebaseDatabase.instance.ref().child('USERS/GOALS/');
  final DatabaseReference _historyGoalsRef = FirebaseDatabase.instance.ref().child('GOALS_HISTORY/');
  final DatabaseReference _logRef = FirebaseDatabase.instance.ref().child('USERS/LOGS/');
  final DatabaseReference _historyLogsRef = FirebaseDatabase.instance.ref().child('LOGS_HISTORY/');
  final DatabaseReference _notesRef = FirebaseDatabase.instance.ref().child('NOTES/');
  final DatabaseReference _plansRef = FirebaseDatabase.instance.ref().child('PLANS/');
  final DatabaseReference _favouritesRef = FirebaseDatabase.instance.ref().child('FAVOURITES/');

  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loadUserFromSession();
  }

  Future<void> _loadUserFromSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email != null) {
      _user = FirebaseAuth.instance.currentUser;
      notifyListeners();
    }
  }

  Future<void> loginWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      _user = credential.user;

      // Save session
      final prefs = await SharedPreferences.getInstance();

      // Check if the user already has a username in the database
      final userSnapshot = await _usernamesRef.child(_user!.uid).get();

      if (userSnapshot.exists) {
        // Save the existing username in session
        final value = userSnapshot.value as Map?;
        prefs.setString('user_name', value?['username']);
      }

      prefs.setString('user_email', _user!.email!);


      notifyListeners();
    } catch (e) {
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithEmail(String username, String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check if the username already exists
      final snapshot = await _usernamesRef.orderByChild('username').equalTo(username).get();
      if (snapshot.exists) {
        throw FirebaseAuthException(code: 'username-taken', message: 'Username is already taken.');
      }

      // Create a new user
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = credential.user;

      // Save the username under USERNAMES/userid
      final userId = _user!.uid;
      await _usernamesRef.child(userId).set({
        'username': username,
      });

      await _usersDetailsRef.child(username).update({
        'id':userId,
        'username': username,
        'email':_user!.email,
        'type':'email'
      });

      // Save session
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('user_email', _user!.email!);
      prefs.setString('user_name', username);

      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleAuth =
      await googleUser!.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final authResult =
      await FirebaseAuth.instance.signInWithCredential(credential);

      _user = authResult.user;

      // Save session
      final prefs = await SharedPreferences.getInstance();

      // Check if the user already has a username in the database
      final userSnapshot = await _usernamesRef.child(_user!.uid).get();

      if (!userSnapshot.exists) {
        // If the username does not exist, create a default one
        String defaultUsername = await _generateDefaultUsername();
        await _usernamesRef.child(_user!.uid).set({'username': defaultUsername});
        await _usersDetailsRef.child(defaultUsername).update({
          'id':_user!.uid,
          'username': defaultUsername,
          'email':_user!.email,
          'type':'google'
        });
        // Save default username in session
        prefs.setString('user_name', defaultUsername);
      } else {
        // Save the existing username in session
        final value = userSnapshot.value as Map?;
        final String username = value?['username'];
        prefs.setString('user_name', username);

        await _usersDetailsRef.child(username).update({
          'id':_user!.uid,
          'username': username,
          'email':_user!.email,
          'type':'google'
        });

      }
      prefs.setString('user_email', _user!.email!);

      notifyListeners();
    } catch (e) {
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithApple() async {
    try {
      _isLoading = true;
      notifyListeners();

      final appleProvider = AppleAuthProvider();

      // Sign in with Firebase
      final authResult = await FirebaseAuth.instance.signInWithProvider(appleProvider);
      _user = authResult.user;

      // Save session
      final prefs = await SharedPreferences.getInstance();

      // Check if username exists in DB
      final userSnapshot = await _usernamesRef.child(_user!.uid).get();

      if (!userSnapshot.exists) {
        // Create default username
        String defaultUsername = await _generateDefaultUsername();
        await _usernamesRef.child(_user!.uid).set({'username': defaultUsername});
        await _usersDetailsRef.child(defaultUsername).update({
          'id': _user!.uid,
          'username': defaultUsername,
          'email': _user!.email,
          'type': 'apple'
        });
        prefs.setString('user_name', defaultUsername);
      } else {
        final value = userSnapshot.value as Map?;
        final String username = value?['username'];
        prefs.setString('user_name', username);

        await _usersDetailsRef.child(username).update({
          'id': _user!.uid,
          'username': username,
          'email': _user!.email,
          'type': 'apple'
        });
      }

      prefs.setString('user_email', _user!.email ?? "");

      notifyListeners();
    }catch (e) {
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<String> _generateDefaultUsername() async {
    final snapshot = await _usernamesRef.orderByChild('username').limitToLast(1).get();

    if (!snapshot.exists) {
      return 'user001';
    }

    final value = snapshot.children.last.value as Map?;
    final lastUsername = value?['username'] as String? ?? '';
    final lastNumber = int.tryParse(lastUsername.replaceFirst(RegExp(r'user'), '')) ?? 0;

    // Increment and generate the next username
    final newNumber = lastNumber + 1;
    return 'user${newNumber.toString().padLeft(3, '0')}';
  }

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
          return "Something went wrong. Please try again.";
      }
    }

    // fallback if it's not the expected exception type
    return "Unexpected error during Apple login: ${e.toString()}";
  }

  String getErrorMessage(Object e){
    String errorMessage;
    FirebaseAuthException authException = e as FirebaseAuthException;
    switch (authException.code) {
      case 'user-not-found':
        errorMessage = 'No user found for that email.';
        break;
      case 'wrong-password':
        errorMessage = 'Incorrect password.';
        break;
      case 'invalid-email':
        errorMessage = 'Invalid email address.';
        break;
      case 'user-disabled':
        errorMessage = 'This user account has been disabled.';
        break;
      case 'too-many-requests':
        errorMessage = 'Too many failed attempts. Try again later.';
        break;
      case 'username-taken':
        errorMessage = 'This username is already taken. Please choose another.';
        break;
      default:
        errorMessage = 'Unexpected error during Login : ${e.message}';
    }
    return errorMessage;
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();

    final prefs = await SharedPreferences.getInstance();
    prefs.remove('user_email');
    prefs.remove('user_name');

    _user = null;
    notifyListeners();
  }

  Future<bool> deleteAccount() async {

    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") ?? '';
    _usersDetailsRef.child(userId).remove();
    _usernamesRef.child(user!.uid).remove();

    final snapshot = await _foldersRef
        .orderByChild("userId")
        .equalTo(userId)
        .get();

    if (snapshot.exists) {
      for (var child in snapshot.children) {
        await child.ref.remove(); // delete each matched node
      }
      print("All folders for userId=$userId deleted");
    } else {
      print("No folders found for userId=$userId");
    }

    _goalsRef.child(userId).remove();
    _logRef.child(userId).remove();
    _historyGoalsRef.child(userId).remove();
    _historyLogsRef.child(userId).remove();
    _notesRef.child(userId).remove();

    final snapshot1 = await _plansRef
        .orderByChild("userId")
        .equalTo(userId)
        .get();

    if (snapshot1.exists) {
      for (var child in snapshot1.children) {
        await child.ref.remove(); // delete each matched node
      }
      print("All plans for userId=$userId deleted");
    } else {
      print("No plans found for userId=$userId");
    }

    final snapshot2 = await _favouritesRef
        .orderByChild("userId")
        .equalTo(userId)
        .get();

    if (snapshot2.exists) {
      for (var child in snapshot2.children) {
        await child.ref.remove(); // delete each matched node
      }
      print("All favourites for userId=$userId deleted");
    } else {
      print("No favourites found for userId=$userId");
    }

    if (user != null) {
      await user!.delete();
      logout();
      print("User account deleted successfully");
      return true;
    } else {
      print("No user is currently signed in");
      return false;
    }
  }

  String? validateUsernameInput(String username) {
    if (username.isEmpty) {
      return 'Username cannot be empty';
    }
    if (username.length < 6) {
      return 'Username must be 6 characters long';
    }
    final usernameRegExp = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegExp.hasMatch(username)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null; // Valid username
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

}
