import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/goal.dart';

class GoalProvider with ChangeNotifier {
  final DatabaseReference _goalsRef = FirebaseDatabase.instance.ref().child('USERS/GOALS/');
  final DatabaseReference _historyRef = FirebaseDatabase.instance.ref().child('GOALS_HISTORY/');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Goal> _goals = [];
  bool _isLoading = false;
  bool _isChanged = false;

  List<Goal> get goals => _goals;
  bool get isLoading => _isLoading;
  bool get isChanged => _isChanged;

  List<Goal> get activeGoals {
    return _goals.where((goal) => goal.isActive).toList();
  }

  int get totalActiveGoals {
    int counter = 0;

    for (var goal in _goals) {
      if (goal.isActive) {
        counter++;
      }
    }
    return counter;
  }

  bool get anyGoalChanges {
    return _goals.any((goal) => goal.isActive && goal.changes);
  }

  Future<void> updateAllGoalChanges() async {
      _isLoading = true;
      notifyListeners();

      List<Goal> changesGoalItems = _goals.where((goal) => goal.isActive && goal.changes).toList();

      for (var goal in changesGoalItems) {
        addGoalHistory(goal.id, 'value', goal.achieved);
      }
      resetChanges();

      _isLoading = false;
      notifyListeners();
  }

  Future<void> updateGoalData(Goal data) async {
    final user = _auth.currentUser;
    if (user == null) return;
    //final String userId = user.uid;
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") as String;

    final goalIndex = _goals.indexWhere((goal) => goal.id == data.id);
    if (goalIndex != -1) {
      _goals[goalIndex].achieved = data.achieved;
      _goals[goalIndex].changes = data.changes;
      // Update in database or backend
     await _goalsRef.child('$userId/${_goals[goalIndex].id}').update({'achieved': _goals[goalIndex].achieved});
      notifyListeners();
    }
  }

  void updateChangeState(bool state) {
    _isChanged = state;
    notifyListeners();
  }

  // Helper to reset _isChanged
  void resetChanges() {
    for (var goal in _goals) {
      goal.changes = false;
    }
    notifyListeners();
  }

  Future<void> updateGoalAchieved(String goalId, bool achieved) async {
    final user = _auth.currentUser;
    if (user == null) return;
    //final String userId = user.uid;
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") as String;

    final goalIndex = _goals.indexWhere((goal) => goal.id == goalId);
    if (goalIndex != -1) {
      _goals[goalIndex].achieved = achieved;
      _isChanged = false; // Mark changes as made
      notifyListeners();

      // Update in database or backend
      _goalsRef.child('$userId/$goalId').update({'achieved': achieved});
    }
  }

  // 🔵 Fetch Goals from Firebase
  Future<void> fetchGoals() async {
    final user = _auth.currentUser;
    if (user == null) return;

    //final String userId = user.uid;
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") as String;
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _goalsRef.child(userId).get();

      if (snapshot.exists && snapshot.value is Map) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

        // Convert data to a list of goals
        _goals = data.entries.map((entry) {
          final key = entry.key as String; // Firebase ID
          final value = Map<String, dynamic>.from(entry.value as Map); // Goal data
          return Goal.fromMap(value, key); // Correct parameter order
        }).toList();
      } else {
        _goals = [];
      }
    } catch (e) {
      print("Error fetching goals: $e");
      _goals = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // 🔵 Add Goal to Firebase
  Future<void> addGoal({required String title, required String description}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    _isLoading = true;
    notifyListeners();
    //final String userId = user.uid;
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") as String;
    final String goalId = _goalsRef.child(userId).push().key!;

    Goal newGoal = Goal(
      id: goalId,
      title: title,
      description: description,
      isActive: true,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await _goalsRef.child("$userId/$goalId").set(newGoal.toMap());
    _goals.add(newGoal);
    _isLoading = false;
    notifyListeners();
  }

  // 🔵 update Goal to Firebase
  Future<void> updateGoal(Goal updatedGoal) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    //final String userId = user.uid;
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") as String;
    try {
      await _goalsRef.child('$userId/${updatedGoal.id}').update({
        'title': updatedGoal.title,
        'description': updatedGoal.description,
      });
      // Update the goal locally
      final index = _goals.indexWhere((goal) => goal.id == updatedGoal.id);
      if (index != -1) {
        _goals[index] = updatedGoal;
        _isChanged = false;
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating goal: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateGoalStatus(String goalId, bool isActive) async {
    final user = _auth.currentUser;
    if (user == null) return;
    //final String userId = user.uid;
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") as String;
    final goalIndex = _goals.indexWhere((goal) => goal.id == goalId);
    if (goalIndex != -1) {
      _goals[goalIndex].isActive = isActive;
      _isChanged = false;
      notifyListeners();

      // Update in database or backend
      _goalsRef.child('$userId/$goalId').update({'isActive': isActive});
    }
  }

  Future<void> updateGoalStatusWithAi(String title, String value) async {
    final user = _auth.currentUser;
    if (user == null) return;
    //final String userId = user.uid;
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") as String;
    final goalIndex = activeGoals.indexWhere((goal) => goal.title == title);
    var achieved = value.toLowerCase() == "no"? false:true;
    if (goalIndex != -1) {
      _goals[goalIndex].achieved = achieved;
      _isChanged = false;
      notifyListeners();

      addGoalHistory(_goals[goalIndex].id, 'value', achieved);
      _goalsRef.child('$userId/${_goals[goalIndex].id}').update({'achieved': achieved});
    }
  }

  // 🔴 Delete Goal
  Future<void> deleteGoal(String goalId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    _isLoading = true;
    notifyListeners();
    //final String userId = user.uid;
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") as String;
    await _goalsRef.child("$userId/$goalId").remove();

    _goals.removeWhere((goal) => goal.id == goalId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addGoalHistory(String goalId, String field, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") as String;

    final historyRef = _historyRef.child('$userId/$goalId');
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}'; // Use date as a unique key

    final snapshot = await historyRef.child(todayKey).get();

    if (snapshot.exists) {
      // If history for today exists, update the field
      await historyRef.child(todayKey).update({
        field: value,
        'updatedAt': now.millisecondsSinceEpoch,
      });
    } else {
      // If no history for today, create a new entry
      await historyRef.child(todayKey).set({
        field: value,
        'updatedAt': now.millisecondsSinceEpoch,
      });
    }
    _isChanged = false;
    notifyListeners();
  }

}
