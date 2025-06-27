import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final DatabaseReference _usernamesRef = FirebaseDatabase.instance.ref().child('USERNAMES/');
  final DatabaseReference _usersDetailsRef = FirebaseDatabase.instance.ref().child('USERS_DETAILS/');

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

      await _usersDetailsRef.child(username).set({
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
        await _usersDetailsRef.child(defaultUsername).set({
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

  String? getErrorMessage(Object e){
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
        errorMessage = 'Login failed: ${e.message}';
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
}
