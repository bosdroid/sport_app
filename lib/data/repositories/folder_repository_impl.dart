import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/folder.dart';
import '../../domain/repositories/folder_repository.dart';

/// Concrete implementation of FolderRepository using Firebase Realtime Database.
class FolderRepositoryImpl implements FolderRepository {
  final DatabaseReference foldersRef;
  final FirebaseAuth auth;

  FolderRepositoryImpl({
    required this.foldersRef,
    required this.auth,
  });

  /// Get userId from SharedPreferences (you are saving "user_name" as ID)
  Future<String?> _getUserId() async {
    final user = auth.currentUser;
    if (user == null) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("user_name");
  }

  @override
  Future<List<Folder>> fetchFolders(String userId) async {
    final snapshot = await foldersRef.child(userId).get();
    if (!snapshot.exists || snapshot.value is! Map) return [];

    final Map data = snapshot.value as Map;
    return data.entries.map((entry) {
      final key = entry.key as String;
      final value = Map<String, dynamic>.from(entry.value as Map);
      return Folder.fromMap(value);
    }).toList();
  }

  @override
  Future<void> createFolder(Folder folder) async {
    final userId = await _getUserId();
    if (userId == null) return;

    await foldersRef.child("$userId/${folder.id}").set(folder.toMap());
  }

  @override
  Future<void> updateFolder(Folder folder) async {
    final userId = await _getUserId();
    if (userId == null) return;

    await foldersRef.child("$userId/${folder.id}").update(folder.toMap());
  }

  @override
  Future<void> deleteFolder(String folderId) async {
    final userId = await _getUserId();
    if (userId == null) return;

    await foldersRef.child("$userId/$folderId").remove();
  }

  @override
  Future<bool> checkFolderPermission(String folderId, String userId) async {
    final snapshot = await foldersRef.child("$userId/$folderId/access").get();
    if (!snapshot.exists) return false;

    final access = snapshot.value as String;
    return access == "public" || access == "private";
  }

  @override
  Future<void> updateFolderAccess(
      String folderId,
      String access, {
        List<String>? allowedUsers,
      }) async {
    final userId = await _getUserId();
    if (userId == null) return;

    final updates = {
      "access": access,
      if (allowedUsers != null) "allowedUsers": allowedUsers,
    };

    await foldersRef.child("$userId/$folderId").update(updates);
  }

  @override
  Future<List<Folder>> searchPublicFolders(String shareId, String userId) async {
    final snapshot = await foldersRef.child(shareId).get();
    if (!snapshot.exists || snapshot.value is! Map) return [];

    final Map data = snapshot.value as Map;
    return data.entries.map((entry) {
      final key = entry.key as String;
      final value = Map<String, dynamic>.from(entry.value as Map);
      final folder = Folder.fromMap(value);

      // Only return if folder is public or user is in allowedUsers
      if (folder.access == "public" ||
          (folder.allowedUsers?.contains(userId) ?? false)) {
        return folder;
      }
      return null;
    }).whereType<Folder>().toList();
  }
}
