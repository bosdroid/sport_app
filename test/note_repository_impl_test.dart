import 'package:bjj_dairy/data/repositories/note_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDatabaseReference extends Mock implements DatabaseReference {}
class MockDataSnapshot extends Mock implements DataSnapshot {}

void main() {
  late MockDatabaseReference mockRef;
  late NoteRepositoryImpl repository;

  setUp(() {
    mockRef = MockDatabaseReference();
    repository = NoteRepositoryImpl(notesRef: mockRef);
    SharedPreferences.setMockInitialValues({"user_name": "user123"});
  });

  group('NoteRepositoryImpl', () {
    test('fetchNote returns empty string if snapshot does not exist', () async {
      final mockChildRef = MockDatabaseReference();
      final mockSnapshot = MockDataSnapshot();

      when(() => mockRef.child(any())).thenReturn(mockChildRef);
      when(() => mockChildRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(false);

      final note = await repository.fetchNote(DateTime(2025, 9, 8));

      expect(note, "");
    });

    test('fetchNote returns note when snapshot exists', () async {
      final mockChildRef = MockDatabaseReference();
      final mockSnapshot = MockDataSnapshot();

      when(() => mockRef.child(any())).thenReturn(mockChildRef);
      when(() => mockChildRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.value).thenReturn({"note": "Hello"});

      final note = await repository.fetchNote(DateTime(2025, 9, 8));

      expect(note, "Hello");
    });

    test('addNote sets new note if snapshot does not exist', () async {
      final mockChildRef = MockDatabaseReference();
      final mockSnapshot = MockDataSnapshot();

      when(() => mockRef.child(any())).thenReturn(mockChildRef);
      when(() => mockChildRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(false);
      when(() => mockChildRef.set(any())).thenAnswer((_) async {});

      await repository.addNote("Test Note", targetDate: DateTime(2025, 9, 8));

      verify(() => mockChildRef.set(any())).called(1);
    });

    test('addNote updates existing note if snapshot exists', () async {
      final mockChildRef = MockDatabaseReference();
      final mockSnapshot = MockDataSnapshot();

      when(() => mockRef.child(any())).thenReturn(mockChildRef);
      when(() => mockChildRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockChildRef.update(any())).thenAnswer((_) async {});

      await repository.addNote("Updated Note", targetDate: DateTime(2025, 9, 8));

      verify(() => mockChildRef.update(any())).called(1);
    });

    test('fetchNote returns empty string when _getUserId is null', () async {
      SharedPreferences.setMockInitialValues({}); // no user_name
      final repo = NoteRepositoryImpl(notesRef: mockRef);

      final result = await repo.fetchNote(DateTime(2025, 9, 8));

      expect(result, "");
      verifyNever(() => mockRef.child(any()));
    });

    test('fetchNote uses DateTime.now() when no dateTime provided', () async {
      final mockChildRef = MockDatabaseReference();
      final mockSnapshot = MockDataSnapshot();

      when(() => mockRef.child(any())).thenReturn(mockChildRef);
      when(() => mockChildRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.value).thenReturn({"note": "Auto Note"});

      final note = await repository.fetchNote(null); // no argument

      expect(note, "Auto Note");
      verify(() => mockRef.child(any())).called(1);
    });

    test('fetchNote returns empty string if snapshot.value is null or invalid', () async {
      final mockChildRef = MockDatabaseReference();
      final mockSnapshot = MockDataSnapshot();

      when(() => mockRef.child(any())).thenReturn(mockChildRef);
      when(() => mockChildRef.get()).thenAnswer((_) async => mockSnapshot);

      // Case 1: exists = true, value = null
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.value).thenReturn(null);
      expect(await repository.fetchNote(DateTime(2025, 9, 8)), "");

      // Case 2: value is not a Map
      when(() => mockSnapshot.value).thenReturn("just a string");
      expect(await repository.fetchNote(DateTime(2025, 9, 8)), "");

      // Case 3: value is Map missing note key
      when(() => mockSnapshot.value).thenReturn({"something": "else"});
      expect(await repository.fetchNote(DateTime(2025, 9, 8)), "");

      // Case 4: note key exists but null
      when(() => mockSnapshot.value).thenReturn({"note": null});
      expect(await repository.fetchNote(DateTime(2025, 9, 8)), "");
    });

    test('addNote does nothing when _getUserId is null', () async {
      SharedPreferences.setMockInitialValues({}); // no user_name
      final repo = NoteRepositoryImpl(notesRef: mockRef);

      await repo.addNote("No user", targetDate: DateTime(2025, 9, 8));

      verifyNever(() => mockRef.child(any()));
    });

    test('addNote uses DateTime.now() when no targetDate provided', () async {
      final mockChildRef = MockDatabaseReference();
      final mockSnapshot = MockDataSnapshot();

      when(() => mockRef.child(any())).thenReturn(mockChildRef);
      when(() => mockChildRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(false);
      when(() => mockChildRef.set(any())).thenAnswer((_) async {});

      await repository.addNote("Now Note");

      verify(() => mockChildRef.set(any(that: predicate((data) {
        return data is Map &&
            data.containsKey('note') &&
            data.containsKey('updatedAt') &&
            data['note'] == "Now Note";
      })))).called(1);
    });

    test('addNote sets and updates with correct path and payload', () async {
      final mockChildRef = MockDatabaseReference();
      final mockSnapshot = MockDataSnapshot();
      final date = DateTime(2025, 9, 8);

      when(() => mockRef.child('user123/${date.year}-${date.month}-${date.day}'))
          .thenReturn(mockChildRef);

      // Case 1: set
      when(() => mockChildRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(false);
      when(() => mockChildRef.set(any())).thenAnswer((_) async {});
      await repository.addNote("Set Test", targetDate: date);
      verify(() => mockChildRef.set(any(that: predicate((data) =>
      data is Map && data['note'] == "Set Test" && data.containsKey('updatedAt'))))).called(1);

      // Case 2: update
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockChildRef.update(any())).thenAnswer((_) async {});
      await repository.addNote("Update Test", targetDate: date);
      verify(() => mockChildRef.update(any(that: predicate((data) =>
      data is Map && data['note'] == "Update Test" && data.containsKey('updatedAt'))))).called(1);
    });


  });
}
