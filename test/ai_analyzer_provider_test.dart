import 'dart:convert';
import 'package:bjj_dairy/domain/entities/goal.dart';
import 'package:bjj_dairy/domain/entities/log.dart';
import 'package:bjj_dairy/domain/repositories/ai_repository.dart';
import 'package:bjj_dairy/domain/repositories/goal_repository.dart';
import 'package:bjj_dairy/domain/repositories/log_repository.dart';
import 'package:bjj_dairy/domain/repositories/note_repository.dart';
import 'package:bjj_dairy/presentation/providers/ai_analyzer_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockAiRepository extends Mock implements AiRepository {}
class MockGoalRepository extends Mock implements GoalRepository {}
class MockLogRepository extends Mock implements LogRepository {}
class MockNoteRepository extends Mock implements NoteRepository {}

void main() {
  late MockAiRepository mockAiRepository;
  late MockGoalRepository mockGoalRepository;
  late MockLogRepository mockLogRepository;
  late MockNoteRepository mockNoteRepository;
  late AiAnalyzerProvider provider;

  setUp(() {
    mockAiRepository = MockAiRepository();
    mockGoalRepository = MockGoalRepository();
    mockLogRepository = MockLogRepository();
    mockNoteRepository = MockNoteRepository();

    provider = AiAnalyzerProvider(
      aiRepository: mockAiRepository,
      goalRepository: mockGoalRepository,
      logRepository: mockLogRepository,
      noteRepository: mockNoteRepository,
    );
  });

  group('AiAnalyzerProvider', () {
    test('resetResponse clears aiResponse', () {
      provider.resetResponse();
      expect(provider.aiResponse, "");
    });

    test('analyzeText calls AI and updates repositories', () async {
      when(() => mockAiRepository.fetchPrompt())
          .thenAnswer((_) async => "Prompt");
      when(() => mockGoalRepository.fetchGoals())
          .thenAnswer((_) async => [Goal(id:"123",title:"Goal1",description: "Goal1 Description",timestamp:21212313)]);
      when(() => mockLogRepository.fetchLogs())
          .thenAnswer((_) async => [Log(id:"123",title:"Log1",description: "Log1 Description",type:"Text",timestamp: 35345345,resetTimestamp: 0)]);
      when(() => mockNoteRepository.fetchNote(any()))
          .thenAnswer((_) async => "Note1");

      final fakeAiResponse = {
        "choices": [
          {
            "message": {
              "content": jsonEncode({
                "Logs": {"Log1": "Updated"},
                "Goals": {"Goal1": "Done"},
                "Notes": ["New Note"]
              })
            }
          }
        ]
      };

      when(() => mockAiRepository.sendToAI(any()))
          .thenAnswer((_) async => fakeAiResponse);
      when(() => mockLogRepository.updateLogDataWithAi(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockGoalRepository.updateGoalStatusWithAi(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockNoteRepository.addNote(any()))
          .thenAnswer((_) async {});

      await provider.analyzeText("Audio input");

      expect(provider.aiResponse, "");
      expect(provider.logs["Log1"], "Updated");
      expect(provider.goals["Goal1"], "Done");
      expect(provider.notes, ["New Note"]);
    });
  });
}

