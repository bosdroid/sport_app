import '../entities/folder.dart';

abstract class FolderRepository {
  Future<List<Folder>> fetchFolders(String userId);
  Future<void> createFolder(Folder folder);
  Future<void> updateFolder(Folder folder);
  Future<void> deleteFolder(String folderId);
  Future<bool> checkFolderPermission(String folderId, String userId);
  Future<void> updateFolderAccess(String folderId, String access, {List<String>? allowedUsers});
  Future<List<Folder>> searchPublicFolders(String shareId, String userId);
}
