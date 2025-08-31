import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/plan.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/favourite.dart';
import '../../domain/repositories/plan_repository.dart';

class PlanRepositoryImpl implements PlanRepository {
  final DatabaseReference plansRef;
  final DatabaseReference favouritesRef;
  final FirebaseAuth auth;

  PlanRepositoryImpl({
    required this.plansRef,
    required this.favouritesRef,
    required this.auth,
  });

  Future<String?> _getUserId() async {
    final user = auth.currentUser;
    if (user == null) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("user_name");
  }

  @override
  Future<List<Plan>> fetchPlans(String userId) async {
    final snapshot = await plansRef.orderByChild("userId").equalTo(userId).get();
    if (!snapshot.exists || snapshot.value is! Map) return [];

    final Map data = snapshot.value as Map;
    return data.values.map((raw) => Plan.fromMap(Map<String, dynamic>.from(raw))).toList();
  }

  @override
  Future<void> addPlan(Plan plan) async {
    await plansRef.child(plan.id).set(plan.toMap());
  }

  @override
  Future<void> updatePlan(Plan plan) async {
    await plansRef.child(plan.id).update(plan.toMap());
  }

  @override
  Future<void> deletePlan(String planId) async {
    await plansRef.child(planId).remove();
  }

  @override
  Future<void> updatePlanStatus(String planId, String status) async {
    await plansRef.child(planId).update({"status": status});
  }

  @override
  Future<void> updatePlanNote(String planId, String note) async {
    await plansRef.child(planId).update({"note": note});
  }

  @override
  Future<void> likePlan(String planId, String userId) async {
    final snapshot = await plansRef.child(planId).get();
    if (!snapshot.exists) return;
    final plan = Plan.fromMap(Map<String, dynamic>.from(snapshot.value as Map));
    plan.likedBy.add(userId);
    await plansRef.child(planId).update({"likedBy": plan.likedBy});
  }

  @override
  Future<void> toggleFavourite(String planId, String userId) async {
    final favId = favouritesRef.push().key!;
    final favourite = Favourite(id: favId, userId: userId, planId: planId);
    await favouritesRef.child(favId).set(favourite.toMap());
  }

  @override
  Future<List<Plan>> fetchFavourites(String userId) async {
    final snapshot = await favouritesRef.orderByChild("userId").equalTo(userId).get();
    if (!snapshot.exists || snapshot.value is! Map) return [];
    final Map data = snapshot.value as Map;
    final List<Plan> plans = [];
    for (var raw in data.values) {
      final fav = Favourite.fromMap(Map<String, dynamic>.from(raw));
      final planSnap = await plansRef.child(fav.planId).get();
      if (planSnap.exists) {
        plans.add(Plan.fromMap(Map<String, dynamic>.from(planSnap.value as Map)));
      }
    }
    return plans;
  }

  @override
  Future<void> addComment(String planId, Comment comment) async {
    await plansRef.child("$planId/comments/${comment.id}").set(comment.toMap());
  }

  @override
  Future<void> deleteComment(String planId, String commentId) async {
    await plansRef.child("$planId/comments/$commentId").remove();
  }
}
