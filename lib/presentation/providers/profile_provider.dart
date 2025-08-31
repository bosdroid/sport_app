import 'package:flutter/foundation.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileProvider with ChangeNotifier {
  final ProfileRepository repository;

  ProfileProvider(this.repository);

  User? _loggedUser;
  User? get loggedUser => _loggedUser;

  /// Fetch user details (from repository).
  Future<void> getUserDetails() async {
    _loggedUser = await repository.getUserDetails();
    notifyListeners();
  }

  /// Update user profile (through repository).
  Future<void> updateUserProfile(User updatedUser) async {
    await repository.updateUserProfile(updatedUser);
    _loggedUser = updatedUser;
    notifyListeners();
  }
}
