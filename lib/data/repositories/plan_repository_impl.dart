import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/folder.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/favourite.dart';
import '../../domain/repositories/plan_repository.dart';
import '../services/image_service.dart';

class PlanRepositoryImpl implements PlanRepository {
  final DatabaseReference _plansRef =
  FirebaseDatabase.instance.ref().child('PLANS/');
  final DatabaseReference _shareIdsRef =
  FirebaseDatabase.instance.ref().child('SHARE_IDS/');
  final DatabaseReference _foldersRef =
  FirebaseDatabase.instance.ref().child('FOLDERS/');
  final DatabaseReference _favouritesRef =
  FirebaseDatabase.instance.ref().child('FAVOURITES/');
  // final DatabaseReference foldersRef;
  // final DatabaseReference shareIdsRef;
  // final DatabaseReference favouritesRef;
  final FirebaseAuth auth;
  // final ImageService _imageService = ImageService();

  PlanRepositoryImpl({
    required this.auth,
  });

  @override
  Future<String?> getUserId() async {
    final user = auth.currentUser;
    if (user == null) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("user_name");
  }

  @override
  Future<void> updatePlanFolder(String planId, String folderId) async {
    await _plansRef.child(planId).update({'folderId': folderId});
  }

  @override
  Future<int> getPlanCountForFolder(String folderId) async {
    try {
      final snapshot =
      await _plansRef.orderByChild('folderId').equalTo(folderId).get();

      if (snapshot.exists && snapshot.value is Map) {
        final Map data = snapshot.value as Map;
        return data.length;
      }
      return 0;
    } catch (e) {
      print('Error fetching plans for folder $folderId: $e');
      return 0;
    }
  }

  @override
  Future<bool> isShareIdUnique(String shareId) async {
    final snapshot = await _shareIdsRef.child(shareId).get();
    return snapshot.value == null;
  }

  @override
  Future<void> createFolder(Folder folder) async {
    // Save folder data
    await _foldersRef.child(folder.id!).set(folder.toMap());

    // Also save shareId reference
    await _shareIdsRef.child(folder.shareId!).set(folder.id);
  }

  @override
  Future<void> updateFolderAccess(
      String folderId,
      String accessType, {
        List<String>? allowedUsers,
      }) async {
    final updateData = {
      'access': accessType,
      'allowedUsers': accessType == 'specific' ? (allowedUsers ?? []) : [],
    };

    await _foldersRef.child(folderId).update(updateData);
  }

  @override
  Future<void> addShareIdIfMissing(String folderId, String shareId) async {
    final DatabaseReference folderRef = _foldersRef.child(folderId);

    // Double-check on the server
    final DataSnapshot current = await folderRef.child('shareId').get();
    if (current.exists && (current.value as String).isNotEmpty) return;

    // Atomically write into both places
    await folderRef.update({'shareId': shareId});
    await _shareIdsRef.child(shareId).set(folderId);
  }

  @override
  Future<List<Folder>> fetchFolders(String userId) async {
    final snapshot =
    await _foldersRef.orderByChild('userId').equalTo(userId).get();

    if (!snapshot.exists) return [];

    final Map<dynamic, dynamic> data =
    Map<dynamic, dynamic>.from(snapshot.value as Map);

    return data.entries
        .map((e) => Folder.fromMap(Map<String, dynamic>.from(e.value)))
        .where((f) => (f.userId == userId || f.allowedUsers.contains(userId)))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  @override
  Future<List<Folder>> fetchFoldersByShareId(String shareId) async {
    final snapshot =
    await _foldersRef.orderByChild('shareId').equalTo(shareId).get();

    if (!snapshot.exists) return [];

    final Map<dynamic, dynamic> data =
    Map<dynamic, dynamic>.from(snapshot.value as Map);

    return data.entries
        .map((e) => Folder.fromMap(Map<String, dynamic>.from(e.value)))
        .toList();
  }

  @override
  Future<Folder?> findByName(String userId, String name) async {
    final snapshot =
    await _foldersRef.orderByChild('userId').equalTo(userId).get();

    if (!snapshot.exists) return null;

    final Map<dynamic, dynamic> data =
    Map<dynamic, dynamic>.from(snapshot.value as Map);

    try {
      return data.entries
          .map((e) => Folder.fromMap(Map<String, dynamic>.from(e.value)))
          .firstWhere(
            (f) => f.name!.toLowerCase() == name.toLowerCase(),
        orElse: () => null as Folder,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> isUnique(String shareId) async {
    final snapshot = await _shareIdsRef.child(shareId).get();
    return snapshot.value == null;
  }

  @override
  Future<void> saveShareId(String shareId, String folderId) async {
    await _shareIdsRef.child(shareId).set(folderId);
  }

  @override
  Future<void> deleteFolder(String folderId) async {
    await _foldersRef.child(folderId).remove();
  }

  @override
  Future<void> deleteShareId(String shareId) async {
    await _shareIdsRef.child(shareId).remove();
  }

  @override
  Future<void> clearFolderFromPlans(String userId, String folderId) async {
    final snapshot =
    await _plansRef.orderByChild('folderId').equalTo(folderId).get();

    if (!snapshot.exists) return;

    if (snapshot.value is Map<Object?, Object?>) {
      final Map<Object?, Object?> data =
      snapshot.value as Map<Object?, Object?>;

      for (final entry in data.entries) {
        final planId = entry.key.toString();
        await _plansRef.child(planId).update({'folderId': ''});
      }
    }
  }

  @override
  Future<void> updateFolderName(String folderId, String newName) async {
    await _foldersRef.child(folderId).update({'name': newName});
  }

  @override
  Future<void> updateFolderOrder(String folderId, int order) async {
    await _foldersRef.child(folderId).update({'order': order});
  }

  @override
  Future<void> updateLikedBy(String planId, List<String> likedBy) async {
    await _plansRef.child(planId).update({'likedBy': likedBy});
  }

  @override
  Future<void> updateFavouritedBy(String planId, List<String> favouritedBy) async {
    await _plansRef.child(planId).update({'favouritedBy': favouritedBy});
  }

  @override
  Future<void> addFavourite(Favourite favourite) async {
    await _favouritesRef.child(favourite.id).set(favourite.toMap());
  }

  @override
  Future<void> removeFavouriteByPlanId(String userId, String planId) async {
    final snapshot = await _favouritesRef.orderByChild("userId").equalTo(userId).get();

    if (snapshot.exists && snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      for (final entry in data.entries) {
        if (entry.value['planId'] == planId) {
          await _favouritesRef.child(entry.key).remove();
        }
      }
    }
  }

  @override
  Future<void> addComment(String planId, Comment comment) async {
    final commentRef = _plansRef.child('$planId/comments').child(comment.id);
    await commentRef.set(comment.toMap());
  }

  @override
  Future<void> deleteComment(String planId, String commentId) async {
    await _plansRef.child('$planId/comments/$commentId').remove();
  }

  @override
  Future<List<Plan>> fetchPlansByUserId(String userId) async {
    try {
      final snapshot = await _plansRef.orderByChild('userId').equalTo(userId).get();

      if (!snapshot.exists || snapshot.value == null) return [];

      final rawData = snapshot.value;
      if (rawData is! Map) return [];

      final List<Plan> fetchedPlans = [];

      for (final entry in (rawData).entries) {
        final value = entry.value;
        if (value is Map<Object?, Object?>) {
          final data = value.map((k, v) => MapEntry(k.toString(), v));
          final plan = Plan.fromMap(data);

          if (plan.userId == userId) {
            fetchedPlans.add(plan);
          }
        }
      }

      return fetchedPlans..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Plan>> fetchFavouritesByUserId(String userId) async {
    try {
      final snapshot = await _favouritesRef.orderByChild('userId').equalTo(userId).get();
      if (!snapshot.exists || snapshot.value == null) return [];

      if (snapshot.value is! Map) return [];

      final List<Plan> fetchedPlans = [];

      for (final entry in (snapshot.value as Map).entries) {
        final value = entry.value;
        if (value is Map<Object?, Object?>) {
          final data = value.map((k, v) => MapEntry(k.toString(), v));
          final favourite = Favourite.fromMap(Map<String, dynamic>.from(data));
          final planId = favourite.planId;

          if (planId.isEmpty) continue;

          final planSnapshot = await _plansRef.child(planId).get();
          if (planSnapshot.exists && planSnapshot.value != null) {
            final planData = Map<String, dynamic>.from(planSnapshot.value as Map);
            final plan = Plan.fromMap(planData)..isShared = true;
            fetchedPlans.add(plan);
          }
        }
      }

      return fetchedPlans..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updatePlanStatus(String planId, String status) async {
    try {
      await _plansRef.child(planId).update({'status': status});
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> addPlan(Plan plan) async {
    try {
      await _plansRef.child(plan.id).set(plan.toMap());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updatePlan(Plan plan) async {
    try {
      await _plansRef.child(plan.id).update(plan.toMap());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateNote(String planId, String note) async {
    try {
      await _plansRef.child(planId).update({'note': note});
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deletePlan(String planId) async {
    try {
      await _plansRef.child(planId).remove();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateConnections(String parentId, String childId) async {
    await _plansRef.child('$parentId/to').update({childId: true});
    await _plansRef.child('$childId/from').update({parentId: true});
  }

  @override
  Future<void> linkPlans({
    required String parentId,
    required String childId,
    required String userId,
  }) async {
    final DatabaseReference parentRef = _plansRef.child(parentId);
    final DatabaseReference childRef = _plansRef.child(childId);

    // 🔥 Keep same push/set functionality
    await parentRef.child("to").push().set(childId);
    await childRef.child("from").push().set(parentId);
  }

  @override
  Future<void> removeLink({
    required String parentId,
    required String childId,
    required String userId,
  }) async {
    await _plansRef.child('$parentId/to/$childId').remove();
    await _plansRef.child('$childId/from/$parentId').remove();
  }

}
