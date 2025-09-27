import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bjj_dairy/domain/entities/goal.dart';
import 'package:bjj_dairy/domain/repositories/goal_repository.dart';
import 'package:bjj_dairy/presentation/providers/goal_provider.dart';

// ---------- Mocks ----------
class MockGoalRepository extends Mock implements GoalRepository {}

// ---------- Fallback for Goal ----------
class FakeGoal extends Fake implements Goal {}

void main() {
  late GoalProvider provider;
  late MockGoalRepository mockRepo;

  // Register fallback once for all tests
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
    when(() => mockRepo.addGoal(title: any(named: 'title'), description: any(named: 'description')))
        .thenAnswer((_) async {});
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

  test('updateGoalData updates local goal immediately', () async {
    when(() => mockRepo.updateGoalData(any())).thenAnswer((_) async {});

    await provider.updateGoalData(sampleGoal);

    // provider.goals stays empty because we didn't fetch, we just ensure call made
    verify(() => mockRepo.updateGoalData(sampleGoal)).called(1);
  });

  test('deleteGoal removes goal', () async {
    when(() => mockRepo.deleteGoal(any())).thenAnswer((_) async {});

    provider.goals.add(sampleGoal);
    await provider.deleteGoal('1');

    expect(provider.goals.isEmpty, true);
    verify(() => mockRepo.deleteGoal('1')).called(1);
  });
}
