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

    // test('sendToAI returns decoded JSON on success', () async {
    //   final client = MockHttpClient();
    //
    //   final responseBody = jsonEncode({
    //     "id": "chatcmpl-123",
    //     "choices": [
    //       {"message": {"content": "Hello"}}
    //     ]
    //   });
    //
    //   // Mock the POST request
    //   when(() => client.post(
    //     Uri.parse("https://api.openai.com/v1/chat/completions"),
    //     headers: any(named: "headers"),
    //     body: any(named: "body"),
    //   )).thenAnswer((_) async => http.Response(responseBody, 200));
    //
    //   final repo = AiRepositoryImpl(
    //     promptRef: mockPromptRef,
    //     notesRef: mockNotesRef,
    //     httpClient: client,
    //   );
    //
    //   final result = await repo.sendToAI("My prompt");
    //
    //   expect(result, isA<Map<String, dynamic>>());
    //   expect(result["choices"], isNotEmpty);
    //
    //   verify(() => client.post(
    //     Uri.parse("https://api.openai.com/v1/chat/completions"),
    //     headers: any(named: "headers"), // don’t hardcode here
    //     body: any(named: "body"),
    //   )).called(1);
    // });

    test('sendToAI throws exception on network error', () async {
      final client = MockHttpClient();

      when(() => client.post(any(),
          headers: any(named: "headers"),
          body: any(named: "body"))).thenThrow(Exception("Network error"));

      final repo = AiRepositoryImpl(
        promptRef: mockPromptRef,
        notesRef: mockNotesRef,
        httpClient: client,
      );

      expect(() async => await repo.sendToAI("prompt"), throwsException);
    });

    test('fetchUserNotes returns empty list if snapshot does not exist', () async {
      final mockChildRef = MockDatabaseReference();
      final mockSnapshot = MockDataSnapshot();

      when(() => mockNotesRef.child("user456")).thenReturn(mockChildRef);
      when(() => mockChildRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(false);

      final notes = await repository.fetchUserNotes("user456");
      expect(notes, isEmpty);
    });

    test('fetchUserNotes aggregates multiple notes correctly', () async {
      final mockChildRef = MockDatabaseReference();
      final mockSnapshot = MockDataSnapshot();
      final mockDateSnapshot1 = MockDataSnapshot();
      final mockDateSnapshot2 = MockDataSnapshot();
      final mockNoteSnapshot1 = MockDataSnapshot();
      final mockNoteSnapshot2 = MockDataSnapshot();
      final mockOtherSnapshot = MockDataSnapshot();

      when(() => mockNotesRef.child("user789")).thenReturn(mockChildRef);
      when(() => mockChildRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.children).thenReturn([mockDateSnapshot1, mockDateSnapshot2]);

      // Date 1 → one valid note
      when(() => mockDateSnapshot1.children).thenReturn([mockNoteSnapshot1]);
      when(() => mockNoteSnapshot1.key).thenReturn("note");
      when(() => mockNoteSnapshot1.value).thenReturn("Note A");

      // Date 2 → one valid note + unrelated + null
      when(() => mockDateSnapshot2.children).thenReturn([
        mockNoteSnapshot2,
        mockOtherSnapshot
      ]);
      when(() => mockNoteSnapshot2.key).thenReturn("note");
      when(() => mockNoteSnapshot2.value).thenReturn("Note B");
      when(() => mockOtherSnapshot.key).thenReturn("random");
      when(() => mockOtherSnapshot.value).thenReturn(null);

      final notes = await repository.fetchUserNotes("user789");

      expect(notes, ["Note A", "Note B"]);
    });

    test('fetchUserNotes skips invalid or null values', () async {
      final mockChildRef = MockDatabaseReference();
      final mockSnapshot = MockDataSnapshot();
      final mockDateSnapshot = MockDataSnapshot();
      final mockNoteSnapshot1 = MockDataSnapshot();
      final mockNoteSnapshot2 = MockDataSnapshot();

      when(() => mockNotesRef.child("user999")).thenReturn(mockChildRef);
      when(() => mockChildRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.children).thenReturn([mockDateSnapshot]);

      // Note snapshots (1st is null, should be skipped)
      when(() => mockDateSnapshot.children)
          .thenReturn([mockNoteSnapshot1, mockNoteSnapshot2]);
      when(() => mockNoteSnapshot1.key).thenReturn("note");
      when(() => mockNoteSnapshot1.value).thenReturn(null); // skipped
      when(() => mockNoteSnapshot2.key).thenReturn("note");
      when(() => mockNoteSnapshot2.value).thenReturn(12345); // valid

      final notes = await repository.fetchUserNotes("user999");

      expect(notes, ["12345"]); // only one valid note
    });

    test('fetchPrompt coerces non-string value to string', () async {
      final mockChildRef = MockDatabaseReference();
      final mockSnapshot = MockDataSnapshot();

      when(() => mockPromptRef.child(any())).thenReturn(mockChildRef);
      when(() => mockChildRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.value).thenReturn(12345);

      final prompt = await repository.fetchPrompt();
      expect(prompt, "12345");
    });

  });


}
