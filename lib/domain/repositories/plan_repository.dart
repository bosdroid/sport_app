import '../entities/favourite.dart';
import '../entities/folder.dart';
import '../entities/plan.dart';
import '../entities/comment.dart';
import '../entities/video_entry.dart';

abstract class PlanRepository {
  Future<String?> getUserId();
  Future<void> updatePlanFolder(String planId, String folderId);
  Future<int> getPlanCountForFolder(String folderId);
  Future<bool> isShareIdUnique(String shareId);
  Future<void> createFolder(Folder folder);
  Future<void> updateFolderAccess(
      String folderId,
      String accessType, {
        List<String>? allowedUsers,
      });
  Future<void> addShareIdIfMissing(String folderId, String shareId);
  Future<List<Folder>> fetchFolders(String userId);
  Future<List<Folder>> fetchFoldersByShareId(String shareId);
  Future<Folder?> findByName(String userId, String name);
  Future<bool> isUnique(String shareId);
  Future<void> saveShareId(String shareId, String folderId);
  Future<void> deleteFolder(String folderId);
  Future<void> deleteShareId(String shareId);
  Future<void> clearFolderFromPlans(String userId, String folderId);
  Future<void> updateFolderName(String folderId, String newName);
  Future<void> updateFolderOrder(String folderId, int order);
  Future<void> updateLikedBy(String planId, List<String> likedBy);
  Future<void> updateFavouritedBy(String planId, List<String> favouritedBy);
  Future<void> addFavourite(Favourite favourite);
  Future<void> removeFavouriteByPlanId(String userId, String planId);
  Future<void> addComment(String planId, Comment comment);
  Future<void> deleteComment(String planId, String commentId);
  Future<List<Plan>> fetchPlansByUserId(String userId);
  Future<List<Plan>> fetchFavouritesByUserId(String userId);
  Future<void> updatePlanStatus(String planId, String status);
  Future<void> addPlan(Plan plan);
  Future<void> updatePlan(Plan plan);
  Future<void> updateNote(String planId, String note);
  Future<void> deletePlan(String planId);
  Future<void> updateConnections(String parentId, String childId);
  Future<void> linkPlans({
    required String parentId,
    required String childId,
    required String userId,
  });
  Future<void> removeLink({
    required String parentId,
    required String childId,
    required String userId,
  });

  Future<void> hideDefaultFolderOrCard({required int type});

  Future<void> migrateGuestDataToNewUser(String guestUid, String newUid);
}
