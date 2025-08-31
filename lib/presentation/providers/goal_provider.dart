import 'package:flutter/material.dart';
import '../../domain/entities/goal.dart';
import '../../domain/repositories/goal_repository.dart';

/// Provider that manages Goal state using GoalRepository
class GoalProvider with ChangeNotifier {
  final GoalRepository repository;

  GoalProvider(this.repository);

  List<Goal> _goals = [];
  bool _isLoading = false;
  bool _isChanged = false;

  List<Goal> get goals => _goals;
  bool get isLoading => _isLoading;
  bool get isChanged => _isChanged;

  List<Goal> get activeGoals => _goals.where((goal) => goal.isActive).toList();
  int get totalActiveGoals => activeGoals.length;
  bool get anyGoalChanges => _goals.any((g) => g.isActive && g.changes);

  Future<void> fetchGoals() async {
    _isLoading = true;
    notifyListeners();
    _goals = await repository.fetchGoals();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addGoal(String title, String description) async {
    _isLoading = true;
    notifyListeners();
    await repository.addGoal(title: title, description: description);
    _goals = await repository.fetchGoals();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateGoal(Goal updatedGoal) async {
    _isLoading = true;
    notifyListeners();
    await repository.updateGoal(updatedGoal);
    _goals = await repository.fetchGoals();
    _isLoading = false;
    _isChanged = false;
    notifyListeners();
  }

  Future<void> updateGoalData(Goal data) async {
    await repository.updateGoalData(data);
    final index = _goals.indexWhere((g) => g.id == data.id);
    if (index != -1) {
      _goals[index] = data;
      notifyListeners();
    }
  }

  Future<void> updateGoalAchieved(String goalId, bool achieved) async {
    await repository.updateGoalAchieved(goalId, achieved);
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index != -1) {
      _goals[index].achieved = achieved;
      _isChanged = false;
      notifyListeners();
    }
  }

  Future<void> updateGoalStatus(String goalId, bool isActive) async {
    await repository.updateGoalStatus(goalId, isActive);
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index != -1) {
      _goals[index].isActive = isActive;
      _isChanged = false;
      notifyListeners();
    }
  }

  Future<void> updateGoalStatusWithAi(String title, String value) async {
    await repository.updateGoalStatusWithAi(title, value);
    _goals = await repository.fetchGoals();
    _isChanged = false;
    notifyListeners();
  }

  Future<void> deleteGoal(String goalId) async {
    _isLoading = true;
    notifyListeners();
    await repository.deleteGoal(goalId);
    _goals.removeWhere((g) => g.id == goalId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addGoalHistory(String goalId, String field, dynamic value) async {
    await repository.addGoalHistory(goalId, field, value);
    _isChanged = false;
    notifyListeners();
  }

  Future<void> updateAllGoalChanges() async {
    _isLoading = true;
    notifyListeners();
    for (var goal in _goals.where((g) => g.isActive && g.changes)) {
      await repository.addGoalHistory(goal.id, 'value', goal.achieved);
    }
    resetChanges();
    _isLoading = false;
    notifyListeners();
  }

  void updateChangeState(bool state) {
    _isChanged = state;
    notifyListeners();
  }

  void resetChanges() {
    for (var goal in _goals) {
      goal.changes = false;
    }
    notifyListeners();
  }
}
