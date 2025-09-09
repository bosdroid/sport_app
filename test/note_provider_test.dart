import 'package:bjj_dairy/domain/repositories/note_repository.dart';
import 'package:bjj_dairy/presentation/providers/note_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';


class MockNoteRepository extends Mock implements NoteRepository {}

void main() {
  late MockNoteRepository mockRepository;
  late NoteProvider provider;

  setUp(() {
    mockRepository = MockNoteRepository();
    provider = NoteProvider(mockRepository);
  });

  group('NoteProvider', () {
    test('fetchTodayNote updates todayNote and targetDateTime', () async {
      final date = DateTime(2025, 9, 8);
      when(() => mockRepository.fetchNote(any()))
          .thenAnswer((_) async => 'Test Note');

      await provider.fetchTodayNote(date);

      expect(provider.todayNote, 'Test Note');
      expect(provider.targetDateTime, date);
      verify(() => mockRepository.fetchNote(date)).called(1);
    });

    test('addNote saves and fetches note again', () async {
      final date = DateTime(2025, 9, 8);
      provider.updateTargetDateTime(date);

      when(() => mockRepository.addNote('New Note', targetDate: date))
          .thenAnswer((_) async {});
      when(() => mockRepository.fetchNote(date))
          .thenAnswer((_) async => 'New Note');

      await provider.addNote('New Note');

      expect(provider.todayNote, 'New Note');
      verify(() => mockRepository.addNote('New Note', targetDate: date))
          .called(1);
      verify(() => mockRepository.fetchNote(date)).called(1);
    });
  });
}
