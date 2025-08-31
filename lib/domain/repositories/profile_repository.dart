import '../entities/user.dart';

/// Contract for managing user profile data.
abstract class ProfileRepository {
  /// Fetch user details by current logged-in user.
  Future<User?> getUserDetails();

  /// Update user profile in Firebase.
  Future<void> updateUserProfile(User updatedUser);
}
