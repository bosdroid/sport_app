import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:bjj_dairy/domain/repositories/note_repository.dart';
import 'package:bjj_dairy/presentation/providers/note_provider.dart';

class MockNoteRepository extends Mock implements NoteRepository {}

void main() {
  late MockNoteRepository mockRepository;
  late NoteProvider provider;
  late List<VoidCallback> listenersCalled;

  setUp(() {
    mockRepository = MockNoteRepository();
    provider = NoteProvider(mockRepository);
    listenersCalled = [];

    // Track notifyListeners calls
    provider.addListener(() => listenersCalled.add(() {}));
  });

  group('NoteProvider', () {
    test('updateTargetDateTime updates date and notifies once', () {
      final date = DateTime(2025, 10, 12);
      provider.updateTargetDateTime(date);

      expect(provider.targetDateTime, date);
      expect(listenersCalled.length, 1);
    });

    test('fetchTodayNote updates both targetDateTime and todayNote', () async {
      final date = DateTime(2025, 9, 8);
      when(() => mockRepository.fetchNote(date))
          .thenAnswer((_) async => 'Test Note');

      await provider.fetchTodayNote(date);

      expect(provider.todayNote, 'Test Note');
      expect(provider.targetDateTime, date);
      verify(() => mockRepository.fetchNote(date)).called(1);
      // two notifications: 1) date updated, 2) note updated
      expect(listenersCalled.length, 2);
    });

    test('fetchTodayNote works when no date is passed (uses DateTime.now())', () async {
      when(() => mockRepository.fetchNote(any()))
          .thenAnswer((_) async => 'Today’s Note');

      await provider.fetchTodayNote(); // no arg

      expect(provider.todayNote, 'Today’s Note');
      expect(provider.targetDateTime, isNotNull);
      verify(() => mockRepository.fetchNote(any())).called(1);
      expect(listenersCalled.length, 2); // updateTargetDateTime + after fetch
    });

    test('fetchTodayNote handles empty string from repository', () async {
      final date = DateTime(2025, 9, 8);
      when(() => mockRepository.fetchNote(date))
          .thenAnswer((_) async => '');

      await provider.fetchTodayNote(date);

      expect(provider.todayNote, '');
      expect(listenersCalled.length, 2);
      verify(() => mockRepository.fetchNote(date)).called(1);
    });

    test('addNote saves and refetches when targetDateTime is set', () async {
      final date = DateTime(2025, 9, 8);
      provider.updateTargetDateTime(date);
      listenersCalled.clear(); // reset after initial listener fire

      when(() => mockRepository.addNote('New Note', targetDate: date))
          .thenAnswer((_) async {});
      when(() => mockRepository.fetchNote(date))
          .thenAnswer((_) async => 'New Note');

      await provider.addNote('New Note');

      expect(provider.todayNote, 'New Note');
      verify(() => mockRepository.addNote('New Note', targetDate: date)).called(1);
      verify(() => mockRepository.fetchNote(date)).called(1);
      expect(listenersCalled.length, 1); // notify once at end
    });

    test('addNote falls back to DateTime.now() when targetDateTime is null', () async {
      when(() => mockRepository.addNote(any(), targetDate: any(named: 'targetDate')))
          .thenAnswer((_) async {});
      when(() => mockRepository.fetchNote(any()))
          .thenAnswer((_) async => 'Default Note');

      await provider.addNote('Default Note');

      expect(provider.todayNote, 'Default Note');
      expect(provider.targetDateTime, isNull); // not modified here
      verify(() => mockRepository.addNote('Default Note', targetDate: any(named: 'targetDate'))).called(1);
      expect(listenersCalled.length, 1);
    });

    test('addNote keeps old note on repository error', () async {
      final date = DateTime(2025, 9, 8);
      provider.updateTargetDateTime(date);

      // Simulate an existing note in repo
      when(() => mockRepository.fetchNote(date))
          .thenAnswer((_) async => 'Old Note');
      await provider.fetchTodayNote(date);
      final oldNote = provider.todayNote;

      // Now simulate repository failure
      when(() => mockRepository.addNote(any(), targetDate: any(named: 'targetDate')))
          .thenThrow(Exception('save failed'));
      when(() => mockRepository.fetchNote(any()))
          .thenThrow(Exception('fetch failed'));

      // Try adding new note (will fail)
      try {
        await provider.addNote('Bad Note');
      } catch (_) {
        // ignore
      }

      // Verify old note still remains
      expect(provider.todayNote, oldNote);
    });

  });
}
