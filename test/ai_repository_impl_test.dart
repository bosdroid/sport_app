import 'dart:convert';
import 'package:bjj_dairy/data/repositories/ai_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';

class MockDatabaseReference extends Mock implements DatabaseReference {}
class MockDataSnapshot extends Mock implements DataSnapshot {}
class MockHttpClient extends Mock implements http.Client {}
class FakeUri extends Fake implements Uri {}

void main() {
  late MockDatabaseReference mockPromptRef;
  late MockDatabaseReference mockNotesRef;
  late AiRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(FakeUri()); // register fake for Uri
  });

  setUp(() {
    mockPromptRef = MockDatabaseReference();
    mockNotesRef = MockDatabaseReference();
    repository = AiRepositoryImpl(
      promptRef: mockPromptRef,
      notesRef: mockNotesRef,
    );
  });

  group('AiRepositoryImpl', () {
    test('fetchPrompt returns empty string if snapshot does not exist', () async {
      final mockChildRef = MockDatabaseReference();
      final mockSnapshot = MockDataSnapshot();

      when(() => mockPromptRef.child(any())).thenReturn(mockChildRef);
      when(() => mockChildRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(false);

      final prompt = await repository.fetchPrompt();

      expect(prompt, "");
    });

    test('fetchPrompt returns value if exists', () async {
      final mockChildRef = MockDatabaseReference();
      final mockSnapshot = MockDataSnapshot();

      when(() => mockPromptRef.child(any())).thenReturn(mockChildRef);
      when(() => mockChildRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.value).thenReturn("Prompt Value");

      final prompt = await repository.fetchPrompt();

      expect(prompt, "Prompt Value");
    });

    test('fetchUserNotes returns list of notes', () async {
      final mockChildRef = MockDatabaseReference();
      final mockSnapshot = MockDataSnapshot();
      final mockDateSnapshot = MockDataSnapshot();
      final mockNoteSnapshot = MockDataSnapshot();

      when(() => mockNotesRef.child("user123")).thenReturn(mockChildRef);
      when(() => mockChildRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.children).thenReturn([mockDateSnapshot]);
      when(() => mockDateSnapshot.children).thenReturn([mockNoteSnapshot]);
      when(() => mockNoteSnapshot.key).thenReturn("note");
      when(() => mockNoteSnapshot.value).thenReturn("My Note");

      final notes = await repository.fetchUserNotes("user123");

      expect(notes, ["My Note"]);
    });

    test('sendToAI throws exception on non-200 response', () async {
      final client = MockHttpClient();

      final response = http.Response("Error", 400);
      when(() => client.post(any(), headers: any(named: "headers"), body: any(named: "body")))
          .thenAnswer((_) async => response);

      // override http.post globally
      final repo = AiRepositoryImpl(promptRef: mockPromptRef, notesRef: mockNotesRef);

      expect(
            () async => await repo.sendToAI("test prompt"),
        throwsException,
      );
    });
  });
}
