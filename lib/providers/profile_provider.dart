
import 'package:bjj_dairy/model/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileProvider with ChangeNotifier{
  final DatabaseReference _usersDetailsRef = FirebaseDatabase.instance.ref().child('USERS_DETAILS/');

  User? _loggedUser = null;
  User? get loggedUser => _loggedUser;

  /// Fetch user details from Firebase by userId
  Future<void> getUserDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String userId = prefs.getString("user_name") as String;
      final snapshot = await _usersDetailsRef.child(userId).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _loggedUser = User.fromMap(data);
        notifyListeners();
      }
      else{
        final currentUser = auth.FirebaseAuth.instance.currentUser;
        _loggedUser = User(
            id:'${currentUser?.uid}',
            username: userId,
            email: '${currentUser?.email}',
            type: 'email'
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error getting user details: $e');
    }
  }

  /// Update user profile in Firebase
  Future<void> updateUserProfile(User updatedUser) async {
    try {
      await _usersDetailsRef.child(updatedUser.username).update(updatedUser.toMap());
      _loggedUser = updatedUser;
      notifyListeners();
    } catch (e) {
      print('Error updating user profile: $e');
    }
  }

}