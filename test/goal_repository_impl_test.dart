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

  MockDataSnapshot buildSnapshot({bool exists = false, dynamic value}) {
    final snap = MockDataSnapshot();
    when(() => snap.exists).thenReturn(exists);
    when(() => snap.value).thenReturn(value);
    return snap;
  }


  // ---------- PRIVATE: _getUserId ----------
  test('_getUserId returns null if user not logged in', () async {
    when(() => auth.currentUser).thenReturn(null);
    final r = await repo.fetchGoals();
    expect(r, isEmpty);
  });

  test('_getUserId returns null if user_name missing in SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({});
    when(() => auth.currentUser).thenReturn(user);
    final r = await repo.fetchGoals();
    expect(r, isEmpty);
  });

  // ---------- fetchGoals ----------
  test('fetchGoals returns empty if snapshot missing or malformed', () async {
    final snap = MockDataSnapshot();
    when(() => goalsRef.child(any())).thenReturn(goalsRef);
    when(() => goalsRef.get()).thenAnswer((_) async => snap);

    when(() => snap.exists).thenReturn(true);
    when(() => snap.value).thenReturn('not-a-map');
    final result = await repo.fetchGoals();
    expect(result, isEmpty);
  });

  test('fetchGoals parses valid goals', () async {
    final snap = MockDataSnapshot();
    when(() => goalsRef.child(any())).thenReturn(goalsRef);
    when(() => goalsRef.get()).thenAnswer((_) async => snap);
    when(() => snap.exists).thenReturn(true);
    when(() => snap.value).thenReturn({
      'g1': {
        'title': 'Goal1',
        'description': 'desc',
        'isActive': true,
        'achieved': false,
        'timestamp': 123,
      }
    });

    final result = await repo.fetchGoals();
    expect(result.length, 1);
    expect(result.first.title, 'Goal1');
  });

  // ---------- addGoal ----------
  test('addGoal writes goal to firebase', () async {
    when(() => goalsRef.child(any())).thenReturn(goalsRef);
    when(() => goalsRef.push()).thenReturn(goalsRef);
    when(() => goalsRef.key).thenReturn('g1');
    when(() => goalsRef.set(any())).thenAnswer((_) async {});

    await repo.addGoal(title: 'T', description: 'D');
    verify(() => goalsRef.set(any())).called(1);
  });

  test('addGoal returns early when no user', () async {
    when(() => auth.currentUser).thenReturn(null);
    await repo.addGoal(title: 'T', description: 'D');
    verifyNever(() => goalsRef.set(any()));
  });

  // ---------- updateGoal ----------
  test('updateGoal updates firebase fields', () async {
    when(() => goalsRef.child(any())).thenReturn(goalsRef);
    when(() => goalsRef.update(any())).thenAnswer((_) async {});
    final g = Goal(id: 'g1', title: 't', description: 'd', timestamp: 1);
    await repo.updateGoal(g);
    verify(() => goalsRef.update(any())).called(1);
  });

  test('updateGoal returns early if no user', () async {
    when(() => auth.currentUser).thenReturn(null);
    final g = Goal(id: 'g1', title: 't', description: 'd', timestamp: 1);
    await repo.updateGoal(g);
    verifyNever(() => goalsRef.update(any()));
  });

  // ---------- updateGoalData ----------
  test('updateGoalData updates achieved field', () async {
    when(() => goalsRef.child(any())).thenReturn(goalsRef);
    when(() => goalsRef.update(any())).thenAnswer((_) async {});
    final g = Goal(
      id: 'g1',
      title: 't',
      description: 'd',
      timestamp: 1,
      achieved: true,
    );
    await repo.updateGoalData(g);
    verify(() => goalsRef.update({'achieved': true})).called(1);
  });

  test('updateGoalData early return if no user', () async {
    when(() => auth.currentUser).thenReturn(null);
    final g = Goal(id: 'g1', title: 't', description: 'd', timestamp: 1);
    await repo.updateGoalData(g);
    verifyNever(() => goalsRef.update(any()));
  });

  // ---------- updateGoalAchieved ----------
  test('updateGoalAchieved writes achieved value', () async {
    when(() => goalsRef.child(any())).thenReturn(goalsRef);
    when(() => goalsRef.update(any())).thenAnswer((_) async {});
    await repo.updateGoalAchieved('g1', true);
    verify(() => goalsRef.update({'achieved': true})).called(1);
  });

  test('updateGoalAchieved early return if no user', () async {
    when(() => auth.currentUser).thenReturn(null);
    await repo.updateGoalAchieved('g1', true);
    verifyNever(() => goalsRef.update(any()));
  });

  // ---------- updateGoalStatus ----------
  test('updateGoalStatus writes isActive value', () async {
    when(() => goalsRef.child(any())).thenReturn(goalsRef);
    when(() => goalsRef.update(any())).thenAnswer((_) async {});
    await repo.updateGoalStatus('g1', false);
    verify(() => goalsRef.update({'isActive': false})).called(1);
  });

  test('updateGoalStatus early return if no user', () async {
    when(() => auth.currentUser).thenReturn(null);
    await repo.updateGoalStatus('g1', false);
    verifyNever(() => goalsRef.update(any()));
  });

  // ---------- updateGoalStatusWithAi ----------
  test('updateGoalStatusWithAi updates matching active goal', () async {
    final snap = buildSnapshot(
      exists: true,
      value: {
        'g1': {
          'title': 'AI Goal',
          'description': 'D',
          'isActive': true,
          'achieved': false,
          'timestamp': 1,
        }
      },
    );

    when(() => goalsRef.child(any())).thenReturn(goalsRef);
    when(() => goalsRef.get()).thenAnswer((_) async => snap);
    when(() => goalsRef.update(any())).thenAnswer((_) async {});
    when(() => historyRef.child(any())).thenReturn(historyRef);
    // ensure addGoalHistory works
    when(() => historyRef.get()).thenAnswer((_) async => buildSnapshot(exists: false));
    when(() => historyRef.set(any())).thenAnswer((_) async {});

    await repo.updateGoalStatusWithAi('AI Goal', 'yes');

    verify(() => goalsRef.update({'achieved': true})).called(1);
  });

  test('updateGoalStatusWithAi sets achieved false when value = "no"', () async {
    final snap = buildSnapshot(
      exists: true,
      value: {
        'g1': {
          'title': 'AI Goal',
          'description': 'D',
          'isActive': true,
          'achieved': true,
          'timestamp': 1,
        }
      },
    );

    when(() => goalsRef.child(any())).thenReturn(goalsRef);
    when(() => goalsRef.get()).thenAnswer((_) async => snap);
    when(() => goalsRef.update(any())).thenAnswer((_) async {});
    when(() => historyRef.child(any())).thenReturn(historyRef);
    when(() => historyRef.get()).thenAnswer((_) async => buildSnapshot(exists: false));
    when(() => historyRef.set(any())).thenAnswer((_) async {});

    await repo.updateGoalStatusWithAi('AI Goal', 'no');

    verify(() => goalsRef.update({'achieved': false})).called(1);
  });


  test('updateGoalStatusWithAi sets achieved false when value = "no"', () async {
    final snap = buildSnapshot(
      exists: true,
      value: {
        'g1': {
          'title': 'AI Goal',
          'description': 'D',
          'isActive': true,
          'achieved': true,
          'timestamp': 1,
        }
      },
    );

    when(() => goalsRef.child(any())).thenReturn(goalsRef);
    when(() => goalsRef.get()).thenAnswer((_) async => snap);
    when(() => goalsRef.update(any())).thenAnswer((_) async {});
    when(() => historyRef.child(any())).thenReturn(historyRef);
    when(() => historyRef.get()).thenAnswer((_) async => buildSnapshot(exists: false));
    when(() => historyRef.set(any())).thenAnswer((_) async {});

    await repo.updateGoalStatusWithAi('AI Goal', 'no');

    verify(() => goalsRef.update({'achieved': false})).called(1);
  });

  test('updateGoalStatusWithAi no matching goal does nothing', () async {
    final snap = MockDataSnapshot();
    when(() => goalsRef.child(any())).thenReturn(goalsRef);
    when(() => goalsRef.get()).thenAnswer((_) async => snap);
    when(() => snap.exists).thenReturn(true);
    when(() => snap.value).thenReturn({
      'g1': {
        'title': 'Other',
        'description': 'd',
        'isActive': true,
        'achieved': true,
        'timestamp': 123,
      }
    });
    await repo.updateGoalStatusWithAi('NotFound', 'yes');
    verifyNever(() => goalsRef.update(any()));
  });

  test('updateGoalStatusWithAi snapshot not exists returns safely', () async {
    final snap = MockDataSnapshot();
    when(() => goalsRef.child(any())).thenReturn(goalsRef);
    when(() => goalsRef.get()).thenAnswer((_) async => snap);
    when(() => snap.exists).thenReturn(false);
    await repo.updateGoalStatusWithAi('t', 'yes');
    verifyNever(() => goalsRef.update(any()));
  });

  // ---------- deleteGoal ----------
  test('deleteGoal removes from firebase', () async {
    when(() => goalsRef.child(any())).thenReturn(goalsRef);
    when(() => goalsRef.remove()).thenAnswer((_) async {});
    await repo.deleteGoal('g1');
    verify(() => goalsRef.remove()).called(1);
  });

  test('deleteGoal early return if no user', () async {
    when(() => auth.currentUser).thenReturn(null);
    await repo.deleteGoal('g1');
    verifyNever(() => goalsRef.remove());
  });

  // ---------- addGoalHistory ----------
  test('addGoalHistory sets when snapshot not exists', () async {
    final snap = MockDataSnapshot();
    when(() => historyRef.child(any())).thenReturn(historyRef);
    when(() => historyRef.get()).thenAnswer((_) async => snap);
    when(() => snap.exists).thenReturn(false);
    when(() => historyRef.set(any())).thenAnswer((_) async {});
    await repo.addGoalHistory('g1', 'value', true);
    verify(() => historyRef.set(any())).called(1);
  });

  test('addGoalHistory updates when snapshot exists', () async {
    final snap = MockDataSnapshot();
    when(() => historyRef.child(any())).thenReturn(historyRef);
    when(() => historyRef.get()).thenAnswer((_) async => snap);
    when(() => snap.exists).thenReturn(true);
    when(() => historyRef.update(any())).thenAnswer((_) async {});
    await repo.addGoalHistory('g1', 'value', true);
    verify(() => historyRef.update(any())).called(1);
  });

  test('addGoalHistory early return if no user', () async {
    when(() => auth.currentUser).thenReturn(null);
    await repo.addGoalHistory('g1', 'field', true);
    verifyNever(() => historyRef.update(any()));
  });
}
