import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/user.dart';
import '../../domain/repositories/profile_repository.dart';

/// Implementation of ProfileRepository using Firebase + SharedPreferences.
class ProfileRepositoryImpl implements ProfileRepository {
  final DatabaseReference usersDetailsRef;
  final auth.FirebaseAuth firebaseAuth;

  ProfileRepositoryImpl({
    required this.usersDetailsRef,
    required this.firebaseAuth,
  });

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("user_name");
  }

  @override
  Future<User?> getUserDetails() async {
    try {
      final userId = await _getUserId();
      if (userId == null) return null;

      final snapshot = await usersDetailsRef.child(userId).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return User.fromMap(data);
      } else {
        final currentUser = firebaseAuth.currentUser;
        return User(
          id: currentUser?.uid ?? '',
          username: userId,
          email: currentUser?.email ?? '',
          type: 'email',
        );
      }
    } catch (e) {
      print('Error getting user details: $e');
      return null;
    }
  }

  @override
  Future<void> updateUserProfile(User updatedUser) async {
    try {
      await usersDetailsRef.child(updatedUser.username).update(updatedUser.toMap());
    } catch (e) {
      print('Error updating user profile: $e');
    }
  }
}
