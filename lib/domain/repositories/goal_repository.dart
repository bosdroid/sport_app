import '../entities/goal.dart';

/// Contract for managing user goals.
/// Defines operations without depending on Firebase/SharedPreferences.
abstract class GoalRepository {
  Future<List<Goal>> fetchGoals();
  Future<void> addGoal({required String title, required String description});
  Future<void> updateGoal(Goal updatedGoal);
  Future<void> updateGoalData(Goal goal);
  Future<void> updateGoalAchieved(String goalId, bool achieved);
  Future<void> updateGoalStatus(String goalId, bool isActive);
  Future<void> updateGoalStatusWithAi(String title, String value);
  Future<void> deleteGoal(String goalId);
  Future<void> addGoalHistory(String goalId, String field, dynamic value);
}
