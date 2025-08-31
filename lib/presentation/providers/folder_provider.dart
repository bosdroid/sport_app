import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/folder.dart';
import '../../domain/repositories/folder_repository.dart';

class FolderProvider with ChangeNotifier {
  final FolderRepository folderRepository;

  FolderProvider(this.folderRepository);

  bool _isLoading = false;
  List<Folder> _folders = [];

  bool get isLoading => _isLoading;
  List<Folder> get folders => _folders;

  /// Fetch folders for current user
  Future<void> fetchFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString('user_name') ?? '';
    _isLoading = true;
    notifyListeners();
    _folders = await folderRepository.fetchFolders(userId);
    _isLoading = false;
    notifyListeners();
  }

  /// Create a new folder
  Future<void> createFolder(Folder folder) async {
    _isLoading = true;
    notifyListeners();
    await folderRepository.createFolder(folder);
    _folders.add(folder);
    _isLoading = false;
    notifyListeners();
  }

  /// Update folder info
  Future<void> updateFolder(Folder folder) async {
    await folderRepository.updateFolder(folder);
    final index = _folders.indexWhere((f) => f.id == folder.id);
    if (index != -1) {
      _folders[index] = folder;
      notifyListeners();
    }
  }

  /// Delete folder
  Future<void> deleteFolder(String folderId) async {
    await folderRepository.deleteFolder(folderId);
    _folders.removeWhere((f) => f.id == folderId);
    notifyListeners();
  }

  /// Check access/permission for a folder
  Future<bool> checkFolderPermission(String folderId, String userId) async {
    return await folderRepository.checkFolderPermission(folderId, userId);
  }

  /// Update access (public/private or allowed users)
  Future<void> updateFolderAccess(
      String folderId,
      String access, {
        List<String>? allowedUsers,
      }) async {
    await folderRepository.updateFolderAccess(
      folderId,
      access,
      allowedUsers: allowedUsers,
    );
    final index = _folders.indexWhere((f) => f.id == folderId);
    if (index != -1) {
      _folders[index].access = access;
      _folders[index].allowedUsers = allowedUsers ?? [];
      notifyListeners();
    }
  }

  /// Search public folders by shareId
  Future<List<Folder>> searchPublicFolders(String shareId, String userId) async {
    return await folderRepository.searchPublicFolders(shareId, userId);
  }
}
