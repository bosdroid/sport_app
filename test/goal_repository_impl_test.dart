import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bjj_dairy/data/repositories/goal_repository_impl.dart';
import 'package:bjj_dairy/domain/entities/goal.dart';

// ---------- Mocks ----------
class MockUser extends Mock implements User {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockDatabaseReference extends Mock implements DatabaseReference {}
class MockDataSnapshot extends Mock implements DataSnapshot {}

void main() {
  late GoalRepositoryImpl repo;
  late MockFirebaseAuth auth;
  late MockDatabaseReference goalsRef;
  late MockDatabaseReference historyRef;
  late MockUser user;

  setUp(() {
    SharedPreferences.setMockInitialValues({'user_name': 'u1'});
    auth = MockFirebaseAuth();
    goalsRef = MockDatabaseReference();
    historyRef = MockDatabaseReference();
    user = MockUser();

    when(() => auth.currentUser).thenReturn(user);

    repo = GoalRepositoryImpl(
      goalsRef: goalsRef,
      historyRef: historyRef,
      auth: auth,
    );
  });

  test('fetchGoals returns empty list if no snapshot', () async {
    final snap = MockDataSnapshot();
    when(() => goalsRef.child(any())).thenReturn(goalsRef);
    when(() => goalsRef.get()).thenAnswer((_) async => snap);
    when(() => snap.exists).thenReturn(false);

    final result = await repo.fetchGoals();
    expect(result, isEmpty);
  });

  test('addGoal writes goal to firebase', () async {
    when(() => goalsRef.child(any())).thenReturn(goalsRef);
    when(() => goalsRef.push()).thenReturn(goalsRef);
    when(() => goalsRef.key).thenReturn('g1');
    when(() => goalsRef.set(any())).thenAnswer((_) async {});

    await repo.addGoal(title: 'T', description: 'D');
    verify(() => goalsRef.set(any())).called(1);
  });

  test('updateGoal updates firebase fields', () async {
    when(() => goalsRef.child(any())).thenReturn(goalsRef);
    when(() => goalsRef.update(any())).thenAnswer((_) async {});

    final g = Goal(
      id: 'g1',
      title: 't',
      description: 'd',
      timestamp: 1,
    );
    await repo.updateGoal(g);
    verify(() => goalsRef.update(any())).called(1);
  });

  test('deleteGoal removes from firebase', () async {
    when(() => goalsRef.child(any())).thenReturn(goalsRef);
    when(() => goalsRef.remove()).thenAnswer((_) async {});
    await repo.deleteGoal('g1');
    verify(() => goalsRef.remove()).called(1);
  });

  test('addGoalHistory sets or updates history', () async {
    final snap = MockDataSnapshot();
    when(() => historyRef.child(any())).thenReturn(historyRef);
    when(() => historyRef.child(any())).thenReturn(historyRef);
    when(() => historyRef.get()).thenAnswer((_) async => snap);
    when(() => snap.exists).thenReturn(false);
    when(() => historyRef.set(any())).thenAnswer((_) async {});

    await repo.addGoalHistory('g1', 'value', true);
    verify(() => historyRef.set(any())).called(1);
  });
}
