import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/goal.dart';
import '../../domain/repositories/goal_repository.dart';

/// Concrete implementation of GoalRepository using Firebase + SharedPreferences.
class GoalRepositoryImpl implements GoalRepository {
  final DatabaseReference goalsRef;
  final DatabaseReference historyRef;
  final FirebaseAuth auth;

  GoalRepositoryImpl({
    required this.goalsRef,
    required this.historyRef,
    required this.auth,
  });

  Future<String?> _getUserId() async {
    final user = auth.currentUser;
    if (user == null) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("user_name");
  }

  @override
  Future<List<Goal>> fetchGoals() async {
    final userId = await _getUserId();
    if (userId == null) return [];

    final snapshot = await goalsRef.child(userId).get();
    if (!snapshot.exists || snapshot.value is! Map) return [];

    final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    return data.entries.map((entry) {
      final key = entry.key as String;
      final value = Map<String, dynamic>.from(entry.value as Map);
      return Goal.fromMap(value, key);
    }).toList();
  }

  @override
  Future<void> addGoal({required String title, required String description}) async {
    final userId = await _getUserId();
    if (userId == null) return;

    final String goalId = goalsRef.child(userId).push().key!;
    final Goal newGoal = Goal(
      id: goalId,
      title: title,
      description: description,
      isActive: true,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await goalsRef.child("$userId/$goalId").set(newGoal.toMap());
  }

  @override
  Future<void> updateGoal(Goal updatedGoal) async {
    final userId = await _getUserId();
    if (userId == null) return;

    await goalsRef.child('$userId/${updatedGoal.id}').update({
      'title': updatedGoal.title,
      'description': updatedGoal.description,
    });
  }

  @override
  Future<void> updateGoalData(Goal goal) async {
    final userId = await _getUserId();
    if (userId == null) return;

    await goalsRef.child('$userId/${goal.id}').update({'achieved': goal.achieved});
  }

  @override
  Future<void> updateGoalAchieved(String goalId, bool achieved) async {
    final userId = await _getUserId();
    if (userId == null) return;

    await goalsRef.child('$userId/$goalId').update({'achieved': achieved});
  }

  @override
  Future<void> updateGoalStatus(String goalId, bool isActive) async {
    final userId = await _getUserId();
    if (userId == null) return;

    await goalsRef.child('$userId/$goalId').update({'isActive': isActive});
  }

  @override
  Future<void> updateGoalStatusWithAi(String title, String value) async {
    final userId = await _getUserId();
    if (userId == null) return;

    final snapshot = await goalsRef.child(userId).get();
    if (!snapshot.exists || snapshot.value is! Map) return;

    final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    final activeGoals = data.entries.map((entry) {
      final key = entry.key as String;
      final valueMap = Map<String, dynamic>.from(entry.value as Map);
      return Goal.fromMap(valueMap, key);
    }).where((goal) => goal.isActive).toList();

    final goalIndex = activeGoals.indexWhere((goal) => goal.title == title);
    if (goalIndex != -1) {
      final achieved = value.toLowerCase() != "no";
      final goal = activeGoals[goalIndex];
      await addGoalHistory(goal.id, 'value', achieved);
      await goalsRef.child('$userId/${goal.id}').update({'achieved': achieved});
    }
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    final userId = await _getUserId();
    if (userId == null) return;

    await goalsRef.child("$userId/$goalId").remove();
  }

  @override
  Future<void> addGoalHistory(String goalId, String field, dynamic value) async {
    final userId = await _getUserId();
    if (userId == null) return;

    final history = historyRef.child('$userId/$goalId');
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';

    final snapshot = await history.child(todayKey).get();
    if (snapshot.exists) {
      await history.child(todayKey).update({
        field: value,
        'updatedAt': now.millisecondsSinceEpoch,
      });
    } else {
      await history.child(todayKey).set({
        field: value,
        'updatedAt': now.millisecondsSinceEpoch,
      });
    }
  }
}
