import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bjj_dairy/domain/entities/goal.dart';
import 'package:bjj_dairy/domain/repositories/goal_repository.dart';
import 'package:bjj_dairy/presentation/providers/goal_provider.dart';

// ---------- Mocks ----------
class MockGoalRepository extends Mock implements GoalRepository {}

// ---------- Fallback ----------
class FakeGoal extends Fake implements Goal {}

void main() {
  late GoalProvider provider;
  late MockGoalRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(FakeGoal());
  });

  final sampleGoal = Goal(
    id: '1',
    title: 'Test Goal',
    description: 'Desc',
    timestamp: 111,
    isActive: true,
    achieved: false,
  );

  setUp(() {
    mockRepo = MockGoalRepository();
    provider = GoalProvider(mockRepo);
  });

  // ---------------- BASIC TESTS ----------------

  test('fetchGoals updates goals and loading flags', () async {
    when(() => mockRepo.fetchGoals()).thenAnswer((_) async => [sampleGoal]);

    expect(provider.isLoading, false);
    await provider.fetchGoals();

    expect(provider.isLoading, false);
    expect(provider.goals.length, 1);
    expect(provider.goals.first.title, 'Test Goal');
    verify(() => mockRepo.fetchGoals()).called(1);
  });

  test('addGoal calls repo and refreshes list', () async {
    when(() => mockRepo.addGoal(
      title: any(named: 'title'),
      description: any(named: 'description'),
    )).thenAnswer((_) async {});
    when(() => mockRepo.fetchGoals()).thenAnswer((_) async => [sampleGoal]);

    await provider.addGoal('t', 'd');

    expect(provider.goals.length, 1);
    verify(() => mockRepo.addGoal(title: 't', description: 'd')).called(1);
  });

  test('updateGoal updates list and resets isChanged', () async {
    when(() => mockRepo.updateGoal(any())).thenAnswer((_) async {});
    when(() => mockRepo.fetchGoals()).thenAnswer((_) async => [sampleGoal]);

    provider.updateChangeState(true);
    await provider.updateGoal(sampleGoal);

    expect(provider.isChanged, false);
    verify(() => mockRepo.updateGoal(sampleGoal)).called(1);
  });

  test('updateGoalData updates local goal immediately (index = -1)', () async {
    when(() => mockRepo.updateGoalData(any())).thenAnswer((_) async {});
    await provider.updateGoalData(sampleGoal);
    verify(() => mockRepo.updateGoalData(sampleGoal)).called(1);
  });

  test('deleteGoal removes goal', () async {
    when(() => mockRepo.deleteGoal(any())).thenAnswer((_) async {});
    provider.goals.add(sampleGoal);
    await provider.deleteGoal('1');

    expect(provider.goals.isEmpty, true);
    verify(() => mockRepo.deleteGoal('1')).called(1);
  });

  // ---------------- NEW COVERAGE TESTS ----------------

  test('activeGoals, totalActiveGoals, and anyGoalChanges getters work', () {
    provider.goals.addAll([
      Goal(
          id: '1',
          title: 'A',
          description: '',
          timestamp: 1,
          isActive: true,
          achieved: false,
          changes: true),
      Goal(
          id: '2',
          title: 'B',
          description: '',
          timestamp: 1,
          isActive: false,
          achieved: false)
    ]);

    expect(provider.activeGoals.length, 1);
    expect(provider.totalActiveGoals, 1);
    expect(provider.anyGoalChanges, true);
  });

  test('updateGoalAchieved updates goal when found', () async {
    when(() => mockRepo.updateGoalAchieved(any(), any())).thenAnswer((_) async {});
    provider.goals.add(sampleGoal);

    await provider.updateGoalAchieved('1', true);

    expect(provider.goals.first.achieved, true);
    expect(provider.isChanged, false);
    verify(() => mockRepo.updateGoalAchieved('1', true)).called(1);
  });

  test('updateGoalAchieved does nothing if goal not found', () async {
    when(() => mockRepo.updateGoalAchieved(any(), any())).thenAnswer((_) async {});
    await provider.updateGoalAchieved('999', true);
    verify(() => mockRepo.updateGoalAchieved('999', true)).called(1);
  });

  test('updateGoalStatus updates goal when found', () async {
    when(() => mockRepo.updateGoalStatus(any(), any())).thenAnswer((_) async {});
    provider.goals.add(sampleGoal);

    await provider.updateGoalStatus('1', false);

    expect(provider.goals.first.isActive, false);
    expect(provider.isChanged, false);
    verify(() => mockRepo.updateGoalStatus('1', false)).called(1);
  });

  test('updateGoalStatus does nothing if goal not found', () async {
    when(() => mockRepo.updateGoalStatus(any(), any())).thenAnswer((_) async {});
    await provider.updateGoalStatus('999', false);
    verify(() => mockRepo.updateGoalStatus('999', false)).called(1);
  });

  test('updateGoalStatusWithAi reloads goals successfully', () async {
    when(() => mockRepo.updateGoalStatusWithAi(any(), any()))
        .thenAnswer((_) async {});
    when(() => mockRepo.fetchGoals()).thenAnswer((_) async => [sampleGoal]);

    await provider.updateGoalStatusWithAi('t', 'v');

    expect(provider.goals.length, 1);
    expect(provider.isChanged, false);
    verify(() => mockRepo.updateGoalStatusWithAi('t', 'v')).called(1);
    verify(() => mockRepo.fetchGoals()).called(1);
  });

  test('addGoalHistory calls repo and resets change flag', () async {
    when(() => mockRepo.addGoalHistory(any(), any(), any())).thenAnswer((_) async {});
    provider.updateChangeState(true);
    await provider.addGoalHistory('1', 'field', 'val');
    expect(provider.isChanged, false);
    verify(() => mockRepo.addGoalHistory('1', 'field', 'val')).called(1);
  });

  test('updateAllGoalChanges calls addGoalHistory for changed active goals', () async {
    final changedGoal = Goal(
      id: '1',
      title: 'Test',
      description: '',
      timestamp: 0,
      isActive: true,
      achieved: true,
      changes: true,
    );
    provider.goals.add(changedGoal);

    when(() => mockRepo.addGoalHistory(any(), any(), any())).thenAnswer((_) async {});

    await provider.updateAllGoalChanges();

    expect(provider.isLoading, false);
    expect(changedGoal.changes, false);
    verify(() => mockRepo.addGoalHistory('1', 'value', true)).called(1);
  });

  test('updateAllGoalChanges handles no changed goals', () async {
    provider.goals.add(sampleGoal);
    await provider.updateAllGoalChanges();
    expect(provider.isLoading, false);
  });

  test('resetChanges sets all changes to false', () {
    provider.goals.addAll([
      Goal(
          id: '1',
          title: 'A',
          description: '',
          timestamp: 1,
          isActive: true,
          achieved: false,
          changes: true),
      Goal(
          id: '2',
          title: 'B',
          description: '',
          timestamp: 1,
          isActive: false,
          achieved: false,
          changes: false),
    ]);

    provider.resetChanges();

    expect(provider.goals.every((g) => g.changes == false), true);
  });

  test('updateGoalData updates existing goal when found', () async {
    when(() => mockRepo.updateGoalData(any())).thenAnswer((_) async {});
    provider.goals.add(sampleGoal);
    final updated = Goal(
      id: '1',
      title: 'Updated',
      description: 'New',
      timestamp: 999,
      isActive: true,
      achieved: true,
    );

    await provider.updateGoalData(updated);
    expect(provider.goals.first.title, 'Updated');
    verify(() => mockRepo.updateGoalData(updated)).called(1);
  });
}
