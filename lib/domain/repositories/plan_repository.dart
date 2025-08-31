import '../entities/plan.dart';
import '../entities/comment.dart';

abstract class PlanRepository {
  Future<List<Plan>> fetchPlans(String userId);
  Future<void> addPlan(Plan plan);
  Future<void> updatePlan(Plan plan);
  Future<void> deletePlan(String planId);
  Future<void> updatePlanStatus(String planId, String status);
  Future<void> updatePlanNote(String planId, String note);

  Future<void> likePlan(String planId, String userId);
  Future<void> toggleFavourite(String planId, String userId);
  Future<List<Plan>> fetchFavourites(String userId);

  Future<void> addComment(String planId, Comment comment);
  Future<void> deleteComment(String planId, String commentId);
}
